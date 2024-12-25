# Ansible 的一些概念

这些概念对于 Ansible 的所有用途，都是通用的。在使用 Ansible 或阅读文档之前，咱们应该先了解他们。

## 控制节点

运行 Ansible 命令行（CLI） 工具（`ansible-playbook`、`ansible`、`ansible-vault` 等）的计算机。咱们可使用任何满足该软件要求的计算机，作为控制节点 -- 笔记本电脑、共享台式机与服务器等，都可以运行 Ansible。咱们还可以在称为 [“执行环境”](ee.md) 的容器中，运行 Ansible。

多个控制节点是可行的，但 Ansible 本身并不在他们之间进行协调，请参阅 [Ansible Automation Platform, `AAP`](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.5) 了解此类功能。


## 托管节点

这些设备也称为 “主机”，是咱们要用 Ansible 管理的目标设备（服务器、网络设备或任何计算机）。

Ansible 通常不会安装在托管节点上，除非咱们使用 `ansible-pull`，但这种情况很少见，且不是推荐的设置。


## 仓库

由一或多个 “仓库源” 所提供的托管节点列表。仓库可指定出每个节点的特定信息，如 IP 地址。他还可用于指派组别，以便在 play 中与批量变量分配中，实现节点选择。

要了解有关仓库的更多信息，请参阅 [“使用清单”](building_ansible_inventories.md) 小节。有时，清单源文件也被称为 “hostfile”（主机文件）。

## Playbooks

他们包含着一些 play（Ansible 执行的基本单元）。这既是个 “执行概念”，也是我们描述 `ansible-playbook` 于其上运行的文件方式。

Playbook 以 YAML 编写，易于阅读、编写、共用和理解。要了解更多有关 playbooks 的信息，请参阅 [Ansible playbooks](playbooks_intro.md)。

### Plays

是 Ansible 执行的主要上下文，此 playbook 对象，this playbook object，将托管节点（主机）映射到任务。play 包含变量、角色和有序的任务列表，可重复运行。他基本上由一个隐式的，映射主机和任务循环组成，并定义了如何对他们进行迭代。

- **角色，roles**
    可重复使用 Ansible 内容（任务、处理程序，handlers、变量、插件、模板及文件等）的有限分发，供 play 内部使用。

    要使用任何角色资源，该角色本身必须导入 play。

- **任务**
    应用到托管主机的某项 “操作” 的定义。咱们可以使用 `ansible` 或 `ansible-console` （都会创建出一条虚拟 play），通过临时命令，an ad hoc command，执行某单个任务一次。

- **处理程序，handlers**
    任务的一种特殊形式，只有在前一任务发出通知，导致状态 “已更改” 时才会执行。


## 模组

**Modules**


为完成每个任务中定义的操作，Ansible 复制到每个托管节点，并在每个托管节点上执行（需要时）的代码或二进制文件。

从管理特定类型数据库的用户，到管理特定类型网络设备的 VLAN 接口，每个模组都有其特定用途。

咱们可在一个任务中调用一个模组，也可以在一个 playbook 中调用多个不同模组。Ansible 模组被分组为一些专辑。要了解 Ansible 包含多少专辑，请参阅 [专辑索引](collection_index.md)。


## 插件

扩展 Ansible 核心功能的代码片段。插件可以控制咱们连接到托管节点的方式（连接插件，connection plugin）、对数据加以操作（过滤插件，filter plugin），甚至控制在控制台显示的内容（回调插件，callback plugins）。

详情请参阅 [“使用插件”](plugins.md)。

## 专辑

**Collections**

Ansible 内容的发布格式，可包含 playbook、角色、模组与插件。咱们可通过 [Ansible Galaxy](https://galaxy.ansible.com/) 安装和使用专辑。

要了解有关专辑的更多信息，请参阅 [使用 Ansible 专辑](collections.md)。

专辑资源可以相互独立、分离地使用。
