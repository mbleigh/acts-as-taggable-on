require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::TagList do
  let(:tag_list) { ActsAsTaggableOn::TagList.new("awesome","radical") }

  it { should be_kind_of Array }

  it "#from should return empty array if empty array is passed" do
    ActsAsTaggableOn::TagList.from([]).should be_empty
  end

  describe "#add" do
    it "should be able to be add a new tag word" do
      tag_list.add("cool")
      tag_list.include?("cool").should be_true
    end

    it "should be able to add delimited lists of words" do
      tag_list.add("cool, wicked", :parse => true)
      tag_list.should include("cool", "wicked")
    end

    it "should be able to add delimited list of words with quoted delimiters" do
      tag_list.add("'cool, wicked', \"really cool, really wicked\"", :parse => true)
      tag_list.should include("cool, wicked", "really cool, really wicked")
    end

    it "should be able to handle other uses of quotation marks correctly" do
      tag_list.add("john's cool car, mary's wicked toy", :parse => true)
      tag_list.should include("john's cool car", "mary's wicked toy")
    end

    it "should be able to add an array of words" do
      tag_list.add(["cool", "wicked"], :parse => true)
      tag_list.should include("cool", "wicked")
    end

    it "should quote escape tags with commas in them" do
      tag_list.add("cool","rad,bodacious")
      tag_list.to_s.should == "awesome, radical, cool, \"rad,bodacious\""
    end

  end

  describe "#remove" do
    it "should be able to remove words" do
      tag_list.remove("awesome")
      tag_list.should_not include("awesome")
    end

    it "should be able to remove delimited lists of words" do
      tag_list.remove("awesome, radical", :parse => true)
      tag_list.should be_empty
    end

    it "should be able to remove an array of words" do
      tag_list.remove(["awesome", "radical"], :parse => true)
      tag_list.should be_empty
    end
  end

  describe "#to_s" do
    it "should give a delimited list of words when converted to string" do
      tag_list.to_s.should == "awesome, radical"
    end

    it "should be able to call to_s on a frozen tag list" do
      tag_list.freeze
      lambda { tag_list.add("cool","rad,bodacious") }.should raise_error
      lambda { tag_list.to_s }.should_not raise_error
    end
  end

  describe "cleaning" do
    it "should parameterize if force_parameterize is set to true" do
      ActsAsTaggableOn.force_parameterize = true
      tag_list = ActsAsTaggableOn::TagList.new("awesome()","radical)(cc")

      tag_list.to_s.should == "awesome, radical-cc"
      ActsAsTaggableOn.force_parameterize = false
    end

    it "should lowercase if force_lowercase is set to true" do
      ActsAsTaggableOn.force_lowercase = true

      tag_list = ActsAsTaggableOn::TagList.new("aweSomE","RaDicaL")
      tag_list.to_s.should == "awesome, radical"

      ActsAsTaggableOn.force_lowercase = false
    end

  end
end