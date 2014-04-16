require 'spec_helper'

describe ActsAsTaggableOn::Utils do
  describe 'like_operator' do
    before(:each) do
      clean_database!
      TaggableModel.acts_as_taggable_on(:tags, :languages, :skills, :needs, :offerings)
      @taggable = TaggableModel.new(:name => 'Bob Jones')
    end

    it 'should return \'ILIKE\' when the adapter is PostgreSQL' do
      TaggableModel.connection.stub(:adapter_name).and_return('PostgreSQL')
      expect(TaggableModel.send(:like_operator)).to eq('ILIKE')
    end

    it 'should return \'LIKE\' when the adapter is not PostgreSQL' do
      TaggableModel.connection.stub(:adapter_name).and_return('MySQL')
      expect(TaggableModel.send(:like_operator)).to eq('LIKE')
    end
  end
end
