#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

echo Running pre hook  > ${OUT_DIR}/test.txt

if test ! -z "${ARTIFACT_S3_URL}"; then

  echo "Downloading from location ${ARTIFACT_S3_URL}"

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

    aws s3 cp "${ARTIFACT_S3_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/deploy/" "${OUT_DIR}/instance/server/default/deploy" --recursive --debug 2> ${OUT_DIR}/error1.txt
    aws s3 cp "${ARTIFACT_S3_URL}/${ARTIFACT_NAME}/${ARTIFACT_VERSION}/conf/" "${OUT_DIR}/instance/server/default/conf" --recursive --debug 2> ${OUT_DIR}/error2.txt
  done

  # Print listed files from deploy
  ls ${OUT_DIR}/instance/server/default/deploy
  ls ${OUT_DIR}/instance/server/default/conf
fi
