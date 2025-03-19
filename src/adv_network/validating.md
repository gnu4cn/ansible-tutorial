# 使用 Ansible 根据设定标准验证数据

[`validate` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/utils/validate_module.html#ansible-collections-ansible-utils-validate-module) 会使用某种验证引擎，根据咱们预定义的标准验证数据。咱们可从设备或文件中拉取这些数据，根据咱们定义的标准对其加以验证，并利用验证结果，识别出配置或运行状态的偏移，而有选择地采取补救措施。



## 理解 `validate` 插件


[ansible.utils](https://galaxy.ansible.com/ui/repo/published/ansible/utils) 包含了这个 [`validate`](https://docs.ansible.com/ansible/latest/collections/ansible/utils/validate_module.html#ansible-collections-ansible-utils-validate-module) 模组。


要验证数据：


1. 拉取到结构化数据，或使用 [`cli_parse` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/utils/cli_parse_module.html#ansible-collections-ansible-utils-cli-parse-module) 将咱们的数据转换为结构化的格式；
2. 定义出测试该数据所依据的标准；
3. 选择某种验证引擎，并根据选取的标准和验证引擎，测试该数据是否有效。


数据结构和标准，取决于咱们所选的验证引擎。这里的示例使用的是 [`ansible.utils` 专辑](https://galaxy.ansible.com/ui/repo/published/ansible/utils) 中提供的 `jsonschema` 验证引擎。如文档所示，Red Hat Ansible 自动化平台的订阅，仅限于支持 `jsonschema` 的公共 API。



## 结构化数据

**Structuring the data**


咱们可从某个文件拉取先前已结构化的数据，或使用 [`cli_parse` 模组](https://docs.ansible.com/ansible/latest/collections/ansible/utils/cli_parse_module.html#ansible-collections-ansible-utils-cli-parse-module) 结构化咱们的数据。


以下示例获取到某种网络（Cisco NXOS）接口的运行状态，并使用 `ansible.netcommon.pyats` 分析器将该状态转换为结构化数据。


```yaml
  - name: "Fetch interface state and parse with pyats"
    ansible.utils.cli_parse:
      command: show interface
      parser:
        name: ansible.netcommon.pyats
    register: nxos_pyats_show_interface

  - name: print structured interface state data
    ansible.builtin.debug:
      msg: "{{ nxos_pyats_show_interface['parsed'] }}"
```


这会得到以下的结构化数据。


```json
ok: [nxos] => {
"changed": false,
"parsed": {
    "Ethernet2/1": {
        "admin_state": "down",
        "auto_mdix": "off",
        "auto_negotiate": false,
        "bandwidth": 1000000,
        "beacon": "off"
        <--output omitted-->
    },
    "Ethernet2/10": {
        "admin_state": "down",
        "auto_mdix": "off",
        "auto_negotiate": false,
        "bandwidth": 1000000,
        "beacon": "off",
        <--output omitted-->
    }
  }
}
```


有关如何将半结构化数据解析为结构化数据的详情，请参阅 [使用 Ansible 解析半结构化文本](parsing.md)。


## 定义验证所依据的标准


这个示例使用了 `jsonschema` 验证引擎，来解析我们在上一小节中创建出的 JSON 结构化数据。所谓标准，定义了我们希望数据要符合的状态。在本例中，我们可以根据所有接口的所需管理状态为 `up`，进行验证。


那么这个示例中的 `jsonschema` 标准就如下所示：


```json
$ cat network_run/criteria/nxos_show_interface_admin_criteria.json
{{#include ../../network_run/criteria/nxos_show_interface_admin_criteria.json}}
```


## 验证数据


现在我们有了结构化数据以及标准，就可以使用 `validate` 模组来验证这些数据了。


以下任务将检查接口的当前状态，是否与标准文件中所定义的所需状态一致。


```yaml
- name: Validate interface admin state
  ansible.utils.validate:
    data: "{{ nxos_pyats_show_interface['parsed'] }}"
    criteria:
      - "{{ lookup('file',  './criteria/nxos_show_interface_admin_criteria.json') | from_json }}"
    engine: ansible.utils.jsonschema
  ignore_errors: true
  register: result

- name: Print the interface names that do not satisfy the desired state
  ansible.builtin.debug:
    msg: "{{ item['data_path'].split('.')[0] }}"
  loop: "{{ result['errors'] }}"
  when: "'errors' in result"
```


在这些任务中，我们做了下面这些：


1. 将 `data` 选项设置为来自 `cli_parse` 模组的结构化 JSON 数据；
2. 将 `criteria` 选项设置为我们定义的那个 JSON 标准文件；
3. 将验证引擎，设置为 `jsonschema`。


> **注意**：`criteria` 选项的值，可以是个列表，且应是由所用验证引擎定义的某种格式。对于这个示例，咱们需要在控制节点上安装 `jsonschema`。


这些任务会输出一个显示出接口管理状态不是 `up` 错误列表。


```console
TASK [Validate interface for admin state] ***********************************************************************************************************
fatal: [nxos02]: FAILED! => {"changed": false, "errors": [{"data_path": "Ethernet2/1.admin_state", "expected": "up", "found": "down", "json_path": "$.Ethernet2/1.admin_state", "message": "'down' does not match 'up'", "relative_schema": {"pattern": "up", "type": "string"}, "schema_path": "patternProperties.^.*.properties.admin_state.pattern", "validator": "pattern"}, {"data_path": "Ethernet2/10.admin_state", "expected": "up", "found": "down", "json_path": "$.Ethernet2/10.admin_state", "message": "'down' does not match 'up'", "relative_schema": {"pattern": "up", "type": "string"}, "schema_path": "patternProperties.^.*.properties.admin_state.pattern", "validator": "pattern"}], "msg": "Validation errors were found.\nAt 'patternProperties.^.*.properties.admin_state.pattern' 'down' does not match 'up'. \nAt 'patternProperties.^.*.properties.admin_state.pattern' 'down' does not match 'up'. \nAt 'patternProperties.^.*.properties.admin_state.pattern' 'down' does not match 'up'. "}
...ignoring


TASK [Print the interface names that do not satisfy the desired state] ****************************************************************************
Monday 14 December 2020  11:05:38 +0530 (0:00:01.661)       0:00:28.676 *******
ok: [nxos] => {
   "msg": "Ethernet2/1"
}
ok: [nxos] => {
   "msg": "Ethernet2/10"
}
```


这显示 `Ethernet2/1` 和 `Ethernet2/10` 两个接口未处于定义标准所需的状态。咱们可创建出一份报告，或采取进一步措施进行补救，使接口达到定义标准所需的状态。


（End）


