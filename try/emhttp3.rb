require 'em-http'
# http://www.google.com/codesearch/p?hl=en#9IUCQyRv1S8/lib/bird_grinder/tweeter/oauth_authorization.rb&q=em-http-request&d=2

module BirdGrinder
  # An asynchronous, delegate-based twitter client that uses
  # em-http-request and yajl on the backend. It's built to be fast,
  # minimal and easy to use.
  #
  # The delegate is simply any class - the tweeter will attempt to
  # call receive_message([Symbol], [BirdGrinder::Nash]) every time
  # it processes a message / item of some kind. This in turn makes
  # it easy to process items. Also, it will dispatch both
  # incoming (e.g. :incoming_mention, :incoming_direct_message) and
  # outgoing (e.g. :outgoing_tweet) events.
  #
  # It has support the twitter search api (via #search) and the currently-
  # alpha twitter streaming api (using #streaming) built right in.
  class Tweeter
    
    # Initializes the tweeter with a given delegate. It will use
    # username and password from your settings file for authorization
    # with twitter.
    #
    # @param [Delegate] delegate the delegate class
    def initialize(delegate)
      #check_auth!
      delegate_to delegate
    end
    
    
    ##def follow(user, opts = {})
    ##  user = user.to_s.strip
    ##  logger.info "Following '#{user}'"
    ##  post("friendships/create.json", opts.merge(:screen_name => user)) do
    ##    delegate.receive_message(:outgoing_follow, N(:user => user))
    ##  end
    ##end
    
    ##def direct_messages(opts = {})
    ##  logger.debug "Fetching direct messages..."
    ##  get("direct_messages.json", opts) do |dms|
    ##    logger.debug "Fetched a total of #{dms.size} direct message(s)"
    ##    dms.each do |dm|
    ##      delegate.receive_message(:incoming_direct_message, status_to_args(dm, :direct_message))
    ##    end
    ##  end
    ##end

    # @todo Use correct authorization method
    ##def authorization_method
    ##  @authorization_method ||= (OAuthAuthorization.enabled? ? OAuthAuthorization : BasicAuthorization).new
    ##end

    protected

    ##def get_followers_page(id, opts, &blk)
    ##  get("followers/ids/#{id}.json", opts) do |res|
    ##    blk.call(res)
    ##  end
    ##end

    def request(path = "/")
      EventMachine::HttpRequest.new(api_base_url / path)
    end

    def get(path, params = {}, &blk)
      req = request(path)
      http = req.get(:query => params)
      authorization_method.add_header_to(http)
      add_response_callback(http, blk)
      http
    end

    def post(path, params = {}, &blk)
      real_params = {}
      params.each_pair { |k,v| real_params[CGI.escape(k.to_s)] = CGI.escape(v) }
      req = request(path)
      http = req.post({
        :head => {'Content-Type'  => 'application/x-www-form-urlencoded'},
        :body => real_params
      })
      authorization_method.add_header_to(http)
      add_response_callback(http, blk)
      http
    end

    def add_response_callback(http, blk)
      http.callback do
        if http.response_header.status == 200
          res = parse_response(http)
          if res.nil?
            logger.warn "Got back a blank / errored response."
          elsif successful?(res)
            blk.call(res) unless blk.blank?
          else
            logger.error "Error: #{res.error} (on #{res.request})"
          end
        else
          logger.info "Request returned a non-200 status code, had #{http.response_header.status} instead."
        end
      end
    end

    def parse_response(http)
      response = Yajl::Parser.parse(http.response)
      if response.respond_to?(:to_ary)
        response.map { |i| i.to_nash }
      else
        response.to_nash
      end
    rescue Yajl::ParseError => e
      logger.error "Invalid Response: #{http.response} (#{e.message})"
      nil
    end

    def successful?(response)
      response.respond_to?(:to_nash) ? !response.to_nash.error? : true
    end

    def status_to_args(status_items, type = :tweet)
      results = status_items.to_nash.normalized
      results.type = type
      results
    end

    ##def check_auth!
    ##  return if BirdGrinder::Settings.username? && BirdGrinder::Settings.password?
    ##  raise BirdGrinder::MissingAuthDetails, "Missing twitter username or password."
    ##end

  end
end

BirdGrinder::Tweeter.new(Class)