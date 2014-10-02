# -*- encoding : utf-8 -*-
require 'spec_helper'

describe 'Single Table Inheritance' do

  def set_info(m)
    @taggable = m[0].new(name: 'taggable model')

    @inheriting_model = m[1].new(name: 'Inheriting Taggable Model')
    @altered_inheriting = m[2].new(name: 'Altered Inheriting Model')

    1.upto(4) do |n|
      eval "@inheriting_#{n} = m[1].new(name: \"Inheriting Model #{n}\")"
    end

    @student = m[3].create!
  end
  
  [
    [TaggableModel, InheritingTaggableModel, AlteredInheritingTaggableModel, Student, Company, User, Market, ActsAsTaggableOn::Tag],
    [TaggableNamespacedModel, InheritingTaggableNamespacedModel, AlteredInheritingTaggableNamespacedModel, NamespacedStudent, NamespacedCompany, NamespacedUser, NamespacedMarket, ActsAsTaggableOn::NspacedTag]
  ].each do |m|

    describe 'tag contexts' do
      before { set_info m }
      it 'should pass on to STI-inherited models' do
        expect(@inheriting_model).to respond_to(:tag_list, :skill_list, :language_list)
        expect(@altered_inheriting).to respond_to(:tag_list, :skill_list, :language_list)
      end

      it 'should pass on to altered STI models' do
        expect(@altered_inheriting).to respond_to(:part_list)
      end
    end

    context 'matching contexts' do

      before do
        set_info m
        @inheriting_1.offering_list = 'one, two'
        @inheriting_1.need_list = 'one, two'
        @inheriting_1.save!

        @inheriting_2.need_list = 'one, two'
        @inheriting_2.save!

        @inheriting_3.offering_list = 'one, two'
        @inheriting_3.save!

        @inheriting_4.tag_list = 'one, two, three, four'
        @inheriting_4.save!

        @taggable.need_list = 'one, two'
        @taggable.save!
      end

      it 'should find objects with tags of matching contexts' do
        expect(@inheriting_1.find_matching_contexts(:offerings, :needs)).to include(@inheriting_2)
        expect(@inheriting_1.find_matching_contexts(:offerings, :needs)).to_not include(@inheriting_3)
        expect(@inheriting_1.find_matching_contexts(:offerings, :needs)).to_not include(@inheriting_4)
        expect(@inheriting_1.find_matching_contexts(:offerings, :needs)).to_not include(@taggable)

        expect(@inheriting_1.find_matching_contexts_for(m[0], :offerings, :needs)).to include(@inheriting_2)
        expect(@inheriting_1.find_matching_contexts_for(m[0], :offerings, :needs)).to_not include(@inheriting_3)
        expect(@inheriting_1.find_matching_contexts_for(m[0], :offerings, :needs)).to_not include(@inheriting_4)
        expect(@inheriting_1.find_matching_contexts_for(m[0], :offerings, :needs)).to include(@taggable)
      end

      it 'should not include the object itself in the list of related objects with tags of matching contexts' do
        expect(@inheriting_1.find_matching_contexts(:offerings, :needs)).to_not include(@inheriting_1)
        expect(@inheriting_1.find_matching_contexts_for(m[1], :offerings, :needs)).to_not include(@inheriting_1)
        expect(@inheriting_1.find_matching_contexts_for(m[0], :offerings, :needs)).to_not include(@inheriting_1)
      end
    end

    context 'find related tags' do
      before do
        set_info m
        @inheriting_1.tag_list = 'one, two'
        @inheriting_1.save

        @inheriting_2.tag_list = 'three, four'
        @inheriting_2.save

        @inheriting_3.tag_list = 'one, four'
        @inheriting_3.save

        @taggable.tag_list = 'one, two, three, four'
        @taggable.save
      end

      it 'should find related objects based on tag names on context' do
        expect(@inheriting_1.find_related_tags).to include(@inheriting_3)
        expect(@inheriting_1.find_related_tags).to_not include(@inheriting_2)
        expect(@inheriting_1.find_related_tags).to_not include(@taggable)

        expect(@inheriting_1.find_related_tags_for(m[0])).to include(@inheriting_3)
        expect(@inheriting_1.find_related_tags_for(m[0])).to_not include(@inheriting_2)
        expect(@inheriting_1.find_related_tags_for(m[0])).to include(@taggable)
      end

      it 'should not include the object itself in the list of related objects' do
        expect(@inheriting_1.find_related_tags).to_not include(@inheriting_1)
        expect(@inheriting_1.find_related_tags_for(m[1])).to_not include(@inheriting_1)
        expect(@inheriting_1.find_related_tags_for(m[0])).to_not include(@inheriting_1)
      end
    end

    describe 'tag list' do
      before do
        set_info m
        @inherited_same = m[1].new(name: 'inherited same')
        @inherited_different = m[2].new(name: 'inherited different')
      end

      #TODO, shared example
      it 'should be able to save tags for inherited models' do
        @inheriting_model.tag_list = 'bob, kelso'
        @inheriting_model.save
        expect(m[1].tagged_with('bob').first).to eq(@inheriting_model)
      end

      it 'should find STI tagged models on the superclass' do
        @inheriting_model.tag_list = 'bob, kelso'
        @inheriting_model.save
        expect(m[0].tagged_with('bob').first).to eq(@inheriting_model)
      end

      it 'should be able to add on contexts only to some subclasses' do
        @altered_inheriting.part_list = 'fork, spoon'
        @altered_inheriting.save
        expect(m[1].tagged_with('fork', on: :parts)).to be_empty
        expect(m[2].tagged_with('fork', on: :parts).first).to eq(@altered_inheriting)
      end

      it 'should have different tag_counts_on for inherited models' do
        @inheriting_model.tag_list = 'bob, kelso'
        @inheriting_model.save!
        @altered_inheriting.tag_list = 'fork, spoon'
        @altered_inheriting.save!

        expect(m[1].tag_counts_on(:tags, order: "#{m[1].namespaced :tags}.id").map(&:name)).to eq(%w(bob kelso))
        expect(m[2].tag_counts_on(:tags, order: "#{m[2].namespaced :tags}.id").map(&:name)).to eq(%w(fork spoon))
        expect(m[0].tag_counts_on(:tags, order: "#{m[0].namespaced :tags}.id").map(&:name)).to eq(%w(bob kelso fork spoon))
      end

      it 'should have different tags_on for inherited models' do
        @inheriting_model.tag_list = 'bob, kelso'
        @inheriting_model.save!
        @altered_inheriting.tag_list = 'fork, spoon'
        @altered_inheriting.save!

        expect(m[1].tags_on(:tags, order: "#{m[1].namespaced :tags}.id").map(&:name)).to eq(%w(bob kelso))
        expect(m[2].tags_on(:tags, order: "#{m[2].namespaced :tags}.id").map(&:name)).to eq(%w(fork spoon))
        expect(m[0].tags_on(:tags, order: "#{m[0].namespaced :tags}.id").map(&:name)).to eq(%w(bob kelso fork spoon))
      end

      it 'should store same tag without validation conflict' do
        @taggable.tag_list = 'one'
        @taggable.save!

        @inheriting_model.tag_list = 'one'
        @inheriting_model.save!

        @inheriting_model.update_attributes! name: 'foo'
      end
    end

    describe 'ownership' do
      before do
        set_info m
      end

      it 'should have taggings' do
        @student.tag(@taggable, with: 'ruby,scheme', on: :tags)
        expect(@student.owned_taggings.count).to eq(2)
      end

      it 'should have tags' do
        @student.tag(@taggable, with: 'ruby,scheme', on: :tags)
        expect(@student.owned_tags.count).to eq(2)
      end

      it 'should return tags for the inheriting tagger' do
        @student.tag(@taggable, with: 'ruby, scheme', on: :tags)
        expect(@taggable.tags_from(@student)).to eq(%w(ruby scheme))
      end

      it 'returns owner tags on the tagger' do
        @student.tag(@taggable, with: 'ruby, scheme', on: :tags)
        expect(@taggable.owner_tags_on(@student, :tags).count).to eq(2)
      end

      it 'should scope objects returned by tagged_with by owners' do
        @student.tag(@taggable, with: 'ruby, scheme', on: :tags)
        expect(m[0].tagged_with(%w(ruby scheme), owned_by: @student).count).to eq(1)
      end
    end

    describe "a subclass of #{m[7]}" do
      before do
        set_info m
        @company = m[4].new(name: 'Dewey, Cheatham & Howe')
        @user = m[5].create!
      end

      it 'sets STI type through string list' do
        @company.market_list = 'law, accounting'
        @company.save!
        expect(m[6].count).to eq(2)
      end

      it "does not interfere with a normal #{m[7]} context on the same model" do
        @company.location_list = 'cambridge'
        @company.save!
        expect(m[7].where(name: 'cambridge', type: nil)).to_not be_empty
      end

      it 'is returned with proper type through ownership' do
        @user.tag(@company, with: 'ripoffs, rackets', on: :markets)
        tags = @company.owner_tags_on(@user, :markets)
        expect(tags.all? { |tag| tag.is_a? m[6] }).to be_truthy
      end
    end
  end
end

