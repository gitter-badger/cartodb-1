require_relative '../../../spec_helper'
require_relative '../../../factories/users_helper'

describe Carto::Editor::VisualizationsController do
  include Warden::Test::Helpers

  include_context 'users helper'

  describe '#show' do
    before(:each) do
      @visualization = FactoryGirl.create(:carto_visualization, user: Carto::User.find(@user1.id))
      Carto::Api::VizJSONPresenter.any_instance.stubs(:to_vizjson).returns({ id: @visualization.id }.to_json)

      @user1.stubs(:has_feature_flag?).with('editor-3').returns(true)

      login(@user1)
    end

    it 'returns 404 for non-editor users requests' do
      @user1.stubs(:has_feature_flag?).with('editor-3').returns(false)

      get editor_visualization_url(id: @visualization.id)

      response.status.should == 404
    end

    it 'returns 404 for non-existent visualizations' do
      get editor_visualization_url(id: UUIDTools::UUID.timestamp_create.to_s)

      response.status.should == 404
    end

    it 'returns 403 for visualizations not writable by user' do
      @other_visualization = FactoryGirl.create(:carto_visualization)

      get editor_visualization_url(id: @other_visualization.id)

      response.status.should == 404
    end

    it 'returns visualization' do
      get editor_visualization_url(id: @visualization.id)

      response.status.should == 200
      response.body.should include(@visualization.id)
    end

    it 'does not show raster kind visualizations' do
      @visualization.kind = Carto::Visualization::KIND_RASTER
      @visualization.save

      get editor_visualization_url(id: @visualization.id)

      response.status.should == 403
    end

    it 'does not show slide type visualizations' do
      @visualization.type = Carto::Visualization::TYPE_SLIDE
      @visualization.save

      get editor_visualization_url(id: @visualization.id)

      response.status.should == 403
    end
  end
end
