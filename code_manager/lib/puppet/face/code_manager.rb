Puppet::Face.define(:code_manager, '0.0.1') do
  description <<-DESCRIPTION
The code_manager face is used to interact with the code-manager service.
DESCRIPTION
  summary "Used to work with the code-manager service"
  copyright "Puppet Labs", 2015
  author "puppetlabs"
  notes "There is a lot to say about code-manager."
  # ...
  action :start do
    summary "Start a deploy"
    arguments "<environment>"

    option '--all' do
      summary "Start a deploy of all environments."
      default_to { false }
    end

    option '--wait' do
      summary "Wait for the code-manager service to return."
      default_to { false }
    end

    when_invoked do |options|
      #[...]
      if options[:all]
        puts "invoked with all"
      end
      if options[:wait]
        puts "invoked with wait"
      end
      token = File.read( File.join(Dir.home, '.puppetlabs', 'token'))
      "code-manager start #{options} and token = #{token}"
    end
  end
end
