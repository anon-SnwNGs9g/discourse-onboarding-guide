import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export default class OnboardingGuideProfileButton extends Component {
  @service currentUser;

  get visible() {
    return this.args.model?.id === this.currentUser?.id;
  }

  @action
  openGuide() {
    sessionStorage.removeItem("discourse-onboarding-guide-dismissed-session");
    sessionStorage.setItem("discourse-onboarding-guide-force-open", "1");
    window.location.reload();
  }

  <template>
    {{#if this.visible}}
      <li>
        <DButton
          @action={{this.openGuide}}
          @icon="clock-rotate-left"
          @label="onboarding_guide.profile_button"
          class="btn-default"
        />
      </li>
    {{/if}}
  </template>
}
