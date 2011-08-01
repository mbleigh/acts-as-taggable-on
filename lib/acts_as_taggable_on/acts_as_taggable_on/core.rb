module ActsAsTaggableOn::Taggable
  module Core    
    def self.included(base)
      base.send :include, ActsAsTaggableOn::Taggable::Core::InstanceMethods
      base.extend ActsAsTaggableOn::Taggable::Core::ClassMethods

      base.class_eval do
        attr_writer :custom_contexts
        after_save :save_tags
      end
      
      base.initialize_acts_as_taggable_on_core
    end
    
    module ClassMethods
      def initialize_acts_as_taggable_on_core
        tag_types.map(&:to_s).each do |tags_type|
          tag_type         = tags_type.to_s.singularize
          context_taggings = "#{tag_type}_taggings".to_sym
          context_tags     = tags_type.to_sym

          class_eval do
            has_many context_taggings, :as => :taggable, :dependent => :destroy, :include => :tag, :class_name => "ActsAsTaggableOn::Tagging",
            :conditions => ["#{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id AND #{ActsAsTaggableOn::Tagging.table_name}.context = ?", tags_type]
            has_many context_tags, :through => context_taggings, :source => :tag, :class_name => "ActsAsTaggableOn::Tag"
          end

          class_eval %(
            def #{tag_type}_list
              tag_list_on('#{tags_type}')
            end

            def #{tag_type}_list=(new_tags)
              set_tag_list_on('#{tags_type}', new_tags)
            end

            def all_#{tags_type}_list
              all_tags_list_on('#{tags_type}')
            end
          )
        end        
      end
      
      def acts_as_taggable_on(*args)
        super(*args)
        initialize_acts_as_taggable_on_core
      end
      
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(", ")
      end

      ##
      # Return a scope of objects that are tagged with the specified tags.
      #
      # @param tags The tags that we want to query for
      # @param [Hash] options A hash of options to alter you query:
      #                       * <tt>:exclude</tt> - if set to true, return objects that are *NOT* tagged with the specified tags
      #                       * <tt>:any</tt> - if set to true, return objects that are tagged with *ANY* of the specified tags
      #                       * <tt>:match_all</tt> - if set to true, return objects that are *ONLY* tagged with the specified tags
      #
      # Example:
      #   User.tagged_with("awesome", "cool")                     # Users that are tagged with awesome and cool
      #   User.tagged_with("awesome", "cool", :exclude => true)   # Users that are not tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :any => true)       # Users that are tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :match_all => true) # Users that are tagged with just awesome and cool
      def tagged_with(tags, options = {})
        tag_list = ActsAsTaggableOn::TagList.from(tags)
        empty_result = scoped(:conditions => "1 = 0")

        return empty_result if tag_list.empty?

        joins = []
        conditions = []

        context = options.delete(:on)
        alias_base_name = undecorated_table_name.gsub('.','_')

        if options.delete(:exclude)
          tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{like_operator} ?", t]) }.join(" OR ")
          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableOn::Tagging.table_name} JOIN #{ActsAsTaggableOn::Tag.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.id AND (#{tags_conditions}) WHERE #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

        elsif options.delete(:any)
          # get tags, drop out if nothing returned (we need at least one)
          tags = ActsAsTaggableOn::Tag.named_any(tag_list)
          return scoped(:conditions => "1 = 0") unless tags.length > 0

          # setup taggings alias so we can chain, ex: items_locations_taggings_awesome_cool_123
          # avoid ambiguous column name
          taggings_context = context ? "_#{context}" : ''
          
          #TODO: fix alias to be smaller
          taggings_alias   = "#{alias_base_name}#{taggings_context}_taggings_#{tags.map(&:safe_name).join('_')}_#{rand(1024)}"

          tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                          "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                          " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"
          tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

          # don't need to sanitize sql, map all ids and join with OR logic
          conditions << tags.map { |t| "#{taggings_alias}.tag_id = #{t.id}" }.join(" OR ")
          select_clause = "DISTINCT #{table_name}.*" unless context and tag_types.one?

          joins << tagging_join

        else
          tags = ActsAsTaggableOn::Tag.named_any(tag_list)
          return empty_result unless tags.length == tag_list.length

          tags.each do |tag|
            prefix   = "#{tag.safe_name}_#{rand(1024)}"

            taggings_alias = "#{alias_base_name}_taggings_#{prefix}"

            tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                            "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                            " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}" +
                            " AND #{taggings_alias}.tag_id = #{tag.id}"
            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

            joins << tagging_join
          end
        end

        taggings_alias, tags_alias = "#{alias_base_name}_taggings_group", "#{alias_base_name}_tags_group"

        if options.delete(:match_all)
          joins << "LEFT OUTER JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                   "  ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key}" +
                   " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"


          group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(self) : "#{table_name}.#{primary_key}"
          group = "#{group_columns} HAVING COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end

        scoped(:select     => select_clause,
               :joins      => joins.join(" "),
               :group      => group,
               :conditions => conditions.join(" AND "),
               :order      => options[:order],
               :readonly   => false)
      end

      def is_taggable?
        true
      end
    end    
    
    module InstanceMethods
      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        self.class.grouped_column_names_for(object)
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

      def cached_tag_list_on(context)
        self["cached_#{context.to_s.singularize}_list"]
      end

      def tag_list_cache_set_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        !instance_variable_get(variable_name).nil?
      end

      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        instance_variable_get(variable_name) || instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(tags_on(context).map(&:name)))
      end

      def tag_list_on(context)
        add_custom_context(context)
        tag_list_cache_on(context)
      end

      def all_tags_list_on(context)
        variable_name = "@all_#{context.to_s.singularize}_list"
        return instance_variable_get(variable_name) if instance_variable_get(variable_name)

        instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(all_tags_on(context).map(&:name)).freeze)
      end

      ##
      # Returns all tags of a given context
      def all_tags_on(context)
        tag_table_name = ActsAsTaggableOn::Tag.table_name
        tagging_table_name = ActsAsTaggableOn::Tagging.table_name

        opts  =  ["#{tagging_table_name}.context = ?", context.to_s]
        scope = base_tags.where(opts)
        
        if ActsAsTaggableOn::Tag.using_postgresql?
          group_columns = grouped_column_names_for(ActsAsTaggableOn::Tag)
          scope = scope.order("max(#{tagging_table_name}.created_at)").group(group_columns)
        else
          scope = scope.group("#{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key}")
        end

        scope.all
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(context)
        base_tags.where(["#{ActsAsTaggableOn::Tagging.table_name}.context = ? AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id IS NULL", context.to_s]).all
      end

      def set_tag_list_on(context, new_list)
        add_custom_context(context)

        variable_name = "@#{context.to_s.singularize}_list"
        instance_variable_set(variable_name, ActsAsTaggableOn::TagList.from(new_list))
      end

      def tagging_contexts
        custom_contexts + self.class.tag_types.map(&:to_s)
      end

      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@#{context.to_s.singularize}_list", nil)
          instance_variable_set("@all_#{context.to_s.singularize}_list", nil)
        end
      
        super(*args)
      end

      def save_tags
        tagging_contexts.each do |context|
          next unless tag_list_cache_set_on(context)

          tag_list = tag_list_cache_on(context).uniq

          # Find existing tags or create non-existing tags:
          tag_list = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list)

          current_tags = tags_on(context)
          old_tags     = current_tags - tag_list
          new_tags     = tag_list     - current_tags
          
          # Find taggings to remove:
          old_taggings = taggings.where(:tagger_type => nil, :tagger_id => nil,
                                        :context => context.to_s, :tag_id => old_tags).all

          if old_taggings.present?
            # Destroy old taggings:
            ActsAsTaggableOn::Tagging.destroy_all :id => old_taggings.map(&:id)
          end

          # Create new taggings:
          new_tags.each do |tag|
            taggings.create!(:tag_id => tag.id, :context => context.to_s, :taggable => self)
          end
        end

        true
      end
    end
  end
end
