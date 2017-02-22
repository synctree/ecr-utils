# ecr-utils
AWS ECR build pipeline utilities

Install
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
