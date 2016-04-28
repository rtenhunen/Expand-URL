#!/usr/bin/env ruby
# 
# Rainer, 2016-04-27

require 'net/http'
require 'getoptlong'

# For debugging & development
DEBUG = false

class Expand_URL

	@@response = nil
	@@end_point = nil
	@@hops = nil
	@@target_url = nil

	def initialize(url)
		@@response = fetch_header(url)
	end

	def hops
		unless @@hops
			find_target_url()
		end
		return @@hops
	end

	def target
		unless @@target_url
			find_target_url()
		end
		return @@target_url
	end

	def raw_response
		@@response
	end

	def title
		page_title()
		
	end

	private
	def fetch_header(url)
		@uri = URI.parse(url)
		@res = Net::HTTP.get_response(@uri)
		@res_hash = @res.to_hash
		@res_hash["code"] = @res.code
		@res_hash["message"] = @res.message
		@res_hash["body"] = @res.body if @res.body
		return @res_hash
	end

	def find_target_url
		# Presuming most services use 301&302 redirects. Since the list may expand, though will be short, it's easiest to maintain as an array
		redirects = ["301", "302"]
		while (redirects.include? @@response["code"])
			(@@hops) ? (@@hops += 1) : (@@hops = 1)
			@@response = fetch_header(@@response["location"][0])
			@@target_url = @@response["location"][0] unless @@response["location"] == nil # response["location"] is an array. We want it as a string
		end			
	end

	def page_title
		# Let's find the title only once. While most queries will only run once, it may be useful to do this smartly for some future scenario
		unless @@response["title"]
			@@response["title"] = @@response["body"].scan(/<title>(.*?)<\/title>/).join("")
			# Yes, yes, "you should never parse HTML with regex" and "this could be done with e.g. nokogiri's .at_css('title').text"…
			# BUT! we're only looking for title element, scan is bloody fast for things like this, and most importantly this way there are no dependencies that are not included with default gemset so there's little licencing & infosec issues
		end
		@@response["title"]
		
	end

end


opts = GetoptLong.new(
	['--help', "-h", GetoptLong::NO_ARGUMENT],
	['--url', "-u", GetoptLong::REQUIRED_ARGUMENT],
	['--redirects', "--hops", "-r", GetoptLong::NO_ARGUMENT]
	)

opts.each do |opt, arg|
# if people use --opt=… instead of -opt …
	arg[0] = '' if (arg =~ /^=/) 

	case opt
		when "--help"
			puts <<-EOF
#{__FILE__} resolves the ultimate, "real", URL & page title from a short url.

options:
-u, --url: (required)
	the url you want to resolve

-r, --redirects:
	adds how many redirects there were in total

-o, --open:
	opens target url in default browser

-h, --help:
	outputs this message


EOF
		exit 0

		when "--url"
			URL = arg

		when "--redirects"
			Hops = true	

		when "--open"
			OPEN = true				
				

	end # case
end # getopt

# DEBUG & DEV options
if (DEBUG)
	URL = "https://t.co/uyiH3Tdk95"
end

# Nil undefined constants
Hops 	||= nil
URL 	||= nil
OPEN 	||= nil

unless (URL)
	puts "ERROR: URL is required"
	exit 1
end


u = Expand_URL.new(URL)
print "#{URL} --> \"#{u.title}\" <#{u.target}>"
if (Hops)
	puts " - #{u.hops} hop#{"s" if u.hops > 1}" 
else
	print "\n"
end


if (OPEN)
	system("open \"#{u.target}\"")
end