module ActiveRecord
  module Acts
    module TaggableOn
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_taggable
          acts_as_taggable_on :tags
        end
        
        def acts_as_taggable_on(*args)
          self.class_eval do
            @tag_types = args
            def self.tag_types
              @tag_types
            end
            
            before_save :save_cached_tag_list
            after_save :save_tags
          end
          
          for tag_type in args
            tag_type = tag_type.to_s
            self.class_eval do
              has_many "#{tag_type.singularize}_taggings".to_sym, :as => :taggable, :dependent => :destroy, :include => :tag, :conditions => ["context = ?",tag_type], :class_name => "Tagging"
              has_many "#{tag_type}".to_sym, :through => "#{tag_type.singularize}_taggings".to_sym, :source => :tag
            end
            
            self.class_eval <<-RUBY
              def self.caching_#{tag_type.singularize}_list?
                column_names.include?("cached_#{tag_type.singularize}_list")
              end
        
              def #{tag_type.singularize}_list
                return @#{tag_type.singularize}_list unless @#{tag_type.singularize}_list.nil?
              
                if self.class.caching_#{tag_type.singularize}_list? and !(cached_value = cached_#{tag_type.singularize}_list).nil?
                  @#{tag_type.singularize}_list = TagList.from(cached_value)
                else
                  @#{tag_type.singularize}_list = TagList.new(*#{tag_type}.map(&:name))
                end
              end
            
              def #{tag_type.singularize}_list=(new_tags)
                @#{tag_type.singularize}_list = TagList.from(new_tags)
              end
            
              def #{tag_type.singularize}_counts(*args)
                options = args.empty? ? {} : args.first
                #{tag_type.singularize}_counts({:conditions => ["#{Tag.table_name}.name IN (?)", #{tag_type.singularize}_list]}.reverse_merge!(options))
              end
            RUBY
          end
          
          include ActiveRecord::Acts::TaggableOn::InstanceMethods
          extend ActiveRecord::Acts::TaggableOn::SingletonMethods          
          
          alias_method_chain :reload, :tag_list
        end
      end
      
      module SingletonMethods
        # Pass either a tag string, or an array of strings or tags
        # 
        # Options:
        #   :exclude - Find models that are not tagged with the given tags
        #   :match_all - Find models that match all of the given tags, not just one
        #   :conditions - A piece of SQL conditions to add to the query
        #   :on - scopes the find to a context
        def find_tagged_with(*args)
          options = find_options_for_find_tagged_with(*args)
          options.blank? ? [] : find(:all,options)
        end
        
        def find_options_for_find_tagged_with(tags, options = {})
          tags = tags.is_a?(Array) ? TagList.new(tags.map(&:to_s)) : TagList.from(tags)

          return {} if tags.empty?

          conditions = []
          conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]
          
          unless (on = options.delete(:on)).nil?
            conditions << sanitize_sql(["context = ?",on.to_s])
          end

          taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"

          if options.delete(:exclude)
            tags_conditions = tags.map { |t| sanitize_sql(["#{Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
            conditions << sanitize_sql(["#{table_name}.id NOT IN (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name} LEFT OUTER JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id WHERE (#{tags_conditions}) AND #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})", tags])
          else
            conditions << tags.map { |t| sanitize_sql(["#{tags_alias}.name LIKE ?", t]) }.join(" OR ")

            if options.delete(:match_all)
              group = "#{taggings_alias}.taggable_id HAVING COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
            end
          end
          
          { :select => "DISTINCT #{table_name}.*",
            :joins => "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)} " +
                      "LEFT OUTER JOIN #{Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id",
            :conditions => conditions.join(" AND "),
            :group      => group
          }.update(options)
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
        def tag_counts(options = {})
          Tag.find(:all, find_options_for_tag_counts(options))
        end

        def find_options_for_tag_counts(options = {})
          options.assert_valid_keys :start_at, :end_at, :conditions, :at_least, :at_most, :order, :limit

          scope = scope(:find)
          start_at = sanitize_sql(["#{Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
          end_at = sanitize_sql(["#{Tagging.table_name}.created_at <= ?", options.delete(:end_at)]) if options[:end_at]

          conditions = [
            "#{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)}",
            options[:conditions],
            scope && scope[:conditions],
            start_at,
            end_at
          ]
          
          unless (on = options.delete(:on)).nil?
            conditions << sanitize_sql(["context = ?",on])
          end
          
          conditions = conditions.compact.join(' AND ')

          joins = ["LEFT OUTER JOIN #{Tagging.table_name} ON #{Tag.table_name}.id = #{Tagging.table_name}.tag_id"]
          joins << "LEFT OUTER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{Tagging.table_name}.taggable_id"
          joins << scope[:joins] if scope && scope[:joins]

          at_least  = sanitize_sql(['COUNT(*) >= ?', options.delete(:at_least)]) if options[:at_least]
          at_most   = sanitize_sql(['COUNT(*) <= ?', options.delete(:at_most)]) if options[:at_most]
          having    = [at_least, at_most].compact.join(' AND ')
          group_by  = "#{Tag.table_name}.id, #{Tag.table_name}.name HAVING COUNT(*) > 0"
          group_by << " AND #{having}" unless having.blank?

          { :select     => "#{Tag.table_name}.id, #{Tag.table_name}.name, COUNT(*) AS count", 
            :joins      => joins.join(" "),
            :conditions => conditions,
            :group      => group_by
          }.update(options)
        end                    
      end
    
      module InstanceMethods
        def save_cached_tag_list
          self.class.tag_types.map(&:to_s).each do |tag_type|
            if self.class.send("caching_#{tag_type.singularize}_list?")
              self["cached_#{tag_type.singularize}_list"] = send("#{tag_type.singularize}_list").to_s
            end
          end
        end
        
        def save_tags
          self.class.tag_types.map(&:to_s).each do |tag_type|
            next unless instance_variable_get("@#{tag_type.singularize}_list")
          
            new_tag_names = instance_variable_get("@#{tag_type.singularize}_list") - send(tag_type).map(&:name)
            old_tags = send(tag_type).reject { |tag| instance_variable_get("@#{tag_type.singularize}_list").include?(tag.name) }
          
            self.class.transaction do
              send(tag_type).delete(*old_tags) if old_tags.any?
              new_tag_names.each do |new_tag_name|
                new_tag = Tag.find_or_create_with_like_by_name(new_tag_name)
                Tagging.create(:tag_id => new_tag.id, :context => tag_type, :taggable_type => self.class.to_s, :taggable_id => self.id)
              end
            end
          end
          
          true
        end
        
        def reload_with_tag_list(*args)
          self.class.tag_types.each do |tag_type|
            self.instance_variable_set("@#{tag_type.to_s.singularize}_list", nil)
          end
          
          reload_without_tag_list(*args)
        end
      end
    end
  end
end