require 'spec_helper'

describe "Single Table Inheritance" do

  before(:each) do
    clean_database!
  end

  let(:taggable)            { TaggableModel.new(:name => "taggable model") }

  let(:inheriting_model)    { InheritingTaggableModel.new(:name => "Inheriting Taggable Model") }
  let(:altered_inheriting)  { AlteredInheritingTaggableModel.new(:name => "Altered Inheriting Model") }

  1.upto(4) do |n|
    let(:"inheriting_#{n}") { InheritingTaggableModel.new(:name => "Inheriting Model #{n}") }
  end

  let(:student)             { Student.create! }

  describe "tag contexts" do
    it "should pass on to STI-inherited models" do
      inheriting_model.should respond_to(:tag_list, :skill_list, :language_list)
      altered_inheriting.should respond_to(:tag_list, :skill_list, :language_list)
    end

    it "should pass on to altered STI models" do
      altered_inheriting.should respond_to(:part_list)
    end
  end

  context "matching contexts" do

    before do
      inheriting_1.offering_list = "one, two"
      inheriting_1.need_list = "one, two"
      inheriting_1.save!

      inheriting_2.need_list = "one, two"
      inheriting_2.save!

      inheriting_3.offering_list = "one, two"
      inheriting_3.save!

      inheriting_4.tag_list = "one, two, three, four"
      inheriting_4.save!

      taggable.need_list = "one, two"
      taggable.save!
    end

    it "should find objects with tags of matching contexts" do
      inheriting_1.find_matching_contexts(:offerings, :needs).should      include(inheriting_2)
      inheriting_1.find_matching_contexts(:offerings, :needs).should_not  include(inheriting_3)
      inheriting_1.find_matching_contexts(:offerings, :needs).should_not  include(inheriting_4)
      inheriting_1.find_matching_contexts(:offerings, :needs).should_not  include(taggable)

      inheriting_1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should     include(inheriting_2)
      inheriting_1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should_not include(inheriting_3)
      inheriting_1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should_not include(inheriting_4)
      inheriting_1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should     include(taggable)
    end

    it "should not include the object itself in the list of related objects with tags of matching contexts" do
      inheriting_1.find_matching_contexts(:offerings, :needs).should_not include(inheriting_1)
      inheriting_1.find_matching_contexts_for(InheritingTaggableModel, :offerings, :needs).should_not include(inheriting_1)
      inheriting_1.find_matching_contexts_for(TaggableModel, :offerings, :needs).should_not include(inheriting_1)
    end
  end

  context "find related tags" do
    before do
      inheriting_1.tag_list = "one, two"
      inheriting_1.save

      inheriting_2.tag_list = "three, four"
      inheriting_2.save

      inheriting_3.tag_list = "one, four"
      inheriting_3.save

      taggable.tag_list = "one, two, three, four"
      taggable.save
    end

    it "should find related objects based on tag names on context" do
      inheriting_1.find_related_tags.should include(inheriting_3)
      inheriting_1.find_related_tags.should_not include(inheriting_2)
      inheriting_1.find_related_tags.should_not include(taggable)

      inheriting_1.find_related_tags_for(TaggableModel).should include(inheriting_3)
      inheriting_1.find_related_tags_for(TaggableModel).should_not include(inheriting_2)
      inheriting_1.find_related_tags_for(TaggableModel).should include(taggable)
    end

    it "should not include the object itself in the list of related objects" do
      inheriting_1.find_related_tags.should_not include(inheriting_1)
      inheriting_1.find_related_tags_for(InheritingTaggableModel).should_not include(inheriting_1)
      inheriting_1.find_related_tags_for(TaggableModel).should_not include(inheriting_1)
    end
  end

  describe "tag list" do
    before do
      @inherited_same = InheritingTaggableModel.new(:name => "inherited same")
      @inherited_different = AlteredInheritingTaggableModel.new(:name => "inherited different")
    end

    it "should be able to save tags for inherited models" do
      inheriting_model.tag_list = "bob, kelso"
      inheriting_model.save
      InheritingTaggableModel.tagged_with("bob").first.should == inheriting_model
    end

    it "should find STI tagged models on the superclass" do
      inheriting_model.tag_list = "bob, kelso"
      inheriting_model.save
      TaggableModel.tagged_with("bob").first.should == inheriting_model
    end

    it "should be able to add on contexts only to some subclasses" do
      altered_inheriting.part_list = "fork, spoon"
      altered_inheriting.save
      InheritingTaggableModel.tagged_with("fork", :on => :parts).should be_empty
      AlteredInheritingTaggableModel.tagged_with("fork", :on => :parts).first.should == altered_inheriting
    end

    it "should have different tag_counts_on for inherited models" do
      inheriting_model.tag_list = "bob, kelso"
      inheriting_model.save!
      altered_inheriting.tag_list = "fork, spoon"
      altered_inheriting.save!

      InheritingTaggableModel.tag_counts_on(:tags, :order => 'tags.id').map(&:name).should == %w(bob kelso)
      AlteredInheritingTaggableModel.tag_counts_on(:tags, :order => 'tags.id').map(&:name).should == %w(fork spoon)
      TaggableModel.tag_counts_on(:tags, :order => 'tags.id').map(&:name).should == %w(bob kelso fork spoon)
    end

    it "should have different tags_on for inherited models" do
      inheriting_model.tag_list = "bob, kelso"
      inheriting_model.save!
      altered_inheriting.tag_list = "fork, spoon"
      altered_inheriting.save!

      InheritingTaggableModel.tags_on(:tags, :order => 'tags.id').map(&:name).should == %w(bob kelso)
      AlteredInheritingTaggableModel.tags_on(:tags, :order => 'tags.id').map(&:name).should == %w(fork spoon)
      TaggableModel.tags_on(:tags, :order => 'tags.id').map(&:name).should == %w(bob kelso fork spoon)
    end

    it 'should store same tag without validation conflict' do
      taggable.tag_list = 'one'
      taggable.save!

      inheriting_model.tag_list = 'one'
      inheriting_model.save!

      inheriting_model.update_attributes! :name => 'foo'
    end
  end

  describe "ownership" do
    it "should have taggings" do
      student.tag(taggable, :with=>'ruby,scheme', :on=>:tags)
      student.owned_taggings.should have(2).tags
    end

    it "should have tags" do
      student.tag(taggable, :with=>'ruby,scheme', :on=>:tags)
      student.owned_tags.should have(2).tags
    end

    it "should return tags for the inheriting tagger" do
      student.tag(taggable, :with => 'ruby, scheme', :on => :tags)
      taggable.tags_from(student).should match_array(%w(ruby scheme))
    end

    it "returns owner tags on the tagger" do
      student.tag(taggable, :with => 'ruby, scheme', :on => :tags)
      taggable.owner_tags_on(student, :tags).should have(2).tags
    end

    it "should scope objects returned by tagged_with by owners" do
      student.tag(taggable, :with => 'ruby, scheme', :on => :tags)
      TaggableModel.tagged_with(%w(ruby scheme), :owned_by => student).should have(1).tag
    end
  end

end
