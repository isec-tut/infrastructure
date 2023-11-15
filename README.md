# infrastructure

## 1. Prerequisite

ネットワーク、OS仮想化、Linux、Gitの基本的な知識があることを前提としています。

LinuxかMacでの動作を推奨しています。
WSL2でも可能ですが、Yubikeyのための設定が追加で必要です。

### 1.1 Requirement tools

- [pass](https://www.passwordstore.org/) : GPGで暗号化されたパスワード等機密情報管理ツール。(名前が一般すぎてのググラビリティが低い)
- [Terraform](https://developer.hashicorp.com/terraform/install) : コードの記述でクラウドなどインフラの自動構築や構成管理ができるInfrastructure as Codeソフトウェアツール
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) : プロビジョニング (ソフトウェアのインストールなどの初期設定のこと) 、アプリケーションのデプロイメントなどを自動化できるツール。特に同じ操作を何度繰り返しても、同じ結果が得られる概念の冪等性が特徴。
https://zenn.dev/y_mrok/books/ansible-no-tsukaikata が無料で公開されていて参考になる。

その他ツール
- `make`
- `gpg`: Macの方は https://gpgtools.org/ でも大丈夫です。
- `sed`: Macの方は`brew install gnu-sed`でGnu版のsedをインストールして`alias sed='gsed'`とエイリアスをしてください。


### 1.2. Initial settings
#### 1.2.1 Repository cloning
このリポジトリにはサブモジュールがあるため、cloneする際に`--recursive`オプションをつける必要があります。

サブモジュールについては https://www.m3tech.blog/entry/git-submodule が参考になります。

```bash
$ git clone --recursive git@github.com:isec-tut/infrastructure.git
```
もしオプションをつけずにcloneした際はリポジトリ内で以下のコマンドによりサブモジュールが取得されます。
```bash
$ git submodule update --init
```

#### 1.2.2 pass setting

サブモジュールのvaultというリポジトリに`pass`により管理され暗号化されたパスワードが含まれていますので`pass`にこのディレクトリを教えてあげる必要があります。
```bash
$ export PASSWORD_STORE_DIR=$(pwd)/vault
or
$ source ./env.sh
```
新たにターミナルを開いた場合でも忘れずに`PASSWORD_STORE_DIR`の設定をしてください。

vaultにパスワード等を追加したときは自動的にコミットされるので以下のようにpushしてください。
```bash
$ pass insert test # testという秘密情報を追加
$ pass git push origin HEAD:main # 自動的にコミットされているのでpushする
```

vaultの更新をした場合は以下のようにサブモジュールの更新をしてください。
```bash
$ git submodule update --remote
$ git add vault
$ git commit -m "Update submodule: vault"
$ git push
```