---
generation_date: 2024-06-06 11:52
tags:  publish_artifcate_script nexus
---
#!/bin/bash

set -ex

# Summary

# Below are the list of tasks that are executed as part of the script

# Prereq:

#  - The script needs 2 positional paramaters
#     - 1. The folder location which need to pacakge- eg: src/main
#     - 2. yes/no (boolean value) if this package is a release artefact.

#  Main:

#  1. check for prereq - positional parameters.
#  2. Parse the arguments from command line
#  3. check if the folder exists
#  4. set the artefact name
#  5. Create the artefact file
#  6. Publish to Nexus

#  The script outputs logs with prefix - [INFO], [SUCCESS], [ERROR] based on the execution.

echo "[INFO] Publish script executing..."

# Variables

# get the values from positional parameter

FOLDER_LOCATION=""
IS_RELEASE=""
NEXUS_CREDS=""

# Nexus Variables

NEXUS_URL=https://nexus-write.ldn.swissbank.com/nexus/content/repositories
SNAPSHOT_REPOSITORY=deploy-shared-055-snapshot
RELEASE_REPOSITORY=deploy-shared-055-release
GROUP_ID=com/ubs/uk8s
NEXUS_USER=SSO_AKS_DEPLOY

# pre-checks()

# check for positional parameters.

script_usage() {
  SCRIPT_NAME=$(basename "$0")
  echo "[DEBUG] Usage: $SCRIPT_NAME --folder-location </path/to/folder> --is-release <true/false> --nexus-creds <NEXUS_CREDENTIALS>"
}

if [ $# -ne 6 ]; then
    script_usage
    exit 1
fi

# Parse command line arguments

while [[ $# -gt 0 ]]; do
  case "$1" in
     --folder-location)
         FOLDER_LOCATION="$2"
         shift 2
         ;;
     --is-release)
         IS_RELEASE="$2"
         shift 2
         ;;
     --nexus-creds)
         NEXUS_CREDS="$2"
         shift 2
         ;;
     *)
         script_usage
         exit 1
         ;;
  esac
done

# check if the folder exists

if [ ! -d "$FOLDER_LOCATION" ]; then
    echo "[ERROR] Folder not found - $FOLDER_LOCATION"
    exit 1
fi

# main()

FOLDER_NAME=$(basename "$FOLDER_LOCATION")
ARTEFACT_VERSION=`cat ./version.txt`

# set the artefact name

if [ $FOLDER_NAME == "env" ]; then
    ARTEFACT_NAME=aks-gitops-deploy-config
    ARTEFACT_ID=$ARTEFACT_NAME-$ARTEFACT_VERSION
    echo "[INFO] Artefact name set to: $ARTEFACT_NAME with version $ARTEFACT_VERSION"
else
    ARTEFACT_NAME=aks-gitops-deploy
    ARTEFACT_ID=$ARTEFACT_NAME-$ARTEFACT_VERSION
    echo "[INFO] Artefact name set to: $ARTEFACT_NAME with version $ARTEFACT_VERSION"
fi

upload_to_nexus() {
    local build_artefact="$1"
    local repository_username="$2"
    local repository_password="$3"
    local deploy_url="$4"
    local exit_code="$5"

    if [[ $exit_code -eq 0 ]]; then
        echo "[SUCCESS] Release artefact $build_artefact created"
        echo "[INFO] Uploading $build_artefact to nexus"

        curl -v -u "${repository_username}:${repository_password}" --upload-file "target/${build_artefact}" "${deploy_url}"
        [ $? -eq 0 ] && echo "[SUCCESS]: Uploaded $build_artefact to $deploy_url" || echo "[ERROR] curl command to publish artefact to nexus failed";
    else
       echo "[ERROR] tar command failed"
       exit 1
    fi
}

# create and publish the artefact file

if [ $IS_RELEASE == "true" ]; then
    if [$FOLDER_NAME == "env"]; then
        BUILD_ARTEFACT=$ARTEFACT_ID.tar.gz
        echo "[INFO] Creating Config release artifact $BUILD_ARTEFACT"
        DEPLOY_URL="${NEXUS_URL}/${RELEASE_REPOSITORY}/${GROUP_ID}/${ARTEFACT_NAME}/${ARTEFACT_VERSION}/${BUILD_ARTEFACT}"
        tar -czf  "target/$BUILD_ARTEFACT" -C "$FOLDER_LOCATION" .
        upload_to_nexus $BUILD_ARTEFACT $NEXUS_USER $NEXUS_CREDS $DEPLOY_URL $?
    else
        BUILD_ARTEFACT=$ARTEFACT_ID.tar.gz
        echo "[INFO] Creating Infra release artifact $BUILD_ARTEFACT"
        DEPLOY_URL="${NEXUS_URL}/${RELEASE_REPOSITORY}/${GROUP_ID}/${ARTEFACT_NAME}/${ARTEFACT_VERSION}/${BUILD_ARTEFACT}"
        tar -czf  "target/$BUILD_ARTEFACT" --exclude='**/*.params.json' --exclude='.git' --exclude='target' --exclude='env' -C "$FOLDER_LOCATION" .
        upload_to_nexus $BUILD_ARTEFACT $NEXUS_USER $NEXUS_CREDS $DEPLOY_URL $?
    fi
else
    if [$FOLDER_NAME == "env"]; then
        CURRENT_TIMESTAMP=$(date +'%Y%m%d%H%M')
        BUILD_ARTEFACT=$ARTEFACT_ID-SNAPSHOT-$CURRENT_TIMESTAMP.tar.gz
        echo "[INFO] Creating Config snapshot artifact $BUILD_ARTEFACT"
        DEPLOY_URL="${NEXUS_URL}/${SNAPSHOT_REPOSITORY}/${GROUP_ID}/${ARTEFACT_NAME}/${ARTEFACT_VERSION}-SNAPSHOT/${BUILD_ARTEFACT}"
        tar -czf  "target/$BUILD_ARTEFACT" -C "$FOLDER_LOCATION" .
        upload_to_nexus $BUILD_ARTEFACT $NEXUS_USER $NEXUS_CREDS $DEPLOY_URL $?
    else
        CURRENT_TIMESTAMP=$(date +'%Y%m%d%H%M')
        BUILD_ARTEFACT=$ARTEFACT_ID-SNAPSHOT-$CURRENT_TIMESTAMP.tar.gz
        echo "[INFO] Creating Infra snapshot artifact $BUILD_ARTEFACT"
        DEPLOY_URL="${NEXUS_URL}/${SNAPSHOT_REPOSITORY}/${GROUP_ID}/${ARTEFACT_NAME}/${ARTEFACT_VERSION}-SNAPSHOT/${BUILD_ARTEFACT}"
        tar -czf  "target/$BUILD_ARTEFACT" --exclude='**/*.params.json' --exclude='.git' --exclude='target' --exclude='env' -C "$FOLDER_LOCATION" .
        upload_to_nexus $BUILD_ARTEFACT $NEXUS_USER $NEXUS_CREDS $DEPLOY_URL $?
    fi
fi