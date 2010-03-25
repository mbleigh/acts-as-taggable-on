require File.dirname(__FILE__) + '/../spec_helper'

describe Tag do
  before(:each) do
    clean_database!
    @tag = Tag.new
    @user = TaggableModel.create(:name => "Pablo")
  end

  describe "named like any" do
    before(:each) do
      Tag.create(:name => "awesome")
      Tag.create(:name => "epic")
    end

    it "should find both tags" do
      Tag.named_like_any(["awesome", "epic"]).should have(2).items
    end
  end

  describe "find or create by name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      Tag.find_or_create_with_like_by_name("awesome").should == @tag
    end

    it "should find by name case insensitive" do
      Tag.find_or_create_with_like_by_name("AWESOME").should == @tag
    end

    it "should create by name" do
      lambda {
        Tag.find_or_create_with_like_by_name("epic")
      }.should change(Tag, :count).by(1)
    end
  end

  describe "find or create all by any name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      Tag.find_or_create_all_with_like_by_name("awesome").should == [@tag]
    end

    it "should find by name case insensitive" do
      Tag.find_or_create_all_with_like_by_name("AWESOME").should == [@tag]
    end

    it "should create by name" do
      lambda {
        Tag.find_or_create_all_with_like_by_name("epic")
      }.should change(Tag, :count).by(1)
    end

    it "should find or create by name" do
      lambda {
        Tag.find_or_create_all_with_like_by_name("awesome", "epic").map(&:name).should == ["awesome", "epic"]
      }.should change(Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      Tag.find_or_create_all_with_like_by_name([]).should == []
    end
  end

  it "should require a name" do
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3
      @tag.errors[:name].should == ["can't be blank"]
    else
      @tag.errors[:name].should == "can't be blank"
    end

    @tag.name = "something"
    @tag.valid?
    
    if ActiveRecord::VERSION::MAJOR >= 3      
      @tag.errors[:name].should == []
    else
      @tag.errors[:name].should be_nil
    end
  end

  it "should equal a tag with the same name" do
    @tag.name = "awesome"
    new_tag = Tag.new(:name => "awesome")
    new_tag.should == @tag
  end

  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end

  it "have named_scope named(something)" do
    @tag.name = "cool"
    @tag.save!
    Tag.named('cool').should include(@tag)
  end

  it "have named_scope named_like(something)" do
    @tag.name = "cool"
    @tag.save!
    @another_tag = Tag.create!(:name => "coolip")
    Tag.named_like('cool').should include(@tag, @another_tag)
  end
end
