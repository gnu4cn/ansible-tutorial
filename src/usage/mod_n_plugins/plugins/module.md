# 模组

模组是 Ansible playbook 的主要组成部分。虽然我们通常不会说 “模组插件”，但模组就是插件的一种型。有关模组与别的插件区别，从开发者视角的一种阐述，请参阅 [Modules and plugins: what is the difference?](https://docs.ansible.com/ansible/latest/dev_guide/developing_locally.html#modules-vs-plugins)。


## 启用模组

通过将某个定制模组放入以下位置之一，咱们便可启用该模组：

- 添加到 `ANSIBLE_LIBRARY` 这个环境变量中的任一目录（与 `$PATH` 一样，`$ANSIBLE_LIBRARY` 也会取一个以冒号分隔的列表）；
- `~/.ansible/plugins/modules`；
- `/usr/share/ansible/plugins/modules`


有关使用本地定制模组的更多信息，请参阅 [添加某个专辑外不模组或插件](https://docs.ansible.com/ansible/latest/dev_guide/developing_locally.html#local-modules)。


## 使用模组

有关在临时任务中使用模组的信息，请参阅 [临时命令简介](../../cli.md)。有关在 playbook 中使用模组的信息，请参阅 [Ansible playbook](../../playbook/about.md)。


（End）

