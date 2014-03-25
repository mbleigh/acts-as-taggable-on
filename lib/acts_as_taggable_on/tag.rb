# coding: utf-8
module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    extend ActsAsTaggableOn::Utils

    attr_accessible :name if defined?(ActiveModel::MassAssignmentSecurity)

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :if => :validates_name_uniqueness?
    validates_length_of :name, :maximum => 255

    # monkey patch this method if don't need name uniqueness validation
    def validates_name_uniqueness?
      true
    end

    ### SCOPES:

    def self.named(name)
      if ActsAsTaggableOn.strict_case_match
        where(["name = #{binary}?", as_8bit_ascii(name)])
      else
        where(["LOWER(name) = LOWER(?)", as_8bit_ascii(unicode_downcase(name))])
      end
    end

    def self.named_any(list)
      if ActsAsTaggableOn.strict_case_match
        clause = list.map { |tag|
          sanitize_sql(["name = #{binary}?", as_8bit_ascii(tag)])
        }.join(" OR ")
        where(clause)
      else
        clause = list.map { |tag|
          sanitize_sql(["LOWER(name) = LOWER(?)", as_8bit_ascii(unicode_downcase(tag))])
        }.join(" OR ")
        where(clause)
      end
    end

    def self.named_like(name)
      clause = ["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(name)}%"]
      where(clause)
    end

    def self.named_like_any(list)
      clause = list.map { |tag|
        sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"])
      }.join(" OR ")
      where(clause)
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      if (ActsAsTaggableOn.strict_case_match)
        self.find_or_create_all_with_like_by_name([name]).first
      else
        named_like(name).first || create(:name => name)
      end
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = Array(list).flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list)

      list.map do |tag_name|
        comparable_tag_name = comparable_name(tag_name)
        existing_tag = existing_tags.detect { |tag| comparable_name(tag.name) == comparable_tag_name }
        begin
          existing_tag || Tag.create(:name => tag_name)
        rescue ActiveRecord::RecordNotUnique
          # Postgres aborts the current transaction with
          # PG::InFailedSqlTransaction: ERROR:  current transaction is aborted, commands ignored until end of transaction block
          # so we have to rollback this transaction
          raise DuplicateTagError.new("'#{tag_name}' has already been taken")
        end
      end
    end

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
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
        using_mysql? ? "BINARY " : nil
      end

      def unicode_downcase(string)
        if ActiveSupport::Multibyte::Unicode.respond_to?(:downcase)
          ActiveSupport::Multibyte::Unicode.downcase(string)
        else
          ActiveSupport::Multibyte::Chars.new(string).downcase.to_s
        end
      end

      def as_8bit_ascii(string)
        if defined?(Encoding)
          string.to_s.dup.force_encoding('BINARY')
        else
          string.to_s.mb_chars
        end
      end
    end
  end
end
