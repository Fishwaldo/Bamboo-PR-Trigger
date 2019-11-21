#!/usr/bin/env ruby
require 'optparse'
require 'rest-client'
require 'json'

options = {}
OptionParser.new do |parser|
    parser.on("-s", "--server Hostname", "The Bamboo Server") do |value|
       options[:server] = value
    end
    parser.on("-u", "--user username", "A Username that has permissions to trigger the build") do |value|
        options[:user] = value
    end
    parser.on("-p", "--pass password", "the Password of the User that has permissions to trigger the build") do |value|
        options[:pass] = value
    end
    parser.on("-k", "--key projectkey", "The Project Key to trigger a branch build on") do |value|
        options[:key] = value
    end
    parser.on("-r", "--revision PR Number", "The Pull Request Number") do |value|
        options[:pr] = value
    end

  end.parse!
if not options[:server]
    STDERR.puts 'Server Name is Not Specified'
    exit(-1)
end
if not options[:user]
    STDERR.puts "User is not Specified"
    exit(-1)
end
if not options[:pass]
    STDERR.puts "Password is not specified"
    exit(-1)
end
if not options[:key]
    STDERR.puts "Key is not Specified"
    exit(-1)
end
if not options[:pr]
    STDERR.puts "Pull Request Number is not Specified"
    exit(-1)
end
options[:url] = "http://" + options[:user] + ":" + options[:pass] + "@" + options[:server] + "/bamboo/rest/api/latest/plan/" + options[:key] + "/branch/" + options[:pr] + ".json";
#puts options[:url]

response =  RestClient.get options[:url]
if (response.code == 200)
    data = JSON.parse(response.body)
    pretty = JSON.pretty_unparse(data)
    puts "PR Test Already Exists: #{data['key']}"
    if (data['enabled'] == false)
        puts "PR Test is Disabled - Enabling"
        param = {}
        param['enabled'] = true
        url = "http://" + options[:user] + ":" + options[:pass] + "@" + options[:server] + "/bamboo/rest/api/latest/plan/" + data["key"] + "/enable"
        response = RestClient.post(url, param.to_json, content_type: :json)
        if (response.code != 204) 
            STDERR.puts "Can't Enable Project #{data['key']} - Aborting"
            exit(-1)
        else
            puts "Enabled..."
        end
    end
    puts "Queuing Build for PR Test.... #{data['key']}"
    url = "http://" + options[:user] + ":" + options[:pass] + "@" + options[:server] + "/bamboo/rest/api/latest/queue/" + data["key"] + ".json";
    response = RestClient.post(url, "", content_type: :json)
    if (response.code != 200)
        STDERR.puts "Queuing Failed... "
        exit(-1);
    else
        build = JSON.parse(response.body)
        puts "PR Test Build Queued #{build['buildResultKey']}"
    end
else
    puts "PR Test Does Not Exist"
    param = {}
    param['vcsBranch'] = "refs/pull/#{options[:pr]}/head"
    param['enabled'] = true
    param['cleanupEnabled'] = true
    url = options[:url] + "?vcsBranch=" + param['vcsBranch'] + "&enabled=true&cleanupEnabled=true"
    response = RestClient.put(url, param.to_json, content_type: :json)
    if (response.code == 200)
        build = JSON.parse(response.body)
        puts "PR Test Build Created and Queued: #{build['key']}"
    else 
        STDERR.puts "Creating New PR Test Failed."
        exit(-1)
    end
end


