import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import OnboardingGuideCategoryBadge from "./onboarding-guide-category-badge";

export default class OnboardingGuideTutorials extends Component {
  <template>
    <p class="onboarding-guide-tutorials__welcome">
      {{i18n "onboarding_guide.tutorials.welcome_title" site_name=@title}}
    </p>
    <p class="onboarding-guide-tutorials__congrats">
      {{i18n "onboarding_guide.tutorials.congratulations"}}
    </p>
    {{#if @tutorialCategory}}
      <p>
        {{i18n "onboarding_guide.tutorials.helper_prefix" site_name=@title}}
        <a
          href={{@tutorialCategory.url}}
          class="hashtag-cooked"
          {{on "click" (fn @openUrl @tutorialCategory.url)}}
        >
          <OnboardingGuideCategoryBadge @category={{@siteCategory}} />
          <span>{{@tutorialCategory.name}}</span>
        </a>
        {{i18n "onboarding_guide.tutorials.helper_suffix"}}
      </p>
    {{/if}}
  </template>
}
