require 'spec_helper'

describe ActsAsTaggableOn::Utils do
  describe "like_operator" do
    before(:each) do
      clean_database!
      TaggableModel.acts_as_taggable_on(:tags, :languages, :skills, :needs, :offerings)
      @taggable = TaggableModel.new(:name => "Bob Jones")
    end

    it "should return 'ILIKE' when the adapter is PostgreSQL" do
      TaggableModel.connection.stub(:adapter_name).and_return("PostgreSQL")
      TaggableModel.send(:like_operator).should == "ILIKE"
    end

    it "should return 'LIKE' when the adapter is not PostgreSQL" do
      TaggableModel.connection.stub(:adapter_name).and_return("MySQL")
      TaggableModel.send(:like_operator).should == "LIKE"
    end
  end
end
