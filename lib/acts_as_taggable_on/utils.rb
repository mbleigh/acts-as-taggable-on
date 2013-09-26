module ActsAsTaggableOn
  module Utils
    def using_postgresql?
      ::ActiveRecord::Base.connection && ::ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    end

    def using_sqlite?
      ::ActiveRecord::Base.connection && ::ActiveRecord::Base.connection.adapter_name == 'SQLite'
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
      str.gsub(/[!%_]/){ |x| '!' + x }
    end
  end
end
