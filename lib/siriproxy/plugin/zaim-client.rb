require 'em-http'
require 'em-http/middleware/oauth'
require 'em-http/middleware/json_response'
require 'pp'

class SiriProxy::Plugin::ZaimClient
  def initialize(param)
    @oauth_config = {
      :consumer_key        => param[:consumer_key],
      :consumer_secret     => param[:consumer_secret],
      :access_token        => param[:access_token],
      :access_token_secret => param[:access_token_secret],
    }
  end

  def read_user_verify
    req.get( :path => '/v1/user/verify_credentials.json', :query => lang  )
  end

  def read_category_pay
    req.get( :path => '/v1/category/pay.json', :query => lang )
  end

  def read_genre_pay
    req.get( :path => '/v1/genre/pay.json', :query => lang )
  end

  def write_pay(param)
    req.post(
      :path => '/v1/pay/create.json',
      :body => {
        "category_id" => param[:category_id],
        "genre_id"    => param[:genre_id],
        "price"       => param[:price],
        "date"        => param[:date] || Date.today.to_s,
      },
    )
  end

  private

  def lang
    { 'lang' => 'ja' }
  end

  def req
    req = EventMachine::HttpRequest.new('https://api.zaim.net')
    req.use EventMachine::Middleware::OAuth, @oauth_config
    req.use EventMachine::Middleware::JSONResponse
    req
  end

end
