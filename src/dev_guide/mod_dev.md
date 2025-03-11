# 开发模组

所谓模组，是 Ansible 代表咱们在本地或远程运行的可重复使用的独立脚本。模组会与咱们的本地机器、API 或远端系统交互，以执行像是更改数据库密码或启动云实例等特定任务。每个模组都可由 Ansible API、`ansible` 或 `ansible-playbook` 等程序使用。模组会提供一些预定义接口，会接受一些参数，并在退出前通过向 `stdout` 打印 JSON 字符串，向 Ansible 返回信息。


如果咱们需要的功能，在成千上万的 Ansible 模组集合中都不可用，咱们则可以轻松编写咱们自己的定制模组。在咱们编写某个用于本地用途的模组时，咱们可以选择任何编程语言，并遵循咱们自己的规则。请用这个主题，了解如何用 Python 创建 Ansible 模组。在咱们创建出某个模组后，必须在本地将其添加到相应的目录中，以便 Ansible 能找到并执行他。有关在本地添加某个模组的详情，请参阅 [在本地添加模组和插件](local_plugins.md)。


## 准备开发 Ansible 模组的环境


咱们只需安装 `ansible-core` 就可以测试模组。模组可以任何语言编写，但以下指南的大部分内容，都假定咱们使用的是 Python。纳入 Ansible 本身的模组，必须是 Python 或 Powershell 的。


将 Python 或 Powershell 用于咱们定制模组的一个好处是，可以使用 [`module_utils` 通用代码](https://docs.ansible.com/ansible/latest/reference_appendices/module_utils.html)，完成参数处理、日志记录和响应编写等大量繁重工作。


## 创建一个模组


强烈建议咱们在 Python 开发中，使用 `venv` 或 `virtualenv`。


要创建一个模组：


1. 在咱们的工作区中创建一个 `library` 目录。咱们的测试 playbook 也应存在于同一目录下；
2. 创建咱们的新模组文件 `$ touch library/my_test.py`。或者以咱们选择的编辑器打开/创建他；
3. 将下面的内容粘贴到咱们的新模组文件中。其中包括了 [所需的 Ansible 格式与文档](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_documenting.html#developing-modules-documenting)，简单[用于声明模组选项的参数规范](https://docs.ansible.com/ansible/latest/dev_guide/developing_program_flow_modules.html#argument-spec)，以及一些示例代码；
4. 修改并扩展代码，以实现咱们打算咱们的新模组要做的事情。关于如何编写简洁的模组代码，请参阅 [编程技巧](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_best_practices.html#developing-modules-best-practices) 和 [Python 3 兼容性](https://docs.ansible.com/ansible/latest/dev_guide/developing_python_3.html#developing-python-3) 页面。


```python
{{#include ../../mod_dev/library/demo_mod.py}}
```


## 创建信息或事实模组

Ansible 使用 `facts` 模组收集目标机器的信息，使用 `info` 模组收集其他对象或文件的信息。如果咱们发现自己试图往现有模组中添加 `state: info` 或 `state: list`，便是需要一个新的专门 `_facts` 或 `_info` 模组的迹象。

在 Ansible 2.8 及以后版本中，我们有两种类型的信息模组，分别是 `*_info` 和 `*_facts`。


如果某个模组被命名为 `<something>_facts`，那是因为他的主要目的是返回 `ansible_facts`。不要用 `_facts` 来命名那些不用于此目的的模组。只将 `ansible_facts` 用于获取主机的特定信息，例如网络接口及其配置、安装的操作系统和程序等。


查询/返回一般信息（而非 `ansible_facts`）的模组应命名为 `_info`。一般信息是那些非主机特定的信息，例如在线/云服务的信息（咱们可以访问到同一台主机中同一在线服务的不同账户），或该机器上可访问的虚拟机与容器的信息，或单个文件或程序的信息等。


这些 `info` 和 `facts` 模组与其他 Ansible 模组别无二致，只是有些小要求：

1. 他们必须以 `<something>_info` 或 `<something>_facts` 命名，其中 `<something>` 是单数；
2. `info` 类的 `*_info` 模组，**必须** 以字典结果的形式返回，以便别的模组可以访问他们；
3. `facts` 类的 `*_facts` 模组，**必须** 返回结果字典中的 `ansible_facts` 字段，以便其他模组可以访问他们；
4. 他们 **必须** 支持 [`check_mode`](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_checkmode.html#check-mode-dry)；
5. 他们 **必须不会** 对系统造成改变；
6. 他们 **必须** 为 [返回值字段](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_documenting.html#return-block) 编写文档，并编写 [示例](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_documenting.html#examples-block)。


咱们可将咱们的事实，像下面这样添加到结果的 `ansible_facts` 字段：


```python
module.exit_json(changed=False, ansible_facts=dict(my_new_fact=value_of_fact))
```

其余就跟创建普通模组一样。


## 验证咱们的模组代码


在咱们修改了上面的示例代码，实现咱们想要的功能后，咱们就可以试用咱们的模组了。如果咱们在验证模组代码时遇到错误，我们的 [调试技巧](https://docs.ansible.com/ansible/latest/dev_guide/debugging.html#debugging-modules) 将有所帮助。


### 在本地验证咱们的模组代码


最简单的方法，是使用 `ansible` 这个 adhoc 命令：


```console
ANSIBLE_LIBRARY=./library ansible -m my_test -a 'name=hello new=true' remotehost
```

若咱们的模组不需要以某个远端主机为目标，咱们可像下面这样快速、轻松地在本地运行咱们的代码：


```console
ANSIBLE_LIBRARY=./library ansible -m my_test -a 'name=hello new=true' localhost
```


- 如果出于任何原因（`pdb`、使用 `print()`、更快的迭代等），咱们想要避免通过 Ansible，那么另一种方法就是创建一个参数文件，即一个向其传递参数以便运行该模组基本 JSON 配置文件。将该参数文件命名为 `/tmp/args.json`，并添加以下内容：


```json
{
    "ANSIBLE_MODULE_ARGS": {
        "name": "hello",
        "new": true
    }
}
```

- 然后该模组便可在本地直接测试。这样做省略了打包步骤，且直接使用了 `module_utils` 文件：


```console
$ python library/my_test.py /tmp/args.json
```

这应返回如下的输出：


```json
{"changed": true, "state": {"original_message": "hello", "new_message": "goodbye"}, "invocation": {"module_args": {"name": "hello", "new": true}}}
```


### 在某个 playbook 中验证咱们的模组代码


通过将其包含在某个 playbook 中，咱们可以轻松运行一个完整测试，只需 `library` 目录与 play 在同一个目录下：

- 在 `library` 所在目录下创建一个 playbook：`touch test_mod.yml`；
- 将以下内容添加到这个新的 playbook 文件：

```yaml
- name: test my new module
  hosts: localhost
  tasks:
  - name: run the new module
    my_test:
      name: 'hello'
      new: true
    register: testout
  - name: dump test output
    debug:
      msg: '{{ testout }}'
```


- 运行该 playbook 并分析输出：`$ ansible-playbook test_mod.yml`


## 测试咱们新创建的模组

查看我们的 [测试](https://docs.ansible.com/ansible/latest/dev_guide/testing.html#developing-testing) 小节，了解更多详细信息，包括有关 [测试模组文档](https://docs.ansible.com/ansible/latest/dev_guide/testing_documentation.html#testing-module-documentation)、添加 [集成测试](https://docs.ansible.com/ansible/latest/dev_guide/testing_documentation.html#testing-module-documentation) 等的说明。


> **注意**：若要贡献到 Ansible，那么每个新模组和插件，都应有集成测试，即使这些测试无法在 Ansible CI 基础设施上运行。在这种情况下，应在 [别名文件](https://docs.ansible.com/ansible/latest/dev_guide/testing/sanity/integration-aliases.html) 中用 `unsupported` 别名标记这些测试。


## 回馈 Ansible


如果咱们想通过添加新功能或修复 bug 为 `ansible-core` 作出贡献，请创建一个 `ansible/ansible` 代码仓库的分叉，并以 `devel` 分支为起点，开发某个新的特性分支。当咱们有了良好的工作代码变更时，咱们可以选择咱们的特性分支作为源，Ansible `devel` 分支作为目标，向 Ansible 代码库提交拉取请求。

若咱们打算为某个 [Ansible 专辑](https://docs.ansible.com/ansible/latest/community/contributing_maintained_collections.html#contributing-maintained-collections) 贡献模块，请查看我们的 [提交检查单](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_checklist.html#developing-modules-checklist)、[编程技巧](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_best_practices.html#developing-modules-best-practices)、[维护 Python 2 和 Python 3 兼容性的策略](https://docs.ansible.com/ansible/latest/dev_guide/developing_python_3.html#developing-python-3)，以及在打开拉取请求前进行 [测试](https://docs.ansible.com/ansible/latest/dev_guide/testing.html#developing-testing) 的相关信息。


[社区指南](../community_guide.md) 涵盖了如何开启拉取请求，以及接下来会发生的事情。


## 交流与开发支持

请访问 [Ansible 交流指南](../community_guide/getting_started.md#与-ansible-社区交流)，了解如何加入对话。


## 致谢

感谢 Thomas Stringer (`@trstringer`) 为这个主题贡献原始资料。


（End）


