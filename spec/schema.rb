ActiveRecord::Schema.define :version => 0 do
  create_table :tags, :force => true do |t|
    t.string :name
  end

  create_table :taggings, :force => true do |t|
    t.references :tag

    # You should make sure that the column created is
    # long enough to store the required class names.
    t.references :taggable, :polymorphic => true
    t.references :tagger, :polymorphic => true

    # Limit is created to prevent MySQL error on index
    # length for MyISAM table type: http://bit.ly/vgW2Ql
    t.string :context, :limit => 128

    t.datetime :created_at
  end
  # above copied from
  # generators/acts_as_taggable_on/migration/migration_generator

  create_table :taggable_models, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :non_standard_id_taggable_models, :primary_key => "an_id", :force => true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :untaggable_models, :force => true do |t|
    t.column :taggable_model_id, :integer
    t.column :name, :string
  end

  create_table :cached_models, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :cached_tag_list, :string
  end

  create_table :other_cached_models, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
    t.column :cached_language_list, :string
    t.column :cached_status_list, :string
    t.column :cached_glass_list, :string
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
  end

  create_table :other_taggable_models, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
  end

  create_table :ordered_taggable_models, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
  end
end
