

require 'open-uri'


base = "http://#{`boot2docker ip`.chomp}:8080"





# Test 1 second TTL.

open("#{base}/cache/1s") do |f|
  raise "wrong max-age header \"#{f.meta['cache-control']}\"" if f.meta['cache-control'] != 'max-age=1'
  xvarnish = f.meta['x-varnish'].split(' ')
  raise 'varnish cache miss on cached content' if xvarnish.length != 1
end

sleep(1)

open("#{base}/cache/1s") do |f|
  raise "wrong max-age header \"#{f.meta['cache-control']}\"" if f.meta['cache-control'] != 'max-age=1'
  xvarnish = f.meta['x-varnish'].split(' ')
  raise 'varnish cache hit on content that should have expired' if xvarnish.length != 2 
end


# Test max TTL.

open("#{base}/cache/forever") do |f|
  raise "wrong max-age header \"#{f.meta['cache-control']}\"" if f.meta['cache-control'] != 'max-age=1'
  xvarnish = f.meta['x-varnish'].split(' ')
  raise 'varnish cache miss on cached content' if xvarnish.length != 1
end

sleep(1)

open("#{base}/cache/forever") do |f|
  raise "wrong max-age header \"#{f.meta['cache-control']}\"" if f.meta['cache-control'] != 'max-age=1'
  xvarnish = f.meta['x-varnish'].split(' ')
  raise 'varnish cache hit on content that should have expired' if xvarnish.length != 2 
end

