# ecr-utils
AWS ECR build pipeline utilities

Requirements
---

- [aws cli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
- [jq](https://github.com/stedolan/jq)

Cloudformation Stacks
---

There are 4 AWS Cloudformation Stack templates included.

- `templates/codebuild.json`
- `templates/codebuild-ecr.json`
- `templates/sns-lambda-codebuild.json`
- `templates/sns-lambda-codebuild-ecr.json`

The name of the template file is pretty straight forward. The name implies the services it will integrate based on the Project Name (`-n`) passed in.

To build a stack, pass the Template file to the script:

```
$ AWS_PROFILE=client ./aws-build-stack.sh \
  -n <github-repo-name> \
  -g <full-path-to-github-repo>.git \
  -w <slace-webhook-url> \
  -t templates/sns-lambda-codebuild-ecr.json
```

Example output:

```
$ AWS_PROFILE=client ./aws-build-stack.sh \
  -n ecr-utils \
  -g https://github.com/synctree/ecr-utils.git \
  -w https://hooks.slack.com/services/superneattokenyo \
  -t templates/sns-lambda-codebuild-ecr.json
[2017-02-23 20:17:47] Project Name:       ecr-utils
[2017-02-23 20:17:47] Github Repo:        https://github.com/synctree/ecr-utils.git
[2017-02-23 20:17:47] Slack Webhook:      hhttps://hooks.slack.com/services/superneattokenyo
[2017-02-23 20:17:47] AWS Region:         us-west-2
[2017-02-23 20:17:47] CF Template:        templates/sns-lambda-codebuild-ecr.json
[2017-02-23 20:17:47] Stack Name:         ecr-utils-sns-lambda-codebuild-ecr
[2017-02-23 20:17:47] Full Template Path: file:////usr//src//ecr-utils//templates//sns-lambda-codebuild-ecr.json
[2017-02-23 20:17:47] Starting Stack Build
[2017-02-23 20:17:50] Stack ID: arn:aws:cloudformation:us-west-2:00000000000:stack/ecr-utils-sns-lambda-codebuild-ecr/70578cf0-fa37-11e6-9f4b-503f2a2ceee6
...............
[2017-02-23 20:19:20] Stack Status: CREATE_COMPLETE
[2017-02-23 20:19:22] Info for Github Service Integration:
[2017-02-23 20:19:22]  == AWS Region: us-west-2
[2017-02-23 20:19:23]  == SNS Topic ARN: "arn:aws:sns:us-west-2:00000000000:lambda-ecr-utils-git"
[2017-02-23 20:19:23]  == AWS Access Key ID: "AKIAJVJLSVDCNSLT4K3A"
[2017-02-23 20:19:24]  == AWS Secret Key: "superSecretAccessKeyWithLimitedPrivs"
[2017-02-23 20:19:25]  == AWS ECR Repo URL: "00000000000.dkr.ecr.us-west-2.amazonaws.com/ecr-utils"
[2017-02-23 20:19:25] Stack created! (ecr-utils-sns-lambda-codebuild-ecr)
```

Install Utilities
---

```
curl https://raw.githubusercontent.com/synctree/eb-utils/master/install.sh | bash -
```

CI Configs
---

- `buildspec.yml`
  - This is the AWS CodeBuild configuration file. Required to use AWS CodeBuild.
  - Simply calls the `bin/build-image` script.
- `circle.yml`
  - Configuration for CircleCI.
  - Calls the `bin/cb` with the branch to build.

### CircleCI circle.yml

```yaml
---
dependencies:
  pre:
    - sudo pip install --upgrade awscli
    - curl https://raw.githubusercontent.com/synctree/ecr-utils/master/install.sh | bash -

test:
  post:
    - /usr/local/bin/cb -p $CODEBUILD_PROJECT -e $ECR_REPO -b $CIRCLE_BRANCH
```

### AWS CodeBuild buildspec.yml

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

bin files
---

- `bin/build-image`
  - This will perform the login, build and push for Docker image to ECR.
  - By default, it will tag the image with the branch name and also with the branch name + SHA1. This will allow for more specific build tagging and release.
- `bin/cb`
  - This will start the AWS CodeBuild and report status back.
  - It will successfully close when a build is complete with a good status. It will close with error and fail the build. This can be used within the
