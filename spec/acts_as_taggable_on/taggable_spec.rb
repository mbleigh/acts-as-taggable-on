require File.dirname(__FILE__) + '/../spec_helper'

describe "Taggable" do
  before(:each) do
    @taggable = User.new(:name => "Bob Jones")
  end
  
  it "should be able to create tags" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.instance_variable_get("@skill_list").instance_of?(TagList).should be_true
    @taggable.save
    
    Tag.find(:all).size.should == 3
  end
  
  it "should differentiate between contexts" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "ruby, bob, charlie"
    @taggable.save
    @taggable.reload
    @taggable.skill_list.include?("ruby").should be_true
    @taggable.skill_list.include?("bob").should be_false
  end
  
  it "should be able to remove tags through list alone" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    @taggable.reload
    @taggable.should have(3).skills
    @taggable.skill_list = "ruby, rails"
    @taggable.save
    @taggable.reload
    @taggable.should have(2).skills
  end
  
  it "should be able to find by tag" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    User.find_tagged_with("ruby").first.should == @taggable
  end
  
  it "should be able to find by tag with context" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "bob, charlie"
    @taggable.save
    User.find_tagged_with("ruby").first.should == @taggable
    User.find_tagged_with("bob", :on => :skills).first.should_not == @taggable
    User.find_tagged_with("bob", :on => :tags).first.should == @taggable
  end
  
  it "should not care about case" do
    bob = User.create(:name => "Bob", :tag_list => "ruby")
    frank = User.create(:name => "Frank", :tag_list => "Ruby")
    
    Tag.find(:all).size.should == 1
    User.find_tagged_with("ruby").should == User.find_tagged_with("Ruby")
  end
end