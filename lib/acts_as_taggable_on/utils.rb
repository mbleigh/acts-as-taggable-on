module ActsAsTaggableOn
  module Utils
    extend self

    def connection
      ::ActiveRecord::Base.connection
    end

    def using_postgresql?
      connection && connection.adapter_name == 'PostgreSQL'
    end

    def using_sqlite?
      connection && connection.adapter_name == 'SQLite'
    end

    def using_mysql?
      #We should probably use regex for mysql to support prehistoric adapters
      connection && connection.adapter_name == 'Mysql2'
    end

    def using_case_insensitive_collation?
      using_mysql? && ::ActiveRecord::Base.connection.collation =~ /_ci\Z/
    end

    def supports_concurrency?
      !using_sqlite?
    end

    def sha_prefix(string)
      Digest::SHA1.hexdigest("#{string}#{rand}")[0..6]
    end

    private

    def like_operator
      using_postgresql? ? 'ILIKE' : 'LIKE'
    end

    # escape _ and % characters in strings, since these are wildcards in SQL.
    def escape_like(str)
      str.gsub(/[!%_]/) { |x| '!' + x }
    end
  end
end
