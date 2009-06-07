require 'sinatra/async'
require 'yaml'

class Memento < Sinatra::Base
  register Sinatra::Async

  attr_reader :host, :port, :memcache

  def initialize(opts = {})
    @@memcache = nil
    
    unless File.exists?(opts[:config_file])
      raise StandardError, "You must have a config/memento.yml file"
    else
      config = YAML::load(File.read(opts[:config_file]))
      server = config['server']
      if server.nil? || (@host, @port = server.split(':')).size != 2
        raise StandardError, "You must specify a Memcache server with the following format: host:port"
      end
    end
  end

  def memcache
    @@memcache ||= EM::P::Memcache.connect(@host, @port.to_i)
  end

  aget '/get/:key' do |key|
    memcache.get(key) { |value| body { value } }
  end

  apost '/set/' do
    key, value = params[:key], params[:value]
    expiry = params[:expiry] || '86400'
    
    memcache.set(key, value, expiry) { body { value } }
  end
  
end

run Memento.new(:config_file => 'config/memento.yml')