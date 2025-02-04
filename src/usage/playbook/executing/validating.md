# 验证任务：检查模式与 `diff` 模式

Ansible 提供两种验证任务的执行模式：检查模式和差异模式。两种模式可单独使用，也可以一起使用。当咱们正在创建或编辑某个 playbook 或角色，并想知道他将做些什么时，这两种模式非常有用。在检查模式下，Ansible 运行时不会在远端系统上做任何更改。支持检查模式的模组，会报告他们将要做的更改。不支持检查模式的模组，则什么也不报告，且什么也不做。在差异模式下，Ansible 会提供前后比较。支持差异模式的模组，会显示出详细信息。咱们可将检查模式和差异模式结合起来，用于 playbook 或角色的详细验证。

## 使用检查模式

检查模式就是种模拟。他不会为那些用到 [基于注册变量的条件](../using/conditionals.md#基于注册变量的条件)（先前任务结果）的任务生成输出。不过，他非常适合验证那些一次只在一个节点上，运行的配置管理 playbook。要以检查模式运行某个 playbook：

```console
ansible-playbook foo.yml --check
```

### 强制或阻止任务的检查模式


*版本 2.2 中的新特性*。


如果咱们希望某些任务，在无论咱们是否以或不以 `--check` 命令行选项下，始终或从不以检查模式运行，则可以为这些任务添加 `check_mode` 选项：

- 即使在调用 playbook 时不带 `--check` 选项，也要强制某个任务以检查模式运行，那么要设置 `check_mode：true`；
- 即使在调用 playbook 时带有 `--check` 选项，也要强制某个任务以普通模式运行，那么要设置 `check_mode：false`。

比如：

```yaml
  tasks:
    - name: This task will always make changes to the system
      ansible.builtin.command: echo '--even-in-check-mode'
      check_mode: false

    - name: This task will never make changes to the system
      ansible.builtin.lineinfile:
        line: "important config"
        dest: /path/to/myconfig.conf
        state: present
      check_mode: true
      register: changes_to_important_config

```

以 `check_mode: true` 运行单个任务，对测试 Ansible 模组很有用，既可以测试模组本身，也可以测试在什么条件下模组会作出改动。咱们可在这些任务上注册变量（参见 [条件](../using/conditionals.md) ），以了解潜在变化的更多细节。

> **注意**：在版本 2.2 前，只存在 `check_mode: false` 的等价物。其写法为 `always_run: true`。

### 在检查模式下跳过任务或忽略错误


*版本 2.1 中的新特性*。

若咱们想要在检查模式下运行 Ansible 时，跳过某个任务或忽略某个任务上的错误，那么可以使用一个布尔值的魔法变量 `ansible_check_mode`，当 Ansible 在检查模式下运行时，该变量会被设置为 `True`。例如：

```yaml
  tasks:

    - name: This task will be skipped in check mode
      ansible.builtin.git:
        repo: ssh://git@github.com/mylogin/hello.git
        dest: /home/mylogin/hello
      when: not ansible_check_mode

    - name: This task will ignore errors in check mode
      ansible.builtin.git:
        repo: ssh://git@github.com/mylogin/hello.git
        dest: /home/mylogin/hello
      ignore_errors: "{{ ansible_check_mode }}"
```


## 使用差异模式


`ansible-playbook` 命令的 `--diff` 选项，可单独使用，也可以与 `--check` 一起使用。当咱们在差异模式下运行时，任何支持差异模式的模组，都会报告所做的改动，或在与 `--check` 一起使用时，报告原本会做的改动。差异模式最常见于那些处理文件的模组（例如 `template` 模组），但其他模组也可能会显示出 “前后，before and after” 信息（例如 `user` 模组）。

差异模式会产生大量输出，因此最好在一次检查一台主机时使用。例如：

```console
ansible-playbook foo.yml --check --diff --limit foo.example.com
```

> **译注**：差异模式下运行 playbook，会有类似 `diff` 命令的输出。

```console
--- before: /tmp/myconfig.conf (content)
+++ after: /tmp/myconfig.conf (content)
@@ -0,0 +1 @@
+important config
```


*版本 2.4 中的新特性*。


### 强制或阻止任务的差异模式

由于 `--diff` 选项可能泄露敏感信息，咱们可通过指定 `diff: false`，对某个任务禁用他。例如：


```yaml
  tasks:
    - name: This task will not report a diff when the file changes
      ansible.builtin.template:
        src: secret.conf.j2
        dest: /etc/secret.conf
        owner: root
        group: root
        mode: '0600'
      diff: false
```

（End）


