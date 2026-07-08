import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { i18n } from "discourse-i18n";
import DButton from "discourse/ui-kit/d-button";

export default class OnboardingGuideUsername extends Component {
  <template>
    <p>{{i18n "onboarding_guide.username.helper"}}</p>
    <DButton
      @label="onboarding_guide.username.open_preferences"
      @action={{fn @openUrl "/my/preferences/account"}}
    />
  </template>
}
