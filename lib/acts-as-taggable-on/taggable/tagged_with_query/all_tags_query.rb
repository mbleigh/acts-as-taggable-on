# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module TaggedWithQuery
      class AllTagsQuery < QueryBase
        def build
          scope = taggable_model.where(
            taggable_arel_table[taggable_model.primary_key].in(
              taggables_with_all_tags
            )
          )

          if options[:match_all].present?
            taggable_model.find_by_sql(tag_arel_table.project(Arel.star.count).where(tags_match_type).to_sql)

            scope = scope.where(
              taggable_arel_table[taggable_model.primary_key].in(
                taggables_with_exact_tag_count
              )
            )
          end

          scope.order(order_conditions).readonly(false)
        end

        private

        def taggables_with_all_tags
          tagging_arel_table
            .project(tagging_arel_table[:taggable_id])
            .where(tagging_conditions)
            .group(tagging_arel_table[:taggable_id])
            .having(tagging_arel_table[:tag_id].count(true).eq(tag_list.size))
        end

        def tagging_conditions
          condition = tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name)
                                                        .and(
                                                          tagging_arel_table[:tag_id].in(
                                                            tag_arel_table.project(tag_arel_table[:id]).where(tags_match_type)
                                                          )
                                                        )

          if options[:start_at].present?
            condition = condition.and(tagging_arel_table[:created_at].gteq(options[:start_at]))
          end

          condition = condition.and(tagging_arel_table[:created_at].lteq(options[:end_at])) if options[:end_at].present?

          condition = condition.and(tagging_arel_table[:context].eq(options[:on])) if options[:on].present?

          if (owner = options[:owned_by]).present?
            condition = condition.and(tagging_arel_table[:tagger_id].eq(owner.id))
                                 .and(tagging_arel_table[:tagger_type].eq(owner.class.base_class.to_s))
          end

          condition
        end

        def taggables_with_exact_tag_count
          all_condition = tagging_arel_table[:taggable_type].eq(taggable_model.base_class.name)

          if options[:start_at].present?
            all_condition = all_condition.and(tagging_arel_table[:created_at].gteq(options[:start_at]))
          end

          if options[:end_at].present?
            all_condition = all_condition.and(tagging_arel_table[:created_at].lteq(options[:end_at]))
          end

          all_condition = all_condition.and(tagging_arel_table[:context].eq(options[:on])) if options[:on].present?

          tagging_arel_table
            .project(tagging_arel_table[:taggable_id])
            .where(all_condition)
            .group(tagging_arel_table[:taggable_id])
            .having(
              tagging_arel_table[:id].count.eq(
                tag_arel_table.project(Arel.star.count).where(tags_match_type)
              )
            )
        end

        def order_conditions
          order_by = []
          if options[:order_by_matching_tag_count].present? && options[:match_all].blank?
            order_by << tagging_arel_table.project(tagging_arel_table[Arel.star].count.as('taggings_count')).order('taggings_count DESC').to_sql
          end

          order_by << options[:order] if options[:order].present?
          order_by.join(', ')
        end
      end
    end
  end
end
