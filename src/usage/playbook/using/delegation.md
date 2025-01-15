# 控制任务于何处运行：委派与本地操作

默认情况下，Ansible 会在与咱们 playbook 的 `hosts` 行，匹配的机器上，收集事实并执行所有任务。本页将向咱们展示，如何将任务委派给不同的机器或组，以及将事实指派给特定的机器或组，或在本地运行整个 playbook。使用这些方法，咱们可以精确高效地，管理相互关联的环境。例如，在更新咱们的 `webservers` 时，咱们可能需要暂时将他们，从负载均衡池中移除。咱们无法在 `webservers` 本身上执行这项任务。通过将任务委派给 `localhost`，咱们可以将所有任务，保持在同一个 play 中。

## 无法委派的任务

有些任务总是在控制节点上执行。这些任务（包括 `include`、`add_host` 和 `debug` 等）不能委派。咱们可以从任务操作的 `connection` 属性文档，确定某个操作是否可以委派。如果 `connection` 属性表明 `support` 为 `False` 或 `None`，则该操作不会用到连接，进而就不能被委派。


## 委派任务


如果咱们打算在某台主机上执行一项任务并引用其他主机，纳姆就要在该任务上使用 `delegate_to` 关键字。这非常适合管理负载均衡池中的节点，或控制服务中断时间窗口。咱们可以使用带有 [`serial`](strategies.md) 关键字的委派，来控制同时执行的主机数量：

```yaml
---
- hosts: webservers
  serial: 5

  tasks:
    - name: Take out of load balancer pool
      ansible.builtin.command: /usr/bin/take_out_of_pool {{ inventory_hostname }}
      delegate_to: 127.0.0.1

    - name: Actual steps would go here
      ansible.builtin.yum:
        name: acme-web-stack
        state: latest

    - name: Add back to load balancer pool
      ansible.builtin.command: /usr/bin/add_back_to_pool {{ inventory_hostname }}
      delegate_to: 127.0.0.1
```

这个 play 中的第一和第三个任务，运行在 `127.0.0.1` 上，也就是运行 Ansible 的机器上。还有一种咱们可用于单个任务的速记语法：`local_action`。以下是与上面相同的 playbook，但使用了委派给 `127.0.0.1` 的速记语法：

```yaml
---
# ...

  tasks:
    - name: Take out of load balancer pool
      local_action: ansible.builtin.command /usr/bin/take_out_of_pool {{ inventory_hostname }}

# ...

    - name: Add back to load balancer pool
      local_action: ansible.builtin.command /usr/bin/add_back_to_pool {{ inventory_hostname }}
```

咱们可以使用一项本地操作，调用 `rsync` 将文件递归复制到托管服务器：

```yaml
---
# ...

  tasks:
    - name: Recursively copy files from management server to target
      local_action: ansible.builtin.command rsync -a /path/to/files {{ inventory_hostname }}:/path/to/target/
```

> **译注**：此任务需要远端托管主机上安装 `rsync`，否则会报出错误：`rsync error: error in rsync protocol data stream (code 12) at io.c(231) [sender=3.3.0]` 而导致任务失败。
>
> 参考：[rsync over ssh "error in rsync protocol data stream" (code 12). ssh works](https://askubuntu.com/a/916141)


请注意，必须配置无口令 SSH 密钥，passphrase-less SSH keys，或 `ssh-agent`，这才能运行，否则 `rsync` 会要求输入口令。

要指定更多参数，请使用下面这种语法：


```yaml
---
# ...

  tasks:
    - name: Send summary mail
      local_action:
        module: community.general.mail
        subject: "Summary Mail"
        to: "{{ mail_recipient }}"
        body: "{{ mail_body }}"
      run_once: True
```


> **译注**：使用 `community.general.mail` 插件发送邮件的任务如下所示：


```yaml
    - name: Send summary mail
      local_action:
        module: community.general.mail
        host: smtp.163.com
        username: '{{ sender@example.com }}'
        from: '{{ sender@example.com }}'
        password: 'password_secret'
        subject: "Summary Mail"
        to: "{{ mail_recipient }}"
        body: "{{ mail_body }}"
      run_once: True
```

> 参考：
>
> - [Ansible mail module fails to send email](https://stackoverflow.com/a/65961523)


> **注意**：
>
> - 当存在 `ansible_host` 变量与其他一些连接变量时，那么他们反映的是任务所委派的主机信息，而不是 `inventory_hostname` 的信息；
>
> - 任务委派到的主机，不会从发出任务的主机继承变量。


> **警告**：虽然咱们可以委派给清单中不存在的主机（经由加上 IP 地址、DNS 名称，或任何连接插件其他需要），但这样做不会将主机添加到咱们的仓库，进而可能会造成问题。以这种方式委派的主机，将从 `all` 组继承变量（假设 [`VARIABLE_PRECEDENCE`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#variable-precedence) 包括了 `all_inventory`）。如果咱们必须 `delegate_to` 给非仓库主机，那么请使用 [添加主机模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/add_host_module.html#add-host-module)。


## 委派上下文中的模板化

请注意，在委派情形下，执行解释器（通常为 Python）、`connection`、`become` 和 `shell` 插件的选项，现在将使受委派主机的值，进行模板化。现在，除 `inventory_hostname` 之外的所有变量，都将从该主机而非原任务主机使用。如果咱们需要原始任务主机中的变量用于这些选项，就必须使用 `hostvars[invent_hostname]['varname']`，即使 `inventory_hostname_short`，也指的是受委派主机。


## 委派与并行执行

默认情况下，Ansible 任务是并行执行的。委派某个任务不会改变这一点，也不会处理并发问题（多个分叉写入同一文件）。最常见的情况是，在单个受委派主机上，为所有主机更新单个文件时（例如使用 `copy`、`template` 或 `lineinfile` 模组），用户便会受此影响。他们仍将在并行分叉（默认为 `5`）中运行，并相互覆盖。


这个问题可以不同方法处理：

```yaml
    - name: "handle concurrency with a loop on the hosts with `run_once: true`"
      lineinfile: "<options here>"
      run_once: true
      loop: '{{ ansible_play_hosts_all }}'
```

即通过使用带有 `serial: 1` 的中间 play，或在任务级别使用 `throttle: 1`，更多详情请参阅 [控制 playbook 的执行：策略及其他](strategies.md)。


## 委派事实

Ansible 任务的委派，与现实世界中的任务委派一样 -- 你的杂货属于你，即使是别人送到你家的。同样，经由某个委派任务收集到的任何事实，默认都会指派给 `inventory_hostname`（当前主机），而不是产生事实的主机（受委派主机）。要将收集到的事实指派给受委派主机，而不是当前主机，请将 `delegate_facts` 设置为 `true`：


```yaml
---
- hosts: app_servers

  tasks:
    - name: Gather facts from db servers
      ansible.builtin.setup:
      delegate_to: "{{ item }}"
      delegate_facts: true
      loop: "{{ groups['dbservers'] }}"
```

该任务收集了 `dbservers` 组中机器的事实，并将这些事实指派给这些机器，即使该 play 以 `app_servers` 组为目标。这样，即使 `dbservers` 不是该 play 的一部分，或通过 `--limit` 被排除在外，咱们也可以查找到 `hostvars['dbhost1']['ansible_default_ipv4']['address']`。

## 本地 playbook


在某个远端主机上本地使用 playbook，而不是通过 SSH 连接使用，这种做法可能有用。这对于通过将某个 playbook 放入到一条 `crontab`，以确保系统配置就非常有用。在某种操作系统安装程序里，比如 Anaconda kickstart，这也可能会用到。


要在本地运行整个 playbook，只需将 `hosts:` 行设置为 `hosts： 127.0.0.1`，然后像下面这样运行该 playbook：

```yaml
ansible-playbook playbook.yml --connection=local
```

另外，即使该 playbook 中的其他 play 使用了默认的远端连接类型，也可以在某单个 play 中使用本地连接：


```yaml
---
- hosts: 127.0.0.1
  connection: local
```

> **注意**：如果咱们将连接设置为了本地，并且没有设置 `ansible_python_interpreter`，那么模组就将在 `/usr/bin/python` 下运行，而不是在 `{{ ansible_playbook_python }}` 下运行。请务必设置 `ansible_python_interpreter`： 例如，在 `host_vars/localhost.yml` 中加以设置。咱们可以使用 `local_action` 或 `delegate_to: localhost`，来避免这个问题。
