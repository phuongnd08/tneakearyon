class Tneakearyon::Bank::ABA::MobileClient
  DEFAULT_HOST = "https://mapp.ababank.com/api/v1"

  attr_accessor :host, :json_response, :session_id, :aba_id, :security_code, :username, :token

  def initialize(options = {})
    self.host = options[:host] || DEFAULT_HOST
    self.username = options[:username] || get_config(:username)
    self.aba_id = options[:aba_id] || get_config(:aba_id)
    self.security_code = options[:security_code] || get_config(:security_code)
  end

  def login!
    parse_response!(
      HTTParty.post(
        api_endpoint(:login),
        :body => build_default_request_body.merge(
          "nick" => username,
          "inner_hash" => encode_message(aba_id + security_code)
        ),
        :headers => {
          "User-Agent" => "android_aba_ibank_client",
          "client_version" => "105"
        }
      ).body
    )
    set_session_id
    set_token
  end

  def get_cards!
    if token.nil?
      login!
    end

    timestamp = get_timestamp
    request_body = build_default_request_body
    add_timestamp!(request_body, timestamp)

    parse_response!(
      HTTParty.post(
        api_endpoint(:cards),
        :body => request_body.merge(
          "hash" => encode_message(aba_id + timestamp.to_s + token)
        )
      ).body
    )
  end

  def get_transaction_details!(trnx_id)
    timestamp = get_timestamp
    request_body = build_default_request_body
    add_timestamp!(request_body, timestamp)
    parse_response!(
      HTTParty.post(
        api_endpoint(:details),
        :body => request_body.merge(
          "trnx_id" => trnx_id,
          "hash" => encode_message(aba_id + trnx_id + timestamp.to_s + token)
        )
      ).body
    )
  end

  private

  def api_endpoint(path)
    host + "/#{path}"
  end

  def encode_message(message)
    Digest::SHA1.hexdigest(message).upcase
  end

  def build_default_request_body
    request_body = {
      "aba_id" => aba_id,
    }
    add_timestamp!(request_body)
    request_body.merge!("session_id" => session_id) if session_id
    request_body
  end

  def add_timestamp!(request_body, timestamp = nil)
    timestamp ||= get_timestamp
    request_body.merge!("ts" => timestamp)
  end

  def get_timestamp
    Time.now.to_i
  end

  def parse_response!(response)
    self.json_response = JSON.parse(response)
  end

  def set_session_id
    self.session_id = json_response["session_id"]
  end

  def set_token
    self.token = json_response["token"]
  end

  def get_config(key)
    ENV["TNEAKEARYON_BANK_ABA_MOBILE_CLIENT_#{key.to_s.upcase}"]
  end
end
