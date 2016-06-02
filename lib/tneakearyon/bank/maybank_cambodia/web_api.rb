require 'nokogiri'
require 'byebug' # REMOVE ME
require 'rack/utils'

class Tneakearyon::Bank::MaybankCambodia::WebApi < Tneakearyon::Bank::MaybankCambodia::Api
  API_BASE_ENDPOINT        = 'https://www.maybank2u.com.kh'

  API_PORTAL_ACCESS_PATH   = '/RIB/ib101/ibPortalAccess.do'
  API_LOGIN_PATH           = '/RIB/ib101/ibLogin.do'
  API_LOGIN_PASSWORD_PATH  = '/RIB/ib101/ibLoginPassword.do'
  API_ACCOUNT_SUMMARY_PATH = '/RIB/ib102/ibAccountSummary.do'
  API_ACCOUNT_INFO_PATH    = '/RIB/ib102/ibAccountInfo.do'

  PAGE_ELEMENTS = {
    :login_token_input_name             => "org.apache.struts.taglib.html.TOKEN",
    :login_name                         => "logdetailsbold",
    :account_number_query_string_param  => "acctNo"
  }

  WHITELISTED_COOKIE_NAMES = ["M2UMCI"]

  attr_accessor :username, :password, :account_details,
                :cookies, :login_token, :encryption_key, :ib_links

  def initialize(params = {})
    self.username = params[:username]
    self.password = params[:password]
  end

  def fetch_account_details!
    return account_details if logged_in?
    login_response = login!

    html = parse_html_response(login_response.body)

    self.account_details ||= {}
    set_login_details(html)

    self.ib_links ||= {}
    set_ib_link_account_summary(html)

    fetch_account_summary!

    account_details
  end

  private

  def logged_in?
    !!account_details && !account_details.empty?
  end

  def login!
    setup_session!
    post_username!
    post_password!
  end

  def setup_session!
    response = HTTParty.get(ib_portal_access_endpoint)
    set_cookies(response)
    html = parse_html_response(response.body)
    set_login_token(html)
    set_encryption_key(html)
  end

  def post_username!
    HTTParty.post(
      ib_login_endpoint,
      :body => set_login_request_body,
      :headers => set_headers
    )
  end

  def post_password!
    HTTParty.post(
      ib_login_password_endpoint,
      :body => set_login_request_body(
        "password" => des_encrypt(password)
      ),
      :headers => set_headers
    )
  end

  def set_ib_link_account_summary(html)
    ib_links[:account_summary] ||= html.at_xpath("//a[contains(@href, '#{API_ACCOUNT_SUMMARY_PATH}')]")["href"]
  end

  def fetch_account_summary!
    accounts = self.account_details[:accounts] ||= {}

    response = HTTParty.get(api_endpoint(ib_links[:account_summary]), :headers => set_headers)
    html = parse_html_response(response.body)

    account_info_link_xpath = "//a[contains(@href, '#{API_ACCOUNT_INFO_PATH}')]"

    html.at_xpath(account_info_link_xpath).ancestors("tbody").first.search("tr").each do |row|
      account_number = Rack::Utils.parse_query(URI.parse(row.at_xpath(account_info_link_xpath)["href"]).query)[page_element(:account_number_query_string_param)]
      columns = row.search("td")
      accounts[account_number] = {
        :number => account_number,
        :current_balance => Monetize.parse(columns[1].text),
        :available_balance => Monetize.parse(columns[2].text)
      }
    end
  end

  def set_login_details(html)
    self.account_details[:login_name] = html.at_xpath("//*[contains(@class, '#{page_element(:login_name)}')]").text
  end

  def set_login_request_body(params = {})
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
    self.cookies ||= {}
    raw_cookies = response.headers["set-cookie"]
    whitelisted_cookie_names.each do |whitelisted_cookie_name|
      value = (/#{whitelisted_cookie_name}=(.+?);/.match(raw_cookies) || [])[1]
      (self.cookies[whitelisted_cookie_name] = value) if value
    end
  end

  def whitelisted_cookie_names
    WHITELISTED_COOKIE_NAMES
  end

  def ib_portal_access_endpoint
    api_endpoint(API_PORTAL_ACCESS_PATH)
  end

  def ib_login_endpoint
    api_endpoint(API_LOGIN_PATH)
  end

  def ib_login_password_endpoint
    api_endpoint(API_LOGIN_PASSWORD_PATH)
  end

  def api_endpoint(path)
    api_base_endpoint + path
  end

  def api_base_endpoint
    API_BASE_ENDPOINT
  end

  def parse_html_response(response_body)
    Nokogiri::HTML(response_body)
  end

  def set_login_token(html)
    self.login_token = (html.at_xpath(".//input[@name='#{page_element(:login_token_input_name)}']") || {})["value"]
  end

  def set_encryption_key(html)
    script = html.xpath(".//script[contains(., 'setValue')]").text
    script =~ /setValue\(\"(.+)\"\)/
    self.encryption_key = $~[1][4..11]
  end
end

# maybank = Tneakearyon::Bank::MaybankCambodia::WebApi.new(:username => "username", :password => "password")
# maybank.fetch_account_details!
# File.open("login_output.html", 'w') { |file| file.write(response.body) }
# html = Nokogiri::HTML(response.body)
