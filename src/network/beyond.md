# 进阶

**Beyond the Basics**


这个页面介绍了一些帮助咱们通过目录结构和源代码控制，管理 Ansible 工作流的概念。与这个指南开头的 [“基本概念”](./concepts.md) 一样，这些中级概念在所有 Ansible 运用中都是通用的。


## 一种典型 Ansible 文件树


Ansible 会希望在一些确切位置，找到一些确切的文件。在咱们扩充仓库、创建并运行更多网络 playbook 时，请像下面这样，在 Ansible 项目工作目录中组织咱们的文件：


```console
.
├── backup
│   ├── vyos.example.net_config.2018-02-08@11:10:15
│   ├── vyos.example.net_config.2018-02-12@08:22:41
├── first_playbook.yml
├── inventory
├── group_vars
│   ├── vyos.yml
│   └── eos.yml
├── roles
│   ├── static_route
│   └── system
├── second_playbook.yml
└── third_playbook.yml
```

其中的 `backup` 目录及其中的文件，会在咱们以 `backup: true` 参数运行 `vyos_config` 等模组时创建出来。



## 跟踪对仓库与 playbook 的更改：使用 `git` 进行源代码控制


在咱们扩展仓库、角色及 playbook 时，咱们应将咱们的 Ansible 项目置于源代码控制之下。我们推荐使用 `git` 进行源代码控制。`git` 提供了审计跟踪功能，让咱们可以跟踪变更、错误回滚、查看历史记录，而分担管理、维护和扩展咱们 Ansible 生态系统的工作量。有很多使用 `git` 的教程和指南。


（End）


