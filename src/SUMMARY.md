# Ansible 教程


[前言](preface.md)

---

# 入门

- [建立仓库](building_an_inventory.md)
- [创建 playbook](creating_a_playbook.md)
- [Ansible 的一些概念](concepts.md)

# 执行环境，Execution Environment

- [执行环境入门](ee.md)
- [建立执行环境](ee/setting_up_ee.md)
- [运行执行环境](ee/running.md)


---

# 安装、升级与配置

- [安装 Ansible](installing.md)
- [在特定操作系统上安装 Ansible](installing_on_distros.md)
- [配置 Anisble](configuring.md)

---

# 使用 Anisble

- [建立 Anisble 仓库](usage/inventories_building.md)
- [运用动态仓库](usage/dynamic_inventory.md)
- [模式：选取主机与组别](usage/patterns.md)
- [连接方式与细节](usage/connection.md)
- [使用 Anisble 命令行工具](usage/cli.md)
    - [`ansible`](usage/cli/ansible.md)
    - [`ansible-config`](usage/cli/ansible-config.md)
    - [`ansible-console`](usage/cli/ansible-console.md)
    - [`ansible-doc`](usage/cli/ansible-doc.md)
    - [`ansible-galaxy`](usage/cli/ansible-galaxy.md)
    - [`ansible-inventory`](usage/cli/ansible-inventory.md)
    - [`ansible-playbook`](usage/cli/ansible-playbook.md)
    - [`ansible-pull`](usage/cli/ansible-pull.md)
    - [`ansible-vault`](usage/cli/ansible-vault.md)
    - [Ansible 命令行备忘录](usage/cli/cli-cheatsheet.md)
- [使用 playbooks](usage/playbooks.md)
    - [关于 playbook](usage/playbook/about.md)
    - [使用 playbook](usage/playbook/using.md)
        - [关于模板化（Jinja2）](usage/playbook/using/templating.md)
        - [使用过滤器操作数据](usage/playbook/using/filters.md)
        - [测试判断](usage/playbook/using/tests.md)
        - [查找](usage/playbook/using/lookups.md)
        - [模板中的 Python3](usage/playbook/using/py3_in_temp.md)
        - [`now` 函数：获取当前时间](usage/playbook/using/now_func.md)
        - [`undef` 函数：给未定义变量添加提示](usage/playbook/using/undef_func.md)
        - [循环](usage/playbook/using/loops.md)
        - [控制任务于何处运行：委派与本地操作](usage/playbook/using/delegation.md)
        - [条件](usage/playbook/using/conditionals.md)
        - [区块](usage/playbook/using/blocks.md)
        - [处理程序：在变化时运行操作](usage/playbook/using/handlers.md)
        - [Playbook 中的错误处理](usage/playbook/using/err_handling.md)
        - [设置远端环境](usage/playbook/using/remote_env.md)
        - [重用 Ansible 工件](usage/playbook/using/reuse.md)
        - [角色](usage/playbook/using/roles.md)
        - [模组默认值](usage/playbook/using/mod_defaults.md)
        - [交互式输入：提示符](usage/playbook/using/prompts.md)
        - [使用变量](usage/playbook/using/vars.md)
        - [发现变量：事实与魔法变量](usage/playbook/using/facts_and_magic_vars.md)
        - [Playbook 示例： 持续交付和滚动升级](usage/playbook/using/example.md)
    - [执行 playbook](usage/playbook/executing.md)
        - [验证任务：检查模式与 `diff` 模式](usage/playbook/executing/validating.md)
        - [掌握权限提升：`become`](usage/playbook/executing/become.md)
        - [标签](usage/playbook/executing/tags.md)
        - [执行 playbook 以排除故障](usage/playbook/executing/troubleshooting.md)
        - [对任务进行调试](usage/playbook/executing/debuging.md)
        - [异步操作与轮询](usage/playbook/executing/async.md)
        - [控制 playbook 的执行：策略及其他](usage/playbook/executing/strategies.md)
    - [高级 playbook 语法](usage/playbook/adv_syntax.md)
    - [操作数据](usage/playbook/man_data.md)


- [使用 Ansible vault 保护敏感数据](usage/vault.md)
    - [关于 Anisble Vault](usage/vault/about.md)
    - [管理 vault 密码](usage/vault/passwords.md)
    - [使用 Anisble Vault 加密内容](usage/vault/encrypting.md)
    - [使用加密变量及文件](usage/vault/enc_vars_and_files.md)
    - [配置使用加密内容的默认值](usage/vault/default.md)
    - [加密文件于何时成为可见？](usage/vault/visible.md)
    - [使用 Ansible Vault 加密的文件格式](usage/vault/formats.md)


- [使用 Ansible 模组与插件](usage/mod_n_plugins.md)
    - [模组介绍](usage/mod_n_plugins/about_mod.md)
    - [模组的维护与支持](usage/mod_n_plugins/mod_maintenance_n_support.md)
    - [剔除模组](usage/mod_n_plugins/rejecting.md)
    - [使用插件](usage/mod_n_plugins/plugins.md)
        - [动作插件](usage/mod_n_plugins/plugins/actions.md)
        - [成为插件](usage/mod_n_plugins/plugins/become.md)
        - [缓存插件](usage/mod_n_plugins/plugins/cache.md)
        - [回调插件](usage/mod_n_plugins/plugins/callback.md)
        - [`cliconf` 插件](usage/mod_n_plugins/plugins/cliconf.md)
        - [连接插件](usage/mod_n_plugins/plugins/connection.md)
        - [文档片段](usage/mod_n_plugins/plugins/docs_fragment.md)
        - [过滤器插件](usage/mod_n_plugins/plugins/filter.md)
        - [`httpapi` 插件](usage/mod_n_plugins/plugins/httpapi.md)
        - [仓库插件](usage/mod_n_plugins/plugins/inventory.md)
        - [查找插件](usage/mod_n_plugins/plugins/lookup.md)
        - [模组](usage/mod_n_plugins/plugins/module.md)
        - [模组工具](usage/mod_n_plugins/plugins/mod_utilities.md)
        - [`netconf` 插件](usage/mod_n_plugins/plugins/netconf.md)
        - [`shell` 插件](usage/mod_n_plugins/plugins/shell.md)
        - [策略插件](usage/mod_n_plugins/plugins/strategy.md)
        - [终端插件](usage/mod_n_plugins/plugins/terminal.md)
        - [测试插件](usage/mod_n_plugins/plugins/test.md)
        - [`vars` 插件](usage/mod_n_plugins/plugins/vars.md)
    - [模组与插件索引](usage/mod_n_plugins/index.md)


- [使用 Ansible 专辑](usage/collection.md)
    - [安装专辑](usage/collection/installation.md)
    - [移除专辑](usage/collection/remove.md)
    - [下载专辑](usage/collection/downloading.md)
    - [列出专辑](usage/collection/listing.md)
    - [验证专辑](usage/collection/verifying.md)
    - [在 playbook 中使用专辑](usage/collection/using.md)
    - [专辑索引](usage/collection/index.md)

- [在 Windows 及 BSD 平台上使用 Ansible](usage/windows_n_bsd.md)
    - [使用 Ansible 管理 BSD 主机](usage/win_n_bsd/bsd.md)
    - [使用 Ansible 管理 Windows 主机](usage/win_n_bsd/win.md)
        - [预期状态设定，DSC](usage/win_n_bsd/win/dsc.md)
        - [Windows 性能](usage/win_n_bsd/win/performance.md)
        - [Windows SSH](usage/win_n_bsd/win/ssh.md)
        - [使用 Ansible 与 Windows](usage/win_n_bsd/win/usage.md)
        - [Windows 远程管理](usage/win_n_bsd/win/winrm.md)
        - [WinRM 证书认证](usage/win_n_bsd/win/winrm_cert.md)
        - [Kerberos 认证](usage/win_n_bsd/win/kerberos.md)
- [Ansible 技巧与窍门](usage/tips_tricks.md)
    - [通用技巧](usage/tips_n_tricks/general.md)
    - [Playbook 技巧](usage/tips_n_tricks/playbook.md)
    - [仓库技巧](usage/tips_n_tricks/inventory.md)
    - [执行的诀窍](usage/tips_n_tricks/execution.md)
    - [示例 Ansible 设置](usage/tips_n_tricks/sample_setup.md)


---

# 向 Ansible 贡献

- [Anisble 社区指南](community_guide.md)
    - [入门](community_guide/getting_started.md)
    - [贡献者路径](community_guide/path.md)


---

# 扩展 Ansible

- [开发者指南](developer_guide.md)
    - [在本地添加模组与插件](dev_guide/local_plugins.md)
    - [咱们是否应该开发一个模组？](dev_guide/reason.md)
    - [开发模组](dev_guide/mod_dev.md)

---

# 网络自动化

- [网络入门](network.md)
    - [基本概念](network/concepts.md)
    - [网络自动化有何不同？](network/difference.md)
    - [运行咱们的首个命令与 Playbook](network/initial.md)
    - [建立咱们的仓库](network/inventory.md)
    - [使用 Ansible 网络角色](network/roles.md)
    - [进阶](network/beyond.md)
    - [使用网络设备连接选项](network/connection.md)
    - [资源及接下来的措施](network/resources.md)

- [网络高级主题](./adv_network.md)
    - [网络资源模组](adv_network/resource_mod.md)
    - [Ansible 网络示例](adv_network/examples.md)
    - [使用 Ansible 解析半结构化文本](adv_network/parsing.md)
    - [使用 Ansible 根据设定标准验证数据](adv_network/validating.md)
    - [网络调试与故障排除指南](adv_network/troubleshooting.md)
    - [在网络模组中使用命令输出与提示符](adv_network/command_output_n_prompts.md)
    - [Ansible 网络 FAQ](adv_network/faq.md)
    - [平台选项](adv_network/platform_options.md)
        - [CloudEngine 操作系统平台](adv_network/platform_options/ce.md)
        - [CNOS 平台选项](adv_network/platform_options/cnos.md)
        - [DELL OS6 平台选项](adv_network/platform_options/dellemc_os6.md)
        - [DELL OS9 平台选项](adv_network/platform_options/dnos9.md)
        - [DELL OS10 平台选项](adv_network/platform_options/os10.md)
        - [ENOS 平台选项](adv_network/platform_options/enos.md)
        - [EOS 平台选项](adv_network/platform_options/eos.md)
        - [`ERIC_ECCLI` 平台选项](adv_network/platform_options/eric_eccli.md)
        - [`EXOS` 平台选项](adv_network/platform_options/exos.md)
        - [FRR 平台选项](adv_network/platform_options/frr.md)
        - [ICX 平台选项](adv_network/platform_options/icx.md)
        - [IOS 平台选项](adv_network/platform_options/icx.md)
        - [IronWare 平台选项](adv_network/platform_options/ironware.md)
        - [Junos OS 平台选项](adv_network/platform_options/junos.md)

---

# Ansible Galaxy

- [Galaxy 用户手册](galaxy_user_guide.md)

---

# 参考

- [YAML 语法](refs/YAML_syntax.md)
- [Playbook 关键字](refs/playbook_keywords.md)
- [Red Hat Ansible 自动化平台](refs/aap.md)
- [优先级规则](refs/precedence.md)
- [Ansible 配置设置](refs/configuration.md)
