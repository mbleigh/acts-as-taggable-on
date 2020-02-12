if ActiveRecord.gem_version >= Gem::Version.new('5.0')
  class AddStatusToTags < ActiveRecord::Migration[4.2]; end
else
  class AddStatusToTags < ActiveRecord::Migration; end
end
AddStatusToTags.class_eval do
  def self.up
    add_column ActsAsTaggableOn.tags_table, :status, :boolean, default: true
  end

  def self.down
    remove_column ActsAsTaggableOn.tags_table, :status
  end
end
