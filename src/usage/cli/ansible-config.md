# `ansible-config`

查看 `ansible` 的配置。

## 简介

```console
usage: ansible-config [-h] [--version] [-v] {list,dump,view,init} ...
```

## 描述

配置命令行类。


## 常用选项

{{#include ansible.md:46}}
{{#include ansible.md:60}}
{{#include ansible.md:68}}


**操作**

+ `list`，列出并输出可用的配置；
    - `--format <FORMAT>, -f <FORMAT>`，列表的输出格式；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。
+ `dump`，显示当前设置，若有指定则合并 `ansible.cfg`；
    - `--format <FORMAT>, -f <FORMAT>`，转储的输出格式；
    - `--only-changed, --changed-only`，只显示与默认配置不同的配置；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

+ `view`，显示当前配置文件；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

+ `init`，创建初始配置。
    - `--disabled`，在所有条目前添加注释字符，以禁用他们；
    - `--format <FORMAT>, -f <FORMAT>`，转储的输出格式；
    - `-c <CONFIG_FILE>, --config <CONFIG_FILE>`，配置文件的路径，默认依优先顺序找到的首个文件；
    - `-t <TYPE>, --type <TYPE>`，筛选到某个指定的插件类型。

{{#include ansible.md:70:72}}
{{#include ansible.md:76:78}}


## 文件


{{#include ansible.md:84:}}


（End）


