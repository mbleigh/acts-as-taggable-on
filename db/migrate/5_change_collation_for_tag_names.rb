# This migration is added to circumvent issue #623 and have special characters
# work properly
if ActiveRecord.gem_version >= Gem::Version.new('5.1')
  class ChangeCollationForTagNames < ActiveRecord::Migration[5.1]; end
else
  class ChangeCollationForTagNames < ActiveRecord::Migration[5.0]; end
end
ChangeCollationForTagNames.class_eval do
  def up
    if ActsAsTaggableOn::Utils.using_mysql?
      execute("ALTER TABLE #{ActsAsTaggableOn.tags_table} MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
    end
  end
end
