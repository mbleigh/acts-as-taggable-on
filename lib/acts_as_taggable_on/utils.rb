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
      
    end

  end
end
