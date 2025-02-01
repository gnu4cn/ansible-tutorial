# 发现变量：事实和魔法变量

使用 Ansible，咱们可以检索或发现一些包含远端系统，或 Ansible 本身信息的变量。与远端系统相关的变量，被称为事实，facts。有了事实，咱们就可以把一个系统的行为或状态，用作别的系统的配置。例如，咱们可以把某个系统的 IP 地址，作为另一系统的配置值。与 Ansible 相关的变量，被称为魔法变量，magic variables。


## Ansible 事实


所谓 Ansible 事实，是与咱们远端系统相关的数据，包括操作系统、IP 地址、连接的文件系统等。咱们可在 `ansible_facts` 变量中，访问这些数据。默认情况下，咱们也可以 `ansible_` 前缀的顶层变量形式，访问某些 Ansible 事实。咱们可使用 [`INJECT_FACTS_AS_VARS`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#inject-facts-as-vars)，设置禁用这一行为。要查看所有可用事实，请将此任务添加到某个 play：


```yaml
    - name: Print all available facts
      ansible.builtin.debug:
        var: ansible_facts
```


而要查看收集到的 “原始” 信息，请在命令行下运行此命令：

```console
ansible <hostname> -m ansible.builtin.setup
```

> **译注**：这里仍然需要指定仓库文件，如下所示：

```console
ansible -i ansible_quickstart/inventory_updated.yaml debian-199 -m ansible.builtin.setup
```

事实包括了大量变量数据，这些数据可能如下所示：

```json
{{#include demo_facts.json}}
```

咱们可在模板或 playbook 中，引用以上所示事实中第一个磁盘的型号：

```yaml
{{ ansible_facts['devices']['xvda']['model'] }}
```


要引用系统的主机名：

```yaml
{{ ansible_facts['nodename'] }}
```


