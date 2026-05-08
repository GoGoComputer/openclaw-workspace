#!/usr/bin/env bash
# =============================================================================
# book/scripts/check-no-elision.sh
# 책 본문에서 코드 생략 표현이 들어갔는지 검사 (CI 용)
# 통과 조건: 0 hit
# =============================================================================
set -euo pipefail

BOOK_SRC="$(cd "$(dirname "$0")/.." && pwd)/src"
echo "🔍 검사 대상: $BOOK_SRC"

# 검출할 패턴 (본문 산문이 아닌 코드 블록 안에서 등장하면 위반)
PATTERNS=(
  '# *\.\.\. *생략'
  '# *\(이하 동일\)'
  '# *앞 장과 같음'
  '# *자세한 내용은.*레포'
  '<!-- *생략 *-->'
)

# 메타 페이지(원칙 자체를 설명하는 페이지) 와 README 는 검사 제외 —
# 이 페이지들은 "이런 표현을 쓰지 않는다" 를 산문으로 설명하므로 의도적으로 패턴이 등장함.
EXCLUDES=(
  --exclude="00-cover.md"
  --exclude="00-preface.md"
  --exclude="A0-overview.md"
)

FAIL=0
for pat in "${PATTERNS[@]}"; do
  if hits=$(grep -rnE "${EXCLUDES[@]}" "$pat" "$BOOK_SRC" 2>/dev/null); then
    echo "❌ 위반 패턴: $pat"
    echo "$hits"
    FAIL=1
  fi
done

# 부록 A 의 모든 .sh 가 임베드되었는지 매핑 검사
APPENDIX_A="$BOOK_SRC/appendix-a-scripts"
WORKSPACE_ROOT="$(cd "$BOOK_SRC/../.." && pwd)"

missing=0
while IFS= read -r script; do
  rel="${script#"$WORKSPACE_ROOT"/}"
  if ! grep -rqF "{{#include ../../../$rel}}" "$APPENDIX_A"; then
    echo "⚠️  부록 A 미임베드: $rel"
    missing=$((missing + 1))
  fi
done < <(find "$WORKSPACE_ROOT/openclaw-mgr/cmd" "$WORKSPACE_ROOT/openclaw-mgr/lib" -name '*.sh' -type f)

if [ "$missing" -gt 0 ]; then
  echo "❌ $missing 개 스크립트가 부록 A 에 빠져 있습니다."
  FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  echo "✅ 코드 무삭제 원칙 통과 — 위반 0건"
  exit 0
else
  echo "❌ 검사 실패. 위 메시지를 확인하세요."
  exit 1
fi
