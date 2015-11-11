require 'spec_helper'
describe 'code_manager' do

  context 'with defaults for all parameters' do
    it { should contain_class('code_manager') }
  end
end
