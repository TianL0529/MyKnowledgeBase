### KAFKA

​	一种分布式流式系统

##### 1.为什么要使用消息中间件（消息中心）

* 消息通讯：可以作为基本的消息通讯，比如聊天室等工具的使用；
* 异步处理：将一些使实用性要求不是很强的业务异步处理，起到缓冲的作用，一定程度上也会避免因为有些消费者处理的太慢或者网络问题导致的通讯等待太久，因为导致的单个服务崩溃，甚至产生多个服务间的雪崩效应；
* 应用解耦：消息队列将消息生产者和消费者分离开来，可以实现应用解耦；
* 流量削峰：可以通过在应用前端采用消息队列来接受请求，可以达到削峰的目的；请求超过队列长度直接不处理，重定向至错误页面。类似于网关限流的作用冗余存储；消息队列把数据进行持久化，知道他们已经被完全处理，通过这一方式规避了数据丢失风险。

##### 2.Kafka的特点

* 可靠性：Kafka是分布式的、可分区的、数据可备份的、高度容错的；
* 可扩展性：在无需停机的情况下实现轻松扩展;
* 消息持久性：Kafka支持将消息持久化到本地磁盘；
* 高性能：Kafka的消息发布订阅具有很高的吞吐量，即使存储了TB级的消息，他依然能保持稳定的性能。

##### 3.Kafka使用场景

* 日志信息收集记录：FileBeats + Kafka + ELK集群架构，FileBeats先将数据传递给消息队列，Logstash server（二级Logstash）拉取消息队列中的数据，进行过滤和分析，然后将数据传递给Elasticsearch进行存储，最后再由Kibana将日志和数据呈现给用户；
* 用户轨迹跟踪：kafka经常被用来记录web用户或者app用户的各种活动，如浏览网页、搜索、点击等操作，这些活动被各个服务器发布到kafka的topic中，然后消费者通过订阅这些topic来做实时的监控分析，当然也可以保存到数据库。
* 运营指标：kafka也经常用来记录运营监控数据。包括收集各种分布式应用的数据，生产各种操作的集中反馈，比如报警和报告。

##### 4.Kafka使用哪种方式消费消息，pull还是push？

Kafka的消费者使用pull的方式将消息从broker中拉下来

* 优点
  * Kafka可以根据consumer的消费能力以适当的速率消费消息
  * 消费者可以控制自己的消费方式：可以使用批量消费，也可以选择逐条消费
  * 消费者还可以选择不同的提交方式来实现不同的传输语义，要是使用了push的方式，就没有这些优点了

* 缺点：如果Kafka没有数据，消费者会专门有个线程去等待数据，可能会陷入循环等待中。

##### 5.Kafka如何避免上述缺点

​		通过在拉请求中**设置参数**，允许消费者请求在等待数据到达的“长轮询”中进行阻塞（并且可选地等待到给定的字节数，以确保大的传输大小）来避免这一问题。

##### 6.push方式的优缺点

* 优点：相对于pull的方式来说，它不需要专门有一个消息去等待，而可能造成线程循环等待的问题。
* 缺点： push（推）模式一般是会以同样的速率将消息推给消费者，很难适应消费速率不同的消费者，这样很容易造成有些消费能力比较低的consumer来不及处理消息，导致出现拒绝服务以及网络拥塞的情况。

##### 7.Kafka与Zookeeper关系

Kafka的数据会存储在zookeeper上。包括broker和消费者consumer的信息 其中：

* **broker信息**：包含各个broker的服务器信息、Topic信息。
* **消费者信息**：主要存储每个消费者消费的topic的offset的值。

##### 8.Kafka的架构

![589bd1739f877fb3f63489ec034413e1](D:\Desktop\知识整理\图片\589bd1739f877fb3f63489ec034413e1.jpg)

* **Producer**：Producer即生产者，消息的产生者，是消息的入口。
* **Broker**：Broker是kafka实例，每个服务器上有一个或多个kafka的实例，我们姑且认为每个broker对应一台服务器。每个kafka集群内的broker都有一个**不重复**的编号，如图中的broker-0、broker-1等……
* **Topic**：消息的主题，可以理解为消息的分类，kafka的数据就保存在topic。在每个broker上都可以创建多个topic。每个主题都定义了要发布给它的消息类型，定义主题是我们工程师的责任，所以我们应该记住一些经验法则：
  * 每个主题都应描述一个其他服务可能需要了解的事件。
  * 每个主题都应定义每条消息都将遵循的一个唯一模式（schema）。
* **Partition**：Topic的分区，每个topic可以有多个分区，分区的作用是做负载，提高kafka的吞吐量。同一个topic在不同的分区的数据是不重复的，partition的表现形式就是一个一个的文件夹！分区使消息可以被并行消费。kafka允许通过一个分区键（partition key）来确定地将消息分配给各个分区。分区键是一段数据（通常是消息本身就的某些属性，例如ID），其上会应用一个算法以确定分区。

![img](D:\Desktop\知识整理\图片\40d8ef5773e150b03b647e30e38a22c6.png)

* **Replication**:每一个分区都有多个副本，副本的作用是做备胎。当主分区（Leader）故障的时候会选择一个备胎（Follower）上位，成为Leader。在kafka中默认副本的最大数量是10个，且副本的数量不能大于Broker的数量，follower和leader绝对是在不同的机器，同一机器对同一个分区也只可能存放一个副本（包括自己）。
* **Message**：每一条发送的消息主体。
* **Consumer**：消费者，即消息的消费方，是消息的出口。
* **Consumer Group**：我们可以将多个消费组组成一个消费者组，在kafka的设计中同一个分区的数据只能被消费者组中的某一个消费者消费。同一个消费者组的消费者可以消费同一个topic的不同分区的数据，这也是为了提高kafka的吞吐量！
* **Zookeeper**：kafka集群依赖zookeeper来保存集群的的元信息，来保证系统的可用性。

工作流程分析：

![ab708fccb54a688f2fa00668e3324928](D:\Desktop\知识整理\图片\ab708fccb54a688f2fa00668e3324928.jpg)

​		需要注意的一点是，消息写入leader后，follower是主动的去leader进行同步的！producer采用push模式将数据发布到broker，每条消息追加到分区中，顺序写入磁盘，所以保证**同一分区**内的数据是有序的！写入示意图如下：

![a0d98f13806434264e83993543be578f](D:\Desktop\知识整理\图片\a0d98f13806434264e83993543be578f.jpg)

上面说到数据会写入到不同的分区，那kafka为什么要做分区呢？

* **方便扩展**：因为一个topic可以有多个partition，所以我们可以通过扩展机器去轻松的应对日益增长的数据量。
* **提高并发**：以partition为读写单位，可以多个消费者同时消费数据，提高了消息的处理效率。

​        熟悉负载均衡的朋友应该知道，当我们向某个服务器发送请求的时候，服务端可能会对请求做一个负载，将流量分发到不同的服务器，那在kafka中，如果某个topic有多个partition，producer又怎么知道该将数据发往哪个partition呢？kafka中有几个原则：

*  partition在写入的时候可以指定需要写入的partition，如果有指定，则写入对应的partition；
* 如果没有指定partition，但是设置了数据的key，则会根据key的值hash出一个partition；
* 如果既没指定partition，又没有设置key，则会轮询选出一个partition。

​        Producer将数据写入kafka后，集群就需要对数据进行保存了！kafka将数据保存在磁盘，可能在我们的一般的认知里，写入磁盘是比较耗时的操作，不适合这种高并发的组件。Kafka初始会单独开辟一块磁盘空间，顺序写入数据（效率比随机写入高）。

**Partition结构**

每个topic都可以分为一个或多个partition，如果觉得topic比较抽象，那partition就是比较具体的东西了 ！Partition在服务器上的表现形式就是一个一个的文件夹，每个partition的文件夹下面会有多组segment文件，每组segment（部分的意思）文件又包含.index文件、.log文件、.timeindex文件三个文件，log文件就是存储message的地方，而index和timeindex文件为索引文件，用于检索消息。

![83ad96b2e9a6735f01da8483647c7b9e](D:\Desktop\知识整理\图片\83ad96b2e9a6735f01da8483647c7b9e.jpg)

​		如上图，这个partition有三组segment文件，每个log文件的大小是一样的，但是存储的message数量是不一定相等的（每条的message大小不一致）。文件的命名是以该segment最小offset来命名的，如000.index存储offset为0~368795的消息，kafka就是利用**分段+索引**的方式来解决查找效率的问题。

**Message结构**

​		上面说到log文件就实际是存储message的地方，我们在producer往kafka写入的也是一条一条的message，那存储在log中的message是什么样子的呢？消息主要包含消息体、消息大小、offset、压缩类型……等等！我们重点需要知道的是下面三个：

* offset：offset是一个占8byte的有序id号，它可以唯一确定每条消息在parition内的位置！
* 消息大小：消息大小占用4byte，用于描述消息的大小。
* 消息体：消息体存放的是实际的消息数据（被压缩过），占用的空间根据具体的消息而不一样。

**存储策略**

无论消息是否被消费，kafka都会保存所有的消息。那对于旧数据有什么删除策略呢？

* 基于时间，默认配置是168小时（7天）。
* 基于大小，默认配置是1073741824 = 1G。

那么它每次删除多少消息呢？

* topic的分区**partitions**，被分为一个个小segment，按照segment为单位进行删除(segment的大小也可以进行配置，默认log.segment.bytes = 1024 * 1024 * 1024)，由时间从远到近的顺序进行删除

需要注意的是，kafka读取特定消息的**时间复杂度是O(1)**，所以这里删除过期的文件并不会提高kafka的性能！

**消费数据**

​		消费者在拉取消息的时候也是**找leader**去拉取，多个消费者可以组成一个消费者组（consumer group），每个消费者组都有一个组id！同一个消费组者的消费者可以消费同一topic下不同分区的数据，但是不会组内多个消费者消费同一分区的数据！

![6441c57c4ca47f6d8b362217f5d128c3](D:\Desktop\知识整理\图片\6441c57c4ca47f6d8b362217f5d128c3.jpg)

​		图示是消费者组内的消费者小于partition数量的情况，所以会出现某个消费者消费多个partition数据的情况，消费的速度也就不及只处理一个partition的消费者的处理速度！如果是消费者组的消费者多于partition的数量，那会不会出现多个消费者消费同一个partition的数据呢？上面已经提到过不会出现这种情况！多出来的消费者不消费任何partition的数据。所以在实际的应用中，建议**消费者组的consumer的数量与partition的数量一致**！

查找消息的时候是怎么利用segment+offset配合查找的呢？假如现在需要查找一个offset为368801的message是什么样的过程呢？先看看下面的图：

![65115332701f470da9fb13eda8b31ade](D:\Desktop\知识整理\图片\65115332701f470da9fb13eda8b31ade.jpg)

* 1、 通过查询跳跃表`ConcurrentSkipListMap`，先找到offset的368801message所在的segment文件（利用二分法查找），这里找到的就是在第二个segment文件。
* 2、 打开找到的segment中的.index文件（也就是368796.index文件，该文件起始偏移量为368796+1，我们要查找的offset为368801的message在该index内的偏移量为368796+5=368801，所以这里要查找的**相对offset**为5）。由于该文件采用的是稀疏索引的方式存储着相对offset及对应message物理偏移量的关系，所以直接找相对offset为5的索引找不到，这里同样利用 二分法查找相对offset小于或者等于指定的相对offset的索引条目中最大的那个相对offset，所以找到的是相对offset为4的这个索引。
* 3、 根据找到的相对offset为4的索引确定message存储的物理偏移位置为256。打开数据文件，从位置为256的那个地方开始顺序扫描直到找到offset为368801的那条Message。

​        这套机制是建立在offset为有序的基础上，利用**segment**+**有序offset**+**稀疏索引**+**二分查找**+**顺序查找**等多种手段来高效的查找数据！至此，消费者就能拿到需要处理的数据进行处理了。那每个消费者又是怎么记录自己消费的位置呢？在早期的版本中，消费者将消费到的offset维护zookeeper中，consumer每间隔一段时间上报一次，这里容易导致重复消费，且性能不好！在新的版本中消费者消费到的offset已经直接维护在kafk集群的__consumer_offsets这个topic中！

##### 9.数据传输的事务有哪几种？每种传输，分别是怎样实现的呢？

* 1.最多一次（<=1）： 消息不会被重复发送，最多被传输一次，但也有可能一次不传输；

  * 最多一次：consumer先**读消息**，**记录offset**，最后再**处理消息**

    这样，不可避免地存在一种**可能**：在记录offset之后，还没处理消息就出现故障了，新的consumer会继续从这个offset处理，那么就会出现有些消息**永远不会被处理。**那么这种机制，就是消息最多被处理一次。

* 2.最少一次(>=1)：消息不会被漏发送，最少被传输一次，但也有可能被重复传输；

  * 最少一次：consumer可以先读取消息，处理消息，最后记录offset

    当然如果在记录offset之前就crash了，新的consumer会重复的消费一些消息。那么这种机制，就是消息最多被处理一次。

* 3.精确的一次（Exactly once）(=1): 不会漏传输也不会重复传输,每个消息都传输被一次而且仅仅被传输一次，这是大家所期望的。

  * 精确一次：可以通过将提交分为两个阶段来解决：保存了offset后提交一次，消息处理成功之后再提交一次。当然也可以直接将消息的offset和消息被处理后的结果保存在一起，这样就能够保证消息能够被精确地消费一次。

##### 10.Kafka在什么情况下会出现消息丢失？

* 消息发送的时候，如果发送出去以后，消息可能因为网络问题并没有发送成功；
* 消息消费的时候，消费者在消费消息的时候，若还未做处理的时候，服务挂了，那这个消息就丢失了；
* 分区中的leader所在的broker挂了：Kafka的Topic中的分区Partition是leader与follower的主从机制，发送消息与消费消息都直接面向leader分区，并不与follower交互，follower则回去leader中拉取消息，进行消息的备份，这样保证了一定的可靠性，但是当leader副本所在的broker突然挂掉，那么就要从follower中选举一个leader，但leader的数据在**挂掉之前并没有同步到follower的这部分消息**肯定就会丢失掉。

##### 11.Kafka的性能好在什么地方？

Kafka的性能好在两个方面：**顺序写**和**零拷贝**：

* **顺序写**：直接追加数据到末尾。实际上，磁盘顺序写的性能极高，在磁盘个数一定，转数一定的情况下，基本和内存速度一致。（操作系统每次从磁盘读写数据的时候，都需要找到数据在磁盘上的地址，再进行读写。而如果是机械硬盘，寻址需要的时间往往会比较长）
* **零拷贝**：
  * 读取文件，再用socket发送出去这一过程传统实现方式：先读取、再发送，实际会经过以下四次复制
    * 将磁盘文件，读取到操作系统内核缓冲区**Read Buffer**
    * 将内核缓冲区的数据，复制到应用程序缓冲区**Application Buffer**
    * 将应用程序缓冲区**Application Buffer**中的数据，复制到socket网络发送缓冲区
    * 将**Socket buffer**的数据，复制到**网卡**，由网卡进行网络传输

![v2-39c716176a0ff87ee0025c96f6608814_720w](D:\Desktop\知识整理\图片\v2-39c716176a0ff87ee0025c96f6608814_720w.jpg)

​		传统方式，读取磁盘文件并进行网络发送，经过的四次数据copy是非常繁琐的。重新思考传统IO方式，会注意到**在读取磁盘文件后，不需要做其他处理，直接用网络发送出去的这种场景下**，第二次和第三次数据的复制过程，不仅没有任何帮助，反而带来了巨大的开销。那么这里使用了**零拷贝**，也就是说，直接由内核缓冲区**Read Buffer**将数据复制到**网卡**，省去第二步和第三步的复制。

![v2-ee634587f9335c695ae837ee946efd45_720w](D:\Desktop\知识整理\图片\v2-ee634587f9335c695ae837ee946efd45_720w.jpg)

零拷贝实现代码：

追溯 Kafka ⽂件传输的代码，会发现，最终它调⽤了 Java NIO 库⾥的 transferTo ⽅法：

```
@Overridepublic

long transferFrom(FileChannel fileChannel, long position, long count) throws

IOException {

 return fileChannel.transferTo(position, count, socketChannel);

}
```

如果 Linux 系统⽀持 sendfile() 系统调⽤，那么 transferTo() 实际上最后就会使⽤到 sendfile() 系统调

⽤函数。

曾经有⼤佬专⻔写过程序测试过，在同样的硬件条件下，传统⽂件传输和零拷拷⻉⽂件传输的性能差异，

你可以看到下⾯这张测试数据图，使⽤了零拷⻉能够缩短 65% 的时间，⼤幅度提升了机器传输数据的吞

吐量。

![image-20210627153422199](D:\Desktop\知识整理\图片\image-20210627153422199.png)



另外，Nginx 也⽀持零拷⻉技术，⼀般默认是开启零拷⻉技术，这样有利于提⾼⽂件传输的效率，是否开

启零拷⻉技术的配置如下：

```
http {
...
 sendfile on
...
}
```

你可以在你的 Linux 系统通过下⾯这个命令，查看⽹卡是否⽀持 scatter-gather 特性：

```
$ ethtool -k eth0 | grep scatter-gather
scatter-gather: on
```

sendfile 配置的具体意思:

* 设置为 on 表示，使⽤零拷⻉技术来传输⽂件：sendfile ，这样只需要 2 次上下⽂切换，和 2 次数据拷⻉。

* 设置为 off 表示，使⽤传统的⽂件传输技术：read + write，这时就需要 4 次上下⽂切换，和 4 次数据拷⻉。

在 nginx 中，我们可以⽤如下配置，来根据⽂件的⼤⼩来使⽤不同的⽅式：

```
location /video/ {
 sendfile on;
 aio on;
 directio 1024m;
}
```

当⽂件⼤⼩⼤于 

directio 值后，使⽤「异步 I/O + 直接 I/O」，否则使⽤「零拷⻉技术」。
