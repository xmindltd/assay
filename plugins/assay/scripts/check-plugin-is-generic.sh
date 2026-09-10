#!/usr/bin/env bash
# 守卫：仓库里不得出现任何「换个看板就不成立」的东西。
# 判据：这句话如果错了，是插件版本的问题，还是某个看板部署的问题？后者一律搬回服务端。
set -uo pipefail
cd "$(dirname "$0")/../../.."   # 仓库根

fail=0
report() { echo "✘ $1"; fail=1; }

scan() { grep -rInE "$1" --include='*.md' --include='*.json' --exclude-dir=.git . ; }

# 1. 具体域名 / 地址（本仓库自己的 GitHub 地址、example.com、<占位符> 放行）
if scan 'https?://[a-zA-Z0-9.-]+' | grep -vE 'example\.com|<[^>]+>|github\.com/[^/ ]+/assay' ; then
  report "出现了具体域名或地址"
fi

# 2. 具体项目 / 看板 id（本仓库自己的地址 xmindltd/assay 放行，长短写法都算）
if scan '\bquin\b|askquin|\bxmindltd\b' | grep -vE 'xmindltd/assay' ; then
  report "出现了具体项目名"
fi

# 3. 具体工具名（只允许约定固定的 describe_dashboard；PROFILE.md 的示例里允许出现一个）
if grep -rInE 'get_(order|user|arpu|abtest|track)_' --include='*.md' --exclude-dir=.git plugins ; then
  report "插件里出现了具体工具名（只允许 describe_dashboard / get_playbook）"
fi

# 4. 阈值数字
if grep -rInE '(k *= *[0-9]+|[0-9]+ *天上限|92 *天)' --include='*.md' --exclude-dir=.git plugins ; then
  report "插件里出现了具体阈值"
fi

if [ "$fail" -eq 0 ]; then echo "✔ 内容是通用的"; fi
exit $fail
