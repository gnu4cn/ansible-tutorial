# IOS 平台选项

[Cisco IOS](https://galaxy.ansible.com/ui/repo/published/cisco/ios) 专辑支持 `enable` 模式（特权升级）。此页面提供了有关如何在 Ansible 中于 iOS 上使用 `enable` 模式的详细信息。

## 可用连接


{{#include ./cnos.md:22:31}}


## 在 Ansible 中使用 CLI

### 示例 CLI `group_vars/ios.yml`


```yaml
ansible_connection: ansible.netcommon.network_cli
ansible_network_os: cisco.ios.ios
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
- name: Backup current switch config (ios)
  cisco.ios.ios_config:
    backup: yes
  register: backup_ios_location
  when: ansible_network_os == 'cisco.ios.ios'
```



{{#include ./ce.md:193:}}
