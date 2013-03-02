# -*- encoding: utf-8 -*-

require 'eventmachine'
require 'siriproxy/plugin/zaim-client'
require 'fiber'
require 'pp'

class SiriProxy::Plugin::Zaim < SiriProxy::Plugin
  def initialize(config = {})
    @zaim_client = SiriProxy::Plugin::ZaimClient.new(
      :consumer_key        => config["consumer_key"],
      :consumer_secret     => config["consumer_secret"],
      :access_token        => config["access_token"],
      :access_token_secret => config["access_token_secret"],
    )
    Fiber.new do
      user = user_verify
      res = genre_pay
      @genres_map = Hash[
        *res["genres"].reject {|h|
          h["title"] == "その他"
        }.map { |h|
          [h["title"], { "genre_id" => h["id"], "category_id" => h["category_id"] }
        ]}.flatten
      ]
    end.resume
  end

  listen_for /Zaim\s?(\S*?)(\d+)円/i do |genre, price|
    p genre
    p price

    key = @genres_map.keys.find { |k| genre =~ /#{k}/ }
    unless key then
      say "見つかりませんでした"
      request_completed
    end

    res = ask "#{genre} #{price}円で登録しますか?"

    if res =~ /はい/ then
      hash = @genres_map[key]
      Fiber.new do
        res = write_pay(
          :category_id => hash["category_id"],
          :genre_id    => hash["genre_id"],
          :price       => price
        )
        if res.instance_of?(Hash) then
          say "登録しました"
        else
          say "失敗しました"
        end
        request_completed
      end.resume
    else
      say "キャンセルしました"
      request_completed
    end
  end

  private

  def user_verify
    f = Fiber.current
    http = @zaim_client.read_user_verify
    http.callback do
      f.resume http.response
    end
    http.errback do
      abort "user verify err"
    end
    Fiber.yield
  end

  def genre_pay
    f = Fiber.current
    http = @zaim_client.read_genre_pay
    http.callback do
      f.resume http.response
    end
    http.errback do
      abort "genre pay err"
    end
    Fiber.yield
  end

  def write_pay(param)
    f = Fiber.current
    http = @zaim_client.write_pay(param)
    http.callback do
      f.resume http.response
    end
    http.errback do
      abort "write pay err"
    end
    Fiber.yield
  end
end
