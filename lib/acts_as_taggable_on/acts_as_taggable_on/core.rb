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
        include taggable_mixin
        tag_types.map(&:to_s).each do |tags_type|
          tag_type         = tags_type.to_s.singularize
          context_taggings = "#{tag_type}_taggings".to_sym
          context_tags     = tags_type.to_sym
          taggings_order   = (preserve_tag_order? ? "#{ActsAsTaggableOn::Tagging.table_name}.id" : [])

          class_eval do
            # when preserving tag order, include order option so that for a 'tags' context
            # the associations tag_taggings & tags are always returned in created order
            has_many_with_compatibility context_taggings, :as => :taggable,
                                        :dependent => :destroy,
                                        :class_name => "ActsAsTaggableOn::Tagging",
                                        :order => taggings_order,
                                        :conditions => ["#{ActsAsTaggableOn::Tagging.table_name}.context = (?)", tags_type],
                                        :include => :tag

            has_many_with_compatibility context_tags, :through => context_taggings,
                                        :source => :tag,
                                        :class_name => "ActsAsTaggableOn::Tag",
                                        :order => taggings_order

          end

          taggable_mixin.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{tag_type}_list
              tag_list_on('#{tags_type}')
            end

            def #{tag_type}_list=(new_tags)
              set_tag_list_on('#{tags_type}', new_tags)
            end

            def all_#{tags_type}_list
              all_tags_list_on('#{tags_type}')
            end
          RUBY
        end
      end

      def taggable_on(preserve_tag_order, *tag_types)
        super(preserve_tag_order, *tag_types)
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
      #                       * <tt>:owned_by</tt> - return objects that are *ONLY* owned by the owner
      #
      # Example:
      #   User.tagged_with("awesome", "cool")                     # Users that are tagged with awesome and cool
      #   User.tagged_with("awesome", "cool", :exclude => true)   # Users that are not tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :any => true)       # Users that are tagged with awesome or cool
      #   User.tagged_with("awesome", "cool", :match_all => true) # Users that are tagged with just awesome and cool
      #   User.tagged_with("awesome", "cool", :owned_by => foo ) # Users that are tagged with just awesome and cool by 'foo'
      def tagged_with(tags, options = {})
        tag_list = ActsAsTaggableOn::TagList.from(tags)
        empty_result = where("1 = 0")

        return empty_result if tag_list.empty?

        joins = []
        conditions = []
        having = []
        select_clause = []

        context = options.delete(:on)
        owned_by = options.delete(:owned_by)
        alias_base_name = undecorated_table_name.gsub('.','_')
        quote = ActsAsTaggableOn::Tag.using_postgresql? ? '"' : ''

        if options.delete(:exclude)
          if options.delete(:wild)
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{like_operator} ? ESCAPE '!'", "%#{escape_like(t)}%"]) }.join(" OR ")
          else
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{like_operator} ?", t]) }.join(" OR ")
          end

          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableOn::Tagging.table_name} JOIN #{ActsAsTaggableOn::Tag.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key} AND (#{tags_conditions}) WHERE #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name)})"

          if owned_by
            joins <<  "JOIN #{ActsAsTaggableOn::Tagging.table_name}" +
                      "  ON #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name)}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id = #{owned_by.id}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_type = #{quote_value(owned_by.class.base_class.to_s)}"
          end

        elsif options.delete(:any)
          # get tags, drop out if nothing returned (we need at least one)
          tags = if options.delete(:wild)
            ActsAsTaggableOn::Tag.named_like_any(tag_list)
          else
            ActsAsTaggableOn::Tag.named_any(tag_list)
          end

          return empty_result unless tags.length > 0

          # setup taggings alias so we can chain, ex: items_locations_taggings_awesome_cool_123
          # avoid ambiguous column name
          taggings_context = context ? "_#{context}" : ''

          taggings_alias   = adjust_taggings_alias(
            "#{alias_base_name[0..4]}#{taggings_context[0..6]}_taggings_#{sha_prefix(tags.map(&:name).join('_'))}"
          )

          tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                          "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                          " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"
          tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

          # don't need to sanitize sql, map all ids and join with OR logic
          conditions << tags.map { |t| "#{taggings_alias}.tag_id = #{t.id}" }.join(" OR ")
          select_clause = "DISTINCT #{table_name}.*" unless context and tag_types.one?

          if owned_by
              tagging_join << " AND " +
                  sanitize_sql([
                      "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                      owned_by.id,
                      owned_by.class.base_class.to_s
                  ])
          end

          joins << tagging_join
        else
          tags = ActsAsTaggableOn::Tag.named_any(tag_list)

          return empty_result unless tags.length == tag_list.length

          tags.each do |tag|
            taggings_alias = adjust_taggings_alias("#{alias_base_name[0..11]}_taggings_#{sha_prefix(tag.name)}")
            tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                            "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                            " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}" +
                            " AND #{taggings_alias}.tag_id = #{tag.id}"

            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

            if owned_by
                tagging_join << " AND " +
                  sanitize_sql([
                    "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                    owned_by.id,
                    owned_by.class.base_class.to_s
                  ])
            end

            joins << tagging_join
          end
        end

        taggings_alias, tags_alias = adjust_taggings_alias("#{alias_base_name}_taggings_group"), "#{alias_base_name}_tags_group"

        if options.delete(:match_all)
          joins << "LEFT OUTER JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                   "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                   " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name)}"


          group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(self) : "#{table_name}.#{primary_key}"
          group = group_columns
          having = "COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end

        select(select_clause) \
          .joins(joins.join(" ")) \
          .where(conditions.join(" AND ")) \
          .group(group) \
          .having(having) \
          .order(options[:order]) \
          .readonly(false)
      end

      def is_taggable?
        true
      end

      def adjust_taggings_alias(taggings_alias)
        if taggings_alias.size > 75
          taggings_alias = 'taggings_alias_' + Digest::SHA1.hexdigest(taggings_alias)
        end
        taggings_alias
      end

      def taggable_mixin
        @taggable_mixin ||= Module.new
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
        instance_variable_defined?(variable_name) && !instance_variable_get(variable_name).nil?
      end

      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        if instance_variable_get(variable_name)
          instance_variable_get(variable_name)
        elsif cached_tag_list_on(context) && self.class.caching_tag_list_on?(context)
          instance_variable_set(variable_name, ActsAsTaggableOn::TagList.from(cached_tag_list_on(context)))
        else
          instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(tags_on(context).map(&:name)))
        end
      end

      def tag_list_on(context)
        add_custom_context(context)
        tag_list_cache_on(context)
      end

      def all_tags_list_on(context)
        variable_name = "@all_#{context.to_s.singularize}_list"
        return instance_variable_get(variable_name) if instance_variable_defined?(variable_name) && instance_variable_get(variable_name)

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
          scope.order("max(#{tagging_table_name}.created_at)").group(group_columns)
        else
          scope.group("#{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key}")
        end.to_a
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(context)
        scope = base_tags.where(["#{ActsAsTaggableOn::Tagging.table_name}.context = ? AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id IS NULL", context.to_s])
        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order("#{ActsAsTaggableOn::Tagging.table_name}.id") if self.class.preserve_tag_order?
        scope
      end

      def set_tag_list_on(context, new_list)
        add_custom_context(context)

        variable_name = "@#{context.to_s.singularize}_list"
        process_dirty_object(context, new_list) unless custom_contexts.include?(context.to_s)

        instance_variable_set(variable_name, ActsAsTaggableOn::TagList.from(new_list))
      end

      def tagging_contexts
        custom_contexts + self.class.tag_types.map(&:to_s)
      end

      def process_dirty_object(context,new_list)
        value = new_list.is_a?(Array) ? new_list.join(', ') : new_list
        attrib = "#{context.to_s.singularize}_list"

        if changed_attributes.include?(attrib)
          # The attribute already has an unsaved change.
          old = changed_attributes[attrib]
          changed_attributes.delete(attrib) if (old.to_s == value.to_s)
        else
          old = tag_list_on(context).to_s
          changed_attributes[attrib] = old if (old.to_s != value.to_s)
        end
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
          # List of currently assigned tag names
          tag_list = tag_list_cache_on(context).uniq

          # Find existing tags or create non-existing tags:
          tags = ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list)

          # Tag objects for currently assigned tags
          current_tags = tags_on(context)

          # Tag maintenance based on whether preserving the created order of tags
          if self.class.preserve_tag_order?
            old_tags, new_tags = current_tags - tags, tags - current_tags

            shared_tags = current_tags & tags

            if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
              index = shared_tags.each_with_index { |_, i| break i unless shared_tags[i] == tags[i] }

              # Update arrays of tag objects
              old_tags |= current_tags[index...current_tags.size]
              new_tags |= current_tags[index...current_tags.size] & shared_tags

              # Order the array of tag objects to match the tag list
              new_tags = tags.map do |t| 
                new_tags.find { |n| n.name.downcase == t.name.downcase }
              end.compact
            end
          else
            # Delete discarded tags and create new tags
            old_tags = current_tags - tags
            new_tags = tags - current_tags
          end

          # Find taggings to remove:
          if old_tags.present?
            old_taggings = taggings.where(:tagger_type => nil, :tagger_id => nil, :context => context.to_s, :tag_id => old_tags)
          end

          # Destroy old taggings:
          if old_taggings.present?
            ActsAsTaggableOn::Tagging.destroy_all "#{ActsAsTaggableOn::Tagging.primary_key}".to_sym => old_taggings.map(&:id)
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
