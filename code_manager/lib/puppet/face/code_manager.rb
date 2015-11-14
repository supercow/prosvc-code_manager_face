require 'puppet'
require 'puppet/face'
require 'tzinfo'
require 'json'

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
    when_invoked do |options|
      "code-manager startall"
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
      token = File.read( File.join(Dir.home, '.puppetlabs', 'token'))
      tz = TZInfo::Timezone.get('America/New_York')
      url = "http://graynoise.konfuzo.net/nobody.txt"
      cl_output = `curl -sS #{url}`
      "code-manager start #post_data = #{JSON.generate post_data} \n and cl_output = #{cl_output} \n and now = #{tz.now} \n and token = #{token}"
    end
  end
end
