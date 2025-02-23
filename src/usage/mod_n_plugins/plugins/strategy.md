# 策略插件

策略插件通过处理任务和主机调度，控制 play 执行的流程。有关使用策略插件及控制执行顺序的其他方式的更多信息，请参阅 [控制 playbook 的执行：策略及其他](../../playbook/executing/strategies.md)。


## 启用策略插件

所有随 Ansible 提供的策略插件，默认均已启用。通过将某个策略插件，放在 [`ansible.cfg`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) 中配置的查找目录来源之一中，咱们就可以启用该策略插件。


## 使用策略插件

一个 play 中只能使用一种策略插件，但咱们可在某个 playbook 或某次 Ansible 运行的各个 play 中，使用不同的策略插件。默认情况下，Ansible 会使用 `linear` 这个策略插件。使用下面这个环境变量，咱们即修改 Ansible 配置中的这一默认设置：

```console
export ANSIBLE_STRATEGY=free
```

或在 `ansible.cfg` 文件中：


```ini
[defaults]
strategy=linear
```


咱们还可在某个 play 中，使用 `strategy` 关键字指定出该 play 中的策略插件：

```yaml
- hosts: all
  strategy: debug
  tasks:
    - copy:
        src: myhosts
        dest: /etc/hosts
      notify: restart_tomcat

    - package:
        name: tomcat
        state: present

  handlers:
    - name: restart_tomcat
      service:
        name: tomcat
        state: restarted
```


## 插件列表

咱们可使用 `ansible-doc -t strategy -l` 命令查看可用插件的列表。使用 `ansible-doc -t strategy <plugin name>` 查看特定插件的文档与示例。


（End）

