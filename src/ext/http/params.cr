module HTTP
  struct Params
    def self.encode(hash : Hash) : String
      ::HTTP::Params.build do |form|
        hash.each do |key, value|
          key = key.to_s
          case value
          when Array
            value.each do |item|
              form.add("#{key}", item.to_s)
            end
          when File
            form.add(key, value.as(File).path)
          when Hash
            value.each do |hkey, hvalue|
              form.add("#{key}[#{hkey}]", hvalue.to_s)
            end
          else
            form.add(key, value.to_s)
          end
        end
      end
    end
  end
end
