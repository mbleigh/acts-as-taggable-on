class AddTimestampToTags < ActiveRecord::Migration
  def up
    unless column_exists? :tags, :updated_at
      add_column :tags, :updated_at, :datetime
    end

    unlesss column_exists? :tags, :aggregated_at
      add_column :tags, :aggregated_at, :datetime
    end
  end

  def down
    remove_column :tags, :updated_at
    remove_column :tags, :aggregated_at
  end
end
