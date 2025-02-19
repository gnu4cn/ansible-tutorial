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

可以在条件（参见 [条件](conditionals.md)）以及模板中，使用事实。咱们还可以使用事实，创建符合特定条件的动态主机组，详情请查看 [`group_by` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/group_by_module.html#group-by-module) 文档。

> **注意**：由于 `ansible_date_time` 是每次运行 playbook 前，Ansible 收集事实时创建并缓存的，因此在一些长时间运行的 playbook 下，就可能会过时。如果咱们的 playbook 需要长时间运行，就要使用 `pipe` 过滤器（例如，`lookup('pipe', 'date +%Y-%m-%d.%H:%M:%S')`），或使用 Jinja 2 模板的 `now()`，代替 `ansible_date_time`。

### 事实收集的软件包需求

在某些发行版上，咱们可能会看到一些缺失事实值，或设置为默认值的事实，因为支持收集这些事实的软件包默认未安装。咱们可在远端主机上，使用操作系统的软件包管理器，安装这些必要软件包。已知的依赖包包括：

- Linux 的网络事实收集 - 依赖于 `ip` 这个二进制命令，通常包含在 `iproute2` 软件包中。


### 缓存事实

与注册的变量一样，事实默认都存储在内存中。不过，与注册的变量不同，事实可被独立收集并缓存下来，供重复使用。有了缓存的事实，在配置某第二个系统时，即使 Ansible 先在第二个系统上执行当前 play，咱们也可以参考某一个系统中的事实。例如：

```yaml
{{ hostvars['asdf.example.com']['ansible_facts']['os_family'] }}
```

缓存是由缓存插件控制的。默认情况下，Ansible 使用的是在当前 playbook 运行期间，将事实存储在内存中的内存缓存插件。要保留 Ansible 事实以供重复使用，就要选择别的缓存插件。详情请参阅 [缓存插件](https://docs.ansible.com/ansible/latest/plugins/cache.html#cache-plugins)。

事实的缓存，可以提高性能。若咱们管理着数千台主机，那么就可以将事实缓存配置为每晚运行，然后在全天定期对较小的某组服务器上的配置进行管理。有了缓存事实，即使只管理少量服务器，咱们也能访问所有主机的变量和信息。

### 关闭事实

默认情况下，Ansible 会在每个 play 开始时收集事实。如果咱们不需要收集事实（例如，如果咱们对咱们的系统所有情况都了如指掌），就可以在 play 级别关闭事实收集，以提高可扩张性。在托管系统数量非常多的推送模式下，或者在实验平台上使用 Ansible，关闭事实收集尤其能提高性能。要关闭事实收集：

```yaml
- hosts: whatever
  gather_facts: false
```


### 添加定制事实

Ansible 中的设置模组，会自动发现每台主机的标准事实集。若咱们打算在事实中，添加一些定制的值，则可以编写某个定制的事实模组、使用一个 `ansible.builtin.set_fact` 任务设置一些临时事实，或使用 `facts.d` 目录提供一些永久的定制事实。


**`facts.d` 或本地事实**

*版本 1.3 中的新特性*。


咱们可以通过向 `facts.d` 添加静态文件，来添加一些静态定制事实，或者向 `facts.d` 添加可执行脚本来添加一些动态事实。例如，咱们可以通过在 `facts.d` 中创建并运行脚本，来添加主机上所有用户的一个列表。

要使用 `facts.d`，就在远端主机上，创建 `/etc/ansible/facts.d` 目录。若咱们偏好别的目录，可以创建出目录，并使用 `fact_path` 这个 play 关键字指定出来。向该目录添加文件，以提供到咱们的定制事实。所有文件名必须以 `.fact` 结尾。文件可以是 JSON、INI 或返回 JSON 的可执行文件。


要添加静态事实，只需添加扩展名为 `.fact` 的文件即可。例如，创建包含以下内容的 `/etc/ansible/facts.d/preferences.fact`：

```ini
[general]
asdf=1
bar=2
```

> **注意**：要确保该文件不可执行，否则会破坏 `ansible.builtin.setup` 模组。

下次事实收集运行时，咱们的事实将包含一个名为 `general` 的哈希变量事实，其成员为 `asdf` 和 `bar`。要验证这点，请运行以下命令：


```console
ansible -i ansible_quickstart/inventory_updated.yaml almalinux-5 -m ansible.builtin.setup -a "filter=ansible_local"
```

咱们将看到，咱们的定制事实已添加：

```json
almalinux-5 | SUCCESS => {
    "ansible_facts": {
        "ansible_local": {
            "preferences": {
                "general": {
                    "asdf": "1",
                    "bar": "2"
                }
            }
        },
        "discovered_interpreter_python": "/usr/bin/python3.9"
    },
    "changed": false
}
```

`ansible_local` 这个命名空间，将由 `facts.d` 创建的自定义事实，与系统事实或 playbook 中其他地方定义的变量分开，因此变量之间不会相互覆盖。咱们可在模板或 playbook 中，访问该定制事实：

```yaml
{{ ansible_local['preferences']['general']['asdf'] }}
```


> **注意**：`key=value` 键值对中的关键字部分，在 `ansible_local` 变量中将被转换为小写。以上面的例子为例，如果那个 `ini` 文件的 `[general]` 小节包含了 `XYZ=3`，那么访问他的方式应该是 `{{ ansible_local['preferences']['general']['xyz'] }}`，而不是 `{{ ansible_local['preferences']['general']['XYZ'] }}`。这是因为 Ansible 使用了 Python 的 [`ConfigParser`](https://docs.python.org/3/library/configparser.html)，他通过 [`optionxform`](https://docs.python.org/3/library/configparser.html#ConfigParser.RawConfigParser.optionxform) 方法，传递所有选项名，而该方法的默认实现会将选项名转换为小写。


咱们还可使用 `facts.d`，在远端主机上执行脚本，向 `ansible_local` 命名空间生成一些动态的定制事实。例如，咱们可以生成一个远端主机上所有用户的列表，作为该主机的一项事实。要使用 `facts.d` 生成动态的定制事实：

1. 编写并测试一个生成所需 JSON 数据的脚本；
2. 将该脚本保存在咱们的 `facts.d` 目录下；
3. 确保咱们的脚本有着 `.fact` 文件扩展名；
4. 确保咱们的搅拌可由 Ansible 连接用户执行；
5. 要开启 `gather_facts` 以执行到该脚本，并将其 JSON 输出添加到 `ansible_local`。

> **译注**：通常咱们需要借助 [`jq`](https://jqlang.org/) 这个实用工具，从脚本产生 JSON 输出。
>
> 参考：
>
> - [How to Easily Create a JSON File in Bash](https://www.benjaminrancourt.ca/how-to-easily-create-a-json-file-in-bash/)

默认情况下，事实收集会在每个 play 开始时运行一次。如果咱们在某个 playbook 中使用 `facts.d` 创建了某项定制事实，那么他将在下一个收集事实的 play 中可用。如果咱们想在创建事实的同一 play 中使用他，就必须显式地重新运行 `setup` 模组。例如：

```yaml
{{#include ../../../../ansible_quickstart/custome_facts_demo.yml}}
```

如果咱们频繁使用这种模式，那么定制事实模组，会比 `facts.d` 效率更高。

> **译注**：下面是个输出 Linux 主机上用户列表的脚本，其借助 `jq` 产生 JSON 字符串。

```bash
{{#include ../../../../ansible_quickstart/ipmi.fact}}
```


## 关于 Ansible 的信息：魔法变量

咱们可以使用 “魔法” 变量，访问有关 Ansible 操作的信息，包括正使用的 Python 版本、仓库中的主机和组，以及 playbook 和角色的目录等。与连接变量一样，魔法变量也属于 [特殊变量](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#special-variables)。魔法变量名称是保留的 - 因此不要使用这些名称设置变量。`environment` 这个变量也是保留的。

最常用的魔法变量分别是 `hostvars`、`groups`、`group_names` 及 `inventory_hostname`。使用 `hostvars`，咱们就能在 playbook 的任何位置，访问为 play 中任何主机定义的变量。咱们也可使用 `hostvars` 这个变量，访问到 Ansible 事实，但只能在收集（或缓存）了事实之后。请注意，在 play 的对象中定义的变量，不是为特定主机定义的，因此不会映射到 `hostvars`。


若咱们打算使用另一节点的某个 `fact` 的值，或指派给另一节点的某个仓库变量的值，来配置数据库服务器，就可以在模板或某个操作行中，使用 `hostvars`：

```yaml
{{ hostvars['test.example.com']['ansible_facts']['distribution'] }}
```

而使用 `groups`，即仓库中中所有组（以及主机）的一个列表，咱们就可以枚举出某个组内的所有主机。例如：

```yaml
{% for host in groups['app_servers'] %}
   # something that applies to all app servers.
{% endfor %}
```

咱们可以同时使用 `groups` 和 `hostvars`，找到某个组中的所有 IP 地址。


```yaml
{% for host in groups['app_servers'] %}
   {{ hostvars[host]['ansible_facts']['eth0']['ipv4']['address'] }}
{% endfor %}
```

> **译注**：模板文件中的组名 `app_servers` 要与 playbook YAML 文件中 `hosts: app_servers` 组别一致，否则会报出错误：`"AnsibleUndefinedVariable: 'dict object' has no attribute 'enp1s0'"`。


咱们可以使用这种方法，将某个前端代理服务器，指向咱们应用程序服务器组中的所有主机，以及在服务器之间设置正确的防火墙规则等。在填充模板的任务前，咱们必须为这些主机缓存好事实，或收集到事实。

使用 `group_names`，即当前主机所在的全部组的一个列表（数组），咱们就可以创建出根据主机的所属组（或角色），而不同的模板文件：

```yaml
{% if 'webserver' in group_names %}
   # some part of a configuration file that only applies to webservers
{% endif %}
```

当事实收集被关闭时，咱们可以使用魔法变量 `inventory_hostname`，即在仓库中配置的主机名，作为 `ansible_hostname` 的替代。如果咱们的 FQDN 较长，则可以使用 `inventory_hostname_short`，其包含第一个句点之前的部分，而不包含域的其余部分。

别的一些有用魔法变量，指向了当前 play 或 playbook。对于要以多个主机名的填充模板，或将列表注入负载均衡器的规则中等情况，这些变量就很有用。


- `ansible_play_hosts` 为当前 play 中，仍处于活动状态的所有主机列表；
- `ansible_play_batch` 是该 play 的当前 “批次” 范围内的主机名列表；
批次数量由 `serial` 定义，在未设置时相当于整个 play（从而令到其与 `ansible_play_hosts` 相同）。

- `ansible_playbook_python` 是用于调用 Ansible 命令行工具的 Python 可执行文件路径；
- `inventory_dir` 是存放 Ansible 仓库主机文件的目录路径名；
- `inventory_file` 是指向 Ansible 仓库主机文件的路径名与文件名；
- `playbook_dir` 包含着 playbook 的基础目录；
- `role_path` 包含当前角色的路径名，且仅在角色内部有效；
- `ansible_check_mode` 是个布尔值，如果使用了 `--check` 运行 Ansible，则就被设置为了 `True`。


### Ansible 版本号

*版本 1.8 中的新特性*。

要将 playbook 的行为，与不同版本的 Ansible 适配，咱们可以使用 `ansible_version` 这个变量，其具有以下结构：

```json
    {
        "full": "2.18.1",
        "major": 2,
        "minor": 18,
        "revision": 1,
        "string": "2.18.1"
    }
```


（End）
