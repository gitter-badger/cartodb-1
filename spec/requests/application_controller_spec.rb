# encoding: utf-8

require_relative '../spec_helper'
require_relative './http_authentication_helper'

describe ApplicationController do
  include HttpAuthenticationHelper

  # This filter should always be invoked if http_header_authentication is set,
  # tests are based in dashboard requests because of genericity.
  describe '#http_header_authentication' do
    def stub_load_common_data
      Admin::VisualizationsController.any_instance.stubs(:load_common_data).returns(true)
    end

    describe 'triggering' do
      it 'enabled if http_header_authentication is configured and header is sent' do
        stub_http_header_authentication_configuration
        ApplicationController.any_instance.expects(:http_header_authentication)
        get dashboard_url, {}, authentication_headers
      end

      it 'disabled if http_header_authentication is configured and header is not set' do
        stub_http_header_authentication_configuration
        ApplicationController.any_instance.expects(:http_header_authentication).never
        get dashboard_url, {}, {}
      end

      it 'disabled if http_header_authentication is not configured' do
        ApplicationController.any_instance.expects(:http_header_authentication).never
        get dashboard_url, {}, {}
        get dashboard_url, {}, authentication_headers
      end
    end

    describe 'email autentication' do
      before(:each) do
        stub_http_header_authentication_configuration(field: 'email')
      end

      it 'loads the dashboard for a known user email' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.email)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'does not load the dashboard for an unknown user email' do
        get dashboard_url, {}, authentication_headers('wadus@wadus.com')
        response.status.should == 302
      end

      it 'does not load the dashboard for a known user username' do
        get dashboard_url, {}, authentication_headers($user_1.username)
        response.status.should == 302
      end
    end

    describe 'username autentication configuration' do
      before(:each) do
        stub_http_header_authentication_configuration(field: 'username')
      end

      it 'loads the dashboard for a known user username' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.username)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'does not load the dashboard for an unknown user username' do
        get dashboard_url, {}, authentication_headers("unknownuser")
        response.status.should == 302
      end

      it 'does not load the dashboard for a known user id' do
        get dashboard_url, {}, authentication_headers($user_1.id)
        response.status.should == 302
      end
    end

    describe 'id autentication configuration' do
      before(:each) do
        stub_http_header_authentication_configuration(field: 'id')
      end

      it 'loads the dashboard for a known user id' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.id)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'does not load the dashboard for an unknown user id' do
        get dashboard_url, {}, authentication_headers(UUIDTools::UUID.timestamp_create.to_s)
        response.status.should == 302
      end

      it 'does not load the dashboard for a known user email' do
        get dashboard_url, {}, authentication_headers($user_1.email)
        response.status.should == 302
      end
    end

    describe 'auto autentication configuration' do
      before(:each) do
        stub_http_header_authentication_configuration(field: 'auto')
      end

      it 'loads the dashboard for a known user id' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.id)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'loads the dashboard for a known user username' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.username)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'loads the dashboard for a known user email' do
        stub_load_common_data
        get dashboard_url, {}, authentication_headers($user_1.email)
        response.status.should == 200
        response.body.should_not include("Login to Carto")
      end

      it 'does not load the dashboard for an unknown user id' do
        get dashboard_url, {}, authentication_headers(UUIDTools::UUID.timestamp_create.to_s)
        response.status.should == 302
      end

      it 'does not load the dashboard for an unknown user username' do
        get dashboard_url, {}, authentication_headers("unknownuser")
        response.status.should == 302
      end

      it 'does not load the dashboard for an unknown user email' do
        get dashboard_url, {}, authentication_headers("wadus@wadus.com")
        response.status.should == 302
      end
    end

    describe 'autocreation' do
      describe 'disabled' do
        before(:each) do
          stub_http_header_authentication_configuration(field: 'auto', autocreation: false)
        end

        it 'redirects to login for unknown emails' do
          get dashboard_url, {}, authentication_headers('unknown@company.com')
          response.status.should == 302
          follow_redirect!
          response.status.should == 200
          response.body.should include("Login to Carto")
        end
      end

      describe 'enabled' do
        before(:each) do
          stub_http_header_authentication_configuration(field: 'auto', autocreation: true)
        end

        it 'redirects to user creation for unknown emails' do
          get dashboard_url, {}, authentication_headers('unknown@company.com')
          response.status.should == 302
          response.location.should match /#{signup_http_authentication_path}/
        end

        # This behaviour allows recreation of deleted users. Related to next one.
        it 'redirects to user creation for unknown emails if there is another finished user creation for that user' do
          email = 'unknown@company.com'
          FactoryGirl.create(:user_creation, state: 'success', email: email)
          get dashboard_url, {}, authentication_headers(email)
          response.status.should == 302
          response.location.should match /#{signup_http_authentication_path}/
        end

        # This behaviour avoids filling `user_creations` table with failed repetitions because of polling.
        it 'returns 409 instead of redirecting to user creation if there is another user creation not finished for that email' do
          email = 'unknown2@company.com'
          FactoryGirl.create(:user_creation, state: 'enqueuing', email: email)
          get dashboard_url, {}, authentication_headers(email)
          response.status.should == 409
        end
      end
    end
  end
end
