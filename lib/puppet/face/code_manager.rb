require 'puppet'
require 'puppet/face'
require 'json'
require 'puppet/network/http/connection'
require 'net/http'
require 'uri'

Puppet::Face.define(:code_manager, '0.0.1') do
  description <<-DESCRIPTION
The code_manager face is used to interact with the code-manager service.
DESCRIPTION
  summary "Used to work with the code-manager service"
  copyright "Puppet Labs", 2015
  author "puppetlabs"
  notes "There is a lot to say about code-manager."
  # ...

  action :startall do
    summary "Start a deploy of all environments."

    post_data = {:all => true}

    option '-w', '--wait' do
      summary "Wait for the code-manager service to return."
      default_to { false }
    end

    option '-s SERVER', '--cmserver SERVER' do
      summary "Code manager server name"
      default_to {  }
    end

    option '-p PORT', '--cmport PORT' do
      summary "Code manager port on server"
      default_to { nil }
    end


    when_invoked do |options|
      #[...]
      if options[:wait]
        post_data [:wait] = true
      end
      deploy_call = DeployCall.new(post_data)
      deploy_call.result
    end
  end

  action :start do
    summary "Start a deploy of one environment"
    arguments "<environment>"

    post_data = {}

    option '--wait' do
      summary "Wait for the code-manager service to return."
      default_to { false }
    end

    when_invoked do |environment, options|
      #[...]
      if options[:wait]
        puts "invoked with wait"
        post_data [:wait] = true
      end
      if environment
        puts "invoked with enivronment #{environment}"
        post_data [:environments] = [ environment ]
      end
      deploy_call = DeployCall.new(post_data)
      deploy_call.result

    end
  end
end

class DeployCall
  def initialize(post_data, server = nil, port = nil)
    Puppet.settings.preferred_run_mode = "master"
    @post_data = post_data
    @token = File.read( File.join(Dir.home, '.puppetlabs', 'token')).chop
    @code_manager_host = 'localhost'
    @code_manager_port = 8170
    @code_manager_path = "code-manager/v1/deploys"
    #@code_manager_all = "http://#{@code_manager_host}:#{@code_manager_port}/#{@code_manager_path}"
    @code_manager_all = "http://#{@code_manager_host}:#{@code_manager_port}/#{@code_manager_path}?token=#{@token}"
    #@code_manager_host = 'graynoise.konfuzo.net'
    #@code_manager_port = 80
    #@code_manager_path = 'nobody.txt'
    require 'pry'; binding.pry
    @uri = URI(@code_manager_all)
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @request = Net::HTTP::Post.new(@uri.request_uri, {'Content-Type' =>'application/json'})
    @request.body = @post_data.to_json
    #@request.body = JSON.generate(@post_data)
    #@request.body = '{"environments":["production"]}'
    @response = @http.request(@request)
    #@response = Net::HTTP.post_form(@uri, 'token' => @token, 'body' => JSON.generate(@post_data))
    #@uri.query = URI.encode_www_form(
    #@http = Net::HTTP.new(@uri.host, @uri.port)
    #@request = Net::HTTP::Post.new(@uri.path, 'token' => @token)
    #@request["token"] = @token
    #@response = @http.post(@uri.path, JSON.generate(@post_data))
  end

  def result
      "\n code-manager start #post_data = #{JSON.generate @post_data} \n"\
        " and code_manager_all = #{@code_manager_all} \n"\
        " and uri.path = #{@uri.path} \n"\
        " and response = #{@response.body} \n"\
        " and Puppet[:ca_server] = #{Puppet[:ca_server]}"
        #" and token = #{@token}"
  end
end
