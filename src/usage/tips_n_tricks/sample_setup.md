# 示例 Ansible 设置


咱们已经了解了 playbook、仓库、角色和变量等。本小节结合了所有这些元素，并概述了一种自动化某个 web 服务的示例设置。


该示例设置按功能组织 playbook、角色、仓库及带有变量的文件。Play 和任务级别的标签，提供了更细的粒度和更大的控制。这是一种强大而灵活的方法，但还有其他组织 Ansible 内容的方法。咱们的 Ansible 用法应符合咱们的需求，所以请随意修改此方法，并相应地组织咱们的内容。



## 示例目录布局

下面这种布局，将大多数任务组织在角色中，其中各个环境都有个仓库文件，且顶层目录中有少量的 playbook：


```console
production                # inventory file for production servers
staging                   # inventory file for staging environment

group_vars/
   group1.yml             # here we assign variables to particular groups
   group2.yml
host_vars/
   hostname1.yml          # here we assign variables to particular systems
   hostname2.yml

library/                  # if any custom modules, put them here (optional)
module_utils/             # if any custom module_utils to support modules, put them here (optional)
filter_plugins/           # if any custom filter plugins, put them here (optional)

site.yml                  # main playbook
webservers.yml            # playbook for webserver tier
dbservers.yml             # playbook for dbserver tier
tasks/                    # task files included from playbooks
    webservers-extra.yml  # <-- avoids confusing playbook with task files
```


```console
roles/
    common/               # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks file can include smaller files if warranted
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for use with the template resource
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            bar.txt       #  <-- files for use with the copy resource
            foo.sh        #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables associated with this role
        defaults/         #
            main.yml      #  <-- default lower priority variables for this role
        meta/             #
            main.yml      #  <-- role dependencies and optional Galaxy info
        library/          # roles can also include custom modules
        module_utils/     # roles can also include custom module_utils
        lookup_plugins/   # or other types of plugins, like lookup in this case

    webtier/              # same kind of structure as "common" was above, done for the webtier role
    monitoring/           # ""
    fooapp/               # ""
```


> **注意**：默认情况下，Ansible 会假定咱们的 playbook 存储在一个目录中，其中角色存储在名为 `roles/` 的子目录中。随着要自动化任务的增多，咱们可以考虑将 playbook 移至名为 `playbooks/` 的子目录中。如果咱们这样做，就必须使用 `ansible.cfg` 文件中的 `roles_path` 设置，配置 `roles/` 目录的路径。


## 替代的目录布局


咱们还可以将各个仓库文件，与其 `group_vars`/`host_vars` 放在一个单独目录中。若咱们的 `group_vars`/`host_vars` 在不同环境中并无太多共同点，这种方法就特别有用。这种布局看起来如下面这个示例：


```yaml
inventories/
   production/
      hosts               # inventory file for production servers
      group_vars/
         group1.yml       # here we assign variables to particular groups
         group2.yml
      host_vars/
         hostname1.yml    # here we assign variables to particular systems
         hostname2.yml

   staging/
      hosts               # inventory file for staging environment
      group_vars/
         group1.yml       # here we assign variables to particular groups
         group2.yml
      host_vars/
         stagehost1.yml   # here we assign variables to particular systems
         stagehost2.yml

library/
module_utils/
filter_plugins/

site.yml
webservers.yml
dbservers.yml

roles/
    common/
    webtier/
    monitoring/
    fooapp/
```


对于大型环境，这种布局赋予了咱们更大的灵活性，以及不同环境之间仓库变量的完全分离。不过，这种方法较难维护，因为文件更多。有关分组和主机变量组织的更多信息，请参阅 [组织主机和组变量](../inventories_building.md#组织主机和组变量)。


## 示例的组与主机变量


以下这些带有变量的示例组和主机文件，包含了适用于各台机器或一组机器的一些值。例如，在亚特兰大的数据中心有其自己的 NTP 服务器。因此，在设置 `ntp.conf` 文件时，咱们就可以使用与下面这个示例中类似的代码：


```yaml
---
# file: group_vars/atlanta
ntp: ntp-atlanta.example.com
backup: backup-atlanta.example.com
```


于此类似，`webservers` 组中的主机，有些不会应用到数据库服务器的配置：

```yaml
---
# file: group_vars/webservers
apacheMaxRequestsPerChild: 3000
apacheMaxClients: 900
```


一些默认值，或确实普遍的值，就要归于名为 `group_vars/all` 的文件：


```yaml
---
# file: group_vars/all
ntp: ntp-boston.example.com
backup: backup-boston.example.com
```

如有必要，咱们可在 `host_vars` 目录下，定义出一些特定于系统硬件差异的变量文件：


```yaml
---
# file: host_vars/db-bos-1.example.com
foo_agent_port: 86
bar_agent_port: 99
```


若咱们使用了 [动态仓库](../dynamic_inventory.md)，Ansible 就会自动创建出许多动态组。因此，像 `class:webserver` 这样的标签，就将自动加载 `group_vars/ec2_tag_class_webserver` 文件中的变量。

> **注意**：咱们可以使用一个名为 `hostvars` 的特殊变量，访问那些主机变量。有关这些特殊变量的列表，请参阅 [特殊变量](https://docs.ansible.com/ansible/latest/reference_appendices/special_variables.html#special-variables)。`hostvars` 这个变量，只能访问到特定于主机的那些变量，而不能访问组变量。


## 按功能组织的示例 playbook

在这种设置下，单个的 playbooks 就能定义整个基础设施。`site.yml` 这个 playbook 会导入另外两个 playbook。一个用于 web 服务器，另一个用于数据库服务器：


```yaml
---
# file: site.yml
- import_playbook: webservers.yml
- import_playbook: dbservers.yml
```

同样位于顶层的 `webservers.yml` 这个 playbook，将 `webservers` 组的配置，映射到与 `webservers` 组相关的两个角色：

```yaml
---
# file: webservers.yml
- hosts: webservers
  roles:
    - common
    - webtier
```


在这种设置下，通过运行 `site.yml`，咱们就可以配置咱们的整个基础设施。此外，要配置仅部分基础设施，就运行 `webservers.yml`。这与 Ansible 的 `--limit` 参数类似，但更明确一些：


```console
ansible-playbook site.yml --limit webservers
ansible-playbook webservers.yml
```

## 基于功能的角色中的示例任务和处理程序文件

Ansible 会加载角色子目录中，任何名为 `main.yml` 的文件。下面这个示例的 `tasks/main.yml` 文件配置了 NTP：


```yaml
---
# file: roles/common/tasks/main.yml

- name: be sure ntp is installed
  yum:
    name: ntp
    state: present
  tags: ntp

- name: be sure ntp is configured
  template:
    src: ntp.conf.j2
    dest: /etc/ntp.conf
  notify:
    - restart ntpd
  tags: ntp

- name: be sure ntpd is running and enabled
  ansible.builtin.service:
    name: ntpd
    state: started
    enabled: true
  tags: ntp
```


下面是个示例的处理程序文件。当某些任务报告变更时，处理程序才会被触发。处理程序会在各个 play 结束时运行：

```yaml
---
# file: roles/common/handlers/main.yml
- name: restart ntpd
  ansible.builtin.service:
    name: ntpd
    state: restarted
```


更多信息，请参阅 [角色](../playbook/using/roles.md)。



## 示例设置的带来了些什么

上面描述的这种基本组织结构，带来了很多不同的自动化选项。要重新配置咱们的整个基础设施：

```console
ansible-playbook -i production site.yml
```

要重新配置所有主机上的 NTP：

```console
ansible-playbook -i production site.yml --tags ntp
```

要仅重新配置 web 服务器：


```console
ansible-playbook -i production webservers.yml
```

要仅重新配置在 Boston 的 web 服务器：


```console
ansible-playbook -i production webservers.yml --limit boston
```


要仅重新配置在 Boston 的前 10 台 web 服务器，及随后的接下来 10 台：


```console
ansible-playbook -i production webservers.yml --limit boston[0:9]
ansible-playbook -i production webservers.yml --limit boston[10:19]
```

这种示例设置同样支持基本的临时命令：


```console
ansible boston -i production -m ping
ansible boston -i production -m command -a '/sbin/reboot'
```

要了解某个特定 Ansible 命令下，哪些任务会运行，或哪些主机名会受影响：

```console
# confirm what task names would be run if I ran this command and said "just ntp tasks"
ansible-playbook -i production webservers.yml --tags ntp --list-tasks

# confirm what hostnames might be communicated with if I said "limit to boston"
ansible-playbook -i production webservers.yml --limit boston --list-hosts
```


## 为部署抑或配置而组织

这种示例设置，演示了一种典型的配置拓扑。在咱们进行多层级的部署时，咱们将很可能需要一些，在各层级间跳转的额外 playbook，以发布应用程序。在这种情形下，咱们可以 `deploy_exampledotcom.yml` 这样 playbook 增强 `site.yml`。不过，上述的一般概念仍然适用。在 Ansible 下，咱们可使用同一工具进行部署和配置。因此，咱们可能将重用组，并将操作系统配置保存在与应用部署不同的单独 playbook 或角色中。

请将 “playbook” 视为一个体育运动的比喻 - 咱们对咱们的基础设施有一套剧本。然后咱们在不同时间、出于不同目的，均有相应的情景剧。


## 使用本地的一些 Ansible 模组


若某个 playbook 有个相对于其 YAML 文件的 `./library` 目录，咱们就可以使用该目录，自动添加一些 Ansible 模组到模组路径中。这样做就能将一些模组与 playbook 组织在一起。例如，请参见本小节开头的目录结构。



（End）


