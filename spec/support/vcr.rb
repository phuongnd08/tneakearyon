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

  c.filter_sensitive_data("JOE BLOGGS") do |interaction|
    (/logdetailsbold.+\>(.+?)\</.match(interaction.response.body) || [])[1]
  end
end

