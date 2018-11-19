#!/bin/sh
set -e
cd "${STL_ACTION_WORKING_DIR:-.}"

set +e
TEST_FILES=$(sh -c "sentinel test $*" 2>&1)
SUCCESS=$?
echo "$TEST_FILES"
set -e

if [ $SUCCESS -eq 0 ]; then
    exit 0
fi

if [ "$STL_ACTION_COMMENT" = "1" ] || [ "$STL_ACTION_COMMENT" = "false" ]; then
    exit $SUCCESS
fi

# Iterate through each unformatted file and build up a comment.
FMT_OUTPUT=""
for file in $TEST_FILES; do
FILE_DIFF=$(sentinel test "$file" | sed -n '/@@.*/,//{/@@.*/d;p}')
FMT_OUTPUT="$FMT_OUTPUT
<details><summary><code>$file</code></summary>

\`\`\`diff
$FILE_DIFF
\`\`\`
</details>
"
done

COMMENT="#### \`sentinel test\` Failed
$FMT_OUTPUT
"
PAYLOAD=$(echo '{}' | jq --arg body "$COMMENT" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data "$PAYLOAD" "$COMMENTS_URL" > /dev/null

exit $SUCCESS

