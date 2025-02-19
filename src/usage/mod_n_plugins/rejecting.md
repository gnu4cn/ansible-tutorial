# 剔除模组

**Rejecting modules**


若咱们打算避免使用某些模组，咱们可将他们添加到一个剔除列表，阻止 Ansible 加载他们。要剔除插件，就要创建 `yaml` 配置文件。该文件的默认位置为 `/etc/ansible/plugin_filters.yml`。使用 `ansible.cfg` 的 `defaults` 小节中的 [`PLUGIN_FILTERS_CFG`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#plugin-filters-cfg) 设置，咱们就可以为该剔除列表，选择一个别的路径。下面是个示例剔除列表：


```yaml
---
filter_version: '1.0'
module_rejectlist:
  # Deprecated
  - docker
  # We only allow pip, not easy_install
  - easy_install
```

该文件包含了两个字段：


- 文件版本，以便咱们将来更新格式的同时，保持向后兼容性。当前版本应为字符串 `'1.0'`；
- 要剔除的模组列表。Ansible 在检索某个任务要调用的模组时，将不会加载此列表中的任何模组。


（End）

