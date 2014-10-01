class AddMissingUniqueIndices < ActiveRecord::Migration
  def self.up(namespace: nil)
    add_index ns_column(namespace, :tags), :name, unique: true

    remove_index ns_column(namespace, :taggings), ns_column(namespace, :tag_id)
    remove_index ns_column(namespace, :taggings), name: "#{ns_column(namespace, :taggings)}_itc"
    add_index ns_column(namespace, :taggings),
              [ns_column(namespace, :tag_id), :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type],
              unique: true, name: "#{ns_column(namespace, :taggings)}_idx"
  end

  def self.down(namespace: nil)
    remove_index ns_column(namespace, :tags), :name

    remove_index ns_column(namespace, :taggings), name: "#{ns_column(namespace, :taggings)}_idx"
    add_index ns_column(namespace, :taggings), ns_column(namespace, :tag_id)
    add_index ns_column(namespace, :taggings), [:taggable_id, :taggable_type, :context], name: "#{ns_column(namespace, :taggings)}_itc"
  end

  def self.ns_column(namespace, col)
    ActsAsTaggableOn.namespaced_attribute namespace, col
  end
end
