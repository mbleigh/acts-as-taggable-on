module ActsAsTaggableOn::Taggable
  module Collection
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Collection::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Collection::ClassMethods
      base.initialize_acts_as_taggable_on_collection
    end
    
    module ClassMethods
      def initialize_acts_as_taggable_on_collection
        tag_types.map(&:to_s).each do |tag_type|
          class_eval %(
            def self.#{tag_type.singularize}_counts(options={})
              tag_counts_on('#{tag_type}', options)
            end

            def #{tag_type.singularize}_counts(options = {})
              tag_counts_on('#{tag_type}', options)
            end

            def top_#{tag_type}(limit = 10)
              tag_counts_on('#{tag_type}', :order => 'count desc', :limit => limit.to_i)
            end

            def self.top_#{tag_type}(limit = 10)
              tag_counts_on('#{tag_type}', :order => 'count desc', :limit => limit.to_i)
            end        
          )
        end        
      end
      
      def acts_as_taggable_on(*args)
        super(*args)
        initialize_acts_as_taggable_on_collection
      end
      
      def tag_counts_on(context, options = {})
        all_tag_counts(options.merge({:on => context.to_s}))
      end
      
      # Calculate the tag counts for all tags.
      #
      # Options:
      #  :start_at - Restrict the tags to those created after a certain time
      #  :end_at - Restrict the tags to those created before a certain time
      #  :conditions - A piece of SQL conditions to add to the query
      #  :limit - The maximum number of tags to return
      #  :order - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
      #  :at_least - Exclude tags with a frequency less than the given value
      #  :at_most - Exclude tags with a frequency greater than the given value
      #  :on - Scope the find to only include a certain context
      def all_tag_counts(options = {})
        options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :on, :id

        start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
        end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]

        taggable_type = sanitize_sql(["#{Tagging.table_name}.taggable_type = ?", base_class.name])
        taggable_id = sanitize_sql(["#{Tagging.table_name}.taggable_id = ?", options.delete(:id)]) if options[:id]
        options[:conditions] = sanitize_sql(options[:conditions]) if options[:conditions]

        conditions = [
          taggable_type,
          taggable_id,
          options[:conditions],
          start_at,
          end_at
        ]

        conditions = conditions.compact.join(' AND ')

        joins = ["LEFT OUTER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
        joins << sanitize_sql(["AND #{Tagging.table_name}.context = ?",options.delete(:on).to_s]) unless options[:on].nil?
        joins << " INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{Tagging.table_name}.taggable_id"

        unless descends_from_active_record?
          # Current model is STI descendant, so add type checking to the join condition
          joins << " AND #{table_name}.#{inheritance_column} = '#{name}'"
        end

        at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
        at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
        having    = [at_least, at_most].compact.join(' AND ')
        group_by  = "#{grouped_column_names_for(Tag)} HAVING COUNT(*) > 0"
        group_by << " AND #{having}" unless having.blank?

        Tag.select("#{Tag.table_name}.*, COUNT(*) AS count").joins(joins.join(" ")).where(conditions).group(group_by).limit(options[:limit]).order(options[:order])
      end
    end
    
    module InstanceMethods
      def tag_counts_on(context, options={})
        self.class.tag_counts_on(context, options.merge(:id => id))
      end
    end
  end
end