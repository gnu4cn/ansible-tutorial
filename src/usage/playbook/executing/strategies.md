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


## 设置分叉数

若咱们有足够的进程处理能力，并希望使用更多的进程分叉，可在 `ansible.cfg` 中设置该数量：


```ini
[defaults]
forks = 30
```


或在命令行上传递：`ansible-playbook -f 30 my_playbook.yml`。


## 使用关键字控制执行

除策略外，还有几个 Ansible 关键字，也会影响 play 的执行。咱们可使用 `serial` 关键字，设置咱们一次要管理的主机数量、百分比或数量列表。在开始下一批主机之前，Ansible 会在指定数量或百分比的主机上完成该 play。咱们可使用 `throttle` 关键字，限制分配给某个区块或任务的工作进程数量，the number of workers。使用 `order` 关键字，咱们可以控制 Ansible 如何在一组主机中选择下一要执行的主机。咱们可以使用 `run_once` 关键字，在单个主机上运行某个任务。这些关键字不属于策略。他们是应用到 play、区块或任务的一些指令或选项。


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

> **注意**：以 `serial` 关键字，设置了批次大小，会将 Ansible 失败范围改为该批次大小，而不是整个主机列表。咱们可使用 `ignore_unreachable` 或 `max_fail_percentage` 选项，修改这一行为。


咱们也可用 `serial` 键字指定一个百分比。Ansible 会将该百分比应用到 play 中的主机总数，以确定出每次要传递的主机数量：


```yaml
---
- name: test play
  hosts: all:!win10-133
  serial: "30%"
```

如果主机数量未被每次传递数量整除，那么最后一次传递，将包含剩余部分。在本例中，如果模式 `all:!win10-133` 中有 20 台主机，那么第一批将包含 6 台主机，第二批将包含 6 台，第三批将包含 6 台，最后一批将包含 2 台主机。

咱们还可将批次大小，指定为一个列表。例如：


```yaml
---
- name: test play
  hosts: all:!win10-133
  serial:
    - 1
    - 2
    - 2
```

在上面的示例中，第一批将包含一台主机，下一批将包含 2 台主机，（如还剩有主机），接下来的每一批都将包含 2 台主机或所有剩余的主机（如剩余的主机少于 2 台）。

咱们可将多个批次大小，以百分比方式列出：

```yaml
---
- name: test play
  hosts: all:!win10-133
  serial:
    - "20%"
    - "40%"
    - "100%"
```

咱们还可以将这些值混用与匹配：


```yaml
---
- name: test play
  hosts: all:!win10-133
  serial:
    - 1
    - 2
    - "20%"
```


> **注意**：不论百分比有多小，每次传递的主机数量将总是 1 或更多。


### 以 `throttle` 关键字限制执行


`throttle` 关键字可限制某个特定任务的工作进程数量。他可在区块与任务级别设置。使用 `throttle` 可限制那些 CPU 密集型，或要与某个存在限速 API 交互的任务：


```yaml
  tasks:
  - command: /path/to/cpu_intensive_command
    throttle: 1
```

在咱们已经限制了进程分叉数，或要并行执行的机器数时，咱们可以使用 `throttle` 减少工作进程数量，但不能增加。换句话说，要产生效果，在三者同时使用时，咱们的 `throttle` 设置必须低于 `forks` 或 `serial` 设置。


### 根据仓库对执行排序


`order` 关键字控制了主机的运行顺序。顺序的可能值有：


- `inventory`
(默认值）由仓库为所请求的选择，提供的顺序（见下文注意事项）；

- `reverse_inventory`
与上面的相同，但逆转了返回的列表；

- `sorted`
按主机名的字母排序；

- `reverse_sorted`
按名字的字母倒序排列；

- `shuffle`
每次运行时随机排序。


> **注意**：`'inventory'` 这种顺序，并不等同于在仓库源文件中，所定义的主机/分组顺序，而是 ”自编译后清单所返回的某个选择的顺序"。这是个向后兼容选项，尽管可以重现，但通常无法预测。由于仓库的性质、主机模式、限制、仓库插件及允许多种来源的能力等因素，几乎不可能返回这样的顺序。对于一些简单情形，这可能会与文件定义的顺序相匹配，但这并不能保证。


### 使用 `run_once` 在单台机器上运行


如果咱们想要某个任务，只在一批主机中的第一台主机上运行，就要在该任务上设置 `run_once` 为 `true`：


```yaml
---
- name: test play
  hosts: all:!win10-133
  gather_facts: False

  tasks:
    - name: first task
      command: hostname
      run_once: true
```

Ansible 会在当前批次的第一台主机上执行这个任务，**并将所有结果和事实，应用到同一批次的所有主机上**。这种方法类似于应用一项条件到某个任务，例如：


```yaml
    - command: /opt/application/upgrade_db.py
      when: inventory_hostname == webservers[0]
```

不过在 `run_once` 下，任务结果会应用到所有主机。要在特定主机而不是批次中第一台主机上运行该任务，就要委派该任务：


```yaml
    - command: /opt/application/upgrade_db.py
      run_once: true
      delegate_to: web01.example.org
```

一如 [委派](../using/delegation.md) 那样，该操作将在那台受委派的主机上执行，但有关信息仍是该任务中，原始主机的信息。


> **注意**：在 `serial` 关键字一起使用时，标记为 `run_once` 的任务，将在 *每个* 序列批次中的一台主机上运行。若要该任务在无论序列模式为何下，必须都只运行一次，就要使用： `inventory_hostname == ansible_play_hosts_all[0]` 的结构。

> **注意**：任意条件（也就是 `when:`），将使用 `'first host'` 的变量，决定该任务是否要运行，而不会测试其他主机。

> **注意**：若咱们想要避免给所有主机设置事实的这种默认行为，就要这个特定任务或区块，设置 `delegate_facts: True`。


（End）


