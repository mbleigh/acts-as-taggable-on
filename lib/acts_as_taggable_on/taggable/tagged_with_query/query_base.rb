module ActsAsTaggableOn::Taggable::TaggedWithQuery
  class QueryBase
    def initialize(taggable_model, tag_model, tagging_model, tag_list, options)
      @taggable_model = taggable_model
      @tag_model      = tag_model
      @tagging_model  = tagging_model
      @tag_list       = tag_list
      @options        = options
    end

    private

    attr_reader :taggable_model, :tag_model, :tagging_model, :tag_list, :options

    def taggable_arel_table
      @taggable_arel_table ||= taggable_model.arel_table
    end

    def tag_arel_table
      @tag_arel_table ||= tag_model.arel_table
    end

    def tagging_arel_table
      @tagging_arel_table ||=tagging_model.arel_table
    end

    def tag_match_type(tag)
      match_type = options[:wild].present? ? 'matches' : 'eq'

      tag_arel_table[:name].lower.public_send(match_type, tag.downcase)
    end

    def tags_match_type
      match_type = options[:wild].present? ? 'matches_any' : 'eq_any'

      tags = options[:wild].present? ? tag_list.map { |tag| "%#{tag.downcase}%"} : tag_list.map(&:downcase)
      tag_arel_table[:name].lower.public_send(match_type, tags)
    end
  end
end
