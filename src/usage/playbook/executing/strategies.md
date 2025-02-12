# 控制 playbook 的执行：策略及其他

默认情况下，在所有受某个 play 影响的主机上，Ansible 都会在启动下一个任务前，使用 5 个（进程）分叉运行每个任务。若咱们想要更改这种默认行为，咱们可使用别的策略插件、更改分叉数，或使用 `serial` 等几个关键字之一。


## 选取策略

上面讲到的默认行为，即为 [线性策略](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/linear_strategy.html#linear-strategy)。Ansible 提供了其他策略，包括 [调试策略](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_strategy.html#debug-strategy)（另请参阅 [“调试任务”](debuging.md)）和 [自由策略](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/free_strategy.html#free-strategy)，后者允许每台主机以最快速度运行，直到 play 的结束处：


```yaml
- hosts: all
  strategy: free
  tasks:
  # ...
```

如上所示，咱们可为每个 play 选择不同策略，也可在 `ansible.cfg` 中的 `defaults` 小节中，全局设置咱们所偏好的策略：


```ini
[defaults]
strategy = free
```

所有策略都是以 [策略插件](https://docs.ansible.com/ansible/latest/plugins/strategy.html#strategy-plugins) 实现的。请查看每种策略插件的文档，了解其工作原理。


## 设置线程分叉数

若咱们有足够的线程处理能力，并希望使用更多的线程分叉，可在 `ansible.cfg` 中设置该数量：


```ini
[defaults]
forks = 30
```


或在命令行上传递：`ansible-playbook -f 30 my_playbook.yml`。


## 使用关键字控制执行

除策略外，还有几个 Ansible 关键字，也会影响 play 的执行。咱们可使用 `serial` 关键字，设置咱们一次要管理的主机数量、百分比或数量列表。在开始下一批主机之前，Ansible 会在指定数量或百分比的主机上完成该 play。咱们可使用 `throttle` 关键字，限制分配给某个区块或任务的进程数量，the number of workers。使用 `order` 关键字，咱们可以控制 Ansible 如何在一组主机中选择下一要执行的主机。咱们可以使用 `run_once` 关键字，在单个主机上运行某个任务。这些关键字不属于策略。他们是应用到 play、区块或任务的一些指令或选项。


其他影响 play 执行的关键字包括 `ignore_errors`、`ignore_unreachable` 和 `any_errors_fatal`。这些选项在 [playbook 中的错误处理](../using/err_handling.md) 中有详细说明。


### 使用 `serial` 关键字设置批次大小

默认情况下，Ansible 会针对咱们在 `hosts:` 字段中，所设置 [模式](../../patterns.md) 中的所有主机，并行运行各个 play。若咱们打算一次只管理少量机器，例如在滚动更新期间，则可使用 `serial` 关键字，定义 Ansible 单次应管理多少台主机：


```yaml
---
- name: test play
  hosts: all:!win10-133
  serial: 2
  gather_facts: False

  tasks:
    - name: first task
      command: hostname
    - name: second task
      command: hostname
```

在上面的示例中，我们使用 `'all:!win10-133'` 排除了 `'all'` 中的 Windows 主机 `'win10-133'`，剩下 5 台主机，Ansible 会在其中 2 台主机上完全执行该 play（两个任务），然后再执行接下来的 2 台主机，最后执行 1 台主机：


```console
PLAY [test play] *******************************************************************************************************************

TASK [first task] ******************************************************************************************************************
changed: [debian-199]
changed: [almalinux-5]

TASK [second task] *****************************************************************************************************************
changed: [debian-199]
changed: [almalinux-5]

PLAY [test play] *******************************************************************************************************************

TASK [first task] ******************************************************************************************************************
changed: [almalinux-61]
changed: [almalinux-39]

TASK [second task] *****************************************************************************************************************
changed: [almalinux-39]
changed: [almalinux-61]

PLAY [test play] *******************************************************************************************************************

TASK [first task] ******************************************************************************************************************
changed: [almalinux-207]

TASK [second task] *****************************************************************************************************************
changed: [almalinux-207]

PLAY RECAP *************************************************************************************************************************
almalinux-207              : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
almalinux-39               : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
almalinux-5                : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
almalinux-61               : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
debian-199                 : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
