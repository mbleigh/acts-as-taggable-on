module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::Utils

    attr_accessible :name

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name
    validates_length_of :name, :maximum => 255

    ### SCOPES:

    def self.named(name)
      where(["lower(name) = ?", name.downcase])
    end

    def self.named_any(list)
      where(list.map { |tag| sanitize_sql(["lower(name) = ?", tag.to_s.mb_chars.downcase]) }.join(" OR "))
    end

    def self.named_like(name)
      where(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(name)}%"])
    end

    def self.named_like_any(list)
      where(list.map { |tag| sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name)
      named_like(name).first || create(:name => name)
    end

    def self.find_or_create_all_with_like_by_name(*list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list).all
      new_tag_names = list.reject do |name|
                        name = comparable_name(name)
                        existing_tags.any? { |tag| comparable_name(tag.name) == name }
                      end
      created_tags  = new_tag_names.map { |name| Tag.create(:name => name) }

      existing_tags + created_tags
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
          str.mb_chars.downcase.to_s
        end
    end
  end
end
