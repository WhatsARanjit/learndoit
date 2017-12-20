#!/usr/bin/env ruby

require 'yaml'
require 'json'
require 'uri'
require 'net/http'
require 'openssl'

config_file = 'config.yaml'
@config     = YAML.load_file(config_file)
@api_url    = @config['url']
@token      = @config['token']
@location   = @config['location']
action      = ARGV[0]

def do_https(endpoint, method = 'post', data = {})

  url              = "#{@api_url}/#{endpoint}"
  uri              = URI(url)
  http             = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl     = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req              = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
  req.body         = data.to_json
  req.content_type = 'application/json'

  # Headers
  req['Accept']                       = 'application/json'
  req['TrainingRocket-Authorization'] = @token if @token

  begin
    res = http.request(req)
  rescue Exception => e
    fail(e.message)
    debug(e.backtrace.inspect)
  else
    res
  end
end

def find_file(id)
  Dir.glob("#{@location}/#{id}*.html").first
end

case action
when 'update'
  raise 'No ID supplied' unless id = ARGV[1]

  data = { 'content' => File.read(find_file(id)) }
  res  = do_https(id, 'post', data)

  if res.code.to_i != 200
    $stderr.puts "ERROR: #{res.code}: #{res.body}"
  else
    puts JSON.parse(res.body)
  end
else
  raise "ERROR: '#{action}' is not supported!"
end
