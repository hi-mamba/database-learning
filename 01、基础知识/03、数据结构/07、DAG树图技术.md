
[原文](https://blog.csdn.net/shangsongwww/article/details/89945977)

<https://www.jianshu.com/p/583513c9613a>

# DAG/树图技术

有向无环图：其实就是指一个没有回路的有向图。

DAG（ Directed Acyclic Graph 有向无环图） 即通过`有向无环图`这个就够来保存交易，
一般通过带有方向的图的边(edge)来表达交易之间的先后确认关系。

DAG技术相比传统的链式结构，有先天的高并发优势，因此受到市场的广泛关注和研究，
但双发的判断更加复杂，目前也还没有很成熟（充分被时间和市场验证）的项目。


