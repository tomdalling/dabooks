#!/usr/bin/env ruby

require 'net/http'
require 'io/console'

LOGIN_FORM_URL = 'https://internetbanking.suncorpbank.com.au/Logon'
LOGIN_URL = 'https://internetbanking.suncorpbank.com.au/'
LOGOUT_URL = 'https://internetbanking.suncorpbank.com.au/Logoff'
USER_AGENT = 'DabooksBot (+https://github.com/tomdalling/dabooks)'
ACCOUNTS_PATH = ARGV[1] || 'books/accounts.txt'
ACCOUNTS = File.read(ACCOUNTS_PATH)
  .each_line
  .map { |line| line.strip.split }

class NetClient
  class RequestError < StandardError; end

  def initialize
    @cookies = {}
  end

  def get(uri)
    request(:Get, uri)
  end

  def post(uri, params={})
    request(:Post, uri, params)
  end

  def request(klass, uri, params={})
    uri = URI(uri)
    request = Net::HTTP.const_get(klass).new(uri)
    request.set_form_data(params) unless params.empty?
    set_headers(request)

    opts = [uri.hostname, uri.port, { use_ssl: true }]
    response = Net::HTTP.start(*opts) do |http|
      http.request(request)
    end

    if response_successfull?(response)
      merge_response(response)
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

def get_session_id(login_response)
end

def download_account(client, session_id, account_no, account_name)
  search_uri = "https://internetbanking.suncorpbank.com.au/#{session_id}/TransactionHistory/Search"
  client.post(search_uri, {
    'SearchType' => 'Quick',
    'AccountNumber' => account_no.to_s,
    'PeriodType' => 'Last180Days',
    'FromDate' => '',
    'ToDate' => '',
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

def login(client)
  print 'Customer ID: '
  customer_id = gets.strip
  print 'Password: '
  password = STDIN.noecho(&:gets).strip
  puts

  #login
  login_response = client.post(LOGIN_URL, {
    'UserId' => customer_id,
    'Password' => password,
    'TokenCode' => '',
  })

  if login_response.code == '302'
    login_response['Location'][%r{/([A-Z0-9]+)/Accounts}, 1]
  else
    p login_response
    File.write('failure.html', login_response.body)
    nil
  end
end

def main
  client = NetClient.new

  # get all the cookies
  puts "Making a session..."
  client.get(LOGIN_FORM_URL)

  # do the login
  puts "Logging in..."
  session_id = login(client)
  raise "!!! Failed to log in. See failure.html for more info." unless session_id

  #download accounts
  ACCOUNTS.each do |acc_no, acc_name|
    download_account(client, session_id, acc_no, acc_name)
  end

  #logout
  puts("Logging out...")
  client.post(LOGOUT_URL)

  puts "Done. Now you might want to..."
  puts "  bundle exec bin/dabooks suncorp *.ofx > books/new_transactions.book"
end

main if __FILE__ == $0
