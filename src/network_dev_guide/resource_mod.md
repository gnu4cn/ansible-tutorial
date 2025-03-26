# 开发网络资源模组

## 了解网络和安全资源模组


网络及安全设备，会将配置分离为应用到某项网络或安全服务的一些小节（比如接口、VLAN 等）。Ansible 的资源模组利用这一优势，允许用户对设备配置中的子小节或资源加以配置。资源模组为不同的网络和安全设备，提供了一致的体验。例如，某个网络资源模组可能只更新网络设备的网络接口、VLAN、ACL 等的特定部分配置。资源模组会：

1. 获取配置的一个片段（事实收集），例如接口配置；
2. 将返回的配置转换为键值对；
3. 将这些键值对放入内部独立的结构化数据格式中。


既然配置数据已被规范化，那么用户就可以更新和修改这些数据，然后使用该资源模组将配置数据发回设备。这样，无需手动解析、数据操作与数据模型管理，即实现了完整的往返配置更新，a full round-trip configuration update without the need for manual parsing, data manipulation, and data model management。


资源模组有两个顶级键 -- `config` 和 `state`：

- `config`：将资源配置数据模型定义为键值对。根据所管理的资源，`config` 的类型选项，可以是 `dict` 或 `list of dict`。也就是说，如果设备只有一个全局配置，那么他应该是个 `dict`（例如，全局的 LLDP 配置）。而如果设备有多个配置实例，则应为 `list` 类型，列表中的各个元素应为 `dict` 类型（例如，接口的配置）；
- `state`：定义了资源模组在终端设备上的动作。


某个新资源模组的 `state` 应支持以下值（适用于支持这些值的设备）：


- `merged`

Ansible 会将设备上的配置，与任务中提供的配置合并。

- `replaced`

Ansible 会用任务中提供的配置子小节，替换设备上的配置子小节。

- `overridden`

Ansible 会用任务中提供的配置，覆盖该资源的设备上配置。请谨慎使用这种状态，因为咱们可能会移除咱们对设备的访问（例如，经由覆盖管理接口的配置）。


- `deleted`

Ansible 会删除设备上的配置子小节，并恢复任何的默认设置。


- `gathered`

Ansible 会显示从网络设备收集到的资源详细信息，并在结果中使用 `gathered` 密钥访问。


- `rendered`

Ansible 会以设备原生格式（例如 Cisco IOS CLI），渲染任务中所提供的配置。Ansible 会在结果中的 `rendered` 键，返回渲染后的配置。请注意，这种状态不会与网络设备通信，而可离线使用。


- `parsed`

Ansible 会将 `running_configuration` 选项中的配置，解析为在结果中 `parsed` 键里的 Ansible 结构化数据。请注意，这不会从网络设备收集配置，因此这种状态可以离线使用。


Ansible 维护专辑中的模组必须支持这些状态值。如果咱们开发的模组只支持 `"present"` 和 `"absent"` 两种状态，那么咱们可将其提交给社区专辑。



> **注意**：`rendered`、`gathered` 与 `parsed` 三种状态不会在设备上执行任何更改。



## 开发网络和安全资源模组


Ansible 工程团队，the Ansible Engineering team，确保在 Ansible 维护的专辑中，模组设计和代码模式在不同资源和平台上保持一致，以提供独立于供应商的感受，及交付高质量代码。我们建议咱们使用 [资源模组构建器](https://github.com/ansible-network/resource_module_builder) 开发资源模组。


开发资源模组的高层级流程为，the highlevel process for developing a resource module：

1. 在资源模组模型代码仓库中，创建并共享某个资源模型设计，作为一个共评议的 PR；
2. 下载最新版本的 [资源模组构建器](https://github.com/ansible-network/resource_module_builder)；
3. 运行资源模组构建器，在咱们已获批准的资源模型中，创建一个专辑框架，a collection scaffold；
4. 编写实现咱们资源模组的代码；
5. 开发验证咱们资源模组集成测试和单元测试；
6. 创建一个到咱们要将这个新资源模组，添加到相应专辑的 PR。请参阅 [“为 Ansible 维护的专辑做贡献”](https://docs.ansible.com/ansible/latest/community/contributing_maintained_collections.html#contributing-maintained-collections)，了解有关为咱们的模组确定出正确专辑的详细信息。


（暂略）

