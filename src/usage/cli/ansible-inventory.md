# `ansible-inventory`

显示 Ansible 清单信息，默认使用清单脚本的 JSON 格式。

## 简介

```console
usage: ansible-inventory [-h] [--version] [-v] [-i INVENTORY] [-l SUBSET]
                      [--vault-id VAULT_IDS]
                      [-J | --vault-password-file VAULT_PASSWORD_FILES]
                      [--playbook-dir BASEDIR] [-e EXTRA_VARS] [--list]
                      [--host HOST] [--graph] [-y] [--toml] [--vars]
                      [--export] [--output OUTPUT_FILE]
                      [group]
```

## 描述

用于以 Ansible 视角，显示或转储所配置的仓库。

## 常用选项

- `--export`，执行 `--list` 时，以专为导出而优化，而不是 Ansible 如何处理的精确表示方式呈现；
- `--graph`，创建仓库的图表，如果提供了模式，则必须是有效的组名。他将忽略 `--limit`；
- `--host <HOST>`，输出指定主机的信息，以仓库脚本形式工作。他将忽略 `--limit`；
- `--list`，输出全部主机信息，以仓库脚本形式工作；
- `--output <OUTPUT_FILE>`，执行 `--list` 时，会将仓库发送到某个文件而非屏幕；
{{#include cli.md:282}}
- `--toml`，使用 TOML 格式而非默认的 JSON 格式，在使用 `--graph` 时会被忽略；
- `--vars`，在图表显示中添加 `vars`，除非与 `--graph` 一起使用，否则会被忽略；
{{#include ansible.md:44:46}}
{{#include ansible.md:50}}
{{#include ansible.md:58}}
{{#include ansible.md:60:61}}
{{#include ansible.md:63}}
{{#include ansible.md:68}}
- `-y, --yaml`，使用 YAML 格式而非默认的 JSON 格式，在使用 `--graph` 时会被忽略；


## 参数，arguments

- `group`，仓库中组别的名字，与使用 `--graph` 时相关。


{{#include ansible.md:70:74}}
{{#include ansible.md:76:}}
