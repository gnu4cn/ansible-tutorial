# `undef` 函数：给未定义变量添加提示


*版本 2.12 中新引入*。


Jinja2 的 `undef()` 函数，会返回一个从 `jinja2.StrictUndefined` 派生的 Python `AnsibleUndefined` 对象。使用 `undef()` 来取消某个优先级较低变量的定义。例如，对于某个任务块，可覆盖某个主机变量：

```yaml
---
- hosts: localhost
  gather_facts: no
  module_defaults:
    group/ns.col.auth: "{{ vaulted_credentials | default({}) }}"
  tasks:
    - ns.col.module1:
    - ns.col.module2:

    - name: override host variable
      vars:
        vaulted_credentials: "{{ undef() }}"
      block:
        - ns.col.module1:
```


`undef` 函数接受一个可选参数：

- `hint`
如果 [`DEFAULT_UNDEFINED_VAR_BEHAVIOR`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-undefined-var-behavior) 被配置为给出一条错误，则给出一个关于该未定义变量的定制提示。
