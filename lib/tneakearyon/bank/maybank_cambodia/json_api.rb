class Tneakearyon::Bank::MaybankCambodia::JsonApi
  DEFAULT_HOST = "https://m2umobile.maybank2u.com.kh"

  attr_accessor :host, :cookie

  def initialize
    self.host = DEFAULT_HOST
  end

  def get_access_token!
    http_response = HTTParty.post(iphone_query_url, :headers => build_headers, :body => get_access_token_payload)
    if http_response.unauthorized?
      self.cookie = http_response.headers["set-cookie"]
      challenges = http_response.response.body.scan(/\{.+\}/).first
      if challenges
        p JSON.parse(challenges)
      end
    end
    http_response
  end

  def get_access_token_payload
    build_request_parameters({"method" => "getAccessToken"})
  end

  def build_headers
    headers = default_headers.dup
    headers.merge!("cookie" => cookie) if !!cookie
    headers
  end

  def default_headers
    {"x-wl-app-version" => "1.0"}
  end

  def build_request_parameters(params)
    {"parameters" => "[#{params.to_json}]"}
  end

  def iphone_query_url
    host + "/RMBP/apps/services/api/RMBPKH/iphone/query"
  end
end
