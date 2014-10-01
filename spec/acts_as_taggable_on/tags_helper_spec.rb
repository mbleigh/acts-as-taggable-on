# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::TagsHelper do

  [
  [TaggableModel, ActsAsTaggableOn::Tag],
  [TaggableNamespacedModel, ActsAsTaggableOn::NspacedTag]
  ].each do |m|

    before(:each) do
      @bob = m[0].create(name: 'Bob Jones', language_list: 'ruby, php')
      @tom = m[0].create(name: 'Tom Marley', language_list: 'ruby, java')
      @eve = m[0].create(name: 'Eve Nodd', language_list: 'ruby, c++')

      @helper =
          class Helper
            include ActsAsTaggableOn::TagsHelper
          end.new
    end


    it 'should yield the proper css classes' do
      tags = {}

      @helper.tag_cloud(m[0].tag_counts_on(:languages), %w(sucky awesome)) do |tag, css_class|
        tags[tag.name] = css_class
      end

      expect(tags['ruby']).to eq('awesome')
      expect(tags['java']).to eq('sucky')
      expect(tags['c++']).to eq('sucky')
      expect(tags['php']).to eq('sucky')
    end

    it 'should handle tags with zero counts (build for empty)' do
      m[1].create(name: 'php')
      m[1].create(name: 'java')
      m[1].create(name: 'c++')

      tags = {}

      @helper.tag_cloud(m[1].all, %w(sucky awesome)) do |tag, css_class|
        tags[tag.name] = css_class
      end

      expect(tags['java']).to eq('sucky')
      expect(tags['c++']).to eq('sucky')
      expect(tags['php']).to eq('sucky')
    end

  end
end
