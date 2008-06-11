require File.dirname(__FILE__) + '/../spec_helper'

describe "Tagger" do
  before(:each) do
    [TaggableModel, Tag, Tagging, TaggableUser].each(&:delete_all)
    @user = TaggableUser.new
    @taggable = TaggableModel.new(:name => "Bob Jones")
  end
  
  it "should have taggings" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_taggings.size == 2
  end
  
  it "should have tags" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_tags.size == 2
  end
  
  it "is tagger" do
    @user.is_tagger?.should(be_true)
  end  
end