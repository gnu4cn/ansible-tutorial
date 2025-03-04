# Windows 性能

本文档提供了一些咱们可能想要将其应用于 Windows 主机，以加快他们运行速度的性能选项，尤其是在对这些 Windows 主机使用 Ansible 的情况下，以及在一般情况下。

## 优化 PowerShell 性能，减少 Ansible 任务开销


要将 PowerShell 的启动速度提高约 10 倍，请在某个管理员会话中，运行以下 PowerShell 代码段。预计其将耗时约数十秒。

> **注意**：如果 `ngen` 任务或服务已经创建了原生镜像，native images，那么咱们将观察不到任何性能上的差别（不过此时该代码段的执行速度，将比尚未创建出原生镜像时更快）。


```powershell
{{#include ./pwsh_optimization.ps1}}
```

每个 Windows Ansible 模组，都会用到 PowerShell。这个优化减少了 PowerShell 的启动时间，消除了每次调用的开销。

> **译注**：此脚本还修复了 Windows 10 IoT Enterprise LTSC 版本上 DSC 特性的问题。


这个代码片段使用 [原生映像生成器 `ngen`](https://docs.microsoft.com/en-us/dotnet/framework/tools/ngen-exe-native-image-generator#WhenToUse)，创建出 PowerShell 所依赖的那些组建的原生镜像。


## 修复虚拟机/云实例启动时 CPU 使用过高的问题


假如咱们正在创建从中生成实例的黄金镜像，若咱们清楚在黄金镜像创建过程与运行时之间，CPU 类型不会发生变化，就可通过在黄金镜像创建过程中 [处理 `ngen` 队列](https://docs.microsoft.com/en-us/dotnet/framework/tools/ngen-exe-native-image-generator#native-image-service)，而避免在启动时出现高 CPU 任务。


> **译注**：关于黄金镜像，以下是些参考。
>
> - [docs.aws.amazon.com: What is a golden image?](https://docs.aws.amazon.com/prescriptive-guidance/latest/iot-greengrass-golden-images/overview.html)
>
> - [redhat.com: What is a golden image?](https://www.redhat.com/en/topics/linux/what-is-a-golden-image)


将以下任务，放在咱们 playbook 的末尾，同时注意可能导致原生镜像失效的一些因素（请 [参阅 MSDN](https://docs.microsoft.com/en-us/dotnet/framework/tools/ngen-exe-native-image-generator#native-images-and-jit-compilation) ）。


```yaml
- name: generate native .NET images for CPU
  win_dotnet_ngen:
```

（End）


