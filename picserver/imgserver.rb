#!/usr/local/bin/ruby
require 'sinatra'
require 'mongo'
require 'json'

set :bind, '0.0.0.0'
set :port, 13427
set :public_folder, File.dirname('./public')

db = Mongo::Connection.new.db("mydb")
coll = db.collection("imgserver")

get '/api' do
  params = request.env['rack.request.query_hash']
  if params['start'] == nil \
    || params['num'] == nil 
    return "NOT ENOUGH PARAMS!"
  end

  ret = []
  res = coll.find()
  if params['start'].to_i + params['num'].to_i >= res.count
    return "INVALID PARAMS!"
  end
  start = params['start'].to_i
  num = params['num'].to_i
  #puts "there are #{res.count} results"
  start.to_i.times{
    res.next
  }
  num.to_i.times{
    doc = res.next
    pics = []
    doc['pics'].each{|pic|
      pics << {"url" => "/public/" + pic}
    }
    ret << {"title" => doc['title'], "pics" => pics}
  }
  if params['callback'] == nil
    return ret.to_json
  else
    return params['callback'] +"(" + ret.to_json + ");"
  end
end

get '/' do
  send_file('index.html')
end
