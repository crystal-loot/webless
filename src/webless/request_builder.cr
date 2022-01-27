class Webless::RequestBuilder
  alias BodyType = String | Bytes | IO | Nil

  protected property method : String?
  protected property path : String?
  protected property headers : HTTP::Headers
  protected property body : BodyType
  protected property params : URI::Params

  def self.new
    self.new(method: nil, path: nil, headers: HTTP::Headers.new, body: nil, params: URI::Params.new)
  end

  {% for verb in %w(get head post put patch delete options) %}
    def self.{{ verb.id }} : RequestBuilder
      new.method(:{{ verb.id }})
    end

    def self.{{ verb.id }}(path : String) : RequestBuilder
      {{ verb.id }}.path(path)
    end
  {% end %}

  protected def initialize(@method, @path, @headers, @body, @params)
  end

  def method(method : Symbol | String) : RequestBuilder
    clone.tap(&.method=(method.to_s.upcase))
  end

  def path(path : String) : RequestBuilder
    clone.tap(&.path=(path))
  end

  def header(key : String, value : String) : RequestBuilder
    clone.tap(&.headers[key] = value)
  end

  def content_type(content_type : String) : RequestBuilder
    header("Content-Type", content_type)
  end

  def body(body : BodyType) : RequestBuilder
    clone.tap(&.body=(body))
  end

  def json(hash : Hash(String, _) | NamedTuple) : RequestBuilder
    content_type("application/json").body(hash.to_json)
  end

  def param(key : String, value : String) : RequestBuilder
    clone.tap(&.params[key] = value)
  end

  def form(form : Hash(String, _) | NamedTuple, multipart : Bool = false) : RequestBuilder
    result = FormHandler.handle(form, multipart)
    body(result[:body]).content_type(result[:content_type])
  end

  def build : HTTP::Request
    path = @path.not_nil!
    path += "?#{params}" if !params.empty?
    HTTP::Request.new(@method.not_nil!, path, @headers, body)
  end

  def clone : RequestBuilder
    self.class.new(@method, @path, @headers.dup, @body, @params.dup)
  end
end

require "./request_builder/form_handler"
