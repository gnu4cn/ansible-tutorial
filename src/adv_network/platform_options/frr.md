# FRR 平台选项


[`FRR` 专辑](https://galaxy.ansible.com/ui/repo/published/frr/frr) 支持 `ansible.netcommon.network_cli` 连接。本节提供了有关如何将这种连接，用于自由范围路由，Free Range Routing，FRR，的详细介绍。


> **译注**：[FRRouting](https://frrouting.org/)，是linux 基金会的合作项目，a Linux foundation collaborative project。代码仓库 [FRRouting/frr](https://github.com/FRRouting/frr)。


## 可用连接

|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不支持 |
| 返回数据格式 | `stdout[0].` |


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/frr.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: frr.frr.frr
ansible_user: frruser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


- `ansible_user` 应属于 `frrvty` 组，且默认 shell 应被设置为 `/bin/vtysh`；
{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Gather FRR facts
  frr.frr.frr_facts:
    gather_subset:
     - config
     - hardware
```



{{#include ./ce.md:193:}}
