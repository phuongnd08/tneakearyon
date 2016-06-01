require 'nokogiri'
require 'byebug' # REMOVE ME

class Tneakearyon::Bank::MaybankCambodia::WebApi < Tneakearyon::Bank::MaybankCambodia::Api
  BASE_API_ENDPOINT = 'https://www.maybank2u.com.kh/RIB'

  PAGE_ELEMENTS = {
    :login_form_name => "ibLoginForm",
    :login_token_input_name => "org.apache.struts.taglib.html.TOKEN"
  }

  attr_accessor :username, :password, :cookie, :login_token, :encryption_key

  def initialize(params = {})
    self.username = params[:username]
    self.password = params[:password]
  end

  def login!
    get_login_response = HTTParty.get(login_endpoint, :headers => set_headers)
    set_cookies(get_login_response)
    get_portal_access_response = HTTParty.get(ib_portal_access_endpoint, :headers => set_headers)
    set_cookies(get_portal_access_response)
    parse_html_response(get_portal_access_response.body)
    post_username_response = HTTParty.post(
      ib_login_endpoint,
      :body => {
        page_element(:login_token_input_name) => login_token,
        "userName" => des_encrypt(username)
      },
      :headers => set_headers
    )
  end

  private

  def page_element(key)
    PAGE_ELEMENTS[key]
  end

  def des_encrypt(value)
    des = OpenSSL::Cipher::Cipher.new("DES-ECB")
    des.encrypt
    des.padding = 1
    des.key = encryption_key
    des.update(value)
    des.final.unpack('H*').first
  end

  def set_headers
    headers = {}
    headers.merge!("cookie" => cookie) if cookie
    headers
  end

  def set_cookies(response)
    self.cookie = response.headers["set-cookie"]
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

  def api_endpoint(path)
    base_api_endpoint + path
  end

  def base_api_endpoint
    BASE_API_ENDPOINT
  end

  def parse_html_response(response_body)
    html = Nokogiri::HTML(response_body)
    set_login_token(html)
    set_encryption_key(html)
  end

  def set_login_token(html)
    self.login_token = html.at_xpath(".//form[@name='#{page_element(:login_form_name)}']/input[@name='#{page_element(:login_token_input_name)}']")["value"]
  end

  def set_encryption_key(html)
    script = html.xpath(".//script[contains(., 'setValue')]").text
    script =~ /setValue\(\"(.+)\"\)/
    self.encryption_key = $~[1][4..11]
  end
end

# maybank = Tneakearyon::Bank::MaybankCambodia::WebApi.new(:username => "login_name")
# response = maybank.login!
# File.open("login_output.html", 'w') { |file| file.write(response.body) }
# html = Nokogiri::HTML(response.body)
