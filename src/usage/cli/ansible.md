# `ansible`

定义和运行针对一组主机的单个任务 playbook。

## 简介

```console
usage: ansible [-h] [--version] [-v] [-b] [--become-method BECOME_METHOD]
            [--become-user BECOME_USER]
            [-K | --become-password-file BECOME_PASSWORD_FILE]
            [-i INVENTORY] [--list-hosts] [-l SUBSET] [-P POLL_INTERVAL]
            [-B SECONDS] [-o] [-t TREE] [--private-key PRIVATE_KEY_FILE]
            [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT]
            [--ssh-common-args SSH_COMMON_ARGS]
            [--sftp-extra-args SFTP_EXTRA_ARGS]
            [--scp-extra-args SCP_EXTRA_ARGS]
            [--ssh-extra-args SSH_EXTRA_ARGS]
            [-k | --connection-password-file CONNECTION_PASSWORD_FILE] [-C]
            [-D] [-e EXTRA_VARS] [--vault-id VAULT_IDS]
            [-J | --vault-password-file VAULT_PASSWORD_FILES] [-f FORKS]
            [-M MODULE_PATH] [--playbook-dir BASEDIR]
            [--task-timeout TASK_TIMEOUT] [-a MODULE_ARGS] [-m MODULE_NAME]
            pattern
```

## 描述

是一个简单的工具/框架/API，用于执行 “远端操作”。此命令允许咱们，针对一组主机定义并运行单个任务的 playbook。

## 常用选项

- `--become-method <BECOME_METHOD>`，权限提升方式（`default=sudo`），使用 `ansible-doc -t become -l` 列出有效选项；
- `--become-password-file <BECOME_PASSWORD_FILE>, --become-pass-file <BECOME_PASSWORD_FILE>`，`become` 的口令文件；
- `--become-user <BECOME_USER>`，以该用户身份运行操作（`default=root`）；
- `--connection-password-file <CONNECTION_PASSWORD_FILE>, --conn-pass-file <CONNECTION_PASSWORD_FILE>`，连接的口令文件；
- `--list-hosts`，输出匹配主机的列表；不执行任何其他操作；
- `--playbook-dir <BASEDIR>`，由于该工具不使用 playbook，因此可将其用作替代的 playbook 目录。这将为许多功能设置相对路径，包括 `roles/`、`group_vars/` 等；
- `--private-key <PRIVATE_KEY_FILE>, --key-file <PRIVATE_KEY_FILE>`，使用此文件来认证连接；
- `--scp-extra-args <SCP_EXTRA_ARGS>`，指定仅传递给 `scp` 的额外参数（如 `-l`）；
- `--sftp-extra-args <SFTP_EXTRA_ARGS>`，指定仅传递给 `sftp` 的额外参数（如 `-f`、`-l`）；
- `--ssh-common-args <SSH_COMMON_ARGS>`，指定传递给 `sftp`/`scp`/`ssh` 的公共参数（如 `ProxyCommand`）；
- `--ssh-extra-args <SSH_EXTRA_ARGS>`，指定仅传递给 `ssh` 的额外参数（如 `-R`）；
- `--task-timeout <TASK_TIMEOUT>`，设置任务超时限制（秒），必须为正整数；
- `--vault-id`，要使用的保险库标识。该参数可指定多次；
- `--vault-password-file, --vault-pass-file`，保险库口令文件；
- `--version`，显示程序的版本号、配置文件位置、所配置的模组搜索路径、模组位置、可执行文件位置并退出；
- `-B <SECONDS>`，异步运行，`X` 秒后失败（`default=N/A`）；
- `-C, --check`，不做任何改变，而是尝试预测可能发生的一些变化；
- `-D, --diff`，更改（小）文件和模板时，显示这些文件的差异；与 `--check` 一起使用效果极佳；
- `-J, --ask-vault-password, --ask-vault-pass`，询问保险库口令；
- `-K, --ask-become-pass`，询问权限提升口令；
- `-M, --module-path`，添加以冒号分隔的路径，作为模组库（`default={{ ANSIBLE_HOME ~ "/plugins/modules:/usr/share/ansible/plugins/modules" }}`）。此参数可指定多次；
- `-P <POLL_INTERVAL>, --poll <POLL_INTERVAL>`，如果使用 `-B` 选项，则设置轮询间隔（`default=15`）；
- `-T <TIMEOUT>, --timeout <TIMEOUT>`，覆盖连接超时，以秒为单位（默认值取决于连接方式）；
- `-a <MODULE_ARGS>, --args <MODULE_ARGS>`，以空格分隔的 `k=v` 格式： `-a 'opt1=val1 opt2=val2'`，或 JSON 字符串： `-a '{"opt1"： "val1", "opt2"： "val2"}'` 形式的该操作的选项；
- `-b, --become`，以 `become` 运行操作（并不意味着密码提示符）；
- `-c <CONNECTION>, --connection <CONNECTION>`，要使用的连接类型（`default=ssh`）；
- `-e, --extra-vars`，以 `key=value` 方式， 或文件名前添加了 `@` 的 YAML/JSON 方式，设置一些额外变量。此参数可指定多次；
- `-f <FORKS>, --forks <FORKS>`，指定要使用的并行进程数（`default=5`）；
- `-h, --help`，打印此帮助消息并退出；
- `-i, --inventory`，指定仓库主机路径，或逗号分隔的主机列表。`--inventory-file` 选项已被弃用。该参数可指定多次；
- `-k, --ask-pass`，询问连接口令；
- `-l <SUBSET>, --limit <SUBSET>`，将选定主机进一步限制为额外模式；
- `-m <MODULE_NAME>, --module-name <MODULE_NAME>`，要执行的操作名称（`default=command`）；
- `-o, --one-line`，压缩输出；
- `-t <TREE>, --tree <TREE>`，记录日志输出到此目录；
- `-u <REMOTE_USER>, --user <REMOTE_USER>`，以该用户身份连接（`default=None`）；
- `-v, --verbose`，会导致 Ansible 打印更多调试信息。添加多个 `-v` 会增加调试信息的冗余度，内置插件目前最多会评估到 `-vvvvv`。 开始时的合理级别是 `-vvv`，连接的调试则可能需要 `-vvvv`。可以多次指定此参数；

## 环境

可以指定以下环境变量。

- `ANSIBLE_INVENTORY` - 覆盖默认的 `ansible` 仓库文件；
- `ANSIBLE_LIBRARY` - 覆盖默认的 `ansible` 模组库路径；
- `ANSIBLE_CONFIG` - 覆盖默认的 `ansible` 配置文件。

`ansible.cfg` 中的大多数选项，都有更多可用选项。


## 文件

- `/etc/ansible/hosts` - 默认的仓库文件；
- `/etc/ansible/ansible.cfg` - 若存在，就会用到的配置文件；
- `~/.ansible.cfg` - 用户配置文件，会覆盖存在的默认配置。
