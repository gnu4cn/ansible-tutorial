# Playbook 示例： 持续交付和滚动升级

## 何谓持续交付？

持续交付（Continuous Delivery, CD），是指频繁地向软件应用，投送更新。

出发点是，通过更频繁地更新，咱们就不必等待特定时间段，而咱们的组织在应对变化过程上，也会变得更好。


有些 Ansible 用户正每小时甚至更频繁地，有时是在每次有批准的代码变更时，就会向最终用户部署更新。为达成这点，咱们需要一些工具，以便能够以零停机时间方式，快速应用这些更新，apply those updates in a zero-downtime way。


本文档以 Ansible 最完整的示例 playbook 之一：`lamp_haproxy` 为模板，详细介绍了如何实现这一目标。该示例使用了大量 Ansible 功能：角色、模板与组变量等，而且还附带了一个可对 web 应用程序栈，进行零停机滚动升级的编排 playbook。

这些 playbook 会将 Apache、PHP、MySQL、Nagios 和 HAProxy，部署到一组基于 CentOS 的服务器上。

我们（作者）不会在此介绍如何运行这些 playbook。请阅读 GitHub 项目中的 README，以及示例以获取相关信息。相反，我们将仔细研究该 playbook 的每一部分，并描述其做了些什么。


## 站点部署

咱们从 `site.yml` 开始。这是咱们整个站点的部署 playbook。他可用于初始部署站点，以及向所有服务器推送更新：


```yaml
{{#include ../../../../playbook_example/site.yml}}
```

> **注意**：若咱们对 playbook 及 play 等术语不熟悉，那么应该复习一下 [“使用游戏本”](../using.md)。

在这个 playbook 中，咱们有 5 个 play。第一个以 `all` 主机为目标，并将 `common` 这个角色应用于所有主机。这是对整个站点的，比如 yum 软件包仓库配置、防火墙配置及其他需要应用到所有服务器的配置。

接下来的四个 play，会针对特定主机组运行，并将特定角色应用于这些服务器。除了用于 Nagios 监控、数据库和 Web 应用程序的角色外，咱们还实现了个安装和配置基本 Apache 设置的 `base-apache` 角色。该角色同时被其中的示例 web 应用及 Nagios 主机用到。


## 可重用内容：角色
