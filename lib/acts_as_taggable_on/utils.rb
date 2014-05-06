module ActsAsTaggableOn
  module Utils
    extend self

    # Use ActsAsTaggableOn::Tag connection
    def connection
      ActsAsTaggableOn::Tag.connection
    end

    def using_postgresql?
      connection && connection.adapter_name == 'PostgreSQL'
    end

    def postgresql_version
      if using_postgresql?
        connection.execute("SHOW SERVER_VERSION").first["server_version"].to_f
      end
    end

    def postgresql_support_json?
      postgresql_version >= 9.2
    end

    def using_sqlite?
      connection && connection.adapter_name == 'SQLite'
    end

    def using_mysql?
      #We should probably use regex for mysql to support prehistoric adapters
      connection && connection.adapter_name == 'Mysql2'
    end

    def using_case_insensitive_collation?
      using_mysql? && connection.collation =~ /_ci\Z/
    end

    def supports_concurrency?
      !using_sqlite?
    end

    def sha_prefix(string)
      Digest::SHA1.hexdigest("#{string}#{rand}")[0..6]
    end

    def active_record4?
      ::ActiveRecord::VERSION::MAJOR == 4
    end

    def active_record42?
      active_record4? && ::ActiveRecord::VERSION::MINOR >= 2
    end

    def like_operator
      using_postgresql? ? 'ILIKE' : 'LIKE'
    end

    # escape _ and % characters in strings, since these are wildcards in SQL.
    def escape_like(str)
      str.gsub(/[!%_]/) { |x| '!' + x }
    end
  end
end
