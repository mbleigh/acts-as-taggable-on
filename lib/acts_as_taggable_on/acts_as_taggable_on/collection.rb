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
        taggable_conditions << sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = ?", options.delete(:id)])  if options[:id]
        taggable_conditions << sanitize_sql([" AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", options.delete(:on).to_s]) if options[:on]
        
        tagging_conditions = [
          taggable_conditions,
          scope[:conditions],
          start_at_conditions,
          end_at_conditions
        ].compact.reverse
        
        tag_conditions = [
          options[:conditions]        
        ].compact.reverse
        
        ## Generate joins:
        taggable_join = "INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{ActsAsTaggableOn::Tagging.table_name}.taggable_id"
        taggable_join << " AND #{table_name}.#{inheritance_column} = '#{name}'" unless descends_from_active_record? # Current model is STI descendant, so add type checking to the join condition      

        tagging_joins = [
          taggable_join,
          scope[:joins]
        ].compact

        tag_joins = [
        ].compact

        [tagging_joins, tag_joins].each(&:reverse!) if ActiveRecord::VERSION::MAJOR < 3

        ## Generate scope:
        tagging_scope = ActsAsTaggableOn::Tagging.select("#{ActsAsTaggableOn::Tagging.table_name}.tag_id, COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) AS tags_count")
        tag_scope = ActsAsTaggableOn::Tag.select("#{ActsAsTaggableOn::Tag.table_name}.*, #{ActsAsTaggableOn::Tagging.table_name}.tags_count AS count").order(options[:order]).limit(options[:limit])   

        # Joins and conditions
        tagging_joins.each      { |join|      tagging_scope = tagging_scope.joins(join)      }        
        tagging_conditions.each { |condition| tagging_scope = tagging_scope.where(condition) }

        tag_joins.each          { |join|      tag_scope     = tag_scope.joins(join)          }
        tag_conditions.each     { |condition| tag_scope     = tag_scope.where(condition)     }

        # GROUP BY and HAVING clauses:
        at_least  = sanitize_sql(['tags_count >= ?', options.delete(:at_least)]) if options[:at_least]
        at_most   = sanitize_sql(['tags_count <= ?', options.delete(:at_most)]) if options[:at_most]
        having    = ["COUNT(#{ActsAsTaggableOn::Tagging.table_name}.tag_id) > 0", at_least, at_most].compact.join(' AND ')    

        group_columns = "#{ActsAsTaggableOn::Tagging.table_name}.tag_id"

        if ActiveRecord::VERSION::MAJOR >= 3
          # Append the current scope to the scope, because we can't use scope(:find) in RoR 3.0 anymore:
          scoped_select = "#{table_name}.#{primary_key}"
          tagging_scope = tagging_scope.where("#{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN(#{select(scoped_select).to_sql})").
                                        group(group_columns).
                                        having(having)
        else
          # Having is not available in 2.3.x:
          group_by  = "#{group_columns} HAVING COUNT(*) > 0"
          group_by << " AND #{having}" unless having.blank?
          tagging_scope = tagging_scope.group(group_by)
        end

        tag_scope = tag_scope.joins("JOIN (#{tagging_scope.to_sql}) AS taggings ON taggings.tag_id = tags.id")
        tag_scope
      end
    end
    
    module InstanceMethods
      def tag_counts_on(context, options={})
        self.class.tag_counts_on(context, options.merge(:id => id))
      end
    end
  end
end