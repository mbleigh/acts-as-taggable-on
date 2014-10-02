# encoding: utf-8
require 'spec_helper'

[
  [ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging, TaggableModel, OrderedTaggableModel, 
    UntaggableModel, NonStandardIdTaggableModel, (TaggableModelWithJson if using_postgresql? and postgresql_support_json?)].compact,
  [ActsAsTaggableOn::NspacedTag, ActsAsTaggableOn::NspacedTagging, TaggableNamespacedModel, OrderedTaggableNamespacedModel, 
    UntaggableNamespacedModel, NonStandardIdTaggableNamespacedModel, (TaggableNamespacedModelWithJson if using_postgresql? and postgresql_support_json?)].compact
].each do |m|

  def ns_generic_att(m, att)
    ns = m.taggable_on_namespace
    ns = :namespaced unless ns.nil?
    ActsAsTaggableOn.namespaced_attribute(ns, att)
  end

  describe 'The test database' do

    it 'should have namespaced and non-namespaced tables' do
      # Check existence of tags, taggings, nspaced_tags and nspaced_taggings tables
      expect(ActiveRecord::Base.connection.table_exists?(m[0].name.demodulize.underscore.pluralize)).to be true
      expect(ActiveRecord::Base.connection.table_exists?(m[1].name.demodulize.underscore.pluralize)).to be true
    end

  end

  describe 'Taggable To Preserve Order' do
    before(:each) do
      @taggable = m[3].new(name: 'Bob Jones')
    end


    it 'should have tag associations' do
      [:tags, :colours].each do |type|
        expect(@taggable.respond_to?(type)).to be_truthy
        expect(@taggable.respond_to?("#{type.to_s.singularize}_taggings")).to be_truthy
      end
    end

    it 'should have tag methods' do
      [:tags, :colours].each do |type|
        expect(@taggable.respond_to?("#{type.to_s.singularize}_list")).to be_truthy
        expect(@taggable.respond_to?("#{type.to_s.singularize}_list=")).to be_truthy
        expect(@taggable.respond_to?("all_#{type}_list")).to be_truthy
      end
    end

    it 'should return tag list in the order the tags were created' do
      # create
      @taggable.tag_list = 'rails, ruby, css'
      expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

      expect(-> {
        @taggable.save
      }).to change(m[0], :count).by(3)

      @taggable.reload
      expect(@taggable.tag_list).to eq(%w(rails ruby css))

      # update
      @taggable.tag_list = 'pow, ruby, rails'
      @taggable.save

      @taggable.reload
      expect(@taggable.tag_list).to eq(%w(pow ruby rails))

      # update with no change
      @taggable.tag_list = 'pow, ruby, rails'
      @taggable.save

      @taggable.reload
      expect(@taggable.tag_list).to eq(%w(pow ruby rails))

      # update to clear tags
      @taggable.tag_list = ''
      @taggable.save

      @taggable.reload
      expect(@taggable.tag_list).to be_empty
    end

    it 'should return tag objects in the order the tags were created' do
      # create
      @taggable.tag_list = 'pow, ruby, rails'
      expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

      expect(-> {
        @taggable.save
      }).to change(m[0], :count).by(3)

      @taggable.reload
      expect(@taggable.tags.map { |t| t.name }).to eq(%w(pow ruby rails))

      # update
      @taggable.tag_list = 'rails, ruby, css, pow'
      @taggable.save

      @taggable.reload
      expect(@taggable.tags.map { |t| t.name }).to eq(%w(rails ruby css pow))
    end

    it 'should return tag objects in tagging id order' do
      # create
      @taggable.tag_list = 'pow, ruby, rails'
      @taggable.save

      @taggable.reload
      ids = @taggable.tags.map { |t| t.send(m[0].namespaced(:taggings)).first.id }
      expect(ids).to eq(ids.sort)

      # update
      @taggable.tag_list = 'rails, ruby, css, pow'
      @taggable.save

      @taggable.reload
      ids = @taggable.tags.map { |t| t.send(m[0].namespaced(:taggings)).first.id }
      expect(ids).to eq(ids.sort)
    end
  end

  describe 'Taggable' do
    before(:each) do
      @taggable = m[2].new(name: 'Bob Jones')
      @taggables = [@taggable, m[2].new(name: 'John Doe')]
    end

    it 'should have tag types' do
      [:tags, :languages, :skills, :needs, :offerings].each do |type|
        expect(m[2].tag_types).to include type
      end

      expect(@taggable.tag_types).to eq(m[2].tag_types)
    end

    it 'should have tag_counts_on' do
      expect(m[2].tag_counts_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(m[2].tag_counts_on(:tags).length).to eq(2)
      expect(@taggable.tag_counts_on(:tags).length).to eq(2)
    end

    it 'should have tags_on' do
      expect(m[2].tags_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(m[2].tags_on(:tags).length).to eq(2)
      expect(@taggable.tags_on(:tags).length).to eq(2)
    end

    it 'should return [] right after create' do
      blank_taggable = m[2].new(name: 'Bob Jones')
      expect(blank_taggable.tag_list).to be_empty
    end

    it 'should be able to create tags' do
      @taggable.skill_list = 'ruby, rails, css'
      expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

      expect(-> {
        @taggable.save
      }).to change(m[0], :count).by(3)

      @taggable.reload
      expect(@taggable.skill_list.sort).to eq(%w(ruby rails css).sort)
    end

    it 'should be able to create tags through the tag list directly' do
      @taggable.tag_list_on(:test).add('hello')
      expect(@taggable.tag_list_cache_on(:test)).to_not be_empty
      expect(@taggable.tag_list_on(:test)).to eq(['hello'])

      @taggable.save
      @taggable.save_tags

      @taggable.reload
      expect(@taggable.tag_list_on(:test)).to eq(['hello'])
    end

    it 'should differentiate between contexts' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.tag_list = 'ruby, bob, charlie'
      @taggable.save
      @taggable.reload
      expect(@taggable.skill_list).to include('ruby')
      expect(@taggable.skill_list).to_not include('bob')
    end

    it 'should be able to remove tags through list alone' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.save
      @taggable.reload
      expect(@taggable.skills.count).to eq(3)
      @taggable.skill_list = 'ruby, rails'
      @taggable.save
      @taggable.reload
      expect(@taggable.skills.count).to eq(2)
    end

    it 'should be able to select taggables by subset of tags using ActiveRelation methods' do
      @taggables[0].tag_list = 'bob'
      @taggables[1].tag_list = 'charlie'
      @taggables[0].skill_list = 'ruby'
      @taggables[1].skill_list = 'css'
      @taggables.each { |taggable| taggable.save }

      @found_taggables_by_tag = m[2].joins(:tags).where(m[0].namespaced(:tags) => {name: ['bob']})
      @found_taggables_by_skill = m[2].joins(:skills).where(m[0].namespaced(:tags) => {name: ['ruby']})

      expect(@found_taggables_by_tag).to include @taggables[0]
      expect(@found_taggables_by_tag).to_not include @taggables[1]
      expect(@found_taggables_by_skill).to include @taggables[0]
      expect(@found_taggables_by_skill).to_not include @taggables[1]
    end

    it 'should be able to find by tag' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.save

      expect(m[2].tagged_with('ruby').first).to eq(@taggable)
    end

    it 'should be able to get a count with find by tag when using a group by' do
      @taggable.skill_list = 'ruby'
      @taggable.save

      expect(m[2].tagged_with('ruby').count).to eq(1)
    end

    it 'can be used as scope' do
      @taggable.skill_list = 'ruby'
      @taggable.save
      untaggable_model = @taggable.untaggable_models.create!(name:'foobar')
      scope_tag = m[2].tagged_with('ruby', any: 'distinct', order: "taggable_#{ns_generic_att(m[0], :models)}.name asc")
      expect(m[4].joins("taggable_#{ns_generic_att(m[0], :model)}".to_sym).merge(scope_tag).except(:select)).to eq([untaggable_model])
    end

    it "shouldn't generate a query with DISTINCT by default" do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.save

      expect(m[2].tagged_with('ruby').to_sql).to_not match /DISTINCT/
    end

    it "should be able to find a tag using dates" do
      @taggable.skill_list = "ruby"
      @taggable.save

      expect(m[2].tagged_with("ruby", :start_at => Date.today.to_time.utc, :end_at => Date.tomorrow.to_time.utc).count).to eq(1)
    end

      it "shouldn't be able to find a tag outside date range" do
      @taggable.skill_list = "ruby"
      @taggable.save

      expect(m[2].tagged_with("ruby", :start_at => (Date.today - 2.days).to_time.utc, :end_at => (Date.today - 1.day).to_time.utc).count).to eq(0)
    end

    it 'should be able to find by tag with context' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.tag_list = 'bob, charlie'
      @taggable.save

      expect(m[2].tagged_with('ruby').first).to eq(@taggable)
      expect(m[2].tagged_with('ruby, css').first).to eq(@taggable)
      expect(m[2].tagged_with('bob', on: :skills).first).to_not eq(@taggable)
      expect(m[2].tagged_with('bob', on: :tags).first).to eq(@taggable)
    end

    it 'should not care about case' do
      m[2].create(name: 'Bob', tag_list: 'ruby')
      m[2].create(name: 'Frank', tag_list: 'Ruby')

      expect(m[0].all.size).to eq(1)
      expect(m[2].tagged_with('ruby').to_a).to eq(m[2].tagged_with('Ruby').to_a)
    end

    it 'should be able to find by tags with other joins in the query' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.tag_list = 'bob, charlie'
      @taggable.save

      expect(m[2].tagged_with(['bob', 'css'], :any => true).to_a).to eq([@taggable])

      bob = m[2].create(:name => 'Bob', :tag_list => 'ruby, rails, css')
      frank = m[2].create(:name => 'Frank', :tag_list => 'ruby, rails')
      charlie = m[2].create(:name => 'Charlie', :skill_list => 'ruby, java')

      # Test for explicit distinct in select
      bob.untaggable_models.create!
      frank.untaggable_models.create!
      charlie.untaggable_models.create!

      expect(m[2].select("distinct(taggable_#{ns_generic_att(m[0], :models)}.id), taggable_#{ns_generic_att(m[0], :models)}.*").joins("untaggable_#{ns_generic_att(m[0], :models)}".to_sym).tagged_with(['css', 'java'], :any => true).to_a.sort).to eq([bob, charlie].sort)

      expect(m[2].select("distinct(taggable_#{ns_generic_att(m[0], :models)}.id), taggable_#{ns_generic_att(m[0], :models)}.*").joins("untaggable_#{ns_generic_att(m[0], :models)}".to_sym).tagged_with(['rails', 'ruby'], :any => false).to_a.sort).to eq([bob, frank].sort)
    end

    it 'should not care about case for unicode names', unless: using_sqlite? do
      ActsAsTaggableOn.strict_case_match = false
      m[2].create(name: 'Anya', tag_list: 'ПРИВЕТ')
      m[2].create(name: 'Igor', tag_list: 'привет')
      m[2].create(name: 'Katia', tag_list: 'ПРИВЕТ')

      expect(m[0].all.size).to eq(1)
      expect(m[2].tagged_with('привет').to_a).to eq(m[2].tagged_with('ПРИВЕТ').to_a)
    end

    context 'should be able to create and find tags in languages without capitalization :' do
      ActsAsTaggableOn.strict_case_match = false
      {
          japanese: {name: 'Chihiro', tag_list: '日本の'},
          hebrew: {name: 'Salim', tag_list: 'עברית'},
          chinese: {name: 'Ieie', tag_list: '中国的'},
          arabic: {name: 'Yasser', tag_list: 'العربية'},
          emo: {name: 'Emo', tag_list: '✏'}
      }.each do |language, values|

        it language do
          m[2].create(values)
          expect(m[2].tagged_with(values[:tag_list]).count).to eq(1)
        end
      end
    end

    it 'should be able to get tag counts on model as a whole' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')
      expect(m[2].tag_counts).to_not be_empty
      expect(m[2].skill_counts).to_not be_empty
    end

    it 'should be able to get all tag counts on model as whole' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')

      expect(m[2].all_tag_counts).to_not be_empty
      expect(m[2].all_tag_counts(order: "#{m[0].namespaced(:tags)}.id").first.count).to eq(3) # ruby
    end

    it 'should be able to get all tags on model as whole' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')

      expect(m[2].all_tags).to_not be_empty
      expect(m[2].all_tags(order: "#{m[0].namespaced(:tags)}.id").first.name).to eq('ruby')
    end

    it 'should be able to use named scopes to chain tag finds by any tags by context' do
      bob = m[2].create(name: 'Bob', need_list: 'rails', offering_list: 'c++')
      m[2].create(name: 'Frank', need_list: 'css', offering_list: 'css')
      m[2].create(name: 'Steve', need_list: 'c++', offering_list: 'java')

      # Let's only find those who need rails or css and are offering c++ or java
      expect(m[2].tagged_with(['rails, css'], on: :needs, any: true).tagged_with(['c++', 'java'], on: :offerings, any: true).to_a).to eq([bob])
    end

    it 'should not return read-only records' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      expect(m[2].tagged_with('ruby').first).to_not be_readonly
    end

    it 'should be able to get scoped tag counts' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')

      expect(m[2].tagged_with('ruby').tag_counts(order: "#{m[2].namespaced(:tags)}.id").first.count).to eq(2) # ruby
      expect(m[2].tagged_with('ruby').skill_counts.first.count).to eq(1) # ruby
    end

    it 'should be able to get all scoped tag counts' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')

      expect(m[2].tagged_with('ruby').all_tag_counts(order: "#{m[2].namespaced(:tags)}.id").first.count).to eq(3) # ruby
    end

    it 'should be able to get all scoped tags' do
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Charlie', skill_list: 'ruby')

      expect(m[2].tagged_with('ruby').all_tags(order: "#{m[2].namespaced(:tags)}.id").first.name).to eq('ruby')
    end

    it 'should only return tag counts for the available scope' do
      frank = m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Charlie', skill_list: 'ruby, java')

      expect(m[2].tagged_with('rails').all_tag_counts.size).to eq(3)
      expect(m[2].tagged_with('rails').all_tag_counts.any? { |tag| tag.name == 'java' }).to be_falsy

      # Test specific join syntaxes:
      frank.untaggable_models.create!
      expect(m[2].tagged_with('rails').joins("untaggable_#{ns_generic_att(m[2], :models)}".to_sym).all_tag_counts.size).to eq(2)
      expect(m[2].tagged_with('rails').joins("untaggable_#{ns_generic_att(m[2], :models)}".to_sym => "taggable_#{ns_generic_att(m[2], :model)}".to_sym).all_tag_counts.size).to eq(2)
      expect(m[2].tagged_with('rails').joins(["untaggable_#{ns_generic_att(m[2], :models)}".to_sym]).all_tag_counts.size).to eq(2)
    end

    it 'should only return tags for the available scope' do
      frank = m[2].create(name: 'Frank', tag_list: 'ruby, rails')
      m[2].create(name: 'Bob', tag_list: 'ruby, rails, css')
      m[2].create(name: 'Charlie', skill_list: 'ruby, java')

      expect(m[2].tagged_with('rails').all_tags.count).to eq(3)
      expect(m[2].tagged_with('rails').all_tags.any? { |tag| tag.name == 'java' }).to be_falsy

      # Test specific join syntaxes:
      frank.untaggable_models.create!
      expect(m[2].tagged_with('rails').joins("untaggable_#{ns_generic_att(m[2], :models)}".to_sym).all_tags.size).to eq(2)
      expect(m[2].tagged_with('rails').joins("untaggable_#{ns_generic_att(m[2], :models)}".to_sym => "taggable_#{ns_generic_att(m[2], :model)}".to_sym).all_tags.size).to eq(2)
      expect(m[2].tagged_with('rails').joins(["untaggable_#{ns_generic_att(m[2], :models)}".to_sym]).all_tags.size).to eq(2)
    end

    it 'should be able to set a custom tag context list' do
      bob = m[2].create(name: 'Bob')
      bob.set_tag_list_on(:rotors, 'spinning, jumping')
      expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
      bob.save
      bob.reload
      expect(bob.tags_on(:rotors)).to_not be_empty
    end

    # ----------------

    def make_bob_frank_steve!(m)
      @bob = m[2].create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
      @frank = m[2].create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
      @steve = m[2].create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')
    end

    # ----------------

    it 'should be able to find tagged' do
      make_bob_frank_steve! m
      expect(m[2].tagged_with('ruby', order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@bob, @frank, @steve])
      expect(m[2].tagged_with('ruby, rails', order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@bob, @frank])
      expect(m[2].tagged_with(%w(ruby rails), order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@bob, @frank])
    end

    it 'should be able to find tagged with quotation marks' do
      bob = m[2].create(name: 'Bob', tag_list: "fitter, happier, more productive, 'I love the ,comma,'")
      expect(m[2].tagged_with("'I love the ,comma,'")).to include(bob)
    end

    it 'should be able to find tagged with invalid tags' do
      bob = m[2].create(name: 'Bob', tag_list: 'fitter, happier, more productive')
      expect(m[2].tagged_with('sad, happier')).to_not include(bob)
    end

    it 'should be able to find tagged with any tag' do
      make_bob_frank_steve! m
      expect(m[2].tagged_with(%w(ruby java), order: "taggable_#{ns_generic_att(m[2], :models)}.name", any: true).to_a).to eq([@bob, @frank, @steve])
      expect(m[2].tagged_with(%w(c++ fitter), order: "taggable_#{ns_generic_att(m[2], :models)}.name", any: true).to_a).to eq([@bob, @steve])
      expect(m[2].tagged_with(%w(depressed css), order: "taggable_#{ns_generic_att(m[2], :models)}.name", any: true).to_a).to eq([@bob, @frank])
    end

    it 'should be able to order by number of matching tags when matching any' do
      make_bob_frank_steve! m
      expect(m[2].tagged_with(%w(ruby java), any: true, order_by_matching_tag_count: true, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@steve, @bob, @frank])
      expect(m[2].tagged_with(%w(c++ fitter), any: true, order_by_matching_tag_count: true, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@steve, @bob])
      expect(m[2].tagged_with(%w(depressed css), any: true, order_by_matching_tag_count: true, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@frank, @bob])
      expect(m[2].tagged_with(['fitter', 'happier', 'more productive', 'c++', 'java', 'ruby'], any: true, order_by_matching_tag_count: true, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@steve, @bob, @frank])
      expect(m[2].tagged_with(%w(c++ java ruby fitter), any: true, order_by_matching_tag_count: true, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@steve, @bob, @frank])
    end

    context 'wild: true' do
      it 'should use params as wildcards' do
        bob = m[2].create(name: 'Bob', tag_list: 'bob, tricia')
        frank = m[2].create(name: 'Frank', tag_list: 'bobby, jim')
        steve = m[2].create(name: 'Steve', tag_list: 'john, patricia')
        jim = m[2].create(name: 'Jim', tag_list: 'jim, steve')

        expect(m[2].tagged_with(%w(bob tricia), wild: true, any: true).to_a.sort_by { |o| o.id }).to eq([bob, frank, steve])
        expect(m[2].tagged_with(%w(bob tricia), wild: true, exclude: true).to_a).to eq([jim])
        expect(m[2].tagged_with('ji', wild: true, any: true).to_a).to eq([frank, jim])
      end
    end

    it 'should be able to find tagged on a custom tag context' do
      bob = m[2].create(name: 'Bob')
      bob.set_tag_list_on(:rotors, 'spinning, jumping')
      expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
      bob.save

      expect(m[2].tagged_with('spinning', on: :rotors).to_a).to eq([bob])
    end

    it 'should be able to use named scopes to chain tag finds' do
      make_bob_frank_steve! m

      # Let's only find those productive Rails developers
      expect(m[2].tagged_with('rails', on: :skills, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@bob, @frank])
      expect(m[2].tagged_with('happier', on: :tags, order: "taggable_#{ns_generic_att(m[2], :models)}.name").to_a).to eq([@bob, @steve])
      expect(m[2].tagged_with('rails', on: :skills).tagged_with('happier', on: :tags).to_a).to eq([@bob])
      expect(m[2].tagged_with('rails').tagged_with('happier', on: :tags).to_a).to eq([@bob])
    end

    it 'should be able to find tagged with only the matching tags' do
      m[2].create(name: 'Bob', tag_list: 'lazy, happier')
      m[2].create(name: 'Frank', tag_list: 'fitter, happier, inefficient')
      steve = m[2].create(name: 'Steve', tag_list: 'fitter, happier')

      expect(m[2].tagged_with('fitter, happier', match_all: true).to_a).to eq([steve])
    end

    it 'should be able to find tagged with only the matching tags for a context' do
      m[2].create(name: 'Bob', tag_list: 'lazy, happier', skill_list: 'ruby, rails, css')
      frank = m[2].create(name: 'Frank', tag_list: 'fitter, happier, inefficient', skill_list: 'css')
      m[2].create(name: 'Steve', tag_list: 'fitter, happier', skill_list: 'ruby, rails, css')

      expect(m[2].tagged_with('css', on: :skills, match_all: true).to_a).to eq([frank])
    end

    it 'should be able to find tagged with some excluded tags' do
      m[2].create(name: 'Bob', tag_list: 'happier, lazy')
      frank = m[2].create(name: 'Frank', tag_list: 'happier')
      steve = m[2].create(name: 'Steve', tag_list: 'happier')

      expect(m[2].tagged_with('lazy', exclude: true)).to include(frank, steve)
      expect(m[2].tagged_with('lazy', exclude: true).size).to eq(2)
    end

    it 'should return an empty scope for empty tags' do
      ['', ' ', nil, []].each do |tag|
        expect(m[2].tagged_with(tag)).to be_empty
      end
    end

    it 'should options key not be deleted' do
      options = {:exclude => true}
      m[2].tagged_with("foo", options)
      expect(options).to eq({:exclude => true})
    end

    it 'should not delete tags if not updated' do
      model = m[2].create(name: 'foo', tag_list: 'ruby, rails, programming')
      model.update_attributes(name: 'bar')
      model.reload
      expect(model.tag_list.sort).to eq(%w(ruby rails programming).sort)
    end

    context 'Duplicates' do
      context 'should not create duplicate taggings' do
        let(:bob) { m[2].create(name: 'Bob') }
        context 'case sensitive' do
          it '#add' do
            expect(lambda {
              bob.tag_list.add 'happier'
              bob.tag_list.add 'happier'
              bob.tag_list.add 'happier', 'rich', 'funny'
              bob.save
            }).to change(m[1], :count).by(3)
          end
          it '#<<' do
            expect(lambda {
              bob.tag_list << 'social'
              bob.tag_list << 'social'
              bob.tag_list << 'social' << 'wow'
              bob.save
            }).to change(m[1], :count).by(2)

          end

          it 'unicode' do

            expect(lambda {
              bob.tag_list.add 'ПРИВЕТ'
              bob.tag_list.add 'ПРИВЕТ'
              bob.tag_list.add 'ПРИВЕТ', 'ПРИВЕТ'
              bob.save
            }).to change(m[1], :count).by(1)

          end

          it '#=' do
            expect(lambda {
              bob.tag_list = ['Happy', 'Happy']
              bob.save
            }).to change(m[1], :count).by(1)
          end
        end
        context 'case insensitive' do
          before(:all) { ActsAsTaggableOn.force_lowercase = true }
          after(:all) { ActsAsTaggableOn.force_lowercase = false }

          it '#<<' do
            expect(lambda {
              bob.tag_list << 'Alone'
              bob.tag_list << 'AloNe'
              bob.tag_list << 'ALONE' << 'In The dark'
              bob.save
            }).to change(m[1], :count).by(2)

          end

          it '#add' do
            expect(lambda {
              bob.tag_list.add 'forever'
              bob.tag_list.add 'ForEver'
              bob.tag_list.add 'FOREVER', 'ALONE'
              bob.save
            }).to change(m[1], :count).by(2)
          end

          it 'unicode' do

            expect(lambda {
              bob.tag_list.add 'ПРИВЕТ'
              bob.tag_list.add 'привет', 'Привет'
              bob.save
            }).to change(m[1], :count).by(1)

          end

          it '#=' do
            expect(lambda {
              bob.tag_list = ['Happy', 'HAPPY']
              bob.save
            }).to change(m[1], :count).by(1)
          end


        end


      end

      xit 'should not duplicate tags added on different threads', if: supports_concurrency?, skip: 'FIXME, Deadlocks in travis' do
        #TODO, try with more threads and fix deadlock
        thread_count = 4
        barrier = Barrier.new thread_count

        expect {
          thread_count.times.map do |idx|
            Thread.start do
              connor = m[2].first_or_create(name: 'Connor')
              connor.tag_list = 'There, can, be, only, one'
              barrier.wait
              begin
                connor.save
              rescue ActsAsTaggableOn::DuplicateTagError
                # second save should succeed
                connor.save
              end
            end
          end.map(&:join)
        }.to change(m[0], :count).by(5)
      end
    end

    describe 'Associations' do
      before(:each) do
        @taggable = m[2].create(tag_list: 'awesome, epic')
      end

      it 'should not remove tags when creating associated objects' do
        @taggable.untaggable_models.create!
        @taggable.reload
        expect(@taggable.tag_list.size).to eq(2)
      end
    end

    describe 'grouped_column_names_for method' do
      it 'should return all column names joined for Tag GROUP clause' do
        # NOTE: type column supports an STI Tag subclass in the test suite, though
        # isn't included by default in the migration generator
        expect(@taggable.grouped_column_names_for(m[0]))
        .to eq("#{m[0].namespaced(:tags)}.id, #{m[0].namespaced(:tags)}.name, #{m[0].namespaced(:tags)}.#{m[0].namespaced(:taggings_count)}, #{m[0].namespaced(:tags)}.type")
      end

      it "should return all column names joined for #{m[2]} GROUP clause" do
        expect(@taggable.grouped_column_names_for(m[2])).to eq("taggable_#{ns_generic_att(m[0], :models)}.id, taggable_#{ns_generic_att(m[0], :models)}.name, taggable_#{ns_generic_att(m[0], :models)}.type")
      end

      it "should return all column names joined for #{m[5]} GROUP clause" do
        expect(@taggable.grouped_column_names_for(m[2])).to eq("taggable_#{ns_generic_att(m[0], :models)}.#{m[2].primary_key}, taggable_#{ns_generic_att(m[0], :models)}.name, taggable_#{ns_generic_att(m[0], :models)}.type")
      end
    end

    describe 'NonStandardIdTaggable' do
      before(:each) do
        @taggable = m[5].new(name: 'Bob Jones')
        @taggables = [@taggable, m[5].new(name: 'John Doe')]
      end

      it 'should have tag types' do
        [:tags, :languages, :skills, :needs, :offerings].each do |type|
          expect(m[5].tag_types).to include type
        end

        expect(@taggable.tag_types).to eq(m[5].tag_types)
      end

      it 'should have tag_counts_on' do
        expect(m[5].tag_counts_on(:tags)).to be_empty

        @taggable.tag_list = %w(awesome epic)
        @taggable.save

        expect(m[5].tag_counts_on(:tags).length).to eq(2)
        expect(@taggable.tag_counts_on(:tags).length).to eq(2)
      end

      it 'should have tags_on' do
        expect(m[5].tags_on(:tags)).to be_empty

        @taggable.tag_list = %w(awesome epic)
        @taggable.save

        expect(m[5].tags_on(:tags).length).to eq(2)
        expect(@taggable.tags_on(:tags).length).to eq(2)
      end

      it 'should be able to create tags' do
        @taggable.skill_list = 'ruby, rails, css'
        expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to be_truthy

        expect(-> {
          @taggable.save
        }).to change(m[0], :count).by(3)

        @taggable.reload
        expect(@taggable.skill_list.sort).to eq(%w(ruby rails css).sort)
      end

      it 'should be able to create tags through the tag list directly' do
        @taggable.tag_list_on(:test).add('hello')
        expect(@taggable.tag_list_cache_on(:test)).to_not be_empty
        expect(@taggable.tag_list_on(:test)).to eq(['hello'])

        @taggable.save
        @taggable.save_tags

        @taggable.reload
        expect(@taggable.tag_list_on(:test)).to eq(['hello'])
      end
    end

    describe 'Autogenerated methods' do
      it 'should be overridable' do
        expect(m[2].create(tag_list: 'woo').tag_list_submethod_called).to be_truthy
      end
    end

    # See https://github.com/mbleigh/acts-as-taggable-on/pull/457 for details
    context 'tag_counts and aggreating scopes, compatability with MySQL ' do
      before(:each) do
        m[2].new(:name => 'Barb Jones').tap { |t| t.tag_list = %w(awesome fun) }.save
        m[2].new(:name => 'John Doe').tap { |t| t.tag_list = %w(cool fun hella) }.save
        m[2].new(:name => 'Jo Doe').tap { |t| t.tag_list = %w(curious young naive sharp) }.save

        m[2].all.each { |t| t.save }
      end

      context 'Model.limit(x).tag_counts.sum(:tags_count)' do
        it 'should not break on Mysql' do
          # Activerecord 3.2 return a string
          expect(m[2].limit(2).tag_counts.sum('tags_count').to_i).to eq(5)
        end
      end

      context 'regression prevention, just making sure these esoteric queries still work' do
        context 'Model.tag_counts.limit(x)' do
          it 'should limit the tag objects (not very useful, of course)' do
            array_of_tag_counts = m[2].tag_counts.limit(2)
            expect(array_of_tag_counts.count).to eq(2)
          end
        end

        context 'Model.tag_counts.sum(:tags_count)' do
          it 'should limit the total tags used' do
            expect(m[2].tag_counts.sum(:tags_count).to_i).to eq(9)
          end
        end

        context 'Model.tag_counts.limit(2).sum(:tags_count)' do
          it 'limit should have no effect; this is just a sanity check' do
            expect(m[2].tag_counts.limit(2).sum(:tags_count).to_i).to eq(9)
          end
        end
      end
    end
  end

  describe 'Taggable model with json columns', if: postgresql_support_json? do
    before(:each) do
      @taggable = m[6].new(:name => 'Bob Jones')
      @taggables = [@taggable, m[6].new(:name => 'John Doe')]
    end

    it 'should be able to find by tag with context' do
      @taggable.skill_list = 'ruby, rails, css'
      @taggable.tag_list = 'bob, charlie'
      @taggable.save

      expect(m[6].tagged_with('ruby').first).to eq(@taggable)
      expect(m[6].tagged_with('ruby, css').first).to eq(@taggable)
      expect(m[6].tagged_with('bob', :on => :skills).first).to_not eq(@taggable)
      expect(m[6].tagged_with('bob', :on => :tags).first).to eq(@taggable)
    end

    it 'should be able to find tagged with any tag' do
      bob = m[6].create(:name => 'Bob', :tag_list => 'fitter, happier, more productive', :skill_list => 'ruby, rails, css')
      frank = m[6].create(:name => 'Frank', :tag_list => 'weaker, depressed, inefficient', :skill_list => 'ruby, rails, css')
      steve = m[6].create(:name => 'Steve', :tag_list => 'fitter, happier, more productive', :skill_list => 'c++, java, ruby')

      expect(m[6].tagged_with(%w(ruby java), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, frank, steve])
      expect(m[6].tagged_with(%w(c++ fitter), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, steve])
      expect(m[6].tagged_with(%w(depressed css), :order => 'taggable_model_with_jsons.name', :any => true).to_a).to eq([bob, frank])
    end
  end

end