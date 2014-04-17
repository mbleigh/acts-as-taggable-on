# encoding: utf-8
require 'spec_helper'

describe 'Taggable To Preserve Order' do
  before(:each) do
    clean_database!
    @taggable = OrderedTaggableModel.new(name: 'Bob Jones')
  end

  it 'should have tag types' do
    [:tags, :colours].each do |type|
      expect(OrderedTaggableModel.tag_types).to include type
    end

    expect(@taggable.tag_types).to eq(OrderedTaggableModel.tag_types)
  end

  it 'should have tag associations' do
    [:tags, :colours].each do |type|
      expect(@taggable.respond_to?(type)).to eq(true)
      expect(@taggable.respond_to?("#{type.to_s.singularize}_taggings")).to eq(true)
    end
  end

  it 'should have tag methods' do
    [:tags, :colours].each do |type|
      expect(@taggable.respond_to?("#{type.to_s.singularize}_list")).to eq(true)
      expect(@taggable.respond_to?("#{type.to_s.singularize}_list=")).to eq(true)
      expect(@taggable.respond_to?("all_#{type}_list")).to eq(true)
    end
  end

  it 'should return tag list in the order the tags were created' do
    # create
    @taggable.tag_list = 'rails, ruby, css'
    expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to eq(true)

    expect(-> {
      @taggable.save
    }).to change(ActsAsTaggableOn::Tag, :count).by(3)

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
    expect(@taggable.instance_variable_get('@tag_list').instance_of?(ActsAsTaggableOn::TagList)).to eq(true)

    expect(-> {
      @taggable.save
    }).to change(ActsAsTaggableOn::Tag, :count).by(3)

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
    ids = @taggable.tags.map { |t| t.taggings.first.id }
    expect(ids).to eq(ids.sort)

    # update
    @taggable.tag_list = 'rails, ruby, css, pow'
    @taggable.save

    @taggable.reload
    ids = @taggable.tags.map { |t| t.taggings.first.id }
    expect(ids).to eq(ids.sort)
  end
end

describe 'Taggable' do
  before(:each) do
    clean_database!
    @taggable = TaggableModel.new(name: 'Bob Jones')
    @taggables = [@taggable, TaggableModel.new(name: 'John Doe')]
  end

  it 'should have tag types' do
    [:tags, :languages, :skills, :needs, :offerings].each do |type|
      expect(TaggableModel.tag_types).to include type
    end

    expect(@taggable.tag_types).to eq(TaggableModel.tag_types)
  end

  it 'should have tag_counts_on' do
    expect(TaggableModel.tag_counts_on(:tags)).to be_empty

    @taggable.tag_list = %w(awesome epic)
    @taggable.save

    expect(TaggableModel.tag_counts_on(:tags).length).to eq(2)
    expect(@taggable.tag_counts_on(:tags).length).to eq(2)
  end

  it 'should have tags_on' do
    expect(TaggableModel.tags_on(:tags)).to be_empty

    @taggable.tag_list = %w(awesome epic)
    @taggable.save

    expect(TaggableModel.tags_on(:tags).length).to eq(2)
    expect(@taggable.tags_on(:tags).length).to eq(2)
  end

  it 'should return [] right after create' do
    blank_taggable = TaggableModel.new(name: 'Bob Jones')
    expect(blank_taggable.tag_list).to be_empty
  end

  it 'should be able to create tags' do
    @taggable.skill_list = 'ruby, rails, css'
    expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to eq(true)

    expect(-> {
      @taggable.save
    }).to change(ActsAsTaggableOn::Tag, :count).by(3)

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

    @found_taggables_by_tag = TaggableModel.joins(:tags).where(tags: {name: ['bob']})
    @found_taggables_by_skill = TaggableModel.joins(:skills).where(tags: {name: ['ruby']})

    expect(@found_taggables_by_tag).to include @taggables[0]
    expect(@found_taggables_by_tag).to_not include @taggables[1]
    expect(@found_taggables_by_skill).to include @taggables[0]
    expect(@found_taggables_by_skill).to_not include @taggables[1]
  end

  it 'should be able to find by tag' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').first).to eq(@taggable)
  end

  it 'should be able to get a count with find by tag when using a group by' do
    @taggable.skill_list = 'ruby'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').group(:created_at).count.count).to eq(1)
  end

  it 'should be able to find by tag with context' do
    @taggable.skill_list = 'ruby, rails, css'
    @taggable.tag_list = 'bob, charlie'
    @taggable.save

    expect(TaggableModel.tagged_with('ruby').first).to eq(@taggable)
    expect(TaggableModel.tagged_with('ruby, css').first).to eq(@taggable)
    expect(TaggableModel.tagged_with('bob', on: :skills).first).to_not eq(@taggable)
    expect(TaggableModel.tagged_with('bob', on: :tags).first).to eq(@taggable)
  end

  it 'should not care about case' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby')
    TaggableModel.create(name: 'Frank', tag_list: 'Ruby')

    expect(ActsAsTaggableOn::Tag.all.size).to eq(1)
    expect(TaggableModel.tagged_with('ruby').to_a).to eq(TaggableModel.tagged_with('Ruby').to_a)
  end

  unless ActsAsTaggableOn::Tag.using_sqlite?
    it 'should not care about case for unicode names' do
      ActsAsTaggableOn.strict_case_match = false
      TaggableModel.create(name: 'Anya', tag_list: 'ПРИВЕТ')
      TaggableModel.create(name: 'Igor', tag_list: 'привет')
      TaggableModel.create(name: 'Katia', tag_list: 'ПРИВЕТ')

      expect(ActsAsTaggableOn::Tag.all.size).to eq(1)
      expect(TaggableModel.tagged_with('привет').to_a).to eq(TaggableModel.tagged_with('ПРИВЕТ').to_a)
    end
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
        TaggableModel.create(values)
        expect(TaggableModel.tagged_with(values[:tag_list]).count).to eq(1)
      end
    end
  end

  it 'should be able to get tag counts on model as a whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')
    expect(TaggableModel.tag_counts).to_not be_empty
    expect(TaggableModel.skill_counts).to_not be_empty
  end

  it 'should be able to get all tag counts on model as whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.all_tag_counts).to_not be_empty
    expect(TaggableModel.all_tag_counts(order: 'tags.id').first.count).to eq(3) # ruby
  end

  it 'should be able to get all tags on model as whole' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.all_tags).to_not be_empty
    expect(TaggableModel.all_tags(order: 'tags.id').first.name).to eq('ruby')
  end

  it 'should be able to use named scopes to chain tag finds by any tags by context' do
    bob = TaggableModel.create(name: 'Bob', need_list: 'rails', offering_list: 'c++')
    TaggableModel.create(name: 'Frank', need_list: 'css', offering_list: 'css')
    TaggableModel.create(name: 'Steve', need_list: 'c++', offering_list: 'java')

    # Let's only find those who need rails or css and are offering c++ or java
    expect(TaggableModel.tagged_with(['rails, css'], on: :needs, any: true).tagged_with(['c++', 'java'], on: :offerings, any: true).to_a).to eq([bob])
  end

  it 'should not return read-only records' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    expect(TaggableModel.tagged_with('ruby').first).to_not be_readonly
  end

  it 'should be able to get scoped tag counts' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').tag_counts(order: 'tags.id').first.count).to eq(2) # ruby
    expect(TaggableModel.tagged_with('ruby').skill_counts.first.count).to eq(1) # ruby
  end

  it 'should be able to get all scoped tag counts' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').all_tag_counts(order: 'tags.id').first.count).to eq(3) # ruby
  end

  it 'should be able to get all scoped tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby')

    expect(TaggableModel.tagged_with('ruby').all_tags(order: 'tags.id').first.name).to eq('ruby')
  end

  it 'should only return tag counts for the available scope' do
    frank = TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby, java')

    expect(TaggableModel.tagged_with('rails').all_tag_counts.size).to eq(3)
    expect(TaggableModel.tagged_with('rails').all_tag_counts.any? { |tag| tag.name == 'java' }).to eq(false)

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    expect(TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tag_counts.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins(untaggable_models: :taggable_model).all_tag_counts.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tag_counts.size).to eq(2)
  end

  it 'should only return tags for the available scope' do
    frank = TaggableModel.create(name: 'Frank', tag_list: 'ruby, rails')
    TaggableModel.create(name: 'Bob', tag_list: 'ruby, rails, css')
    TaggableModel.create(name: 'Charlie', skill_list: 'ruby, java')

    expect(TaggableModel.tagged_with('rails').all_tags.count).to eq(3)
    expect(TaggableModel.tagged_with('rails').all_tags.any? { |tag| tag.name == 'java' }).to eq(false)

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    expect(TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tags.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins(untaggable_models: :taggable_model).all_tags.size).to eq(2)
    expect(TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tags.size).to eq(2)
  end

  it 'should be able to set a custom tag context list' do
    bob = TaggableModel.create(name: 'Bob')
    bob.set_tag_list_on(:rotors, 'spinning, jumping')
    expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
    bob.save
    bob.reload
    expect(bob.tags_on(:rotors)).to_not be_empty
  end

  it 'should be able to find tagged' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with('ruby', order: 'taggable_models.name').to_a).to eq([bob, frank, steve])
    expect(TaggableModel.tagged_with('ruby, rails', order: 'taggable_models.name').to_a).to eq([bob, frank])
    expect(TaggableModel.tagged_with(%w(ruby rails), order: 'taggable_models.name').to_a).to eq([bob, frank])
  end

  it 'should be able to find tagged with quotation marks' do
    bob = TaggableModel.create(name: 'Bob', tag_list: "fitter, happier, more productive, 'I love the ,comma,'")
    expect(TaggableModel.tagged_with("'I love the ,comma,'")).to include(bob)
  end

  it 'should be able to find tagged with invalid tags' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive')
    expect(TaggableModel.tagged_with('sad, happier')).to_not include(bob)
  end

  it 'should be able to find tagged with any tag' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with(%w(ruby java), order: 'taggable_models.name', any: true).to_a).to eq([bob, frank, steve])
    expect(TaggableModel.tagged_with(%w(c++ fitter), order: 'taggable_models.name', any: true).to_a).to eq([bob, steve])
    expect(TaggableModel.tagged_with(%w(depressed css), order: 'taggable_models.name', any: true).to_a).to eq([bob, frank])
  end

  it 'should be able to order by number of matching tags when matching any' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, ruby')

    expect(TaggableModel.tagged_with(%w(ruby java), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
    expect(TaggableModel.tagged_with(%w(c++ fitter), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob])
    expect(TaggableModel.tagged_with(%w(depressed css), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([frank, bob])
    expect(TaggableModel.tagged_with(['fitter', 'happier', 'more productive', 'c++', 'java', 'ruby'], any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
    expect(TaggableModel.tagged_with(%w(c++ java ruby fitter), any: true, order_by_matching_tag_count: true, order: 'taggable_models.name').to_a).to eq([steve, bob, frank])
  end

  context 'wild: true' do
    it 'should use params as wildcards' do
      bob = TaggableModel.create(name: 'Bob', tag_list: 'bob, tricia')
      frank = TaggableModel.create(name: 'Frank', tag_list: 'bobby, jim')
      steve = TaggableModel.create(name: 'Steve', tag_list: 'john, patricia')
      jim = TaggableModel.create(name: 'Jim', tag_list: 'jim, steve')

      expect(TaggableModel.tagged_with(%w(bob tricia), wild: true, any: true).to_a.sort_by { |o| o.id }).to eq([bob, frank, steve])
      expect(TaggableModel.tagged_with(%w(bob tricia), wild: true, exclude: true).to_a).to eq([jim])
    end
  end

  it 'should be able to find tagged on a custom tag context' do
    bob = TaggableModel.create(name: 'Bob')
    bob.set_tag_list_on(:rotors, 'spinning, jumping')
    expect(bob.tag_list_on(:rotors)).to eq(%w(spinning jumping))
    bob.save

    expect(TaggableModel.tagged_with('spinning', on: :rotors).to_a).to eq([bob])
  end

  it 'should be able to use named scopes to chain tag finds' do
    bob = TaggableModel.create(name: 'Bob', tag_list: 'fitter, happier, more productive', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'weaker, depressed, inefficient', skill_list: 'ruby, rails, css')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier, more productive', skill_list: 'c++, java, python')

    # Let's only find those productive Rails developers
    expect(TaggableModel.tagged_with('rails', on: :skills, order: 'taggable_models.name').to_a).to eq([bob, frank])
    expect(TaggableModel.tagged_with('happier', on: :tags, order: 'taggable_models.name').to_a).to eq([bob, steve])
    expect(TaggableModel.tagged_with('rails', on: :skills).tagged_with('happier', on: :tags).to_a).to eq([bob])
    expect(TaggableModel.tagged_with('rails').tagged_with('happier', on: :tags).to_a).to eq([bob])
  end

  it 'should be able to find tagged with only the matching tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'lazy, happier')
    TaggableModel.create(name: 'Frank', tag_list: 'fitter, happier, inefficient')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier')

    expect(TaggableModel.tagged_with('fitter, happier', match_all: true).to_a).to eq([steve])
  end

  it 'should be able to find tagged with only the matching tags for a context' do
    TaggableModel.create(name: 'Bob', tag_list: 'lazy, happier', skill_list: 'ruby, rails, css')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'fitter, happier, inefficient', skill_list: 'css')
    TaggableModel.create(name: 'Steve', tag_list: 'fitter, happier', skill_list: 'ruby, rails, css')

    expect(TaggableModel.tagged_with('css', on: :skills, match_all: true).to_a).to eq([frank])
  end

  it 'should be able to find tagged with some excluded tags' do
    TaggableModel.create(name: 'Bob', tag_list: 'happier, lazy')
    frank = TaggableModel.create(name: 'Frank', tag_list: 'happier')
    steve = TaggableModel.create(name: 'Steve', tag_list: 'happier')

    expect(TaggableModel.tagged_with('lazy', exclude: true)).to include(frank, steve)
    expect(TaggableModel.tagged_with('lazy', exclude: true).size).to eq(2)
  end

  it 'should return an empty scope for empty tags' do
    ['', ' ', nil, []].each do |tag|
      expect(TaggableModel.tagged_with(tag)).to be_empty
    end
  end

  context 'Duplicates' do
    it 'should not create duplicate taggings' do
      bob = TaggableModel.create(name: 'Bob')
      expect(-> {
        bob.tag_list << 'happier' << 'happier'
        bob.save
      }).to change(ActsAsTaggableOn::Tagging, :count).by(1)
    end

    pending 'should not create duplicate taggings [force lowercase]'

    if ActsAsTaggableOn::Utils.supports_concurrency?
      xit 'should not duplicate tags added on different threads' do
        #TODO, try with more threads and fix deadlock
        thread_count = 4
        barrier = Barrier.new thread_count

        expect {
          thread_count.times.map do |idx|
            Thread.start do
              connor = TaggableModel.first_or_create(name: 'Connor')
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
        }.to change(ActsAsTaggableOn::Tag, :count).by(5)
      end
    end
  end

  describe 'Associations' do
    before(:each) do
      @taggable = TaggableModel.create(tag_list: 'awesome, epic')
    end

    it 'should not remove tags when creating associated objects' do
      @taggable.untaggable_models.create!
      @taggable.reload
      expect(@taggable.tag_list.size).to eq(2)
    end
  end

  describe 'grouped_column_names_for method' do
    it 'should return all column names joined for Tag GROUP clause' do
      expect(@taggable.grouped_column_names_for(ActsAsTaggableOn::Tag)).to eq('tags.id, tags.name, tags.taggings_count')
    end

    it 'should return all column names joined for TaggableModel GROUP clause' do
      expect(@taggable.grouped_column_names_for(TaggableModel)).to eq('taggable_models.id, taggable_models.name, taggable_models.type')
    end

    it 'should return all column names joined for NonStandardIdTaggableModel GROUP clause' do
      expect(@taggable.grouped_column_names_for(TaggableModel)).to eq("taggable_models.#{TaggableModel.primary_key}, taggable_models.name, taggable_models.type")
    end
  end

  describe 'NonStandardIdTaggable' do
    before(:each) do
      clean_database!
      @taggable = NonStandardIdTaggableModel.new(name: 'Bob Jones')
      @taggables = [@taggable, NonStandardIdTaggableModel.new(name: 'John Doe')]
    end

    it 'should have tag types' do
      [:tags, :languages, :skills, :needs, :offerings].each do |type|
        expect(NonStandardIdTaggableModel.tag_types).to include type
      end

      expect(@taggable.tag_types).to eq(NonStandardIdTaggableModel.tag_types)
    end

    it 'should have tag_counts_on' do
      expect(NonStandardIdTaggableModel.tag_counts_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(NonStandardIdTaggableModel.tag_counts_on(:tags).length).to eq(2)
      expect(@taggable.tag_counts_on(:tags).length).to eq(2)
    end

    it 'should have tags_on' do
      expect(NonStandardIdTaggableModel.tags_on(:tags)).to be_empty

      @taggable.tag_list = %w(awesome epic)
      @taggable.save

      expect(NonStandardIdTaggableModel.tags_on(:tags).length).to eq(2)
      expect(@taggable.tags_on(:tags).length).to eq(2)
    end

    it 'should be able to create tags' do
      @taggable.skill_list = 'ruby, rails, css'
      expect(@taggable.instance_variable_get('@skill_list').instance_of?(ActsAsTaggableOn::TagList)).to eq(true)

      expect(-> {
        @taggable.save
      }).to change(ActsAsTaggableOn::Tag, :count).by(3)

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

  describe 'Dirty Objects' do
    context 'with un-contexted tags' do
      before(:each) do
        @taggable = TaggableModel.create(tag_list: 'awesome, epic')
      end

      context 'when tag_list changed' do
        before(:each) do
          expect(@taggable.changes).to be_empty
          @taggable.tag_list = 'one'
        end

        it 'should show changes of dirty object' do
          expect(@taggable.changes).to eq({'tag_list' => ['awesome, epic', ['one']]})
        end

        it 'flags tag_list as changed' do
          expect(@taggable.tag_list_changed?).to eq(true)
        end

        it 'preserves original value' do
          expect(@taggable.tag_list_was).to eq('awesome, epic')
        end

        it 'shows what the change was' do
          expect(@taggable.tag_list_change).to eq(['awesome, epic', ['one']])
        end
      end

      context 'when tag_list is the same' do
        before(:each) do
          @taggable.tag_list = 'awesome, epic'
        end

        it 'is not flagged as changed' do
          expect(@taggable.tag_list_changed?).to eq(false)
        end

        it 'does not show any changes to the taggable item' do
          expect(@taggable.changes).to be_empty
        end

        context "and using a delimiter different from a ','" do
          before do
            @old_delimiter = ActsAsTaggableOn.delimiter
            ActsAsTaggableOn.delimiter = ';'
          end

          after do
            ActsAsTaggableOn.delimiter = @old_delimiter
          end

          it 'does not show any changes to the taggable item when using array assignments' do
            @taggable.tag_list = %w(awesome epic)
            expect(@taggable.changes).to be_empty
          end
        end
      end
    end

    context 'with context tags' do
      before(:each) do
        @taggable = TaggableModel.create('language_list' => 'awesome, epic')
      end

      context 'when language_list changed' do
        before(:each) do
          expect(@taggable.changes).to be_empty
          @taggable.language_list = 'one'
        end

        it 'should show changes of dirty object' do
          expect(@taggable.changes).to eq({'language_list' => ['awesome, epic', ['one']]})
        end

        it 'flags language_list as changed' do
          expect(@taggable.language_list_changed?).to eq(true)
        end

        it 'preserves original value' do
          expect(@taggable.language_list_was).to eq('awesome, epic')
        end

        it 'shows what the change was' do
          expect(@taggable.language_list_change).to eq(['awesome, epic', ['one']])
        end

        it 'shows what the changes were' do
          expect(@taggable.language_list_changes).to eq(['awesome, epic', ['one']])
        end
      end

      context 'when language_list is the same' do
        before(:each) do
          @taggable.language_list = 'awesome, epic'
        end

        it 'is not flagged as changed' do
          expect(@taggable.language_list_changed?).to eq(false)
        end

        it 'does not show any changes to the taggable item' do
          expect(@taggable.changes).to be_empty
        end
      end
    end
  end

  describe 'Autogenerated methods' do
    it 'should be overridable' do
      expect(TaggableModel.create(tag_list: 'woo').tag_list_submethod_called).to eq(true)
    end
  end
end
