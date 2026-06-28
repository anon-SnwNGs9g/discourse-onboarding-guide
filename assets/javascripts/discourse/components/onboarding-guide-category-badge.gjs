import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";

export default class OnboardingGuideCategoryBadge extends Component {
  <template>
    {{#if @category.icon}}
      <span class="hashtag-category-icon hashtag-color--category-{{@category.id}}">{{dIcon @category.icon}}</span>
    {{else if @category.emoji}}
      <span class="hashtag-category-emoji hashtag-color--category-{{@category.id}}">{{dReplaceEmoji (concat ":" @category.emoji ":")}}</span>
    {{else}}
      <span class="hashtag-category-square hashtag-color--category-{{@category.id}}"></span>
    {{/if}}
  </template>
}
