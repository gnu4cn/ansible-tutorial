# `ansible-console`

REPL 控制台，用于执行 Ansible 任务。

> **译注**：REPL console，其中 REPL 指 read, evaluate, print, loop，读取-求值-打印-循环，故 REPL console 指的是交互式控制台。


## 简介

```console
usage: ansible-console [-h] [--version] [-v] [-b]
                    [--become-method BECOME_METHOD]
                    [--become-user BECOME_USER]
                    [-K | --become-password-file BECOME_PASSWORD_FILE]
                    [-i INVENTORY] [--list-hosts] [-l SUBSET]
                    [--private-key PRIVATE_KEY_FILE] [-u REMOTE_USER]
                    [-c CONNECTION] [-T TIMEOUT]
                    [--ssh-common-args SSH_COMMON_ARGS]
                    [--sftp-extra-args SFTP_EXTRA_ARGS]
                    [--scp-extra-args SCP_EXTRA_ARGS]
                    [--ssh-extra-args SSH_EXTRA_ARGS]
                    [-k | --connection-password-file CONNECTION_PASSWORD_FILE]
                    [-C] [-D] [--vault-id VAULT_IDS]
                    [-J | --vault-password-file VAULT_PASSWORD_FILES]
                    [-f FORKS] [-M MODULE_PATH] [--playbook-dir BASEDIR]
                    [-e EXTRA_VARS] [--task-timeout TASK_TIMEOUT] [--step]
                    [pattern]
```

## 描述

这是个 REPL，可通过一个漂亮的 shell（基于 dominis 的 `ansible-shell`），运行针对所选仓库的临时任务，该 shell 具有内置的制表符补全功能。

他支持多种命令，并可在运行时修改配置：


- `cd [pattern]`：改变主机/组别（咱们可以运用主机模式，比如 `app*.dc*:!app01*`）；
- `list`：列出当前路径下的可用主机；
- `list groups`：列出当前路径下所包含的组别；
- `become`：打开 `become` 命令行开关；
- `!`：强制从 `ansible` 模组进入 `shell` 模组（`!yum update -y`）；
- `verbosity [num]`：设置详细级别；
- `forks [num]`：设置进程分叉数目；
- `become_user [user]`：设置 `become_user`；
- `remote_user [user]`：设置 `remote_user`；
- `become_method [method]`：设置权限升级方式；
- `check [bool]`：打开检查模式；
- `diff [bool]`：打开 `diff` 模式；
- `timeout [integer]`：设置任务超时（秒，`0` 关闭超时）；
- `help [command/module]`：显示命令或模组的帮助信息；
- `exit`：退出 `ansible-console`。


## 常用选项

{{#include ansible.md:32:42}}
- `--step`，一次运行一步：每项运行前要进行确认；
{{#include ansible.md:43:46}}
{{#include ansible.md:48:52}}
{{#include ansible.md:56:63}}
{{#include ansible.md:67:68}}


## 命令行参数


- `host-pattern`，仓库中某组别的名字、一种类 shell 的在仓库中的全局主机选取，或以逗号分隔的二者任意组合。


{{#include ansible.md:70:}}
