# 处理程序：在变化时运行操作

有时，咱们希望某个任务，只在某台机器上有变更时才运行。例如，若某个任务更新了某个服务配置，咱们就可能想要重启该服务，而如果配置没有变动，则不希望重启。Ansible 使用处理程序，来解决这种用例。处理程序是一些在收到通知时，才运行的任务。


## 处理程序示例


下面这个 playbook（`verify-apache.yml`），包含了带有处理程序的单个 play。


```yaml
---
- name: Verify apache installation
  hosts: webservers
  vars:
    http_port: 80
    max_clients: 200
  remote_user: root
  tasks:
    - name: Ensure apache is at the latest version
      ansible.builtin.yum:
        name: httpd
        state: latest

    - name: Write the apache config file
      ansible.builtin.template:
        src: /srv/httpd.j2
        dest: /etc/httpd.conf
      notify:
        - Restart apache

    - name: Ensure apache is running
      ansible.builtin.service:
        name: httpd
        state: started

  handlers:
    - name: Restart apache
      ansible.builtin.service:
        name: httpd
        state: restarted
```

在这个示例 playbook 中，Apache 服务器会在该 play 中的所有任务完成后，由其中的处理程序重启。


## 通知处理程序
