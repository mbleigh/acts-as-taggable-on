require 'spec_helper'

describe "Acts As Taggable On" do

  before(:each) do
    clean_database!
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

end
