# 执行 playbook


准备好运行咱们的 Ansible playbook 了吗？


运行复杂 playbook 需要反复试错，因此就要了解 Ansible 给到咱们的一些功能，以确保成功的执行。咱们可以 “模拟运行，dry run” playbook，来验证咱们的任务，使用 `--start-at-task` 与 `--step` 单步模式等选项，来有效地排除 playbook 问题。咱们还可使用 Ansible 的调试器，在执行过程中纠正任务。通过异步的 playbook 执行，Ansible 提供了灵活性，并提供了允许咱们运行咱们 playbook 特定部分的标签特性。
