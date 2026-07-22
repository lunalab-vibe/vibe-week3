#!/usr/bin/env bash
# Stop 훅: 한 턴이 끝날 때마다 날짜·시각과 완료 메시지를 worklog.txt에 기록한다.
echo "$(date '+%Y-%m-%d %H:%M:%S') ✅ 작업 한 턴 완료" >> "$CLAUDE_PROJECT_DIR/.claude/worklog.txt"
exit 0
