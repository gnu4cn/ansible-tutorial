# WeOS 4 平台选项

Westermo WeOS 4 是 [`community.network`](https://galaxy.ansible.com/ui/repo/published/community/network) 专辑的一部分，仅支持 CLI 连接。本页提供了有关如何在 Ansible 中于 WeOS 4 上使用 `ansible.netcommon.network_cli` 的详细介绍。


> **译注**：Westermo 是 ARESKOM 旗下的子品牌。
>
> _ARESKOM Communication 成立于 2004 年，是土耳其伊斯坦布尔阿塔谢希尔的一家公司，业务涉及数据通信、工业网络和移动宽带、M2M 和物联网、电信产品和解决方案领域值得信赖的增值分销商和解决方案提供商，提供最佳的集成通信解决方案_。
>
> _Westermo 为物理要求苛刻的环境中的关键任务系统设计和制造数据通信产品。这些产品既用于社会基础设施，如交通、供水和能源供应，也用于加工工业，如采矿和石化_。
>
>
>
> 参考：
>
> - [WESTERMO](https://areskom.com/brands/westermo/)
>
> - [WeOS 4, Westermo Operating System](../../images/westermo_ds_weos_1909_en_revb.pdf)


## 可用连接

|  | `CLI` |
| :-- | :-- |
| 协议 | SSH |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 |
| 间接访问 | 通过堡垒机（跳转主机） |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` |
| `enable` 模式（权限提升） | 不受 WeOS 4 支持 |
| 返回数据格式 | `stdout[0].` |

WeOS 4 不支持 `ansible_connection: local`。咱们必须使用 `ansible_connection: ansible.netcommon.network_cli`。

## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/weos4.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.weos4
ansible_user: myuser
ansible_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```


{{#include ./ce.md:43:45}}


### 示例 CLI 任务

```yaml
- name: Get version information (WeOS 4)
  ansible.netcommon.cli_command:
    commands: "show version"
  register: show_ver
  when: ansible_network_os == 'community.network.weos4'
```


### 示例配置任务

```yaml
- name: Replace configuration with file on ansible host (WeOS 4)
  ansible.netcommon.cli_config:
    config: "{{ lookup('file', 'westermo.conf') }}"
    replace: "yes"
    diff_match: exact
    diff_replace: config
  when: ansible_network_os == 'community.network.weos4'
```


{{#include ./ce.md:193:}}
