require 'spec_helper'

describe "Acts As Taggable On" do
  before(:each) do
    clean_database!
  end

  describe "Related Objects" do
    it "should find related objects based on tag names on context" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")
      taggable3 = TaggableModel.create!(:name => "Taggable 3")

      taggable1.tag_list = "one, two"
      taggable1.save

      taggable2.tag_list = "three, four"
      taggable2.save

      taggable3.tag_list = "one, four"
      taggable3.save

      taggable1.find_related_tags.should include(taggable3)
      taggable1.find_related_tags.should_not include(taggable2)
    end

    it "finds related tags for ordered taggable on" do
      taggable1 = OrderedTaggableModel.create!(:name => "Taggable 1")
      taggable2 = OrderedTaggableModel.create!(:name => "Taggable 2")
      taggable3 = OrderedTaggableModel.create!(:name => "Taggable 3")

      taggable1.colour_list = "one, two"
      taggable1.save

      taggable2.colour_list = "three, four"
      taggable2.save

      taggable3.colour_list = "one, four"
      taggable3.save

      taggable1.find_related_colours.should include(taggable3)
      taggable1.find_related_colours.should_not include(taggable2)
    end

    it "should find related objects based on tag names on context - non standard id" do
      taggable1 = NonStandardIdTaggableModel.create!(:name => "Taggable 1")
      taggable2 = NonStandardIdTaggableModel.create!(:name => "Taggable 2")
      taggable3 = NonStandardIdTaggableModel.create!(:name => "Taggable 3")

      taggable1.tag_list = "one, two"
      taggable1.save

      taggable2.tag_list = "three, four"
      taggable2.save

      taggable3.tag_list = "one, four"
      taggable3.save

      taggable1.find_related_tags.should include(taggable3)
      taggable1.find_related_tags.should_not include(taggable2)
    end

    it "should find other related objects based on tag names on context" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = OtherTaggableModel.create!(:name => "Taggable 2")
      taggable3 = OtherTaggableModel.create!(:name => "Taggable 3")

      taggable1.tag_list = "one, two"
      taggable1.save

      taggable2.tag_list = "three, four"
      taggable2.save

      taggable3.tag_list = "one, four"
      taggable3.save

      taggable1.find_related_tags_for(OtherTaggableModel).should include(taggable3)
      taggable1.find_related_tags_for(OtherTaggableModel).should_not include(taggable2)
    end

    it "should not include the object itself in the list of related objects" do
      taggable1 = TaggableModel.create!(:name => "Taggable 1")
      taggable2 = TaggableModel.create!(:name => "Taggable 2")

      taggable1.tag_list = "one"
      taggable1.save

      taggable2.tag_list = "one, two"
      taggable2.save

      taggable1.find_related_tags.should include(taggable2)
      taggable1.find_related_tags.should_not include(taggable1)
    end

    it "should not include the object itself in the list of related objects - non standard id" do
      taggable1 = NonStandardIdTaggableModel.create!(:name => "Taggable 1")
      taggable2 = NonStandardIdTaggableModel.create!(:name => "Taggable 2")

      taggable1.tag_list = "one"
      taggable1.save

      taggable2.tag_list = "one, two"
      taggable2.save

      taggable1.find_related_tags.should include(taggable2)
      taggable1.find_related_tags.should_not include(taggable1)
    end

		context "Ignored Tags" do
			let(:taggable1) { TaggableModel.create!(:name => "Taggable 1") }
			let(:taggable2) { TaggableModel.create!(:name => "Taggable 2") }
			let(:taggable3) { TaggableModel.create!(:name => "Taggable 3") }
			before(:each) do
				taggable1.tag_list = "one, two, four"
				taggable1.save

				taggable2.tag_list = "two, three"
				taggable2.save

				taggable3.tag_list = "one, three"
				taggable3.save
			end
			it "should not include ignored tags in related search" do
				taggable1.find_related_tags(:ignore => 'two').should_not include(taggable2)
				taggable1.find_related_tags(:ignore => 'two').should include(taggable3)
			end

			it "should accept array of ignored tags" do
				taggable4 = TaggableModel.create!(:name => "Taggable 4")
				taggable4.tag_list = "four"
				taggable4.save

				taggable1.find_related_tags(:ignore => ['two', 'four']).should_not include(taggable2)
				taggable1.find_related_tags(:ignore => ['two', 'four']).should_not include(taggable4)
			end

			it "should accept symbols as ignored tags" do
				taggable1.find_related_tags(:ignore => :two).should_not include(taggable2)
			end
		end

  end
end
