import Component from "@glimmer/component";
import { fn, get } from "@ember/helper";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";

export default class OnboardingGuidePledges extends Component {
  <template>
    <div class="onboarding-guide-links">
      <a href="/guidelines" {{on "click" (fn @openOverlay (i18n "onboarding_guide.pledges.guidelines") "/guidelines")}}>
        {{i18n "onboarding_guide.pledges.guidelines"}}
      </a>
      <a href="/tos" {{on "click" (fn @openOverlay (i18n "onboarding_guide.pledges.tos") "/tos")}}>
        {{i18n "onboarding_guide.pledges.tos"}}
      </a>
    </div>
    {{#each @pledges as |pledge index|}}
      <label class="onboarding-guide-field">
        <span>{{pledge}}</span>
        <input
          type="text"
          value={{get @pledgeInputs index}}
          {{on "input" (fn @updatePledge index)}}
        />
      </label>
    {{/each}}
  </template>
}
