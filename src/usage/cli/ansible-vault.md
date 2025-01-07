# `ansible-vault`


Ansible 数据文件的加密/解密实用工具。



## 简介


```console
usage: ansible-vault [-h] [--version] [-v]
                  {create,decrypt,edit,view,encrypt,encrypt_string,rekey}
                  ...
```



## 描述

可以加密 Ansible 用到的任何结构化数据文件。这可以包括 `group_vars/` 或 `host_vars/` 等仓库变量、由 `include_vars` 或 `vars_files` 加载的变量，或在 `ansible-playbook` 命令行中，使用 `-e @file.yaml` 或 `-e @file.json` 传递的变量文件。角色变量与默认值也包括在内！

由于 Ansible 任务、处理程序和其他对象都是数据，因此也可以用保险柜加密。如果咱们不想暴露正在使用的变量，咱们可以对单个任务文件，进行完全加密。


## 常用选项

{{#include ansible.md:46}}
{{#include ansible.md:60}}
{{#include ansible.md:68}}


## 操作

### `create`

在编辑器中创建并打开一个文件，文件关闭时将使用所提供的保险库密文加密；

- `--encrypt-vault-id`，用于加密的保险库 ID（如果提供了多个保险库 ID，则为必填项）；
- `--skip-tty-check`，允许在没有连接 tty 时打开编辑器；
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}

> **译注**：TTY 是 teletype 或 teletypewriter 电传打字机的缩写。

### `decrypt`

使用所提供的保险库密钥，解密提供的文件；


- `--output <OUTPUT_FILE>`，加密或解密的输出文件名；使用 `-` 表示 `stdout`；
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}



### `edit`

在编辑器中打开并解密现有的某个保险库文件，该文件关闭后将再次加密；


- `--output <OUTPUT_FILE>`，加密或解密的输出文件名；使用 `-` 表示 `stdout`；
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}


### `view`


使用用到所提供保险库密钥的寻呼机，打开、解密并查看某个既有的保险库文件；


- `--vault-id`，要使用的保险库标识。该参数可指定多次；
{{#include ansible.md:45}}
{{#include ansible.md:50}}


### `encrypt`

使用所提供的保险库密钥，对提供的文件进行加密；


- `--encrypt-vault-id`，用于加密的保险库 ID（如果提供了多个保险库 ID，则为必填项）；
{{#include ansible-vault.md:62}}
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}

### `encrypt_string`

使用所提供的保险库密钥，对提供的字符串进行加密；

- `--encrypt-vault-id`，用于加密的保险库 ID（如果提供了多个保险库 ID，则为必填项）；
{{#include ansible-vault.md:62}}
- `--show-input`，提示输入要加密的字符串时，不隐藏输入内容；
- `--stdin-name <ENCRYPT_STRING_STDIN_NAME>`，指定 `stdin` 的变量名称；
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}
- `-n, --name`，指定变量名。该参数可指定多次；
- `-p, --prompt`，要加密字符串的提示府。


### `rekey`

用新的密文重新加密已加密的文件时，需要之前的密文。

- `--encrypt-vault-id`，用于加密的保险库 ID（如果提供了多个保险库 ID，则为必填项）；
- `--new-vault-id <NEW_VAULT_ID>`，用于 `rekey` 的新保险库标识；
- `--new-vault-password-file <NEW_VAULT_PASSWORD_FILE>`，用于 `rekey` 的新保险库口令文件；
{{#include ansible.md:44:45}}
{{#include ansible.md:50}}



{{#include ansible.md:70:72}}
{{#include ansible.md:76:}}
