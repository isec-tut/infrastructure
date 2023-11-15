# Terraform

> **Note**
>
> `root@pve:`となっているコマンドはproxmoxにsshでログインしてから実行しています。

> **Note**
>
> `isec@ubuntu:`となっているコマンドはローカルの環境で実行しています。


## 1. 初期時のみのセットアップ

> **Warning**
>
> Proxmoxをインストールしなおした場合のみに以下を実行する必要があります。
> それ以外の場合はこの章はスキップしてください。


```bash
# proxmoxのlocalストレージにcloud-initのsnippetsを追加できるようにする
root@pve:~$ pvesm set local --content vztmpl,snippets,iso,backup

# proxmoxにおけるterraformの実行ユーザを追加して、トークンを取得する
root@pve:~$ pveum role add TerraformProv -privs "SDN.Use Datastore.AllocateSpace Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"

root@pve:~$ pveum user add terraform-prov@pve --password $(openssl rand -base64 32)
root@pve:~$ pveum aclmod / -user terraform-prov@pve -role TerraformProv
# 最後に作成したtoken(以下の例では`d19b28f7-3756-4158-92e5-e6c033fa9e00`)をvaultに反映する必要がある
root@pve:~$ pvesh create /access/users/terraform-prov@pve/token/terraform --privsep 0
┌──────────────┬──────────────────────────────────────┐
│ key          │ value                                │
╞══════════════╪══════════════════════════════════════╡
│ full-tokenid │ terraform-prov@pve!terraform         │
├──────────────┼──────────────────────────────────────┤
│ info         │ {"privsep":"0"}                      │
├──────────────┼──────────────────────────────────────┤
│ value        │ d19b28f7-3756-4158-92e5-e6c033fa9e00 │
└──────────────┴──────────────────────────────────────┘
```


```bash
# 以下でvaultに暗号化された機密情報を編集するためにエディタが起動する
isec@ubuntu:~/infrastructure$ pass edit infra/terraform/tfvars
```

以下のようなファイルになっているので `proxmox.token_secret` を先ほど表示されたtoken(例では`d19b28f7-3756-4158-92e5-e6c033fa9e00`)を入力し保存します。

```terraform
proxmox = {
  api_url      = "dummy"
  token_id     = "dummy"
  token_secret = "d19b28f7-3756-4158-92e5-e6c033fa9e00"
}

userdata = {
  user_name       = "dummy"
  hashed_password = "dummy"
  ssh_pub_key     = "dummy"
}
```

> **Note**
>
> デフォルトではNanoエディタが起動するので、`Ctrl+x`, `y`, `Enter`で保存して終了できます。

変更すると自動的にcommitされるので忘れずにpushしておく。

```bash
isec@ubuntu:~/infrastructure$ pass git log # 変更確認
isec@ubuntu:~/infrastructure$ pass git push
```

## 2. VMの作成

Terraformを使って宣言的にVMの構成を管理しているので以下のコマンドを実行するだけで、Proxmox上にVMを作成することができます。

```bash
# terraformのプラグインをダウンロードする
isec@ubuntu:~/infrastructure/terraform$ terraform init
# vmの元になるtemplate vmを作成する *初めに１回だけ実行すればよい*
isec@ubuntu:~/infrastructure/terraform$ make template
# template vmから新規にcloneしてvmを作成する
isec@ubuntu:~/infrastructure/terraform$ make vm
```

デフォルトで作成されるVMの概要は以下の通りです。
- hostname: `isec-k3s`
- IP address: `172.16.50.15`
- SSH: SSHはパスワードでのログインが禁止されており、ハードウェアトークンを用いてのみSSHログイン可能
- User: `isec` sudoはパスワードなしで実行可能
- Password: 以下のコマンドを実行することで閲覧可能
  ```bash
  isec@ubuntu:~/infrastructure$ pass infra/vm/k3s/password
  ```

テンプレートイメージはUbuntu 22.04のcloud-imageを使用しており、cloud-imageは毎日ビルドされているので、ベースを更新したいときは以下のように`update-template`すればテンプレートが更新される。

```bash
# cloud-imageを新たにダウンロードしてtemplate vmを更新する
isec@ubuntu:~/infrastructure/terraform$ make update-template
```

> **Note**
>
> テンプレートの更新を反映するにはもう一度cloneからやり直す必要があります。
>
> ただ、同一のIDやName、アドレスを使用したVMは複数作成できないため、`make vm`を２回実行することはできないことに注意してください。
>
> なので`make vm`する前に、`make destroy-vm`を実行することで作成したVMを削除することで`make vm`を実行することができます。**しかし、これは実行中のVMの場合は環境を壊してしまう可能性があるため、何を実行しようとしているのか理解している場合のみ実行してください。**

> **Note**
>
> 実行中のVMは停止せずに新たにVMを作成したい場合は、`make`コマンドの引数に`TARGET_VM_ID`,`TARGET_VM_NAME`,`TARGET_VM_IP_ADDR`を指定することで重複せずにVMを作成できます。
> デフォルトの値は以下の通りです。
> - `TARGET_VM_ID` = `115`
> - `TARGET_VM_NAME` = `isec-k3s`
> - `TARGET_VM_IP_ADDR` = `172.16.50.15`
>
> ```bash
> # デフォルト値から変更してVMを作成する場合
> isec@ubuntu:~/infrastructure/terraform$ make vm TARGET_VM_ID="116"TARGET_VM_NAME="isec-k3s-1" TARGET_VM_IP_ADDR="172.16.50.16"
> ```
