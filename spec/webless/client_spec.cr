require "../spec_helper"

Spectator.describe Webless::Client do
  it "sends context directly to HTTP handler" do
    result = nil

    client = Webless::Client.new do |context|
      result = context
    end

    client.get("/foo")

    expect(result).not_to be_nil
    expect(result.not_nil!.request).to have_attributes(path: "/foo", method: "GET")
  end

  it "handles cookies" do
    client = Webless::Client.new do |context|
      context.response.cookies["foo"] = "bar"
    end

    client.get("/foo")

    expect(client.cookie_jar["foo"]).to eq("bar")
  end

  it "can set cookies" do
    client = Webless::Client.new do |context|
      cookie = context.request.cookies["foo"]
      context.response.cookies["foo"] = "#{cookie.value}1"
    end

    client.cookie_jar["foo"] = "bar"

    client.get("/foo")

    expect(client.cookie_jar["foo"]).to eq("bar1")
  end

  # this allows wrappers of this library to not have to
  # add code to keep up with it themselves
  it "provides access to last response" do
    client = Webless::Client.new do |context|
      context.response.status = HTTP::Status::BAD_REQUEST
    end

    client.get("/foo")

    expect(client.last_response.status).to eq(HTTP::Status::BAD_REQUEST)
  end

  it "can clear cookies" do
    client = Webless::Client.new do |context|
      context.response.cookies["foo"] = "bar"
    end

    client.get("/foo")

    expect(client.cookie_jar["foo"]).to eq("bar")

    client.clear_cookies

    expect(client.cookie_jar["foo"]?).to be_nil
  end

  it "does not overwrite cookie with different path" do
    client = Webless::Client.new do |context|
      context.response.cookies << HTTP::Cookie.new("foo", "bazz", path: "/asdf")
    end

    client.cookie_jar["foo"] = HTTP::Cookie.new("foo", "bar", path: "/")

    client.get("/foo")

    expect(client.cookie_jar["foo"]).to eq("bazz")
    expect(client.cookie_jar.for(URI.new(path: "/asdf"))["foo"].value).to eq("bazz")
    expect(client.cookie_jar.for(URI.new(path: "/"))["foo"].value).to eq("bar")
  end

  it "does not send cookies for specific path to different path request" do
    client = Webless::Client.new do |context|
      expect(context.request.cookies["foo"]?).to be_nil
    end

    client.cookie_jar["foo"] = HTTP::Cookie.new("foo", "bar", path: "/foo")

    client.get("/")
  end

  it "can follow redirects" do
    client = Webless::Client.new do |context|
      if context.request.path == "/foo"
        context.response.status = HTTP::Status::MOVED_PERMANENTLY
        context.response.headers["Location"] = "/bar"
        next
      end
      context.response.status = HTTP::Status::NO_CONTENT
    end

    client.get("/foo")
    response = client.follow_redirect!

    expect(response.status).to eq(HTTP::Status::NO_CONTENT)
    expect(client.last_request.resource).to eq("/bar")
    expect(client.last_request.headers["Referrer"]).to eq("https://#{Webless::DEFAULT_HOST}/foo")
  end
end
