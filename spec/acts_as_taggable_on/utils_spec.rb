require 'spec_helper'

describe ActsAsTaggableOn::Utils do
  describe '#like_operator' do
    it 'should return \'ILIKE\' when the adapter is PostgreSQL' do
      allow(TaggableModel.connection).to receive(:adapter_name) { 'PostgreSQL' }
      expect(TaggableModel.like_operator).to eq('ILIKE')
    end

    it 'should return \'LIKE\' when the adapter is not PostgreSQL' do
      allow(TaggableModel.connection).to receive(:adapter_name) { 'MySQL' }
      expect(TaggableModel.like_operator).to eq('LIKE')
    end
  end
end
