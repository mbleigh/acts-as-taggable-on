class AddNamespacedTableInTestEnv < ActiveRecord::Migration
  def self.up
  	if Rails.env.test?
    	execute "CREATE TABLE nspaced_taggings LIKE taggings; CREATE TABLE nspaced_tags LIKE tags; CREATE TABLE taggable_namespaced_models LIKE taggable_models;"
    end
  end

  def self.down
  	if Rails.env.test?
    	execute "DROP TABLE nspaced_taggings, nspaced_tags, taggable_namespaced_models;"
    end
  end
end
