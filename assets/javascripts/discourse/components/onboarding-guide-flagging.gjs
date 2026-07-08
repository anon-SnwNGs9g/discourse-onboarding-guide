import Component from "@glimmer/component";
import { fn, concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import OnboardingGuideSamplePost from "./onboarding-guide-sample-post";

export default class OnboardingGuideFlagging extends Component {
  <template>
    <p>{{i18n "onboarding_guide.flagging.helper"}}</p>
    <OnboardingGuideSamplePost @onFlag={{@markSampleFlagged}} />
    <div class="onboarding-guide-flagging-alt">
      <p>
        {{i18n "onboarding_guide.flagging.pm_helper_before"}}
        <a href="/g/{{@moderatorsGroupName}}" class="mention-group" {{on "click" (fn @openUrl (concat "/g/" @moderatorsGroupName))}}>@{{@moderatorsGroupName}}</a>
        {{i18n "onboarding_guide.flagging.pm_helper_after"}}
      </p>
      <ol class="onboarding-guide-flagging-steps">
        <li>{{i18n "onboarding_guide.flagging.pm_step_one"}}</li>
        <li>{{i18n "onboarding_guide.flagging.pm_step_two"}}</li>
        <li>
          {{i18n "onboarding_guide.flagging.pm_step_three" groupName=@moderatorsGroupName}}
        </li>
        <li>
          {{i18n "onboarding_guide.flagging.pm_step_four" groupName=@moderatorsGroupName}}
        </li>
      </ol>

      <div class="onboarding-guide-group-demo">
        <div class="onboarding-guide-group-demo__mobile-frame">
          <div class="onboarding-guide-group-demo__topbar">
            <button
              type="button"
              class="onboarding-guide-group-demo__hamburger"
              {{on "click" @togglePmSidebar}}
              aria-label={{i18n "onboarding_guide.flagging.pm_hamburger_label"}}
            >
              {{dIcon "bars"}}
            </button>
          </div>

          {{#if @pmSidebarOpen}}
            <div class="onboarding-guide-group-demo__sidebar">
              <div class="onboarding-guide-group-demo__sidebar-item">
                {{i18n "onboarding_guide.flagging.pm_sidebar_home"}}
              </div>
              <div class="onboarding-guide-group-demo__sidebar-item">
                {{i18n "onboarding_guide.flagging.pm_sidebar_latest"}}
              </div>
              <div class="onboarding-guide-group-demo__more-wrap">
                <button
                  type="button"
                  class="onboarding-guide-group-demo__sidebar-item is-active"
                  {{on "click" @togglePmMore}}
                >
                  <span class="onboarding-guide-group-demo__ellipsis">...</span>
                  <span>{{i18n "onboarding_guide.flagging.pm_sidebar_more"}}</span>
                </button>

                {{#if @pmMoreOpen}}
                  <div class="onboarding-guide-group-demo__dropdown">
                    <div>{{i18n "onboarding_guide.flagging.pm_dropdown_bookmarks"}}</div>
                    <button
                      type="button"
                      class="onboarding-guide-group-demo__dropdown-item {{if @pmGroupsOpen "is-active" ""}}"
                      {{on "click" @openPmGroups}}
                    >
                      {{i18n "onboarding_guide.flagging.pm_dropdown_groups"}}
                    </button>
                    <div>{{i18n "onboarding_guide.flagging.pm_dropdown_tags"}}</div>
                  </div>
                {{/if}}
              </div>
            </div>
          {{/if}}
        </div>
      </div>

      {{#if @pmGroupsOpen}}
        <div class="onboarding-guide-group-card">
          <div class="onboarding-guide-group-card__header">
            <div>
              <div class="onboarding-guide-group-card__title">
                {{i18n "onboarding_guide.flagging.pm_group_title"}}
              </div>
              <div class="onboarding-guide-group-card__subtitle">
                {{i18n "onboarding_guide.flagging.pm_group_hint" groupName=@moderatorsGroupName}}
              </div>
            </div>
            <button
              type="button"
              class="btn btn-primary"
              {{on "click" @markPmMessageClicked}}
            >
              {{i18n "onboarding_guide.flagging.pm_message_button"}}
            </button>
          </div>

          <div class="onboarding-guide-group-card__body">
            {{#if @pmMessageClicked}}
              <div class="onboarding-guide-group-card__done">
                {{i18n "onboarding_guide.flagging.pm_completed"}}
              </div>
            {{/if}}
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}
