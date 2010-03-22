require File.dirname(__FILE__) + '/../spec_helper'

describe "Tagger" do
  before(:each) do
    clean_database!
    @user = TaggableUser.new
    @taggable = TaggableModel.new(:name => "Bob Jones")
  end

  it "should have taggings" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_taggings.size == 2
  end

  it "should have tags" do
    @user.tag(@taggable, :with=>'ruby,scheme', :on=>:tags)
    @user.owned_tags.size == 2
  end
  
  it "should not overlap or lose tags from different users" do
    @user2 = TaggableUser.new
    lambda{
      @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)
      @user2.tag(@taggable, :with => 'java, python, lisp, ruby', :on => :tags)
    }.should change(Tagging, :count).by(6)

    @user.owned_tags.map(&:name).sort.should == %w(ruby scheme).sort
    @user2.owned_tags.map(&:name).sort.should == %w(java python lisp ruby).sort
    
    @taggable.tags_from(@user).sort.should == %w(ruby scheme).sort
    @taggable.tags_from(@user2).sort.should == %w(java lisp python ruby).sort
    
    @taggable.all_tags_list_on(:tags).sort.should == %w(ruby scheme java python lisp).sort
    @taggable.all_tags_on(:tags).size.should == 6
  end
  
  it "should not lose tags" do
    @taggable.update_attributes(:tag_list => 'ruby')
    @user.tag(@taggable, :with => 'ruby, scheme', :on => :tags)
    
    [@taggable, @user].each(&:reload)
    @taggable.tag_list.should == %w(ruby)
    @taggable.all_tags_list.sort.should == %w(ruby scheme).sort
    
    lambda {
      @taggable.update_attributes(:tag_list => "")
    }.should change(Tagging, :count).by(-1)
    
    @taggable.tag_list.should == []
    @taggable.all_tags_list.sort.should == %w(ruby scheme).sort
  end

  it "is tagger" do
    @user.is_tagger?.should(be_true)
  end  
end