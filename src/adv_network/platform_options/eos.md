# EOS 平台选项


[Arista EOS](https://galaxy.ansible.com/ui/repo/published/arista/eos) 专辑支持多种连接。本页详细介绍了每种连接在 Ansible 中的工作原理及使用方法。


## 可用连接

|  | CLI | eAPI |
| :-- | :-- | :-- |
| 协议 | SSH | HTTP(S) |
| 凭据 | 在存在 SSH 密钥/ `ssh-agent` 时使用 SSH 密钥/`ssh-agent`，在使用密码时接受 `-u my_user -k` 参数 | 存在 HTTPS 证书时使用 HTTPS 证书 |
| 间接访问 | 通过堡垒机（跳转主机） | 经由 web 代理 |
| 连接设置 | `ansible_connection: ansible.netcommon.network_cli` | `ansible_connection: ansible.netcommon.httpapi` |
| `enable` 模式（权限提升） | 受支持的：与 `ansible_become_method: enable` 一起使用 `ansible_become: true` | 受支持的：`httpapi` 会使用与 `ansible_become_method: enable` 一起的 `ansible_become: true` |
| 返回的数据格式 | `stdout[0].` | `stdout[0].messages[0].` |


`ansible_connection: local` 已被弃用。要使用 `ansible_connection: ansible.netcommon.network_cli` 或 `ansible_connection: ansible.netcommon.httpapi` 代替。


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/eos.yml`

```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: arista.eos.eos
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
- name: Backup current switch config (eos)
  arista.eos.eos_config:
    backup: yes
  register: backup_eos_location
  when: ansible_network_os == 'arista.eos.eos'
```


## 在 Ansible 中使用 eAPI

### 启用 eAPI

使用 eAPI 连接交换机前，咱们必须启用 eAPI。要在某个新交换机上使用 Ansible 启用 eAPI，就要经由 CLI 连接，用到 `arista.eos.eos_eapi` 模组。如同上面 CLI 示例中一样，设置 `group_vars/eos.yml`，然后运行类似下面的 playbook 任务：

```yaml
{{#include ../../../network_run/enable_eapi.yml}}
```

> **译注**：
>
> - 运行此 playbook 需要使用 `-bK` 命令行开关进行权限提升；
>
> - 需要更多操作才能启用 HTTPS 的 eAPI。否则会报出错误：`"Could not connect to https://eos-sw:443/command-api: [Errno 111] 连接被拒绝"`；
>
> - 在 Arista EOS 交换机上启用 eAPI 后，会报出错误：`"Could not connect to https://eos-sw:443/command-api: [SSL: SSLV3_ALERT_HANDSHAKE_FAILURE] ssl/tls alert handshake failure (_ssl.c:1000)"`；
>
> - 在 Arista EOS 交换机上成功启用 HTTPS 的 eAPI 后，可直接访问 https://eos-sw/，但因为使用的自签名证书，而会报出证书错误。要往分组/主机加入变量 `ansible_httpapi_ciphers: AES256-SHA:DHE-RSA-AES256-SHA:AES128-SHA:DHE-RSA-AES128-SHA` 解决此问题；
>
> - 需要 `ansible_user` 与 `ansible_password` 变量。否则报出错误 `"HTTP Error 401: Unauthorized"`。示例配置如下。

```yaml
    eos-sw:
      ansible_host: eos-sw
      ansible_network_os: arista.eos.eos
      ansible_connection: ansible.netcommon.httpapi
      ansible_httpapi_use_ssl: true
      ansible_httpapi_validate_certs: false
      ansible_user: admin
      ansible_password: my_secret
      ansible_ssh_private_key_file: /home/hector/.ssh/id_ecdsa
      ansible_httpapi_ciphers: AES256-SHA:DHE-RSA-AES256-SHA:AES128-SHA:DHE-RSA-AES128-SHA

```
>
> 参考：
>
> - [Arista eAPI 101](https://arista.my.site.com/AristaCommunity/s/article/arista-eapi-101)
>
> - [Python >= 3.10 and SSLV3_ALERT_HANDSHAKE_FAILURE error](https://arista.my.site.com/AristaCommunity/s/article/Python-3-10-and-SSLV3-ALERT-HANDSHAKE-FAILURE-error)

咱们可在 [`arista.eos.eos_eapi`](https://docs.ansible.com/ansible/latest/collections/arista/eos/eos_eapi_module.html#ansible-collections-arista-eos-eos-eapi-module) 模组文档中，找到启用 HTTP/HTTPS 连接的更多选项。


启用 eAPI 后，就要修改咱们的 `group_vars/eos.yml` 以使用 eAPI 连接。


### 示例 eAPI `group_vars/eos.yml`


```yaml
ansible_connection: ansible.netcommon.httpapi
ansible_network_os: arista.eos.eos
ansible_user: myuser
ansible_password: !vault...
ansible_become: true
ansible_become_method: enable
proxy_env:
  http_proxy: http://proxy.example.com:8080
```

- 如果咱们是直接访问主机（而非通过 web 代理），咱们可移除 `proxy_env` 配置项；
- 如果咱们通过某个使用 `https` 的 web 代理服务器访问主机，则要将 `http_proxy` 更改为 `https_proxy`。


### 示例 eAPI 任务

```yaml
- name: Backup current switch config (eos)
  arista.eos.eos_config:
    backup: yes
  register: backup_eos_location
  environment: "{{ proxy_env }}"
  when: ansible_network_os == 'arista.eos.eos'
```

在这个示例中，`group_vars` 中定义的 `proxy_env` 变量，被传递给任务中模组的 `environment` 选项。


{{#include ./ce.md:193:}}
