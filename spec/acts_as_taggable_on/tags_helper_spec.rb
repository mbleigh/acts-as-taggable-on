require File.dirname(__FILE__) + '/../spec_helper'

describe TagsHelper do
  before(:each) do
    [TaggableModel, Tag, Tagging].each(&:delete_all)
    
    @bob = TaggableModel.create(:name => "Bob Jones",  :language_list => "ruby, php")
    @tom = TaggableModel.create(:name => "Tom Marley", :language_list => "ruby, java")
    @eve = TaggableModel.create(:name => "Eve Nodd",   :language_list => "ruby, c++")
    
    @helper = class Helper
      include TagsHelper
    end.new
    
    
  end
  
  it "should yield the proper css classes" do 
    tags = { }
    
    @helper.tag_cloud(TaggableModel.tag_counts_on(:languages), ["sucky", "awesome"]) do |tag, css_class|
      tags[tag.name] = css_class
    end
    
    tags["ruby"].should == "awesome"
    tags["java"].should == "sucky"
    tags["c++"].should == "sucky"
    tags["php"].should == "sucky"
  end
end