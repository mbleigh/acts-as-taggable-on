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

      duplicates = []
      result = []
      existing_tags = named_any_by_comparable_name(list)
      list.each do |tag_name|
        existing_tag = existing_tags[comparable_name(tag_name)]
        if existing_tag
          result << existing_tag
        else
          begin
            result << Tag.create(:name => tag_name)
          rescue ActiveRecord::RecordNotUnique
            duplicates << tag_name
          end
        end
      end

      if duplicates.empty?
        result
      else
        result + Tag.named_any(duplicates)
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
        as_8bit_ascii(str).downcase
      end

      # Get the list of tags and index them by the comparable_name for faster lookup
      #
      # @param *list [Array<Array>] Array of tag lists
      # @return [Hash<comparable_name, tag_name>]
      def named_any_by_comparable_name(list)
        Hash[Tag.named_any(list).group_by{|tag| comparable_name(tag.name)}.map{|k,v| [k,v.first]}]
      end

      def binary
        using_mysql? ? "BINARY " : nil
      end

      def as_8bit_ascii(string)
        if defined?(Encoding)
          string.to_s.force_encoding('BINARY')
        else
          string.to_s.mb_chars
        end
      end
    end
  end
end
