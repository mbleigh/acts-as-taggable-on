ActiveRecord::Schema.define :version => 0 do
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
