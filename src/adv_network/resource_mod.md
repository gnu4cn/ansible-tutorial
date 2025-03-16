# 网络资源模组


Ansible 的网络资源模组简化了咱们管理不同网络设备的方式，并使之标准化。网络设备会将其配置分离为适用于某项网络服务的多个小节（比如接口与 VLAN 小节）。Ansible 的网络资源模组利用这一优势，允许咱们在网络设备的配置内，配置一些子小节或称为 **资源**。网络资源模组为不同的网络设备，提供了一种一致体验。


## 网络资源模组的状态


咱们通过指定出咱们所想要的某个网络资源模组状态的方式，使用这些网络资源模组。资源模组支持以下这些状态：

- `merged`

Ansible 会将设备上的配置，与任务中提供的配置合并。

- `replaced`

Ansible 会用任务中提供的配置子小节，替换设备上的配置子小节。

- `overridden`

Ansible 会用任务中提供的配置，覆盖该项资源在设备上的配置。请谨慎使用这种状态，因为咱们可能会移除咱们对设备的访问权限（例如，由移除管理接口的配置造成）。

- `deleted`

Ansible 会删除设备上的配置子小节，并恢复所有默认设置。

- `gathered`

Ansible 会显示从网络设备收集到的该项资源详细信息，并在结果中使用 `gathered` 键进行访问。

- `rendered`

Ansible 会以设备原生格式，the device-native format，（比如 Cisco IOS CLI），渲染任务中提供的配置。Ansible 会在结果的 `rendered` 键中，返回这种渲染后的配置。请注意，这种状态不会与网络设备通信，而可脱机使用。


- `parsed`


Ansible 会将 `running_config` 选项中的配置，解析为结果中 `parsed` 键下的 Ansible 的结构化数据。请注意此过程不会从网络设备收集配置，因此这种状态可以离线使用。


## 使用网络资源模组


下面这个示例会根据不同的状态，配置某个 Cisco IOS 设备的 L3 接口资源。


```yaml
- name: configure l3 interface
  cisco.ios.ios_l3_interfaces:
    config: "{{ config }}"
    state: <state>
```

下面举例说明在给定资源初始配置，与给定任务提供的配置下，资源配置会如何随不同状态而变化。

- 资源起始配置

```console
interface loopback100
 ip address 10.10.1.100 255.255.255.0
 ipv6 address FC00::100/64
```

- 任务提供的配置（YAML 格式）

```yaml
config:
- ipv6:
  - address: fc00::100/64
  - address: fc00::101/64
  name: loopback100
```


+ 设备上的最终资源配置
    - `merged`

    ```console
    interface loopback100
     ip address 10.10.1.100 255.255.255.0
     ipv6 address FC00:100/64
     ipv6 address FC00:101/64
    ```

    - `replaced`

    ```console
    interface loopback100
     no ip address
     ipv6 address FC00:100/64
     ipv6 address FC00:101/64
    ```

    - `overridden`

    不正确的用例。这将从设备上删除所有接口 **（包括 `mgmt` 接口），除了** 那个已配置的 `loopback100`。


    - `deleted`

    ```console
    interface loopback100
     no ip address
    ```


> **译注**：在针对运行在 GNS3 上的 Cisco IOS 与 NXOSv 路由器的实验中，均为观察到示例中所描述的变化。后续将进一步确认资源模组根据状态对设备资源配置的影响。在状态为 `replaced` 时，示例中的资源模组执行的命令如下（注册该任务的结果就可以看到）：

```json
"commands": [
    "interface loopback100",
    "ipv6 address fc00::101/64"
]
```

> 因此其只会往接口 `loopback100` 添加一个 IPv6 地址，而不会移除该接口上的 IPv4 地址。有此造成与上面所讲到的预期结果不同。


网络资源模组返回以下详细信息：


- `before` 状态 - 该任务被执行前，现有资源的配置；
- `after` 状态 - 该任务执行后，存在于网络设备上的新的资源配置；
- 命令 - 在设备上所配置的全部命令。


```yaml
ok: [nxos101] =>
  result:
    after:
      contact: IT Support
      location: Room E, Building 6, Seattle, WA 98134
      users:
      - algorithm: md5
        group: network-admin
        localized_key: true
        password: '0x73fd9a2cc8c53ed3dd4ed8f4ff157e69'
        privacy_password: '0x73fd9a2cc8c53ed3dd4ed8f4ff157e69'
        username: admin
    before:
      contact: IT Support
      location: Room E, Building 5, Seattle HQ
      users:
      - algorithm: md5
        group: network-admin
        localized_key: true
        password: '0x73fd9a2cc8c53ed3dd4ed8f4ff157e69'
        privacy_password: '0x73fd9a2cc8c53ed3dd4ed8f4ff157e69'
        username: admin
    changed: true
    commands:
    - snmp-server location Room E, Building 6, Seattle, WA 98134
    failed: false
```


## 示例：验证网络设备配置未更改


下面的 playbook 使用 `arista.eos.eos_l3_interfaces` 模组，收集网络设备配置的一个子集（仅 3 层接口），并验证信息准确而未发生更改。这个 playbook 会将 `arista.eos.eos_facts` 的结果，直接传递给 `arista.eos.eos_l3_interfaces` 这个模组。


```yaml
{{#include ../../network_run/demo_arista_resource.yml}}
```


## 示例： 获取及更新某个网络设备上的 VLAN


这个示例展示了，咱们如何使用资源模组完成：

1. 获取到某个网络设备上的当前配置；
2. 将该配置保存到本地；
3. 更新该配置并将其应用到网络设备。



这个示例使用了 `cisco.ios.ios_vlans` 资源模组，获取及更新一个 IOS 设备上的 VLAN。


1. 获取到当前的 IOS VLAN 配置；


```yaml
    - name: Gather VLAN information as structured data
      cisco.ios.ios_facts:
         gather_subset:
          - '!all'
          - '!min'
         gather_network_resources:
         - 'vlans'
```


2. 将该 VLAN 配置存储在本地；


```yaml
    - name: Store VLAN facts to host_vars
      copy:
        content: "{{ ansible_network_resources | to_nice_yaml }}"
        dest: "{{ playbook_dir }}/host_vars/{{ inventory_hostname }}"
```

> **译注**：将此任务修改为下面这样：

```yaml
    - name: Store VLAN facts to host_vars
      copy:
        content: "{{ ansible_network_resources }}"
        dest: "{{ playbook_dir }}/host_vars/{{ inventory_hostname }}.json"
```

> 便于第 3、4 步中的 VLAN 配置的编辑和资源配置更新。


3. 修改该存储的文件，以在本地更新 VLAN 配置；

4. 将更新后的 VLAN 配置，与设备上的既有配置合并。


```yaml
    - name: Make VLAN config changes by updating stored facts on the control node.
      cisco.ios.ios_vlans:
        config: "{{ vlans }}"
        state: merged
      tags: update_config
```

> **译注**：实验中将该任务修改为下面这样：

```yaml
    - name: Make VLAN config changes by updating stored facts on the control node.
      cisco.ios.ios_vlans:
        config: "{{ lookup('ansible.builtin.file', config_file) }}"
        state: replaced
      tags: update_config
      vars:
        config_file: "{{ playbook_dir }}/host_vars/{{ inventory_hostname }}.json"
```

> 以使用 `lookup` 插件，从配置文件读取内容。其中 `config_file` 中的内容为下面这样。

```json
[
  {"name": "default", "vlan_id": 1, "state": "active", "shutdown": "disabled", "mtu": 1500},
  {"name": "oa", "vlan_id": 10, "state": "active", "shutdown": "disabled", "mtu": 1500},
  {"name": "rnd", "vlan_id": 20, "state": "active", "shutdown": "disabled", "mtu": 1500},
  {"name": "sales", "vlan_id": 20, "state": "active", "shutdown": "disabled", "mtu": 1500}
]
```

> 否则会报出以下错误。

- `"dictionary requested, could not parse JSON or key=value"`；
- `"argument 'config' is of type <class 'dict'> and we were unable to convert to list: <class 'dict'> cannot be converted to a list"`。


（End）


