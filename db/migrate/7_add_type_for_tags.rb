class AddTypeForTags < ActiveRecord::Migration
  def change
    unless column_exists? :tags, :type
      add_column :tags, :type, :string, null: false, default: 'ActsAsTaggableOn::Tag'
    end
  end
end
