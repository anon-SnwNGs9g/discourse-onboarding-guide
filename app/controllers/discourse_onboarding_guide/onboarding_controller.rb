# frozen_string_literal: true

module ::DiscourseOnboardingGuide
  class OnboardingController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    requires_login

    def show
      render_json_dump(StateResolver.state_for(current_user))
    end

    def progress
      current_user.upsert_custom_fields(
        DiscourseOnboardingGuide::PROGRESS_FIELD => progress_params.to_h.to_json,
      )
      current_user.save_custom_fields

      render json: success_json
    end

    def preferences
      PreferenceUpdater.update!(current_user, preference_items_params)
      render json: success_json
    end

    def complete
      raise Discourse::InvalidParameters.new(:version) if params[:version].to_i != StateResolver.current_version

      progress = StateResolver.progress_for(current_user)
      unless StateResolver::STEP_KEYS.all? { |step| progress[step] == true }
        return render_json_error(I18n.t("invalid_params"), status: 422)
      end

      current_user.upsert_custom_fields(
        DiscourseOnboardingGuide::COMPLETED_VERSION_FIELD => StateResolver.current_version,
      )
      current_user.save_custom_fields

      render json: success_json
    end

    private

    def progress_params
      params.require(:progress).permit(*StateResolver::STEP_KEYS, :current_step)
    end

    def preference_items_params
      params.require(:items).map do |item|
        ActionController::Parameters.new(item).permit(:id, :type, :state).to_h.symbolize_keys
      end
    end
  end
end
