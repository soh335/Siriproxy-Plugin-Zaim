require 'sinatra'
require 'omniauth'
require 'omniauth-zaim'

# can't regist zaim's service url with port.
# so, i regist http://127.0.0.1 and rackup with 80 port.

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :zaim,
    ENV['CONSUMER_KEY'],
    ENV['CONSUMER_SECRET']
end

get '/' do
  erb :index
end

get '/auth/:name/callback' do
  @auth = request.env['omniauth.auth']
  erb :callback
end

__END__

@@ index
<html>
<head>
</head>
<body>
<div>
<a href="/auth/zaim">auth zaim</a>
</div>
</body>
</html>

@@ callback
<html>
<head>
</head>
<body>
<div>
<p>access token</p>
<p><%= @auth.credentials.token %></p>
</div>
<div>
<p>access token secret</p>
<p><%= @auth.credentials.secret %></p>
</div>
</body>
</html>
