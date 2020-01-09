#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

if test ! -z "${ARTIFACT_S3_URL}"; then


  echo "Downloading from location ${ARTIFACT_S3_URL}"

  #test ! -z "${2}" && ARTIFACT_NAME="${2}"
  echo "Downloading Artifact ${ARTIFACT_NAME}"

  #test ! -z "${3}" && ARTIFACT_VERSION="${3}"
  echo "Downloading Artifact Version ${ARTIFACT_VERSION}"

  # Install AWS CLI if the upload location is S3
  if test "${ARTIFACT_S3_URL#s3}" == "${ARTIFACT_S3_URL}"; then
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

  for row in $(echo "${ARTIFACT_LIST}" | jq -c '.[]'); do
    _artifact() {
      echo ${row} | jq -r ${1}
    }


    echo $(_artifact '.name')  > ${OUT_DIR}/test${row}.txt
    ARTIFACT_NAME=$(_artifact '.name')
    ARTIFACT_VERSION=$(_artifact '.version')
    ARTIFACT_TYPE=$(_artifact '.type')
    ARTIFACT_FILE_NAME="${ARTIFACT_NAME}-${ARTIFACT_VERSION}.jar"
    #ARTIFACT_DOWNLOAD_URL="${ARTIFACT_S3_URL}/${ARTIFACT_FILE_NAME}"
    ARTIFACT_DOWNLOAD_URL="s3://yfaruqi-artifact-test/pf-apple-cloud-identity-connector/1.0.1/deploy/pf-apple-idp-adapter-1.0.1.jar"

    # Test command to see if the script is being executed
    echo ${ARTIFACT_VERSION} > ${OUT_DIR}/test${ARTIFACT_NAME}.txt

    echo ${ARTIFACT_S3_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/deploy > ${OUT_DIR}/artifactdeploy.txt

    # Download latest artifact file from s3 bucket
    #aws s3 cp "${ARTIFACT_DOWNLOAD_URL}" "${OUT_DIR}/instance/server/default/deploy/${ARTIFACT_FILE_NAME}"
    aws s3 cp "${ARTIFACT_S3_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/deploy" "${OUT_DIR}/instance/server/default/deploy" --recursive

    #aws s3 cp "${ARTIFACT_S3_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/template" "${OUT_DIR}/instance/server/default/conf/template" --recursive
  done

  #Testing parsing json
  echo ${ARTIFACT_LIST} > ${OUT_DIR}/artifactList.json
  #ARTIFACT_NAME=$(jq -r .name ${OUT_DIR}/artifactList.json)
  #ARTIFACT_VERSION=$(jq -r .version ${OUT_DIR}/artifactList.json)
  #ARTIFACT_TYPE=$(jq -r .type ${OUT_DIR}/artifactList.json)
  #ARTIFACT_FILE_NAME="${ARTIFACT_NAME}-${ARTIFACT_VERSION}.${ARTIFACT_TYPE}"
  #ARTIFACT_DOWNLOAD_URL="${ARTIFACT_S3_URL}/${ARTIFACT_FILE_NAME}"

  # Test command to see if the script is being executed
  #echo ${ARTIFACT_VERSION} > ${OUT_DIR}/test${ARTIFACT_NAME}.txt

  # Download latest artifact file from s3 bucket
  #aws s3 cp "${ARTIFACT_DOWNLOAD_URL}" "${OUT_DIR}/instance/server/default/deploy/${ARTIFACT_FILE_NAME}"

  # Print listed files from deploy
  ls ${OUT_DIR}/instance/server/default/deploy
fi
