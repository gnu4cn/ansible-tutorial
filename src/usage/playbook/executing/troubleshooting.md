# 执行 playbook 以排除故障

咱们在测试新 play 或调试 playbook 时，咱们可能需要多次运行同一 play。为了提高这样做的效率，Ansible 提供了两种执行 playbook 的方式：`start-at-task` 与步骤模式。


## `start-at-task`

要在某特定任务（通常是上次运行失败的任务）处，开始执行 playbook，请使用 `--start-at-task` 选项。


```yaml
ansible-playbook playbook.yml --start-at-task="install packages"
```

在本例中，Ansible 在名为 `"install packages"` 的任务处，开始执行咱们的 playbook。此特性对那些动态重用的角色或任务（`include_*`）中的任务不生效，请参阅 [比较包含和导入：动态和静态的重用](#比较包含和导入动态和静态重用)。


## 步骤模式

要交互式地执行 playbook，请使用 `--step` 命令行开关。


```yaml
ansible-playbook playbook.yml --step
```

该选项下，Ansible 会在每个任务处停止，并询问是否执行该任务。例如，如果咱们有个名为 `"configure ssh"` 的任务，则该词 playbook 运行会停止并询问。

```console
Perform task: configure ssh (y/n/c):
```

要回答 `"y"` 来执行该任务，回答 `"n"` 来跳过该任务，回答 `"c"` 来退出步骤模式，随后不带询问地执行所有剩余任务。


（End）


