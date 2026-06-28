# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class StateResolver
    STEP_KEYS = %w[pledges flagging username preferences tutorials].freeze

    class << self
      def required_for?(user)
        SiteSetting.onboarding_guide_enabled && assigned?(user) && completed_version(user) < current_version
      end

      def preference_items_for(user)
        parsed_preference_items.filter_map do |group|
          items = group["items"].filter_map do |item|
            if item["type"] == "category"
              category = Category.find_by(slug: item["slug"])
              next if category.blank? || !Guardian.new(user).can_see_category?(category)

              {
                id: category.id,
                type: "category",
                key: category.slug,
                label: item["label"].presence || category.name,
                state: category_state_for(user, category.id),
              }
            else
              tag = Tag.find_by_name(item["name"])
              next if tag.blank?

              {
                id: tag.id,
                type: "tag",
                key: tag.name,
                label: item["label"].presence || tag.name,
                state: tag_state_for(user, tag.id),
              }
            end
          end
          next if items.empty?

          { summary: group["summary"], items: items }
        end
      end

      def flat_preference_items_for(user)
        preference_items_for(user).flat_map { |group| group[:items] }
      end

      def progress_for(user)
        raw = user.custom_fields[DiscourseOnboardingGuide::PROGRESS_FIELD]
        parsed = raw.is_a?(Hash) ? raw : JSON.parse(raw || "{}")
        return {} unless parsed.is_a?(Hash)

        boolean_type = ActiveModel::Type::Boolean.new
        progress = parsed.slice(*STEP_KEYS, "current_step", "version")
        return {} if progress["version"].to_i != current_version

        progress.tap do
          STEP_KEYS.each do |step|
            next unless progress.key?(step)

            progress[step] = boolean_type.cast(progress[step])
          end
        end
      rescue JSON::ParserError
        {}
      end

      def current_version
        SiteSetting.onboarding_guide_version.to_i
      end

      def completed_version(user)
        user.custom_fields[DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD].to_i
      end

      def assigned?(user)
        user.custom_fields[DiscourseOnboardingGuide::ASSIGNED_VERSION_FIELD].to_i > 0
      end

      private

      def parsed_preference_items
        JSON.parse(SiteSetting.onboarding_guide_preference_items_json)
      rescue JSON::ParserError
        []
      end

      def category_state_for(user, category_id)
        notification_level =
          CategoryUser.where(user_id: user.id, category_id: category_id).pick(:notification_level)
        category_state_from_level(notification_level)
      end

      def tag_state_for(user, tag_id)
        notification_level = TagUser.where(user_id: user.id, tag_id: tag_id).pick(:notification_level)
        tag_state_from_level(notification_level)
      end

      def category_state_from_level(level)
        return "regular" if level.blank?

        CategoryUser.notification_levels.key(level)&.to_s || "regular"
      end

      def tag_state_from_level(level)
        return "regular" if level.blank?

        TagUser.notification_levels.key(level)&.to_s || "regular"
      end
    end
  end
end
