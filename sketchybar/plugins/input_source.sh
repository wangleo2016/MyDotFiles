#!/bin/bash

SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null)

if echo "$SOURCE" | grep -q "com.apple.inputmethod.SCIM"; then
  LABEL="CN"
elif echo "$SOURCE" | grep -q "com.apple.inputmethod.Japanese"; then
  LABEL="JP"
else
  LABEL="EN"
fi

sketchybar --set "$NAME" label="$LABEL"
