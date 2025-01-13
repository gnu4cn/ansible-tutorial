# 循环


Ansible 提供了 `loop`、`with_<lookup>` 和 `until` 关键字，来多次执行某个任务。常用循环的例子，包括使用 [`file` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html#file-module)，更改多个文件与/或目录的所有权，使用 [`user` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html#user-module) 创建多个用户，以及重复某个轮询步骤，直到得出确切结果。

> **注意**：
>
> - 虽然我们（Anisble 项目）是在 Ansible 2.5 中，才将 `loop` 作为一种更简单的完成循环方式添加进来，但我们建议将其用于大多数用例；
>
> - 我们并没有弃用 `with_<lookup>`，在可预见的未来，该语法仍将有效；
>
> - `loop` 和 `with_<lookup>` 是互斥的。尽管将他们嵌套在 `until` 下是可行的，但这会影响每次循环迭代。


## 三种循环的比较

- `until` 的一般用例，与可能失败的任务有关，而 `loop` 和 `with_<lookup>`，则用于重复任务，并略有不同；
- `loop` 和 `with_<lookup>` 将对作为输入数据的列表中，每个条目运行一次任务，而 `until` 将重复运行任务，直到满足某个条件。对于程序员来说，前者属于 “`for` 循环”，后者属于 “`while`/`until` 循环”；
- `with_<lookup>` 关键字依赖于 [查找插件](https://docs.ansible.com/ansible/latest/plugins/lookup.html#lookup-plugins) - 即使 `items` 也是一种查找；
- `loop` 关键字等同于 `with_list`，是简单循环的最佳选择；
- `loop` 关键字不接受字符串作为输入，请参阅 [确保 `loop` 的列表输入：使用查询而非查找](#确保-loop-的列表输入使用查询而非查找)；
- `until` 关键字可接受 “隐式模板化”（无需 `{{ }}`）的 “结束条件”（返回 `True` 或 `False` 的表达式），通常会基于咱们为任务 `register` 的变量；
- `loop_control` 会影响 `loop` 和 `with_<lookup>`，但不会影响 `until`，后者有自己的配套关键字：`retries` 和 `delay`；
- 一般来说，[从 `with_X` 迁移到 `loop`](#从-with_x-迁移到-loop) 中讲到的全部 `with_*` 用法，都可被更新到使用 `loop`；
- 将 `with_items` 改为 `loop` 时要小心，因为 `with_items` 会执行隐式的单层级扁平化。咱们可能需要与 `| flatten(1)` 一起使用 `loop`，来匹配准确的结果。例如，要获得与下面同样输出：

```yaml
with_items:
  - 1
  - [2,3]
  - 4
```

咱们就需要：

```yaml
loop: "{{ [1, [2, 3], 4] | flatten(1) }}"
```

- 任何需要在循环中用到查找的 `with_*` 语句，都不应转换为使用 `loop` 关键字。例如，与其使用：

```yaml
loop: "{{ lookup('fileglob', '*.txt', wantlist=True) }}"
```

那么保持下面这样就更加简洁：

```yaml
with_fileglob: '*.txt'
```

## 使用 `loop`

凡是重复任务，都可以写成对简单字符串列表的标准循环。咱们可在任务中直接定义出列表。


```yaml
    - name: Add several users
      ansible.builtin.user:
        name: "{{ item }}"
        state: absent
        groups: "wheel"
      loop:
         - testuser1
         - testuser2
```

咱们可以将其中的列表，定义在某个变量文件中，或咱们 play 的 `'vars'` 小节中，然后在任务中引用列表名称。


```yaml
loop: "{{ somelist }}"
```

上面的示例等价于：

```yaml
- name: Add user testuser1
  ansible.builtin.user:
    name: "testuser1"
    state: present
    groups: "wheel"

- name: Add user testuser2
  ansible.builtin.user:
    name: "testuser2"
    state: present
    groups: "wheel"
```

咱们可以直接将列表，传递给某些插件的某个参数。大多数软件打包模组（如 `yum` 和 `apt`），都具备这种能力。在可行的情况下，将列表传递给参数，比循环执行任务更好。例如：

```yaml
- name: 最佳的 yum 操作，optimal yum
  ansible.builtin.yum:
    name: "{{ list_of_packages }}"
    state: present

- name: 非最佳的 yum 操作，速度较慢，且可能导致依赖项问题，non-optimal yum, slower and may cause issues with interdependencies
  ansible.builtin.yum:
    name: "{{ item }}"
    state: present
  loop: "{{ list_of_packages }}"
```

请查阅 [模组文档](https://docs.ansible.com/ansible/latest/collections/index_module.html#list-of-module-plugins)，了解是否可将列表，传递给某个特定模组参数。


### 对哈希值列表的迭代

如果咱们有个哈希值列表，那么就可以在循环中引用其中的子键。例如

```yaml
    - name: Add several users
      ansible.builtin.user:
        name: "{{ item.name }}"
        state: present
        groups: "{{ item.groups }}"
      loop:
        - { name: 'testuser1', groups: 'wheel' }
        - { name: 'testuser2', groups: 'root' }
```

在将 [条件](conditionals.md) 与循环结合时，`when: ` 语句会分别处理每个项目。有关示例，请参阅 [带 `when` 的基本条件](conditionals.md)。


### 对字典的迭代

要在字典上循环，请使用 [`dict2items`](filters.md#将字典转化为列表)：

```yaml
    - name: Using dict2items
      ansible.builtin.debug:
        msg: "{{ item.key }} - {{ item.value }}"
      loop: "{{ tag_data | dict2items }}"
      vars:
        tag_data:
          Environment: dev
          Application: payment
```

这里，我们遍历了 `tag_data`，并打印出了其中的键和值。


### 使用循环注册变量


咱们可将某个循环的输出，注册为一个变量。例如


```yaml
    - name: Register loop output as a variable
      ansible.builtin.shell: "echo {{ item }}"
      loop:
        - "one"
        - "two"
      register: echo
```

咱们在某个循环中用到 `register` 后，放入到那个变量中的数据结构，将包含一个 `results` 属性，其为有关模组（本例中为 `ansible.builtin.shell` ）所有响应的一个列表。这不同于在不与循环使用 `register` 时，返回的数据结构。`results` 属性旁边的 `changed`/`failed`/`skipped` 属性，将代表任务的整体状态。如果有一次迭代触发了更改/失败，则 `changed`/`failed` 就为 `true`，而只有当所有迭代都被跳过时，`skipped`才为真。

> **译注**：上面示例中，注册的 `echo` 内容如下。

```json
{{#include ./reg_var_demo.output}}
```


后续为检查结果，而对该注册变量的循环，可能看起来像下面这样：


```yaml
    - name: Fail if return code is not 0
      ansible.builtin.fail:
        msg: "The command ({{ item.cmd }}) did not have a 0 return code"
      when: item.rc != 0
      loop: "{{ echo.results }}"
```

在迭代期间，当前条目的结果，将被放入变量中。


```yaml
- name: Place the result of the current item in the variable
      ansible.builtin.shell: echo "{{ item }}"
      loop:
        - one
        - two
      register: echo
      changed_when: echo.stdout != "one"
```

### 重试任务直至满足条件

*版本 1.4 中新引入*。


咱们可以使用 `until` 关键字重试某项任务，直到特定条件满足为止。下面是个例子：

```yaml
- name: Retry a task until a certain condition is met
      ansible.builtin.shell: /usr/bin/foo
      register: result
      until: result.stdout.find("all systems go") != -1
      retries: 5
      delay: 10
```

该任务会最多运行 5 次，每次尝试之间延迟 10 秒。如果任何一次尝试结果，有着在 `stdout` 中显示的 `"all systems go"`，则任务成功。`retries` 的默认值为 `3`，`delay` 的默认值为 `5`。

要查看单次重试的结果，就要使用 `-vv` 运行该 play。

当咱们用 `until` 运行某个任务，并将结果注册为变量时，注册的变量将包含一个记录了任务重试次数，名为 `"attempts"` 的键。

如果没有指定 `until`，则任务将重试直到任务成功，但最多重试 `retries` 次（2.16 版本新增）。

咱们可以将 `until` 关键字与 `loop` 或 `with_<lookup>` 结合使用。循环中每个元素的任务结果，都被注册在变量中，并可用于 `until` 的条件。下面是个示例：

```yaml
    - name: Retry combined with a loop
      uri:
        url: "https://{{ item }}.ansible.com"
        method: GET
      register: uri_output
      with_items:
      - "galaxy"
      - "docs"
      - "forum"
      - "www"
      retries: 2
      delay: 3
      until: "uri_output.status == 200"
```

> **注意**：当咱们在某个循环中使用 `timeout` 关键字时，他会应用到该任务操作的每次尝试。详情请参阅 [`TASK_TIMEOUT`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#task-timeout)。


### 对仓库的循环

通常情况下，play 本身就是对仓库的一个循环，但有时咱们需要对不同主机做同样事情的某个任务。要对咱们的仓库，或仓库的某个子集，进行循环迭代，可以将常规的 `loop`，与 `ansible_play_batch` 或 `groups` 变量一起使用。

```yaml
    - name: Show all the hosts in the inventory
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ groups['all'] }}"

    - name: Show all the hosts in the current play
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ ansible_play_batch }}"
```

还有个特定查询插件 `inventory_hostnames`，可以这样使用：

```yaml
    - name: Show all the hosts in the inventory
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ query('inventory_hostnames', 'all') }}"

    - name: Show all the hosts matching the pattern, ie all but the group www
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ query('inventory_hostnames', 'all:!app') }}"
```

> **译注**：上述两个示例的输出中，每个远端主机都会出现两次。至于原因为何，尚不得而知。

有关模式的更多信息，请参阅 [模式：选择主机和群组](../../patterns.md)。


## 确保 `loop` 的列表输入：使用查询而非查找

`loop` 关键字需要个列表作为输入，而 `lookup` 关键字默认返回的是个逗号分隔值的字符串。Ansible 2.5 引入了个总是返回一个列表，名为 [`query`](https://docs.ansible.com/ansible/latest/plugins/lookup.html#query) 的新 Jinja2 函数，在使用 `loop` 关键字时，提供了一种更简单的接口，以及查找插件的更可预测的输出。


咱们可以使用 `wantlist=True` 参数，强制 `lookup` 返回一个列表给 `loop`，或者可以使用 `query` 代替。


下面两个示例完成同样的事情。


```yaml
loop: "{{ query('inventory_hostnames', 'all') }}"

loop: "{{ lookup('inventory_hostnames', 'all', wantlist=True) }}"
```


## 给循环添加控制


*版本 2.1 中新引入*。

通过 `loop_control` 关键字，咱们可以对循环进行有效管理。


### 使用 `label` 限制循环的输出


*版本 2.2 中新引入*。

在复杂数据结构上循环时，咱们任务的控制台输出可能会非常多。要限制显示出的输出，就要将 `label` 与 `loop_control` 一起使用。


```yaml
    - name: Create servers
      digital_ocean:
        name: "{{ item.name }}"
        state: present
      loop:
        - name: server1
          disks: 3gb
          ram: 15Gb
          network:
            nic01: 100Gb
            nic02: 10Gb
            ...
      loop_control:
        label: "{{ item.name }}"
```

此任务的输出，将只显示每个 `item` 的 `name` 字段，而不是多行 `{{ item }}` 变量的全部内容。

> **注意**：这是为了使控制台输出更可读，而不是保护敏感数据。如果 `loop` 中有敏感数据，请在任务中设置 `no_log: true`，以防止泄露。
>
> **译注**：设置了 `no_log: true` 后，控制台输出将不再显示 `item` 信息，取而代之的是 `item=None`。


### 在循环内暂停


*版本 2.2 中新引入*。


要控制任务循环中，每个项目执行之间的间隔时间（以秒为单位），请将 `pause` 指令与 `loop_control` 一起使用。

```yaml
    # main.yml
    - name: Create servers, pause 3s before creating next
      community.digitalocean.digital_ocean:
        name: "{{ item }}"
        state: present
      loop:
        - server1
        - server2
      loop_control:
        pause: 3
```



## 从 `with_X` 迁移到 `loop`
