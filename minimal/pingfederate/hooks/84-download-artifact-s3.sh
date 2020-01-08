#!/usr/bin/env sh

${VERBOSE} && set -x

# Set PATH - since this is executed from within the server process, it may not have all we need on the path
export PATH="${PATH}:${SERVER_ROOT_DIR}/bin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"

ARTIFACT_S3_URL="s3://yfaruqi-pf-artifacts-bucket"
ARTIFACT_NAME="pf-apple-idp-adapter"
ARTIFACT_VERSION="1.0.1"

#test ! -z "${1}" && ARTIFACT_S3_URL="${1}"
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

ARTIFACT_FILE_NAME="${ARTIFACT_NAME}-${ARTIFACT_VERSION}.jar"
ARTIFACT_DOWNLOAD_URL="${ARTIFACT_S3_URL}/${ARTIFACT_FILE_NAME}"

# Test command to see if the script is being executed
echo $ARTIFACT_DOWNLOAD_URL > ${OUT_DIR}/test${ARTIFACT_NAME}.txt

# Download latest artifact file from s3 bucket
aws s3 cp "${ARTIFACT_DOWNLOAD_URL}" "${OUT_DIR}"
aws s3 cp "${ARTIFACT_DOWNLOAD_URL}" "${OUT_DIR}/instance/server/default/deploy/${ARTIFACT_FILE_NAME}"

# Print listed files from deploy
ls ${OUT_DIR}/instance/server/default/deploy
