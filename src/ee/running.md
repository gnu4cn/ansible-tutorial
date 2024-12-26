# 运行执行环境

使用 `ansible-navigator`，咱们可在命令行上针对 `localhost` 或远端目标运行执行环境。

> **注意**：除 `ansible-navigator` 外，还有其他工具可以运行执行环境。


## 针对 `localhost` 运行

1. 创建一个 `test_localhost.yaml` playbook；


```yaml
{{#include ../../ansible_quickstart/test_localhost.yaml}}
```

2. 在 `postgresql_ee` 执行环境里，运行该 playbook。

```console
ansible-navigator run ansible_quickstart/test_localhost.yaml --execution-environment-image postgresql_ee --mode stdout --pull-policy missing --container-option='--user=0'
```

> **译注**：该命令的输出包含了 `localhost` 的硬件（主板/CPU（指令集、核心数等）/内存/BIOS/磁盘等）、操作系统与内核版本等全部信息。


