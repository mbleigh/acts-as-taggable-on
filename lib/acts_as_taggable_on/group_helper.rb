module ActiveRecord
  module Acts
    module TaggableOn
      module GroupHelper
        # all column names are necessary for PostgreSQL group clause
        def grouped_column_names_for(object)
          object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(", ")
        end
      end
    end
  end
end