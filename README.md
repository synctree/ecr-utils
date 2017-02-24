# ecr-utils
AWS ECR build pipeline utilities

Requirements
---

- [aws cli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
- [jq](https://github.com/stedolan/jq)

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
 [2017-02-23 19:30:21] Project Name:       ecr-utils
 [2017-02-23 19:30:21] Github Repo:        https://github.com/synctree/ecr-utils.git
 [2017-02-23 19:30:21] Slack Webhook:      https://hooks.slack.com/services/superneattokenyo
 [2017-02-23 19:30:21] AWS Region:         us-west-2
 [2017-02-23 19:30:21] CF Template:        templates/lambda-codebuild.json
 [2017-02-23 19:30:21] Stack Name:         ecr-utils-pipeline
 [2017-02-23 19:30:21] Full Template Path: file:////usr//src//ecr-utils//templates//lambda-codebuild.json
 [2017-02-23 19:30:21] Starting Stack Build
 [2017-02-23 19:30:28] Stack ID: arn:aws:cloudformation:us-west-2:000000000000:stack/ecr-utils-pipeline/d2936cb0-fa30-11e6-8760-500c593b9a36
 .................
 [2017-02-23 19:32:11] Stack Status: CREATE_COMPLETE
 [2017-02-23 19:32:12] Info for Github Service Integration:
 [2017-02-23 19:32:12]  == AWS Region: us-west-2
 [2017-02-23 19:32:13]  == SNS Topic ARN: "arn:aws:sns:us-west-2:000000000000:lambda-ecr-utils-git"
 [2017-02-23 19:32:14]  == AWS Access Key ID: "AKIAJYP3FBXTYWADLX7A"
 [2017-02-23 19:32:15]  == AWS Secret Key: "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"
 [2017-02-23 19:32:15] Stack created! (ecr-utils-pipeline)
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
