# Ansible playbook

{{#include inventories_building.md:3:7}}

欢迎阅读 Ansible playbook 指南。所谓 playbook， 是 Ansible 用来部署和配置仓库中节点的 YAML 格式的自动化蓝图。本指南将向咱们介绍 playbook，并随后涵盖了一些任务与 play 的不同用例，比如：

- 以提升的权限或不同用户身份执行任务；
- 使用循环对列表中项目，重复执行某些任务；
- 授权 playbook，以在不同机器上执行任务；
- 运行有条件的任务，及使用 playbook 测试，对条件进行评估；
- 使用区块对任务集进行分组。


咱们还能了解到，如何通过使用专辑、创建可重用的文件与角色、包含及导入 playbook，及使用标签运行 playbook 的选定部分等方式，更有效地使用 Ansible playbook。
