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
  
  context "inheritance" do
    before do
      @taggable = TaggableModel.new(:name => "taggable")
      @inherited_same = InheritingTaggableModel.new(:name => "inherited same")
      @inherited_different = AlteredInheritingTaggableModel.new(:name => "inherited different")
    end
    
    it "should pass on tag contexts to STI-inherited models" do
      @inherited_same.should respond_to(:tag_list, :skill_list, :language_list)
      @inherited_different.should respond_to(:tag_list, :skill_list, :language_list)
    end
    
    it "should have tag contexts added in altered STI models" do
      @inherited_different.should respond_to(:part_list)
    end
  end
  
  context "reloading" do
    it "should save a model instantiated by Model.find" do
      taggable = TaggableModel.create!(:name => "Taggable")
      found_taggable = TaggableModel.find(taggable.id)
      found_taggable.save
    end
  end
  
  context "related" do
    it "should find related objects based on tag names on context" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")
      taggable3 = TaggableModel.create!(:name => "Taggable 3")

      taggable1.tag_list = "one, two"
      taggable1.save
      
      taggable2.tag_list = "three, four"
      taggable2.save
      
      taggable3.tag_list = "one, four"
      taggable3.save
      
      taggable1.find_related_tags.should include(taggable3)
      taggable1.find_related_tags.should_not include(taggable2)
    end
  end
end