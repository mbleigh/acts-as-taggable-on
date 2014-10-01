ActiveRecord::Schema.define version: 0 do


  create_table :tags, force: true do |t|
    t.string :name
    t.integer :taggings_count, default: 0
    t.string :type
  end
  add_index 'tags', ['name'], name: 'index_tags_on_name', unique: true

  create_table :taggings, force: true do |t|
    t.references :tag

    # You should make sure that the column created is
    # long enough to store the required class names.
    t.references :taggable, polymorphic: true
    t.references :tagger, polymorphic: true

    # Limit is created to prevent MySQL error on index
    # length for MyISAM table type: http://bit.ly/vgW2Ql
    t.string :context, limit: 128

    t.datetime :created_at
  end
  add_index 'taggings',
            ['tag_id', 'taggable_id', 'taggable_type', 'context', 'tagger_id', 'tagger_type'],
            unique: true, name: 'taggings_idx'



  create_table :nspaced_tags, force: true do |t|
    t.string :name
    t.integer :nspaced_taggings_count, default: 0
    t.string :type
  end
  add_index 'nspaced_tags', ['name'], name: 'index_nspaced_tags_on_name', unique: true

  create_table :nspaced_taggings, force: true do |t|
    t.references :nspaced_tag

    # You should make sure that the column created is
    # long enough to store the required class names.
    t.references :taggable, polymorphic: true
    t.references :tagger, polymorphic: true

    # Limit is created to prevent MySQL error on index
    # length for MyISAM table type: http://bit.ly/vgW2Ql
    t.string :context, limit: 128

    t.datetime :created_at
  end
  add_index 'nspaced_taggings',
            ['nspaced_tag_id', 'taggable_id', 'taggable_type', 'context', 'tagger_id', 'tagger_type'],
            unique: true, name: 'nspaced_taggings_idx'



  # above copied from
  # generators/acts_as_taggable_on/migration/migration_generator



  # Test models (could be named anything in a live application)
  [:taggable_models, :taggable_namespaced_models].each do |m|
    create_table m, force: true do |t|
      t.column :name, :string
      t.column :type, :string
    end

    create_table "non_standard_id_#{m}", primary_key: 'an_id', force: true do |t|
      t.column :name, :string
      t.column :type, :string
    end

    create_table "un#{m}", force: true do |t|
      t.column "#{m.to_s.singularize}_id", :integer
      t.column :name, :string
    end

    create_table "other_#{m}", force: true do |t|
      t.column :name, :string
      t.column :type, :string
    end

    create_table "ordered_#{m}", force: true do |t|
      t.column :name, :string
      t.column :type, :string
    end
  end


  [nil, :namespaced_].each do |m|
    create_table "cached_#{m}models", force: true do |t|
      t.column :name, :string
      t.column :type, :string
      t.column :cached_tag_list, :string
    end

    create_table "other_cached_#{m}models", force: true do |t|
      t.column :name, :string
      t.column :type, :string
      t.column :cached_language_list, :string
      t.column :cached_status_list, :string
      t.column :cached_glass_list, :string
    end

    create_table "#{m}users", force: true do |t|
      t.column :name, :string
    end

    create_table "#{m}companies", force: true do |t|
      t.column :name, :string
    end
  end


  # Special cases for postgresql
  if using_postgresql?

    create_table :other_cached_with_array_models, force: true do |t|
      t.column :name, :string
      t.column :type, :string
      t.column :cached_language_list, :string, array: true
      t.column :cached_status_list, :string, array: true
      t.column :cached_glass_list, :string, array: true
    end

    if postgresql_support_json?
      create_table :taggable_model_with_jsons, :force => true do |t|
        t.column :name, :string
        t.column :type, :string
        t.column :opts, :json
      end
    end
  end
end
