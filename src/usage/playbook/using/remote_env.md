# 设置远端环境

*版本 1.1 中的新特性*。

咱们可以在 play、区块或任务级别，使用 `environment` 关键字，为远端主机上的某项操作，设置某个环境变量。使用此关键字，咱们可以为某个执行 `http` 请求的任务启用代理，为那些特定语言的版本管理器，设置所需的环境变量，等等。


当咱们在 play 或区块级别，以 `environment:` 设置了某个值时，该值就只对 play 或区块中，由同一用户执行的任务可用。`environment:` 关键字不会影响 Ansible 本身、Ansible 的配置设置、其他用户的环境，或其他插件，比如查找或过滤器等的执行。使用 `environment: `设置的变量，不会自动成为 Ansible 事实，即使咱们在 play 级别设置了他们。咱们必须在 playbook 中，包含一个显式的 `gather_facts` 任务，并在该任务中设置 `environment` 关键字，才能将这些值转化为 Ansible 事实。

## 在某个任务中设置远端环境


咱们可直接在任务级别设置环境。


```yaml
- hosts: db
  gather_facts: no

  tasks:

    - name: Install cobbler
      ansible.builtin.package:
        name: cobbler
        state: present
      environment:
        http_proxy: socks5h://192.168.122.1:10080
        https_proxy: socks5h://192.168.122.1:10080
```

> **译注**：[`ansible.builtin.package`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/package_module.html) 模组：
>
> - 在无需指定软件包管理器模组（如 `ansible.builtin.dnf`、`ansible.builtin.apt` .....）下，该模组即可管理目标机上的软件包。`ansible.builtin.package` 会调用 `ansible.builtin.setup` 模组发现的操作系统所使用的软件包管理器模组。如果 `ansible.builtin.setup` 尚未运行，`ansible.builtin.package` 将运行他；
>
> - 该模组充当了底层软件包管理器模组的代理。虽然所有参数都会传递给底层模组，但并非所有模组都支持相同参数。本文档仅涉及所有打包模组都支持的最小模组参数交集；
>
> - 对于 Windows 目标主机，要使用 `ansible.windows.win_package` 模组。


通过将环境设置定义为咱们 play 中变量，然后在某个任务中访问他们，就像访问任何存储的 Ansible 变量一样，从而重用这些环境设置。

```yaml
- hosts: webservers
  gather_facts: no
  vars:
    proxy_env:
      http_proxy: socks5h://192.168.122.1:10080
      https_proxy: socks5h://192.168.122.1:10080

  tasks:

    - name: Install cobbler
      ansible.builtin.package:
        name: cobbler
        state: present
      environment: "{{ proxy_env }}"
```

通过将环境设置，定义在某个 `group_vars` 文件中，咱们可在多个 playbook 中重用这些环境设置。


```yaml
---
# file: group_vars/boston

ntp_server: ntp.bos.example.com
backup: bak.bos.example.com
proxy_env:
  http_proxy: socks5h://192.168.122.1:10080
  https_proxy: socks5h://192.168.122.1:10080
```

咱们可以在 play 级别设置远端环境。

```yaml
- hosts: testing

  roles:
     - php
     - nginx

  environment:
    http_proxy: socks5h://192.168.122.1:10080
    https_proxy: socks5h://192.168.122.1:10080
```

这些示例展示的是代理设置，但咱们可通过这种方式，提供任意数量的设置。


## 使用特定语言的版本管理器

某些特定语言的版本管理器（比如 `rbenv`、`nvm` 与 `pyenv` 等），需要咱们在使用这些工具时，设置一些环境变量。手动使用这些工具时，咱们通常会从某个脚本，或添加到 shell 配置文件的一些行，`source` 一些环境变量。在 Ansible 中，咱们可通过 play 级别的 `environment` 关键字，来实现这点。

```yaml
---
### A playbook demonstrating a common npm workflow:
# - Check for package.json in the application directory
# - If package.json exists:
#   * Run npm prune
#   * Run npm install

- hosts: application
  become: false

  vars:
    node_app_dir: /var/local/my_node_app

  environment:
    NVM_DIR: /var/local/nvm
    PATH: /var/local/nvm/versions/node/v4.2.1/bin:{{ ansible_env.PATH }}

  tasks:
    - name: Check for package.json
      ansible.builtin.stat:
        path: '{{ node_app_dir }}/package.json'
      register: packagejson

    - name: Run npm prune
      ansible.builtin.command: npm prune
      args:
        chdir: '{{ node_app_dir }}'
      when: packagejson.stat.exists

    - name: Run npm install
      community.general.npm:
        path: '{{ node_app_dir }}'
      when: packagejson.stat.exists
```

> **注意**：上面的示例，将 `ansible_env` 用作了 `PATH` 的一部分。将变量建立在 `ansible_env` 上是有风险的。Ansible 通过收集事实，产生出 `ansible_env` 的值，因此这些变量的值，取决于 Ansible 在收集这些事实时，用到的 `remote_user` 或 `become_user`。如果修改了 `remote_user`/`become_user`，`ansible_env` 中的值就可能不是咱们期望的值了。

> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> - 环境变量通常是以明文形式传递的（取决于 `shell` 插件），因此不推荐使用这种方式，向正在执行的模组传递秘密。


咱们也可以在任务级别，指定该环境。

```yaml
---
- name: Install ruby 2.3.1
  ansible.builtin.command: rbenv install {{ rbenv_ruby_version }}
  args:
    creates: '{{ rbenv_root }}/versions/{{ rbenv_ruby_version }}/bin/ruby'
  vars:
    rbenv_root: /usr/local/rbenv
    rbenv_ruby_version: 2.3.1
  environment:
    CONFIGURE_OPTS: '--disable-install-doc'
    RBENV_ROOT: '{{ rbenv_root }}'
    PATH: '{{ rbenv_root }}/bin:{{ rbenv_root }}/shims:{{ rbenv_plugins }}/ruby-build/bin:{{ ansible_env.PATH }}'
```


（End）


