# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class PreferenceUpdater
    VALID_STATES = %w[regular tracking watching_first_post muted].freeze
    VALID_TYPES = %w[category tag].freeze

    class << self
      def update!(user, items)
        allowed_items = StateResolver.flat_preference_items_for(user).index_by { |item| "#{item[:type]}:#{item[:id]}" }

        items.each do |item|
          type = item[:type].to_s
          id = item[:id].to_i
          state = item[:state].to_s

          raise Discourse::InvalidParameters.new(:items) if !VALID_STATES.include?(state)
          raise Discourse::InvalidParameters.new(:items) if !VALID_TYPES.include?(type)
          raise Discourse::InvalidParameters.new(:items) if !allowed_items.key?("#{type}:#{id}")

          if type == "category"
            update_category_state!(user, id, state)
          else
            update_tag_state!(user, id, state)
          end
        end
      end

      private

      def update_category_state!(user, category_id, state)
        CategoryUser.where(user_id: user.id, category_id: category_id).delete_all
        return if state == "regular"

        CategoryUser.create!(
          user_id: user.id,
          category_id: category_id,
          notification_level: CategoryUser.notification_levels[state.to_sym],
        )
      end

      def update_tag_state!(user, tag_id, state)
        TagUser.where(user_id: user.id, tag_id: tag_id).delete_all
        return if state == "regular"

        TagUser.create!(
          user_id: user.id,
          tag_id: tag_id,
          notification_level: TagUser.notification_levels[state.to_sym],
        )
      end
    end
  end
end
