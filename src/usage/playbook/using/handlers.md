# 处理程序：在变化时运行操作

有时，咱们希望某个任务，只在某台机器上有变更时才运行。例如，若某个任务更新了某个服务配置，咱们就可能想要重启该服务，而如果配置没有变动，则不希望重启。Ansible 使用处理程序，来解决这种用例。处理程序是一些在收到通知时，才运行的任务。


## 处理程序示例


下面这个 playbook（`verify-apache.yml`），包含了带有处理程序的单个 play。


```yaml
---
- name: Verify apache installation
  hosts: webservers
  vars:
    http_port: 80
    max_clients: 200
  remote_user: root
  tasks:
    - name: Ensure apache is at the latest version
      ansible.builtin.yum:
        name: httpd
        state: latest

    - name: Write the apache config file
      ansible.builtin.template:
        src: /srv/httpd.j2
        dest: /etc/httpd.conf
      notify:
        - Restart apache

    - name: Ensure apache is running
      ansible.builtin.service:
        name: httpd
        state: started

  handlers:
    - name: Restart apache
      ansible.builtin.service:
        name: httpd
        state: restarted
```

在这个示例 playbook 中，Apache 服务器会在该 play 中的所有任务完成后，由其中的处理程序重启。


## 通知处理程序

使用 `notify` 关键字，任务便可以指示一或多个处理程序执行。`notify` 关键字可应用到某个任务，并接受一个处理程序名称的列表，该列表会在任务造成的变更时，收到通知。或者，也可以提供包含单个处理程序名称的字符串。下面的示例演示了，如何由单个任务，通知多个处理程序：


```yaml
  tasks:
    - name: Template configuration file
      ansible.builtin.template:
        src: template.j2
        dest: /etc/foo.conf
      notify:
        - Restart apache
        - Restart memcached

    handlers:
      - name: Restart memcached
        ansible.builtin.service:
          name: memcached
          state: restarted

      - name: Restart apache
        ansible.builtin.service:
          name: apache
          state: restarted
```

在上述示例中，在任务造成的变更时，处理程序会按以下顺序执行： `Restart memcached`、`Restart apache`。处理程序的执行顺序，是在 `handlers` 小节中定义的顺序，而不是 `notify` 语句中的列出顺序。如果多次通知了同一处理程序，则无论有多少个任务通知个他，该处理程序都只会执行一次。例如，如果多个任务更新了某个配置文件，并通知了某个处理程序重启 Apache，Ansible 只会反弹 Apache 一次，以避免不必要的重启。


## 通知与循环

任务可以使用循环来通知处理程序。当与变量组合，来触发多个动态通知时，这点尤其有用。

请注意，如果任务作为整体发生有了变更，那么处理程序就会被触发。而当使用了循环时，如果任何一个循环项有了变更，就都会设置下变化了的状态。也就是说，任何的变化，都会触发所有处理程序。

```yaml
  tasks:
    - name: Template services
      ansible.builtin.template:
        src: "{{ item }}.j2"
        dest: /etc/systemd/system/{{ item }}.service
      # 注意：若有 *任何* 循环迭代触发了变更，那么 *全部* 处理程序都会运行
      notify: Restart {{ item }}
      loop:
        - memcached
        - apache

  handlers:
    - name: Restart memcached
      ansible.builtin.service:
        name: memcached
        state: restarted

    - name: Restart apache
      ansible.builtin.service:
        name: apache
        state: restarted
```

在上述示例中，任一模板文件发生变化，`memcached` 和 `apache` 都将重启；如果文件都没有变化，两者就都不会重启。


## 处理程序命名

处理程序必须命名，任务才能使用 `notify` 关键字通知他们。

此外，处理程序还可以使用 `listen` 关键字。使用这个处理程序关键字，处理程序就可以监听，可将多个处理程序分组的主题了，如下所示：

```yaml
  tasks:
    - name: Restart everything
      command: echo "this task will restart the web services"
      notify: "restart web services"

  handlers:
    - name: Restart memcached
      service:
        name: memcached
        state: restarted
      listen: "restart web services"

    - name: Restart apache
      service:
        name: apache
        state: restarted
      listen: "restart web services"
```

通知 `restart web services` 这个主题，会导致执行所有监听该主题的处理程序，无论这些处理程序是怎样命名的。

这种用法，使得触发多个处理程序变得更加容易。他还将处理程序与其名称解耦，从而更容易在 playbook 和角色之间，共享处理程序（尤其是在使用来自如 Ansible Galaxy 这样的共享源，的第三方角色时）。

每个处理程序都应有个全局唯一的名称。如果以同一名称定义了多个处理程序，则只有最后加载到 play 的处理程序才会被通知并执行，而屏蔽掉前面那些有相同名称的处理程序。

无论处理程序在哪里定义，处理程序（即处理程序名称与监听主题）都只有一个全局作用域。这也包括在角色中定义的处理程序。

## 控制处理程序于何时运行

默认情况下，处理程序会在某个特定 play 中的所有任务完成后运行。通知到处理程序，会在以下全部小节后自动被执行，这些小节的顺序如下：`pre_tasks`、`roles`/`tasks` 及 `post_tasks`。这种方法效率很高，因为无论有多少任务通知处理程序，处理程序都只会运行一次。例如，如果多个任务都更新了某个配置文件，并通知处理程序重启 Apache，Ansible 都只会弹跳 Apache 一次，以避免不必要的重启。

如果咱们需要在 play 结束前就运行处理程序，就要添加一个用到 [`meta` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html#meta-module) 的任务来刷新他们， 该模组会执行下面的 Ansible 操作：

```yaml
  tasks:
    - name: Some tasks go here
      ansible.builtin.shell: ...

    - name: Flush handlers
      meta: flush_handlers

    - name: Some other tasks
      ansible.builtin.shell: ...
```

其中的 `meta: flush_handlers` 任务，会触发这个 play 中该处已被通知的全部处理程序。

无论是在各个小节被提到的后自动执行，还是由 `flush_handlers` 元任务手动执行，这些处理程序都可以在 play 的后续小节中，再次被通知并运行。

## 定义任务何时造成变更

咱们可以使用 `changed_when` 关键字，控制处理程序何时收到任务变更通知。


```yaml
  tasks:
    - name: Copy httpd configuration
      ansible.builtin.copy:
        src: ./new_httpd.conf
        dest: /etc/httpd/conf/httpd.conf
      # The task is always reported as changed
      changed_when: True
      notify: Restart apache
```

有关 `changed_when` 的更多信息，请参阅 [定义 `"changed"`](err_handling.md)。


##
