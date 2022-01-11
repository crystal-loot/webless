class Webless::CookieJar
  @cookies = [] of HTTP::Cookie

  def []=(name : String, value : String)
    self[name] = HTTP::Cookie.new(name, value)
  end

  def []=(name : String, cookie : HTTP::Cookie)
    @cookies.reject! { |existing| replaces?(existing, with: cookie) }
    @cookies << cookie
    sort!
  end

  def <<(cookie : HTTP::Cookie)
    self[cookie.name] = cookie
  end

  def [](name : String) : String
    get_cookie(name).value
  end

  def []?(name : String) : String?
    get_cookie?(name).try(&.value)
  end

  def get_cookie(name : String) : HTTP::Cookie
    get_cookie?(name).not_nil!
  end

  def get_cookie?(name : String) : HTTP::Cookie?
    cookies = self.for(nil)
    cookies[name]?
  end

  def for(uri : URI?) : HTTP::Cookies
    cookies = HTTP::Cookies.new

    @cookies.reject(&.expired?)
      .select { |cookie| uri.nil? || valid?(cookie, uri) }
      .each { |cookie| cookies << cookie }

    cookies
  end

  def merge(cookies : HTTP::Cookies)
    cookies.each { |cookie| self << cookie }
  end

  private def replaces?(existing : HTTP::Cookie, with other : HTTP::Cookie) : Bool
    [existing.name.downcase, cookie_domain(existing), cookie_path(existing)] == [other.name.downcase, cookie_domain(other), cookie_path(other)]
  end

  private def sort!
    @cookies.sort do |a, b|
      to_sortable(a) <=> to_sortable(b)
    end
  end

  private def to_sortable(cookie : HTTP::Cookie)
    [cookie.name, cookie_path(cookie), cookie_domain(cookie).reverse]
  end

  private def valid?(cookie : HTTP::Cookie, uri : URI) : Bool
    uri.host ||= default_host

    !!((!cookie.secure || uri.scheme == "https") &&
      uri.host =~ Regex.new("#{Regex.escape(cookie_domain(cookie))}$", Regex::Options::IGNORE_CASE) &&
      uri.path =~ Regex.new("^#{Regex.escape(cookie_path(cookie))}"))
  end

  private def cookie_domain(cookie : HTTP::Cookie) : String
    cookie.domain || default_host
  end

  private def cookie_path(cookie : HTTP::Cookie) : String
    cookie.path || "/"
  end

  private def default_host : String
    Webless::DEFAULT_HOST
  end
end
