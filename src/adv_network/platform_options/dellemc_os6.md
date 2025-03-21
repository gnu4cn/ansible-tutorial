# DELL OS6 平台选项

`dellemc.os6` 专辑支持 `enable` 模式（权限提升）。本页提供了关于如何在 Ansible 中于 OS6 上使用 `enable` 模式的详细说明。

> **译注**：
>
> -- _Dell Networking Operating System, DNOS，DELL 网络通信操作系统，是运行于戴尔网络通信部门的交换机上的网络操作系统。他源自 PowerConnect OS (DNOS 6.x) 或 Force10 OS/FTOS (DNOS 9.x)，将用于 10G 及更高速的戴尔网络 S 系列交换机及 Z 系列 40G 核心交换机，DNOS6 用于 N 系列交换机_。
>
> - _DNOS 3.x： 这是园区接入交换机的固件系列，只能使用基于 Web 的图形用户界面进行管理，或作为无管理设备运行_。
>
> - _DNOS 6.x： 这是 Dell 网络 N 系列（园区）网络交换机上运行的操作系统。他是 “PowerConnect” 操作系统的最新版本，在 Linux 内核上运行。PowerConnect 8100 系列交换机（随后成为戴尔网络 N40xx 交换机）可升级使用该系统，所有 DN N1000、N2000 和 N3000 系列交换机也都安装了该系统。他有个完整的基于 Web 的 GUI，以及一个完整的 CLI（命令行界面），CLI 与原来的 PowerConnect CLI 非常相似，但增加了一系列新功能，如 PVSTP（每 VLAN 的生成树）、基于策略的路由和多机架链路聚合，Multi-chassis Link Aggregation, MLAG_。
>
> - _DNOS 9.x： 这是运行在戴尔网络 S- 和 Z- 系列交换机上的操作系统，是 FTOS 或 Force10 操作系统的进一步发展。标准 DNOS 9.x（和 FTOS）只提供 CLI，不提供 GUI，不过使用自动化工具集可在 DNOS9/FTOS 交换机上创建自己的 WebGUI。DNOS 9.x 运行于 NetBSD 上_。
>
> - _FTOS 或 Force10 操作系统是 Force10 以太网交换机上使用的固件系列。其功能与思科的 NX-OS 或瞻博 Juniper 网络的 Junos 类似。FTOS 10 在 Debian 上运行。作为戴尔品牌重塑战略的一部分，FTOS 将更名为戴尔网络操作系统，DNOS 9.x 或更高版本，而传统的 PowerConnect 交换机将使用 DNOS 6.x_。
>
> _只有 PowerConnect 8100 能够在 DNOS 6.x 上运行：所有其他 PowerConnect 以太网交换机将继续运行自己的 PowerConnect OS（在 VxWorks 的基础上），而 PowerConnect W 系列则在戴尔特定版本的 ArubaOS 上运行。Dell Networking S- xxxx 和 Z9x00 系列将在 DNOS 上运行，而其他 Dell 网络部门交换机将继续运行 FTOS 8.x 固件_。
>
> Dell PowerConnect W 系列是来自 Aruba 网络的无线设备。
>
> - _OS10 则是基于 Linux 的开放式网络操作系统，可在所有开放式网络安装环境，Open Network Install Environment, ONIE 交换机上运行。由于他直接运行于 Linux 环境中，网络管理员可以高度自动化该网络平台，并以类似于 Linux服务器的方式管理交换机_。
>
>
> 参考：
>
> - [Dell Networking Operating System](https://en.wikipedia.org/wiki/Dell_Networking_Operating_System)
>
> - [FTOS](https://en.wikipedia.org/wiki/FTOS)
>
> - [Dell PowerConnect](https://en.wikipedia.org/wiki/Dell_PowerConnect)
