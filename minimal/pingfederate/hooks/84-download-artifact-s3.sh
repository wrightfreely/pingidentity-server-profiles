#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

echo ${PF_ARTIFACT_LIST} > ${OUT_DIR}/artifactList.txt
echo ${ARTIFACT_REPO_URL} > ${OUT_DIR}/artifactRepo.txt

# Check to see if an artifact list is available
if test ! -z "${PF_ARTIFACT_LIST}"; then

  # Check to see if the source S3 bucket is specified
  if test ! -z "${ARTIFACT_REPO_URL}"; then

    echo "Downloading from location ${ARTIFACT_REPO_URL}"

    # Install AWS CLI if the upload location is S3
    if test "${ARTIFACT_REPO_URL#s3}" == "${ARTIFACT_REPO_URL}"; then
      echo "Upload location is not S3"
      exit 0
    elif ! which aws > /dev/null; then
      echo "Installing AWS CLI"
      apk --update add python3
      pip3 install --no-cache-dir --upgrade pip
      pip3 install --no-cache-dir --upgrade awscli
    fi

    if ! which jq > /dev/null; then
      echo "Installing jq"
      pip3 install --no-cache-dir --upgrade jq
    fi

    DIRECTORY_NAME=$(echo ${PING_PRODUCT} | tr '[:upper:]' '[:lower:]')

    if [ -z "${ARTIFACT_REPO_URL##*/pingfederate*}" ] ; then
      TARGET_BASE_URL="${ARTIFACT_REPO_URL}"
    else
      TARGET_BASE_URL="${ARTIFACT_REPO_URL}/${DIRECTORY_NAME}"
    fi

    if test "${PF_ARTIFACT_LIST#LIST:}" == "${PF_ARTIFACT_LIST}"; then
      ARTIFACT_LIST_JSON="${PF_ARTIFACT_LIST}"
    else
      ARTIFACT_LIST_JSON=${PF_ARTIFACT_LIST/LIST:/}
    fi

    echo ${ARTIFACT_LIST_JSON} > ${OUT_DIR}/artifactListJSON.txt
    for artifact in $(echo "${ARTIFACT_LIST_JSON}" | jq -c '.[]'); do
      _artifact() {
        echo ${artifact} | jq -r ${1}
      }

      ARTIFACT_NAME=$(_artifact '.name')
      ARTIFACT_VERSION=$(_artifact '.version')

      if [ ! -z "$(aws s3 ls ${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/deploy)" ]
      then
        aws s3 cp "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/deploy/" "${OUT_DIR}/instance/server/default/deploy" --recursive
      fi

      if [ ! -z "$(aws s3 ls ${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/conf)" ]
      then
        aws s3 cp "${TARGET_BASE_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/conf/" "${OUT_DIR}/instance/server/default/conf" --recursive
      fi

    done

    # Print listed files from deploy
    ls ${OUT_DIR}/instance/server/default/deploy
    ls ${OUT_DIR}/instance/server/default/conf/template

  fi

fi
