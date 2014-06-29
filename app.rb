require 'sinatra'
require 'scuttle'
require 'json'

get '/' do
  erb :index
end

get '/convert.json' do
  begin
    content_type :json
    arel = Scuttle.colorize(Scuttle.beautify(Scuttle.convert(params[:sql])), :div)
    { result: "succeeded", arel: arel }.to_json
  rescue => e
    { result: "failed", arel: nil }.to_json
  end
end
