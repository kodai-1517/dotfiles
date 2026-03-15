#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
FIRST_RUN=false

# --first-run フラグの判定
if [ "${1:-}" = "--first-run" ]; then
  FIRST_RUN=true
fi

echo "==> バックアップ先: $BACKUP_DIR"

# ──────────────────────────────────────────
# ユーティリティ関数
# ──────────────────────────────────────────

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local rel="${dst#"$HOME/"}"
    local backup_path="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$backup_path")"
    cp -r "$dst" "$backup_path"
    echo "  backup: $dst"
  fi
  ln -sf "$src" "$dst"
  echo "  linked: $dst -> $src"
}

# ──────────────────────────────────────────
# 1. Homebrew
# ──────────────────────────────────────────
echo ""
echo "==> [1/5] Homebrew"

if $FIRST_RUN; then
  echo "  Command Line Tools の確認"
  xcode-select --install 2>/dev/null || true
fi

if ! command -v brew &>/dev/null; then
  echo "  Homebrew をインストール中..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

brew bundle install --file="$DOTFILES/Brewfile"
echo ""
echo "  [参考] Brewfileに含まれていないパッケージ:"
brew bundle cleanup --file="$DOTFILES/Brewfile" || true

# ──────────────────────────────────────────
# 2. シェル設定
# ──────────────────────────────────────────
echo ""
echo "==> [2/5] シェル設定"

BREW_PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
FISH_PATH="$BREW_PREFIX/bin/fish"

if [ ! -f "$FISH_PATH" ]; then
  echo "  warn: fish が見つかりません ($FISH_PATH)。Brewfile を確認してください。"
else
  if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
  fi
  if [ "$SHELL" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
  fi
fi

link "$DOTFILES/fish/config.fish" "$HOME/.config/fish/config.fish"
[ -f "$DOTFILES/starship.toml" ] && \
  link "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"

# ──────────────────────────────────────────
# 3. Git設定
# ──────────────────────────────────────────
echo ""
echo "==> [3/5] Git設定"
link "$DOTFILES/.gitconfig" "$HOME/.gitconfig"

# ──────────────────────────────────────────
# 4. VS Code
# ──────────────────────────────────────────
echo ""
echo "==> [4/5] VS Code"

if [ -f "$DOTFILES/vscode/extensions.txt" ]; then
  if command -v code &>/dev/null; then
    INSTALLED=$(code --list-extensions)
    while IFS= read -r ext || [ -n "$ext" ]; do
      # CRLFや前後空白を除去し、空行はスキップ
      ext=$(printf '%s' "$ext" | tr -d '\r')
      ext="${ext#"${ext%%[![:space:]]*}"}"
      ext="${ext%"${ext##*[![:space:]]}"}"
      [ -z "$ext" ] && continue

      if echo "$INSTALLED" | grep -Fqi -x "$ext"; then
        echo "  skip: $ext"
      else
        echo "  installing: $ext"
        if code --install-extension "$ext"; then
          INSTALLED="$INSTALLED"$'\n'"$ext"
        else
          echo "  warn: failed to install $ext (continuing)"
        fi
      fi
    done < "$DOTFILES/vscode/extensions.txt"
  else
    echo "  warn: code コマンドが見つかりません。"
    echo "        VS Codeで『Shell Command: Install 'code' command in PATH』を実行してください。"
  fi
fi

[ -f "$DOTFILES/vscode/settings.json" ] && \
  link "$DOTFILES/vscode/settings.json" \
    "$HOME/Library/Application Support/Code/User/settings.json"

[ -f "$DOTFILES/vscode/mcp.json" ] && \
  link "$DOTFILES/vscode/mcp.json" \
    "$HOME/Library/Application Support/Code/User/mcp.json"

# ──────────────────────────────────────────
# 5. ランタイム（asdf）
# ──────────────────────────────────────────
echo ""
echo "==> [5/5] ランタイム"

if [ -f "$DOTFILES/.tool-versions" ]; then
  while IFS=' ' read -r plugin _version; do
    asdf plugin add "$plugin" 2>/dev/null || true
  done < "$DOTFILES/.tool-versions"
  link "$DOTFILES/.tool-versions" "$HOME/.tool-versions"
  (cd "$DOTFILES" && asdf install) && echo "  ✓ ランタイムのインストール完了"
else
  echo "  warn: $DOTFILES/.tool-versions が見つからないためランタイム設定をスキップします"
fi

# ──────────────────────────────────────────
# 完了
# ──────────────────────────────────────────
echo ""
echo "✅ セットアップ完了！"
echo "   バックアップ: $BACKUP_DIR"
echo "   ターミナルを再起動してください"

if $FIRST_RUN; then
  echo ""
  echo "   次に手動でやること："
  echo "   1. gh auth login"
  echo "   2. Obsidian で vault を指定"
fi
