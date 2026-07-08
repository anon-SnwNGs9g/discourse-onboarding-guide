import Component from "@glimmer/component";
import { fn, concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import OnboardingGuideCategoryBadge from "./onboarding-guide-category-badge";

export default class OnboardingGuidePreferences extends Component {
  <template>
    <p>{{i18n "onboarding_guide.preferences.helper"}}</p>
    {{#each @preferenceItems as |group|}}
      <div class="onboarding-guide-preference-group">
        <div class="onboarding-guide-preference-group__summary">{{group.summary}}</div>
        {{#each group.items as |item|}}
          <div class="onboarding-guide-preference-item">
            <div class="onboarding-guide-preference-label">
              {{#if (eq item.type "category")}}
                {{#let (@preferenceItemCategory item) as |cat|}}
                  {{#if cat}}
                    <a href={{@preferenceItemUrl item}} class="hashtag-cooked" {{on "click" (fn @openUrl (@preferenceItemUrl item))}}>
                      <OnboardingGuideCategoryBadge @category={{cat}} />
                      <span>{{item.label}}</span>
                    </a>
                  {{else}}
                    <span>{{item.label}}</span>
                  {{/if}}
                {{/let}}
              {{else}}
                <a href={{@preferenceItemUrl item}} class="hashtag-cooked" {{on "click" (fn @openUrl (@preferenceItemUrl item))}}>{{dIcon "tag"}}<span>{{item.label}}</span></a>
              {{/if}}
            </div>
            <div class="onboarding-guide-preference-options">
              {{#each @notificationStates as |state|}}
                <button
                  type="button"
                  class={{if (eq (@selectedState item) state) "is-selected" ""}}
                  {{on "click" (fn @choosePreference item state)}}
                >
                  {{i18n (concat "onboarding_guide.preferences." state)}}
                </button>
              {{/each}}
            </div>
          </div>
        {{/each}}
      </div>
    {{/each}}
  </template>
}
