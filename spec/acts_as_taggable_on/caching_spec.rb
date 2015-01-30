# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Acts As Taggable On' do

  describe 'Caching' do
    def set_tags(m)
      @taggable = m[0].new(name: 'Bob Jones')
      @another_taggable = m[1].new(name: 'John Smith')
    end
    
    [
      [CachedModel, OtherCachedModel, TaggableModel],
      [CachedNamespacedModel, OtherCachedNamespacedModel, TaggableNamespacedModel]
    ].each do |m|

      it 'should add saving of tag lists and cached tag lists to the instance' do
        set_tags m
        expect(@taggable).to respond_to(:save_cached_tag_list)
        expect(@another_taggable).to respond_to(:save_cached_tag_list)

        expect(@taggable).to respond_to(:save_tags)
      end

      it 'should add cached tag lists to the instance if cached column is not present' do
        set_tags m
        expect(m[2].new(name: 'Art Kram')).to_not respond_to(:save_cached_tag_list)
      end

      it 'should generate a cached column checker for each tag type' do
        set_tags m
        expect(CachedModel).to respond_to(:caching_tag_list?)
        expect(OtherCachedModel).to respond_to(:caching_language_list?)
      end

      it 'should not have cached tags' do
        set_tags m
        expect(@taggable.cached_tag_list).to be_blank
        expect(@another_taggable.cached_language_list).to be_blank
      end

      it 'should cache tags' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        expect(@taggable.cached_tag_list).to eq('awesome, epic')

        @another_taggable.update_attributes(language_list: 'ruby, .net')
        expect(@another_taggable.cached_language_list).to eq('ruby, .net')
      end

      it 'should keep the cache' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        @taggable = m[0].find(@taggable.id)
        @taggable.save!
        expect(@taggable.cached_tag_list).to eq('awesome, epic')
      end

      it 'should update the cache' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        @taggable.update_attributes(tag_list: 'awesome')
        expect(@taggable.cached_tag_list).to eq('awesome')
      end

      it 'should remove the cache' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        @taggable.update_attributes(tag_list: '')
        expect(@taggable.cached_tag_list).to be_blank
      end

      it 'should have a tag list' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        @taggable = m[0].find(@taggable.id)
        expect(@taggable.tag_list.sort).to eq(%w(awesome epic).sort)
      end

      it 'should keep the tag list' do
        set_tags m
        @taggable.update_attributes(tag_list: 'awesome, epic')
        @taggable = m[0].find(@taggable.id)
        @taggable.save!
        expect(@taggable.tag_list.sort).to eq(%w(awesome epic).sort)
      end

    end

    it 'should clear the cache on reset_column_information' do
      CachedModel.column_names
      CachedModel.reset_column_information
      expect(CachedModel.instance_variable_get(:@acts_as_taggable_on_cache_columns)).to eql(nil)
    end
  end

  describe 'CachingWithArray' do
    pending '#TODO'
  end
end
