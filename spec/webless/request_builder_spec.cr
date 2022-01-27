require "../spec_helper"

Spectator.describe Webless::RequestBuilder do
  it "works" do
    request = Webless::RequestBuilder.post("/foo").form({foo: "bar"}).build

    expect(request.resource).to eq("/foo")
    expect(request.method).to eq("POST")
    expect(request.headers["Content-Type"]).to eq("application/x-www-form-urlencoded")
  end
end
