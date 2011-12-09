module ActsAsTaggableOn
  module Utils
    def self.included(base)
      
      base.send :include, ActsAsTaggableOn::Utils::OverallMethods
      base.extend ActsAsTaggableOn::Utils::OverallMethods      
    end

    module OverallMethods
      def using_postgresql?
        ::ActiveRecord::Base.connection && ::ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      end
      
      private
      def like_operator
        using_postgresql? ? 'ILIKE' : 'LIKE'
      end
      
      # escape _ and % characters in strings, since these are wildcards in SQL.
      def escape_like(str)
        str.to_s.gsub("_", "\\\_").gsub("%", "\\\%")
      end
    end

  end
end
