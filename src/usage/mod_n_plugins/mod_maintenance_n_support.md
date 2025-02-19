# 模组的维护与支持

如果咱们正使用某个模组，而咱们发现了个 bug，那么就可能想知道，要在哪里报告该 bug，谁负责修复他，以及咱们可以怎样跟踪模组的更改。若咱们是 Red Hat 订阅用户，就可能想知道，咱们所面临问题能否能获得支持。


从 Ansible 2.10 开始，大多数模组都存在于专辑中了。各个专辑的发布方式，反映了该专辑中模组的维护和支持情况。


## 维护问题

| 专辑 | 代码位置 | 由谁维护 |
| :-- | :-- | :-- |
| `ansible.builtin` | GitHub 上的 [`ansible/ansible`](https://github.com/ansible/ansible/tree/devel/lib/ansible/modules) 代码仓库。 | 核心团队。 |
| 在 [Galaxy](https://galaxy.ansible.com/) 上发布的专辑。 | 各不相同；请依照 `repo` 所指的链接。 | 社区或合作方。 |
| 在 [Automation Hub](https://www.ansible.com/products/automation-hub/) 上发布的专辑。 | 各不相同；请依照 `repo` 所指的链接。 | 内容团队或合作方。 |


## 问题报告

**Issue Reporting**


若咱们发现了个影响到主 Ansible 代码库，亦即 `ansible-core` 中某个插件的 bug：

1. 请确认咱们运行的是 Ansible 的最新稳定版本，还是开发分支；
2. 查看 [Ansible 代码库中的 issue tracker](https://github.com/ansible/ansible/issues)，看看该问题是否已被提交；
3. 如果 issue tracker 上还没有这个问题，那么请创建一个 issue。请包含尽可能多的有关咱们所发现行为的细节。


若咱们发现了个影响到 Galaxy 专辑中某个插件的 bug：


1. 在 Galaxy 上找到该专辑；
2. 找到该专辑的 issue tracker；
3. 看看那里该问题是否已被提交；
4. 如果 issue tracker 上还没有这个问题，那么创建一个。请尽可能多地包含咱们所发现行为的细节。


一些合作方专辑，可能会托管在在私有代码库中。


若咱们不确定咱们所见到的行为是否是个 bug，若咱们有些问题，咱们想讨论一些面向专辑开发的话题，或者咱们只是想取得联系，请访问 [Ansible 通信指南](https://docs.ansible.com/ansible/latest/community/communication.html#communication)，获取有关如何加入社区的信息。


若咱们发现了个影响到某 Automation Hub 专辑中，某个模组的 bug：


1. 若该专辑在 Automation Hub 上提供了 Issue Tracker，那么请单击该处并开启一个有关该专辑代码库的问题。如果该专辑没有提供 Issue Tracker，则请依照在 [Red Hat 客户门户网站](https://access.redhat.com/) 上报告问题的流程。要在该门户网站上创建问题，咱们有一份 Red Hat Ansible 自动化平台的订阅。


## 支持

保留在 [`ansible-core`] 中的所有插件，与托管在 Automation Hub 中的全部专辑，都受 Red Hat 支持。其他插件或专辑则不受 Red Hat 支持。若咱们订阅了 Red Hat Ansible 自动化平台，则可在 [Red Hat 客户门户网站](https://access.redhat.com/) 上，找到更多信息和资源。


（End）


