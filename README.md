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
#### 1.2.1 GPG setting

#### WSL2の場合

YubikeyをWSL2に認識させるためにWindowsのUSBをWSLにバインドする[usbipd-win](https://github.com/dorssel/usbipd-win/)を使用する。

> **Note**
>
> usbipd-winはWindowsにインストールしてください
>


詳細: https://learn.microsoft.com/ja-jp/windows/wsl/connect-usb

wingetが使える場合は以下のコマンドを実行してインストールできます。
```cmd
winget install --interactive --exact dorssel.usbipd-win
```
インストール完了後、再起動します。

WSL2を起動しつつ別ターミナルで管理者権限でPowerShellを起動して以下のコマンドを実行します。

```powershell
# Windowsで認識しているUSBの一覧を取得
usbipd list
# 対象のYubikeyのバスIDを使用してYubikeyをusbipdの管理下にするためにバインドする
usbipd bind --busid <busid>
```
これ以降のコマンドには管理者権限は必要ありません。
```powershell
# もう一度一覧を表示させてYubikeyがsharedになっていることを確認する
usbipd list
# USBデバイスをWSL2に接続する
usbipd attach --wsl --busid <busid>
```
> **Note**
>
> 初めにbindすれば次回からはattachするだけでWSL2に接続されます。
>
> Yubikeyを接続するUSBポートを変更した場合はもう一度bindする必要があります。

WSL2のターミナルを開き以下のコマンドを実行します。

```bash
# WSL2でYubikeyが認識されているかを確認
lsusb

# 必要なソフトウェアのインストール
sudo apt install -y scdaemon pcscd pass gpg make

# pcscd(スマートカードデーモン)を再起動
sudo service pcscd restart

# GPG公開鍵をインポート
wget https://github.com/isec-tut/infrastructure/raw/main/keys/gpg/isec.gpg.pub
gpg --import isec.gpg.pub
# GPG公開鍵を信頼する
echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "isec" trust
# gpg-agentの設定ファイルを作成する
cat <<EOF > $(gpgconf --list-dir homedir)/gpg-agent.conf
pinentry-program  /usr/bin/pinentry-curses

enable-ssh-support
default-cache-ttl-ssh    7200
max-cache-ttl-ssh       28800
EOF
fi

# gpg-agentの再読み込み
gpg-connect-agent reloadagent /bye
gpg-connect-agent updatestartuptty /bye

# gpgがYubikeyを認識しているか確認
gpg --card-status

# sshの公開鍵のダウンロード
wget -O ~/.ssh/isec.pub https://github.com/isec-tut/infrastructure/raw/main/keys/ssh/isec.pub
chmod 600 ~/.ssh/isec.pub
```
本リポジトリでは以下のsshconfigを前提として作成されています。
```sshconfig
Host isec-er-lite3
    HostName        172.16.50.1
    User            isec
    IdentityFile    ~/.ssh/isec.pub

Host isec-pve
    HostName        172.16.50.2
    User            root
    IdentityFile    ~/.ssh/isec.pub

Host isec-k3s
    HostName        172.16.50.15
    User            isec
    IdentityFile    ~/.ssh/isec.pub
```

以下の内容で`.zshrc`や`.bashrc`などに追加することで自動的に初期設定を行うことができます。
```bash
result=0
# Yubikeyが接続されているか確認
output=$(lsusb | grep -i Yubico 2>&1 > /dev/null) || result=$?
if [ "$result" = "0" ]; then
  echo "Yubikey is connected. Checking if gpg-agent recognizes Yubikey."
  result=0
  # gpg-agentがYubikeyを認識しているか確認
  output=$(gpg --card-status 2>&1 > /dev/null) || result=$?
  if [ ! "$result" = "0" ]; then
    echo "gpg-agent is not recognizes Yubikey. Restarting pcscd..."
    sudo service pcscd restart
  fi
  echo "OK"
else
  echo "Yubikey is not connected. Please connect your Yubikey."
fi

export GPG_TTY=$(tty)
LANG=C gpg-connect-agent reloadagent /bye 2>&1 > /dev/null
LANG=C gpg-connect-agent updatestartuptty /bye 2>&1 > /dev/null
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
```


#### 1.2.2 Repository cloning
このリポジトリにはサブモジュールがあるため、cloneする際に`--recursive`オプションをつける必要があります。

サブモジュールについては https://www.m3tech.blog/entry/git-submodule が参考になります。

```bash
git clone --recursive git@github.com:isec-tut/infrastructure.git
```
もしオプションをつけずにcloneした際はリポジトリ内で以下のコマンドによりサブモジュールが取得されます。
```bash
git submodule update --init
```

#### 1.2.2 pass setting

サブモジュールのvaultというリポジトリに`pass`により管理され暗号化されたパスワードが含まれていますので`pass`にこのディレクトリを教えてあげる必要があります。
```bash
export PASSWORD_STORE_DIR=$(pwd)/vault
```
or
```bash
source ./env.sh
```
新たにターミナルを開いた場合でも忘れずに`PASSWORD_STORE_DIR`の設定をしてください。

vaultにパスワード等を追加したときは自動的にコミットされるので以下のようにpushしてください。
```bash
pass insert test # testという秘密情報を追加
pass git push origin HEAD:main # 自動的にコミットされているのでpushする
```

vaultの更新をした場合は以下のようにサブモジュールの更新をしてください。
```bash
git submodule update --remote
git add vault
git commit -m "Update submodule: vault"
git push
```