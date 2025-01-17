# 条件

在某个 playbook 中，咱们可能希望根据某个事实（远端系统的数据）、某个变量或前一任务结果等的取值，而执行不同任务或实现不同目标。咱们可能想要某些变量的值，取决于其他变量的值。或者，咱们可能打算根据一些主机是否符合其他条件，来创建一些额外主机组。这些都可以通过条件来实现。

Ansible 在条件中用到 Jinja2 [测试](tests.md) 和 [过滤器](filters.md)。Ansible 支持所有标准测试和过滤器，并添加了一些独特的测试和过滤器。


> **注意**：Ansible 中有许多控制执行流程的选项。咱们可以在 [Jinja: Comparisons](https://jinja.palletsprojects.com/en/latest/templates/#comparisons)，找到更多受支持的条件示例。


## 使用 `when` 的基本条件

最简单的条件语句，适用于单个任务。创建出一个任务，然后添加一个应用了某种测试的 `when` 语句。`when` 子句，the `when` clause，是个不带双花括符（参见 [引用简单变量](vars.md)）的，原始 Jinja2 表达式。当咱们运行任务或 playbook 时，Ansible 会对所有主机，计算该测试。在该测试通过（返回 `True` 值）的主机上，Ansible 会运行该任务。例如，如果咱们正在多台机器上安装 `mysql`，而其中一些机器启用了 SELinux，则就可能会有个配置 SELinux 以允许 `mysql` 运行的任务。咱们只想要该任务，在启用了 SELinux 的机器上运行：


```yaml
  tasks:
    - name: Gather SELinux facts
      setup:
        gather_subset:
          - selinux

    - name: Install Python package python3-libsemanage
      ansible.builtin.dnf:
        name: python3-libsemanage
        state: present


    - name: Configure SELinux to start mysql on any port
      ansible.posix.seboolean:
        name: mysql_connect_any
        state: true
        persistent: true
      when: ansible_selinux.status == "enabled"
      # 所有变量都可以直接在条件语句中使用，无需双花括符
```

> **译注**：
>
> - 这里的 `setup` 任务，是因为 playbook 中全局设置了 `gather_facts: no`，因此首先要收集有关 SELinux 的事实；
>
> - 要安装 `ansible.posix` 专辑（`ansible-galaxy collection install ansible.posix`）；
>
> - 需要在目标托管主机上，安装 `python3-libsemanage` 软件包。


### 基于 `ansible_facts` 的条件


咱们会经常想要根据事实，facts，执行或跳过某项任务。事实是单个主机的属性，包括 IP 地址、操作系统、文件系统状态等。使用基于事实的条件：

- 咱们可以只在操作系统为特定版本时，才安装某个特定软件包；
- 咱们可以跳过在内部 IP 地址主机上的防火墙配置；
- 咱们可以只在文件系统快满的时候，才执行清理任务。

有关经常出现条件语句中的事实列表，请参阅 [经常用到的事实](#经常用到的事实)。并非所有事实都存在于全部主机。例如，下面示例中用到的 `lsb_major_release`事实，就只有当目标主机上安装了 `lsb_release` 软件包时才存在。要查看咱们系统上有哪些事实，请在 playbook 中添加一个调试任务：

```yaml
    - name: Show facts available on the system
      ansible.builtin.debug:
        var: ansible_facts
```

下面是个基于事实的条件示例：

```yaml
---
- hosts: nginx
  gather_facts: no
  vars:

  tasks:
    - name: Gather some facts
      setup:
        gather_subset:
          - os_family
    - name: Shut down Debian flavored systems
      ansible.builtin.command: /sbin/shutdown -t now
      when: ansible_os_family == "Debian"
```

若咱们有多重条件，则可以用括号将他们分组：


```yaml
    - name: Gather some facts
      setup:
        gather_subset:
          - distribution
          - distribution_major_version

    - debug:
        msg: "{{ ansible_facts['distribution'] }}, {{ ansible_facts['distribution_major_version'] }}"

    - name: Shut down Debian flavored systems
      ansible.builtin.command: /sbin/shutdown -t now
      when: (ansible_facts['distribution'] == "AlmaLinux" and ansible_facts['distribution_major_version'] == "9") or
            (ansible_facts['distribution'] == "Debian" and ansible_facts['distribution_major_version'] == "7")
```

咱们可以使用 [逻辑运算符](https://jinja.palletsprojects.com/en/latest/templates/#logic)， 来组合条件。当咱们有着多个都需要为真的条件时（即逻辑 `and`），咱们可以将他们指定为一个列表：


```yaml
    - name: Shut down AlmaLinux 9 systems
      ansible.builtin.command: /sbin/shutdown -t now
      when:
        - ansible_facts['distribution'] == "AlmaLinux"
        - ansible_facts['distribution_major_version'] == "9"
```


如果某个事实或变量是个字符串，而咱们需要对其进行数学比较，那么就要使用一个过滤器，确保 Ansible 将其读取为一个整数：


```yaml
    - ansible.builtin.setup:
        gather_subset:
          - distribution
          - distribution_major_version

    - ansible.builtin.shell: echo "only on AlmaLinux 8, derivatives, and later"
      when:
        - ansible_facts['distribution'] == "AlmaLinux"
        - ansible_facts['distribution_major_version'] | int >= 8
```

可以将 Ansible 事实存储为变量，用于条件逻辑，如下面的示例：


```yaml
  tasks:
      - name: Get the CPU temperature
        set_fact:
          temperature: "{{ ansible_facts['cpu_temperature'] }}"

      - name: Restart the system if the temperature is too high
        when: temperature | float > 90
        shell: "reboot"
```

> **译注**：在 `virt-manager` KVM 虚拟机中，不支持获取 `cpu_temperature` 事实。

### 基于注册变量的条件

咱们经常会在 playbook 中，根据早先任务的结果，执行或跳过某个任务。例如，咱们可能打算在某个服务被先前任务升级后，对其进行配置。要根据注册变量创建条件：

1. 将早先任务的结果，注册为变量；
2. 创建出一个基于该注册变量的条件测试。


咱们使用 `register` 关键字，创建出注册变量的名字。注册变量始终包含创建他的任务状态，以及该任务产生的全部输出。咱们可以在模板与操作行，以及条件 `when` 语句中使用注册变量。咱们可以使用 `variable.stdout`，访问注册变量的字符串内容。例如：

```yaml
- name: Test play
  hosts: all

  tasks:

      - name: Register a variable
        ansible.builtin.shell: cat /etc/motd
        register: motd_contents

      - name: Use the variable in conditional statement
        ansible.builtin.shell: echo "motd contains the word hi"
        when: motd_contents.stdout.find('hi') != -1
```

如果该注册变量是个列表，则咱们可以在某个任务循环中，使用注册的结果。如果该注册变量不是列表，那么咱们可以使用 `stdout_lines` 或 `variable.stdout.split()`，将其转换为列表。咱们还可以按其他字段分割这些行：

```yaml
- name: Registered variable usage as a loop list
  hosts: all
  tasks:

    - name: Retrieve the list of home directories
      ansible.builtin.command: ls /home
      register: home_dirs

    - name: Add home dirs to the backup spooler
      ansible.builtin.file:
        path: /mnt/bkspool/{{ item }}
        src: /home/{{ item }}
        state: link
      loop: "{{ home_dirs.stdout_lines }}"
      # 与 `loop: "{{ home_dirs.stdout.split() }}"` 相同
```

注册变量的字符串内容可以为空。如果咱们只打算在注册变量的 `stdout` 字段为空的主机上，运行另一任务，就要检查注册变量的字符串内容是否为空：

```yaml
- name: Check registered variable for emptiness
  hosts: all

  tasks:
      - file:
          path: '/home/hector/mydir'
          state: directory

      - name: List contents of directory
        ansible.builtin.command: 'ls mydir'
        register: contents

      - name: Check contents for emptiness
        ansible.builtin.debug:
          msg: "Directory is empty"
        when: contents.stdout == ""
```


Ansible 总是会在每台主机的注册变量中，注册一些内容，即使在任务失败或 Ansible 因未满足条件，而跳过某个任务的主机上也是如此。要在这些主机上运行后续任务，就要查询注册变量的 `is skipped` 字段（而不是 `undefined` 或 `default`）。更多信息，请参阅 [变量的注册](vars.md)。以下是基于某项任务的成功或失败的一些条件示例。如果咱们希望 Ansible 在某项任务失败时，继续在某台主机上执行，请记住要忽略错误：


```yaml
tasks:
  - name: Register a variable, ignore errors and continue
    ansible.builtin.command: /bin/false
    register: result
    ignore_errors: true

  - name: Run only if the task that registered the "result" variable fails
    ansible.builtin.command: /bin/something
    when: result is failed

  - name: Run only if the task that registered the "result" variable succeeds
    ansible.builtin.command: /bin/something_else
    when: result is succeeded

  - name: Run only if the task that registered the "result" variable is skipped
    ansible.builtin.command: /bin/still/something_else
    when: result is skipped

  - name: Run only if the task that registered the "result" variable changed something.
    ansible.builtin.command: /bin/still/something_else
    when: result is changed
```

> **注意**：旧版本的 Ansible 使用 `success` 和 `fail`，而 `succeeded` 和 `failed` 使用的才是正确时态。现在所有这些选项都有效。


### 基于变量的条件

咱们还可以根据在 playbook 或仓库中定义的变量，创建条件。由于条件必需布尔值输入（测试结果必须为 `True` 才能触发该条件），因此咱们必须将 `| bool` 过滤器，应用于那些非布尔值变量，比如包含 `"yes"`、`"on"`、`"1"` 或 `"true"` 等内容的字符串变量。咱们可以这样定义变量：

```yaml
vars:
  epic: true
  monumental: "yes"
```

使用上述变量，Ansible 将运行下面这些中的一个任务，并跳过其他任务：


```yaml
  tasks:
    - name: >
        当 "epic" 或 "monumental" 为真时，运行该命令，run
        the command if "epic" or "monumental" is true
      ansible.builtin.shell: echo "This certainly is epic!"
      when: epic or monumental | bool

    - name: 当 "epic" 为假时运行该命令，run the command if "epic" is false
      ansible.builtin.shell: echo "This certainly isn't epic!"
      when: not epic
```

> **译注**：上面的示例，使用了 YAML 中多行字符串的写法。咱们可以使用 `>` 与 `|` 两种方式，写出多行的字符串。
>
> 参考：[How do I break a string in YAML over multiple lines?](https://stackoverflow.com/a/21699210/12288760)


如果所需的变量尚未设置，咱们可以使用 Jinja2 的 `defined` 测试，跳过或将其失败。例如：

```yaml
  tasks:
    - name: Run the command if "foo" is defined
      ansible.builtin.shell: echo "I've got '{{ foo }}' and am not afraid to use it!"
      when: foo is defined

    - name: Fail if "bar" is undefined
      ansible.builtin.fail: msg="Bailing out. This play requires 'bar'"
      when: bar is undefined
```


这与 `vars` 文件的条件导入（见下文）结合起来特别有用。正如示例所示，咱们无需使用 `{{ }}`， 来在条件语句中使用变量，因为这些已经隐含其中了。


### 在循环中使用条件

如果咱们将 `when` 语句与循环相结合，那么 Ansible 会对每个项目，分别处理条件。这是有意为之，如此咱们就可以在循环中的某些项目上执行任务，而在其他项目上跳过。例如：

```yaml
  tasks:
    - name: Run with items greater than 5
      ansible.builtin.command: echo {{ item }}
      loop: [ 0, 2, 4, 6, 8, 10 ]
      when: item > 5
```

若咱们需要在循环变量未定义时，跳过整个任务，就要使用 `|default` 过滤器，提供一个空迭代器。例如，在对某个列表进行循环时：

```yaml
    - name: Skip the whole task when a loop variable is undefined
      ansible.builtin.command: echo {{ item }}
      loop: "{{ mylist|default([]) }}"
      when: item > 5
```

在对某个字典进行循环时，咱们可以做同样的事情：


```yaml
    - name: The same as above using a dict
      ansible.builtin.command: echo {{ item.key }}
      loop: "{{ query('dict', mydict|default({})) }}"
      when: item.value > 5
```

### 加载自定义事实


正如 [“是否应该开发模组？”](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules.html#developing-modules) 中所述，咱们可以提供自己的事实收集模组。要运行这些模组，只需在咱们任务列表的顶部，调用咱们自己的定制事实收集模组，那么该处返回的变量，将可供后面的任务使用：


```yaml
  tasks:
    - name: Gather site specific fact data
      action: site_facts

    - name: Use a custom fact
      ansible.builtin.command: /usr/bin/thingy
      when: my_custom_fact_just_retrieved_from_the_remote_system == '1234'
```

### 重用下的条件

咱们可以在可重用任务文件、playbooks 或角色下，运用条件。对于动态重用（包含）和静态重用（导入），Ansible 会区别地执行这些条件语句。有关 Ansible 中重用的更多信息，请参阅 [重用 Ansible 制品](reuse.md)。

- **条件导入**

当咱们将某个条件，添加到导入语句时，Ansible 会将该条件，应用于导入文件中的所有任务。这种行为相当于 [标签继承：将表天添加到多个任务](../executing.md)。Ansible 会将该条件应用到每个任务，并分别评估每个任务。例如，若咱们要定义并显示某个先前未定义的变量，咱们可能会有个名为 `main.yml` 的 playbook，和一个名为 `other_tasks.yml` 的任务文件：


```yaml
# 导入文件中的全部任务，都会继承导入语句中的条件
# main.yml
- hosts: app
  gather_facts: no

  tasks:
  - import_tasks: other_tasks.yml # 注意是 "import"
    when: x is not defined
```


```yaml
# other_tasks.yml
- name: Set a variable
  ansible.builtin.set_fact:
    x: foo

- name: Print a variable
  ansible.builtin.debug:
    var: x
```

Ansible 会在执行时，将其扩展为相当于


```yaml
- name: Set a variable if not defined
  ansible.builtin.set_fact:
    x: foo
  when: x is not defined
  # 此任务会给 `x` 设置个值

- name: Do the task if "x" is not defined
  ansible.builtin.debug:
    var: x
  when: x is not defined
  # Ansible 会跳过此任务，因为 `x` 现在未被定义
```


如果 `x` 在初始时已定义，则两个任务都会按原定计划跳过。但如果 `x` 最初未定义，那么其中的 `debug` 任务将被跳过，因为对每个导入任务其中的条件都会被评估。将定义变量的 `set_fact` 任务中的条件将被评估为 `true`，并导致 `debug` 任务的条件，被评估为 `false`。


如果这不是咱们想要的行为，则可使用 `include_* `语句，将条件仅应用于该语句本身。

```yaml
# 导入文件中的全部任务，都会继承导入语句中的条件
# main.yml
- hosts: app
  gather_facts: no

  tasks:
  - include_tasks: other_tasks.yml # 注意是 "include"
    when: x is not defined
```

现在若 `x` 最初未定义，其中的 `debug` 任务将不会被跳过，因为条件是在包含时评估的，进而不会应用到单个任务。


咱们可以将条件应用到 `import_playbook` 及其他 `import_*` 语句。在咱们使用这种方法时，Ansible 会为每台主机上不符合条件的每项任务，都返回 `"skipped"` 消息，产生出重复性输出。在许多情况下，[`group_by` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_by_module.html#group-by-module) 是实现相同目标的更简便方法；请参阅  [处理操作系统和发行版差异](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html#os-variance)。


- **包含下的条件**

当咱们在某条 `include_*` 语句中使用条件时，则该条件只会应用于这个包含任务本身，而不会应用于所包含文件中任何别的任务。为了与上述导入上条件的示例对比，请查看同样的 playbook 和任务文件，但使用的是包含而不是导入：

```yaml
# 包含允许咱们重用某个文件，以便在某个变量尚未定义时定义出他

# main.yml
- include_tasks: other_tasks.yml
  when: x is not defined
```

```yaml
# other_tasks.yml
- name: Set a variable
  ansible.builtin.set_fact:
    x: foo

- name: Print a variable
  ansible.builtin.debug:
    var: x
```


Ansible 在执行时会将其展开为等价的：


```yaml
# main.yml
- include_tasks: other_tasks.yml
  when: x is not defined
  # 若条件满足，Ansible 会包含 `other_tasks.yml`

# other_tasks.yml
- name: Set a variable
  ansible.builtin.set_fact:
    x: foo
  # 没有条件应用到此任务，Ansible 会将 `x` 的值设置为 `"foo"`

- name: Print a variable
  ansible.builtin.debug:
    var: x
  # 没有条件应用到此任务，Ansible 会打印出这个 `debug` 语句
```

通过使用 `include_tasks` 而不是 `import_tasks`，`other_tasks.yml` 中的两个任务都将按预期执行。有关 `include` 和 `import` 之间区别的更多信息，请参阅 [重用 Ansible 制品](reuse.md)。


- **条件角色**

将条件应用到角色的方式有三：

- 通过将 `when` 语句放在 `roles` 关键字下，将同一条件或同样的一些条件，添加到该角色中的全部任务。请参阅本节中的示例；
- 通过将 `when` 语句，放在咱们 playbook 中某个静态 `import_role` 上，将同一条件或同样的一些条件，添加到该角色中的全部任务；
- 将同一条件或同样的一些条件，添加到角色本身内部的单个任务或区块。这是唯一一种咱们可以根据咱们的 `when` 语句，选取或跳过角色内某些任务的方法。要选择或跳过角色内的任务，咱们必须在单个任务或区块上设置条件，要在咱们的 playbook 中，使用动态的 `include_role`，并在将一或多个条件添加到该包含。当咱们用到这种方法时，Ansible 会将设置的条件，应用到该包含本身，以及角色中任何同样具有 `when` 语句的任务。


当咱们使用 `roles` 关键字，静态地将某个角色纳入咱们的 playbook 时，Ansible 会将咱们定义的条件，添加到该角色中的所有任务。例如

```yaml
- hosts: webservers
  roles:
     - role: debian_stock_config
       when: ansible_facts['os_family'] == 'Debian'
```


### 基于事实选取变量、文件或模板

有时，主机的事实，决定了咱们打算对某些变量所使用的值，甚至决定了咱们对该主机所选择的文件或模板。例如，CentOS 与 Debian 上，软件包名称就是不同的。常见服务的配置文件，在不同操作系统及不同版本上，也是不同的。根据主机的某项事实，要加载不同变量文件、模板或其他文件：

1. 将变量文件、模板或文件，命名为与 Ansible 事实相匹配的名称，以区分他们；

2. 使用某个基于 Ansible 事实的变量，为每台主机选择正确的变量文件、模板或文件。


Ansible 会将变量与任务分开，使咱们的 playbook 不会在嵌套条件下，变成任意代码。由于需要追踪的决策点较少，因此这种方法能使配置规则更精简、更可审计。


- **根据事实选取变量文件**

通过将变量值放在变量文件中，并有条件地导入变量文件，咱们可创建出能在多种平台和操作系统版本上运行的 playbook，而且只需使用最少的语法。如果咱们打算在一些 CentOS 和一些 Debian 服务器上安装 Apache，就要以一些 YAML 的键值，创建出变量文件。例如：


```yaml
---
# for vars/RedHat.yml
apache: httpd
somethingelse: 42
```

然后根据咱们在 playbook 中，在托管主机上收集到的事实，导入这些变量文件：


```yaml
---
- hosts: webservers
  remote_user: root
  vars_files:
    - "vars/common.yml"
    - [ "vars/{{ ansible_facts['os_family'] }}.yml", "vars/os_defaults.yml" ]
  tasks:
    - name: Make sure apache is started
      ansible.builtin.service:
        name: '{{ apache }}'
        state: started
```

Ansible 会收集 `webservers` 组中主机的事实，然后将变量 `ansible_facts[‘os_family’]` 插值到一个文件名列表。如果咱们有着 Red Hat 操作系统（例如 CentOS）的主机，Ansible 就会查找 `"vars/RedHat.yml"`。如果该文件不存在，Ansible 会尝试加载 `"vars/os_defaults.yml"`。对于 Debian 主机，Ansible 会首先查找 `"vars/Debian.yml"`，然后再退回到 `"vars/os_defaults.yml"`。如果列表中的文件一个也找不到，Ansible 就会抛出错误。


- **根据事实选取文件与模板**


当不同操作系统或版本，需要不同配置文件或模板时，咱们也可以使用同样方法。根据指派给各台主机的变量，选择合适的文件或模板。与在单个模板中加入大量条件，来涵盖多种操作系统或软件包版本相比，这种方法要简洁得多。

比如，咱们可以将 CentOS 和 Debian 之间，截然不同的配置文件模板化：

```yaml
    - name: Template a file
      ansible.builtin.template:
        src: "{{ item }}"
        dest: /etc/myapp/foo.conf
      loop: "{{ query('first_found', { 'files': myfiles, 'paths': mypaths}) }}"
      vars:
        myfiles:
          - "{{ ansible_facts['distribution'] }}.conf"
          -  default.conf
        mypaths: ['search_location_one/somedir/', '/opt/other_location/somedir/']
```


## 调试条件

若咱们的条件 `when` 语句，没有按照咱们的意图行事，那么咱们可以添加一条 `debug` 语句，以确定该条件评估结果是 `true` 还是 `false`。条件中出现未预期行为的常见原因是，将某个整数测试为字符串，或将某个字符串测试为整数。要调试某个条件语句，可在一个 `debug` 任务中，添加整个语句作为 `var:` 的值。然后，Ansible 就会显示出该测试，和该语句的评估结果。下面是一组任务，和示例输出：


```yaml
    - name: check value of return code
      ansible.builtin.debug:
        var: bar_status.rc

    - name: check test for rc value as string
      ansible.builtin.debug:
        var: bar_status.rc == "127"

    - name: check test for rc value as integer
      ansible.builtin.debug:
        var: bar_status.rc == 127
```

```yaml
TASK [check value of return code] *************************************************************************************
ok: [almalinux-39] => {
    "bar_status.rc": "127"
}

TASK [check test for rc value as string] ******************************************************************************
ok: [almalinux-39] => {
    "bar_status.rc == \"127\"": false
}

TASK [check test for rc value as integer] *****************************************************************************
ok: [almalinux-39] => {
    "bar_status.rc == 127": true
}
```

## 常用事实

以下 Ansible 事实在条件式中会经常用到。


### `ansible_facts['distribution']`

可能的取值（示例，非完整列表）：


```console
Alpine
Altlinux
Amazon
Archlinux
ClearLinux
Coreos
CentOS
Debian
Fedora
Gentoo
Mandriva
NA
OpenWrt
OracleLinux
RedHat
Slackware
SLES
SMGL
SUSE
Ubuntu
VMwareESX
```

### `ansible_facts['distribution_major_version']`


操作系统的主版本号。例如，Ubuntu 16.04 的值为 `16`。


### `ansible_facts['os_family']`



可能的取值（示例，非完整列表）：


```console
AIX
Alpine
Altlinux
Archlinux
Darwin
Debian
FreeBSD
Gentoo
HP-UX
Mandrake
RedHat
SMGL
Slackware
Solaris
Suse
Windows
```

（End）


