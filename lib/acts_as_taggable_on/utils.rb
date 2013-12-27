require "digest/sha1"
module ActsAsTaggableOn
  module Utils

    def self.included(host_klass)
      host_klass.extend self
    end

    def db_adapter_name
      ActiveRecord::Base.connection_config[:adapter].dup.downcase
    end

    def using_postgresql?
      db_adapter_name == 'postgresql'
    end

    def using_sqlite?
      db_adapter_name.start_with?('sqlite')
    end

    def using_mysql?
      db_adapter_name.start_with?('mysql')
    end

    def sha_prefix(string)
      Digest::SHA1.hexdigest("#{string}#{rand}")[0..6]
    end

    def like_operator
      using_postgresql? ? 'ILIKE' : 'LIKE'
    end

    # escape _ and % characters in strings, since these are wildcards in SQL.
    def escape_like(str)
      str.gsub(/[!%_]/){ |x| '!' + x }
    end

    def comparable_name(str)
      as_8bit_ascii(str).downcase
    end

    def binary
      using_mysql? ? "BINARY " : nil
    end

    def as_8bit_ascii(string)
      if defined?(Encoding)
        string.to_s.force_encoding('BINARY')
      else
        string.to_s.mb_chars
      end
    end

  end
end
