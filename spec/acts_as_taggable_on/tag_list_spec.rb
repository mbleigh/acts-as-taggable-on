require File.expand_path('../../spec_helper', __FILE__)

describe ActsAsTaggableOn::TagList do
  before(:each) do
    @tag_list = ActsAsTaggableOn::TagList.new("awesome","radical")
  end
  
  it "should be an array" do
    @tag_list.is_a?(Array).should be_true
  end
  
  it "should be able to be add a new tag word" do
    @tag_list.add("cool")
    @tag_list.include?("cool").should be_true
  end
  
  it "should be able to add delimited lists of words" do
    @tag_list.add("cool, wicked", :parse => true)
    @tag_list.include?("cool").should be_true
    @tag_list.include?("wicked").should be_true
  end
  
  it "should be able to add delimited list of words with quoted delimiters" do
    @tag_list.add("'cool, wicked', \"really cool, really wicked\"", :parse => true)
    @tag_list.include?("cool, wicked").should be_true
    @tag_list.include?("really cool, really wicked").should be_true
  end
  
  it "should be able to handle other uses of quotation marks correctly" do
    @tag_list.add("john's cool car, mary's wicked toy", :parse => true)
    @tag_list.include?("john's cool car").should be_true
    @tag_list.include?("mary's wicked toy").should be_true
  end
  
  it "should be able to add an array of words" do
    @tag_list.add(["cool", "wicked"], :parse => true)
    @tag_list.include?("cool").should be_true
    @tag_list.include?("wicked").should be_true
  end
  
  it "should be able to remove words" do
    @tag_list.remove("awesome")
    @tag_list.include?("awesome").should be_false
  end
  
  it "should be able to remove delimited lists of words" do
    @tag_list.remove("awesome, radical", :parse => true)
    @tag_list.should be_empty
  end
  
  it "should be able to remove an array of words" do
    @tag_list.remove(["awesome", "radical"], :parse => true)
    @tag_list.should be_empty
  end
  
  it "should give a delimited list of words when converted to string" do
    @tag_list.to_s.should == "awesome, radical"
  end
  
  it "should quote escape tags with commas in them" do
    @tag_list.add("cool","rad,bodacious")
    @tag_list.to_s.should == "awesome, radical, cool, \"rad,bodacious\""
  end
  
  it "should be able to call to_s on a frozen tag list" do
    @tag_list.freeze
    lambda { @tag_list.add("cool","rad,bodacious") }.should raise_error
    lambda { @tag_list.to_s }.should_not raise_error
  end
end