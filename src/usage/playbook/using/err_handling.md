# Playbook 中的错误处理

当 Ansible 收到某个命令返回的非零代码，或某个模组的失败时，默认情况下会在该主机上停止执行，并在其他主机上继续执行。不过，在某些情况下，咱们可能需要别的行为。有时，非零返回代码表示成功。有时，咱们会想要一台主机上的失败，停止所有主机上的执行。Ansible 提供了处理这些情况的工具与设置，帮助咱们得到咱们想要的行为、输出和报告。

## 忽略失败的命令

默认情况下，当某个任务于某台主机上失败时，Ansible 就会在该主机上停止执行任务。咱们可以使用 `ignore_errors`，继续执行任务。

```yaml
    - name: Do not count this as a failure
      ansible.builtin.command: /bin/false
      ignore_errors: true
```

`ignore_errors` 指令只会在该任务能运行，并返回 `'failed'` 值时起作用。他不会让 Ansible 忽略未定义变量错误、连接失败、执行问题（如缺少软件包）或语法错误等。


## 忽略主机不可达错误

*版本 2.7 中的新特性*。

使用 `ignore_unreachable` 关键字，咱们就可以忽略因主机实例 `'UNREACHABLE'` 而导致的任务失败。Ansible 会忽略任务错误，而继续对不可达主机执行后续任务。例如，在任务级别：

```yaml
    - name: This executes, fails, and the failure is ignored
      ansible.builtin.command: /bin/true
      ignore_unreachable: true

    - name: This executes, fails, and ends the play for this host
      ansible.builtin.command: /bin/true
```

以及在 playbook 层面：

```yaml
- hosts: all
  ignore_unreachable: true

  tasks:
    - name: This executes, fails, and the failure is ignored
      ansible.builtin.command: /bin/true

    - name: This executes, fails, and ends the play for this host
      ansible.builtin.command: /bin/true
      ignore_unreachable: false
```

## 重置不可达主机

如果 Ansible 无法连接到某台主机，他会将该主机标记为 `'UNREACHABLE'`，并将其从该次运行的活动主机列表中移除。咱们可以使用 `meta: clear_host_errors` 元任务，重新激活所有主机，以便后续任务可以再次尝试连接他们。


## 处理程序与失败

Ansible 会在每个 play 结束时，运行 [处理程序](handlers.md)。如果某个任务通知了一个处理程序，但 play 中的另一任务稍后失败了，默认情况下处理程序就 *不会* 在该主机上运行，这可能会使该主机处于意外状态。例如，某个任务可能会更新某个配置文件，并通知处理程序重新启动某个服务。如果同一 play 中的某个任务稍后失败了，则配置文件可能已被更改，但对应服务却不会重新启动。

你可以使用 `--force-handlers` 命令行选项、在 play 中加入 `force_handlers.True`，或者在 `ansible.cfg` 中加入 `force_handlers = True`，改变这种行为。强制使用处理程序时，Ansible 会在所有主机上，运行全部通知到的处理程序，即使有任务失败的主机也不例外。(请注意，某些错误仍可能导致处理程序无法运行，例如主机变得不可达。）


## 定义失败

Ansible 允许咱们使用 `failed_when` 条件，定义各个任务中 “失败” 的含义。与 Ansible 中的所有条件一样，多个 `failed_when` 条件的列表，会以隐式的 `and` 连接，这意味着只有在满足 *所有* 条件时，任务才会失败。如果咱们想在满足任一条件时触发失败，则必须在字符串中，使用显式的 `or` 运算符定义条件。

咱们可以通过在某条命令的输出中，检索某个单词或短语来检查是否失败：

```yaml
    - name: Fail task when the command error output prints FAILED
      ansible.builtin.command: /usr/bin/example-command -x -y -z
      register: command_result
      failed_when: "'FAILED' in command_result.stderr"
```

或基于返回代码:

```yaml
    - name: Fail task when both files are identical
      ansible.builtin.raw: diff foo/file1 bar/file2
      register: diff_cmd
      failed_when: diff_cmd.rc == 0 or diff_cmd.rc >= 2
```

咱们还可以结合多个失败条件。下面这个任务将在两个条件都为真时失败：

```yaml
    - name: Check if a file exists in temp and fail task if it does
      ansible.builtin.command: ls /tmp/this_should_not_be_here
      register: result
      failed_when:
        - result.rc == 0
        - '"No such" not in result.stderr'
```

如果咱们想要让该任务，在仅满足一个条件时就失败，可将 `failed_when` 的定义改为：

```yaml
      failed_when: result.rc == 0 or "No such" not in result.stderr
```

如果咱们有太多条件，无法整齐地放在一行中时，咱们可以用 `>` 语法，将其分割成一个多行 YAML 值。


```yaml
    - name: example of many failed_when conditions with OR
      ansible.builtin.shell: "./myBinary"
      register: ret
      failed_when: >
        ("No such file or directory" in ret.stdout) or
        (ret.stderr != '') or
        (ret.rc == 10)
```

## 定义 `"changed"`


Ansible 允许你使用 `changed_when` 条件，定义某个特定任务何时 “改变” 了某个远端节点。这样，咱们就可以根据返回代码或输出，决定某个改变是否应在 Ansible 统计中报告，以及是否应触发某个处理程序。与 Ansible 中的所有条件一样，多个 `changed_when` 条件的列表，会以隐式的 `and` 连接，这意味着只有当 *所有* 条件都满足时，该任务才会报告变更。如果咱们想要满足任一条件时就报告变化，则必须在字符串中，使用显式的 `or` 运算符定义条件。例如


```yaml
  tasks:

    - name: Report 'changed' when the return code is not equal to 2
      ansible.builtin.shell: /usr/bin/billybass --mode="take me to the river"
      register: bass_result
      changed_when: "bass_result.rc != 2"

    - name: This will never report 'changed' status
      ansible.builtin.shell: wall 'beep'
      changed_when: False

    - name: This task will always report 'changed' status
      ansible.builtin.command: /path/to/command
      changed_when: True
```

咱们同样可以结合多个条件，来覆盖 `"changed"` 的结果。


```yaml
    - name: Combine multiple conditions to override 'changed' result
      ansible.builtin.command: /bin/fake_command
      register: result
      ignore_errors: True
      changed_when:
        - '"ERROR" in result.stderr'
        - result.rc == 2
```


> **注意**：就像 `when` 一样，这两个条件式无需模板分隔符（`{{ }}`），因为他们是隐含的。


更多的条件语法示例，请参阅 [定义失败](#定义失败)。


## 确保命令和 shell 成功

`command` 和 `shell` 模组，都关心返回代码，因此若咱们有条成功退出代码不为零的命令，就可以这样做：

```yaml
  tasks:
    - name: Run this command and ignore the result
      ansible.builtin.shell: /usr/bin/somecommand || /bin/true
```

## 在所有主机上中止某个 play


有时，咱们会想要单台主机上，或一定比例主机上的某个失败，中止所有主机上的整个 play。咱们可以使用 `any_errors_fatal`，在首个失败发生后，停止整个 play 的执行。要实现更细粒度的控制，咱们可以使用 `max_fail_percentage`，在一定比例主机失败后，终止该次运行。


### 首次出错时中止：`any_errors_fatal`

若咱们设置了 `any_errors_fatal`，且某个任务返回了一个报错，那么 Ansible 就会在当前批次的所有主机上，完成该致命任务，然后停止在所有主机上播放该 play。后续任务和 play 都不会执行。咱们可以通过添加一个救援小节到区块，从致命错误中恢复。咱们可在 play 或区块级别，设置 `any_errors_fatal`。


```yaml
- hosts: somehosts
  any_errors_fatal: true
  roles:
    - myrole

- hosts: somehosts
  tasks:
    - block:
        - include_tasks: mytasks.yml
      any_errors_fatal: true
```

在所有任务都必须 100% 成功，才能继续 playbook 的执行时，咱们就可以使用此功能。例如，如果咱们在多个数据中心的机器上，运行着某项服务，并使用负载均衡，将流量从用户传递到服务，那么咱们就会希望在停止服务进行维护前，禁用所有负载均衡器。为确保禁用负载均衡器任务中的任何失败，都将停止所有其他任务：


```yaml
---
- hosts: load_balancers_dc_a
  any_errors_fatal: true

  tasks:
    - name: Shut down datacenter 'A'
      ansible.builtin.command: /usr/bin/disable-dc

- hosts: frontends_dc_a

  tasks:
    - name: Stop service
      ansible.builtin.command: /usr/bin/stop-software

    - name: Update software
      ansible.builtin.command: /usr/bin/upgrade-software

- hosts: load_balancers_dc_a

  tasks:
    - name: Start datacenter 'A'
      ansible.builtin.command: /usr/bin/enable-dc
```

在此示例中，只有当所有负载均衡器都成功禁用后，Ansible 才会启动前端的软件升级。


### 设置最大失败百分比


默认情况下，只要还有主机未出现失败，Ansible 就会继续执行任务。在某些情况下，比如执行滚动更新时，咱们可能希望在达到一定的故障阈值时，就要中止运行。要做到这一点，咱们可以在某个 play 上，设置最大失败百分比：


```yaml
---
- hosts: webservers
  max_fail_percentage: 30
  serial: 10
```

当咱们将其与 [`serial`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_strategies.html#rolling-update-batch-size) 关键字一起使用时，`max_fail_percentage` 设置就会应用于每个批次。在上面的示例中，如果第一批（或任何一批）服务器中，若 10 台服务器中有 3 台以上出现失败，则其余 play 将被中止。


> **注意**：必须超过而不是等于所设置的百分比。例如，如果 `serial` 设置为 `4`，而咱们希望该任务在 2 个系统失败时中止 play，则应将 `max_fail_percentage` 设置为 `49`，而不是 `50`。


## 以区块方式控制出错

咱们还可以使用区块，定义对任务报错的响应。这种方法类似于许多编程语言中的异常处理。有关详细信息和示例，请参阅 [使用块处理错误](blocks.md#使用区块处理错误)。


（End）


