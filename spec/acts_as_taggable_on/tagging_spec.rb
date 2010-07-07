require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::Tagging do
  before(:each) do
    clean_database!
    @tagging = ActsAsTaggableOn::Tagging.new
  end

  it "should not be valid with a invalid tag" do
    @tagging.taggable = TaggableModel.create(:name => "Bob Jones")
    @tagging.tag = ActsAsTaggableOn::Tag.new(:name => "")
    @tagging.context = "tags"

    @tagging.should_not be_valid
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tagging.errors[:tag_id].should == ["can't be blank"]
    else
      @tagging.errors[:tag_id].should == "can't be blank"
    end
  end

  it "should not create duplicate taggings" do
    @taggable = TaggableModel.create(:name => "Bob Jones")
    @tag = ActsAsTaggableOn::Tag.create(:name => "awesome")

    lambda {
      2.times { ActsAsTaggableOn::Tagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags') }
    }.should change(ActsAsTaggableOn::Tagging, :count).by(1)
  end
end
