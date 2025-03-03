# Windows 性能

本文档提供了一些咱们可能想要将其应用于 Windows 主机，以加快他们运行速度的性能选项，尤其是在对这些 Windows 主机使用 Ansible 的情况下，以及在一般情况下。

## 优化 PowerShell 性能，减少 Ansible 任务开销


要将 PowerShell 的启动速度提高约 10 倍，请在某个管理员会话中，运行以下 PowerShell 代码段。预计其将耗时约数十秒。

> **注意**：如果 `ngen` 任务或服务已经创建了原生镜像，native images，那么咱们将观察不到任何性能上的差别（不过此时该代码段的执行速度，将比尚未创建出原生镜像时更快）。


```powershell
{{#include ./pwsh_optimization.ps1}}
```


