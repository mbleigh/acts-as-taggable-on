class AddTagForeignKey < ActiveRecord::Migration
  def change
    add_foreign_key :taggings, :tags, column: :tag_id
  end
end
