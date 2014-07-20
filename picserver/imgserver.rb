#!/usr/local/bin/ruby
require 'sinatra'
require 'mongo'
require 'json'

set :bind, '0.0.0.0'
set :port, 13427
set :public_folder, File.dirname('./imgs')

db = Mongo::Connection.new.db("mydb")
coll = db.collection("imgserver")

get '/api' do
  params = request.env['rack.request.query_hash']
  if params['start'] == nil || params['num'] == nil
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
    ret << {"title" => doc['title'], "pics" => doc['pics']}
  }
  return ret.to_json
end
