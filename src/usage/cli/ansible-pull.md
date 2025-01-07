# `ansible-pull`

从某个版本控制系统代码库中拉取 playbook，并在目标主机上执行。

## 简介

```console
usage: ansible-pull [-h] [--version] [-v] [--private-key PRIVATE_KEY_FILE]
                 [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT]
                 [--ssh-common-args SSH_COMMON_ARGS]
                 [--sftp-extra-args SFTP_EXTRA_ARGS]
                 [--scp-extra-args SCP_EXTRA_ARGS]
                 [--ssh-extra-args SSH_EXTRA_ARGS]
                 [-k | --connection-password-file CONNECTION_PASSWORD_FILE]
                 [--vault-id VAULT_IDS]
                 [-J | --vault-password-file VAULT_PASSWORD_FILES]
                 [-e EXTRA_VARS] [-t TAGS] [--skip-tags SKIP_TAGS]
                 [-i INVENTORY] [--list-hosts] [-l SUBSET] [-M MODULE_PATH]
                 [-K | --become-password-file BECOME_PASSWORD_FILE]
                 [--purge] [-o] [-s SLEEP] [-f] [-d DEST] [-U URL] [--full]
                 [-C CHECKOUT] [--accept-host-key] [-m MODULE_NAME]
                 [--verify-commit] [--clean] [--track-subs] [--check]
                 [--diff]
                 [playbook.yml ...]
```

## 描述


用于在各个托管节点上，拉取 `ansible` 的远端副本，每个托管节点都通过 `cron` 运行，并通过某种源码库更新 playbook 源码。这就将 `ansible` 的默认 *推送* 架构，颠倒成了一种 *拉取* 架构，这就具备近乎无限的横向扩展潜力。

{{#include ansible-galaxy.md:16}}

其中的设置 playbook 可被调整为改变 `ansible-pull` 的 `cron` 频率、日志记录位置及参数等。这对极端扩展，以及定期修复都很有用。使用 `fetch` 模组，从 `ansible-pull` 的运行中检索日志，是收集和分析 `ansible-pull` 远端日志的绝佳方法。


## 常用选项

- `--accept-host-key`，如果尚未添加，则网址添加代码仓库 URL 的主机密钥；
{{#include ansible.md:33}}
- `--check`，不做任何改变，而是尝试预测可能发生的一些变化；
- `--clean`，处于工作中代码仓库下，被修改的文件将被丢弃；
{{#include ansible.md:33}}
{{#include ansible-pull.md:42}}
- `--diff`，更改（小）文件和模板时，显示这些文件的差异；与 `--check` 一起使用效果极佳；
- `--full`，进行完整克隆，而不是浅层克隆；
{{#include ansible.md:35}}
{{#include ansible-pull.md:45}}
{{#include ansible.md:36}}
{{#include ansible.md:38}}
- `--purge`，运行 playbook 后清除签出；
{{#include ansible.md:39:40}}
{{#include ansible-playbook.md:43}}
{{#include ansible.md:41:42}}
- `--track-subs`，子模组将跟踪最新的变更。这相当于在 `git submodule update` 命令中，指定 `-remote` 开关；
{{#include ansible.md:44:45}}
- `--verify-commit`，验证已签出提交的 GPG 签名，如果验证失败，则中止运行该 playbook。这需要相应的 VCS 模组，来支持此类操作；
{{#include ansible.md:46}}
- `-C <CHECKOUT>, --checkout <CHECKOUT>`，要签出的分支/标签/提交。默认值为版本库模组的行为方式；
{{#include ansible.md:50:52}}
{{#include ansible.md:54}}
- `-U <URL>, --url <URL>`，playbook 源码库的 URL；
{{#include ansible.md:57}}
- `-d <DEST>, --directory <DEST>`，Ansible 将签出版本库到的目录路径;
{{#include ansible.md:58}}
- `-f, --force`，即使版本库无法更新，也要运行 playbook；
{{#include ansible.md:60:63}}
- `-m <MODULE_NAME>, --module-name <MODULE_NAME>`，版本库模组名称，`ansible` 将使用该名称签出版本库。可选项有（`'git'`、`'subversion'`、`'hg'`、`'bzr'`）。默认为 `git`；
- `-o, --only-if-changed`，仅在版本库已更新的情况下运行 playbook；
- `-s <SLEEP>, --sleep <SLEEP>`，启动前的随机睡眠时间间隔（`0` 到 `n` 秒之间）。这是分散 `git` 请求的有效方法；
{{#include ansible-playbook.md:52}}
{{#include ansible.md:67:68}}


## 参数，arguments

- `playbook.yaml`，要作为 Ansible playbook 运行的 YAML 格式文件的名称。可以是签出中的相对路径。默认情况下，Ansible 会根据主机的 FQDN、主机名和名为 `local.yml` 的 playbook 顺序，查找 playbook。



{{#include ansible.md:70:}}
