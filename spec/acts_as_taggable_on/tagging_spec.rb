require 'spec_helper'

describe ActsAsTaggableOn::Tagging do
  before :each do
    DatabaseCleaner.start
    @tagging = ActsAsTaggableOn::Tagging.new
  end

  after :each do
    DatabaseCleaner.clean
  end

  it "should not be valid with a invalid tag" do
    @tagging.taggable = TaggableModel.create(:name => "Bob Jones")
    @tagging.tag = ActsAsTaggableOn::Tag.new(:name => "")
    @tagging.context = "tags"

    @tagging.should_not be_valid
    
    @tagging.errors[:tag_id].should == ["can't be blank"]
  end

  it "should not create duplicate taggings" do
    @taggable = TaggableModel.create(:name => "Bob Jones")
    @tag = ActsAsTaggableOn::Tag.create(:name => "awesome")

    lambda {
      2.times { ActsAsTaggableOn::Tagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags') }
    }.should change(ActsAsTaggableOn::Tagging, :count).by(1)
  end
  
end
