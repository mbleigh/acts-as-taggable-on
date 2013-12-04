require 'spec_helper'

describe "Taggable To Preserve Order" do
  before(:each) do
    clean_database!
    @taggable = OrderedTaggableModel.new(:name => "Bob Jones")
  end

  it "should have tag types" do
    [:tags, :colours].each do |type|
      OrderedTaggableModel.tag_types.should include type
    end

    @taggable.tag_types.should == OrderedTaggableModel.tag_types
  end

  it "should have tag associations" do
    [:tags, :colours].each do |type|
      @taggable.respond_to?(type).should be_true
      @taggable.respond_to?("#{type.to_s.singularize}_taggings").should be_true
    end
  end

  # it "should have tag associations ordered by id" do
  #   [:tags, :colours].each do |type|
  #     OrderedTaggableModel.reflect_on_association(type).options[:order].should include('id')
  #     OrderedTaggableModel.reflect_on_association("#{type.to_s.singularize}_taggings".to_sym).options[:order].should include('id')
  #   end
  # end

  it "should have tag methods" do
    [:tags, :colours].each do |type|
      @taggable.respond_to?("#{type.to_s.singularize}_list").should be_true
      @taggable.respond_to?("#{type.to_s.singularize}_list=").should be_true
      @taggable.respond_to?("all_#{type.to_s}_list").should be_true
    end
  end

  it "should return tag list in the order the tags were created" do
    # create
    @taggable.tag_list = "rails, ruby, css"
    @taggable.instance_variable_get("@tag_list").instance_of?(ActsAsTaggableOn::TagList).should be_true

    lambda {
      @taggable.save
    }.should change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    @taggable.tag_list.should == %w(rails ruby css)

    # update
    @taggable.tag_list = "pow, ruby, rails"
    @taggable.save

    @taggable.reload
    @taggable.tag_list.should == %w(pow ruby rails)

    # update with no change
    @taggable.tag_list = "pow, ruby, rails"
    @taggable.save

    @taggable.reload
    @taggable.tag_list.should == %w(pow ruby rails)

    # update to clear tags
    @taggable.tag_list = ""
    @taggable.save

    @taggable.reload
    @taggable.tag_list.should == []
  end

  it "should return tag objects in the order the tags were created" do
    # create
    @taggable.tag_list = "pow, ruby, rails"
    @taggable.instance_variable_get("@tag_list").instance_of?(ActsAsTaggableOn::TagList).should be_true

    lambda {
      @taggable.save
    }.should change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    @taggable.tags.map{|t| t.name}.should == %w(pow ruby rails)

    # update
    @taggable.tag_list = "rails, ruby, css, pow"
    @taggable.save

    @taggable.reload
    @taggable.tags.map{|t| t.name}.should == %w(rails ruby css pow)
  end

  it "should return tag objects in tagging id order" do
    # create
    @taggable.tag_list = "pow, ruby, rails"
    @taggable.save

    @taggable.reload
    ids = @taggable.tags.map{|t| t.taggings.first.id}
    ids.should == ids.sort

    # update
    @taggable.tag_list = "rails, ruby, css, pow"
    @taggable.save

    @taggable.reload
    ids = @taggable.tags.map{|t| t.taggings.first.id}
    ids.should == ids.sort
  end
end

describe "Taggable" do
  before(:each) do
    clean_database!
    @taggable = TaggableModel.new(:name => "Bob Jones")
    @taggables = [@taggable, TaggableModel.new(:name => "John Doe")]
  end

  it "should have tag types" do
    [:tags, :languages, :skills, :needs, :offerings].each do |type|
      TaggableModel.tag_types.should include type
    end

    @taggable.tag_types.should == TaggableModel.tag_types
  end

  it "should have tag_counts_on" do
    TaggableModel.tag_counts_on(:tags).should be_empty

    @taggable.tag_list = ["awesome", "epic"]
    @taggable.save

    TaggableModel.tag_counts_on(:tags).length.should == 2
    @taggable.tag_counts_on(:tags).length.should == 2
  end

  it "should have tags_on" do
    TaggableModel.tags_on(:tags).should be_empty

    @taggable.tag_list = ["awesome", "epic"]
    @taggable.save

    TaggableModel.tags_on(:tags).length.should == 2
    @taggable.tags_on(:tags).length.should == 2
  end

  it "should return [] right after create" do
    blank_taggable = TaggableModel.new(:name => "Bob Jones")
    blank_taggable.tag_list.should == []
  end

  it "should be able to create tags" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.instance_variable_get("@skill_list").instance_of?(ActsAsTaggableOn::TagList).should be_true

    lambda {
      @taggable.save
    }.should change(ActsAsTaggableOn::Tag, :count).by(3)

    @taggable.reload
    @taggable.skill_list.sort.should == %w(ruby rails css).sort
  end

  it "should be able to create tags through the tag list directly" do
    @taggable.tag_list_on(:test).add("hello")
    @taggable.tag_list_cache_on(:test).should_not be_empty
    @taggable.tag_list_on(:test).should == ["hello"]

    @taggable.save
    @taggable.save_tags

    @taggable.reload
    @taggable.tag_list_on(:test).should == ["hello"]
  end

  it "should differentiate between contexts" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "ruby, bob, charlie"
    @taggable.save
    @taggable.reload
    @taggable.skill_list.should include("ruby")
    @taggable.skill_list.should_not include("bob")
  end

  it "should be able to remove tags through list alone" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save
    @taggable.reload
    @taggable.should have(3).skills
    @taggable.skill_list = "ruby, rails"
    @taggable.save
    @taggable.reload
    @taggable.should have(2).skills
  end

  it "should be able to select taggables by subset of tags using ActiveRelation methods" do
    @taggables[0].tag_list = "bob"
    @taggables[1].tag_list = "charlie"
    @taggables[0].skill_list = "ruby"
    @taggables[1].skill_list = "css"
    @taggables.each{|taggable| taggable.save}

    @found_taggables_by_tag = TaggableModel.joins(:tags).where(:tags => {:name => ["bob"]})
    @found_taggables_by_skill = TaggableModel.joins(:skills).where(:tags => {:name => ["ruby"]})

    @found_taggables_by_tag.should include @taggables[0]
    @found_taggables_by_tag.should_not include @taggables[1]
    @found_taggables_by_skill.should include @taggables[0]
    @found_taggables_by_skill.should_not include @taggables[1]
  end

  it "should be able to find by tag" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.save

    TaggableModel.tagged_with("ruby").first.should == @taggable
  end

  it "should be able to find by tag with context" do
    @taggable.skill_list = "ruby, rails, css"
    @taggable.tag_list = "bob, charlie"
    @taggable.save

    TaggableModel.tagged_with("ruby").first.should == @taggable
    TaggableModel.tagged_with("ruby, css").first.should == @taggable
    TaggableModel.tagged_with("bob", :on => :skills).first.should_not == @taggable
    TaggableModel.tagged_with("bob", :on => :tags).first.should == @taggable
  end

  it "should not care about case" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "Ruby")

    ActsAsTaggableOn::Tag.all.size.should == 1
    TaggableModel.tagged_with("ruby").to_a.should == TaggableModel.tagged_with("Ruby").to_a
  end

  it "should be able to get tag counts on model as a whole" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")
    TaggableModel.tag_counts.should_not be_empty
    TaggableModel.skill_counts.should_not be_empty
  end

  it "should be able to get all tag counts on model as whole" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")

    TaggableModel.all_tag_counts.should_not be_empty
    TaggableModel.all_tag_counts(:order => 'tags.id').first.count.should == 3 # ruby
  end

  it "should be able to get all tags on model as whole" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")

    TaggableModel.all_tags.should_not be_empty
    TaggableModel.all_tags(:order => 'tags.id').first.name.should == "ruby"
  end

  it "should be able to use named scopes to chain tag finds by any tags by context" do
    bob   = TaggableModel.create(:name => "Bob",   :need_list => "rails", :offering_list => "c++")
    frank = TaggableModel.create(:name => "Frank", :need_list => "css",   :offering_list => "css")
    steve = TaggableModel.create(:name => 'Steve', :need_list => "c++",   :offering_list => "java")

    # Let's only find those who need rails or css and are offering c++ or java
    TaggableModel.tagged_with(['rails, css'], :on => :needs, :any => true).tagged_with(['c++', 'java'], :on => :offerings, :any => true).to_a.should == [bob]
  end

  it "should not return read-only records" do
    TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    TaggableModel.tagged_with("ruby").first.should_not be_readonly
  end

  it "should be able to get scoped tag counts" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")

    TaggableModel.tagged_with("ruby").tag_counts(:order => 'tags.id').first.count.should == 2   # ruby
    TaggableModel.tagged_with("ruby").skill_counts.first.count.should == 1 # ruby
  end

  it "should be able to get all scoped tag counts" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")

    TaggableModel.tagged_with("ruby").all_tag_counts(:order => 'tags.id').first.count.should == 3 # ruby
  end

  it "should be able to get all scoped tags" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby")

    TaggableModel.tagged_with("ruby").all_tags(:order => 'tags.id').first.name.should == "ruby"
  end

  it 'should only return tag counts for the available scope' do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby, java")

    TaggableModel.tagged_with('rails').all_tag_counts.should have(3).items
    TaggableModel.tagged_with('rails').all_tag_counts.any? { |tag| tag.name == 'java' }.should be_false

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tag_counts.should have(2).items
    TaggableModel.tagged_with('rails').joins(:untaggable_models => :taggable_model).all_tag_counts.should have(2).items
    TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tag_counts.should have(2).items
  end

  it 'should only return tags for the available scope' do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "ruby, rails")
    charlie = TaggableModel.create(:name => "Charlie", :skill_list => "ruby, java")

    TaggableModel.tagged_with('rails').all_tags.should have(3).items
    TaggableModel.tagged_with('rails').all_tags.any? { |tag| tag.name == 'java' }.should be_false

    # Test specific join syntaxes:
    frank.untaggable_models.create!
    TaggableModel.tagged_with('rails').joins(:untaggable_models).all_tags.should have(2).items
    TaggableModel.tagged_with('rails').joins({ :untaggable_models => :taggable_model }).all_tags.should have(2).items
    TaggableModel.tagged_with('rails').joins([:untaggable_models]).all_tags.should have(2).items
  end

  it "should be able to set a custom tag context list" do
    bob = TaggableModel.create(:name => "Bob")
    bob.set_tag_list_on(:rotors, "spinning, jumping")
    bob.tag_list_on(:rotors).should == ["spinning","jumping"]
    bob.save
    bob.reload
    bob.tags_on(:rotors).should_not be_empty
  end

  it "should be able to find tagged" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "fitter, happier, more productive", :skill_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "weaker, depressed, inefficient", :skill_list => "ruby, rails, css")
    steve = TaggableModel.create(:name => 'Steve', :tag_list => 'fitter, happier, more productive', :skill_list => 'c++, java, ruby')

    TaggableModel.tagged_with("ruby", :order => 'taggable_models.name').to_a.should == [bob, frank, steve]
    TaggableModel.tagged_with("ruby, rails", :order => 'taggable_models.name').to_a.should == [bob, frank]
    TaggableModel.tagged_with(["ruby", "rails"], :order => 'taggable_models.name').to_a.should == [bob, frank]
  end

  it "should be able to find tagged with quotation marks" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "fitter, happier, more productive, 'I love the ,comma,'")
    TaggableModel.tagged_with("'I love the ,comma,'").should include(bob)
  end

  it "should be able to find tagged with invalid tags" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "fitter, happier, more productive")
    TaggableModel.tagged_with("sad, happier").should_not include(bob)
  end

  it "should be able to find tagged with any tag" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "fitter, happier, more productive", :skill_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "weaker, depressed, inefficient", :skill_list => "ruby, rails, css")
    steve = TaggableModel.create(:name => 'Steve', :tag_list => 'fitter, happier, more productive', :skill_list => 'c++, java, ruby')

    TaggableModel.tagged_with(["ruby", "java"], :order => 'taggable_models.name', :any => true).to_a.should == [bob, frank, steve]
    TaggableModel.tagged_with(["c++", "fitter"], :order => 'taggable_models.name', :any => true).to_a.should == [bob, steve]
    TaggableModel.tagged_with(["depressed", "css"], :order => 'taggable_models.name', :any => true).to_a.should == [bob, frank]
  end

  context "wild: true" do
    it "should use params as wildcards" do
      bob = TaggableModel.create(:name => "Bob", :tag_list => "bob, tricia")
      frank = TaggableModel.create(:name => "Frank", :tag_list => "bobby, jim")
      steve = TaggableModel.create(:name => "Steve", :tag_list => "john, patricia")
      jim = TaggableModel.create(:name => "Jim", :tag_list => "jim, steve")


      TaggableModel.tagged_with(["bob", "tricia"], :wild => true, :any => true).to_a.sort_by{|o| o.id}.should == [bob, frank, steve]
      TaggableModel.tagged_with(["bob", "tricia"], :wild => true, :exclude => true).to_a.should == [jim]
    end
  end

  it "should be able to find tagged on a custom tag context" do
    bob = TaggableModel.create(:name => "Bob")
    bob.set_tag_list_on(:rotors, "spinning, jumping")
    bob.tag_list_on(:rotors).should == ["spinning","jumping"]
    bob.save

    TaggableModel.tagged_with("spinning", :on => :rotors).to_a.should == [bob]
  end

  it "should be able to use named scopes to chain tag finds" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "fitter, happier, more productive", :skill_list => "ruby, rails, css")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "weaker, depressed, inefficient", :skill_list => "ruby, rails, css")
    steve = TaggableModel.create(:name => 'Steve', :tag_list => 'fitter, happier, more productive', :skill_list => 'c++, java, python')

    # Let's only find those productive Rails developers
    TaggableModel.tagged_with('rails', :on => :skills, :order => 'taggable_models.name').to_a.should == [bob, frank]
    TaggableModel.tagged_with('happier', :on => :tags, :order => 'taggable_models.name').to_a.should == [bob, steve]
    TaggableModel.tagged_with('rails', :on => :skills).tagged_with('happier', :on => :tags).to_a.should == [bob]
    TaggableModel.tagged_with('rails').tagged_with('happier', :on => :tags).to_a.should == [bob]
  end

  it "should be able to find tagged with only the matching tags" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "lazy, happier")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "fitter, happier, inefficient")
    steve = TaggableModel.create(:name => 'Steve', :tag_list => "fitter, happier")

    TaggableModel.tagged_with("fitter, happier", :match_all => true).to_a.should == [steve]
  end

  it "should be able to find tagged with some excluded tags" do
    bob = TaggableModel.create(:name => "Bob", :tag_list => "happier, lazy")
    frank = TaggableModel.create(:name => "Frank", :tag_list => "happier")
    steve = TaggableModel.create(:name => 'Steve', :tag_list => "happier")

    TaggableModel.tagged_with("lazy", :exclude => true).to_a.should == [frank, steve]
  end

  it "should return an empty scope for empty tags" do
    TaggableModel.tagged_with('').should == []
    TaggableModel.tagged_with(' ').should == []
    TaggableModel.tagged_with(nil).should == []
    TaggableModel.tagged_with([]).should == []
  end

  it "should not create duplicate taggings" do
    bob = TaggableModel.create(:name => "Bob")
    lambda {
      bob.tag_list << "happier"
      bob.tag_list << "happier"
      bob.save
    }.should change(ActsAsTaggableOn::Tagging, :count).by(1)
  end

  describe "Associations" do
    before(:each) do
      @taggable = TaggableModel.create(:tag_list => "awesome, epic")
    end

    it "should not remove tags when creating associated objects" do
      @taggable.untaggable_models.create!
      @taggable.reload
      @taggable.tag_list.should have(2).items
    end
  end

  describe "grouped_column_names_for method" do
    it "should return all column names joined for Tag GROUP clause" do
      @taggable.grouped_column_names_for(ActsAsTaggableOn::Tag).should == "tags.id, tags.name"
    end

    it "should return all column names joined for TaggableModel GROUP clause" do
      @taggable.grouped_column_names_for(TaggableModel).should == "taggable_models.id, taggable_models.name, taggable_models.type"
    end

    it "should return all column names joined for NonStandardIdTaggableModel GROUP clause" do
      @taggable.grouped_column_names_for(TaggableModel).should == "taggable_models.#{TaggableModel.primary_key}, taggable_models.name, taggable_models.type"
    end
  end

  describe "NonStandardIdTaggable" do
    before(:each) do
      clean_database!
      @taggable = NonStandardIdTaggableModel.new(:name => "Bob Jones")
      @taggables = [@taggable, NonStandardIdTaggableModel.new(:name => "John Doe")]
    end

    it "should have tag types" do
      [:tags, :languages, :skills, :needs, :offerings].each do |type|
        NonStandardIdTaggableModel.tag_types.should include type
      end

      @taggable.tag_types.should == NonStandardIdTaggableModel.tag_types
    end

    it "should have tag_counts_on" do
      NonStandardIdTaggableModel.tag_counts_on(:tags).should be_empty

      @taggable.tag_list = ["awesome", "epic"]
      @taggable.save

      NonStandardIdTaggableModel.tag_counts_on(:tags).length.should == 2
      @taggable.tag_counts_on(:tags).length.should == 2
    end

    it "should have tags_on" do
      NonStandardIdTaggableModel.tags_on(:tags).should be_empty

      @taggable.tag_list = ["awesome", "epic"]
      @taggable.save

      NonStandardIdTaggableModel.tags_on(:tags).length.should == 2
      @taggable.tags_on(:tags).length.should == 2
    end

    it "should be able to create tags" do
      @taggable.skill_list = "ruby, rails, css"
      @taggable.instance_variable_get("@skill_list").instance_of?(ActsAsTaggableOn::TagList).should be_true

      lambda {
        @taggable.save
      }.should change(ActsAsTaggableOn::Tag, :count).by(3)

      @taggable.reload
      @taggable.skill_list.sort.should == %w(ruby rails css).sort
    end

    it "should be able to create tags through the tag list directly" do
      @taggable.tag_list_on(:test).add("hello")
      @taggable.tag_list_cache_on(:test).should_not be_empty
      @taggable.tag_list_on(:test).should == ["hello"]

      @taggable.save
      @taggable.save_tags

      @taggable.reload
      @taggable.tag_list_on(:test).should == ["hello"]
    end
  end

  describe "Dirty Objects" do
    context "with un-contexted tags" do
      before(:each) do
        @taggable = TaggableModel.create(:tag_list => "awesome, epic")
      end

      context "when tag_list changed" do
        before(:each) do
          @taggable.changes.should == {}
          @taggable.tag_list = 'one'
        end

        it 'should show changes of dirty object' do
          @taggable.changes.should == {"tag_list"=>["awesome, epic", ["one"]]}
        end

        it 'flags tag_list as changed' do
          @taggable.tag_list_changed?.should be_true
        end

        it 'preserves original value' do
          @taggable.tag_list_was.should == "awesome, epic"
        end

        it 'shows what the change was' do
          @taggable.tag_list_change.should == ["awesome, epic", ["one"]]
        end
      end

      context 'when tag_list is the same' do
        before(:each) do
          @taggable.tag_list = "awesome, epic"
        end

        it 'is not flagged as changed' do
          @taggable.tag_list_changed?.should be_false
        end

        it 'does not show any changes to the taggable item' do
          @taggable.changes.should == {}
        end
      end
    end

    context "with context tags" do
      before(:each) do
        @taggable = TaggableModel.create(:language_list => "awesome, epic")
      end

      context "when language_list changed" do
        before(:each) do
          @taggable.changes.should == {}
          @taggable.language_list = 'one'
        end

        it 'should show changes of dirty object' do
          @taggable.changes.should == {"language_list"=>["awesome, epic", ["one"]]}
        end

        it 'flags language_list as changed' do
          @taggable.language_list_changed?.should be_true
        end

        it 'preserves original value' do
          @taggable.language_list_was.should == "awesome, epic"
        end

        it 'shows what the change was' do
          @taggable.language_list_change.should == ["awesome, epic", ["one"]]
        end

        it 'shows what the changes were' do
          @taggable.language_list_changes.should == ["awesome, epic", ["one"]]
        end
      end

      context 'when language_list is the same' do
        before(:each) do
          @taggable.language_list = "awesome, epic"
        end

        it 'is not flagged as changed' do
          @taggable.language_list_changed?.should be_false
        end

        it 'does not show any changes to the taggable item' do
          @taggable.changes.should == {}
        end
      end
    end
  end

  describe "Autogenerated methods" do
    it "should be overridable" do
      TaggableModel.create(:tag_list=>'woo').tag_list_submethod_called.should be_true
    end
  end
end


