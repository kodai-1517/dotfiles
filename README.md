# dotfiles

自分の macOS 開発環境を最短で復元するためのメモ兼セットアップリポジトリ。

## このREADMEの使い方

- 新しいMacをセットアップするときに上から順に実行する
- ふだん設定を追加したときに、更新手順だけ確認する
- 何か壊れたときに、復旧手順を見る

## 最短セットアップ手順

### 1. リポジトリを配置

```bash
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```

### 2. 初回セットアップを実行

```bash
./setup.sh --first-run
```

### 3. 手動でやること

```bash
gh auth login
```

- Obsidian の vault を指定
- 必要なら VS Code で `Shell Command: Install 'code' command in PATH` を実行

## 日常運用

### 設定を反映し直す

```bash
cd ~/dotfiles
./setup.sh
```

### 変更を保存する

```bash
cd ~/dotfiles
git add .
git commit -m "Update dotfiles"
git push
```

## setup.sh の実行内容

1. Homebrew の確認とインストール
2. Brewfile のパッケージ導入
3. fish をログインシェルに設定
4. dotfiles をホーム配下へシンボリックリンク
5. VS Code 設定と拡張機能の反映
6. asdf のプラグイン追加とランタイム導入

## バックアップ方針

- 既存ファイルが通常ファイルなら、`~/.dotfiles_backup/<timestamp>/` に退避される
- GitHub はコミット済みファイルの履歴管理用
- ローカルバックアップは、未コミット状態やホーム配下の既存設定を戻すための保険

## 管理対象

- `setup.sh`: セットアップ本体
- `Brewfile`: CLI ツールとアプリ
- `fish/config.fish`: fish 初期設定
- `starship.toml`: プロンプト設定
- `.gitconfig`: Git 共通設定
- `.tool-versions`: asdf 管理バージョン
- `vscode/settings.json`: VS Code 設定
- `vscode/extensions.txt`: VS Code 拡張機能一覧

## 追加・変更時のチェックリスト

1. 対象ファイルをこのリポジトリで更新
2. `./setup.sh` を実行して反映確認
3. 必要なら README も更新
4. commit / push

## トラブル時メモ

- `code` コマンドが見つからない: VS Code の Shell Command を有効化
- fish が見つからない: `brew install fish` 後に `./setup.sh` を再実行
- `pnpm` / `uv` が見つからない: `./setup.sh` を再実行して新しいターミナルを開く
- 以前の設定へ戻したい: `~/.dotfiles_backup` から復元
