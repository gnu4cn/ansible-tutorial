# 执行的诀窍

下面这些技巧适用于使用 Ansible，而不是使用 Ansible 的工件。


## 要使用执行环境

要使用称为 [“执行环境”](../../ee.md) 的可迁移容器映像，降低复杂性。


## 先在暂存环境中尝试

在生产环境中推出变更前，在暂存环境中测试变更，始终是个好主意。两种环境的规模无需一样，且咱们可使用组变量，控制环境之间的差异。咱们还可以在暂存环境中使用 `--syntax-check` 命令行开关，检查任何的语法错误，比如在下面的示例中：


```console
ansible-playbook --syntax-check
```

## 以批次模式更新

使用 `serial` 关键字控制在该批次中一次更新多少台机器。请参阅 [控制任务于何处运行：委派及本地操作](../playbook/using/delegation.md)。


## 处理操作系统及发行版的差异


组变量文件会与 `group_by` 模组一起工作，帮助 Ansible 在需要不同设置、软件包和工具的一系列操作系统和发行版中执行。`group_by` 模组会创建出匹配特定条件的动态主机组。该组无需在仓库文件中定义。这种方法可让咱们在不同操作系统或发行版上，执行不同任务。


比如，下面这个 play 会根据操作系统名称，将所有系统分类为一些动态分组：

```yaml
- name: Talk to all hosts just so we can learn about them
  hosts: all
  tasks:

    - name: Classify hosts depending on their OS distribution
      ansible.builtin.group_by:
        key: os_{{ ansible_facts['distribution'] }}
```

后续 play 就可以使用这些组，作为 `hosts` 行上的模式了，如下所示：


```yaml
- hosts: os_CentOS
  gather_facts: False
  tasks:

    # Tasks for CentOS hosts only go in this play.
    - name: Ping my CentOS hosts
      ansible.builtin.ping:
```


咱们还可以在组变量文件中，添加一个特定于组的设置。在下面的示例中，CentOS 机器获得的 `asdf` 值为 `'42'`，而别的机器则得到的是 `'10'`。咱们还可以使用组变量文件，将一些角色应用到这些系统，以及为这些系统设置一些变量。


```yaml
---
# file: group_vars/all
asdf: 10

---
# file: group_vars/os_CentOS.yml
asdf: 42
```


> **注意**：这三个名称都必须匹配：由 `group_by` 任务创建的名字、后续 play 中模式的名字，以及组变量文件的名字。


若咱们只需要特定于操作系统的一些变量，而不需要任务，咱们也可通过 `include_vars` 运用这样同样的设置：


```yaml
- name: Use include_vars to include OS-specific variables and print them
  hosts: all
  tasks:

    - name: Set OS distribution dependent variables
      ansible.builtin.include_vars: "os_{{ ansible_facts['distribution'] }}.yml"

    - name: Print the variable
      ansible.builtin.debug:
        var: asdf
```


这会从 `group_vars/os_CentOS.yml` 文件拉取变量。

（End）


