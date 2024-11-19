class Rack::Attack
  throttle("req/ip", limit: 5, period: 1.minute) do |req|
    req.ip
  end

  self.throttled_responder = lambda do |_env|
    [ 429, { "Content-Type" => "application/json" }, [ { message: "Rate limit exceeded. Try again later." }.to_json ] ]
  end
end
