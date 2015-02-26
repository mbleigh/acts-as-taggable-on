# This rake task is to be run by MySql users only, and fixes the management of 
# binary-encoded strings for tag 'names'. Issues: 
# https://github.com/mbleigh/acts-as-taggable-on/issues/623

namespace :acts_as_taggable_on_engine do

  namespace :tag_names do

    desc "Forcing collate of tag names to utf8_bin"
    task :collate => [:environment] do |t, args|
      puts "Changing collate for column 'name' of table 'tags'"
      ActiveRecord::Migration.execute("ALTER TABLE tags MODIFY name varchar(255) CHARACTER SET utf8 COLLATE utf8_bin;")
    end

  end

end
