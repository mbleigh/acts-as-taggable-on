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
end