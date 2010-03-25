require 'active_record'
require 'action_view'
require File.expand_path('../../lib/acts-as-taggable-on', __FILE__)

if defined?(ActiveRecord::Acts::TaggableOn)
  ActiveRecord::Base.send :include, ActiveRecord::Acts::TaggableOn
  ActiveRecord::Base.send :include, ActiveRecord::Acts::Tagger
  ActionView::Base.send :include, TagsHelper if defined?(ActionView::Base)
end

TEST_DATABASE_FILE = File.join(File.dirname(__FILE__), '..', 'test.sqlite3')
File.unlink(TEST_DATABASE_FILE) if File.exist?(TEST_DATABASE_FILE)
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => TEST_DATABASE_FILE

ActiveRecord::Base.silence do
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define :version => 0 do
    create_table "taggings", :force => true do |t|
      t.integer  "tag_id",        :limit => 11
      t.integer  "taggable_id",   :limit => 11
      t.string   "taggable_type"
      t.string   "context"
      t.datetime "created_at"
      t.integer  "tagger_id",     :limit => 11
      t.string   "tagger_type"
    end

    add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
    add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

    create_table "tags", :force => true do |t|
      t.string "name"
    end

    create_table :taggable_models, :force => true do |t|
      t.column :name, :string
      t.column :type, :string
      t.column :cached_tag_list, :string
    end
  end

  class TaggableModel < ActiveRecord::Base
    acts_as_taggable
    acts_as_taggable_on :languages
    acts_as_taggable_on :skills
    acts_as_taggable_on :needs, :offerings
  end
end

puts Benchmark.measure {
  1000.times { TaggableModel.create :tag_list => "awesome, epic, neat" }
}