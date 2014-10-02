# encoding: utf-8
module ActsAsTaggableOn
  class Migrator < ActiveRecord::Migration


    # Generate instance methods
    def initialize(namespace: nil)
      initialize_namespacing! namespace
      [:make_tables!, :make_unique_indexes!, :make_taggings_counter_cache!, :add_missing_taggable_index!].each do |meth|
        define_singleton_method meth, lambda {
          self.class.send meth, namespace: @namespace
        }
      end
    end

    def self.initialize_namespacing!(namespace=nil)
      @namespace = namespace
      return if @initialized
      ActsAsTaggableOn.namespace_base_classes! namespace
      @initialized = true
    end
    def initialize_namespacing!(namespace=nil)
      @namespace = namespace
      return if @initialized
      ActsAsTaggableOn.namespace_base_classes! namespace
      @initialized = true
    end




    # First migration
    def self.make_tables!(namespace: nil)
      self.initialize_namespacing! namespace
      create_table ns(:tags) do |t|
        t.string :name
      end

      create_table ns(:taggings) do |t|
        t.references ns(:tag)

        # You should make sure that the column created is
        # long enough to store the required class names.
        t.references :taggable, polymorphic: true
        t.references :tagger, polymorphic: true

        # Limit is created to prevent MySQL error on index
        # length for MyISAM table type: http://bit.ly/vgW2Ql
        t.string :context, limit: 128

        t.datetime :created_at
      end

      add_index ns(:taggings), ns(:tag_id)
      add_index ns(:taggings), [:taggable_id, :taggable_type, :context], name: ns(:taggings_itc)
    end

    def self.destroy_tables!(namespace: nil)
      self.initialize_namespacing! namespace
      drop_table ns(:taggings)
      drop_table ns(:tags)
    end




    # Second migration
    def self.make_unique_indexes!(namespace: nil)
      self.initialize_namespacing! namespace
      add_index ns(:tags), :name, unique: true

      remove_index ns(:taggings), ns(:tag_id)
      remove_index ns(:taggings), name: ns(:taggings_itc)
      add_index ns(:taggings),
                [ns(:tag_id), :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
                unique: true, name: ns(:taggings_idx)
    end

    def self.destroy_unique_indexes!(namespace: nil)
      self.initialize_namespacing! namespace
      remove_index ns(:tags), :name

      remove_index ns(:taggings), name: ns(:taggings_idx)
      add_index ns(:taggings), ns(:tag_id)
      add_index ns(:taggings), [:taggable_id, :taggable_type, :context], name: ns(:taggings_itc)
    end




    # Third migration
    def self.make_taggings_counter_cache!(namespace: nil)
      self.initialize_namespacing! namespace
      add_column ns(:tags), ns(:taggings_count), :integer, default: 0
      m = ns_class(:Tag)

      m.reset_column_information
      m.find_each do |tag|
        m.reset_counters(tag.id, ns(:taggings))
      end
    end

    def self.destroy_taggings_counter_cache!(namespace: nil)
      self.initialize_namespacing! namespace
      remove_column :tags, :taggings_count
    end



    # Fourth migration - doesn't this conflict/duplicate a past migration?!?!
    def self.add_missing_taggable_index!(namespace: nil)
      self.initialize_namespacing! namespace
      add_index ns(:taggings), [:taggable_id, :taggable_type, :context], name: ns(:taggings_itc)
    end

    def self.destroy_missing_taggable_index!(namespace: nil)
      self.initialize_namespacing! namespace
      remove_index ns(:taggings), [:taggable_id, :taggable_type, :context], name: ns(:taggings_itc)
    end




    private

    def self.ns(obj)
      ActsAsTaggableOn.namespaced_attribute(@namespace, obj)
    end
    def self.ns_class(obj)
      ActsAsTaggableOn.namespaced_class(@namespace, obj)
    end




  end
end
