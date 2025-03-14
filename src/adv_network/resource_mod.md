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
 ipv6 address FC00:100/64
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
