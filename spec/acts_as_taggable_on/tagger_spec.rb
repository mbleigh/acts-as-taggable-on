require 'spec_helper'

describe "Tagger" do
  before(:each) do
    clean_database!
    @user = User.create
    @taggable = TaggableModel.create(:name => "Bob Jones")
  end

  it "should have taggings" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_taggings.size == 2
  end

  it "should have tags" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_tags.size == 2
  end

  it "should scope objects returned by tagged_with by owners" do
    @taggable2 = TaggableModel.create(:name => "Jim Jones")
    @taggable3 = TaggableModel.create(:name => "Jane Doe")

    @user2 = User.new
    @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)
    @user2.tag(@taggable2, :with => 'ruby, scheme', :on => :tags)
    @user2.tag(@taggable3, :with => 'ruby, scheme', :on => :tags)

    TaggableModel.tagged_with(%w(ruby scheme), :owned_by => @user).count.should == 1
    TaggableModel.tagged_with(%w(ruby scheme), :owned_by => @user2).count.should == 2
  end

  it "only returns objects tagged by owned_by when any is true" do
    @user2 = User.new
    @taggable2 = TaggableModel.create(:name => "Jim Jones")
    @taggable3 = TaggableModel.create(:name => "Jane Doe")

    @user.tag(@taggable, :with => 'ruby', :on => :tags)
    @user.tag(@taggable2, :with => 'java', :on => :tags)
    @user2.tag(@taggable3, :with => 'ruby', :on => :tags)

    tags = TaggableModel.tagged_with(%w(ruby java), :owned_by => @user, :any => true)
    tags.should match_array [@taggable, @taggable2]
  end

  it "only returns objects tagged by owned_by when exclude is true" do
    @user2 = User.new
    @taggable2 = TaggableModel.create(:name => "Jim Jones")
    @taggable3 = TaggableModel.create(:name => "Jane Doe")

    @user.tag(@taggable, :with => 'ruby', :on => :tags)
    @user.tag(@taggable2, :with => 'java', :on => :tags)
    @user2.tag(@taggable3, :with => 'java', :on => :tags)

    tags = TaggableModel.tagged_with(%w(ruby), :owned_by => @user, :exclude => true)
    tags.should match_array [@taggable2]
  end

  it "should not overlap tags from different taggers" do
    @user2 = User.new
    lambda{
      @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)
      @user2.tag(@taggable, :with => 'java, python, lisp, ruby', :on => :tags)
    }.should change(ActsAsTaggableOn::Tagging, :count).by(6)

    [@user, @user2, @taggable].each(&:reload)

    @user.owned_tags.map(&:name).sort.should == %w(ruby scheme).sort
    @user2.owned_tags.map(&:name).sort.should == %w(java python lisp ruby).sort

    @taggable.tags_from(@user).sort.should == %w(ruby scheme).sort
    @taggable.tags_from(@user2).sort.should == %w(java lisp python ruby).sort

    @taggable.all_tags_list.sort.should == %w(ruby scheme java python lisp).sort
    @taggable.all_tags_on(:tags).size.should == 5
  end

  it "should not lose tags from different taggers" do
    @user2 = User.create
    @user2.tag(@taggable, :with => 'java, python, lisp, ruby', :on => :tags)
    @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)

    lambda {
      @user2.tag(@taggable, :with => 'java, python, lisp', :on => :tags)
    }.should change(ActsAsTaggableOn::Tagging, :count).by(-1)

    [@user, @user2, @taggable].each(&:reload)

    @taggable.tags_from(@user).sort.should == %w(ruby scheme).sort
    @taggable.tags_from(@user2).sort.should == %w(java python lisp).sort

    @taggable.all_tags_list.sort.should == %w(ruby scheme java python lisp).sort
    @taggable.all_tags_on(:tags).length.should == 5
  end

  it "should not lose tags" do
    @user2 = User.create

    @user.tag(@taggable, :with => 'awesome', :on => :tags)
    @user2.tag(@taggable, :with => 'awesome, epic', :on => :tags)

    lambda {
      @user2.tag(@taggable, :with => 'epic', :on => :tags)
    }.should change(ActsAsTaggableOn::Tagging, :count).by(-1)

    @taggable.reload
    @taggable.all_tags_list.should include('awesome')
    @taggable.all_tags_list.should include('epic')
  end

  it "should not lose tags" do
    @taggable.update_attributes(:tag_list => 'ruby')
    @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)

    [@taggable, @user].each(&:reload)
    @taggable.tag_list.should == %w(ruby)
    @taggable.all_tags_list.sort.should == %w(ruby scheme).sort

    lambda {
      @taggable.update_attributes(:tag_list => "")
    }.should change(ActsAsTaggableOn::Tagging, :count).by(-1)

    @taggable.tag_list.should == []
    @taggable.all_tags_list.sort.should == %w(ruby scheme).sort
  end

  it "is tagger" do
    @user.is_tagger?.should(be_true)
  end

  it "should skip save if skip_save is passed as option" do
    lambda {
      @user.tag(@taggable, :with => 'epic', :on => :tags, :skip_save => true)
    }.should_not change(ActsAsTaggableOn::Tagging, :count)
  end

end
