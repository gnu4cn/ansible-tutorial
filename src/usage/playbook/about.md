# 关于 Ansible playbook

Ansible playbook 提供了一种可重复、可重用、简单的配置管理与多机部署系统，非常适合部署复杂的应用程序。如果咱们需要使用 Ansible 多次执行某项任务，就可以编写个 playbook 并将其置于源代码控制系统之下。然后，咱们就可以使用该 playbook，推送新配置或确认远端系统的配置。


Playbook 可以做到：

- 声明配置；
- 在多组机器上，按照预定顺序，编排任何手动作业流程的那些步骤；
- 同步或 [异步地](playbook/executing.md) 启动任务；

## Playbook 语法

Playbook 以语法极少的 YAML 格式表达。如果咱们不熟悉 YAML，请参阅我们的 [YAML 语法](../refs/YAML_syntax.md) 概述，并考虑为咱们的文本编辑器安装个插件（请参阅 [其他工具和程序](https://docs.ansible.com/ansible/latest/community/other_tools_and_programs.html#other-tools-and-programs)），帮助咱们在 playbook 中，编写出简洁的 YAML 语法。


Playbook 由位于一个有序列表中的，一或多个 play 组成。“playbook” 和 "play" 两个词语，是体育运动中的比喻。其中的每个 play， 都会执行该 playbook 总体目标的一部分，运行一或多个任务。每个任务都会调用一个 Ansible 模组。


## Playbook 的执行

Playbook 会以从上到下的顺序运行。在每个 play 中，任务也会依从上到下的顺序运行。带有多个 play 的 playbook，可以编排多机的部署，在 `webservers` 上运行一个任务，然后在数据库服务器上运行另一任务，然后在网络基础设施上运行第三个任务，依此类推。每个 play 至少要定义两件事：


- 使用 [模式](patterns.md) 指定出的所面向的托管节点；
- 至少一项要执行的任务。

> **注意**：在 Ansible 2.10 及更高版本中，建议咱们在 playbook 中使用完全限定的专辑名称，以确保选择了正确的模组，因为多个集合可能包含同名的模组（比如 `user`）。请参阅 [在 playbook 中使用专辑](collection/using.md)。


在下面这个示例中，第一个 play 的目标是那些 web 服务器；第二个 play 的目标是数据库服务器。

```yaml
{{#include playbook.yml}}
```

咱们的 playbook 不仅可以包含主机行和任务。例如，上面的 playbook 就为每个 play 设置了个 `remote_user`。这是用于 SSH 连接的用户帐户。在 playbook、play 或任务级别，咱们均可添加其他 [playbook 关键字](../../refs/playbook_keywords.md)，来影响 Ansible 的行为方式。 Playbook 关键字可以控制 [连接插件](../../plugins/connection.md)、是否使用 [权限提升](executing.md)、如何处理错误等等。为了支持各种环境，Ansible 允许咱们以命令行开关方式、在Ansible 配置中，或在仓库中，设置这许多的参数。了解这些数据源的[优先级规则](../../refs/precedence.md)，将有助于咱们扩展咱们的 Ansible 生态。

### 任务执行

默认情况下，Ansible 会对匹配主机模式的所有机器，依次执行每个任务，一次一个。每个任务都会以特定参数，执行某个模组。当某个任务在所有目标机器上都执行完毕后，Ansible 就会进入下一任务。咱们可以使用 [策略](executing.md)，改变这种默认行为。在每个任务中，Ansible 会对所有主机，应用相同的任务指令。如果某个任务在某台主机上失败了，Ansible 就会将该主机从该 playbook 的其余部分的轮换中移除。


咱们运行某个 playbook 时，Ansible 会返回连接信息、所有 play 与任务的 `name` 行、每个任务在各台机器上是成功还是失败，以及每个任务是否在各台机器上造成了变动。在 playbook 执行底部，Ansible 会提供目标节点及其执行情况的摘要。一般故障与致命的 `unreachable` 通信尝试次数，在统计中是分开的。


### 期望状态与 “幂等性”

**Desired state and 'idempotency'**


大多数 Ansible 模组都会检查，所期望的最终状态是否已经达到，且如果已经达到该状态，就会退出而不执行任何操作，这样重复该任务就不会改变最终状态。以这种方式行事的模组，通常被称为 “幂等的”。无论咱们运行一次还是多次 playbook，结果都应一致。不过，并非所有 playbook 和模组都是如此。如果咱们不确定，就要在沙箱环境中测试咱们的 playbook，然后才在生产环境中多次运行他们。


### 运行 playbook

要运行咱们的 playbook，请使用 [`ansible-playbook`](../cli/ansible-playbook.md) 命令。


```console
ansible-playbook playbook.yml -f 10
```

运行 playbook 时使用 `--verbose` 开关，可查看成功模组和未成功模组的详细输出。


### 在检查模式下运行 playbook


Ansible 的检查模式，允许咱们在不对系统进行任何改动的情况下，执行 playbook。在生产环境中执行前，咱们可使用检查模式来测试 playbook。

要在检查模式下运行某个 playbook，咱们可以向 `ansible-playbook` 命令，传递 `-C` 或 `--check` 开关：


```console
ansible-playbook --check playbook.yml
```


执行该命令将正常运行 playbook，但 Ansible 不会应用任何更改，而只提供一份说明其所做修改的报告。该报告会包含文件修改、命令执行及模组调用等的详细信息。

检查模式提供了一种安全实用的方法，在不冒着对系统进行意外更改风险下，检查 playbook 的功能。此外，他还是一种可用于对未如预期发挥作用的 playbook，进行故障排除的宝贵工具。


## `ansible-pull`

如果咱们想逆转 Ansible 架构，让节点签入到某个中心位置，而不是将配置推送给他们，咱们就可以这样做。

`ansible-pull` 是个小脚本，他将从 `git` 签出一个包含配置说明的代码仓库，然后根据这些内容运行 `ansible-playbook`。

假设咱们对签出位置进行了负载平衡，那么 `ansible-pull` 基本上可以无限扩展。

请运行 `ansible-pull --help` 了解详情。


## 验证 playbook


在运行 playbook 之前，咱们可能想要验证他们，以发现语法错误及其他问题。`ansible-playbook` 命令提供了多个验证选项，包括 `--check`、`--diff`、`--list-hosts`、`--list-tasks` 和 `--syntax-check` 等。[验证 playbook 的工具](https://docs.ansible.com/ansible/latest/community/other_tools_and_programs.html#validate-playbook-tools) 介绍了验证和测试 playbook 的一些其他工具。


### `ansible-lint`

在执行 playbook 之前，咱们可使用 [`ansible-lint`](https://ansible.readthedocs.io/projects/lint/) ，获取到咱们 playbook 的详细、特定于 Ansible 的反馈。例如，如果咱们对在本页顶部附近的名为 `verify-apache.yml` 的 playbook 运行 `ansible-lint`，应会得到以下结果：

```console
$ ansible-lint verify-apache.yml
[403] Package installs should not use latest
verify-apache.yml:8
Task/Handler: ensure apache is at the latest version
```

[`ansible-lint` 默认规则页面](https://ansible.readthedocs.io/projects/lint/rules/) 描述了每种错误。对于 `[403]`，建议的修复方法是将 playbook 中的 `state: latest` 改为 `state: present`。


（End）


