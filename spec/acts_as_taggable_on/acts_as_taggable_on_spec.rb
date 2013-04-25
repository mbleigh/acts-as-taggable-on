require 'spec_helper'

describe "Acts As Taggable On" do
  before(:each) do
    clean_database!
  end

  it "should provide a class method 'taggable?' that is false for untaggable models" do
    UntaggableModel.should_not be_taggable
  end
  
  describe "Taggable Method Generation To Preserve Order" do
    before(:each) do
      clean_database!
      TaggableModel.tag_types = []
      TaggableModel.preserve_tag_order = false
      TaggableModel.acts_as_ordered_taggable_on(:ordered_tags)
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end

    it "should respond 'true' to preserve_tag_order?" do
      @taggable.class.preserve_tag_order?.should be_true
    end
  end

  describe "Taggable Method Generation" do
    before(:each) do
      clean_database!
      TaggableModel.tag_types = []
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
    
    it "should create a class attribute for preserve tag order" do
      @taggable.class.should respond_to(:preserve_tag_order?)
    end

    it "should create an instance attribute for preserve tag order" do
      @taggable.should respond_to(:preserve_tag_order?)
    end
    
    it "should respond 'false' to preserve_tag_order?" do
      @taggable.class.preserve_tag_order?.should be_false
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

  describe "Reloading" do
    it "should save a model instantiated by Model.find" do
      taggable = TaggableModel.create!(:name => "Taggable")
      found_taggable = TaggableModel.find(taggable.id)
      found_taggable.save
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

    it "should not include the object itself in the list of related objects with tags of matching contexts" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")

      taggable1.offering_list = "one, two"
      taggable1.need_list = "one, two"
      taggable1.save

      taggable2.need_list = "one, two"
      taggable2.save

      taggable1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should include(taggable2)
      taggable1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should_not include(taggable1)
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
      @another_taggable = OtherCachedModel.new(:name => "John Smith")
    end

    it "should add saving of tag lists and cached tag lists to the instance" do
      @taggable.should respond_to(:save_cached_tag_list)
      @another_taggable.should respond_to(:save_cached_tag_list)

      @taggable.should respond_to(:save_tags)
    end

    it "should add cached tag lists to the instance if cached column is not present" do
      TaggableModel.new(:name => "Art Kram").should_not respond_to(:save_cached_tag_list)
    end

    it "should generate a cached column checker for each tag type" do
      CachedModel.should respond_to(:caching_tag_list?)
      OtherCachedModel.should respond_to(:caching_language_list?)
    end

    it 'should not have cached tags' do
      @taggable.cached_tag_list.should be_blank
      @another_taggable.cached_language_list.should be_blank
    end

    it 'should cache tags' do
      @taggable.update_attributes(:tag_list => 'awesome, epic')
      @taggable.cached_tag_list.should == 'awesome, epic'

      @another_taggable.update_attributes(:language_list => 'ruby, .net')
      @another_taggable.cached_language_list.should == 'ruby, .net'
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

  context 'when tagging context ends in an "s" when singular (ex. "status", "glass", etc.)' do
   describe 'caching' do
     before  { @taggable = OtherCachedModel.new(:name => "John Smith") }
     subject { @taggable }

     it { should respond_to(:save_cached_tag_list) }
     its(:cached_language_list) { should be_blank }
     its(:cached_status_list)   { should be_blank }
     its(:cached_glass_list)    { should be_blank }

     context 'language taggings cache after update' do
       before  { @taggable.update_attributes(:language_list => 'ruby, .net') }
       subject { @taggable }

       its(:language_list)        { should == ['ruby', '.net']}
       its(:cached_language_list) { should == 'ruby, .net' }           # passes
       its(:instance_variables)   { should     include((RUBY_VERSION < '1.9' ? '@language_list' : :@language_list)) }
     end

     context 'status taggings cache after update' do
       before  { @taggable.update_attributes(:status_list => 'happy, married') }
       subject { @taggable }

       its(:status_list)        { should     == ['happy', 'married'] }
       its(:cached_status_list) { should     == 'happy, married'     } # fails
       its(:cached_status_list) { should_not == ''                   } # fails, is blank
       its(:instance_variables) { should     include((RUBY_VERSION < '1.9' ? '@status_list' : :@status_list)) }
       its(:instance_variables) { should_not include((RUBY_VERSION < '1.9' ? '@statu_list' : :@statu_list))  } # fails, note: one "s"

     end

     context 'glass taggings cache after update' do
       before do
         @taggable.update_attributes(:glass_list => 'rectangle, aviator')
       end

       subject { @taggable }
       its(:glass_list)         { should     == ['rectangle', 'aviator'] }
       its(:cached_glass_list)  { should     == 'rectangle, aviator'     } # fails
       its(:cached_glass_list)  { should_not == ''                       } # fails, is blank
       if RUBY_VERSION < '1.9'
         its(:instance_variables) { should     include('@glass_list')      }
         its(:instance_variables) { should_not include('@glas_list')       } # fails, note: one "s"
       else
         its(:instance_variables) { should     include(:@glass_list)      }
         its(:instance_variables) { should_not include(:@glas_list)       } # fails, note: one "s"
       end

     end
   end
  end

  describe "taggings" do
    before(:each) do
      @taggable = TaggableModel.new(:name => "Art Kram")
    end

    it 'should return [] taggings' do
      @taggable.taggings.should == []
    end
  end

  describe "@@remove_unused_tags" do
    before do
      @taggable = TaggableModel.create(:name => "Bob Jones")
      @tag = ActsAsTaggableOn::Tag.create(:name => "awesome")

      @tagging = ActsAsTaggableOn::Tagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags')
    end

    context "if set to true" do
      before do
        ActsAsTaggableOn.remove_unused_tags = true
      end

      it "should remove unused tags after removing taggings" do
        @tagging.destroy
        ActsAsTaggableOn::Tag.find_by_name("awesome").should be_nil
      end
    end

    context "if set to false" do
      before do
        ActsAsTaggableOn.remove_unused_tags = false
      end

      it "should not remove unused tags after removing taggings" do
        @tagging.destroy
        ActsAsTaggableOn::Tag.find_by_name("awesome").should == @tag
      end
    end
  end

end
