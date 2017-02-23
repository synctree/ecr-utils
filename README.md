# ecr-utils
AWS ECR build pipeline utilities

Cloudformation Stacks
---

There are 2 AWS Cloudformation Stacks included. One that will build out the `AWS CodeBuild` project alone and one that will build out `SNS + Lambda + AWS CodeBuild`.

To build the `AWS CodeBuild` Only Stack:

```
$ AWS_PROFILE=client ./aws-build-stack.sh \
  -n <github-repo-name> \
  -g <full-path-to-github-repo>.git \
  -w <slace-webhook-url> \
  -t templates/codebuild-only.json
```

To build the `SNS + Lambda + AWS CodeBuild` Stack:

```
$ AWS_PROFILE=client ./aws-build-stack.sh \
  -n <github-repo-name> \
  -g <full-path-to-github-repo>.git \
  -w <slace-webhook-url> \
  -t templates/lambda-codebuild.json
```

Example output:

```
$ AWS_PROFILE=client ./aws-build-stack.sh \
 -n ecr-utils \
 -g https://github.com/synctree/ecr-utils.git \
 -w https://hooks.slack.com/services/superneattokenyo \
 -t templates/lambda-codebuild.json
[2017-02-23 16:54:38] Project Name:       ecr-utils
[2017-02-23 16:54:38] Github Repo:        https://github.com/synctree/ecr-utils.git
[2017-02-23 16:54:38] Slack Webhook:      https://hooks.slack.com/services/superneattokenyo
[2017-02-23 16:54:38] AWS Region:         us-west-2
[2017-02-23 16:54:38] CF Template:        templates/lambda-codebuild.json
[2017-02-23 16:54:38] Stack Name:         ecr-utils-pipeline
[2017-02-23 16:54:38] Full Template Path: file:////opt//usr//ecr-utils//templates//lambda-codebuild.json
[2017-02-23 16:54:38] Starting Stack Build
[2017-02-23 16:54:40] Stack ID:           arn:aws:cloudformation:us-west-2:0000000000:stack/ecr-utils-pipeline/0ea23030-fa1b-11e6-8367-50d5ca789ee6
..........
[2017-02-23 16:55:42] Stack Status: CREATE_COMPLETE
[2017-02-23 16:55:43] Stack created! (ecr-utils-pipeline)
[2017-02-23 16:55:44] SNS Topic to link with Github repo: "arn:aws:sns:us-west-2:0000000000:lambda-ecr-utils-git"
```

Install Utilities
---

```
curl https://raw.githubusercontent.com/synctree/eb-utils/master/install.sh | bash -
```

CircleCI circle.yml
---

```yaml
---
dependencies:
  pre:
    - curl https://raw.githubusercontent.com/synctree/ecr-utils/master/install.sh | bash -

test:
  post:
    - /usr/local/bin/cb -p $CODEBUILD_PROJECT -e $ECR_REPO -b $CIRCLE_BRANCH
```

AWS CodeBuild buildspec.yml
---

```yaml
version: 0.1

phases:
  pre_build:
    commands:
      - curl https://raw.githubusercontent.com/synctree/ecr-utils/master/install.sh | bash -
  build:
    commands:
      - /usr/local/bin/build-image -w $SLACK_WEBHOOK -e $ECR_URL -n $ECR_REPO_NAME
  post_build:
    commands:
      - echo "[`date`] Build Complete."
```
