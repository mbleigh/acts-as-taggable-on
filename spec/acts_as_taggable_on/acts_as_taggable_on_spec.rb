require File.dirname(__FILE__) + '/../spec_helper'

describe "acts_as_taggable_on" do
  context "Taggable Method Generation" do
    before(:each) do
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end
  
    it "should create a class attribute for tag types" do
      @taggable.class.should respond_to(:tag_types)
    end
  
    it "should generate an association for each tag type" do
      @taggable.should respond_to(:tags, :skills, :languages)
    end
    
    it "should generate a cached column checker for each tag type" do
     TaggableModel.should respond_to(:caching_tag_list?, :caching_skill_list?, :caching_language_list?)
    end
    
    it "should add tagged_with and tag_counts to singleton" do
      TaggableModel.should respond_to(:find_tagged_with, :tag_counts)
    end
    
    it "should add saving of tag lists and cached tag lists to the instance" do
      @taggable.should respond_to(:save_cached_tag_list)
      @taggable.should respond_to(:save_tags)
    end
  
    it "should generate a tag_list accessor/setter for each tag type" do
      @taggable.should respond_to(:tag_list, :skill_list, :language_list)
      @taggable.should respond_to(:tag_list=, :skill_list=, :language_list=)
    end
  end
  
  context "reloading" do
    it "should save a model instantiated by Model.find" do
      taggable = TaggableModel.create!(:name => "Taggable")
      found_taggable = TaggableModel.find(taggable.id)
      found_taggable.save
    end
  end
end