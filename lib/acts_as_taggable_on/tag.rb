# frozen_string_literal: true

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    self.table_name = ActsAsTaggableOn.tags_table

    ### ASSOCIATIONS:

    has_many :taggings, dependent: :destroy, class_name: '::ActsAsTaggableOn::Tagging'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_length_of :name, maximum: 255

    validate :name_is_unique

    # monkey patch this method if don't need name uniqueness validation
    def validates_name_uniqueness?
      true
    end

    ### SCOPES:
    scope :most_used, ->(limit = 20) { order('taggings_count desc').limit(limit) }
    scope :least_used, ->(limit = 20) { order('taggings_count asc').limit(limit) }

    def self.named(name)
      if ActsAsTaggableOn.strict_case_match
        where(["name = #{binary}?", as_8bit_ascii(name)])
      else
        where(['LOWER(name) = LOWER(?)', as_8bit_ascii(unicode_downcase(name))])
      end
    end

    def self.named_any(list)
      clause = list.map do |tag|
        sanitize_sql_for_named_any(tag).force_encoding('BINARY')
      end.join(' OR ')
      where(clause)
    end

    def self.named_like(name)
      clause = ["name #{ActsAsTaggableOn::Utils.like_operator} ? ESCAPE '!'",
                "%#{ActsAsTaggableOn::Utils.escape_like(name)}%"]
      where(clause)
    end

    def self.named_like_any(list)
      clause = list.map do |tag|
        sanitize_sql(["name #{ActsAsTaggableOn::Utils.like_operator} ? ESCAPE '!'",
                      "%#{ActsAsTaggableOn::Utils.escape_like(tag.to_s)}%"])
      end.join(' OR ')
      where(clause)
    end

    def self.for_context(context)
      joins(:taggings)
        .where(["#{ActsAsTaggableOn.taggings_table}.context = ?", context])
        .select("DISTINCT #{ActsAsTaggableOn.tags_table}.*")
    end

    def self.for_tenant(tenant)
      joins(:taggings)
        .where("#{ActsAsTaggableOn.taggings_table}.tenant = ?", tenant.to_s)
        .select("DISTINCT #{ActsAsTaggableOn.tags_table}.*")
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      if ActsAsTaggableOn.strict_case_match
        find_or_create_all_with_like_by_name([name]).first
      else
        named_like(name).first || create(name: name)
      end
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = Array(list).flatten

      return [] if list.empty?

      existing_tags = named_any(list)
      list.map do |tag_name|
        tries ||= 3
        comparable_tag_name = comparable_name(tag_name)
        existing_tag = existing_tags.find { |tag| comparable_name(tag.name) == comparable_tag_name }
        existing_tag || create(name: tag_name)
      rescue ActiveRecord::RecordNotUnique
        if (tries -= 1).positive?
          ActiveRecord::Base.connection.execute 'ROLLBACK'
          existing_tags = named_any(list)
          retry
        end

        raise DuplicateTagError, "'#{tag_name}' has already been taken"
      end
    end

    ### INSTANCE METHODS:

    def ==(other)
      super || (other.is_a?(Tag) && name == other.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

    private

    def name_is_unique
      return unless self.class.named(name).exists?

      type_of_comparison = ActsAsTaggableOn.strict_case_match ? 'case-sensitive' : 'case-insensitive'
      errors.add(:name, :not_unique, type_of_comparison: type_of_comparison)
    end

    class << self
      private

      def comparable_name(str)
        if ActsAsTaggableOn.strict_case_match
          str
        else
          unicode_downcase(str.to_s)
        end
      end

      def binary
        ActsAsTaggableOn::Utils.using_mysql? ? 'BINARY ' : nil
      end

      def as_8bit_ascii(string)
        string.to_s.mb_chars
      end

      def unicode_downcase(string)
        as_8bit_ascii(string).downcase
      end

      def sanitize_sql_for_named_any(tag)
        if ActsAsTaggableOn.strict_case_match
          sanitize_sql(["name = #{binary}?", as_8bit_ascii(tag)])
        else
          sanitize_sql(['LOWER(name) = LOWER(?)', as_8bit_ascii(unicode_downcase(tag))])
        end
      end
    end
  end
end
