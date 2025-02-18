# 模组介绍

模组（也称为 “任务插件” 或 “库插件”）是一些可在命令行上，或在某个 playbook 任务中使用的分离代码单元。Ansible 通常会在远端托管节点上，执行各个模组，并收集返回值。在 Ansible 2.10 及更高版本中，大多数模组都托管在专辑中了。


咱们可在命令行上执行模组：


```console
ansible webservers -m service -a "name=httpd state=started"
ansible webservers -m ping
ansible webservers -m command -a "/sbin/reboot -t now"
```

每个模组都支持一些参数。几乎所有模组都会取一些以空格分开的 `key=value` 参数。有些模组则不取参数，而 `command`/`shell` 模组，就只取咱们要运行命令的字符串。


在 playbook 中，Ansible 模组会以非常类似的方式被执行。


```yaml
- name: reboot the servers
  command: /sbin/reboot -t now
```

另一种传递参数给模组的方式，是使用 YAML 语法，这也称为 “复参，complex args”。


```yaml
- name: restart webserver
  service:
    name: httpd
    state: restarted
```

所有模组都会返回 JSON 格式的数据。这意味着模组可以任何编程语言编写。模组应是幂等性的，并在检测到当前状态与所需的最终状态一致时，应避免进行任何更改。当于 Ansible playbook 中被用到时，模组可触发通知 [处理程序](../playbook/using/handlers.md)，以运行额外任务形式的 `'change events'`。

使用 `ansible-doc` 工具，咱们可以在命令行，访问到各个模组的文档。


```console
ansible-doc yum
```

有关所有可用模组的列表，请参阅 [`Collection` 文档](https://docs.ansible.com/ansible/latest/collections/index.html#list-of-collections)，或在命令提示符下运行下面这个命令。

```console
ansible-doc -l
```

（End）


