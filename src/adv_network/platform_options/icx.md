# ICX 平台选项

ICX 是 [`community.network`]() 专辑的一部分，支持 `enable` 模式（权限提升）。本页提供了有关在 Ansible 中于 ICX 上使用 `enable` 模式的详细介绍。


> **译注**：ICX 平台是搭载于康普 Commscope 旗下有线及无线网络设备与软件品牌 RUCKUS Networks 交换机的网络操作系统。
>
>
>
> 参考：
>
> - [RUCKUS ICX FastIron 10.0.10f_cd1 (GA) Software Release (.zip)](https://support.ruckuswireless.com/software/4396-ruckus-icx-fastiron-10-0-10f_cd1-ga-software-release-zip)


## 可用连接

{{#include ./cnos.md:22:31}}


## 在 Ansible 中使用 CLI


### 示例 CLI `group_vars/icx.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: community.network.icx
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
- name: Backup current switch config (icx)
  community.network.icx_config:
    backup: yes
  register: backup_icx_location
  when: ansible_network_os == 'community.network.icx'
```



{{#include ./ce.md:193:}}
