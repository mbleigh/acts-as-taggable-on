require File.dirname(__FILE__) + '/../spec_helper'

describe Tagging do
  before(:each) do
    @tagging = Tagging.new
  end
  
  it "should not be valid with a invalid tag" do
    @tagging.taggable = TaggableModel.create(:name => "Bob Jones")
    @tagging.tag = Tag.new(:name => "")
    @tagging.context = "tags"

    @tagging.should_not be_valid
    @tagging.errors.on(:tag_id).should == "can't be blank"
  end
  
  it "should not create duplicate taggings" do
    @taggable = TaggableModel.create(:name => "Bob Jones")
    @tag = Tag.create(:name => "awesome")
    
    lambda {
      2.times { Tagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags') }
    }.should change(Tagging, :count).by(1)
  end
end