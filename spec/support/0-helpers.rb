def using_sqlite?
  ActsAsTaggableOn::Utils.connection && ActsAsTaggableOn::Utils.connection.adapter_name == 'SQLite'
end

def supports_concurrency?
  !using_sqlite?
end

def using_postgresql?
  ActsAsTaggableOn::Utils.using_postgresql?
end

def postgresql_version
  if using_postgresql?
    ActsAsTaggableOn::Utils.connection.execute('SHOW SERVER_VERSION').first['server_version'].to_f
  else
    0.0
  end
end

def postgresql_support_json?
  postgresql_version >= 9.2
end


def using_mysql?
  ActsAsTaggableOn::Utils.using_mysql?
end

def using_case_insensitive_collation?
  using_mysql? && ActsAsTaggableOn::Utils.connection.collation =~ /_ci\Z/
end

# Quickly retrieve table contents for debugging...feel free
# to modify --- used for debugging tests
def look_at_database(options = {only: nil})
  only = options[:only]
  puts "\n\n========== Database Tables =========="
  if only.nil? or only == :tags
    puts "\n---tags---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM tags").inspect
  end
  if only.nil? or only == :taggings
    puts "\n---taggings---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM taggings").inspect
  end
  if only.nil? or only == :taggable_models
    puts "\n---taggable_models---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM taggable_models").inspect
  end
  puts "\n\n---\n\n" if only.nil?
  if only.nil? or only == :tags
    puts "\n---nspaced_tags---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM nspaced_tags").inspect
  end
  if only.nil? or only == :taggigns
    puts "\n---nspaced_taggings---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM nspaced_taggings").inspect
  end
  if only.nil? or only == :taggable_models
    puts "\n---taggable_namespaced_models---"
    puts ActiveRecord::Base.connection.execute("SELECT * FROM taggable_namespaced_models").inspect
  end
  puts "\n================ End ================\n\n"
end