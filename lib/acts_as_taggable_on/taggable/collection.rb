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
      
      ##
      # Calculate the tag counts for all tags.
      #
      # @param [Hash] options Options:
      #                       * :start_at   - Restrict the tags to those created after a certain time
      #                       * :end_at     - Restrict the tags to those created before a certain time
      #                       * :conditions - A piece of SQL conditions to add to the query
      #                       * :limit      - The maximum number of tags to return
      #                       * :order      - A piece of SQL to order by. Eg 'tags.count desc' or 'taggings.created_at desc'
      #                       * :at_least   - Exclude tags with a frequency less than the given value
      #                       * :at_most    - Exclude tags with a frequency greater than the given value
      #                       * :on         - Scope the find to only include a certain context
      def all_tag_counts(options = {})
        options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit, :on, :id

        scope = if ActiveRecord::VERSION::MAJOR >= 3
                  {}
                else
                  scope(:find) || {}           
                end

        ## Generate conditions:
        options[:conditions] = sanitize_sql(options[:conditions]) if options[:conditions]     
          
        start_at_conditions = sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
        end_at_conditions   = sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at <= ?", options.delete(:end_at)])   if options[:end_at]

        taggable_conditions  = sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.taggable_type = ?", base_class.name])
        taggable_conditions << sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = ?", options.delete(:id)]) if options[:id]

        conditions = [
          taggable_conditions,
          options[:conditions],
          scope[:conditions],
          start_at_conditions,
          end_at_conditions
        ].compact.reverse
        
        ## Generate joins:
        tagging_join  = "LEFT OUTER JOIN #{ActsAsTaggableOn::Tagging.table_name} ON #{ActsAsTaggableOn::Tag.table_name}.id = #{ActsAsTaggableOn::Tagging.table_name}.tag_id"
        tagging_join << sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", options.delete(:on).to_s]) if options[:on]

        taggable_join = "INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id"
        taggable_join << " AND #{table_name}.#{inheritance_column} = '#{name}'" unless descends_from_active_record? # Current model is STI descendant, so add type checking to the join condition      

        joins = [
          tagging_join,
          taggable_join,
          scope[:joins]
        ].compact

        joins = joins.reverse if ActiveRecord::VERSION::MAJOR < 3


        ## Generate scope:
        scope = ActsAsTaggableOn::Tag.scoped(:select => "#{ActsAsTaggableOn::Tag.table_name}.*, COUNT(*) AS count").order(options[:order]).limit(options[:limit])   
        
        # Joins and conditions
        joins.each      { |join|      scope = scope.joins(join)      }
        conditions.each { |condition| scope = scope.where(condition) }
        
        # GROUP BY and HAVING clauses:
        at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
        at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
        having    = [at_least, at_most].compact.join(' AND ')        

        if ActiveRecord::VERSION::MAJOR >= 3
          # Append the current scope to the scope, because we can't use scope(:find) in RoR 3.0 anymore:
          scoped_select = "#{table_name}.#{primary_key}"
          scope = scope.where("#{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN(#{select(scoped_select).to_sql})")
          
          # We have having() in RoR 3.0 so use it:
          having = having.blank? ? "COUNT(*) > 0" : "COUNT(*) > 0 AND #{having}"
          scope = scope.group(grouped_column_names_for(ActsAsTaggableOn::Tag)).having(having)
        else
          # Having is not available in 2.3.x:
          group_by  = "#{grouped_column_names_for(ActsAsTaggableOn::Tag)} HAVING COUNT(*) > 0"
          group_by << " AND #{having}" unless having.blank?
          scope = scope.group(group_by)
        end

        scope
      end
    end
    
    module InstanceMethods
      def tag_counts_on(context, options={})
        self.class.tag_counts_on(context, options.merge(:id => id))
      end
    end
  end
end