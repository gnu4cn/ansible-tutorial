# Ansible CLI 备忘单

本页给出了每个带有常用命令行开关的 Ansible 命令行实用工具的一或多个示例，以及到该命令完整文档的链接。本页仅提供一些常见用例的快速提示，可能已经过时或不完整，或两者兼而有之。要获取规范文档，请点击 CLI 页面的链接。


## `ansible-playbook` 命令

```console
ansible-playbook -i /path/to/my_inventory_file -u my_connection_user -k -f 3 -T 30 -t my_tag -M /path/to/my_modules -b -K my_playbook.yml
```

从当前工作目录加载 `my_playbook.yml`，并：


- `-i`，使用所提供 [仓库](inventories_building.md) 路径中的 `my_inventory_file`，来匹配随后的 [模式](patterns.md)；
- `-u`，以 `my_connection_user` 作为用户名 [通过 SSH](connection.md) 连接；
- `-k`，询问密码，然后将密码提供给 SSH 验证；
- `-f`，分配 3 个 [分叉](playbooks.md)；
- `-T`，设置一个 30 秒的超时；
- `-t`，仅运行被标记为 [标签](playbooks.md) `my_tag` 的任务；
- `-M`，从 `/path/to/my/modules` 处加载 [本地模组](../dev_guide/developing_locally.md)；
- `-b`，以提升的权限执行（使用 [`become`](playbooks.md)）；
- `-K`，提示用户输入 `become` 口令。

详细文档请参见 [ansible-playbook](ansible-playbook.md)。


## `ansible-galaxy` 命令


### 安装专辑

- 安装单个专辑

```console
ansible-galaxy collection install mynamespace.mycollection
```

从所配置的 Galaxy 服务器（默认为 `galaxy.ansible.com`），下载 `mynamespace.mycollection`。

- 安装专辑清单

```console
ansible-galaxy collection install -r requirements.yml
```

下载 `requirements.yml` 文件中所指定的专辑列表。

- 列出全部已安装的专辑

```console
ansible-galaxy collection list
```



### 安装角色

- 安装一个名为 `example.role` 的角色

```console
ansible-galaxy role install example.role

# SNIPPED_OUTPUT
- extracting example.role to /home/user/.ansible/roles/example.role
- example.role was installed successfully
```

- 列出全部已安装的角色

```console
ansible-galaxy role list
```

详细文档请参见 [ansible-galaxy](ansible-galaxy.md)。

## `ansible` 命令

### 运行临时命令

- 安装某个软件包

```console
ansible localhost -m ansible.builtin.apt -a "name=apache2 state=present" -b -K
```

运行 `ansible localhost` - 表明是在本地系统上；- `name=apache2 state=present` - 表明是在在基于 Debian 的系统上，安装 `apache2` 软件包；`-b` - 表明要使用 `become` 以提升的权限执行；`-m` - 指定模块名称；`-K` - 提示权限提升口令。

```console
localhost | SUCCESS => {
"cache_update_time": 1709959287,
"cache_updated": false,
"changed": false
#...
```


## `ansible-doc` 命令

### 显示插件名称及其源文件；


```console
ansible-doc -F
# ...
```


- 显示可用插件。


```console
ansible-doc -t module -l
# ...
```
