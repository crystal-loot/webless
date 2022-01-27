class Webless::RequestBuilder::FormHandler
  alias FormType = Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(FormType) | Hash(String, FormType)

  def self.handle(form : Hash(String, _) | NamedTuple, multipart : Bool) : NamedTuple(body: String, content_type: String)
    new(cast(form).as(Hash(String, FormType)), multipart).handle
  end

  private def self.cast(raw : Array) : FormType
    raw.map { |item| cast(item) }.as(FormType)
  end

  private def self.cast(raw : Hash) : FormType
    temp = {} of String => FormType

    raw.each do |key, value|
      temp[key.to_s] = cast(value)
    end

    temp.as(FormType)
  end

  private def self.cast(raw : NamedTuple) : FormType
    cast(raw.to_h).as(FormType)
  end

  private def self.cast(raw : FormType) : FormType
    raw.as(FormType)
  end

  @form : Hash(String, FormType)
  @multipart : Bool

  def initialize(@form, @multipart)
  end

  def handle : NamedTuple(body: String, content_type: String)
    if @multipart
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io)
      @form.each { |k, v| apply_multipart(builder, k, v) }
      builder.finish

      {body: io.to_s, content_type: builder.content_type}
    else
      body = HTTP::Params.encode(@form)
      {body: body, content_type: "application/x-www-form-urlencoded"}
    end
  end

  private def apply_multipart(builder : HTTP::FormData::Builder, k : String, v : FormType)
    if v.is_a?(File)
      builder.file(k, v.as(IO), HTTP::FormData::FileMetadata.new(filename: File.basename(v.path)))
    elsif v.is_a?(Array)
      v.each { |item| apply_multipart(builder, k, item) }
    else
      builder.field(k, v.to_s)
    end
  end
end
