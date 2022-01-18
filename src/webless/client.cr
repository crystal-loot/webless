class Webless::Client < HTTP::Client
  @port = -1

  @app : HTTP::Handler | HTTP::Handler::HandlerProc
  @last_response : HTTP::Client::Response?
  @last_request : HTTP::Request?
  getter cookie_jar = Webless::CookieJar.new

  def self.new(&app : HTTP::Handler::HandlerProc) : self
    new(app)
  end

  def initialize(@app, @host = Webless::DEFAULT_HOST)
  end

  def exec_internal(request : HTTP::Request) : HTTP::Client::Response
    @last_request = request
    cookie_jar.for(uri_for_request(request)).add_request_headers(request.headers)
    set_defaults(request)
    run_before_request_callbacks(request)
    buffer = IO::Memory.new
    response = HTTP::Server::Response.new(buffer)
    context = HTTP::Server::Context.new(request, response)

    @app.call(context)
    response.close

    response = @last_response = HTTP::Client::Response.from_io(buffer.rewind)
    cookie_jar.merge(HTTP::Cookies.from_server_headers(response.headers))
    response
  end

  def last_request : HTTP::Request
    @last_request.not_nil!
  end

  # Added because the URL is not accessible on the request
  def last_request_url : String
    uri_for_request(last_request).to_s
  end

  def last_response : HTTP::Client::Response
    @last_response.not_nil!
  end

  def clear_cookies
    @cookie_jar = Webless::CookieJar.new
  end

  def follow_redirect! : HTTP::Client::Response
    if !last_response.status.redirection?
      raise "Last response was not a redirect. Cannot follow_redirect!"
    end
    request_method = last_response.status == HTTP::Status::TEMPORARY_REDIRECT ? last_request.method : "GET"
    params = last_response.status == HTTP::Status::TEMPORARY_REDIRECT ? last_request.query_params : URI::Params.new
    next_location = uri_for_request(last_request).resolve(URI.parse(last_response.headers["Location"]))
    next_location.query_params = params

    exec(request_method, next_location.to_s, HTTP::Headers{"Referrer" => uri_for_request(last_request).to_s})
  end

  private def uri_for_request(request : HTTP::Request) : URI
    URI.parse(request.path).tap do |uri|
      uri.path = "/#{uri.path}" unless uri.path.starts_with?("/")
      uri.host ||= host
      uri.scheme ||= "https"
    end
  end
end
