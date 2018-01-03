# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ActsAsTaggableOn::Taggable::Core do
  describe 'InstanceMethods' do
    let(:taggable) { TaggableModel.create(tag_list: 'awesome, epic') }

    context '#tagged_with?' do
      it 'validates the presence of a given tag' do
        expect(taggable.tagged_with?('awesome')).to be_truthy
      end

      it 'invalidates the presence of a given tag' do
        expect(taggable.tagged_with?('test')).to be_falsy
      end
    end
  end
end
