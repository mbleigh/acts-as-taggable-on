require 'spec_helper'

describe "Tag Expressions" do
  before(:each) do
    clean_database!
    @user = User.new({:name => "Bob"})
    @user.save
    @taggable = TaggableModel.create(:name => "Bob Jones")
  end

  it "should be able to parse tags and operators" do
    ActsAsTaggableOn::Expression::Parse::parse_expression("tag+tag2-tag3-tag4&tag5&tag6").length.should equal(11)
  end

  it "should ignore whitespace between tags and operators" do
    ActsAsTaggableOn::Expression::Parse::parse_expression("tag  +  tag2 - tag4- tag4& tag5 & tag6").length.should equal(11)
  end

  it "should allow the use of whitespace to separate tags and operators" do
    TaggableModel.create(:name => "Bob", :tag_list => "c++, java, ruby")
    TaggableModel.create(:name => 'Steve', :tag_list => "ruby, python")

    TaggableModel.tagged_with("c++ + python", :expression => true, :use_whitespace => true).to_a.length.should == 2
    TaggableModel.tagged_with("c++ ++++++++++ python", :expression => true, :use_whitespace => true).to_a.length.should == 2

  end

  it "should ensure first index is an operator" do
    list1 = ActsAsTaggableOn::Expression::Parse::parse_expression("tag+tag2-tag3-tag4&tag5&tag6")
    ActsAsTaggableOn::Expression::Parse::fixed_expression_array(list1).length.should equal(12)

    list2 = ActsAsTaggableOn::Expression::Parse::parse_expression("&tag+tag2-tag3-tag4&tag5&tag6")
    ActsAsTaggableOn::Expression::Parse::fixed_expression_array(list2).length.should equal(12)
  end

  it "should handle repeated operators" do
      parse1 = ActsAsTaggableOn::Expression::Parse::parse_expression("tag++tag3--tag3&&tag4")
      parse2 = ActsAsTaggableOn::Expression::Parse::parse_expression("tag+tag3-tag3&tag4")

      parse1.should == parse2

    TaggableModel.create(:name => "Bob", :tag_list => "c++, java, ruby")
    TaggableModel.create(:name => 'Steve', :tag_list => "ruby, python")

    TaggableModel.tagged_with("c\\+\\+++++python", :expression => true, :use_whitespace => false).to_a.length.should == 2
    TaggableModel.tagged_with("c++ ++++++++++ python", :expression => true, :use_whitespace => true).to_a.length.should == 2
  end

  it "should permit operators preceded by a backward slash in tag name" do
      bob = TaggableModel.create(:name => "Bob", :tag_list => "sad, lazy+strong")
      frank = TaggableModel.create(:name => "Frank", :tag_list => "happy, strong")
      TaggableModel.tagged_with("lazy\\+strong+happy", :expression => true).to_a.should include(bob, frank)
  end

  it "should allow + and | operators to perform unions" do
      TaggableModel.create(:name => "Bob", :tag_list => "sad, strong")
      TaggableModel.create(:name => "Frank", :tag_list => "happy, strong")
      result1 = TaggableModel.tagged_with("sad+happy", :expression => true).to_a
      result2 = TaggableModel.tagged_with("sad|happy", :expression => true).to_a
      result1.should == result2
  end


  it "should produce same result as ActiveRecord chaining in simple cases" do
    TaggableModel.create(:name => "Bob", :tag_list => "sad, lazy, strong")
    TaggableModel.create(:name => "Frank", :tag_list => "happy, strong")
    TaggableModel.create(:name => 'Steve', :tag_list => "happy, lazy")
    TaggableModel.create(:name => 'Steve+Molly', :tag_list => "sad, strong, lazy, grumpy")

    chain = TaggableModel.tagged_with("sad, happy", :any => true).tagged_with("lazy").tagged_with("grumpy", :exclude => true).tagged_with("strong").to_a
    expression = TaggableModel.tagged_with("sad+happy&lazy-grumpy&strong", :expression => true).to_a
    chain.should == expression

    chain = TaggableModel.tagged_with("sad").tagged_with("happy", :any => true).tagged_with("lazy").tagged_with("grumpy", :exclude => true).tagged_with("strong").to_a
    expression = TaggableModel.tagged_with("&sad+happy&lazy-grumpy", :expression => true).to_a
    chain.should == expression
  end

  it "should produce better results than ActiveRecord chaining in more complex cases" do
    TaggableModel.create(:name => "Bob", :tag_list => "sad, lazy, strong")
    TaggableModel.create(:name => "Frank", :tag_list => "happy, strong")
    TaggableModel.create(:name => 'Steve', :tag_list => "happy, lazy")
    TaggableModel.create(:name => 'Steve+Molly', :tag_list => "sad, strong, lazy, grumpy")

    default_chain = TaggableModel.tagged_with("sad&lazy+happy", :expression => true, :default_chaining => true).to_a
    fixed_chain = TaggableModel.tagged_with("sad&lazy+happy", :expression => true, :default_chaining => false).to_a

    default_chain.length.should == 0
    fixed_chain.length.should == 3
  end
end
