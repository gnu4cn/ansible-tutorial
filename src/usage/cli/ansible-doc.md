# `ansible-doc`

插件文档工具，plugin documentation tool。

## 简介

```console
usage: ansible-doc [-h] [--version] [-v] [-M MODULE_PATH]
                [--playbook-dir BASEDIR]
                [-t {become,cache,callback,cliconf,connection,httpapi,inventory,lookup,netconf,shell,vars,module,strategy,test,filter,role,keyword}]
                [-j] [-r ROLES_PATH]
                [-e ENTRY_POINT | -s | -F | -l | --metadata-dump]
                [--no-fail-on-errors]
                [plugin ...]
```


## 描述

显示安装在 Ansible 库中的模组信息。他会显示一个插件的简短列表，及这些插件的简短描述，提供这些插件 `DOCUMENTATION` 字符串的打印输出，还能创建可被粘贴到某个 playbook 的一个简短 “片段”。


## 常用选项


- `--metadata-dump`，**仅供内部使用** 转储所有条目的 JSON 元数据，而忽略其他选项；
- `--no-fail-on-errors`，**仅供内部使用** 仅用于 `--metadata-dump`. 不因出错而运行失败。而是在 JSON 中报告错误信息；
{{#include ansible.md:37}}
{{#include ansible.md:46}}
- `-F, --list_files`，显示插件名称及各自的源文件，不带摘要（表示 `-list`）。提供的参数将用于筛选，可以是命名空间，或完整的集合名称；
{{#include ansible.md:52}}
- `-e <ENTRY_POINT>, --entry-point <ENTRY_POINT>`，选取角色，`roles`，的入口点。
{{#include ansible.md:60}}
- `-j, --json`，修改输出为 JSON 格式；
- `-l, --list`，列出可用的插件。提供的参数将用于筛选，可以是命名空间，或完整集合名称；
- `-r, --roles-path`，包含角色的目录路径。此参数可指定多次；
- `-s, --snippet`，显示这些插件类型：`inventory`、`lookup`、`module`，的 playbook 代码片段；
- `-t <TYPE>, --type <TYPE>`，选择插件类型（默认为 `module`）。可用的插件类型有：`('become', 'cache', 'callback', 'cliconf', 'connection', 'httpapi', 'inventory', 'lookup', 'netconf', 'shell', 'vars', 'module'、'strategy'、'test'、'filter'、'role'、'keyword')`；
{{#include ansible.md:68}}


{{#include ansible.md:70:72}}


{{#include ansible.md:75:78}}


{{#include ansible.md:81}}

{{#include ansible.md:84:}}


（End）


