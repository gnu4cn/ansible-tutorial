# 异步操作与轮询

默认情况下，Ansible 会同步运行任务，在操作完成前，保持与远端节点的连接打开。这意味着，在某个 playbook 中，每个任务默认都会阻塞下一任务，在当前任务完成前，后续任务不会运行。这种行为可能会带来挑战。例如，某个任务可能会耗费超过 SSH 会话允许的时间，而造成超时问题。或者，咱们可能想要某个长时间运行的进程在后台执行，而同时并发执行其他任务。异步模式允许咱们控制那些长时间运行任务的执行方式。


## 异步的临时任务

**Asychronous ad hoc tasks**


咱们可以 [临时任务](../../cli.md) 方式，在后台执行那些长时间运行的操作。例如，要以 3600 秒的超时（`-B`），且不进行轮询 (`-P`)，在后台异步执行 `long_running_operation`：


```console
ansible -B 600 -P 0 -i playbook_executing/inventory.yml debian-199 -m command -a "ping -c 1000 163.com"
```

要在稍后检查该作业的状态，就要使用 `async_status` 模组，将咱们在后台运行原始作业时，返回的作业 ID 传递给他：


```console
ansible -i playbook_executing/inventory.yml debian-199 -m async_status -a "jid=j60738290022.3357"
```

Ansible 还能以轮询方式，自动检查咱们长时间运行作业的状态。大多数情况下，在两次轮询之间，Ansible 会保持与远端节点的连接。要以 30 分钟时长，每 60 秒轮询一次状态运行：

```console
ansible -B 1800 -P 60 -i playbook_executing/inventory.yml debian-199 -a "ping -c 1000 163.com"
```

轮询模式是种智能模式，因此在轮询开始前，所有作业在任何机器上都会被启动。若咱们想要快速启动咱们的所有作业，就要确保使用足够大的 `--forks` 值。时限（秒）用完 (`-B`) 后，远端节点上的进程将被终止。


异步模式最适合于那些长时间运行的 shell 命令或软件升级。例如，异步地运行 `copy` 模组，就不会执行后台的文件传输。


### 异步的 playbook 任务


[Playbook](../using.md) 也以一种简化的语法，支持了异步模式和轮询。通过在 playbook 中使用异步模式，咱们可避免连接超时，或避免阻塞后续任务。Playbook 中异步模式的行为，取决于 `poll` 的值。


### 避免连接超时：`poll > 0`


如果咱们打算为 playbook 中的某个任务，设置一个较长的超时限制，就要与设置为正值的 `poll` 一起使用 `async`。Ansible 仍会阻塞咱们 playbook 中的下一任务，等待该异步任务完成、失败或超时。不过，该任务将只在超过咱们用 `async` 参数设置的超时限制时，才会超时。


为避免某个任务超时，要指定其最长运行时间，以及咱们想要轮询状态的频率：

```yaml
---
- hosts: webservers
  gather_facts: no
  remote_user: root

  tasks:

  - name: Simulate long running op (15 sec), wait for up to 45 sec, poll every 5 sec
    ansible.builtin.command: /bin/sleep 15
    async: 45
    poll: 5
```

> **注意**：默认的轮询值是由 `DEFAULT_POLL_INTERVAL` 这个设置设定。异步时限没有默认值。如果咱们不使用 `'async'` 关键字，任务就会同步运行，即 Ansible 的默认行为。

> **注意**：某个启用了轮询的异步任务完成时，临时的异步任务缓存文件（默认在 `~/.ansible_async/` 下），便会自动被移除。


### 并发地运行任务：`poll = 0`


若咱们打算并发地运行某个 playbook 中的多个任务，就要与设置为 `0` 的 `poll` 一起使用 `async`。当咱们设置了 `poll: 0` 时，Ansible 会启动该任务，并会在不等待其结果下，立即转到下一个任务。每个异步任务运行到完成、失败或超时（运行到超过 `async` 的值）为止。该次 playbook 运行，会在不回头检查那些异步任务下结束。

要异步地运行某个 playbook：

```yaml
---
- hosts: webservers
  gather_facts: no
  remote_user: root

  tasks:

  - name: Simulate long running op, allow to run for 45 sec, fire and forget
    ansible.builtin.command: /bin/sleep 15
    async: 45
    poll: 0
```

> **注意**：对于那些需要独占锁的操作（如 `yum` 事务），若咱们希望在 playbook 中稍后要运行针对同一资源的其他命令，就不要给这些操作指定 `0` 的轮询值。

> **注意**：在 `poll: 0` 下运行时，Ansible 不会自动清理异步作业缓存文件。咱们需要以 `mode: cleanup` 参数，使用 `async_status 模组手动清理。

若咱们需要某个异步任务的同步点，咱们可注册该异步任务，以获得其任务 ID，然后使用在后面的任务中，使用 `async_status` 模组观察他。例如：

```yaml
    - name: Run an async task
      ansible.builtin.yum:
        name: docker-io
        state: present
      async: 1000
      poll: 0
      register: yum_sleeper

    - name: Check on an async task
      async_status:
        jid: "{{ yum_sleeper.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 100
      delay: 10
```

> **注意**：如果 `async:` 的值不够高，会导致那个 “稍后检查” 任务失败，因为 `async_status:` 正在查找的临时状态文件，将尚未写入或已不存在。

> **注意**：异步的 playbook 任务总是会返回 `changed`。如果任务使用的是某个要求用户以 `changed_when`、`creates` 等，注解修改的模组，则应将这些注释添加到接下来的 `async_status` 任务。

要在限制并发运行任务数量的同时，运行多个异步任务：


```yaml
#####################
# main.yml
#####################
    - name: Run items asynchronously in batch of two items
      vars:
        sleep_durations:
          - 1
          - 2
          - 3
          - 4
          - 5
        durations: "{{ item }}"
      include_tasks: execute_batch.yml
      loop: "{{ sleep_durations | batch(2) | list }}"
```


```yaml
#####################
# execute_batch.yml
#####################
- name: Async sleeping for batched_items
  ansible.builtin.command: sleep {{ async_item }}
  async: 45
  poll: 0
  loop: "{{ durations }}"
  loop_control:
    loop_var: "async_item"
  register: async_results

- name: Check sync status
  async_status:
    jid: "{{ async_result_item.ansible_job_id }}"
  loop: "{{ async_results.results }}"
  loop_control:
    loop_var: "async_result_item"
  register: async_poll_results
  until: async_poll_results.finished
  retries: 30
```

> **译注**：`async_status` 模组确实会有如下输出：

```console
changed: [almalinux-61] => (item={'failed': 0, 'started': 1, 'finished': 0, 'ansible_job_id': 'j553788170089.21001', 'results_file':
 '/home/hector/.ansible_async/j553788170089.21001', 'changed': True, 'async_item': 3, 'ansible_loop_var': 'async_item'})
```


（End）


