#!/usr/bin/env ruby

require 'rubygems'
require 'trollop'
require 'parseconfig'
require 'aws-sdk-v1'
require 'json'
require 'pp'

# define the list of AWS regions that we may possibly iterate over
aws_regions = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'eu-central-1', 'ap-northeast-1', 'ap-southeast-1', 'ap-southeast-2', 'sa-east-1']

# pull the AWS credentials from our environment
access_key = ENV['AWS_ACCESS_KEY']
secret_key = ENV['AWS_SECRET_KEY']

#
# if https_proxy is defined, use that. if not, but http_proxy is defined,
# use that; otherwise no proxy will be used.
#
if !ENV['https_proxy'].nil?
  proxy = ENV['https_proxy']
else
  if !ENV['http_proxy'].nil?
  	proxy = ENV['http_proxy']
  end
end

cfg_file = "#{ENV['HOME']}/.zephyr/config"
config = ParseConfig.new(cfg_file)
feedlist = Array.new
if config['json_feed'].nil?
  print "No json_feed location defined in ~/.zephyr/config, exiting!\n"
  exit 1
end

total_count = 0
aws_regions.each do |region|
  unless config['aws']["aws_region_#{region}"] == 'skip'
  	count = 0
  	print "Probing region #{region}...\n"
  	# setup aws config
  	if proxy.nil?
      AWS.config(access_key_id: access_key, secret_access_key: secret_key, region: region, proxy_uri: proxy)
    else
      AWS.config(access_key_id: access_key, secret_access_key: secret_key, region: region)
    end
    ec2 = AWS::ec2

    instances = ec2.instances.inject({}) { |m, i| m[i.id] = i.private_dns_name; m }
    instances.each do |id, dns|
      instance = ec2.instances[id]

      inst = Hash.new

      inst['id'] = id
      inst['name'] = instance.tags['Name']
      inst['private_dns_name'] = dns
      inst['private_ip_address'] = instance.private_ip_address
      inst['type'] = instance.instance_type
      inst['status'] = instance.status
      inst['ami'] = instance.image_id
      inst['platform'] = instance.platform
      inst['region'] = region
      if instance.public_ip_address
      	inst['public_ip_address'] = instance.public_ip_address
      end
      if instance.public_dns_name
      	inst['public_dns_name'] = instance.public_dns_name
      end

      feedlist = feedlist.push(inst)
      count += 1
    end

    print "#{count} instances detected.\n"
    total_count += count
  else
  	print "Skipping region #{region}...\n"
  end
end

print "#{total_count} instances across all monitored regions.\n"

f = File.new(config['json_feed'], 'w+')
f.write(feedlist.to_json)
f.close