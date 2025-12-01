# frozen_string_literal: true

# Combined migration for acts_as_taggable_on setup
# Combines migrations 1-7 from acts_as_taggable_on_engine
class SetupActsAsTaggableOn < ActiveRecord::Migration[7.1]
  def up
    # Create tags table
    unless table_exists?(ActsAsTaggableOn.tags_table)
      create_table ActsAsTaggableOn.tags_table do |t|
        t.string :name
        t.integer :taggings_count, default: 0
        t.timestamps
      end
    end

    # Add unique index on tag name
    unless index_exists?(ActsAsTaggableOn.tags_table, :name)
      add_index ActsAsTaggableOn.tags_table, :name, unique: true
    end

    # Create taggings table
    unless table_exists?(ActsAsTaggableOn.taggings_table)
      create_table ActsAsTaggableOn.taggings_table do |t|
        t.references :tag, foreign_key: { to_table: ActsAsTaggableOn.tags_table }
        t.references :taggable, polymorphic: true
        t.references :tagger, polymorphic: true
        t.string :context, limit: 128
        t.string :tenant, limit: 128
        t.datetime :created_at
      end
    end

    # Add all indexes
    add_index ActsAsTaggableOn.taggings_table,
              %i[tag_id taggable_id taggable_type context tagger_id tagger_type],
              unique: true, name: "taggings_idx" unless index_exists?(ActsAsTaggableOn.taggings_table, "taggings_idx", name: true)

    add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type context],
              name: "taggings_taggable_context_idx" unless index_exists?(ActsAsTaggableOn.taggings_table, "taggings_taggable_context_idx", name: true)

    add_index ActsAsTaggableOn.taggings_table, :tag_id unless index_exists?(ActsAsTaggableOn.taggings_table, :tag_id)
    add_index ActsAsTaggableOn.taggings_table, :taggable_id unless index_exists?(ActsAsTaggableOn.taggings_table, :taggable_id)
    add_index ActsAsTaggableOn.taggings_table, :taggable_type unless index_exists?(ActsAsTaggableOn.taggings_table, :taggable_type)
    add_index ActsAsTaggableOn.taggings_table, :tagger_id unless index_exists?(ActsAsTaggableOn.taggings_table, :tagger_id)
    add_index ActsAsTaggableOn.taggings_table, :context unless index_exists?(ActsAsTaggableOn.taggings_table, :context)
    add_index ActsAsTaggableOn.taggings_table, %i[tagger_id tagger_type] unless index_exists?(ActsAsTaggableOn.taggings_table, %i[tagger_id tagger_type])
    add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type tagger_id context],
              name: "taggings_idy" unless index_exists?(ActsAsTaggableOn.taggings_table, "taggings_idy", name: true)
    add_index ActsAsTaggableOn.taggings_table, :tenant unless index_exists?(ActsAsTaggableOn.taggings_table, :tenant)

    # Change collation for MySQL
    return unless ActsAsTaggableOn::Utils.using_mysql?
    return if table_exists?(ActsAsTaggableOn.tags_table) && column_exists?(ActsAsTaggableOn.tags_table, :name)

    execute("ALTER TABLE #{ActsAsTaggableOn.tags_table} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
  end

  def down
    # Depdending on your needs, you might want to implement the down method.
    # Uncomment the lines below for new installations where rollback is necessary.
    # drop_table ActsAsTaggableOn.taggings_table
    # drop_table ActsAsTaggableOn.tags_table
    raise ActiveRecord::IrreversibleMigration
  end
end
