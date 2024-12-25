# 创建 playbook

所谓 playbook，是 YAML 格式的自动化蓝图，automation blueprints, in `YAML` format，Ansible 使用 playbook 来部署和配置托管节点。

- **模组，module**
    Ansible 在托管节点上，要运行的代码或二进制文件的一个单元。Ansible 模组以集合形式分组，每个组别都有个完全限定集合名称（Fully Qualified Collection Name, FQCN）。

- **任务，task**
    对某单个定义了 Ansible 所执行操作模组的引用。

- **Play**
    映射到仓库中一些托管节点的有序任务列表。

- **Playbook**
    定义出 Ansible 从上到下执行操作，以实现总体目标顺序的 play 列表。

> **译注**：下图是 Ansible 模组、任务、play 与 playbook 的关系图示。可以看出其中模组是直接作用于托管主机/系统的单元。任务、play 和 playbook 是将简单的模组，组织为复杂操作的方式，而任务是介于模组与 play 之间的桥梁（模组 <--> 任务 <--> play）。

![Ansible 模组、任务、play 与 playbook 之间的关系图示](images/ansible-playbooks.jpeg)
