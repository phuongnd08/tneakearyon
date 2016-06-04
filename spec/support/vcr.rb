require 'vcr'

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'

  c.filter_sensitive_data('<REQUEST_BODY>') do |interaction|
    interaction.request.body
  end

  c.filter_sensitive_data('<Cookie>') do |interaction|
    cookie = interaction.request.headers["Cookie"]
    cookie && cookie.first
  end

  c.filter_sensitive_data("<set-cookie>") do |interaction|
    set_cookie = interaction.response.headers["Set-Cookie"]
    set_cookie && set_cookie.first
  end

  filtered_data_regexp = /^TNEAKEARYON_TEST_FILTERED_DATA_/

  ENV.select { |key, value| key =~ filtered_data_regexp }.each do |key, value|
    filter_name = key.sub(filtered_data_regexp, "")
    c.filter_sensitive_data("<FILTERED_#{filter_name}>") do |interaction|
      value
    end
  end
end
