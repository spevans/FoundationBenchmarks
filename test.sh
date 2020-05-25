#!/bin/sh

MACOS_TESTS="Passed"
LINUX_TESTS="Passed"

swift package clean
swift test -c release || MACOS_TESTS="Failed"
docker build --tag=foundation-benckmark-tests:$(date +%s) . || LINUX_TESTS="Failed"

echo
echo macOS tests ${MACOS_TESTS}
echo Linux tests ${LINUX_TESTS}
