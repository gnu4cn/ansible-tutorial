# NXOS 平台选项

[`Cisco NXOS`](https://galaxy.ansible.com/ui/repo/published/cisco/nxos) 支持多种连接。本页提供了关于 Ansible 中每种连接的工作原理及使用方法的详细介绍。


## 可用连接


|  | CLI | NX-API |
| :-- | :-- | :-- |
| 协议 | SSH | HTTP(S) |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 | 存在 HTTPS 证书时使用 HTTPS 证书 |
| 间接访问 | 通过堡垒机（跳转主机） | 经由 web 代理 |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.httpapi` |
| `enable` 模式（权限提升） | 受支持的：与 `ansible_become_method: enable` 及 `ansible_become_password:` 一起使用 `ansible_become: true` | 不受 NX-API 支持 |
| 返回的数据格式 | `stdout[0].` | `stdout[0].messages[0].` |


`ansible_connection: local` 已被弃用。要使用 `ansible_connection: ansible.netcommon.network_cli` 或 `ansible_connection: ansible.netcommon.httpapi` 代替。


## 在 Ansible 中使用 CLI


### 示例 CLI 的 `group_vars/nxos.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: cisco.nxos.nxos
ansible_user: myuser
ansible_password: !vault...
ansible_become: true
ansible_become_method: enable
ansible_become_password: !vault...
ansible_ssh_common_args: '-o ProxyCommand="ssh -W %h:%p -q bastion01"'
```

{{#include ./ce.md:43:45}}


### 示例 CLI 任务


```yaml
- name: Backup current switch config (nxos)
  cisco.nxos.nxos_config:
    backup: yes
  register: backup_nxos_location
  when: ansible_network_os == 'cisco.nxos.nxos'
```


## 在 Ansible 中使用 NX-API

### 启用 NX-API


在咱们可以使用 NX-API 连接交换机前，咱们必须启用 NX-API。要经由 Ansible 在新交换机上启用 NX-API，就要通过 CLI 连接使用 `nxos_nxapi` 这个模组。像上面的 CLI 示例中一样设置 `group_vars/nxos.yml`，然后像运行一个下面这样 playbook 任务：


```yaml
- name: Enable NX-API
  cisco.nxos.nxos_nxapi:
    enable_http: yes
    enable_https: yes
  when: ansible_network_os == 'cisco.nxos.nxos'
```

要进一步了解启用 HTTP/HTTPS 和本地 `http` 的选项，请参阅 [`nxos_nxapi`](https://docs.ansible.com/ansible/2.9/modules/nxos_nxapi_module.html#nxos-nxapi-module) 模组文档。

启用 NX-API 后，就要修改咱们的 `group_vars/nxos.yml`，以使用 NX-API 连接。


### 示例 NX-API `group_vars/nxos.yml`


```yaml
ansible_connection: ansible.netcommon.httpapi
ansible_network_os: cisco.nxos.nxos
ansible_user: myuser
ansible_password: !vault...
proxy_env:
  http_proxy: http://proxy.example.com:8080
```

{{#include ./eos.md:112:113}}


### 示例 NX-API 任务

```yaml
- name: Backup current switch config (nxos)
  cisco.nxos.nxos_config:
    backup: yes
  register: backup_nxos_location
  environment: "{{ proxy_env }}"
  when: ansible_network_os == 'cisco.nxos.nxos'
```

{{#include ./eos.md:127}}


{{#include ./ce.md:193:195}}


## 思科 Nexus 平台支持矩阵

以下平台和软件版本已由思科认证，可与此版本的 Ansible 一起使用。


*平台/软件最低需求*


| 受支持平台 | 最低 NX-OS 版本 |
| :-- | :-- |
| Cisco Nexus N3k | 7.0(3)I2(5) 及更高版本 |
| Cisco Nexus N9k | 7.0(3)I2(5) 及更高版本 |
| Cisco Nexus N5k | 7.3(0)N1(1) 及更高版本 |
| Cisco Nexus N6k | 7.3(0)N1(1) 及更高版本 |
| Cisco Nexus N7k | 7.3(0)D1(1) 及更高版本 |
| Cisco Nexus MDS | 8.4(1) 及更高版本（有关兼容性，请参见各模组文档） |


*平台型号*


| 平台 | 说明 |
| :-- | :-- |
| N3k | 支持 N30xx、N31xx 和 N35xx 型号 |
| N5k | 支持所有 N5xxx 型号 |
| N5k | 支持所有 N6xxx 型号 |
| N5k | 支持所有 N7xxx 型号 |
| N5k | 支持所有 N9xxx 型号 |
| MDS | 支持所有 MDS 9xxx 型号 |


（End）


