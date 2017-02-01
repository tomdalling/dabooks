#!/usr/bin/env ruby

require 'net/http'
require 'io/console'
require 'nokogiri'
require 'byebug'
require 'date'

LOGIN_FORM_URL = 'https://internetbanking.suncorpbank.com.au/'
LOGOUT_URL = 'https://internetbanking.suncorpbank.com.au/Logoff'
USER_AGENT = 'DabooksBot (+https://github.com/tomdalling/dabooks)'
ACCOUNTS_PATH = ARGV[1] || 'books/accounts.txt'
ACCOUNTS = File.read(ACCOUNTS_PATH)
  .each_line
  .map { |line| line.strip.split }

def enforce_absolute_url(uri, base)
  uri = URI(uri)
  if uri.relative?
    URI.join(base.to_s, uri.to_s)
  else
    uri
  end
end

class NetClient
  class RequestError < StandardError; end

  def initialize
    @cookies = {}
  end

  def get(uri, follow_redirects: false)
    response = request(:Get, uri)
    response = follow_redirects(response) if follow_redirects
    response
  end

  def follow_redirects(response)
    while response.code == '302'
      response = request(:Get, enforce_absolute_url(response['Location'], response.uri))
    end
    response
  end

  def post(uri, params={})
    request(:Post, uri, params)
  end

  def request(klass, uri, params={})
    uri = URI(uri)
    #puts "#{klass} #{uri.scheme}://#{uri.host}#{uri.path}"
    request = Net::HTTP.const_get(klass).new(uri)
    request.set_form_data(params) unless params.empty?
    set_headers(request)

    opts = [uri.hostname, uri.port, { use_ssl: true }]
    response = Net::HTTP.start(*opts) do |http|
      http.request(request)
    end

    if response_successfull?(response)
      merge_response(response)
      #puts response.code.inspect
      response
    else
      raise(RequestError, response)
    end
  end

  private

    def set_headers(request)
      request['User-Agent'] = USER_AGENT

      unless @cookies.empty?
        request['Cookie'] = @cookies
          .map{ |k,v| "#{k}=#{v}" }
          .join('; ')
      end
    end

    def merge_response(response)
      @cookies = (response.get_fields('set-cookie') || [])
        .map(&method(:parse_cookie))
        .reduce(@cookies.dup, :merge)
    end

    def parse_cookie(cookie)
      name, _, rest = cookie.partition('=')
      value = rest.include?(';') ? rest.partition(';').first : rest
      { name => value }
    end

    def response_successfull?(response)
      code = response.code.to_i
      (200 <= code && code <= 399)
    end
end

def aus_date(date)
  date.strftime('%d/%m/%Y')
end

def download_account(client, session_id, account_no, account_name, from_date)
  search_uri = "https://internetbanking.suncorpbank.com.au/#{session_id}/TransactionHistory/Search"
  client.post(search_uri, {
    'SearchType' => 'Quick',
    'AccountNumber' => account_no.to_s,
    'PeriodType' => 'ByDate',
    'FromDate' => aus_date(from_date),
    'ToDate' => aus_date(Date.today),
    'Order' => 'Ascending',
  })

  download_uri = "https://internetbanking.suncorpbank.com.au/#{session_id}/TransactionHistoryDownload/Options"
  response = client.post(download_uri, {
    'downloadFormatName' => 'Ofx',
    'downloadDateFormat' => 'dd/MM/yyyy',
    'onlyCurrentPage' => 'False',
  })

  File.write(account_name + '.ofx', response.body)
  puts "Downloaded #{account_name}.ofx"
end

def extract_login_uri(response)
  page = Nokogiri::HTML(response.body)
  form = page.css('form').find { |el| el['name'] == 'Logon' }
  fail "!!! Can't find login form" unless form

  enforce_absolute_url(form['action'], response.uri)
end

def login(client)
  #find the login form
  form_response = client.get(LOGIN_FORM_URL, follow_redirects: true)
  login_url = extract_login_uri(form_response)

  #get the username/password
  print 'Customer ID: '
  customer_id = gets.strip
  print 'Password: '
  password = STDIN.noecho(&:gets).strip
  puts

  #login
  login_response = client.follow_redirects(client.post(login_url, {
    'username' => customer_id,
    'password' => password,
    'passcode' => '',
  }))

  if login_response.code == '200'
    login_response.uri.to_s[%r{/([A-Z0-9]+)/Accounts}, 1]
  else
    p login_response
    File.write('failure.html', login_response.body)
    nil
  end
end

def get_from_date
  default = Date.today.prev_month(6)
  print "From what date? (default #{default.iso8601}): "
  input = gets.strip

  if input.empty?
    default
  else
    begin
      Date.iso8601(input)
    rescue ArgumentError
      puts "Invalid date"
      abort
    end
  end
end

def main
  from_date = get_from_date

  client = NetClient.new

  # do the login
  puts "Logging in..."
  session_id = login(client)
  unless session_id
    raise "!!! Failed to log in. See failure.html for more info."
  end

  #download accounts
  ACCOUNTS.each do |acc_no, acc_name|
    download_account(client, session_id, acc_no, acc_name, from_date)
  end

  #logout
  puts("Logging out...")
  client.post(LOGOUT_URL)

  puts "Done. Now you might want to..."
  puts "  bundle exec bin/dabooks suncorp *.ofx > books/new_transactions.book"
end

main if __FILE__ == $0
