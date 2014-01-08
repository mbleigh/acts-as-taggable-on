# coding: utf-8
module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::Utils

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
        where(["name = #{binary}?", name])
      else
        where(["lower(name) = ?", name.downcase])
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
          lowercase_ascii_tag = as_8bit_ascii(tag).downcase
          sanitize_sql(["lower(name) = ?", lowercase_ascii_tag])
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

        existing_tag || Tag.create(:name => tag_name)
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
          as_8bit_ascii(str)
        else
          as_8bit_ascii(str).downcase
        end
      end

      def binary
        /mysql/ === ActiveRecord::Base.connection_config[:adapter] ? "BINARY " : nil
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
