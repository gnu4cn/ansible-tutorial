# 区块

区块创建出任务的逻辑组。区块还提供了处理任务错误的方法，类似于许多编程语言中的异常处理。


## 使用区块给任务分组


区块中的所有任务，都会继承应用于区块级别的指令。大多数咱们可应用于单个任务的指令（循环除外），都可应用于区块级别，因此区块会令到设置任务共用的数据或指令，更加容易。指令不会影响区块本身，只会被区块中的任务继承。例如，`when` 语句会被应用到区块中的那些任务，而不是区块本身。

*内部有着一些命名任务的区块示例*

```yaml
  tasks:
    - name: Install, configure, and start Apache
      when: ansible_facts['distribution'] == 'CentOS'
      block:
        - name: Install httpd and memcached
          ansible.builtin.yum:
            name:
            - httpd
            - memcached
            state: present

        - name: Apply the foo config template
          ansible.builtin.template:
            src: templates/src.j2
            dest: /etc/foo.conf

        - name: Start service bar and enable it
          ansible.builtin.service:
            name: bar
            state: started
            enabled: True
      become: true
      become_user: root
      ignore_errors: true
```

在上面的示例中，其中的 `when` 条件将在 Ansible 运行区块中的三个任务之前，得以评估。所有三个任务还都会继承那些权限提升指令，以 `root` 用户身份运行。最后，`ignore_errors: true` 可以确保即使某些任务失败，Ansible 也会继续执行该 playbook。

> **注意**：区块中的所有任务，包括通过 `include_role` 所包含的任务，都会继承在区块级别应用的指令。

从 Ansible 2.3 开始，就可以为区块命名了。为了在咱们运行 playbook 时，更好地查看正在执行的任务，我们建议在所有任务中，都使用名称，无论是在区块内还是其他地方。


## 使用区块处理错误


使用带有 `rescue` 和 `always` 小节的区块，咱们可以控制 Ansible 对任务出错的响应方式。


救援区块指定了在区块中某个早先任务失败时，要运行的任务。这种方法类似于许多编程语言中的异常处理。Ansible 只在某个任务返回 `'failed'` 状态后，才会运行救援区块。不良的任务定义，与不可达的主机，不会触发救援区块。


*区块出错处理示例*

```yaml
  tasks:
    - name: Handle the error
      block:
        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'

        - name: Force a failure
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I never execute, due to the above task failing, :-('
      rescue:
        - name: Print when errors
          ansible.builtin.debug:
            msg: 'I caught an error, can do stuff here to fix it, :-)'
```

咱们还可以添加一个 `always` 小节到某个区块。无论前面区块的任务状态为何，`always` 小节中的任务都会运行。


*带 `always` 小节的区块*


```yaml
  tasks:
    - name: Always do X
      block:
        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'

        - name: Force a failure
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I never execute :-('
      always:
        - name: Always do this
          ansible.builtin.debug:
            msg: "This always executes, :-)"
```

这些元素共同提供了复杂的错误处理功能。


*包含全部小节的区块*


```yaml
  tasks:
    - name: Attempt and graceful roll back demo
      block:
        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'

        - name: Force a failure
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I never execute, due to the above task failing, :-('
      rescue:
        - name: Print when errors
          ansible.builtin.debug:
            msg: 'I caught an error'

        - name: Force a failure in middle of recovery! >:-)
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I also never execute :-('
      always:
        - name: Always do this
          ansible.builtin.debug:
            msg: "This always executes"
```


`block` 中的任务会正常执行。如果区块中有任务返回了 `failed`，则 `rescue` 小节就会执行任务，以从错误中恢复。无论 `block` 和 `rescue` 小节的结果如何，`always` 小节都会运行。


如果区块中发生了错误，而救援任务成功了，则 Ansible 会还原原始任务该次运行的失败状态，并就像原始任务成功了一样，继续运行。该救援任务被视为成功，而不会触发 `max_fail_percentage` 或 `any_errors_fatal` 配置。不过，Ansible 仍会在 playbook 统计中报告失败。

咱们可使用带有某个救援任务中 `flush_handlers` 指令的区块，来确保即使发生错误也能运行所有处理程序：

*在错误处理中运行处理程序的区块*

```yaml
  tasks:
    - name: Attempt and graceful roll back demo
      block:
        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'
          changed_when: true
          notify: Run me even after an error

        - name: Force a failure
          ansible.builtin.command: /bin/false
      rescue:
        - name: Make sure all handlers run
          meta: flush_handlers
  handlers:
     - name: Run me even after an error
       ansible.builtin.debug:
         msg: 'This handler runs even on error'
```

*版本 2.1 中的新特性*。


Ansible 为区块中救援部分的任务，提供了如下两个变量：

- `ansible_failed_task`
返回 `'failed'` 并触发了救援的那个任务。例如，使用 `ansible_failed_task.name` 获取其名称。


- `ansible_failed_result`
捕获到的触发了救援的失败任务的返回结果。这相当于在 `register` 关键字中，使用了这个变量。


这两个变量都可以在 `rescue` 小节被检查到：

*在 `rescue` 小节使用特殊变量*

```yaml
  tasks:
    - name: Attempt and graceful roll back demo
      block:
        - name: Do Something
          ansible.builtin.shell: grep $(whoami) /etc/hosts

        - name: Force a failure, if previous one succeeds
          ansible.builtin.command: /bin/false
      rescue:
        - name: All is good if the first task failed
          when: ansible_failed_task.name == 'Do Something'
          ansible.builtin.debug:
            msg: All is good, ignore error as grep could not find 'me' in hosts

        - name: All is good if the second task failed
          when: "'/bin/false' in ansible_failed_result.cmd | d([])"
          ansible.builtin.fail:
            msg: It is still false!!!
```

> **注意**：在 `ansible-core` 2.14 或更高版本中，当存在嵌套区块时，这两个变量都会从内部区块，传播到区块的外层 `rescue` 部分。


（End）


