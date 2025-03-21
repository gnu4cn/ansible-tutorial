# CloudEngine 操作系统平台选项


CloudEngine CE OS 属于 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，支持多种连接。本页提供了有关每种连接在 Ansible 中的工作原理和使用方法的详细介绍。

> **译注**：CloudEngine 是华为公司的新一代交换机平台。其中 CE 系列是数据中心交换机平台，S 系列是园区交换机平台。
>
> 在使用 CE 平台时，显示告警信息 `[DEPRECATION WARNING]: community.network.ce has been deprecated. This collection and all content in it is unmaintained and deprecated. This feature will be removed from community.network in version 6.0.0. Deprecation warnings can be disabled by setting deprecation_warnings=False in ansible.cfg.`。表示未来 `community.network` 可能不再支持 CloudEngine 平台。
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


`ansible_connection: local` 已被弃用。请使用 `ansible_connection: ansible.netcommon.netconf` 或 `ansible_connection=ansible.netcommon.network_cli` 代替。


## 示例 CLI 仓库 `[ce:vars]`

```ini
[ce:vars]
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=community.network.ce
ansible_user=myuser
ansible_password=!vault...
ansible_ssh_common_args='-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

- 若咱们使用的是 SSH 密钥（包括 `ssh-agent`），则可以移除 `ansible_password` 配置项；
- 若咱们直接访问的主机（不通过堡垒机/跳转主机），则可移除 `ansible_ssh_common_args` 配置项；
- 若咱们通过堡垒机/跳转主机访问咱们的主机，则咱们不能在 `ProxyCommand` 指令中包含咱们的 SSH 密码。为防止秘密外泄（例如在 `ps` 的输出中），SSH 不支持使用环境变量提供密码。


### 示例 CLI 任务

```yaml
{{#include ../../../network_run/ce_example.yml}}
```

## 在 Ansible 中使用 `NETCONF`


### 启用 `NETCONF`


在使用 `NETCONF` 连接交换机之前，咱们必须：

- 使用 `pip install ncclient` 命令，在控制节点上安装 `ncclient` 这个 python 软件包；
- 在 CloudEngine OS 设备上启用 `NETCONF`。

要使用 Ansible 在某个新交换机上启用 `NETCONF`，就要使用带有 `CLI` 连接的 `community.network.ce_config` 模组。像上面的 `CLI` 示例中一样，设置咱们的平台级别变量，然后像下面这样运行一个 playbook 任务：


```yaml
{{#include ../../../network_run/enable_netconf.yml}}
```


启用 `NETCONF` 后，就要把咱们的变量，修改为使用 `NETCONF` 连接。

> **译注**：出了执行上述任务启用 `NETCONF` 还需进行以下设置。
>
> - 给 SSH 连接用户添加 `snetconf` 的 SSH `service-type`：`ssh user hector service-type stelnet snetconf`；
>
> - 配置 `NETCONF` 端口号。若未配置会报出 `"Error: b'Could not open socket to ce-sw:830'"` 错误。

```console
netconf
protocol inbound ssh port 830
commit
quit
```

> 参考：[华为设备-通过NETCONF对设备下发配置](https://zhuanlan.zhihu.com/p/488093458)


### 示例 `NETCONF` 仓库 `[ce:vars]`


```yaml
    ce-sw:
      ansible_host: ce-sw
      ansible_network_os: community.network.ce
      ansible_connection: ansible.netcommon.netconf
      ansible_ssh_user: hector
      ansible_ssh_pass: 'my_pass'
```


### 示例 `NETCONF` 任务


```yaml
{{#include ../../../network_run/demo_netconf.yml}}
```


## 说明


### 工作于 `ansible.netcommon.network_cli` 下的模组

- `community.network.ce_acl_interface`
- `community.network.ce_command`
- `community.network.ce_config`
- `community.network.ce_evpn_bgp`
- `community.network.ce_evpn_bgp_rr`
- `community.network.ce_evpn_global`
- `community.network.ce_facts`
- `community.network.ce_mlag_interface`
- `community.network.ce_mtu`
- `community.network.ce_netstream_aging`
- `community.network.ce_netstream_export`
- `community.network.ce_netstream_global`
- `community.network.ce_netstream_template`
- `community.network.ce_ntp_auth`
- `community.network.ce_rollback`
- `community.network.ce_snmp_contact`
- `community.network.ce_snmp_location`
- `community.network.ce_snmp_traps`
- `community.network.ce_startup`
- `community.network.ce_stp`
- `community.network.ce_vxlan_arp`
- `community.network.ce_vxlan_gateway`
- `community.network.ce_vxlan_global`


### 工作于 `ansible.netcommon.netconf` 下的模组

- `community.network.ce_aaa_server`
- `community.network.ce_aaa_server_host`
- `community.network.ce_acl`
- `community.network.ce_acl_advance`
- `community.network.ce_bfd_global`
- `community.network.ce_bfd_session`
- `community.network.ce_bfd_view`
- `community.network.ce_bgp`
- `community.network.ce_bgp_af`
- `community.network.ce_bgp_neighbor`
- `community.network.ce_bgp_neighbor_af`
- `community.network.ce_dldp`
- `community.network.ce_dldp_interface`
- `community.network.ce_eth_trunk`
- `community.network.ce_evpn_bd_vni`
- `community.network.ce_file_copy`
- `community.network.ce_info_center_debug`
- `community.network.ce_info_center_global`
- `community.network.ce_info_center_log`
- `community.network.ce_info_center_trap`
- `community.network.ce_interface`
- `community.network.ce_interface_ospf`
- `community.network.ce_ip_interface`
- `community.network.ce_lacp`
- `community.network.ce_link_status`
- `community.network.ce_lldp`
- `community.network.ce_lldp_interface`
- `community.network.ce_mlag_config`
- `community.network.ce_netconf`
- `community.network.ce_ntp`
- `community.network.ce_ospf`
- `community.network.ce_ospf_vrf`
- `community.network.ce_reboot`
- `community.network.ce_sflow`
- `community.network.ce_snmp_community`
- `community.network.ce_snmp_target_host`
- `community.network.ce_snmp_user`
- `community.network.ce_static_route`
- `community.network.ce_static_route_bfd`
- `community.network.ce_switchport`
- `community.network.ce_vlan`
- `community.network.ce_vrf`
- `community.network.ce_vrf_af`
- `community.network.ce_vrf_interface`
- `community.network.ce_vrrp`
- `community.network.ce_vxlan_tunnel`
- `community.network.ce_vxlan_vap`


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> 切勿以明文方式存储密码。我们建议使用 SSH 密钥验证 SSH 连接。Ansible 支持 `ssh-agent` 来管理 SSH 密钥。如果必须使用密码来验证 SSH 连接，建议使用 [Ansible Vault](../../usage/vault/enc_vars_and_files.md#传递单个密码) 对密码进行加密。

（End）



