require 'spec_helper'

describe "acts_as_tagger" do
  before(:each) do
    clean_database!
  end
  
  describe "Tagger Method Generation" do
    before(:each) do
      @tagger = User.new
    end

    it "should add #is_tagger? query method to the class-side" do
      User.should respond_to(:is_tagger?)
    end
    
    it "should return true from the class-side #is_tagger?" do
      User.is_tagger?.should be_true
    end
    
    it "should return false from the base #is_tagger?" do
      ActiveRecord::Base.is_tagger?.should be_false
    end
    
    it "should add #is_tagger? query method to the singleton" do
      @tagger.should respond_to(:is_tagger?)
    end
    
    it "should add #tag method on the instance-side" do
      @tagger.should respond_to(:tag)
    end
    
    it "should generate an association for #owned_taggings and #owned_tags" do
      @tagger.should respond_to(:owned_taggings, :owned_tags)
    end
  end
  
  describe "#tag" do
    context 'when called with a non-existent tag context' do
      before(:each) do
        @tagger = User.new
        @taggable = TaggableModel.new(:name=>"Richard Prior")
      end
      
      it "should by default not throw an exception " do
        @taggable.tag_list_on(:foo).should be_empty
        lambda {
          @tagger.tag(@taggable, :with=>'this, and, that', :on=>:foo)
        }.should_not raise_error
      end
      
      it 'should by default create the tag context on-the-fly' do
        @taggable.tag_list_on(:here_ond_now).should be_empty
        @tagger.tag(@taggable, :with=>'that', :on => :here_ond_now)
        @taggable.tag_list_on(:here_ond_now).should_not include('that')
        @taggable.all_tags_list_on(:here_ond_now).should include('that')
      end
      
      it "should show all the tag list when both public and owned tags exist" do
        @taggable.tag_list = 'ruby, python'
        @tagger.tag(@taggable, :with => 'java, lisp', :on => :tags)
        @taggable.all_tags_on(:tags).map(&:name).sort.should == %w(ruby python java lisp).sort
      end
      
      it "should not add owned tags to the common list" do
        @taggable.tag_list = 'ruby, python'
        @tagger.tag(@taggable, :with => 'java, lisp', :on => :tags)
        @taggable.tag_list.should == %w(ruby python)
        @tagger.tag(@taggable, :with => '', :on => :tags)
        @taggable.tag_list.should == %w(ruby python)
      end
      
      it "should throw an exception when the default is over-ridden" do
        @taggable.tag_list_on(:foo_boo).should be_empty
        lambda {
          @tagger.tag(@taggable, :with=>'this, and, that', :on=>:foo_boo, :force=>false)
        }.should raise_error        
      end

      it "should not create the tag context on-the-fly when the default is over-ridden" do
        @taggable.tag_list_on(:foo_boo).should be_empty
        @tagger.tag(@taggable, :with=>'this, and, that', :on=>:foo_boo, :force=>false) rescue
        @taggable.tag_list_on(:foo_boo).should be_empty
      end
    end
    
    describe "when called by multiple tagger's" do
      before(:each) do
        @user_x = User.create(:name => "User X")
        @user_y = User.create(:name => "User Y")
        @taggable = TaggableModel.create(:name => 'acts_as_taggable_on', :tag_list => 'plugin')
        
        @user_x.tag(@taggable, :with => 'ruby, rails',  :on => :tags)
        @user_y.tag(@taggable, :with => 'ruby, plugin', :on => :tags)

        @user_y.tag(@taggable, :with => '', :on => :tags)
        @user_y.tag(@taggable, :with => '', :on => :tags)
      end
      
      it "should delete owned tags" do        
        @user_y.owned_tags.should == []
      end
      
      it "should not delete other taggers tags" do
        @user_x.owned_tags.should have(2).items
      end
      
      it "should not delete original tags" do
        @taggable.all_tags_list_on(:tags).should include('plugin')
      end
    end
  end

end
