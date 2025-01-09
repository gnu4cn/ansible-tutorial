# `ansible-playbook`

运行 Ansible playbook，在目标主机上执行定义好的任务。

## 简介

```console
usage: ansible-playbook [-h] [--version] [-v] [--private-key PRIVATE_KEY_FILE]
                     [-u REMOTE_USER] [-c CONNECTION] [-T TIMEOUT]
                     [--ssh-common-args SSH_COMMON_ARGS]
                     [--sftp-extra-args SFTP_EXTRA_ARGS]
                     [--scp-extra-args SCP_EXTRA_ARGS]
                     [--ssh-extra-args SSH_EXTRA_ARGS]
                     [-k | --connection-password-file CONNECTION_PASSWORD_FILE]
                     [--force-handlers] [--flush-cache] [-b]
                     [--become-method BECOME_METHOD]
                     [--become-user BECOME_USER]
                     [-K | --become-password-file BECOME_PASSWORD_FILE]
                     [-t TAGS] [--skip-tags SKIP_TAGS] [-C] [-D]
                     [-i INVENTORY] [--list-hosts] [-l SUBSET]
                     [-e EXTRA_VARS] [--vault-id VAULT_IDS]
                     [-J | --vault-password-file VAULT_PASSWORD_FILES]
                     [-f FORKS] [-M MODULE_PATH] [--syntax-check]
                     [--list-tasks] [--list-tags] [--step]
                     [--start-at-task START_AT_TASK]
                     playbook [playbook ...]
```

## 描述

是运行 *Ansible playbook*，一种配置与多节点部署系统，的工具。更多信息，请参见项目主页 （[https://docs.ansible.com](https://docs.ansible.com)）。


## 常用选项

{{#include ansible.md:32:35}}
- `--flush-cache`，清除仓库中每台主机的事实缓存，the fact cache；
- `--force-handlers`，即使某项任务失败，仍然运行处理程序，run handlers even if a task fails；
{{#include ansible.md:36}}
- `--list-tags`，列出全部可用的标签；
- `--list-tasks`，列出将会执行的全部任务；
{{#include ansible.md:38:40}}
- `--skip-tags`，只运行标签与这些值不匹配的 play 与任务。此参数可指定多次；
{{#include ansible.md:41:42}}
- `--start-at-task <START_AT_TASK>`，在与此名称匹配的任务处启动 playbook；
{{#include ansible-console.md:57}}
- `--syntax-check`，对 playbook 进行一次语法检查，但不会执行他；
{{#include ansible.md:44:46}}
{{#include ansible.md:48:52}}
{{#include ansible.md:54}}
{{#include ansible.md:56:63}}
- `-t, --tags`，只运行标记了这些值的 play 和任务。该参数可指定多次；
{{#include ansible.md:67:68}}


{{#include ansible.md:70:}}


（End）


