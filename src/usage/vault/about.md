# 关于 Ansible Vault

Ansible Vault 可加密变量和文件，进而咱们可保护诸如密码或密钥等敏感内容，而不是让他们以明文形式在 playbook 或角色中可见。要使用 Ansible Vault，咱们需要一或多个用于加密与解密内容的密码。若咱们将咱们的保险库密码，存储在秘密管理器等第三方工具中，咱们还需要一个脚本来访问他们。要将该密码与 [`ansible-vault`](../cli/ansible-vault.md) 这个命令行工具一起使用，来创建和查看加密变量、创建加密文件、加密现有文件，或编辑、重制密钥，re-key，或解密文件。然后，咱们就可以把加密内容置于源代码控制系统之下，而更安全地共享内容。


> <span style="background-color: #f0b37e; color: white; width: 100%"> **警告**：</span>
>
> - Ansible Vault 下的加密，只能保护 “静态数据，data at rest”。一旦内容被解密（即 “使用中的数据，data in use”），play 及插件的作者，就有责任避免任何的秘密泄露，有关隐藏输出的详情，请参阅 [`no_log`](https://docs.ansible.com/ansible/latest/reference_appendices/faq.html#keep-secret-data)，有关 Ansible Vault 下所使用编辑器的安全考虑，请参阅 [确保编辑器安全的步骤](encryping.md#保全编辑器的步骤)。


通过提供用于加密变量和文件的密码，咱们可在临时命令和 playbook 中，使用加密的变量和文件。咱们可修改 `ansible.cfg` 文件，指定出某个密码文件的位置，或者始终提示输入密码。

（End）


