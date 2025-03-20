# CloudEngine 操作系统平台选项


CloudEngine CE OS 属于 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，支持多种连接。本页提供了有关每种连接在 Ansible 中的工作原理和使用方法的详细介绍。

> **译注**：CloudEngine 是华为公司的新一代交换机平台。其中 CE 系列是数据中心交换机平台，S 系列是园区交换机平台。
>
> 参见：
>
> - [CloudEngine数据中心交换机](https://carrier.huawei.com/cn/products/fixed-network/data-communication/switches/dc-switches)
>
> - [CloudEngine S系列园区交换机](https://e.huawei.com/cn/products/switches/campus-switches)


## 可用的连接

| | `CLI` | `NETCONF` |
| :-- | :-- | :-- |
| 协议 | SSH | 透过 SSH 的 XML |
| 凭据 | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` |
| 间接访问 | 使用堡垒机（跳转主机） | 使用堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.netconf` |
| `enable` 模式（权限提升） | 不受 CE OS 支持 | 不受 CE OS 支持 |
| 返回数据格式 | 参考单独模组文档 | 参考单独模组文档 |

