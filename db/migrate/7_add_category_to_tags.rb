if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddCategoryToTags < ActiveRecord::Migration[4.2]; end
else
  class AddCategoryToTags < ActiveRecord::Migration; end
end
AddCategoryToTags.class_eval do
  def self.up
    add_column ActsAsTaggableOn.tags_table, :category, :string
  end

  def self.down
    remove_column ActsAsTaggableOn.tags_table, :category
  end
end
