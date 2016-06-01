require 'nokogiri'
require 'byebug' # REMOVE ME

class Tneakearyon::Bank::MaybankCambodia::WebApi < Tneakearyon::Bank::MaybankCambodia::Api
  BASE_API_ENDPOINT = 'https://www.maybank2u.com.kh/RIB'

  WHITELISTED_COOKIE_NAMES = ["M2UMCI", "PMData"]

  PAGE_ELEMENTS = {
    :login_form_name => "ibLoginForm",
    :login_token_input_name => "org.apache.struts.taglib.html.TOKEN"
  }

  attr_accessor :username, :password, :cookies, :login_token, :encryption_key

  def initialize(params = {})
    self.username = params[:username]
    self.password = params[:password]
  end

  def login!
    get_login_response = HTTParty.get(login_endpoint, :headers => set_headers)
    set_cookies(get_login_response)

    get_portal_access_response = HTTParty.get(ib_portal_access_endpoint, :headers => set_headers)
    html = parse_html_response(get_portal_access_response.body)
    set_login_token(html)
    set_encryption_key(html)
    set_cookies(get_portal_access_response)

    post_username_response = HTTParty.post(
      ib_login_endpoint,
      :body => set_login_details_body,
      :headers => set_headers
    )

    html = parse_html_response(post_username_response.body)
    set_login_token(html)
    set_cookies(post_username_response)

    post_password_response = HTTParty.post(
      ib_login_password_endpoint,
      :body => set_login_details_body(
        "password" => des_encrypt(password)
      ),
      :headers => set_headers
    )
  end

  def cookies
    @cookies ||= {}
  end

  private

  def set_login_details_body(params = {})
    {
      page_element(:login_token_input_name) => login_token,
      "userName" => des_encrypt(username),
    }.merge(params)
  end

  def page_element(key)
    PAGE_ELEMENTS[key]
  end

  def des_encrypt(value)
    des = OpenSSL::Cipher::Cipher.new("DES-ECB")
    des.encrypt
    des.key = encryption_key
    des.iv = ""
    des.padding = 1
    (des.update(value) + des.final).unpack('H*').first
  end

  def set_headers
    headers = {}
    cookie_string = cookies.map {|k ,v| "#{k}=#{v}" }.join("; ")
    headers.merge!("cookie" => cookie_string) if !cookie_string.empty?
    headers
  end

  def set_cookies(response)
    raw_cookies = response.headers["set-cookie"]
    whitelisted_cookie_names.each do |whitelisted_cookie_name|
      value = (/#{whitelisted_cookie_name}=(.+?);/.match(raw_cookies) || [])[1]
      (self.cookies[whitelisted_cookie_name] = value) if value
    end
  end

  def whitelisted_cookie_names
    WHITELISTED_COOKIE_NAMES
  end

  def login_endpoint
    api_endpoint('/common/Login.do')
  end

  def ib_portal_access_endpoint
    api_endpoint('/ib101/ibPortalAccess.do')
  end

  def ib_login_endpoint
    api_endpoint('/ib101/ibLogin.do')
  end

  def ib_login_password_endpoint
    api_endpoint('/ib101/ibLoginPassword.do')
  end

  def api_endpoint(path)
    base_api_endpoint + path
  end

  def base_api_endpoint
    BASE_API_ENDPOINT
  end

  def parse_html_response(response_body)
    Nokogiri::HTML(response_body)
  end

  def set_login_token(html)
    self.login_token = (html.at_xpath(".//form[@name='#{page_element(:login_form_name)}']/input[@name='#{page_element(:login_token_input_name)}']") || {})["value"]
  end

  def set_encryption_key(html)
    script = html.xpath(".//script[contains(., 'setValue')]").text
    script =~ /setValue\(\"(.+)\"\)/
    self.encryption_key = $~[1][4..11]
  end
end

# maybank = Tneakearyon::Bank::MaybankCambodia::WebApi.new(:username => "username", :password => "password")
# response = maybank.login!
# File.open("login_output.html", 'w') { |file| file.write(response.body) }
# html = Nokogiri::HTML(response.body)
