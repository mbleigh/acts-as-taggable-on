require File.dirname(__FILE__) + '/../spec_helper'

describe "Acts As Taggable On" do
  it "should provide a class method 'taggable?' that is false for untaggable models" do
    UntaggableModel.should_not be_taggable
  end
  
  describe "Taggable Method Generation" do
    before(:each) do
      [TaggableModel, Tag, Tagging, TaggableUser].each(&:delete_all)
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end
  
    it "should respond 'true' to taggable?" do
      @taggable.class.should be_taggable
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
  
  describe "Single Table Inheritance" do
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
  
  describe "Reloading" do
    it "should save a model instantiated by Model.find" do
      taggable = TaggableModel.create!(:name => "Taggable")
      found_taggable = TaggableModel.find(taggable.id)
      found_taggable.save
    end
  end
  
  describe "Related Objects" do
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

    it "should find other related objects based on tag names on context" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = OtherTaggableModel.create!(:name => "Taggable 2")
      taggable3 = OtherTaggableModel.create!(:name => "Taggable 3")

      taggable1.tag_list = "one, two"
      taggable1.save
      
      taggable2.tag_list = "three, four"
      taggable2.save
      
      taggable3.tag_list = "one, four"
      taggable3.save

      taggable1.find_related_tags_for(OtherTaggableModel).should include(taggable3)
      taggable1.find_related_tags_for(OtherTaggableModel).should_not include(taggable2)
    end
  end
  
  describe 'Tagging Contexts' do
    before(:all) do
      class Array
        def freq
          k=Hash.new(0)
          self.each {|e| k[e]+=1}
          k
        end
      end
    end
    
    it 'should eliminate duplicate tagging contexts ' do
      TaggableModel.acts_as_taggable_on(:skills, :skills)
      TaggableModel.tag_types.freq[:skills].should_not == 3
    end

    it "should not contain embedded/nested arrays" do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      TaggableModel.tag_types.freq[[:array]].should == 0
    end

    it "should _flatten_ the content of arrays" do
      TaggableModel.acts_as_taggable_on([:array], [:array])
      TaggableModel.tag_types.freq[:array].should == 1
    end

    it "should not raise an error when passed nil" do
      lambda {
        TaggableModel.acts_as_taggable_on()
      }.should_not raise_error
    end

    it "should not raise an error when passed [nil]" do
      lambda {
        TaggableModel.acts_as_taggable_on([nil])
      }.should_not raise_error
    end

    after(:all) do
      class Array; remove_method :freq; end
    end
  end
  
end