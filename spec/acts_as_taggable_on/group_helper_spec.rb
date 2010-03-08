require File.dirname(__FILE__) + '/../spec_helper'

describe "Group Helper" do
  before(:each) do
    clean_database!    
  end

  describe "grouped_column_names_for method" do
    before(:each) do
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end

    it "should return all column names joined for Tag GROUP clause" do
      @taggable.grouped_column_names_for(Tag).should == "tags.id, tags.name"
    end

    it "should return all column names joined for TaggableModel GROUP clause" do
      @taggable.grouped_column_names_for(TaggableModel).should == "taggable_models.id, taggable_models.name, taggable_models.type, taggable_models.cached_tag_list"
    end
  end
end