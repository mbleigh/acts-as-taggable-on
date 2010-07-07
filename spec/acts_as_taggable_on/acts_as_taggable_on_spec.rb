require File.expand_path('../../spec_helper', __FILE__)

describe "Acts As Taggable On" do
  before(:each) do
    clean_database!
  end

  it "should provide a class method 'taggable?' that is false for untaggable models" do
    UntaggableModel.should_not be_taggable
  end

  describe "Taggable Method Generation" do
    before(:each) do
      clean_database!
      TaggableModel.write_inheritable_attribute(:tag_types, [])
      TaggableModel.acts_as_taggable_on(:tags, :languages, :skills, :needs, :offerings)
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end

    it "should respond 'true' to taggable?" do
      @taggable.class.should be_taggable
    end

    it "should create a class attribute for tag types" do
      @taggable.class.should respond_to(:tag_types)
    end

    it "should create an instance attribute for tag types" do
      @taggable.should respond_to(:tag_types)
    end
    
    it "should have all tag types" do
      @taggable.tag_types.should == [:tags, :languages, :skills, :needs, :offerings]
    end

    it "should generate an association for each tag type" do
      @taggable.should respond_to(:tags, :skills, :languages)
    end

    it "should add tagged_with and tag_counts to singleton" do
      TaggableModel.should respond_to(:tagged_with, :tag_counts)
    end

    it "should generate a tag_list accessor/setter for each tag type" do
      @taggable.should respond_to(:tag_list, :skill_list, :language_list)
      @taggable.should respond_to(:tag_list=, :skill_list=, :language_list=)
    end
    
    it "should generate a tag_list accessor, that includes owned tags, for each tag type" do
      @taggable.should respond_to(:all_tags_list, :all_skills_list, :all_languages_list)
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
  
    it "should not include the object itself in the list of related objects" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")
  
      taggable1.tag_list = "one"
      taggable1.save
  
      taggable2.tag_list = "one, two"
      taggable2.save
  
      taggable1.find_related_tags.should include(taggable2)
      taggable1.find_related_tags.should_not include(taggable1)
    end
  end

  describe "Matching Contexts" do
    it "should find objects with tags of matching contexts" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")
      taggable3 = TaggableModel.create!(:name => "Taggable 3")
  
      taggable1.offering_list = "one, two"
      taggable1.save!
  
      taggable2.need_list = "one, two"
      taggable2.save!
  
      taggable3.offering_list = "one, two"
      taggable3.save!
  
      taggable1.find_matching_contexts(:offerings, :needs).should include(taggable2)
      taggable1.find_matching_contexts(:offerings, :needs).should_not include(taggable3)
    end
  
    it "should find other related objects with tags of matching contexts" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = OtherTaggableModel.create!(:name => "Taggable 2")
      taggable3 = OtherTaggableModel.create!(:name => "Taggable 3")
  
      taggable1.offering_list = "one, two"
      taggable1.save
  
      taggable2.need_list = "one, two"
      taggable2.save
  
      taggable3.offering_list = "one, two"
      taggable3.save
  
      taggable1.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs).should include(taggable2)
      taggable1.find_matching_contexts_for(OtherTaggableModel, :offerings, :needs).should_not include(taggable3)
    end
  
    it "should not include the object itself in the list of related objects" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")
  
      taggable1.tag_list = "one"
      taggable1.save
  
      taggable2.tag_list = "one, two"
      taggable2.save
  
      taggable1.find_related_tags.should include(taggable2)
      taggable1.find_related_tags.should_not include(taggable1)
    end
  end

  describe 'Tagging Contexts' do
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
  end
  
  describe 'Caching' do
    before(:each) do
      @taggable = CachedModel.new(:name => "Bob Jones")  
    end
    
    it "should add saving of tag lists and cached tag lists to the instance" do
      @taggable.should respond_to(:save_cached_tag_list)
      @taggable.should respond_to(:save_tags)
    end  

    it "should generate a cached column checker for each tag type" do
      CachedModel.should respond_to(:caching_tag_list?)
    end  
    
    it 'should not have cached tags' do
      @taggable.cached_tag_list.should be_blank  
    end
    
    it 'should cache tags' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable.cached_tag_list.should == 'awesome, epic'
    end
    
    it 'should keep the cache' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable = CachedModel.find(@taggable)  
      @taggable.save!
      @taggable.cached_tag_list.should == 'awesome, epic'   
    end
    
    it 'should update the cache' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable.update_attributes(:tag_list => 'awesome')
      @taggable.cached_tag_list.should == 'awesome'      
    end
    
    it 'should remove the cache' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable.update_attributes(:tag_list => '')
      @taggable.cached_tag_list.should be_blank  
    end
    
    it 'should have a tag list' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable = CachedModel.find(@taggable.id)
      @taggable.tag_list.sort.should == %w(awesome epic).sort
    end
    
    it 'should keep the tag list' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable = CachedModel.find(@taggable.id)
      @taggable.save!
      @taggable.tag_list.sort.should == %w(awesome epic).sort
    end
  end

end
