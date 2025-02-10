# 对任务进行调试

Ansible 提供了个任务调试器，这样咱们就可以在执行过程中修复错误，而不用编辑咱们的 playbook，然后再运行一次，看看咱们的改动是否有效。在任务上下文中，咱们有着对该调试器所有功能的访问能力。咱们可以检查或设置变量值、更新模组参数，并以新的变量和参数重新运行该任务。调试器能让咱们解决失败原因，并继续 playbook 的执行。


## 开启调试器

该调试器默认并未开启。若咱们想要在 playbook 执行过程中调用调试器，就必须先启用他。


清使用以下三种方式之一，启用调试器：

- 使用 `debugger` 关键字；
- 在配置文件或某个环境变量中启用，或者；
- 作为一项策略启用。


### 使用 `debugger` 关键字启用调试器

*版本 2.5 中的新特性*。


咱们可使用 `debugger` 关键字，为某个特定 play、角色、区块或任务，启用（或禁用）调试器。在开发或扩展 playbook、play 和角色时，这个选项特别有用。咱们可在新任务或更新的任务上，启用调试器。如果任务失败了，咱们可以有效地修复错误。`debugger` 关键字接受五个值：


| 值 | 结果 |
| :-- | :-- |
| `always` | 无论结果如何，始终调用调试器。|
| `never` | 无论结果如何，绝不调用调试器。 |
| `on_failed` | 仅在任务失败时调用调试器。|
| `on_unreachable` | 仅在主机不可达时调用调试器。 |
| `on_skipped` | 仅在任务被跳过时才调用调试器。 |


当咱们使用 `debugger` 关键字时，咱们指定的值，会覆盖任何启用或禁用调试器的全局配置。若咱们在多个层级，比如同时在某个角色及某个任务上，定义了 `debugger`，那么 Ansible 会以最细粒度的定义为重。在 play 或角色级别的定义，会应用到该 play 或角色中的所有区块和任务，除非这些任务指定了不同值。区块级别的定义，会覆盖 play 或角色级别的定义，并适用于该区块中的所有任务，除非这些任务指定了不同值。任务层级的定义，会始终应用于该任务；他会覆盖区块、play 或角色层级的定义。

### 使用 `debugger` 示例

在某个任务上设置 `debugger` 关键字的示例：


```yaml
    - name: Execute a command
      ansible.builtin.command: "false"
      debugger: on_failed
```


在某个 play 中设置 `debugger` 关键字的示例：


```yaml
---
- hosts: webservers
  gather_facts: no
  debugger: on_skipped

  tasks:
    - name: Execute a command
      ansible.builtin.command: "true"
      when: False
```


在多个层级设置 `debugger` 关键字的示例：

```yaml
---
- hosts: webservers
  gather_facts: no
  debugger: never

  tasks:
    - name: Execute a command
      ansible.builtin.command: "false"
      debugger: on_failed
```


在本例中，调试器在 play 层级被设置为 `never`，在任务层级被设置为 `on_failed`。如果该任务失败，Ansible 就会调用调试器，因为任务的定义会覆盖其父 play 的定义。


### 在配置文件或环境变量中启用调试器

*版本 2.5 中的新特性*。

以 `ansible.cfg` 中的一项设置，或一个环境变量，咱们可全局启用任务调试器。该设置的唯一选项为 `True` 或 `False`。若咱们将该配置选项或环境变量设置为 `True`，那么 Ansible 默认会在任务失败时，运行调试器。


要在 `ansible.cfg` 中启用任务调试器，请将下面这个设置，添加到 `[defaults]` 小节：


```ini
[defaults]
enable_task_debugger = True
```

要以环境变量启用任务调试器，请在运行咱们的 playbook 时传递该下面这个变量：

```console
ANSIBLE_ENABLE_TASK_DEBUGGER=True ansible-playbook -i hosts site.yml
```

在咱们全局性地启用调试器后，每个失败任务都会调用调试器，除非角色、play、区块或任务，显式地禁用了调试器。若咱们需要对触发调试器的条件，更细粒度的控制，就要使用 `debugger` 关键字。

### 以策略方式启用调试器

如果咱们运行的是老旧 playbook 或角色，就可能会看到作为 [策略](https://docs.ansible.com/ansible/latest/plugins/strategy.html#strategy-plugins) 启用的调试器。咱们可在 play 级别、`ansible.cfg` 中，或以环境变量 `ANSIBLE_STRATEGY=debug` 中这样做。例如：


```yaml
- hosts: test
  strategy: debug

  tasks:
  ...
```


或在 `ansible.cfg` 中：

```ini
[defaults]
strategy = debug
```

> **注意**：这种向后兼容的方式，与 2.5 之前的 Ansible 版本匹配，可能会在未来的版本中移除。


## 解决调试器中的错误


Ansible 调用了调试器后，咱们可以使用七条 [调试器命令](#可用的调试命令)，来解决 Ansible 遇到的错误。请看下面这个示例 playbook，他定义了 `var1` 这个变量，但在任务中错误地使用了未定义的 `wrong_var` 这个变量。

```yaml
---
- hosts: dbservers
  gather_facts: no
  debugger: on_failed

  vars:
    var1: value1

  tasks:
    - name: Use a wrong variable
      ansible.builtin.ping: data={{ wrong_var }}
```

若咱们运行这个 playbook，那么当那个任务失败时，Ansible 会调用调试器。在调试的提示符下，咱们可以更改模组参数或变量，然后再次运行任务。

```console
PLAY ***************************************************************************

TASK [wrong variable] **********************************************************
fatal: [192.0.2.10]: FAILED! => {"failed": true, "msg": "ERROR! 'wrong_var' is undefined"}
Debugger invoked
[192.0.2.10] TASK: wrong variable (debug)> p result._result
{'failed': True,
 'msg': 'The task includes an option with an undefined variable. The error '
        "was: 'wrong_var' is undefined\n"
        '\n'
        'The error appears to have been in '
        "'playbooks/debugger.yml': line 7, "
        'column 7, but may\n'
        'be elsewhere in the file depending on the exact syntax problem.\n'
        '\n'
        'The offending line appears to be:\n'
        '\n'
        '  tasks:\n'
        '    - name: wrong variable\n'
        '      ^ here\n'}
[192.0.2.10] TASK: wrong variable (debug)> p task.args
{u'data': u'{{ wrong_var }}'}
[192.0.2.10] TASK: wrong variable (debug)> task.args['data'] = '{{ var1 }}'
[192.0.2.10] TASK: wrong variable (debug)> p task.args
{u'data': '{{ var1 }}'}
[192.0.2.10] TASK: wrong variable (debug)> redo
ok: [192.0.2.10]

PLAY RECAP *********************************************************************
192.0.2.10               : ok=1    changed=0    unreachable=0    failed=0
```

在调试器中将任务参数，修改为使用 `var1` 而不是 `wrong_var`，就令到该任务成功运行。


## 可用的调试命令

咱们可在调试提示符下，使用以下七条命令：


| 命令 | 简写 | 操作 |
| :-- | :-- | :-- |
| `print` | `p` | 打印出有关该任务的信息。 |
| `task.args[key] = value` | 没有简写。 | 更新模组参数。 |
| `task_vars[key] = value` | 没有简写。 | 更新任务变量（接下来咱们必须执行 `update_task`）。 |
| `update_task` | `u` | 使用更新后的任务变量，重新创建任务。 |
| `redo` | `r` | 再次运行该任务。 |
| `continue` | `c` | 继续执行，开始下一任务。|

更多详情，请参阅下面的单独说明及示例。


### `print` 命令

`print *task/task.args/task_vars/host/result*` 会打印任务有关的信息。

```console
[192.0.2.10] TASK: install package (debug)> p task
TASK: install package
[192.0.2.10] TASK: install package (debug)> p task.args
{u'name': u'{{ pkg_name }}'}
[192.0.2.10] TASK: install package (debug)> p task_vars
{u'ansible_all_ipv4_addresses': [u'192.0.2.10'],
 u'ansible_architecture': u'x86_64',
 ...
}
[192.0.2.10] TASK: install package (debug)> p task_vars['pkg_name']
u'bash'
[192.0.2.10] TASK: install package (debug)> p host
192.0.2.10
[192.0.2.10] TASK: install package (debug)> p result._result
{'_ansible_no_log': False,
 'changed': False,
 u'failed': True,
 ...
 u'msg': u"No package matching 'not_exist' is available"}
 ```


### 更新任务参数命令

`task.args[*key*] = *value*` 会更新某个模组的参数。下面这个示例 playbook 有着无效的软件包名称。


```yaml
---
- hosts: dbservers
  strategy: debug
  gather_facts: true

  vars:
    pkg_name: not_exist
  tasks:
    - name: Install a package
      ansible.builtin.dnf: name={{ pkg_name }}
```

当咱们运行这个 playbook 时，那个无效软件包名称会引发一个错误，Ansible 就会调用调试器。咱们可通过查看并随后更新模组参数，修复这个软件包名称。

```console
[192.0.2.10] TASK: install package (debug)> p task.args
{u'name': u'{{ pkg_name }}'}
[192.0.2.10] TASK: install package (debug)> task.args['name'] = 'bash'
[192.0.2.10] TASK: install package (debug)> p task.args
{u'name': 'bash'}
[192.0.2.10] TASK: install package (debug)> redo
```

在咱们更新模组参数后，要使用 `redo` 命令以新参数再次运行该任务。


### 更新变量命令

`task_vars[*key*] = *value*` 会更新 `task_vars`。咱们可通过查看并更新任务变量，而非模组参数，修复上述 playbook。


```console
[192.0.2.10] TASK: install package (debug)> p task_vars['pkg_name']
u'not_exist'
[192.0.2.10] TASK: install package (debug)> task_vars['pkg_name'] = 'bash'
[192.0.2.10] TASK: install package (debug)> p task_vars['pkg_name']
'bash'
[192.0.2.10] TASK: install package (debug)> update_task
[192.0.2.10] TASK: install package (debug)> redo
```

在咱们更新任务变量后，使用 `redo` 重新运行该任务前，必须先使用 `update_task` 加载新的变量。

> **注意**：在 2.5 中，为避免与 `vars()` 这个 python 函数冲突，此命令已从 `vars` 更改为 `task_vars`。


### 更新任务命令

*版本 2.8 中的新特性*。


`u` 或 `update_task` 命令会使用更新后的任务变量，以原始任务数据结构和模板重新创建出该任务。有关使用示例，请参阅 [更新变量命令](#更新变量命令) 条目。


### `redo` 命令

`r` 或 `redo` 命令会再次运行该任务。


### `continue` 命令

`c` 或 `continue` 会继续执行，开始下一任务。


### `quit` 命令

`q` 或 `quit` 命令会推出调试器。该次 playbook 执行会被放弃。


## 调试器如何与 `free` 策略交互


默认 `linear` 策略启用下，Ansible 会在调试器激活时挂起执行，并在咱们键入 `redo` 命令后立即运行所调试的任务。然而，在 `free` 策略启用下，Ansible 不会等待所有主机，而可能会在一台主机上的某个任务失败前，在另一主机上排队等待稍后的任务。在 `free` 策略下，当调试器处于活动状态时，Ansible 不会排队或执行任何任务。不过，所有排队任务都会保留在队列中，并在退出调试器后立即运行。如果咱们使用 `redo` 命令，重新调度了调试器中的某个任务，其他队列任务就可能会在咱们重新调度的任务之前执行。有关策略的更多信息，请参阅 [控制 playbook 的执行：策略及其他](../strategies.md)。


（End）


