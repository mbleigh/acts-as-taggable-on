require File.dirname(__FILE__) + '/../spec_helper'

describe "acts_as_tagger" do
  context "Tagger Method Generation" do

    before(:each) do
      @tagger = TaggableUser.new()
    end

    it "should add #is_tagger? query method to the class-side" do
      TaggableUser.should respond_to(:is_tagger?)
    end
    
    it "should return true from the class-side #is_tagger?" do
      TaggableUser.is_tagger?.should be_true
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
        @tagger = TaggableUser.new()
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
        @tagger.tag(@taggable, :with=>'that', :on=>:here_ond_now)
        @taggable.tag_list_on(:here_ond_now).should include('that')
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
  
  end

end