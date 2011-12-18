require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::Tag do
  before(:each) do
    clean_database!
    @tag = ActsAsTaggableOn::Tag.new
    @user = TaggableModel.create(:name => "Pablo")
  end

  describe "named like any" do
    before(:each) do
      ActsAsTaggableOn::Tag.create(:name => "Awesome")
      ActsAsTaggableOn::Tag.create(:name => "awesome")
      ActsAsTaggableOn::Tag.create(:name => "epic")
    end

    it "should find both tags" do
      ActsAsTaggableOn::Tag.named_like_any(["awesome", "epic"]).should have(3).items
    end
  end

  describe "find or create by name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("awesome").should == @tag
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("AWESOME").should == @tag
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end
  end

  describe "find or create all by any name" do
    before(:each) do
      @tag.name = "awesome"
      @tag.save
    end

    it "should find by name" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("awesome").should == [@tag]
    end

    it "should find by name case insensitive" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("AWESOME").should == [@tag]
    end

    it "should create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("epic")
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should find or create by name" do
      lambda {
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name("awesome", "epic").map(&:name).should == ["awesome", "epic"]
      }.should change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it "should return an empty array if no tags are specified" do
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name([]).should == []
    end
  end

  it "should require a name" do
    @tag.valid?

    @tag.errors[:name].should == ["can't be blank"]

    @tag.name = "something"
    @tag.valid?

    @tag.errors[:name].should == []
  end

  it "should equal a tag with the same name" do
    @tag.name = "awesome"
    new_tag = ActsAsTaggableOn::Tag.new(:name => "awesome")
    new_tag.should == @tag
  end

  it "should return its name when to_s is called" do
    @tag.name = "cool"
    @tag.to_s.should == "cool"
  end

  it "have named_scope named(something)" do
    @tag.name = "cool"
    @tag.save!
    ActsAsTaggableOn::Tag.named('cool').should include(@tag)
  end

  it "have named_scope named_like(something)" do
    @tag.name = "cool"
    @tag.save!
    @another_tag = ActsAsTaggableOn::Tag.create!(:name => "coolip")
    ActsAsTaggableOn::Tag.named_like('cool').should include(@tag, @another_tag)
  end

  describe "escape wildcard symbols in like requests" do
    before(:each) do
      @tag.name = "cool"
      @tag.save
      @another_tag = ActsAsTaggableOn::Tag.create!(:name => "coo%")
      @another_tag2 = ActsAsTaggableOn::Tag.create!(:name => "coolish")
    end

    it "return escaped result when '%' char present in tag" do
        ActsAsTaggableOn::Tag.named_like('coo%').should_not include(@tag)
        ActsAsTaggableOn::Tag.named_like('coo%').should include(@another_tag)
    end

  end
  
  describe ".remove_unused" do
    before do
      @taggable = TaggableModel.create(:name => "Bob Jones")
      @tag = ActsAsTaggableOn::Tag.create(:name => "awesome")

      @tagging = ActsAsTaggableOn::Tagging.create(:taggable => @taggable, :tag => @tag, :context => 'tags')
    end
    
    context "if set to true" do
      before do
        ActsAsTaggableOn::Tag.remove_unused = true                  
      end
      
      it "should remove unused tags after removing taggings" do
        @tagging.destroy
        ActsAsTaggableOn::Tag.find_by_name("awesome").should be_nil
      end
    end
    
    context "if set to false" do
      before do
        ActsAsTaggableOn::Tag.remove_unused = false        
      end
      
      it "should not remove unused tags after removing taggings" do
        @tagging.destroy
        ActsAsTaggableOn::Tag.find_by_name("awesome").should == @tag
      end
    end
  end
end
