# encoding: utf-8
require 'spec_helper'
require 'db/migrate/2_add_missing_unique_indices.rb'

shared_examples_for 'without unique index' do
  before { AddMissingUniqueIndices.down }
  after { ActsAsTaggableOn::Tag.delete_all; AddMissingUniqueIndices.up }
end

describe ActsAsTaggableOn::Tag do
  before(:each) do
    @tag = ActsAsTaggableOn::Tag.new
    @user = TaggableModel.create(name: 'Pablo')
  end



  describe 'named like any' do
    context 'case insensitive collation and unique index on tag name' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        before(:each) do
          ActsAsTaggableOn::Tag.create(name: 'Awesome')
          ActsAsTaggableOn::Tag.create(name: 'epic')
        end

        it 'should find both tags' do
          expect(ActsAsTaggableOn::Tag.named_like_any(%w(awesome epic)).count).to eq(2)
        end
      end
    end

    context 'case insensitive collation without indexes or case sensitive collation with indexes' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        include_context 'without unique index'
      end

      before(:each) do
        ActsAsTaggableOn::Tag.create(name: 'Awesome')
        ActsAsTaggableOn::Tag.create(name: 'awesome')
        ActsAsTaggableOn::Tag.create(name: 'epic')
      end

      it 'should find both tags' do
        expect(ActsAsTaggableOn::Tag.named_like_any(%w(awesome epic)).count).to eq(3)
      end
    end
  end

  describe 'find or create by name' do
    before(:each) do
      @tag.name = 'awesome'
      @tag.save
    end

    it 'should find by name' do
      expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('awesome')).to eq(@tag)
    end

    it 'should find by name case insensitive' do
      expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('AWESOME')).to eq(@tag)
    end

    it 'should create by name' do
      expect(-> {
        ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('epic')
      }).to change(ActsAsTaggableOn::Tag, :count).by(1)
    end
  end

  unless ActsAsTaggableOn::Utils.using_sqlite?
    describe 'find or create by unicode name' do
      before(:each) do
        @tag.name = 'привет'
        @tag.save
      end

      it 'should find by name' do
        expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('привет')).to eq(@tag)
      end

      it 'should find by name case insensitive' do
        expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('ПРИВЕТ')).to eq(@tag)
      end

      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        it 'should find by name accent insensitive' do
          @tag.name = 'inupiat'
          @tag.save
          expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('Iñupiat')).to eq(@tag)
        end
      end
    end
  end

  describe 'find or create all by any name' do
    before(:each) do
      @tag.name = 'awesome'
      @tag.save
    end

    it 'should find by name' do
      expect(ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('awesome')).to eq([@tag])
    end

    it 'should find by name case insensitive' do
      expect(ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('AWESOME')).to eq([@tag])
    end

    context 'case sensitive' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        include_context 'without unique index'
      end

      it 'should find by name case sensitive' do
        ActsAsTaggableOn.strict_case_match = true
        expect {
          ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('AWESOME')
        }.to change(ActsAsTaggableOn::Tag, :count).by(1)
      end
    end

    it 'should create by name' do
      expect {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('epic')
      }.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    context 'case sensitive' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        include_context 'without unique index'
      end

      it 'should find or create by name case sensitive' do
        ActsAsTaggableOn.strict_case_match = true
        expect {
          expect(ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('AWESOME', 'awesome').map(&:name)).to eq(%w(AWESOME awesome))
        }.to change(ActsAsTaggableOn::Tag, :count).by(1)
      end
    end

    it 'should find or create by name' do
      expect {
        expect(ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name('awesome', 'epic').map(&:name)).to eq(%w(awesome epic))
      }.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it 'should return an empty array if no tags are specified' do
      expect(ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name([])).to be_empty
    end
  end

  it 'should require a name' do
    @tag.valid?
    #TODO, we should find another way to check this
    expect(@tag.errors[:name]).to eq(["can't be blank"])

    @tag.name = 'something'
    @tag.valid?

    expect(@tag.errors[:name]).to be_empty
  end

  it 'should limit the name length to 255 or less characters' do
    @tag.name = 'fgkgnkkgjymkypbuozmwwghblmzpqfsgjasflblywhgkwndnkzeifalfcpeaeqychjuuowlacmuidnnrkprgpcpybarbkrmziqihcrxirlokhnzfvmtzixgvhlxzncyywficpraxfnjptxxhkqmvicbcdcynkjvziefqzyndxkjmsjlvyvbwraklbalykyxoliqdlreeykuphdtmzfdwpphmrqvwvqffojkqhlzvinqajsxbszyvrqqyzusxranr'
    @tag.valid?
    #TODO, we should find another way to check this
    expect(@tag.errors[:name]).to eq(['is too long (maximum is 255 characters)'])

    @tag.name = 'fgkgnkkgjymkypbuozmwwghblmzpqfsgjasflblywhgkwndnkzeifalfcpeaeqychjuuowlacmuidnnrkprgpcpybarbkrmziqihcrxirlokhnzfvmtzixgvhlxzncyywficpraxfnjptxxhkqmvicbcdcynkjvziefqzyndxkjmsjlvyvbwraklbalykyxoliqdlreeykuphdtmzfdwpphmrqvwvqffojkqhlzvinqajsxbszyvrqqyzusxran'
    @tag.valid?
    expect(@tag.errors[:name]).to be_empty
  end

  it 'should equal a tag with the same name' do
    @tag.name = 'awesome'
    new_tag = ActsAsTaggableOn::Tag.new(name: 'awesome')
    expect(new_tag).to eq(@tag)
  end

  it 'should return its name when to_s is called' do
    @tag.name = 'cool'
    expect(@tag.to_s).to eq('cool')
  end

  it 'have named_scope named(something)' do
    @tag.name = 'cool'
    @tag.save!
    expect(ActsAsTaggableOn::Tag.named('cool')).to include(@tag)
  end

  it 'have named_scope named_like(something)' do
    @tag.name = 'cool'
    @tag.save!
    @another_tag = ActsAsTaggableOn::Tag.create!(name: 'coolip')
    expect(ActsAsTaggableOn::Tag.named_like('cool')).to include(@tag, @another_tag)
  end

  describe 'escape wildcard symbols in like requests' do
    before(:each) do
      @tag.name = 'cool'
      @tag.save
      @another_tag = ActsAsTaggableOn::Tag.create!(name: 'coo%')
      @another_tag2 = ActsAsTaggableOn::Tag.create!(name: 'coolish')
    end

    it "return escaped result when '%' char present in tag" do
      expect(ActsAsTaggableOn::Tag.named_like('coo%')).to_not include(@tag)
      expect(ActsAsTaggableOn::Tag.named_like('coo%')).to include(@another_tag)
    end

  end

  describe 'when using strict_case_match' do
    before do
      ActsAsTaggableOn.strict_case_match = true
      @tag.name = 'awesome'
      @tag.save!
    end

    after do
      ActsAsTaggableOn.strict_case_match = false
    end

    it 'should find by name' do
      expect(ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('awesome')).to eq(@tag)
    end

    context 'case sensitive' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        include_context 'without unique index'
      end

      it 'should find by name case sensitively' do
        expect {
          ActsAsTaggableOn::Tag.find_or_create_with_like_by_name('AWESOME')
        }.to change(ActsAsTaggableOn::Tag, :count)

        expect(ActsAsTaggableOn::Tag.last.name).to eq('AWESOME')
      end
    end

    context 'case sensitive' do
      if ActsAsTaggableOn::Utils.using_case_insensitive_collation?
        include_context 'without unique index'
      end

      it 'should have a named_scope named(something) that matches exactly' do
        uppercase_tag = ActsAsTaggableOn::Tag.create(name: 'Cool')
        @tag.name = 'cool'
        @tag.save!

        expect(ActsAsTaggableOn::Tag.named('cool')).to include(@tag)
        expect(ActsAsTaggableOn::Tag.named('cool')).to_not include(uppercase_tag)
      end
    end

    it 'should not change enconding' do
      name = "\u3042"
      original_encoding = name.encoding
      record = ActsAsTaggableOn::Tag.find_or_create_with_like_by_name(name)
      record.reload
      expect(record.name.encoding).to eq(original_encoding)
    end
  end

  describe 'name uniqeness validation' do
    let(:duplicate_tag) { ActsAsTaggableOn::Tag.new(name: 'ror') }

    before { ActsAsTaggableOn::Tag.create(name: 'ror') }

    context "when don't need unique names" do
      include_context 'without unique index'
      it 'should not run uniqueness validation' do
        allow(duplicate_tag).to receive(:validates_name_uniqueness?) { false }
        duplicate_tag.save
        expect(duplicate_tag).to be_persisted
      end
    end

    context 'when do need unique names' do
      it 'should run uniqueness validation' do
        expect(duplicate_tag).to_not be_valid
      end

      it 'add error to name' do
        duplicate_tag.save

        expect(duplicate_tag.errors.size).to eq(1)
        expect(duplicate_tag.errors.messages[:name]).to include('has already been taken')
      end
    end
  end
end
