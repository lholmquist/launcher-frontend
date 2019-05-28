#!/bin/bash
# Split on "/" to get last part of URL, ref: http://stackoverflow.com/a/5257398/689223
URL_SPLIT=(${CIRCLE_PULL_REQUEST//\// })
PR_NUM=$(printf %s\\n "${URL_SPLIT[@]:(-1)}")
# Domain names follow the RFC1123 spec [a-Z] [0-9] [-] limited to 253 characters
# https://en.wikipedia.org/wiki/Domain_Name_System#Domain_name_syntax
# So, just replace "/" or "." with "-"

DEPLOY_APP_SUBDOMAIN=`echo "fabric8-launcher-frontend-pr-${PR_NUM}-app"`
DEPLOY_APP_DOMAIN="https://${DEPLOY_APP_SUBDOMAIN}.surge.sh"
ALREADY_DEPLOYED_APP=`yarn run surge list | grep ${DEPLOY_APP_SUBDOMAIN}`
yarn app:build:mock-api
yarn run surge --project ./packages/launcher-app/build --domain ${DEPLOY_APP_DOMAIN};

DEPLOY_WELCOME_APP_DOMAIN="https://fabric8-launcher-frontend-pr-${PR_NUM}-welcome-app.surge.sh"
yarn wa:build:mock-api
yarn run surge --project ./packages/launcher-welcome-app/build --domain ${DEPLOY_WELCOME_APP_DOMAIN};

DEPLOY_STORYBOOK_DOMAIN="https://fabric8-launcher-frontend-pr-${PR_NUM}-storybook.surge.sh"
yarn comp:storybook:build
yarn run surge --project ./packages/launcher-component/storybook-static --domain ${DEPLOY_STORYBOOK_DOMAIN};

DEPLOY_QUARKUS_DOMAIN="https://fabric8-launcher-frontend-pr-${PR_NUM}-quarkus-app.surge.sh"
yarn quarkus-app:build
yarn run surge --project ./packages/quarkus-launcher-app/build --domain ${DEPLOY_QUARKUS_DOMAIN};

if [ -z "$ALREADY_DEPLOYED_APP" ]
then
  # Using the Issues api instead of the PR api
  # Done so because every PR is an issue, and the issues api allows to post general comments,
  # while the PR api requires that comments are made to specific files and specific commits
  GITHUB_PR_COMMENTS="https://api.github.com/repos/${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}/issues/${PR_NUM}/comments"
  echo "Adding github PR comment ${GITHUB_PR_COMMENTS}"
  curl -H "Authorization: token ${GH_PR_TOKEN}" --request POST ${GITHUB_PR_COMMENTS} --data '{"body":"This PR was deployed **with mocked data** in the following URLs for your appreciation:\n- Frontend: '${DEPLOY_APP_DOMAIN}'\n- Welcome App: '${DEPLOY_WELCOME_APP_DOMAIN}'\n- Storybook: '${DEPLOY_STORYBOOK_DOMAIN}'\n- Quarkus: '${DEPLOY_QUARKUS_DOMAIN}'"}'
else
  echo "Already deployed ${DEPLOY_STORYBOOK_DOMAIN}"
fi
