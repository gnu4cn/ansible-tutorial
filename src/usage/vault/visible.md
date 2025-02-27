# 加密文件于何时成为可见？


一般来说，咱们用 Ansible Vault 加密的内容，会在执行后保持加密。但有一个例外。若咱们将加密文件作为 `src` 参数，传递给 [`copy`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html#copy-module)、[`template`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/template_module.html#template-module)、[`unarchive`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/unarchive_module.html#unarchive-module)、[`script`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/script_module.html#script-module)或 [`assemble`](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/assemble_module.html#assemble-module) 等模组，那么该文件将在目标主机上不会被加密（假设咱们在运行 play 时，提供了正确的 vault 密码）。这种行为是有意的，也是有用的。咱们可以加密某个配置文件或模板，以避免共享咱们的配置细节，但当咱们将该配置复制到咱们环境中的服务器时，就会希望其被解密，以便本地用户和进程可以访问他。


（End）

