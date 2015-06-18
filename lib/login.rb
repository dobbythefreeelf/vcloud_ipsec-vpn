require "vpnconfig/version"

module Vpnconfig
  class Login
    # TODO: When this is actually doing the API call as well should be able to stop saving the xml file and just return it instead
    def login(username)
      print "Enter Password for user #{username}: "
      password = STDIN.noecho(&:gets).chomp
      puts ''
      puts 'Getting connection string...'
      conn = get_conn_string(username, password)
      conn
    end

    def get_conn_string(username,password)
      begin
        uri = URI.parse("https://api.vcd.portal.skyscapecloud.com/api/sessions")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(uri.request_uri, { 'Accept' => 'application/*+xml;version=5.5' })
        request.basic_auth(username, password)
        response = http.request(request)
        auth = response['x-vcloud-authorization'].to_s
        if auth.nil? || auth.length != 44
          puts "there is something wrong with the auth token: #{auth}"
        end
      rescue Exception => e
        puts "Error getting auth Token"
        puts e
      end
      doc = Nokogiri::XML(response.body)
      session = doc.at('Session')
      org_href = session.at('Link[@type="application/vnd.vmware.vcloud.org+xml"]')['href']
      return { "auth_token" => auth, "org_url" => org_href.to_s }
    end
  end
end
