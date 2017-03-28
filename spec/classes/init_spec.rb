require 'spec_helper'

describe 'windows_ad' do
  context 'with default values for all parameters' do
    let(:facts) do
      {
        kernelversion: '6.2',
        operatingsystem: 'windows',
      }
    end

    let(:params) do
      {
        installsubfeatures: false
      }
    end
    it { should contain_class('windows_ad') }
  end
end
