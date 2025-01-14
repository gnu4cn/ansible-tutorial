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


### 跳出循环


*版本 1.4 中新引入*。


根据 Jinja2 的表达式，要将 `break_when` 指令与 `loop_control` 一起使用，以在某个项目后退出循环。


```yaml
    # main.yml
    - name: Use set_fact in a loop until a condition is met
      vars:
        special_characters: "!@#$%^&*(),.?:{}|<>"
        character_set: "digits,ascii_letters,{{ special_characters }}"
        password_policy: '^(?=.*\d)(?=.*[A-Z])(?=.*[{{ special_characters | regex_escape }}]).{12,}$'
      block:
        - name: Generate a password until it contains a digit, uppercase letter, and special character (10 attempts)
          set_fact:
            password: "{{ lookup('password', '/dev/null', chars=character_set, length=12) }}"
          loop: "{{ range(0, 10) }}"
          loop_control:
            break_when:
              - password is match(password_policy)

        - fail:
            msg: "Maximum attempts to generate a valid password exceeded"
          when: password is not match(password_policy)
```


### 使用 `index_var` 跟踪循环进度


*版本 2.5 中新引入*。

要跟踪咱们在循环中身处何处，就要将 `index_var` 指令与 `loop_control` 结合使用。该指令会指定一个变量名，来包含当前循环的索引。


```yaml
    - name: Count our fruit
      ansible.builtin.debug:
        msg: "{{ item }} with index {{ my_idx }}"
      loop:
        - apple
        - banana
        - pear
      loop_control:
        index_var: my_idx
```

> **注意**：`index_var` 的索引从 `0` 开始。


### 扩展的循环变量

*版本 2.8 中新引入*。


自 Ansible 2.8 开始，咱们可以使用循环控制的 `extended` 选项，获取扩展的循环信息。该选项将暴露出以下信息。


| 变量 | 描述 |
| :-- | :-- |
| `ansible_loop.allitems` | 循环中全部条目的清单。 |
| `ansible_loop.index` | 循环的当前迭代。（从 `1` 开始索引） |
| `ansible_loop.index0` | 循环的当前迭代。（从 `0` 开始索引） |
| `ansible_loop.revindex` | 从循环结束开始的迭代次。（从 `1` 开始索引） |
| `ansible_loop.revindex0` | 从循环结束开始的迭代次。（从 `0` 开始索引） |
| `ansible_loop.first` | 若该次迭代为首次迭代，则为 `True` |
| `ansible_loop.last` | 若该次迭代为末次迭代，则为 `True` |
| `ansible_loop.length` | 循环中条目数 |
| `ansible_loop.previtem` | 循环的前一次迭代条目。第一次迭代时为 `undefined`。 |
| `ansible_loop.nextitem` | 循环的下一次迭代条目。末次迭代时为 `undefined`。 |


```yaml
      loop_control:
        extended: true
```

> **注意**：使用 `loop_control.extended` 时，控制节点会使用更多内存。这是由于 `ansible_loop.allitems` 包含着对每次循环完整循环数据的引用。在 `ansible` 主进程内，对结果进行序列化以在回调插件中显示时，这些引用可能会被解引用，从而导致内存使用量增加。

*版本 1.4 中新引入*。

要禁用 `ansible_loop.allitems` 条目，以减少内存消耗，请设置 `loop_control.extended_allitems：false`。


```yaml
      loop_control:
        extended: true
        extended_allitems: false
```

### 访问咱们 `loop_var` 的名字


*版本 2.8 中新引入*。

自 Ansible 2.8 开始，咱们可以使用 `ansible_loop_var` 变量，获取提供给 `loop_control.loop_var` 的值名字。

对于角色作者来说，在编写允许循环的角色时，可以通过以下方式收集到所需的 `loop_var` 值，而不是指定出该值，for role authors, writing roles that allow loops, instead of dictating the required loop_var value, you can gather the value through the following


```yaml
"{{ lookup('vars', ansible_loop_var) }}"
```

## 嵌套循环

虽然在下面这些示例中，我们使用的是 `loop`，但 `with_<lookup>` 也同样适用。


### 对嵌套列表进行遍历


最简单的 “嵌套” 循环方式，是避免嵌套循环，只需格式化数据即可取得同样结果。咱们可以使用 Jinja2 表达式，遍历复杂列表。例如，某个循环可以与嵌套列表结合，从而模拟出嵌套循环。

```yaml
    - name: Give users access to multiple databases
      community.mysql.mysql_user:
        name: "{{ item[0] }}"
        priv: "{{ item[1] }}.*:ALL"
        append_privs: true
        password: "foo"
      loop: "{{ ['alice', 'bob'] | product(['clientdb', 'employeedb', 'providerdb']) | list }}"
```

### 通过 `include_tasks` 堆叠循环

*版本 2.1 中新引入*。


使用 `include_tasks`，咱们可以嵌套两个循环任务。不过，默认情况下，Ansible 会为每个循环，都设置循环变量 `item`。这意味着内层、嵌套的循环，会覆盖外层循环的 `item` 值。为避免这种情况，咱们可以将 `loop_var` 和 `loop_control` 一起使用，从而为每个循环分别指定变量名。

```yaml
    # main.yml
    - include_tasks: inner.yml
      loop:
        - 1
        - 2
        - 3
      loop_control:
        loop_var: outer_item
```

```yaml
# inner.yml
- name: Print outer and inner items
  ansible.builtin.debug:
    msg: "outer item={{ outer_item }} inner item={{ item }}"
  loop:
    - a
    - b
    - c
```


> **注意**：如果 Ansible 检测到当前循环，使用了某个已定义的变量，他将抛出一个错误，来令到任务失败。


### `util` 与 `loop`


`util` 的条件，将应用于 `loop` 的每个 `item`：

```yaml
    - debug: msg={{item}}
      loop:
        - 1
        - 2
        - 3
      retries: 2
      until: item > 2
```

这将使 Ansible 重试前 2 个项目两次，然后在第 3 次尝试中失败，随后在第 3 个项目的第一次尝试中成功，最终导致整个任务失败。

```console
[started TASK: debug on localhost]
FAILED - RETRYING: [localhost]: debug (2 retries left).Result was: {
    "attempts": 1,
    "changed": false,
    "msg": 1,
    "retries": 3
}
FAILED - RETRYING: [localhost]: debug (1 retries left).Result was: {
    "attempts": 2,
    "changed": false,
    "msg": 1,
    "retries": 3
}
failed: [localhost] (item=1) => {
    "msg": 1
}
FAILED - RETRYING: [localhost]: debug (2 retries left).Result was: {
    "attempts": 1,
    "changed": false,
    "msg": 2,
    "retries": 3
}
FAILED - RETRYING: [localhost]: debug (1 retries left).Result was: {
    "attempts": 2,
    "changed": false,
    "msg": 2,
    "retries": 3
}
failed: [localhost] (item=2) => {
    "msg": 2
}
ok: [localhost] => (item=3) => {
    "msg": 3
}
fatal: [localhost]: FAILED! => {"msg": "One or more items failed"}
```

## 从 `with_X` 迁移到 `loop`

大多数情况下，循环都最好使用 `loop` 关键字，而不是 `with_X` 样式的循环。`loop` 语法使用过滤器表达是最好的，而不是使用更复杂的 `query` 或 `lookup`。


下面这些示例，展示了如何将许多常见的 `with_` 风格循环，转换为 `loop` 和过滤器。


### `with_list`


`with_list` 可由 `loop` 直接替换。

```yaml
    - name: with_list
      ansible.builtin.debug:
        msg: "{{ item }}"
      with_list:
        - one
        - two

    - name: with_list -> loop
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop:
        - one
        - two
```


### `with_items`

`with_items` 可被 `loop` 与 `flatten` 过滤器替代。


```yaml
  vars:
    items: ['a', 11, 'b', 'this']

  tasks:
    - name: with_items
      ansible.builtin.debug:
        msg: "{{ item }}"
      with_items: "{{ items }}"

    - name: with_items -> loop
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ items|flatten(levels=1) }}"
```


### `with_indexed_items`

`with_indexed_items` 可由 `loop`、`flatten` 过滤器与 `loop_control.index_var` 三者替换。

```yaml
  vars:
    items:
      - 'a': 11
      - 'b': 'this'

  tasks:
    - name: with_indexed_items
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      with_indexed_items: "{{ items }}"

    - name: with_indexed_items -> loop
      ansible.builtin.debug:
        msg: "{{ index }} - {{ item }}"
      loop: "{{ items|flatten(levels=1) }}"
      loop_control:
        index_var: index
```

### `with_flattened`

`with_flattened` 可由 `loop` 与 `flatten` 过滤器替代。

```yaml
  vars:
    items:
      - 'a': 11
      - 'b': 'this'

  tasks:
    - name: with_flattened
      ansible.builtin.debug:
        msg: "{{ item }}"
      with_flattened: "{{ items }}"

    - name: with_flattened -> loop
      ansible.builtin.debug:
        msg: "{{ item }}"
      loop: "{{ items|flatten }}"
```


### `with_together`


`with_together` 可由 `loop` 与 `zip` 过滤器替代。

```yaml
  vars:
    list_one:
      - 'a': 11
      - 'b': 'this'
    list_two:
      - c: 12
      - d: 'that'

  tasks:
    - name: with_together
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      with_together:
        - "{{ list_one }}"
        - "{{ list_two }}"

    - name: with_together -> loop
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      loop: "{{ list_one|zip(list_two)|list }}"
```

另一个复杂数据示例

```yaml
    - name: with_together -> loop
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }} - {{ item.2 }}"
      loop: "{{ data[0]|zip(*data[1:])|list }}"
      vars:
        data:
          - ['a', 'b', 'c']
          - ['d', 'e', 'f']
          - ['g', 'h', 'i']
```


> **译注**：其中的 `*data[1:]` 表示了 `data` 的后两个条目，注意这种写法。


### `with_dict`


`with_dict` 可以用 `loop` 和 `dictsort`，或 `loop` 与 `dict2items` 过滤器代替。


```yaml
  vars:
    dictionary: {
      'a': 11,
      'd': 'that',
      'c': 12,
      'b': 'this',
    }

  tasks:
    - name: with_dict
      ansible.builtin.debug:
        msg: "{{ item.key }} - {{ item.value }}"
      with_dict: "{{ dictionary }}"

    - name: with_dict -> loop (option 1)
      ansible.builtin.debug:
        msg: "{{ item.key }} - {{ item.value }}"
      loop: "{{ dictionary|dict2items }}"

    - name: with_dict -> loop (option 2)
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      loop: "{{ dictionary|dictsort }}"
```

> **译注**：注意 playbook YAML 中 `dict` 数据结构的写法。


### `with_sequence`

`with_sequence` 可被 `loop` 与 `range` 函数，以及潜在的 `format` 过滤器替代。


```yaml
    - name: with_sequence
      ansible.builtin.debug:
        msg: "{{ item }}"
      with_sequence: start=0 end=4 stride=2 format=testuser%02x

    - name: with_sequence -> loop
      ansible.builtin.debug:
        msg: "{{ 'testuser%02x' | format(item) }}"
      loop: "{{ range(0, 4 + 1, 2)|list }}"
```


其中循环的范围，不包括终点。

### `with_subelements`

`with_subelements` 可被 `loop` 和 `subelements` 过滤器替代。


```yaml
  vars:
    users:
      - name: alice
        mysql:
          hosts: [ debian, ubuntu]
      - name: bob
        mysql:
          hosts: [centos, almalinux]
      - name: tom
        mysql:
          hosts: [archlinux, manjaro]

  tasks:
    - name: with_subelements
      ansible.builtin.debug:
        msg: "{{ item.0.name }} - {{ item.1 }}"
      with_subelements:
        - "{{ users }}"
        - mysql.hosts

    - name: with_subelements -> loop
      ansible.builtin.debug:
        msg: "{{ item.0.name }} - {{ item.1 }}"
      loop: "{{ users|subelements('mysql.hosts') }}"
```

### `with_nested`/`with_cartesian`

`with_nested` 和 `with_cartesian` 可被 `loop` 和 `product` 过滤器取代。


```yaml
  vars:
    list_one:
      - a: 11
      - b: this
    list_two:
      - c: 12
      - d: that

  tasks:
    - name: with_nested
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      with_nested:
        - "{{ list_one }}"
        - "{{ list_two }}"

    - name: with_nested -> loop
      ansible.builtin.debug:
        msg: "{{ item.0 }} - {{ item.1 }}"
      loop: "{{ list_one|product(list_two)|list }}"
```


### `with_random_choice`


`with_random_choice` 可仅由 `random` 过滤器取代，而无需 `loop`。


```yaml
  vars:
    my_list:
      - 11
      - this
      - 12
      - that

  tasks:
    - name: with_random_choice
      ansible.builtin.debug:
        msg: "{{ item }}"
      with_random_choice: "{{ my_list }}"

    - name: with_random_choice -> loop (No loop is needed here)
      ansible.builtin.debug:
        msg: "{{ my_list|random }}"
      tags: random
```
