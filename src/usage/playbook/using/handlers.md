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
      # 该任务总是会报告为已变更
      changed_when: True
      notify: Restart apache
```

有关 `changed_when` 的更多信息，请参阅 [定义 `"changed"`](err_handling.md)。


## 在处理程序中使用变量

咱们可能希望咱们的 Ansible 处理程序用到变量。例如，如果某个服务的名称，会因发行版而略有不同，咱们就会想要咱们的输出，对各个目标机器显示所重启服务的准确名称。要避免在处理程序的名称中，放置变量。由于处理程序名称是早期模板化的，因此 Ansible 可能无法为下面这样的处理程序名称，提供一个可用值：

```yaml
  handlers:
    # This handler name may cause your play to fail!
    - name: Restart "{{ web_service_name }}"
```

> **译注**：但如果 `web_service_name` 可用，这样写是没有问题的，下面的 playbook 代码就可以被正常运行。

```yaml
  vars:
    www_service: web
    kv_service: memcached

  tasks:
    - setup:
        gather_subset:
          - distribution

    - name: Set host variables based on distribution
      include_vars: "{{ ansible_facts.distribution }}.yml"

    - name: Update nginx config
      ansible.builtin.template:
        src: './templates/nginx.j2'
        dest: '/etc/nginx/nginx.conf'
      notify: Restart web service

  handlers:
    - name: 'Restart {{ www_service }} service'
      ansible.builtin.service:
        name: "{{ web_service_name | default('nginx') }}"
        state: restarted
```


> 下面这样写，就可以依次重启 `memcached` 和 `nginx` 服务。

```yaml
  handlers:
    - name: Restart web service
      service:
        name: '{{ item }}'
        state: restarted
      loop:
        - memcached
        - nginx
      listen: "restart web services"
```


如果处理程序名称中用到的变量不可用，则整个 play 都会失败。中途改变变量，*不会* 反应到新创建的处理程序。

相反，要将变量放在咱们处理程序的任务参数中。咱们可以使用 `include_vars` 指令，加载这些变量值，如下所示：

```yaml
  tasks:
    - name: Set host variables based on distribution
      include_vars: "{{ ansible_facts.distribution }}.yml"

  handlers:
    - name: Restart web service
      ansible.builtin.service:
        name: "{{ web_service_name | default('httpd') }}"
        state: restarted
```

> **译注**：这里 `include_vars` 会首先查找 playbook YAML 文件所在目录下，`vars` 目录中对应的 `{{ ansible.distribution }}.yml` 文件，即使当前目录下也存在该文件。这中默认行为, 在当前目录与 `vars` 目录中，存在同样的变量文件时，就会优先加载 `vars` 目录中的该文件，从而造成一些难以发现的错误，运行 playbook 时使用 `-vvv` 命令行开关才能发现。以下是 `include_vars` 指令任务的输出。

```json
ok: [almalinux-5] => {
    "ansible_facts": {
        "http_port": 80,
        "max_clients": 512,
        "web_service_name": "nginx"
    },
    "ansible_included_var_files": [
        "/home/hector/ansible-tutorial/src/usage/playbook/j2_example/AlmaLinux.yml"
    ],
    "changed": false
}
ok: [debian-199] => {
    "ansible_facts": {
        "somethingelse": 42,
        "web": "nginx"
    },
    "ansible_included_var_files": [
        "/home/hector/ansible-tutorial/src/usage/playbook/j2_example/vars/Debian.yml"
    ],
    "changed": false
}
```

尽管处理程序的名称可以包含模板，但 `listen` 的主题则不能。

> **译注**：经测试，下面使用了模板的 `listen` 写法，却是会报出找不到该监听主题的错误。

```yaml
    - name: 'Restart memcached service'
      ansible.builtin.service:
        name: memcached
        state: restarted
      listen: 'restart {{ kv_service }} service'
```

> 报出的错误如下：

```console
ERROR! The requested handler 'restart memcached service' was not found in either the main handlers list nor in the listening handlers list
```

## 角色中的处理程序

角色中的处理程序，不仅仅包含在其角色中，而是会与某个 play 中全部别的处理程序一起，被插入到全局作用域中。如此他们便可以，在定义他们的角色之外得以使用。这也意味着，他们的名字可能会与角色外的处理程序发生冲突。为确保通知到角色中的处理程序，而非角色外同名处理程序，就要使用以下形式的处理程序名称，通知该处理程序：`role_name : handler_name`。

`roles` 小节中通知到的处理程序，会在 `tasks` 小节结束时，并在任何 `tasks` 通知到的处理程序前，自动刷新。

## 处理程序中的包含与导入


将一个动态包含，比如 `include_task`，作为处理程序通知，会导致该包含内所有任务的执行。通知定义在某个动态包含内的处理程序，是不可行的。

将 `import_task` 这样的静态包含作为处理程序，会导致该处理程序于 play 执行前，被该导入中的处理程序有效重写。静态包含本身无法被通知到，而该包含内的任务，则可以被单独通知到。

## 作为处理程序的元任务

自 Ansible 2.14 版起，就允许使用 [元任务](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/meta_module.html#ansible-collections-ansible-builtin-meta-module)，及将其作为处理程序而被通知到。但请注意，`flush_handlers` 不能用作处理程序，以防止意外行为。


## 局限

处理程序不能运行 `import_role` 及 `include_role`。处理程序会 [忽略标记](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_tags.html#tags-on-handlers)。

（End）

