module ActsAsTaggableOn::Taggable
  module Core
    def self.included(base)
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
          tag_type = tags_type.to_s.singularize
          context_taggings = "#{tag_type}_taggings".to_sym
          context_tags = tags_type.to_sym
          taggings_order = (preserve_tag_order? ? "#{ActsAsTaggableOn::Tagging.table_name}.id" : [])

          class_eval do
            # when preserving tag order, include order option so that for a 'tags' context
            # the associations tag_taggings & tags are always returned in created order
            has_many context_taggings, -> { includes(:tag).order(taggings_order).where(context: tags_type) },
                     as: :taggable,
                     class_name: ActsAsTaggableOn::Tagging,
                     dependent: :destroy

            has_many context_tags, -> { order(taggings_order) },
                     class_name: ActsAsTaggableOn::Tag,
                     through: context_taggings,
                     source: :tag
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
        object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(', ')
      end

      ##
      # Return a scope of objects that are tagged with the specified tags.
      #
      # @param tags The tags that we want to query for
      # @param [Hash] options A hash of options to alter you query:
      #                       * <tt>:exclude</tt> - if set to true, return objects that are *NOT* tagged with the specified tags
      #                       * <tt>:any</tt> - if set to true, return objects that are tagged with *ANY* of the specified tags
      #                       * <tt>:order_by_matching_tag_count</tt> - if set to true and used with :any, sort by objects matching the most tags, descending
      #                       * <tt>:match_all</tt> - if set to true, return objects that are *ONLY* tagged with the specified tags
      #                       * <tt>:owned_by</tt> - return objects that are *ONLY* owned by the owner
      #                       * <tt>:start_at</tt> - Restrict the tags to those created after a certain time
      #                       * <tt>:end_at</tt> - Restrict the tags to those created before a certain time
      #
      # Example:
      #   User.tagged_with(["awesome", "cool"])                     # Users that are tagged with awesome and cool
      #   User.tagged_with(["awesome", "cool"], :exclude => true)   # Users that are not tagged with awesome or cool
      #   User.tagged_with(["awesome", "cool"], :any => true)       # Users that are tagged with awesome or cool
      #   User.tagged_with(["awesome", "cool"], :any => true, :order_by_matching_tag_count => true)  # Sort by users who match the most tags, descending
      #   User.tagged_with(["awesome", "cool"], :match_all => true) # Users that are tagged with just awesome and cool
      #   User.tagged_with(["awesome", "cool"], :owned_by => foo ) # Users that are tagged with just awesome and cool by 'foo'
      #   User.tagged_with(["awesome", "cool"], :owned_by => foo, :start_at => Date.today ) # Users that are tagged with just awesome, cool by 'foo' and starting today
      def tagged_with(tags, options = {})
        tag_list = ActsAsTaggableOn.default_parser.new(tags).parse
        options = options.dup
        empty_result = where('1 = 0')

        return empty_result if tag_list.empty?

        joins = []
        conditions = []
        having = []
        select_clause = []
        order_by = []

        context = options.delete(:on)
        owned_by = options.delete(:owned_by)
        alias_base_name = undecorated_table_name.gsub('.', '_')
        # FIXME use ActiveRecord's connection quote_column_name
        quote = ActsAsTaggableOn::Utils.using_postgresql? ? '"' : ''

        if options.delete(:exclude)
          if options.delete(:wild)
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{ActsAsTaggableOn::Utils.like_operator} ? ESCAPE '!'", "%#{ActsAsTaggableOn::Utils.escape_like(t)}%"]) }.join(' OR ')
          else
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{ActsAsTaggableOn::Utils.like_operator} ?", t]) }.join(' OR ')
          end

          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableOn::Tagging.table_name} JOIN #{ActsAsTaggableOn::Tag.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key} AND (#{tags_conditions}) WHERE #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name, nil)})"

          if owned_by
            joins <<  "JOIN #{ActsAsTaggableOn::Tagging.table_name}" +
                      "  ON #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name, nil)}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id = #{quote_value(owned_by.id, nil)}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_type = #{quote_value(owned_by.class.base_class.to_s, nil)}"

            joins << " AND " + sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
            joins << " AND " + sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at <= ?", options.delete(:end_at)])   if options[:end_at]
          end

        elsif any = options.delete(:any)
          # get tags, drop out if nothing returned (we need at least one)
          tags = if options.delete(:wild)
                   ActsAsTaggableOn::Tag.named_like_any(tag_list)
                 else
                   ActsAsTaggableOn::Tag.named_any(tag_list)
                 end

          return empty_result if tags.length == 0

          # setup taggings alias so we can chain, ex: items_locations_taggings_awesome_cool_123
          # avoid ambiguous column name
          taggings_context = context ? "_#{context}" : ''

          taggings_alias = adjust_taggings_alias(
              "#{alias_base_name[0..4]}#{taggings_context[0..6]}_taggings_#{ActsAsTaggableOn::Utils.sha_prefix(tags.map(&:name).join('_'))}"
          )

          tagging_cond = "#{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                          " WHERE #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                          " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}"

          tagging_cond << " AND " + sanitize_sql(["#{taggings_alias}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
          tagging_cond << " AND " + sanitize_sql(["#{taggings_alias}.created_at <= ?", options.delete(:end_at)])   if options[:end_at]

          tagging_cond << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

          # don't need to sanitize sql, map all ids and join with OR logic
          tag_ids = tags.map { |t| quote_value(t.id, nil) }.join(', ')
          tagging_cond << " AND #{taggings_alias}.tag_id in (#{tag_ids})"
          select_clause << " #{table_name}.*" unless context and tag_types.one?

          if owned_by
            tagging_cond << ' AND ' +
                sanitize_sql([
                                 "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                                 owned_by.id,
                                 owned_by.class.base_class.to_s
                             ])
          end

          conditions << "EXISTS (SELECT 1 FROM #{tagging_cond})"
          if options.delete(:order_by_matching_tag_count)
            order_by << "(SELECT count(*) FROM #{tagging_cond}) desc"
          end
        else
          tags = ActsAsTaggableOn::Tag.named_any(tag_list)

          return empty_result unless tags.length == tag_list.length

          tags.each do |tag|
            taggings_alias = adjust_taggings_alias("#{alias_base_name[0..11]}_taggings_#{ActsAsTaggableOn::Utils.sha_prefix(tag.name)}")
            tagging_join = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" \
                "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}" +
                " AND #{taggings_alias}.tag_id = #{quote_value(tag.id, nil)}"

            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.created_at <= ?", options.delete(:end_at)])   if options[:end_at]

            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

            if owned_by
              tagging_join << ' AND ' +
                  sanitize_sql([
                                   "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                                   owned_by.id,
                                   owned_by.class.base_class.to_s
                               ])
            end

            joins << tagging_join
          end
        end

        group ||= [] # Rails interprets this as a no-op in the group() call below
        if options.delete(:order_by_matching_tag_count)
          select_clause << "#{table_name}.*, COUNT(#{taggings_alias}.tag_id) AS #{taggings_alias}_count"
          group_columns = ActsAsTaggableOn::Utils.using_postgresql? ? grouped_column_names_for(self) : "#{table_name}.#{primary_key}"
          group = group_columns
          order_by << "#{taggings_alias}_count DESC"

        elsif options.delete(:match_all)
          taggings_alias, _ = adjust_taggings_alias("#{alias_base_name}_taggings_group"), "#{alias_base_name}_tags_group"
          joins << "LEFT OUTER JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" \
              "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" \
              " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}"

          joins << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context
          joins << " AND " + sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at >= ?", options.delete(:start_at)]) if options[:start_at]
          joins << " AND " + sanitize_sql(["#{ActsAsTaggableOn::Tagging.table_name}.created_at <= ?", options.delete(:end_at)])   if options[:end_at]

          group_columns = ActsAsTaggableOn::Utils.using_postgresql? ? grouped_column_names_for(self) : "#{table_name}.#{primary_key}"
          group = group_columns
          having = "COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end

        order_by << options[:order] if options[:order].present?

        query = self
        query = self.select(select_clause.join(',')) unless select_clause.empty?
        query.joins(joins.join(' '))
          .where(conditions.join(' AND '))
          .group(group)
          .having(having)
          .order(order_by.join(', '))
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

      private

      # Rails 5 has merged sanitize and quote_value
      # See https://github.com/rails/rails/blob/master/activerecord/lib/active_record/sanitization.rb#L10
      def quote_value(value, column = nil)
        ActsAsTaggableOn::Utils.active_record5? ? super(value) : super(value, column)
      end
    end

    # all column names are necessary for PostgreSQL group clause
    def grouped_column_names_for(object)
      self.class.grouped_column_names_for(object)
    end

    def custom_contexts
      @custom_contexts ||= taggings.map(&:context).uniq
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
      instance_variable_defined?(variable_name) && instance_variable_get(variable_name)
    end

    def tag_list_cache_on(context)
      variable_name = "@#{context.to_s.singularize}_list"
      if instance_variable_get(variable_name)
        instance_variable_get(variable_name)
      elsif cached_tag_list_on(context) && self.class.caching_tag_list_on?(context)
        instance_variable_set(variable_name, ActsAsTaggableOn.default_parser.new(cached_tag_list_on(context)).parse)
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
      tagging_table_name = ActsAsTaggableOn::Tagging.table_name

      opts = ["#{tagging_table_name}.context = ?", context.to_s]
      scope = base_tags.where(opts)

      if ActsAsTaggableOn::Utils.using_postgresql?
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

      instance_variable_set(variable_name, ActsAsTaggableOn.default_parser.new(new_list).parse)
    end

    def tagging_contexts
      self.class.tag_types.map(&:to_s) + custom_contexts
    end

    def process_dirty_object(context, new_list)
      value = new_list.is_a?(Array) ? ActsAsTaggableOn::TagList.new(new_list) : new_list
      attrib = "#{context.to_s.singularize}_list"

      if changed_attributes.include?(attrib)
        # The attribute already has an unsaved change.
        old = changed_attributes[attrib]
        @changed_attributes.delete(attrib) if old.to_s == value.to_s
      else
        old = tag_list_on(context)
        if self.class.preserve_tag_order
          @changed_attributes[attrib] = old if old.to_s != value.to_s
        else
          @changed_attributes[attrib] = old.to_s if old.sort != ActsAsTaggableOn.default_parser.new(value).parse.sort
        end
      end
    end

    def reload(*args)
      self.class.tag_types.each do |context|
        instance_variable_set("@#{context.to_s.singularize}_list", nil)
        instance_variable_set("@all_#{context.to_s.singularize}_list", nil)
      end

      super(*args)
    end

    ##
    # Find existing tags or create non-existing tags
    def load_tags(tag_list)
      ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list)
    end

    def save_tags
      tagging_contexts.each do |context|
        next unless tag_list_cache_set_on(context)
        # List of currently assigned tag names
        tag_list = tag_list_cache_on(context).uniq

        # Find existing tags or create non-existing tags:
        tags = find_or_create_tags_from_list_with_context(tag_list, context)

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

        # Destroy old taggings:
        if old_tags.present?
          taggings.not_owned.by_context(context).where(tag_id: old_tags).destroy_all
        end

        # Create new taggings:
        new_tags.each do |tag|
          taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self)
        end
      end

      true
    end

    private

    # Filters the tag lists from the attribute names.
    def attributes_for_update(attribute_names)
      tag_lists = tag_types.map {|tags_type| "#{tags_type.to_s.singularize}_list"}
      super.delete_if {|attr| tag_lists.include? attr }
    end

    # Filters the tag lists from the attribute names.
    def attributes_for_create(attribute_names)
      tag_lists = tag_types.map {|tags_type| "#{tags_type.to_s.singularize}_list"}
      super.delete_if {|attr| tag_lists.include? attr }
    end

    ##
    # Override this hook if you wish to subclass {ActsAsTaggableOn::Tag} --
    # context is provided so that you may conditionally use a Tag subclass
    # only for some contexts.
    #
    # @example Custom Tag class for one context
    #   class Company < ActiveRecord::Base
    #     acts_as_taggable_on :markets, :locations
    #
    #     def find_or_create_tags_from_list_with_context(tag_list, context)
    #       if context.to_sym == :markets
    #         MarketTag.find_or_create_all_with_like_by_name(tag_list)
    #       else
    #         super
    #       end
    #     end
    #
    # @param [Array<String>] tag_list Tags to find or create
    # @param [Symbol] context The tag context for the tag_list
    def find_or_create_tags_from_list_with_context(tag_list, _context)
      load_tags(tag_list)
    end
  end
end
