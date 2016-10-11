require 'nokogiri'
require 'rack/utils'
require 'httparty'

class Tneakearyon::Bank::MaybankCambodia::WebClient
  API_BASE_ENDPOINT                      = 'https://www.maybank2u.com.kh'

  API_PORTAL_ACCESS_PATH                 = '/RIB/ib101/ibPortalAccess.do'
  API_LOGIN_PATH                         = '/RIB/ib101/ibLogin.do'
  API_LOGIN_PASSWORD_PATH                = '/RIB/ib101/ibLoginPassword.do'
  API_ACCOUNT_SUMMARY_PATH               = '/RIB/ib102/ibAccountSummary.do'
  API_ACCOUNT_INFO_PATH                  = '/RIB/ib102/ibAccountInfo.do'
  API_THIRD_PARTY_TRANSFER_DETAILS_PATH  = '/RIB/ib104/ib3rdPartyTransferDetails.do'
  API_THIRD_PARTY_TRANSFER_CONFIRM_PATH  = '/RIB/ib104/ib3rdPartyTransferConfirm.do'
  API_THIRD_PARTY_TRANSFER_RESULTS_PATH  = '/RIB/ib104/ib3rdPartyTransferResults.do'
  API_TAC_REQUEST_PATH                   = '/RIB/ib106/ibTACRequest.do'

  PAGE_ELEMENTS = {
    :form_token_input_name              => "org.apache.struts.taglib.html.TOKEN",
    :login_name                         => "logdetailsbold",
    :account_number_query_string_param  => "acctNo",
    :secondary_token_query_string_param => "SECONDARY_TOKEN",
    :server_side_error                  => "serverSideError"
  }

  WHITELISTED_COOKIE_NAMES = ["M2UMCI"]

  attr_accessor :username, :password, :login_details, :bank_accounts,
                :cookies, :html_response, :form_token, :encryption_key, :secondary_token,
                :response_error

  def initialize(params = {})
    self.username = params[:username] || ENV["TNEAKEARYON_BANK_MAYBANK_CAMBODIA_WEB_CLIENT_USERNAME"]
    self.password = params[:password] || ENV["TNEAKEARYON_BANK_MAYBANK_CAMBODIA_WEB_CLIENT_PASSWORD"]
  end

  def inspect
    "#{self.to_s} @login_details=#{login_details.inspect}"
  end

  def fetch_login_details!
    login! if !logged_in?
    login_details
  end

  def fetch_bank_accounts!
    login! if !logged_in?
    fetch_account_summary!
    bank_accounts
  end

  def execute_third_party_transfer!(options = {})
    default_from_account = ENV["TNEAKEARYON_BANK_MAYBANK_CAMBODIA_DEFAULT_TRANSFER_FROM_ACCOUNT_NUMBER"]
    options[:from_account] ||= default_from_account if default_from_account
    raise(ArgumentError, "You must pass :from_account, :to_account, :amount and :tac") if !options.has_key?(:from_account) || !options.has_key?(:to_account) || !options.has_key?(:amount) || !options.has_key?(:tac)
    login! if !logged_in?
    get_third_party_transfer_details!
    transfer_confirmation = post_third_party_transfer_confirm!(options)
    if response_error
      transfer_confirmation
    else
      transfer_result = post_third_party_transfer_results!(options)
      transfer_confirmation.merge(transfer_result)
    end
  end

  def request_tac!
    login! if !logged_in?
    do_request_tac!
  end

  private

  def parse_url_query_string(url)
    Rack::Utils.parse_query(URI.parse(url).query)
  end

  def logged_in?
    !!login_name
  end

  def login_name
    (login_details || {})[:name]
  end

  def login!
    setup_session!
    post_username!
    post_password!
    self.login_details ||= {}
    self.login_details[:name] = extract_login_name!
  end

  def extract_login_name!
    if page_element = html_response.at_xpath("//*[contains(@class, '#{page_element(:login_name)}')]")
      page_element.text
    else
      raise(RuntimeError, "Unable to login. Check credentials")
    end
  end

  def do_request_tac!
    set_html_response(
      HTTParty.get(
        ib_tac_request_endpoint,
        :headers => build_headers
      )
    )
  end

  def get_third_party_transfer_details!
    set_html_response(
      HTTParty.get(
        ib_third_party_transfer_details_endpoint,
        :query => {
          page_element(:secondary_token_query_string_param) => secondary_token,
          "transferType" => "open"
        },
        :headers => build_headers
      )
    )
    self.secondary_token = set_form_token(html_response)
  end

  def post_third_party_transfer_confirm!(options = {})
    set_html_response(
      HTTParty.post(
        ib_third_party_transfer_confirm_endpoint,
        :body => build_third_party_transfer_request_body(options),
        :headers => build_headers
      )
    )
    error_element = html_response.at_xpath("//*[@id='#{page_element(:server_side_error)}']")
    error_message = error_element && error_element.text.strip

    if error_message && !error_message.empty?
      self.response_error = true
      {:error_message => error_message}
    else
      self.secondary_token = set_form_token(html_response)
      extract_transfer_details(options[:to_account])
    end
  end

  def post_third_party_transfer_results!(options = {})
    set_html_response(
      HTTParty.post(
        ib_third_party_transfer_results_endpoint,
        :body => build_third_party_transfer_results_body(options),
        :headers => build_headers
      )
    )
    extract_transfer_results(options[:to_account])
  end

  def extract_transfer_details(to_account_number)
    transfer_info = known_value_td(to_account_number).ancestors("table").children.search("tr")
    {
      :amount => Monetize.parse(table_value(transfer_info[0], 1)),
      :from_account_number => table_value(transfer_info[1], 1),
      :to_account_number => table_value(transfer_info[2], 1),
      :to_account_name => table_value(transfer_info[3], 1),
      :email => table_value(transfer_info[4], 1),
      :effective_date => Date.parse(table_value(transfer_info[5], 1))
    }
  end

  def extract_transfer_results(to_account_number)
    transfer_results = known_value_td(to_account_number).ancestors("table").children.search("table").children.search("tr")
    reason = table_value(transfer_results[1], 1)
    {
      :error_message => reason,
      :status => table_value(transfer_results[0], 1),
      :reason => reason,
      :reference_number => table_value(transfer_results[2], 1),
      :transfer_date => Date.parse(table_value(transfer_results[3], 1)),
      :transfer_time => Time.parse(table_value(transfer_results[4], 1))
    }
  end

  def known_value_td(known_value)
    html_response.at_xpath("//td[contains(., '#{known_value}')]")
  end

  def table_value(row, column)
    row.children.search("td")[column].text.strip
  end

  def build_third_party_transfer_results_body(options = {})
    build_request_body.merge(
      "tacValue" => options[:tac_value]
    )
  end

  def build_third_party_transfer_request_body(options = {})
    body = build_request_body
    body.merge!(
      "fromAcct" => options[:from_account],
      "toAcct" => options[:to_account],
      "amount" => options[:amount].to_s
    )

    effective_date = Date.parse(((options[:effective_date] && options[:effective_date]) || Date.today).to_s)
    body.merge!("effectiveDate" => effective_date.strftime("%Y%m%d"))
    body.merge!("email" => options[:email]) if options[:email]
    body
  end

  def build_request_body
    {
      page_element(:secondary_token_query_string_param) => secondary_token,
      page_element(:form_token_input_name) => secondary_token
    }
  end

  def setup_session!
    response = HTTParty.get(ib_portal_access_endpoint)
    set_cookies(response)
    html = parse_html_response(response.body)
    set_form_token(html)
    set_encryption_key(html)
  end

  def post_username!
    HTTParty.post(
      ib_login_endpoint,
      :body => set_login_request_body,
      :headers => build_headers
    )
  end

  def post_password!
    set_html_response(
      HTTParty.post(
        ib_login_password_endpoint,
        :body => set_login_request_body(
          "password" => des_encrypt(password)
        ),
        :headers => build_headers
      )
    )
  end

  def set_html_response(raw_response)
    self.html_response = parse_html_response(raw_response.body)
    reset_secondary_token
    html_response
  end

  def reset_secondary_token
    if page_element = html_response.at_xpath("//a[contains(@href, '#{page_element(:secondary_token_query_string_param)}')]")
      self.secondary_token = parse_url_query_string(
        page_element["href"]
      )[page_element(:secondary_token_query_string_param)]
    end
  end

  def fetch_account_summary!
    self.bank_accounts = []
    account_summary_path = html_response.at_xpath("//a[contains(@href, '#{API_ACCOUNT_SUMMARY_PATH}')]")["href"]

    set_html_response(
      HTTParty.get(api_endpoint(account_summary_path), :headers => build_headers)
    )

    account_info_link_xpath = "//a[contains(@href, '#{API_ACCOUNT_INFO_PATH}')]"

    html_response.at_xpath(account_info_link_xpath).ancestors("tbody").first.search("tr").each do |row|
      account_number = parse_url_query_string(row.at_xpath(account_info_link_xpath)["href"])[page_element(:account_number_query_string_param)]
      self.bank_accounts << {
        :number => account_number,
        :current_balance => Monetize.parse(table_value(row, 1)),
        :available_balance => Monetize.parse(table_value(row, 2))
      }
    end

    bank_accounts
  end

  def set_login_request_body(params = {})
    {
      page_element(:form_token_input_name) => form_token,
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

  def build_headers
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

  def ib_third_party_transfer_details_endpoint
    api_endpoint(API_THIRD_PARTY_TRANSFER_DETAILS_PATH)
  end

  def ib_third_party_transfer_confirm_endpoint
    api_endpoint(API_THIRD_PARTY_TRANSFER_CONFIRM_PATH)
  end

  def ib_third_party_transfer_results_endpoint
    api_endpoint(API_THIRD_PARTY_TRANSFER_RESULTS_PATH)
  end

  def ib_tac_request_endpoint
    api_endpoint(API_TAC_REQUEST_PATH)
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

  def set_form_token(html)
    self.form_token = (html.at_xpath(".//input[@name='#{page_element(:form_token_input_name)}']") || {})["value"]
  end

  def set_encryption_key(html)
    script = html.xpath(".//script[contains(., 'setValue')]").text
    script =~ /setValue\(\"(.+)\"\)/
    self.encryption_key = $~[1][4..11]
  end
end

# maybank = Tneakearyon::Bank::MaybankCambodia::WebClient.new(:username => "username", :password => "password")
# maybank.fetch_account_details!
# response = maybank.transfer!(:from_account => "fromAccount", :to_account => "toAccount", :amount => Money.new(10000, "USD"), :email => "someone@gmail.com")
# File.open("login_output.html", 'w') { |file| file.write(maybank.html_response.to_s) }
# File.open("login_output.html", 'w') { |file| file.write(response.body) }
# html = Nokogiri::HTML(response.body)
