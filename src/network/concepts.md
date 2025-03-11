# 基本概念


这些概念对 Ansible 的全部用途都很常见，包括网络自动化。要将 Ansible 用于网络自动化，咱们就必须掌握这些概念。这个基本介绍提供了跟随本指南种示例所需的背景知识。


## 控制节点

咱们在其上运行 Ansible CLI 工具（`ansible-playbook`、`ansible`、`ansible-vault` 等）的计算机。咱们可使用任何符合软件要求的计算机，作为控制节点 -- 笔记本电脑、公用台式机及服务器等，都可以运行 Ansible。咱们还可在称为 [“执行环境”](../ee.md) 的容器中，运行 Ansible。

多个控制节点是可行的，但 Ansible 本身不会在多个节点之间协调，有关此类功能，请参阅 `AAP`。


## 托管节点

又被称为 “主机”，是咱们要用 Ansible 管理的目标设备（服务器、网络设备或任何计算机）。

Ansible 通常不安装在托管节点上，除非使用 `ansible-pull`，但这种情况很少见，也不是推荐的设置。



## 仓库

由一或多个 “仓库来源” 提供的托管节点列表。咱们仓库可以指定出每个节点的特定信息，如 IP 地址等。他还可用于指定组别，以便在 Play 和批量变量赋值中，均可进行节点选取。


要了解有关仓库的更多信息，请参阅 [“使用清单”](../usage/inventories_building.md#仓库基础知识格式主机与组别) 小节。有时，清单源文件也被称为 “主机文件”（`hostfile`）。


## Playbook


他们包含了一些 plays（这是 Ansible 执行的基本单位）。这既是一个 “执行概念”，也是我们描述 `ansible-playbook` 所运行文件的方式。

Playbook 以 YAML 编写，易于阅读、编写、共享和理解。要了解更多有关 playbook 的信息，请参阅 [Ansible playbook](../usage/playbook/about.md)。


### Play

Ansible 执行的主要上下文，这个 playbook 对象将托管节点（主机）映射到任务。Play 包含变量、角色和任务的有序列表，并可重复运行。他基本上由映射了主机和任务的隐式循环组成，并定义了如何对其进行迭代。


- **角色**

一些可重用 Ansible 内容（任务、处理程序、变量、插件、模板及文件等）的有限分发，供 play 内部使用。

要使用任何角色资源，该角色本身必须导入这个 play。



- **任务**

应用到托管主机某项 “操作” 的定义。咱们可使用 `ansible` 或 `ansible-console`（两者都会创建一个虚拟 play），以临时命令执行单个任务。



- **处理程序**


任务的一种特殊形式，只有在前一造成 `changed` 状态的任务，发出了通知时才会执行。


## 模组


Ansible 拷贝到各个托管节点，并在其上执行（在需要时），以完成每个任务中所定义的操作的代码或二进制文件。


从管理特定类型数据库的用户，到管理特定类型网络设备的 VLAN 接口，每个模组都有其特定用途。


咱们可以用一个任务调用某个模组，或者在某个 playbook 中调用多个不同模组。Ansible 模组依专辑分组。要了解 Ansible 包含了多少个专辑，请参阅 [专辑索引](https://docs.ansible.com/ansible/latest/collections/index.html#list-of-collections)。


## 插件


扩展 Ansible 核心功能的一些代码片段。插件可以控制咱们连接到托管节点的方式（`connection` 插件）、操作数据（`filter` 插件），甚至掌控在控制台中的显示内容（`callback` 插件）。

详情请参阅 [“使用插件”](../usage/mod_n_plugins/plugins.md)。


## 专辑


Ansible 内容的发布格式，可包含 playbook、角色、模组及插件。咱们可通过 [Ansible Galaxy](https://galaxy.ansible.com/) 安装和使用专辑。


要了解有关专辑的更多信息，请参阅 [使用 Ansible 专辑](../usage/collection.md)。


专辑资源可以相互独立和分离地使用。



（End）


