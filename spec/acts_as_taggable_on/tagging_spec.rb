require 'spec_helper'

describe ActsAsTaggableOn::Tagging do
  before(:each) do
    clean_database!
    @tagging = ActsAsTaggableOn::Tagging.new
  end

  it 'should not be valid with a invalid tag' do
    @tagging.taggable = TaggableModel.create(name: 'Bob Jones')
    @tagging.tag = ActsAsTaggableOn::Tag.new(name: '')
    @tagging.context = 'tags'

    expect(@tagging).to_not be_valid

    expect(@tagging.errors[:tag_id]).to eq(['can\'t be blank'])
  end

  it 'should not create duplicate taggings' do
    @taggable = TaggableModel.create(name: 'Bob Jones')
    @tag = ActsAsTaggableOn::Tag.create(name: 'awesome')

    expect(-> {
      2.times { ActsAsTaggableOn::Tagging.create(taggable: @taggable, tag: @tag, context: 'tags') }
    }).to change(ActsAsTaggableOn::Tagging, :count).by(1)
  end
  
end
