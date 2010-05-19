module ActsAsTaggableOn
  module Taggable
    module PostgreSQL
      def self.included(base)
        base.send :include, ActsAsTaggableOn::Taggable::PostgreSQL::InstanceMethods
        base.extend ActsAsTaggableOn::Taggable::PostgreSQL::ClassMethods
      
        ActsAsTaggableOn::Tag.class_eval do
          def self.named(name)
            where(["name ILIKE ?", name])
          end

          def self.named_any(list)
            where(list.map { |tag| sanitize_sql(["name ILIKE ?", tag.to_s]) }.join(" OR "))
          end

          def self.named_like(name)
            where(["name ILIKE ?", "%#{name}%"])
          end

          def self.named_like_any(list)
            where(list.map { |tag| sanitize_sql(["name ILIKE ?", "%#{tag.to_s}%"]) }.join(" OR "))
          end          
        end
      end
      
      module InstanceMethods
      end
      
      module ClassMethods
        # all column names are necessary for PostgreSQL group clause
        def grouped_column_names_for(*objects)
          object   = objects.shift
          columns  = object.column_names.map { |column| "#{object.table_name}.#{column}" }
          columns << objects.map do |object|
                       "#{object.table_name}.created_at"
                     end.flatten

          columns.flatten.join(", ")
        end
      end
    end
  end
end