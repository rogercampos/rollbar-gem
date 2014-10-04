require 'spec_helper'

describe HomeController do
  let(:logger_mock) { double("Rails.logger").as_null_object }

  before(:each) do
    reset_configuration
    Rollbar.configure do |config|
      config.access_token = 'bfec94a1ede64984b862880224edd0ed'
      config.environment = ::Rails.env
      config.root = ::Rails.root
      config.framework = "Rails: #{::Rails::VERSION::STRING}"
      config.logger = logger_mock
      config.request_timeout = 60
    end
  end

  context "with broken request" do
    it "should report uncaught exceptions" do
      # only seems to be relevant in 3.1 and 3.2
      if ::Rails::VERSION::STRING.starts_with? "3.1" or ::Rails::VERSION::STRING.starts_with? "3.2"
        expect{ get 'current_user', nil, :cookie => '8%B' }.to raise_exception

        Rollbar.last_report.should_not be_nil

        exception_info = Rollbar.last_report[:body][:trace][:exception]
        exception_info[:class].should == 'ArgumentError'
        exception_info[:message].should == 'invalid %-encoding (8%B)'
      end
    end
  end

  context "with error hiding deep inside" do
    let!(:cookie_method_name){ :[] }
    let!(:original_cookie_method){ ActionDispatch::Cookies::CookieJar.instance_method(cookie_method_name) }
    let!(:broken_cookie_method){ Proc.new{ |name| "1" - 1 } }

    it "should report uncaught exceptions" do
      ActionDispatch::Cookies::CookieJar.send(:define_method, cookie_method_name, broken_cookie_method)
      get 'current_user'
      response.status.should == 500
      ActionDispatch::Cookies::CookieJar.send(:define_method, cookie_method_name, original_cookie_method)

      body = Rollbar.last_report[:body]
      trace = body[:trace] && body[:trace] || body[:trace_chain][0]

      trace[:exception][:class].should == 'NoMethodError'
      trace[:exception][:message].should == 'undefined method `-\' for "1":String'
    end
  end
end
