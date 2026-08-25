#!/usr/bin/env bash

WORKSPACE_ID="$1"

# 获取所有显示器当前可见的 workspace
VISIBLE_WORKSPACES=$(aerospace list-workspaces --monitor all --visible)

# 如果当前这个 workspace 在任意显示器上可见，则显示红色
if echo "$VISIBLE_WORKSPACES" | grep -qx "$WORKSPACE_ID"; then
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color=0xffff0000
else
  # 不可见的 workspace 使用默认颜色
  sketchybar --set "$NAME" \
    background.drawing=off \
    icon.color=0xffffffff
fi
