# 网络自动化有何不同？

网络自动化用到一些基本的 Ansible 概念，但在网络模组的工作方式上，存在一些重要差异。这个说明将帮助咱们，理解本指南中的那些练习。


## 在控制节点上执行


与大多数 Ansible 模组不同，网络模组不会在托管节点上运行。从用户角度看，网络模组会像其他模组一样工作。他们以临时命令、playbook 及角色运作。但在幕后，网络模组使用了不同于其他（Linux/Unix 和 Windows）模组的方法论。Ansible 是以 Python 编写和执行的。由于大多数网络设备无法运行 Python，因此 Ansible 网络模组是在 Ansible 控制节点上执行的，也就是 `ansible` 或 `ansible-playbook` 运行之处。


对于那些提供了 `backup` 选项的网络模组，也会将控制节点作为备份文件的目的地。在 Linux/Unix 模组下，如果受管节点上已存在某个配置文件，则备份文件会默认写入与新的、已更改文件相同的目录中。网络模组不会更新托管节点上的配置文件，因为网络配置不是以文件形式写入的。网络模组会在控制节点上写入备份文件，通常写入 playbook 根目录下的 `backup` 目录。


使用网络模组的连接插件（如 `ansible.netcommon.network_cli`）时，诸如 `ansible.builtin.file` 和 `ansible.buildin.copy` 的一些 Unix/Linux 模组，也会在控制节点上运行。


## 多种通信协议


由于网络模组是在控制节点，而非托管节点上执行，因此他们可支持多种通信协议。为各个网络模组所选的通信协议（XML over SSH、CLI over SSH、API over HTTPS 等），取决于网络平台与模组用途。有些网络模组只支持一种协议，有些则提供了选择。最常见的协议是透过 SSH 的 CLI。咱们以 `ansible_connection` 变量，设置通信协议：


| `ansible_connection` 的值 | 协议 | 要求 | 是否持久协议？ |
| :-- | :-- | :-- | :-- |
| `ansible.netcommon.network_cli` | 透过 SSH 的 CLI | `network_os` 设置 | 是 |
| `ansible.netcommon.netconf` | 透过 SSH 的 XML | `network_os` 设置 | 是 |
| `ansible.netcommon.httpapi` | 透过 HTTP/HTTPS 的 API | `network_os` 设置 | 是 |
| `local` | 依据厂商 | 厂商设置 | 否 |


> **注意**：`ansible.netcommon.httpapi` 连接插件已弃用了 `eos_eapi` 和 `nxos_nxapi`。详情和示例请参阅 [Httpapi 插件](https://docs.ansible.com/ansible/latest/plugins/httpapi.html#httpapi-plugins)。


`ansible_connection: local` 已被弃用。请使用上面列出的持久化连接类型。在持久化连接下，咱们可只定义一次主机和凭据，而不是在每个任务中都要定义。咱们还需设置咱们与之通信的特定网络平台的 `network_os` 变量。有关在不同平台上使用各种连接类型的更多详情，请参阅 [特定平台](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 页面。


## 按网络平台组织的专辑


所谓网络平台，是一组具有某种通用操作系统，可由某个 Ansible 专辑管理的网络设备，比如：

- Arista：[arista.eos](https://galaxy.ansible.com/arista/eos)；
- 思科：[cisco.ios](https://galaxy.ansible.com/cisco/ios)、[cisco.iosxr](https://galaxy.ansible.com/cisco/iosxr) 及 [cisco.nxos](https://galaxy.ansible.com/cisco/nxos)；
- Juniper：[junipernetworks.junos](https://galaxy.ansible.com/junipernetworks/junos)；
- VyOS：[vyos.vyos](https://galaxy.ansible.com/vyos/vyos)。


> **译注**：[VyOS](https://vyos.io/) 是个个开放源代码的网络操作系统，为路由、防火墙和 VPN 功能，提供了一种全面套件。VyOS 为小型和大型网络环境，提供了强大而灵活的解决方案。他旨在支持企业级网络，并具有社区驱动开发和持续更新的额外优势。


某种网络平台内的所有模组，有着某些共同要求。某些网络平台有着一些特定差异 -- 详情请参见 [特定平台](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 文档。


## 权限提升：`enable` 模式、`become` 与 `authorize`


一些网络平台支持权限，其中某些任务必须由特权用户完成。在网络设备上，这叫做 `enable` 模式（相当于类 Unix 系统管理中的 `sudo`）。Ansible 网络模组为支持权限提升的网络设备，提供了此项功能。有关支持 `eanble` 模式的详细信息，以及如何使用 `enable` 模式的示例，请参阅 [特定平台](https://docs.ansible.com/ansible/latest/network/user_guide/platform_index.html#platform-options) 文档。


### 使用 `become` 进行权限提升

在任何支持权限提升的网络平台上，使用顶级的 Ansible 参数 `become: true` 与 `become_method: enable`，以提升的权限运行任务、play 或 playbook。咱们必须使用 `connection：network_cli` 或 `connection：httpapi`，与 `become: true` 及 `become_method: enable` 一起使用。如果咱们使用 `network_cli` 连接插件将 Ansible 连接到网络设备，则 `group_vars` 文件将如下所示：


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: cisco.ios.ios
ansible_become: true
ansible_become_method: enable
```

（End）


