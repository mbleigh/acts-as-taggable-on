if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddTenantToTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddTenantToTaggings < ActiveRecord::Migration; end
end
AddTenantToTaggings.class_eval do
  def self.up
    add_column ActsAsTaggableOn.taggings_table, :tenant, :string, limit: 128
    add_index ActsAsTaggableOn.taggings_table, :tenant unless index_exists? ActsAsTaggableOn.taggings_table, :tenant
  end

  def self.down
    remove_index ActsAsTaggableOn.taggings_table, :tenant
    remove_column ActsAsTaggableOn.taggings_table, :tenant
  end
end
