class Webless::RequestBuilder::FormHandler
  alias FormType = Symbol | String | Int32 | Int64 | Float64 | Bool | File | Array(FormType) | Hash(String, FormType)

  def self.handle(form : Hash(String, _) | NamedTuple) : NamedTuple(body: String, content_type: String)
    new(cast(form).as(Hash(String, FormType))).handle
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

  def initialize(@form)
  end

  def handle : NamedTuple(body: String, content_type: String)
    if multipart?
      io = IO::Memory.new
      builder = HTTP::FormData::Builder.new(io)
      @form.each do |k, v|
        case v
        when File
          builder.file(k, v.as(IO), HTTP::FormData::FileMetadata.new(filename: File.basename(v.path)))
        when Array
          v.each do |e|
            case e
            when File
              builder.file(k, e.as(IO), HTTP::FormData::FileMetadata.new(filename: File.basename(e.path)))
            else
              builder.field(k, e.to_s)
            end
          end
        else
          builder.field(k, v.to_s)
        end
      end
      builder.finish

      {body: io.to_s, content_type: builder.content_type}
    else
      body = HTTP::Params.encode(@form)
      {body: body, content_type: "application/x-www-form-urlencoded"}
    end
  end

  def multipart? : Bool
    @form.any? do |_, v|
      v.is_a?(File) || (v.is_a?(Array) && v.any?(File))
    end
  end
end
