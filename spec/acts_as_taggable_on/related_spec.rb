# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Acts As Taggable On' do

  describe 'Related Objects' do

    [
      [TaggableModel, OrderedTaggableModel, NonStandardIdTaggableModel, OtherTaggableModel],
      [TaggableNamespacedModel, OrderedTaggableNamespacedModel, NonStandardIdTaggableNamespacedModel, OtherTaggableNamespacedModel]
    ].each do |m|

      #TODO, shared example
      it 'should find related objects based on tag names on context' do
        taggable1 = m[0].create!(name: 'Taggable 1', tag_list: 'one, two')
        taggable2 = m[0].create!(name: 'Taggable 2', tag_list: 'three, four')
        taggable3 = m[0].create!(name: 'Taggable 3', tag_list: 'one, four')

        expect(taggable1.find_related_tags).to include(taggable3)
        expect(taggable1.find_related_tags).to_not include(taggable2)
      end

      it 'finds related tags for ordered taggable on' do
        taggable1 = m[1].create!(name: 'Taggable 1', colour_list: 'one, two')
        taggable2 = m[1].create!(name: 'Taggable 2', colour_list: 'three, four')
        taggable3 = m[1].create!(name: 'Taggable 3', colour_list: 'one, four')

        expect(taggable1.find_related_colours).to include(taggable3)
        expect(taggable1.find_related_colours).to_not include(taggable2)
      end

      it 'should find related objects based on tag names on context - non standard id' do
        taggable1 = m[2].create!(name: 'Taggable 1', tag_list: 'one, two')
        taggable2 = m[2].create!(name: 'Taggable 2', tag_list: 'three, four')
        taggable3 = m[2].create!(name: 'Taggable 3', tag_list: 'one, four')

        expect(taggable1.find_related_tags).to include(taggable3)
        expect(taggable1.find_related_tags).to_not include(taggable2)
      end

      it 'should find other related objects based on tag names on context' do
        taggable1 = m[0].create!(name: 'Taggable 1', tag_list: 'one, two')
        taggable2 = m[3].create!(name: 'Taggable 2', tag_list: 'three, four')
        taggable3 = m[3].create!(name: 'Taggable 3', tag_list: 'one, four')

        expect(taggable1.find_related_tags_for(m[3])).to include(taggable3)
        expect(taggable1.find_related_tags_for(m[3])).to_not include(taggable2)
      end

    end


    shared_examples "a collection" do
      it do
        taggable1 = described_class.create!(name: 'Taggable 1', tag_list: 'one')
        taggable2 = described_class.create!(name: 'Taggable 2', tag_list: 'one, two')

        expect(taggable1.find_related_tags).to include(taggable2)
        expect(taggable1.find_related_tags).to_not include(taggable1)
      end
    end

    # it 'should not include the object itself in the list of related objects' do
    describe TaggableModel do
      it_behaves_like "a collection"
    end

    # it 'should not include the object itself in the list of related objects - non standard id' do
    describe NonStandardIdTaggableModel do
      it_behaves_like "a collection"
    end

    context 'Ignored Tags' do
      def set_tags(m)
        @taggable1 = m.create!(name: 'Taggable 1', tag_list: 'one, two, four')
        @taggable2 = m.create!(name: 'Taggable 2', tag_list: 'two, three')
        @taggable3 = m.create!(name: 'Taggable 3', tag_list: 'one, three')
      end

      [ TaggableModel, TaggableNamespacedModel ].each do |m|
        it 'should not include ignored tags in related search' do
          set_tags m
          expect(@taggable1.find_related_tags(ignore: 'two')).to_not include(@taggable2)
          expect(@taggable1.find_related_tags(ignore: 'two')).to include(@taggable3)
        end

        it 'should accept array of ignored tags' do
          set_tags m
          taggable4 = m.create!(name: 'Taggable 4', tag_list: 'four')
          expect(@taggable1.find_related_tags(ignore: ['two', 'four'])).to_not include(@taggable2)
          expect(@taggable1.find_related_tags(ignore: ['two', 'four'])).to_not include(taggable4)
        end

        it 'should accept symbols as ignored tags' do
          set_tags m
          expect(@taggable1.find_related_tags(ignore: :two)).to_not include(@taggable2)
        end
      end
    end

  end
end
