require 'net/http'
require 'net/https'

# try to import ntlm authentication
# (this requires patching ntlm with contrib/rubyntlm.patch)
begin
  require 'net/ntlm' 
rescue LoadError
end

# this is for OpenURI::Meta
require 'open-uri'

# target: replacement for old curl wrapper.
# get (easy enough), put, post, propfind, etc, etc.
# custom headers - for soap.
# and efficient saving to local, and uploading.

class Net::HTTPClient
	VERSION = '0.1.5'

	attr_reader :factory, :http, :uri

	def initialize opts={}
		opts = {:factory => Net::HTTP, :proxy => true}.merge opts
		@auth = opts[:auth]
		@factory = opts[:factory]
		if opts[:proxy]
			proxy = opts[:proxy]
			unless proxy.is_a? URI
				proxy = ENV['http_proxy'] if proxy == true
				proxy = URI.parse proxy['://'] ? proxy : 'http://' + proxy if proxy
			end
			@factory = Net::HTTP.Proxy proxy.host, proxy.port if proxy.is_a? URI
		end
		@uri = URI.parse ''
	end

	def reconnect
		# maybe we should be creating the factory now. using uri.find_proxy
		# too... seems neater. although its slow for some reason.
		#puts "* creating new connection"
		@http = @factory.new @uri.host, @uri.port
		if @uri.scheme == 'https'
			# default to none unless we can find the certificates.
			# this is terribly hacky, but the open-uri certificate finding code wasn't
			# working either.
			@http.use_ssl = true
			@http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			ca_file = '/etc/ssl/certs/ca-certificates.crt'
			# for use on windows:
			ca_files = [ca_file, File.dirname(File.expand_path(__FILE__)).tr('\\', '/').
													 split(/\//)[0..-6].join('/') + ca_file]
			ca_files.each do |ca_file|
				next unless File.exists? ca_file
				@http.verify_mode = OpenSSL::SSL::VERIFY_PEER
				store = OpenSSL::X509::Store.new
				store.set_default_paths
				@http.cert_store = store
				@http.ca_file = ca_file
			end
		end
		@reused = false
		@http.start
	end

	def auth= auth
		@auth = auth
		reconnect
	end

	def uri= uri
		uri = @uri + uri
		uri.path = '/' if uri.path.empty?
		# need new connection?
		begin
			#p [:testing, @uri, uri]
			raise URI::BadURIError unless @uri + '/' == uri + '/'
			@uri = uri
		rescue URI::BadURIError
			@uri = uri
			reconnect
		end
	end

	# should add stuff like deflate encoding accept.
	# and maybe the block versions
	def path_and_query uri
		uri.query ? "#{uri.path}?#{uri.query}" : uri.path
	end

	# include a write io object
	# idea is something like:
	# open('somefile', 'w') { |f| client.get url, f }
	# if its a string, then its taken to be a filename, which is sort
	# of uncomfortably different from put, but done for convenience anyway.

	def get uri, save_to=nil, headers={}
		self.uri = uri
		req = Net::HTTP::Get.new path_and_query(@uri), headers
		if !save_to
			meta_extend_body request(req)
		else
			stream = if save_to.is_a? String; open save_to, 'w'; else save_to; end
			request req do |resp|
				meta_extend save_to, resp
				resp.read_body { |data| stream << data }
			end
			stream.close if save_to.is_a? String
		end
	end

	def head uri, headers={}
		self.uri = uri
		req = Net::HTTP::Head.new path_and_query(@uri), headers
		request req
	end

	def post uri, body, headers={}
		self.uri = uri
		req = Net::HTTP::Post.new path_and_query(@uri), headers
		setup_req_body req, body
		meta_extend_body request(req)
	end

	# upload stream pointed to by io, to uri
	def put uri, body, headers={}
		self.uri = uri
		path = path_and_query @uri
		# append the filename to the uri if a folder
		if path =~ /\/$/
			raise "must specify full destination path" unless body.respond_to? :path
			path += File.basename body.path
		end
		req = Net::HTTP::Put.new path, headers
		setup_req_body req, body
#		puts "doing put. path: #{path.inspect}, headers: #{headers.inspect}. req: #{req.inspect}"
		request req
	end

	# missing a few here....
	def propfind uri, body=nil, headers={}
		self.uri = uri
		req = Net::HTTP::Propfind.new path_and_query(@uri), {'Depth' => '0'}.merge(headers)
		setup_req_body req, body if body
		resp = request req
		resp
	end

	def delete uri, headers={}
		self.uri = uri
		req = Net::HTTP::Delete.new path_and_query(@uri), headers
		request req
	end

	def move uri, dest_uri, headers={}
		self.uri = uri
		# dest_uri will override header's destination. warn instead?
		req = Net::HTTP::Move.new path_and_query(@uri), headers.merge('Destination' => (@uri + dest_uri).to_s)
		resp = request req
		resp
	end

	def copy uri, dest_uri, headers={}
		self.uri = uri
		# dest_uri will override header's destination. warn instead?
		req = Net::HTTP::Copy.new path_and_query(@uri), headers.merge('Destination' => (@uri + dest_uri).to_s)
		resp = request req
		resp
	end

	def mkcol uri, headers={}
		self.uri = uri
		req = Net::HTTP::Mkcol.new path_and_query(@uri), headers
		request req
	end

	def trace uri, headers={}
		self.uri = uri
		req = Net::HTTP::Mkcol.new path_and_query(@uri), headers
		request req
	end

	def request req, body=nil, &block
		# handle common request stuff here.
		# note that we set the authentication, with a flag that means we will
		# only authenticate un-asked, on the first use of a connection. this assumes
		# we know what method to use. otherwise, we have to wait till challenged.
		if @auth
			case @auth[0]
			when :ntlm;  req.ntlm_auth  @auth[1], @auth[2], @reused
			when :basic; req.basic_auth @auth[1], @auth[2]
			else         raise "unknown auth type #{@auth.inspect}"
			end
		end

		while true
			# we may cause an error if the connection is dead.
			# i don't know how to find that out other than to just try, and catch the error,
			# and try again, which is ugly. also, i haven't yet found the entire set of
			# possible errors. so far, i've seen:
			# OpenSSL::SSL::SSLError (on cygwin, https)
			# EOFError (on mswin32, https)
			# Errno::ECONNABORTED (on mswin32, https)
			resp = begin
				@http.request req, body, &block
			rescue
				raise unless @reused
				# printing this to get an idea about classes to rescue
				known = [EOFError, OpenSSL::SSL::SSLError, Errno::ECONNABORTED]
				STDERR.puts "* recreating connection to avoid #{$!.class}" unless known.include? $!.class
				reconnect
				req.reuse
				@http.request req, body, &block
			ensure
				@reused = true
			end
			case resp
			when Net::HTTPSuccess
				return resp
			when Net::HTTPMovedPermanently, # 301
					 Net::HTTPFound, # 302
					 Net::HTTPSeeOther, # 303
					 Net::HTTPTemporaryRedirect # 307
				# is the location field already escaped? it seems it is from
				# what i can gather...
				self.uri = resp['location']
#				self.uri = URI.escape resp['location']
				# FIXME
				# "If the 301 status code is received in response to a request other than GET or HEAD, the user agent MUST NOT automatically redirect the request"
				# http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
				# However, most existing user agent implementations treat 302 as if it were a 303 response,
				# performing a GET on the Location field-value regardless of the original request method...
				# so do i reuse the request or not? do i post data again? i think no.
				# I was triggering a bug, whereby a POST to a server responded with a 302, to send us to
				# the result page, to which I posted again, resulting in an infinite loop (not effected by
				# any timeout, as the bug is here unshielded from timeout. fix that?).
				# for now, we'll just do posts differently. Should read the above RFC and fix a lot of this
				# still interested to know what to do with data generally in redirects, and authentication
				# challenge loops etc.
				unless Net::HTTP::Get === req
					req = Net::HTTP::Get.new path_and_query(@uri)
				else
					# reuse the request. not sure how the block form should handle this, with io that
					# mightn't be rewindable etc etc. req.reuse?
					req.instance_variable_set :@path, path_and_query(@uri)
					req.reuse
				end
			else
				resp.error!
			end
		end
	end

	private
	def meta_extend_body resp
		meta_extend resp.body, resp
	end
	
	def meta_extend obj, resp
		OpenURI::Meta.init obj
		resp.each { |key, val| obj.meta_add_field key, val }
		obj.meta_add_field 'client', self
		obj.base_uri = @uri
		obj.status = [resp.code, resp.message]
		obj
	end

	def setup_req_body req, body
		if body.respond_to? :read
			unless req.content_length
				raise "must specify content length for stream" unless body.respond_to? :stat
#				puts "\nuploading stream #{body.inspect}, size #{body.stat.size}"
				req.content_length = body.stat.size
			end
			#req.body = body.read
			req.body_stream = body
		else
			req.body = body
		end
	end
end


