require 'spec_helper'

describe OmniAuth::Strategies::Idq do
  subject do
    OmniAuth::Strategies::Idq.new({})
  end

  context "client options" do
    it 'should have correct name' do
      subject.options.name.should eq("idq")
    end

    it 'should have correct site' do
      subject.options.client_options.site.should eq('https://taas.idquanta.com')
    end

    it 'should have correct authorize url' do
      subject.options.client_options.authorize_path.should eq('/idqoauth/api/v1/auth)
    end
  end
end
