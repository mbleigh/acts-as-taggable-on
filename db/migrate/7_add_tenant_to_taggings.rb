if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddTenantToTaggings < ActiveRecord::Migration[4.2]; end
else
  class AddTenantToTaggings < ActiveRecord::Migration; end
end
AddTenantToTaggings.class_eval do
  def self.up
    add_column :taggings, :tenant, :string, limit: 128
    add_index :taggings, :tenant unless index_exists? :taggings, :tenant
  end

  def self.down
    remove_index :taggings, :tenant
    remove_column :taggings, :tenant
  end
end
