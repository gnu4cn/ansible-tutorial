# Junos OS 平台选项

[瞻博网络 Juniper Junos OS](https://galaxy.ansible.com/ui/repo/published/junipernetworks/junos) 支持多种连接。本页提供了有关在 Ansible 中每种连接工作原理及使用方法的详细介绍。


## 可用连接


|  | CLI，仅限 `junos_netconf`、`junos_command` 与 `junos_ping` 模组 | NETCONF，除 `junos_netconf` 外的那些启用了 NETCONF 的模组 |
| :-- | :-- | :-- |
| 协议 | SSH | 透过 SSH 的 XML |
| 凭据 | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` | 若存在 SSH 密钥/ `ssh-agent`，则使用 SSH 密钥/ `ssh-agent`，若使用密码，则接受 `-u my_user -k` |
| 间接访问 | 使用堡垒机（跳转主机） | 使用堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.netconf` |
| `enable` 模式（权限提升） | 不受 Junos OS 支持 | 不受 Junos OS 支持 |
| 返回数据格式 | `stdout[0].` | <li>json: <code>result[0]['software-information'][0]['host-name'][0]['data'] foo lo0</code></li><li>text: <code>result[1].software-information[0].physical-interface[0].name[0].data foo lo0</code></li><li>xml: <code>result[1].rpc-reply.interface-information[0].physical-interface[0].name[0].data foo lo0</code></li>


`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.netconf` 或 `ansible_connection=ansible.netcommon.network_cli` 代替。
