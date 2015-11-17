require 'spec_helper'
describe 'code_manager_face' do

  context 'with defaults for all parameters' do
    it { should contain_class('code_manager_face') }
  end
end
