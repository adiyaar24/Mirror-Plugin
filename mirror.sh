#!/bin/sh
set -xe

ANONYMOUS=${PLUGIN_ANONYMOUS}
SOURCE_TOKEN=${PLUGIN_SOURCE_TOKEN}
SOURCE_URL=${PLUGIN_SOURCE_URL}
TARGET_TOKEN=${PLUGIN_TARGET_TOKEN}
TARGET_URL=${PLUGIN_TARGET_URL}
REFERENCE=${PLUGIN_REFERENCE}
REFERENCE_SHA_OLD=${PLUGIN_REFERENCE_SHA_OLD}
SYNC_DELETE=${PLUGIN_SYNC_DELETE}

if [ "$ANONYMOUS" = "true" ]; then
  SOURCE_URL_WITH_AUTH=$SOURCE_URL
  echo "Anonymous mode enabled. Using source URL without authentication."
else
  SOURCE_URL_WITH_AUTH=$(echo "$SOURCE_URL" | sed -e "s^//^//git:$SOURCE_TOKEN@^")
  echo "Using source URL with authentication."
fi


TARGET_URL_WITH_AUTH=$(echo "$TARGET_URL" | sed -e "s^//^//git:$TARGET_TOKEN@^")

echo "setup repo with source '$SOURCE_URL' and target '$TARGET_URL'"
git init --bare repo
cd repo
git remote add source $SOURCE_URL_WITH_AUTH
git remote add target $TARGET_URL_WITH_AUTH

echo "checking reference '$REFERENCE' existence on source"
set +e
git ls-remote --exit-code source $REFERENCE
STATUS=$?
set -e

# Handle reference deletion
if [ $STATUS -eq 2 ]; then
  if [ -z "$SYNC_DELETE" ] || [ "$SYNC_DELETE" != "true" ]; then
    echo "skip sync of deleted reference"
    return 0
  fi

  if [ -z "$REFERENCE_SHA_OLD" ]  || [ "$REFERENCE_SHA_OLD" = "null" ]; then
    echo "delete reference '$REFERENCE' from target"
    git push target ":$REFERENCE"
  else
    echo "delete reference '$REFERENCE' from target if on sha '$REFERENCE_SHA_OLD'"
    git push target ":$REFERENCE" --force-with-lease="$REFERENCE:$REFERENCE_SHA_OLD"
  fi

  echo "sync successful"
  return 0
elif [ $STATUS -ne 0 ]; then
  echo "failed to check reference existence"
  return 1
fi

# handle reference update / creation
echo "pulling reference '$REFERENCE' from source"
git fetch source "$REFERENCE:refs/sync/source"
SOURCE_SHA=$(git rev-parse "refs/sync/source^{commit}")
echo "source is on sha '$SOURCE_SHA'"

echo "pushing reference '$REFERENCE' on commit '$SOURCE_SHA' to target"
set +e
git push target "refs/sync/source:$REFERENCE"

# did the push succeed? return success
if [ $? -eq 0 ]; then
  echo "sync successful"
  return 0
fi

# we don't have any old sha left? return failure
if [ -z "$REFERENCE_SHA_OLD" ]  || [ "$REFERENCE_SHA_OLD" = "null" ]; then
  echo "sync failed - changes can't be fast forwarded"
  return 2
fi

# otherwise, retry save force-push to mimik changes on source (handles force push on source)
echo "fast forward sync failed - retry using the old sha '$REFERENCE_SHA_OLD' as assumed sha of reference on target repo"
git push target "refs/sync/source:$REFERENCE" --force-with-lease="$REFERENCE:$REFERENCE_SHA_OLD"

# did the push fail? return failure
if [ $? -ne 0 ]; then
  echo "sync failed - source and target are out of sync"
  echo "Manual intervention needed"
  return 3
fi

echo "sync successful"