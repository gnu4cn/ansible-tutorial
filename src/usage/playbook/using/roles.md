# 角色

角色让咱们，可以根据已知文件结构，自动加载相关变量、文件、任务、处理程序和其他 Ansible 工件。在咱们将咱们的内容，分组到角色后，咱们就可以轻松地重用他们，并与其他用户共享。

## 角色目录结构

Ansible 角色有个定义好的目录结构，有 7 个主要标准目录。在每个角色中，咱们必须至少包含其中一个目录。咱们可以省略角色未用到的所有目录。例如：

```console
# playbooks
site.yml
webservers.yml
fooservers.yml
```

```console
roles/
    common/               # 这个层次结构，表示某个 “角色”
        tasks/            #
            main.yml      # <-- 如有必要，任务文件可包含一些较小文件
        handlers/         #
            main.yml      #  <-- 处理程序文件
        templates/        #  <-- 用于使用模板资源的文件
            ntp.conf.j2   #  <------- 以 .j2 结尾的模板
        files/            #
            bar.txt       #  <-- 用于 copy 模组资源的文件
            foo.sh        #  <-- 用于 script 模组资源的脚本文件
        vars/             #
            main.yml      #  <-- 与本角色相关的变量
        defaults/         #
            main.yml      #  <-- 本角色的默认较低优先级变量
        meta/             #
            main.yml      #  <-- 角色依赖项
        library/          # 角色也可以包含定制模组
        module_utils/     # 角色也可以包含定制的 module_utils
        lookup_plugins/   # 或其他插件类型，比如这种情形下的查找

    webtier/              # 如同上面 "common" 这种同类型的结构，用于 webtier 角色
    monitoring/           # ""
    fooapp/               # ""
```

默认情况下，Ansible 会在大多数角色目录中，查找 `main.yml` 文件以获取相关内容（也包括 `main.yaml` 和 `main`）：

- `tasks/main.yml` - 角色提供给 play 用于执行的任务列表；
- `handlers/main.yml` - 导入到父 play 中，供该角色，或 play 中的其他角色及任务使用的处理程序；
- `defaults/main.yml` - 该角色提供的变量的低优先级值（更多信息请参阅 [“使用变量”](vars.md)）。角色自身的默认值，将优先于其他角色的默认值，但任何/所有其他变量来源，都将优先于此；
- `vars/main.yml` - 角色提供给 play 的高优先级变量（更多信息请参阅 [“使用变量”](vars.md)）；
- `files/stuff.txt` - 对角色及其子角色可用的一或多个文件；
- `templates/something.j2` - 在角色或子角色中使用的模板；
- `meta/main.yml` - 角色的元数据，包括角色的依赖项及可选的 Galaxy 元数据，如支持的平台等。对于以独立角色上传到 Galaxy，这是必须的，但在咱们的 play 中使用角色时，则不需要。


> **注意**：
>
> - 对于某个角色来说，上述任何文件都不是必需的。例如，咱们可以只提供 `files/something.txt` 或 `vars/for_import.yml`，其仍然是个有效的角色；
>
> - 在独立角色中，咱们也可以包含自定义模组和/或插件，例如 `library/my_module.py`，这些模组和/或插件可在该角色中使用（更多信息，请参阅 [在角色中嵌入模组和插件](#在角色中嵌入模组和插件)）；
>
> - 所谓 “独立” 角色，指的是不属于某个专辑，而是作为可单独安装内容的角色；
>
> - `vars/` 和 `defaults/` 中的变量，会被导入到 play 的作用域中，除非咱们通过 `import_role`/`include_role` 中的 `public` 选项禁用他。
