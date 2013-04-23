module ActsAsTaggableOn
  module TagsHelper
    # See the README for an example using tag_cloud.
    def tag_cloud(tags, classes)
      return [] if tags.empty?

      max_count = tags.sort_by(&:count).last.count.to_f

      tags.each do |tag|
        index = ((tag.count / max_count) * (classes.size - 1))
        yield tag, classes[index.nan? ? 0 : index.round]
      end
    end
  end
end