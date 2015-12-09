require 'puppet'
require 'puppet/face'
require 'json'
require 'net/http'
require 'openssl'
require 'puppet/network/http'
require 'puppet/network/http_pool'
require 'puppet/network/http/nocache_pool'
require 'uri'

Puppet::Face.define(:code_manager, '0.1.0') do
  description <<-DESCRIPTION
The code_manager face is used to interact with the code-manager service to
deploy environments.
DESCRIPTION
  summary "Used to work with the code-manager service to deploy environments"
  copyright "Puppet Labs", 2015
  author "puppetlabs"
  notes "No notes at this time."

  action :startall do
    summary "Start a deploy of all environments."

    post_body = {"deploy-all" => true}

    option '-w', '--wait' do
      summary "Wait for the code-manager service to return"
      default_to { false }
    end

    option '-s SERVER', '--cmserver SERVER' do
      summary "Code manager server name"
      default_to { nil }
    end

    option '-p PORT', '--cmport PORT' do
      summary "Code manager port on server"
      default_to { nil }
    end

    option '-t TOKENFILE', '--tokenfile TOKENFILE' do
      summary "File containing RBAC authorization token"
      default_to { nil }
    end

    option '-k', '--insecure' do
      summary "Allow insecure connections (assuming PE certs not added to root)"
      default_to { nil }
    end

    option '--ca_cert CA_CERT' do
      summary 'path to a ca certificate to add to default trust store'
      default_to { "/etc/puppetlabs/puppet/ssl/certs/ca.pem" }
    end

    when_invoked do |options|
      deploy_call = DeployCall.new(post_body, options)
      deploy_call.result()
    end
  end

  action :start do
    summary "Start a deploy of one environment"
    arguments "<environment>"

    post_body = {}

    option '-w', '--wait' do
      summary "Wait for the code-manager service to return."
      default_to { false }
    end

    option '-s SERVER', '--cmserver SERVER' do
      summary "Code manager server name"
      default_to { nil }
    end

    option '-p PORT', '--cmport PORT' do
      summary "Code manager port on server"
      default_to { nil }
    end

    option '-t TOKENFILE', '--tokenfile TOKENFILE' do
      summary "File containing RBAC authorization token"
      default_to { nil }
    end

    option '-k', '--insecure' do
      summary "Allow insecure connections (assuming PE certs not added to root)"
      default_to { nil }
    end

    option '--ca_cert CA_CERT' do
      summary 'path to a ca certificate to add to default trust store'
      default_to { "/etc/puppetlabs/puppet/ssl/certs/ca.pem" }
    end

    when_invoked do |environment, options|
      post_body["environments"] = [ environment ]
      deploy_call = DeployCall.new(post_body, options)
      deploy_call.result()
    end
  end
end

# Class to actually do the deploy call across multiple actions
class DeployCall
  DEFAULT_CODE_MANAGER_PORT = 8170
  CODE_MANAGER_PATH = "code-manager/v1/deploys"

  def initialize(post_body, options)
    @post_body = post_body
    if options[:wait]
      @post_body[:wait] = true
    end

    token_file = options[:tokenfile] || File.join(Dir.home, '.puppetlabs', 'token')

    if File.file?(token_file)
      token = File.read(token_file).gsub(/\n+/,'')
    else
      raise "Token file does not exist or is not readable."
    end

    if options[:insecure]
      @cert_store = nil
    else
      @cert_store = get_store(options[:ca_cert])
    end

    Puppet.settings.preferred_run_mode = "agent"
    code_manager_host = options[:cmserver] || Puppet[:server]
    code_manager_port = options[:cmport] || DEFAULT_CODE_MANAGER_PORT

    @code_manager_all = "https://#{code_manager_host}:#{code_manager_port}/#{CODE_MANAGER_PATH}?token=#{token}"
  end

  def get_store(ca_cert)
    cert_store = OpenSSL::X509::Store.new
    cert_store.set_default_paths
    if File.file?(ca_cert)
      cert_store.add_file(ca_cert)
    else
      Puppet.warning "Could not load ca_certificate #{ca_cert} using default store"
    end
    cert_store
  end

  def result()
    uri = URI(@code_manager_all)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'
    if uri.scheme == 'https'
      http.use_ssl = true
      if @cert_store
        http.cert_store = @cert_store
      else
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' =>'application/json'})
    request.body = @post_body.to_json
    begin
      response = http.request(request)
    rescue Exception => e
      raise "Request to #{@code_manager_all} failed: #{e}"
    end

    begin
      JSON.pretty_generate(JSON.parse(response.body))
    rescue Exception
      raise "Could not parse response body: #{response.body}"
    end
  end
end
