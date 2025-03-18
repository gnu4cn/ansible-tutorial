# 使用 Ansible 解析半结构化文本

`cli_parse` 这个模组，可将诸如网络配置这样的半结构化数据，解析为结构化数据，从而允许以编程方式使用来自该设备的数据。咱们可在一个 playbook 中，从网络设备中提取信息并更新某个 CMDB。用例包括自动化的故障排除、创建动态文档、更新 IPAM（IP 地址管理，IP address management）工具等。


## 掌握 CLI 解析器


`1.0.0` 或更高版本的 `ansible.utils` 专辑，包含了可运行 CLI 命令并解析半结构化文本输出的 `cli_parse` 模组。咱们可在仅支持某种命令行界面，且这些命令被执行后会返回半结构化文本的某个设备、主机，或某种平台上，使用 `cli_parse` 模组。`cli_parse` 模组既可以在设备上运行 CLI 命令，并返回某种解析结果，也可以仅解析任何文本文档。`cli_parse` 模组包含了与各种解析引擎连接的 `cli_parser` 插件。


### 为何要解析文本？

将诸如网络配置这样的半结构化数据，解析为结构化数据后，实现该设备数据的编程使用。用例包括自动化的故障排除、创建动态文档、更新 IPAM（IP 地址管理）工具等。咱们可能更偏向使用 Ansible 原生完成此目的，以利用一些原生的 Ansible 结构，比如：

- 有条件地运行其他任务或角色的 `when` 子句，the `when` clause；
- 检查配置及运行状态合规性的 `assert` 模组；
- 生成配置及运行状态信息报告的 `template` 模组；
- 生成主机、设备或平台命令、配置的模板及 `command` 或 `config` 模组；
- 补充原生事实信息的当前平台 `facts` 模组。


通过将半结构化文本，解析为 Ansible 的原生数据结构，咱们可以充分利用 Ansible 的那些网络模组与插件。


### 何时不解析文本

在下列情况下，咱们不应解析半结构化文本：

- 设备、主机或平台有着 RESTAPI 且返回的是 JSON；
- 即有 Ansible 的事实模组，已经返回了所需数据（译注：结构化数据）；
- 已有那些用于设备与资源配置管理的 Ansible 网络资源模组。


## 解析命令行 CLI

`cli_parse` 模组，包括了以下的 `cli_parsing` 插件：

- `native`

Ansible 内置的原生解析引擎，无需额外的 python 库。

- `xml`

将 XML 解析为某种 Ansible 原生的数据结构。

- `textfsm`

一个用于解析半结构化文本，实现了一种基于模板的状态机的 python 模组。

- `ntc_templates`

支持各种平台和命令的一些预定义的 `textfsm` 模板包。


- `ttp`

使用模板进行半结构化文本解析的一个库，具有一些简化流程的能力。


- `pyats`

使用 Cisco 测试自动化与验证解决方案 <sup>1</sup> 所包含的那些解析器。

> 1, Cisco Test Automation & Validation Solution，[Cisco pyATS: Network Test & Automation Solution](https://developer.cisco.com/docs/pyats/)


- `json`


将 CLI 处输出的 JSON，转换为 Ansible 的原生数据结构。


> 译注：上述 `cli_parse` 用到的 `cli_parsing` 插件，需要安装 `textfsm`、`ntc_templates`、`ttp`、`jc`、`genie` 与 `pyats` Python 模组 `python -m pip install textfsm ntc_templates ttp jc genie pyats`。


尽管 Ansible 包含许多可将 XML 转换为 Ansible 原生数据结构的插件，但 `cli_parse` 模组可在单个的任务中，同时在设备上运行返回 XML 的命令，并返回转换后的数据。


由于 `cli_parse` 使用了基于插件的架构，因此他可以使用任何 Ansible 专辑中别的解析引擎。


> **注意**：`ansible.netcommon.native` 和 `ansible.utils.json` 两个解析引擎，在 Red Hat Ansible 自动化平台订阅下有完整支持。Red Hat Ansible 自动化平台订阅的支持仅限于 `ntc_templates`、`pyATS`、`textfsm`、`xmltodict` 及一些公共 API（如文档所示）的使用。



### 使用原生解析引擎解析


原生解析引擎包含在 `cli_parse` 模组中。他使用正则表达式捕获数据，以产生出解析后的数据结构。原生解析引擎需要一个 YAML 模板文件，来解析命令的输出。


- **网络示例**


这个示例使用某个网络设备命令的输出，并应用一个原生模板，生成 Ansible 结构化数据格式的输出。



来自网络设备的 `show interface` 命令输出如下：


```console
Ethernet1/1 is up
admin state is up, Dedicated Interface
  Hardware: 100/1000/10000 Ethernet, address: 5254.005a.f8bd (bia 5254.005a.f8bd)
  MTU 1500 bytes, BW 1000000 Kbit, DLY 10 usec
  reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation ARPA, medium is broadcast
  Port mode is access
  full-duplex, auto-speed
  Beacon is turned off
  Auto-Negotiation is turned on  FEC mode is Auto
  Input flow-control is off, output flow-control is off
  Auto-mdix is turned off
  Switchport monitor is off
  EtherType is 0x8100
  EEE (efficient-ethernet) : n/a
  Last link flapped 4week(s) 6day(s)
  Last clearing of "show interface" counters never
<...>
```

> **译注**：这是一台思科 NXOS 设备的 `sh int` 命令输出。


创建出与之输出相匹配的原生模板，并将其存储为 `templates/nxos_show_interface.yaml`：


```yaml
{{#include ../../network_run/nxos_show_interface.yaml}}
```

这个原生解析器模板，是按一个解析器列表组织的，每个解析器都包含以下这些键值对：

- `example` - 要解析文本行的一个示例行；
- `getval` - 使用一些命名捕获组存储所提取数据的一个正则表达式；
- `result` - 从解析数据中以模板形式填充的数据树；
- `shared` - 以解析出的数据，产生自一个模板的数据树。


下面的示例任务使用了 `cli_parse` 与原生解析器，与上面的示例模板，解析来自某个 Cisco NXOS 设备的 `show interface` 命令：


```yaml
{{#include ../../network_run/demo_native_parser.yml}}
```

来深入研究以下这个任务：


- 其中的 `command` 选项，提供了咱们要在设备或主机上运行的命令。或者，咱们也可以使用 `text` 选项，提供某个先前命令的文本；
- `parser` 选项提供了特定于解析器引擎的信息；
- `name` 子选项提供了解析引擎的完全合格专辑名字（FQCN，`ansible.builtin.native`）；
+ 默认情况下，`cli_parse` 模组会在 `templates` 目录下，查找模板 `{{ short_os }}_{ command }}.yaml`。
    - 模板文件名中的 `short_os` 派生自主机的 `ansible_network_os` 或 `ansible_distribution` 变量；
    - 在模板文件名的 `command` 部分，网络或主机命令中的空格会以 `_` 替换。在本例中，`show interfaces` 这个网络 CLI 命令，在文件名中就成为了 `show_interfaces`。


> **注意**：`ansible.netcommon.native` 解析引擎在 Red Hat Ansible 自动化平台订阅下受完整支持。


这个任务的最后，`set_fact` 选项会根据 `cli_parse` 返回的已结构化数据，设置该设备的以下 `interfaces` 事实：



```yaml
Ethernet1/1:
    hardware: 100/1000/10000 Ethernet
    mac_address: 5254.005a.f8bd
    name: Ethernet1/1
    state:
    admin: up
    operating: up
Ethernet1/10:
    hardware: 100/1000/10000 Ethernet
    mac_address: 5254.005a.f8c6
# ...
```

- **Linux 示例**


咱们还可使用这个原生解析器，在 Linux 上运行命令及解析输出。


一个示例 Linux 命令（`ip addr show`）的输出如下：


```console
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp1s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:90:33:26 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.61/24 brd 192.168.122.255 scope global dynamic noprefixroute enp1s0
       valid_lft 3199sec preferred_lft 3199sec
    inet6 fe80::5054:ff:fe90:3326/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```


创建出与此输出匹配的原生模板，并将其存储为 `templates/almalinux_ip_addr_show.yaml`：


```yaml
{{#include ../../network_run/almalinux_ip_addr_show.yaml}}
```


> **注意**：解析器模板中的 `shared` 键，允许接口名称在后续解析器条目中使用。正则表达式中示例和自由间距模式的使用，使模板更易于阅读。


下面的示例任务使用原生解析器下的 `cli_parse`，与上述示例模板，解析 Linux 的输出：


```yaml
{{#include ../../network_run/demo_native_parser.linux.yml}}
```

这个任务假定咱们之前已经收集了相关信息，以确定出找到模板所需的 `ansible_distribution`。或者，咱们也可以在 `parser/template_path` 选项中提供这个路径。

> **译注**：这里使用 `setup` 任务收集 `distribution` 与 `os_family` 两项主机事实上，以便后面的 `cli_parse` 模组可以找到正确的模板。此外将此任务用到的模板，放在任务 YAML 旁边也可以找到。

此任务的最后，`set_fact` 选项会根据 `cli_parse` 所返回的已结构化数据，为主机设置以下 `interfaces` 事实：

```yaml
lo:
  broadcast: false
  carrier: true
  ip_address: 127.0.0.1
  mask_bits: 8
  mtu: 65536
  multicast: false
  name: lo
  state: unknown
  up: true
enp64s0u1:
  broadcast: true
  carrier: true
  ip_address: 192.168.86.83
  mask_bits: 24
  mtu: 1500
  multicast: true
  name: enp64s0u1
  state: up
  up: true
# ...
```


### 解析 JSON


虽然 Ansible 会在识别到序列化 JSON 时，原生地将其转换为 Ansible 的原生数据，但咱们也可使用 `cli_parse` 模组进行这种转换。


示例任务：


```yaml
{{#include ../../network_run/demo_parsing_json.yml}}
```


深入探究一下这个任务：


- `show interface | json` 这个命令会在设备上执行；
- 输出被设置为该设备的 `interfaces` 事实；
- JSON 支持主要是为了保持 playbook 的一致性而提供。


> **注意**：`ansible.netcommon.json` 解析引擎在 Red Hat Ansible 自动化平台订阅下受完整支持。


### 使用 `ntc_templates` 解析命令行输出


`ntc_templates` 这个 python 库，包含了一些用于解析各种网络设备命令输出的预定义 `textfsm` 模板。


示例任务：


```yaml
{{#include ../../network_run/demo_ntc_templates.yml}}
```


深入探究一下这个任务：

- 设备的 `ansible_network_os` 变量，会转换为 `ntc_template` 的格式 `cisc_nxos`。此外，咱们也可使用 `parser/os` 选项提供 `os` 变量；
- 包含在 `ntc_templates` Python 包中的 `cisco_nxos_show_interface.textfsm` 模板，会解析输出；
- 有关 `ntc_templates` 这个 python 库的更多信息，请参阅 [`ntc_templates` 的 `README`](https://github.com/networktocode/ntc-templates)。


> **注意**：如文档所示，Red Hat Ansible 自动化平台的订阅的支持，仅限于 `ntc_templates` 公共 API 的使用。


此任务及预定义模板，会将以下事实设置为该主机的 `interfaces` 事实：


```yaml
interfaces:
- address: 5254.005a.f8b5
  admin_state: up
  bandwidth: 1000000 Kbit
  bia: 5254.005a.f8b5
  delay: 10 usec
  description: ''
  duplex: full-duplex
  encapsulation: ARPA
  hardware_type: Ethernet
  input_errors: ''
  input_packets: ''
  interface: mgmt0
  ip_address: 192.168.101.14/24
  last_link_flapped: ''
  link_status: up
  mode: ''
  mtu: '1500'
  output_errors: ''
  output_packets: ''
  speed: 1000 Mb/s
- address: 5254.005a.f8bd
  admin_state: up
  bandwidth: 1000000 Kbit
  bia: 5254.005a.f8bd
  delay: 10 usec
```


### 使用 `pyATS` 解析


`pyATS` 是思科测试自动化与验证解决方案的一部分。他包含了许多适用于多种网络平台和命令的预定义解析器。咱们可通过 `cli_parse` 模组使用这些 `pyATS` 软件包中的预定义解析器。


示例任务：

```yaml
{{#include ../../network_run/demo_pyats_parsing.yml}}
```


深入探究一下这个任务：

- `cli_parse` 模组会自动转换 `ansible_network_os`，本例中 `ansible_network_os` 被设置为 `cisco.nxos.nxos`，就会转换到 `pyATS` 的 `nxos`。另外，咱们也可使用 `parser/os` 选项，设置操作系统；
- 使用命令与操作系统的组合，`pyATS` 选择了以下解析器：`show interfaces`；
- `cli_parse` 模组会将 `cisco.ios.ios` 设置为 `pyATS` 的 `iosxe`。咱们可使用 `parser/os` 选项覆盖此设置；
- `cli_parse` 只会使用 `pyATS` 中的那些预定义解析器。请参阅 [`pyATS` 文档](https://developer.cisco.com/docs/pyats/) 和 [`pyATS` 包含的解析器](https://pubhub.devnetcloud.com/media/genie-feature-browser/docs/#/parsers) 的完整列表。



> **注意**：如文档所示，Red Hat Ansible 自动化平台订阅的支持，仅限于 `pyATS` 公共 API 的使用。


这个任务会将以下事实，设置为该主机的 `interfaces` 事实：


```yaml
mgmt0:
  admin_state: up
  auto_mdix: 'off'
  auto_negotiate: true
  bandwidth: 1000000
  counters:
    in_broadcast_pkts: 3
    in_multicast_pkts: 1652395
    in_octets: 556155103
    in_pkts: 2236713
    in_unicast_pkts: 584259
    rate:
      in_rate: 320
      in_rate_pkts: 0
      load_interval: 1
      out_rate: 48
      out_rate_pkts: 0
    rx: true
    tx: true
  delay: 10
  duplex_mode: full
  enabled: true
  encapsulations:
    encapsulation: arpa
  ethertype: '0x0000'
  ipv4:
    192.168.101.14/24:
      ip: 192.168.101.14
      prefix_length: '24'
  link_state: up
  # ...
```


### 使用 `textfsm` 解析


`textfsm` 是个实现了一种用于解析半格式化文本的基于模板状态机的 Python 模组。


以下示例 `textfsm` 模板，保存在 `templates/nxos_show_interface.textfsm`：

```textfsm
{{#include ../../network_run/templates/nxos_show_interface.textfsm}}
```


下面这个任务使用了该 `textfsm` 模板与 `cli_parse` 模组。


```yaml
{{#include ../../network_run/demo_textfsm_parsing.yml}}
```


深入探究一下这个任务：

- 设备的 `ansible_network_os` 变量 (`cisco.nxos.nxos`)，会被转换为 `nxos`。咱们也可在 `parser/os` 这个选项中提供操作系统；
- 使用操作系统和所运行命令的组合，`textfsm` 的模板名称就默认为 `templates/nxos_show_interface.textfsm`。咱们也可使用 `parser/template_path` 选项，覆盖这个生成的模板路径；
- 详情请查看 [`textfsm` README](https://github.com/google/textfsm)；
- `textfsm` 先前是作为过滤器插件提供的。Ansible 用户应过渡到 `cli_parse` 模组。


> **注意**：如文档所示，Red Hat Ansible 自动化平台订阅的支持，仅限于 `testfsm` 公共 API 的使用。


这个任务会将以下事实，设置为主机的 `interfaces` 事实：


```yaml
- ADDRESS: X254.005a.f8b5
  ADMIN_STATE: up
  BANDWIDTH: 1000000 Kbit
  BIA: X254.005a.f8b5
  DELAY: 10 usec
  DESCRIPTION: ''
  DUPLEX: full-duplex
  ENCAPSULATION: ARPA
  HARDWARE_TYPE: Ethernet
  INPUT_ERRORS: ''
  INPUT_PACKETS: ''
  INTERFACE: mgmt0
  IP_ADDRESS: 192.168.101.14/24
  LAST_LINK_FLAPPED: ''
  LINK_STATUS: up
  MODE: ''
  MTU: '1500'
  OUTPUT_ERRORS: ''
  OUTPUT_PACKETS: ''
  SPEED: 1000 Mb/s
- ADDRESS: X254.005a.f8bd
  ADMIN_STATE: up
  BANDWIDTH: 1000000 Kbit
  BIA: X254.005a.f8bd
...
```


### 使用 `TTP` 解析


`TTP` 是个使用模板进行半结构化文本解析的 Python 库。`TTP` 使用类似于 Jinja 的语法，限制了对正则表达式的需求。熟悉 Jinja 模板的用户，可能会发现 TTP 模板语法很熟悉。


以下是个存储为 `templates/nxos_show_interface.ttp` 的 `TTP` 模板示例：


```ttp
{{#include ../../network_run/templates/nxos_show_interface.ttp}}
```


下面这个任务使用该模板，解析 `show interface` 命令的输出：


```yaml
{{#include ../../network_run/demo_ttp_parsing.yml}}
```


深入探究一下这个任务：

- 默认模板路径 `templates/nxos_show_interface.ttp` 是使用主机的 `ansible_network_os` 变量与 `command` 选项生成的；
+ `TTP` 还支持将传递给解析器的几个其他变量。这些变量包括：
    - `parser/vars/ttp_init` - 解析器初始化时，传递的附加参数；
    - `parser/vars/ttp_results` - 用于影响解析器输出的附加参数；
    - `parser/vars/ttp_vars` - 模板中可用的附加变量。
- 详情请参见 [`TTP` 文档](https://ttp.readthedocs.io/)。


该任务会将以下事实，设置为主机的 `interfaces` 事实：


```yaml
- admin_state: up,
  interface: mgmt0
  state: up
- admin_state: up,
  interface: Ethernet1/1
  state: up
- admin_state: up,
  interface: Ethernet1/2
  state: up
```


### 使用 `JC` 解析


`JC` 是个可将数十种常见 Linux/UNIX/macOS/Windows 命令行工具及文件类型的输出，转换为 python 字典或字典列表，以更易于解析的 python 库。JC 是 `community.general` 专辑中的一种过滤器插件。


以下是个使用 `JC` 解析 `dig` 命令输出的示例：


```yaml
{{#include ../../network_run/demo_jc_parsing.yml}}
```

- `JC` 项目及文档，可在 [此处](https://github.com/kellyjonbrazil/jc/) 找到；
- 更多信息，请参阅此 [博客条目](https://blog.kellybrazil.com/2020/08/30/parsing-command-output-in-ansible-with-jc/)。


### 转换 XML


尽管 Ansible 包含许多可将 XML 转换为 Ansible 原生数据结构的插件，但 `cli_parse` 模组可在单个任务中，同时在设备上运行返回 XML 的命令，并返回转换后的数据。


下面这个示例任务，会运行 `show interface` 命令并将输出解析为 XML：


```yaml
{{#include ../../network_run/demo_converting_xml.yml}}
```

> **注意**：如文档所示，Red Hat Ansible 自动化平台订阅的支持，仅限于 `xmltodict` 的公共 API 的使用。

这个任务会根据如下返回的输出，设置主机的 `interfaces` 事实：


```yaml
nf:rpc-reply:
  '@xmlns': http://www.cisco.com/nxos:1.0:if_manager
  '@xmlns:nf': urn:ietf:params:xml:ns:netconf:base:1.0
  nf:data:
    show:
      interface:
        __XML__OPT_Cmd_show_interface_quick:
          __XML__OPT_Cmd_show_interface___readonly__:
            __readonly__:
              TABLE_interface:
                ROW_interface:
                - admin_state: up
                  encapsulation: ARPA
                  eth_autoneg: 'on'
                  eth_bia_addr: x254.005a.f8b5
                  eth_bw: '1000000'
```


## 高级用例

`cli_parse` 模组还有着多个支持更复杂用例的特性。


### 提供完整模板路径

在任务中使用 `template_path` 选项，覆盖默认的模板路径：


```yaml
- name: "Run command and parse with native"
  ansible.utils.cli_parse:
    command: show interface
    parser:
      name: ansible.netcommon.native
      template_path: /home/user/templates/filename.yaml
```


### 向解析器提供不同于 `command` 所运行的命令


如果解析器期望使用的命令，不同于 `cli_parse` 所运行的命令，则可使用 `parser` 的 `command` 子选项，配置解析器期望使用的命令：


```yaml
- name: "Run command and parse with native"
  ansible.utils.cli_parse:
    command: sho int
    parser:
      name: ansible.netcommon.native
      command: show interface
```


### 提供自定义的操作系统值


使用解析器的 `os` 子选项直接设置操作系统，而非使用 `ansible_network_os` 或 `ansible_distribution` 主机变量，生成模板路径或使用指定解析器引擎：

```yaml
- name: Use ios instead of iosxe for pyats
  ansible.utils.cli_parse:
    command: show something
    parser:
      name: ansible.netcommon.pyats
      os: ios

- name: Use linux instead of fedora from ansible_distribution
  ansible.utils.cli_parse:
    command: ps -ef
    parser:
      name: ansible.netcommon.native
      os: linux
```


### 解析既有文本


使用 `text` 而非 `command` 选项，解析 playbook 中较早收集的文本。


```yaml
# using /home/user/templates/filename.yaml
- name: "Parse text from previous task"
  ansible.utils.cli_parse:
    text: "{{ output['stdout'] }}"
    parser:
      name: ansible.netcommon.native
      template_path: /home/user/templates/filename.yaml

 # using /home/user/templates/filename.yaml
- name: "Parse text from file"
  ansible.utils.cli_parse:
    text: "{{ lookup('file', 'path/to/file.txt') }}"
    parser:
      name: ansible.netcommon.native
      template_path: /home/user/templates/filename.yaml

# using templates/nxos_show_version.yaml
- name: "Parse text from previous task"
  ansible.utils.cli_parse:
    text: "{{ sho_version['stdout'] }}"
    parser:
      name: ansible.netcommon.native
      os: nxos
      command: show version
```

（End）


