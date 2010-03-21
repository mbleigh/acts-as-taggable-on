module ActsAsTaggableOn::Taggable
  module Core
    def self.included(base)
      base.class_eval do
        attr_writer :custom_contexts

        after_save :save_tags

        def self.tagged_with(*args)
          find_options_for_find_tagged_with(*args)
        end
      end
      
      if ActiveRecord::VERSION::MAJOR < 3
        base.send :include, ActsAsTaggableOn::ActiveRecord::Backports
      end 
      
      base.tag_types.map(&:to_s).each do |tag_type|
        context_taggings = "#{tag_type.singularize}_taggings".to_sym
        context_tags     = tag_type.to_sym
        
        base.class_eval do
          has_many context_taggings, :as => :taggable, :dependent => :destroy, :include => :tag,
                   :conditions => ['#{Tagging.table_name}.context = ?', tag_type], :class_name => "Tagging"
          has_many context_tags, :through => context_taggings, :source => :tag
        end
        
        base.class_eval %(
          def self.#{tag_type.singularize}_counts(options={})
            tag_counts_on('#{tag_type}',options)
          end

          def #{tag_type.singularize}_list
            tag_list_on('#{tag_type}')
          end

          def #{tag_type.singularize}_list=(new_tags)
            set_tag_list_on('#{tag_type}',new_tags)
          end

          def #{tag_type.singularize}_counts(options = {})
            tag_counts_on('#{tag_type}',options)
          end

          def #{tag_type}_from(owner)
            tag_list_on('#{tag_type}', owner)
          end

          def top_#{tag_type}(limit = 10)
            tag_counts_on('#{tag_type}', :order => 'count desc', :limit => limit.to_i)
          end

          def self.top_#{tag_type}(limit = 10)
            tag_counts_on('#{tag_type}', :order => 'count desc', :limit => limit.to_i)
          end
        )
      end
      
      base.extend ClassMethods
      include InstanceMethods
    end
    
    module ClassMethods
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(", ")
      end

      def tag_counts_on(context, options = {})
        find_for_tag_counts(options.merge({:on => context.to_s}))
      end

      def all_tag_counts(options = {})
        find_for_tag_counts(options)
      end

      def find_options_for_find_tagged_with(tags, options = {})
        tag_list = TagList.from(tags)

        return {} if tag_list.empty?

        joins = []
        conditions = []

        context = options.delete(:on)

        if options.delete(:exclude)
          tags_conditions = tag_list.map { |t| sanitize_sql(["#{Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name} JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id AND (#{tags_conditions}) WHERE #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

        elsif options.delete(:any)
          tags_conditions = tag_list.map { |t| sanitize_sql(["#{Tag.table_name}.name LIKE ?", t]) }.join(" OR ")
          conditions << "#{table_name}.#{primary_key} IN (SELECT #{Tagging.table_name}.taggable_id FROM #{Tagging.table_name} JOIN #{Tag.table_name} ON #{Tagging.table_name}.tag_id = #{Tag.table_name}.id AND (#{tags_conditions}) WHERE #{Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

        else
          tags = Tag.named_any(tag_list)
          return { :conditions => "1 = 0" } unless tags.length == tag_list.length

          tags.each do |tag|
            safe_tag = tag.name.gsub(/[^a-zA-Z0-9]/, '')
            prefix   = "#{safe_tag}_#{rand(1024)}"

            taggings_alias = "#{table_name}_taggings_#{prefix}"

            tagging_join  = "JOIN #{Tagging.table_name} #{taggings_alias}" +
                            "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                            " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}" +
                            " AND #{taggings_alias}.tag_id = #{tag.id}"
            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

            joins << tagging_join
          end
        end

        taggings_alias, tags_alias = "#{table_name}_taggings_group", "#{table_name}_tags_group"

        if options.delete(:match_all)
          joins << "LEFT OUTER JOIN #{Tagging.table_name} #{taggings_alias}" +
                   "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                   " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"

          group = "#{grouped_column_names_for(self)} HAVING COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end

        joins(joins.join(" ")).group(group).where(conditions.join(" AND ")).readonly(false)

        # { :joins      => joins.join(" "),
        #   :group      => group,
        #   :conditions => conditions.join(" AND "),
        #   :readonly   => false }.update(options)
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
      def find_for_tag_counts(options = {})
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

      def is_taggable?
        true
      end

    end    
    
    module InstanceMethods
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(", ")
      end

      def custom_contexts
        @custom_contexts ||= []
      end

      def is_taggable?
        self.class.is_taggable?
      end

      def add_custom_context(value)
        custom_contexts << value.to_s unless custom_contexts.include?(value.to_s) or self.class.tag_types.map(&:to_s).include?(value.to_s)
      end

      def tag_list_on(context, owner = nil)
        add_custom_context(context)
        cache = tag_list_cache_on(context)
        return owner ? cache[owner] : cache[owner] if cache[owner]

        if !owner && self.class.caching_tag_list_on?(context) and !(cached_value = cached_tag_list_on(context)).nil?
          cache[owner] = TagList.from(cached_tag_list_on(context))
        else
          cache[owner] = TagList.new(*tags_on(context, owner).map(&:name))
        end
      end

      def all_tags_list_on(context)
        variable_name = "@all_#{context.to_s.singularize}_list"
        return instance_variable_get(variable_name) if instance_variable_get(variable_name)
        instance_variable_set(variable_name, TagList.new(all_tags_on(context).map(&:name)).freeze)
      end

      def all_tags_on(context)
        opts =  ["#{Tagging.table_name}.context = ?", context.to_s]
        base_tags.where(opts).order("#{Tagging.table_name}.created_at")
      end

      def tags_on(context, owner = nil)
        if owner
          opts = ["#{Tagging.table_name}.context = ? AND #{Tagging.table_name}.tagger_id = ? AND #{Tagging.table_name}.tagger_type = ?", context.to_s, owner.id, owner.class.to_s]
        else
          opts = ["#{Tagging.table_name}.context = ? AND #{Tagging.table_name}.tagger_id IS NULL", context.to_s]
        end
        base_tags.where(opts)
      end


      def set_tag_list_on(context, new_list, tagger = nil)
        tag_list_cache_on(context)[tagger] = TagList.from(new_list)
        add_custom_context(context)
      end

      def tag_counts_on(context, options={})
        self.class.tag_counts_on(context, options.merge(:id => id))
      end

      def save_tags
        contexts = custom_contexts + self.class.tag_types.map(&:to_s)

        transaction do
          contexts.each do |context|
            cache = tag_list_cache_on(context)

            cache.each do |owner, list|
              new_tags = Tag.find_or_create_all_with_like_by_name(list.uniq)
              taggings = Tagging.where({ :taggable_id => self.id, :taggable_type => self.class.base_class.to_s })

              # Destroy old taggings:
              if owner
                old_tags = tags_on(context, owner) - new_tags
                old_taggings = Tagging.where({ :taggable_id => self.id, :taggable_type => self.class.base_class.to_s, :tag_id => old_tags, :tagger_id => owner.id, :tagger_type => owner.class.to_s, :context => context })

                Tagging.destroy_all :id => old_taggings.map(&:id)
              else
                old_tags = tags_on(context) - new_tags
                base_tags.delete(*old_tags)
              end

              new_tags.reject! { |tag| taggings.any? { |tagging|
                  tagging.tag_id      == tag.id &&
                  tagging.tagger_id   == (owner ? owner.id : nil) &&
                  tagging.tagger_type == (owner ? owner.class.to_s : nil) &&
                  tagging.context     == context
                }
              }

              # create new taggings:
              new_tags.each do |tag|
                Tagging.create!(:tag_id => tag.id, :context => context, :tagger => owner, :taggable => self)
              end
            end
          end
        end

        true
      end
    end
  end
end