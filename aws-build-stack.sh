#!/bin/bash
# build-image <tag(optional)>

info() {
  echo "[`date +'%Y-%m-%d %T'`] $@"
}

infon() {
  echo -n "[`date +'%Y-%m-%d %T'`] $@"
}

die() {
  echo "[`date +'%Y-%m-%d %T'`] $@" >&2
  exit 1
}

while [[ $# -gt 1 ]]; do
  key="$1"

  case $key in
    -w|--webhook)
      WEBHOOK="$2"
      shift # past argument
      ;;
    -g|--github)
      REPO="$2"
      shift # past argument
      ;;
    -r|--region)
      REGION="$2"
      shift # past argument
      ;;
    -n|--name)
      NAME="$2"
      shift # past argument
      ;;
    -t|--template)
      TEMPLATE="$2"
      shift # past argument
      ;;
    *)
      echo "Unknown Option."
      exit 1
      ;;
  esac
  shift # past argument or value
done

eval project_name=\$NAME
if [ "$project_name" ]; then
  info "Project Name:       $project_name"
else
  die "-n|--name Required"
fi

eval github=\$REPO
if [ "$github" ]; then
  info "Github Repo:        $github"
else
  die "-g|--github Required"
fi

eval webhook=\$WEBHOOK
if [ "$webhook" ]; then
  info "Slack Webhook:      $webhook"
else
  die "-w|--webhook Required"
fi

aws_region='us-west-2'
eval region_set=\$REGION
if [ "$region_set" ]; then
  aws_region="$region_set"
fi
info "AWS Region:         $aws_region"

template='templates/sns-lambda-codebuild.json'
eval temp_set=\$TEMPLATE
if [ "$temp_set" ]; then
  template="$temp_set"
fi
info "CF Template:        $template"

base=$(echo $template | xargs basename -s .json | xargs basename -s .yml)
stack_name="${project_name}-${base}"
info "Stack Name:         $stack_name"

template_path="file://$(echo $(pwd)/${template} | sed -e 's/\//\/\//g')"
info "Full Template Path: $template_path"

init_build() {
  aws --region $aws_region cloudformation create-stack \
    --stack-name $stack_name \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-body $template_path \
    --parameters \
    ParameterKey=SlackWebhook,ParameterValue=${webhook} \
    ParameterKey=CodeRepoUrl,ParameterValue=${github} \
    ParameterKey=ProjectName,ParameterValue=${project_name}
}

start_build() {
  init_build | jq -r '.StackId'
}

stack_data() {
  aws --region $aws_region cloudformation describe-stacks --stack-name $stack_name
}

build_status() {
  # CREATE_COMPLETE|CREATE_IN_PROGRESS|CREATE_FAILED
  stack_data | jq -r '.Stacks[0].StackStatus'
}

is_updating() {
  [[ "$(build_status)" == "CREATE_IN_PROGRESS" ]] && return 0
  return 1
}

is_complete() {
  [[ "$(build_status)" == "CREATE_COMPLETE" ]] && return 0
  return 1
}

get_resources() {
  aws --region $aws_region cloudformation describe-stack-resources --stack-name $stack_name
}

sns_topic_arn() {
  get_resources | jq -c '.StackResources[] | select(.LogicalResourceId | contains("LambdaGitSNS"))' | jq -c '.PhysicalResourceId'
}

get_access_key() {
  aws --region $aws_region cloudformation describe-stacks --stack-name $stack_name | jq -c '.Stacks[0].Outputs[] | select(.OutputKey | contains("AccessKey"))' | jq -c '.OutputValue'
}

get_secret_key() {
  aws --region $aws_region cloudformation describe-stacks --stack-name $stack_name | jq -c '.Stacks[0].Outputs[] | select(.OutputKey | contains("SecretKey"))' | jq -c '.OutputValue'
}

get_ecr_repo() {
  aws --region $aws_region cloudformation describe-stacks --stack-name $stack_name | jq -c '.Stacks[0].Outputs[] | select(.OutputKey | contains("ECRRepo"))' | jq -c '.OutputValue'
}

while [[ true ]] ; do
  info "Starting Stack Build"
  stack_id="$(start_build)"
  info "Stack ID: $stack_id"

  start=$(date -u +%s)
  deadline=$((start + 900))
  while is_updating && [[ $(date -u +%s) -le $deadline ]] ; do
    echo -n .
    sleep 5
  done
  echo " "

  info "Stack Status: $(build_status)"
  if is_updating ; then
    die "Stack build timed out!"
  fi

  if is_complete ; then
    info "Info for Github Service Integration:"
    info " == AWS Region: $aws_region"
    info " == SNS Topic ARN: $(sns_topic_arn)"
    info " == AWS Access Key ID: $(get_access_key)"
    info " == AWS Secret Key: $(get_secret_key)"
    info " == AWS ECR Repo URL: $(get_ecr_repo)"
    info "Stack created! ($stack_name)"
    exit 0
  fi

  die "Stack build failed!"
done
