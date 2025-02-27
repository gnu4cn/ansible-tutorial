# 配置使用加密内容的默认值

## 设置一个默认 vault ID

若咱们使用某个 vault ID 的频率远高于任何其他 vault ID，那么咱们可设置 `DEFAULT_VAULT_IDENTITY_LIST` 这个配置选项，指定为某个默认的 vault ID 与密码来源。若咱们没有指定 `--vault-id`，Ansible 将全部使用默认的 vault ID 与密码来源。咱们可以给该选项设置多个值。设置多个值就相当于传递多个 `--vault-id` 的命令行选项。


> **译注**：这是在 `~/.ansible.cfg` 文件中，添加类似下面这样的一行设置的。注意由于 `~/.ansible.cfg` 是个 INI 文件，故该变量的清单写法无需 `[]`。


```ini
[defaults]
vault_identity_list = 'dev@~/.ansible/dev.secret', 'prod@~/.ansible/prod.secret'
```

## 设置默认密码来源


若咱们不愿在命令行上提供密码文件，或者咱们使用某个 vault 密码文件的频率远高于其他文件，那么咱们可设置 [`DEFAULT_VAULT_PASSWORD_FILE`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#default-vault-password-file) 这个配置选项，或 [`ANSIBLE_VAULT_PASSWORD_FILE`](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#envvar-ANSIBLE_VAULT_PASSWORD_FILE) 这个环境变量，指定出要使用的某个默认文件。例如，若咱们设置了 `ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt`，Ansible 就会自动检索该文件中的密码。这在比如咱们从诸如 Jenkins 等持续集成系统中，使用 Ansible 时，就非常有用。

咱们引用的文件，既可以是个包含着密码的文件（纯文本的），也可以是某个会返回密码的脚本（设置了可执行权限）。



（End）



