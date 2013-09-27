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

  describe "using_mysql?" do
    it "should return true when the adapter is mysql" do
      TaggableModel.connection.stub(:adapter_name).and_return("MySQL2")
      TaggableModel.using_mysql?.should be_true
    end

    it "should return false when the adapter is not mysql" do
      TaggableModel.connection.stub(:adapter_name).and_return("PostgreSQL")
      TaggableModel.using_mysql?.should be_false
    end
  end

  describe "using_case_insensitive_collation?" do
    context "when the adapter is mysql" do
      before do
        TaggableModel.connection.stub(:adapter_name).and_return("MySQL2")
      end

      it "should return true when the collation is case insensitive" do
        TaggableModel.connection.stub(:collation).and_return("utf8_unicode_ci")
        TaggableModel.using_case_insensitive_collation?.should be_true
      end

      it "should return false when the adapter is case sensitive" do
        TaggableModel.connection.stub(:collation).and_return("utf8_bin")
        TaggableModel.using_case_insensitive_collation?.should be_false
      end
    end

    it "should return false when the adapter is not mysql" do
      TaggableModel.connection.stub(:adapter_name).and_return("PostgreSQL")
      TaggableModel.using_case_insensitive_collation?.should be_false
    end
  end
end
