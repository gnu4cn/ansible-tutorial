# Ansible 教程


[前言](preface.md)

---

# 入门

- [建立仓库](building_an_inventory.md)
- [创建 playbook](creating_a_playbook.md)
- [Ansible 的一些概念](concepts.md)

---

# 执行环境，Execution Environment

- [执行环境入门](ee.md)
- [建立执行环境](ee/setting_up_ee.md)
- [运行执行环境](ee/running.md)


---

# 安装指南，Installation Guide

- [安装 Ansible](installing.md)
- [在特定操作系统上安装 Ansible](installing_on_distros.md)


---

# 配置

- [配置 Anisble](configuring.md)

---

# 使用

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
    - [高级 playbook 语法](usage/playbook/adv_syntax.md)
- [使用 Ansible vault 保护敏感数据](usage/vault.md)
- [使用 Ansible 专辑](usage/collections.md)
    - [在 playbook 中使用专辑](usage/collection/using.md)


---

# 插件

- [关于插件](plugins.md)
- [仓库插件](plugins/inventory.md)
- [连接插件](plugins/connection.md)
- [查找插件](plugins/lookup.md)


---

# 专辑

- [关于专辑](collections.md)
- [专辑索引](collection_index.md)
- [Anisble 内建专辑](collections/ansible_builtin.md)

---

# 开发者指南

- [关于开发者指南](dev_guide.md)
- [本地开发](dev_guide/developing_locally.md)
- [插件开发](dev_guide/plugins.md)


---

# Ansible Galaxy

- [Galaxy 用户手册](galaxy_user_guide.md)

---

# Tips and Tricks

- [示例配置](tips_tricks/sample_setup.md)

---

# 参考

- [YAML 语法](refs/YAML_syntax.md)
- [Playbook 关键字](refs/playbook_keywords.md)
- [Red Hat Ansible 自动化平台](refs/aap.md)
- [优先级规则](refs/precedence.md)
