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

> **译注**：在 `virt-manager` KVM 虚拟机中，不支持获取 `cpu_temperature` 事实上。

### 基于注册变量的条件
