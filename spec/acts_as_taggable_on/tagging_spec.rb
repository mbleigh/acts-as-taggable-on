# -*- encoding : utf-8 -*-
require 'spec_helper'

[
  [ActsAsTaggableOn::Tagging, TaggableModel, ActsAsTaggableOn::Tag],
  [ActsAsTaggableOn::NspacedTagging, TaggableNamespacedModel, ActsAsTaggableOn::NspacedTag]
].each do |m|

  describe m[0] do
    def set_info(m)
      @tagging = m[0].new
    end
    before(:each) { set_info m }

    it 'should not be valid with a invalid tag' do
      @tagging.taggable = m[1].create(name: 'Bob Jones')
      @tagging.tag = m[2].new(name: '')
      @tagging.context = 'tags'

      expect(@tagging).to_not be_valid
      expect(@tagging.errors[m[0].namespaced(:tag_id)]).to eq(['can\'t be blank'])
    end

    it 'should not create duplicate taggings' do
      @taggable = m[1].create(name: 'Bob Jones')
      @tag = m[2].create(name: 'awesome')

      expect(-> {
        2.times { m[0].create(taggable: @taggable, m[0].namespaced(:tag) => @tag, context: 'tags') }
      }).to change(m[0], :count).by(1)
    end

    it 'should not delete tags of other records' do
      6.times { m[1].create(name: 'Bob Jones', tag_list: 'very, serious, bug') }
      expect(m[2].count).to eq(3)
      taggable = m[1].first
      taggable.tag_list = 'bug'
      taggable.save

      expect(taggable.tag_list).to eq(['bug'])

      another_taggable = m[1].where('id != ?', taggable.id).sample
      expect(another_taggable.tag_list.sort).to eq(%w(very serious bug).sort)
    end

    it 'should destroy unused tags after tagging destroyed' do
      previous_setting = ActsAsTaggableOn.remove_unused_tags
      ActsAsTaggableOn.remove_unused_tags = true
      m[2].destroy_all
      @taggable = m[1].create(name: 'Bob Jones')
      @taggable.update_attribute :tag_list, 'aaa,bbb,ccc'
      @taggable.update_attribute :tag_list, ''
      expect(m[2].count).to eql(0)
      ActsAsTaggableOn.remove_unused_tags = previous_setting
    end

    pending 'context scopes' do
      describe '.by_context'

      describe '.by_contexts'

      describe '.owned_by'

      describe '.not_owned'

    end

  end

end