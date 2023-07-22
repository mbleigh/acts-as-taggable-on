# frozen_string_literal: true

class AddMissingIndexesOnTaggings < ActiveRecord::Migration[6.0]
  def change
    add_index ActsAsTaggableOn.taggings_table, :context unless index_exists? ActsAsTaggableOn.taggings_table, :context

    unless index_exists? ActsAsTaggableOn.taggings_table, %i[tagger_id tagger_type]
      add_index ActsAsTaggableOn.taggings_table, %i[tagger_id tagger_type]
    end

    unless index_exists? ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type tagger_id context],
                         name: 'taggings_idy'
      add_index ActsAsTaggableOn.taggings_table, %i[taggable_id taggable_type tagger_id context],
                name: 'taggings_idy'
    end
  end
end
