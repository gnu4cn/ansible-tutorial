# 建立咱们的仓库

在没有仓库的情况下运行 playbook，需要多个命令行开关。此外，针对单个设备运行某个 playbook，并不比手动进行同样更改效率高多少。要充分利用 Ansible 的威力，下一步就是使用仓库文件，将托管节点组织成具有 `ansible_network_os` 与 SSH 用户等信息的一些分组。功能齐全的仓库文件，可以作为咱们网络事实的来源。使用仓库文件，在一条命令下，某个 playbook 就能维护数百网络设备。本页将向咱们展示，如何一步步创建出仓库文件。


## 基本仓库

首先，要按逻辑对仓库进行分组。最佳做法是按他们是 “什么，What”（比如应用、技术栈或微服务等）、在“何处，Where”（数据中心或地区）和 于“何时，When”（开发阶段），对服务器和网络设备进行分组：


- 是 **什么，What**：`db`、`web`、`leaf`、`spine` 等；
- 在 **何处，Where**：`east`、`west`、`floor_19`、`building_A` 等；
- 于 **何时，When**：`dev`、`test`、`staging`、`prod` 等。


在咱们的分组名字中，要避免使用空格、连字符（`-`）及数字开头（要使用 `floor_19`，而不是 `19th_floor`）。分组名字是区分大小写。


下面这个小型数据中心示例，说明了一种基本分组结构。咱们可使用 `[metagroupname:children]` 这种语法对组再进行分组，而将一些组列为该元组的成员。在这里，`network` 这个组就包含了所有叶子和主干；而 `datacenter` 组则包含了所有网络设备及所有 web 服务器。


```yaml
{{#include ./demo_inventory.yml}}
```

咱们也可以 INI 格式，创建出同一仓库。


```ini
[leafs]
leaf01
leaf02

[spines]
spine01
spine02

[network:children]
leafs
spines

[webservers]
webserver01
webserver02

[datacenter:children]
network
webservers
```


## 添加变量到仓库

接下来，咱们可在这个仓库中，设置咱们那首个 Ansible 命令所需的许多变量的值，这样咱们就可以在 `ansible-playbook` 命令中跳过他们。在这个示例中，该仓库要包含每个网络设备的 IP 地址、操作系统及 SSH 用户。若咱们网络设备只能通过 IP 地址访问，那么就必须将 IP 地址添加到仓库文件。而若咱们使用主机名访问网络设备，则就不需要 IP 地址。


```yaml
{{#include ./demo_inventory_with_vars.yml}}
```


## 仓库里的组变量



当某个组中的设备共用了相同的变量值（比如 OS 或 SSH 用户）时，通过将这些变量合并到组变量中，咱们便可减少重复并简化维护：


```yaml
{{#include ./demo_inventory_with_group_vars.yml}}
```


## 变量语法


变量值语法在仓库、playbook 和 `group_vars` 文件中的语法各不相同，下文将对此进行介绍。尽管 playbook 和 `group_vars` 文件都是以 YAML 编写，但咱们在二者中使用变量的方式却各不相同。


- 在 INI 样式的仓库文件中，咱们 **必须** 对变量值使用 `key=value` 语法，比如：`ansible_network_os=vyos.vyos.vyos`；
- 在任何扩展名为 `.yml` 或 `.yaml` 的文件中，包括 playbooks 和 `group_vars` 文件，咱们 **必须** 使用 YAML 的语法：`key: value`；
- 在 `group_vars` 文件中，要使用完整的键名：`ansible_network_os: vyos.vyos.vyos`；
- 在 playbook 中，要使用去掉 `ansible` 前缀的简短形式键名：`network_os: vyos.vyos.vyos`。


## 按平台分组仓库

随着咱们仓库的增长，咱们可能希望按平台对设备进行分组。这样做允许为该平台上的所有设备，轻松指定出一些特定于平台的变量：


```yaml
{{#include ./demo_inventory_by_platform.yml}}
```


在这种设置下，咱们只需两个命令行开关，便可运行 `first_playbook.yml`：


```console
ansible-playbook -i inventory.yml -k first_playbook.yml
```


使用 `-k` 命令行，咱们可在提示符下提供 SSH 密码。另外，咱们也可使用 `ansible-vault`，将 SSH 与其他机密和密码，安全地存储在 `group_vars` 文件中。详情请参阅 [使用 `ansible-vault` 保护敏感变量](#使用-ansible-vault-保护敏感变量)。


## 核实仓库


咱们可使用 `ansible-inventory` 这个 CLI 命令，显示出 Ansible 所看到的仓库。


```json
{{#include ./ansible-inventory.output}}
```


## 使用 `ansible-vault` 保护敏感变量


`ansible-vault` 命令提供了文件与/或像是密码的单个变量的加密功能。本教程将向咱们展示，如何加密单个 SSH 密码。咱们可使用下面的命令，加密如数据库密码、权限提升密码等其他敏感信息。


首先，咱们必须为 `ansible-vault` 本身创建一个密码。其会被用作加密的密钥，而有了这个密钥，咱们就可以加密咱们整个 Ansible 项目中的上百个不同密码。在咱们运行咱们的 playbook 时，只需一个密码（`ansible-vault` 的密码）就能访问所有这些秘密（加密值）。下面是个简单的例子。


1. 创建一个文件，并咱们的 `ansible-vault` 密码写入该文件：

```console
echo "my-ansible-vault-pw" > ~/my-ansible-vault-pw-file
```

2. 创建出咱们 VyOS 网络设备的加密 ssh 密码，从咱们刚才创建的文件中拉取 `ansible-vault` 的密码：


```console
$ ansible-vault encrypt_string --encrypt-vault-id prod "my_password" --name "ansible_password"
Encryption successful
ansible_password: !vault |
          $ANSIBLE_VAULT;1.2;AES256;prod
          32383636663834666639633735313133393436306165323836663437666265363066636465306164
          3730383865653762663531323032326133363865396232360a383962633632333538326662626264
          35336532346336633663666334393766653139626131353964363139656535653339306337643262
          6566633962393764370a303765383565633765636334663231666234323164323739633566313732
          3861
```

> **译注**：`--encrypt-vault-id prod` 命令行参数使用了定义在 `~/.ansible.cfg` 配置设置中的变量。参见 [管理 vault 密码](../usage/vault/passwords.md)。

```ini
vault_identity_list = 'dev@~/.ansible/dev.secret', 'prod@~/.ansible/prod.secret', 'default@~/.ansible/prod.secret', 'input@prompt'
```

> 使用命令 `openssl rand -base64 20 | sed -E 's/(.)\1+/\1/g' > ~/.ansible/prod.secret` 可产生高强度的随机 `ansible-vault` 密码。


若咱们更喜欢键入 `ansible-vault` 的密码，而不是将其存储在某个文件中，那么咱们可以请求一个提示符：


```console
$ ansible-vault encrypt_string --encrypt-vault-id input "my_password" --name "ansible_password"
```

并输入 `input` 的 vault 密码。

其中的 `--encrypt-vault-id` 命令行开关，允许不同用户或不同访问级别的不同 vault 密码。

下面这个示例是个 YAML 仓库的摘录，因为 INI 格式不支持内联的 vualt 值：

```yaml
# ...

vyos: # this is a group in yaml inventory, but you can also do under a host
  vars:
    ansible_connection: ansible.netcommon.network_cli
    ansible_network_os: vyos.vyos.vyos
    ansible_user: my_vyos_user
    ansible_password:  !vault |
         $ANSIBLE_VAULT;1.2;AES256;my_user
         66386134653765386232383236303063623663343437643766386435663632343266393064373933
         3661666132363339303639353538316662616638356631650a316338316663666439383138353032
         63393934343937373637306162366265383461316334383132626462656463363630613832313562
         3837646266663835640a313164343535316666653031353763613037656362613535633538386539
         65656439626166666363323435613131643066353762333232326232323565376635

 # ...
```


要在某个 INI 仓库中使用内联 vault 变量，咱们需要先将该 vault 变量存储在某个 YAML 格式的变量文件中，该文件可位于 `host_vars/` 或 `group_vars/`，以便在某个 play 中通过 `vars_files` 或 `include_vars` 指令，自动获取或引用。

要使用此设置运行某个 playbook，就要去掉 `-k` 标志，并添加一个咱们 `vault-id` 的命令行开关：

```console
ansible-playbook -i network_run/inventory.yml --vault-id prod@~/.ansible/prod.secret src/network/demo_vault.yml
```

> **译注**：在 `~/.ansible.cfg` 中设置了 `vualt_identity_list` 变量后，不加 `--vault-id` 也可以解密 vault 变量。且运行上面的命令会始终要求输入 Vualt 密码：

```console
$ ansible-playbook -i network_run/inventory.yml src/network/demo_vault.yml
Vault password (input):
```

有关构建仓库文件的更多详情，请参阅 [仓库介绍](../usage/inventories_building.md#如何建立仓库)；有关 `ansible-vault` 的更多详情，请参阅 [完整的 Ansible Vault 文档](../usage/vault/about.md)。


现在，咱们已经掌握了命令、playbook 及仓库的基础知识，是时候探索一些更复杂的 Ansible 网络示例了。


（End）


