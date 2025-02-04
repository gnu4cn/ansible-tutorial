# Playbook 示例： 持续交付和滚动升级

## 何谓持续交付？

持续交付（Continuous Delivery, CD），是指频繁地向软件应用，投送更新。

出发点是，通过更频繁地更新，咱们就不必等待特定时间段，而咱们的组织在应对变化过程上，也会变得更好。


有些 Ansible 用户正每小时甚至更频繁地，有时是在每次有批准的代码变更时，就会向最终用户部署更新。为达成这点，咱们需要一些工具，以便能够以零停机时间方式，快速应用这些更新，apply those updates in a zero-downtime way。


本文档以 Ansible 最完整的示例 playbook 之一：`lamp_haproxy` 为模板，详细介绍了如何实现这一目标。该示例使用了大量 Ansible 功能：角色、模板与组变量等，而且还附带了一个可对 web 应用程序栈，进行零停机滚动升级的编排 playbook。

这些 playbook 会将 Apache、PHP、MySQL、[Nagios](https://www.nagios.org/) 和 HAProxy，部署到一组基于 CentOS 的服务器上。

我们（作者）不会在此介绍如何运行这些 playbook。请阅读 GitHub 项目中的 README，以及示例以获取相关信息。相反，我们将仔细研究该 playbook 的每一部分，并描述其做了些什么。

> **译注**：Ansible 示例的 GitHub 在 [ansible/ansible-examples](https://github.com/ansible/ansible-examples)。其中可以找到 `lamp_haproxy` 这个示例。


## 站点部署

咱们从 `site.yml` 开始。这是咱们整个站点的部署 playbook。他可用于初始部署站点，以及向所有服务器推送更新：


```yaml
{{#include ../../../../playbook_example/site.yml}}
```

> **注意**：若咱们对 playbook 及 play 等术语不熟悉，那么应该复习一下 [“使用游戏本”](../using.md)。

在这个 playbook 中，咱们有 5 个 play。第一个以 `all` 主机为目标，并将 `common` 这个角色应用于所有主机。这是对整个站点的，比如 yum 软件包仓库配置、防火墙配置及其他需要应用到所有服务器的配置。

接下来的四个 play，会针对特定主机组运行，并将特定角色应用于这些服务器。除了用于 Nagios 监控、数据库和 Web 应用程序的角色外，咱们还实现了个安装和配置基本 Apache 设置的 `base-apache` 角色。该角色同时被其中的示例 web 应用及 Nagios 主机用到。


## 可重用内容：角色


现在，咱们应该对角色，及其在 Ansible 中的工作方式有了一些了解。角色是种将任务、处理程序、模板和文件等内容，组织成可重用组件的方式。

此示例有 6 个角色：`common`、`base-apache`、`db`、`haproxy`、`nagios` 和 `web`。如何组织角色由咱们及咱们的应用程序决定，但大多数站点，都会有一或多个应用到所有系统的 `common` 角色，然后是一系列用于安装和配置站点的特定部分，特定于应用的角色。

角色可以有变量与依赖项，且咱们可向角色传递参数，以修改其行为。有关角色的更多信息，请参阅 [“角色”](roles.md) 小节。


## 配置：组变量

组变量是应用到服务器组的变量。在模板与 playbook 中，他们被用于定制行为，以及提供易于更改的设置和参数。他们存储在与咱们仓库文件的同一位置，名为 `group_vars` 的目录中。下面是 `lamp_haproxy` 的 `group_vars/all` 文件。如咱们所料，这些变量会被应用到咱们仓库中的所有机器：


```yaml
---
httpd_port: 80
ntpserver: 192.0.2.23
```


这是个 YAML 文件，且咱们可以创建出更复杂变量结构的列表和字典。在本例中，我们只需设置两个变量，一个是 web 服务器的端口，另一个是咱们这些机器，应用于时间同步的 NTP 服务器。

下面是另一组变量文件。这是会应用到 `dbservers` 组中主机的 `group_vars/dbservers`：


```yaml
---
db_service: postgresql
db_port: 5432
dbuser: root
dbname: foodb
upassword: usersecret
```

若咱们检查一下这个示例，就会发现类似地，`webervers`  和 `lbservers` 组都有一些组变量。

这些变量会用在多个地方。咱们可在 playbook 中使用他们，比如在 `roles/db/tasks/main.yml` 中：


```yaml
- name: Create Application Database
  postgresql_db:
    name: "{{ dbname }}"
    state: present

- name: Create Application DB User
  postgresql_user:
    name: "{{ dbuser }}"
    password: "{{ upassword }}"
    priv: "*.*:ALL"
    host: '%'
    state: present
```

咱们还可以在模板中，使用这些变量，比如在 `roles/common/templates/ntp.conf.j2` 中：


```yaml
driftfile /var/lib/ntp/drift

restrict 127.0.0.1
restrict -6 ::1

server {{ ntpserver }}

includefile /etc/ntp/crypto/pw

keys /etc/ntp/keys
```

咱们可以看到，`{{` 和 `}}` 的变量替换语法，对模板和变量都是一样的。花括号内的语法，是 Jinja2 的语法，咱们可对花括号内的数据进行各种操作，以及应用不同过滤器。在模板中，咱们还可使用 `for` 循环和 `if` 语句，处理更复杂的情况，就像在这个 `roles/common/templates/iptables.j2` 中的这样：

```yaml
{% if inventory_hostname in groups['dbservers'] %}
-A INPUT -p tcp  --dport 5432 -j  ACCEPT
{% endif %}
```

这是在测试我们当前运行机器的仓库名称（`inventory_hostname`），是否存在于仓库组 `dbservers` 中。如果是，那么该机器将获得一个 `5432` 端口的 iptables `ACCEPT` 行。

下面是同一模板中的另一个例子：

```yaml
{% for host in groups['monitoring'] %}
-A INPUT -p tcp -s {{ hostvars[host].ansible_default_ipv4.address }} --dport 5666 -j ACCEPT
{% endfor %}
```

这会循环遍历 `monitoring` 组中的所有主机，并在当前机器的 iptables 配置中，为各个监控主机的默认 IPv4 地址添加 `ACCEPT` 行，以便 Nagios 可以监控这些主机。

咱们可在 [这里](https://jinja.palletsprojects.com/)，了解有关 Jinja2 及其能力的更多信息，也可以在 [“使用变量”](vars.md) 小节，阅读有关 Ansible 变量的更多信息。


## 滚动更新

现在，咱们已经拥有了一个完全部署好的站点，包括 web 服务器、负载均衡器和监控。咱们要如何更新呢？这就是 Ansible 的编排功能发挥作用的地方。有些应用程序使用 “编排，orchestration” 一词，表示基本的排序或命令执行，而 Ansible 将编排称为 “像管弦乐队一样指挥机器”，并为此提供了一个相当复杂的引擎。

Ansible 具备以协调方式，对多层应用程序进行操作的能力，因此可以轻松地对我们的 web 应用，进行复杂的零停机滚动升级。这是在一个名为 `rolling_update.yml` 的单独 playbook 中实现的。


查看剧本，咱们可以看到他由两个 play 组成。第一个 play 非常简单，看起来像这样：


```yaml
- hosts: monitoring
  tasks: []
```

这是怎么回事，为什么没有任务？咱们可能知道，在对服务器进行操作前，Ansible 会从服务器收集 “事实”。这些事实对各种事情都很有用：网络信息、操作系统/发行版的版本等等。在咱们的示例中，咱们需要在执行更新前，了解咱们环境中所有监控服务器的一些情况，因此这个简单 play，会在咱们的监控服务器上，强制执行一次收集事实步骤。咱们有时会看到这种模式，这是个要掌握的有用技巧。


下一部分便是更新 play 了。其中第一部分是这样的：


```yaml
- hosts: webservers
  user: root
  serial: 1
```

这只是个在 `webservers` 组上操作的普通 play 定义。`serial` 关键字告诉 Ansible，一次要在多少台服务器上操作。若其未指定，Ansible 将在不超过配置文件中，指定的默认 `fork` 限制的远端主机上，并行执行操作。而为了零停机的滚动升级，咱们就可能不会想要同时在这么多主机上操作。如果咱们只有少数几台 web 服务器，咱们可能希望将 `serial` 设置为 `1`，即一次只对一台主机进行操作。若咱们有 100 台主机，或许可将 `serial` 设置为 `10`，一次对 10 台主机进行操作。


下面是这个更新 play 的下一部分：


> **注意**：
>
> - `serial` 关键字会强制 play 分 “批次” 执行。每个批次都算作对这些主机某个子选择的一个完整 play。这会对 play 的行为产生一些影响。例如，如果某个批次中的所有主机都失败了，则整个运行都会失败。在与 `max_fail_percentage` 结合使用时，咱们应考虑到这点。

```yaml
pre_tasks:
- name: disable nagios alerts for this host webserver service
  nagios:
    action: disable_alerts
    host: "{{ inventory_hostname }}"
    services: webserver
  delegate_to: "{{ item }}"
  loop: "{{ groups.monitoring }}"

- name: disable the server in haproxy
  shell: echo "disable server myapplb/{{ inventory_hostname }}" | socat stdio /var/lib/haproxy/stats
  delegate_to: "{{ item }}"
  loop: "{{ groups.lbservers }}"
```


`pre_tasks` 这个关键字，只是让咱们列出，在调用角色之前要运行的任务。这点稍后会更有意义。若咱们检视这些任务的名称，就会发现咱们正在禁用 Nagios 告警，然后从 HAProxy 负载均衡池中，移除当前正在更新的 web 服务器。


`delegate_to` 和 `loop` 的参数，是一起使用的，这就造成 Ansible 会循环每个监控服务器和负载均衡器，并 “代表” 该 web 服务器在监控服务器，或负载均衡服务器上执行该操作（委派该操作）。用编程术语来说，外循环是 web 服务器的列表，而内循环则是监控服务器的列表。


请注意，HAProxy 这步看起来有点复杂。咱们在本例中使用 HAProxy，是因为他是免费可用的，不过如果咱们的基础设施中有比如 F5 或 Netscaler（或者咱们有 AWS 弹性 IP 设置？），则可使用 Ansible 的一些模组，与他们进行通信。咱们也可以使用别的监控模组代替 Nagios，不过这只是说明 `'pre task'`  小节的主要目标 -- 将服务器从监控中移出，使其脱离轮替。


下一步就只是将适当的角色，重新应用到这些 web 服务器。这将引发 `web` 和 `base-apache` 角色中的任何配置管理声明，应用到这些 web 服务器，包括web 应用代码本身的更新。我们不一定非要这样做 -- 我们也可以只更新 web 应用，但这是个很好的例子，说明了如何使用角色，来重用任务：


```yaml
roles:
- common
- base-apache
- web
```
