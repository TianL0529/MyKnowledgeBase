### **Redis**

**--Redis是什么？**
Redis是C语言开发的一个开源的（遵从BSD协议）高性能键值对（key-value）的内存数据库，可以用作数据库、缓存、消息中间件等。它是一种NoSQL（not-only sql，泛指非关系型数据库）的数据库。
Redis作为一个内存数据库的特点：
①、性能优秀，数据在内存中，读写速度非常快，支持并发10W QPS；
②、单进程单线程，是线程安全的，采用IO多路复用机制；
③、丰富的数据类型，支持字符串（string）、散列（hashes）、列表（lists）、集合（sets）、有序集合（sorted sets）等；
④、支持数据持久化。可以将内存中数据保存在磁盘中，重启时加载；
⑤、主从复制，哨兵，高可用；
⑥、可以用作分布式锁；
⑦、可以作为消息中间件使用，支持发布订阅。

### Redis为什么这么快？

#### Redis有多快？

我们可以先说到底有多快，根据官方数据，Redis 的 QPS 可以达到约 100000（每秒请求数），有兴趣的可以参考官方的基准程序测试《How fast is Redis？》，地址：https://redis.io/topics/benchmarks

![image-20210722164528423](D:\Desktop\知识整理\图片\image-20210722164528423.png)

横轴是连接数，纵轴是 QPS`（Queries Per Second）`。

#### 基于内存实现：

Redis 是基于内存的数据库，跟磁盘数据库相比，完全吊打磁盘的速度。

不论读写操作都是在内存上完成的，我们分别对比下内存操作与磁盘操作的差异。

**磁盘调用**

![image-20210722164537558](D:\Desktop\知识整理\图片\image-20210722164537558.png)

**内存操作**

内存直接由 CPU 控制，也就是 CPU 内部集成的内存控制器，所以说内存是直接与 CPU 对接，享受与 CPU 通信的最优带宽。

最后以一张图量化系统的各种延时时间（部分数据引用 Brendan Gregg）

![image-20210722164603784](D:\Desktop\知识整理\图片\image-20210722164603784.png)

#### 高效的数据结构

学习 MySQL 的时候我知道为了提高检索速度使用了 B+ Tree 数据结构，所以 Redis 速度快应该也跟数据结构有关。

Redis 一共有 5 种数据类型，`String、List、Hash、Set、SortedSet`。

不同的数据类型底层使用了一种或者多种数据结构来支撑，目的就是为了追求更快的速度。

> 码哥寄语：我们可以分别说明每种数据类型底层的数据结构优点，很多人只知道数据类型，而说出底层数据结构就能让人眼前一亮。

![image-20210722164747573](D:\Desktop\知识整理\图片\image-20210722164747573.png)

**SDS 简单动态字符串优势**

![image-20210722164822608](D:\Desktop\知识整理\图片\image-20210722164822608.png)

* SDS 中 len 保存这字符串的长度，O(1) 时间复杂度查询字符串长度信息。
* 空间预分配：SDS 被修改后，程序不仅会为 SDS 分配所需要的必须空间，还会分配额外的未使用空间。
* 惰性空间释放：当对 SDS 进行缩短操作时，程序并不会回收多余的内存空间，而是使用 free 字段将这些字节数量记录下来不释放，后面如果需要 append 操作，则直接使用 free 中未使用的空间，减少了内存的分配。

**zipList 压缩列表**

压缩列表是 List 、hash、 sorted Set 三种数据类型底层实现之一。

当一个列表只有少量数据的时候，并且每个列表项要么就是小整数值，要么就是长度比较短的字符串，那么 Redis 就会使用压缩列表来做列表键的底层实现。

![image-20210722164922453](D:\Desktop\知识整理\图片\image-20210722164922453.png)

这样内存紧凑，节约内存。

**quicklist**

后续版本对列表数据结构进行了改造，使用 quicklist 代替了 ziplist 和 linkedlist。

**quicklist 是 ziplist 和 linkedlist 的混合体，它将 linkedlist 按段切分，每一段使用 ziplist 来紧凑存储，多个 ziplist 之间使用双向指针串接起来。**

![image-20210722164956444](D:\Desktop\知识整理\图片\image-20210722164956444.png)

**skipList 跳跃表**

sorted set 类型的排序功能便是通过「跳跃列表」数据结构来实现。

跳跃表（skiplist）是一种有序数据结构，它通过在每个节点中维持多个指向其他节点的指针，从而达到快速访问节点的目的。

跳表在链表的基础上，增加了多层级索引，通过索引位置的几个跳转，实现数据的快速定位，如下图所示：

![image-20210722165014765](D:\Desktop\知识整理\图片\image-20210722165014765.png)

**整数数组（intset）**

当一个集合只包含整数值元素，并且这个集合的元素数量不多时，Redis 就会使用整数集合作为集合键的底层实现，节省内存。

#### 单线程模型

> 码哥寄语：我们需要注意的是，Redis 的单线程指的是 **Redis 的网络 IO （6.x 版本后网络 IO 使用多线程）以及键值对指令读写是由一个线程来执行的。** 对于 Redis 的持久化、集群数据同步、异步删除等都是其他线程执行。

千万别说 Redis 就只有一个线程。

**单线程指的是 Redis 键值对读写指令的执行是单线程。**

先说官方答案，让人觉得足够严谨，而不是人云亦云去背诵一些博客。

**官方答案：\**因为 Redis 是基于内存的操作，CPU 不是 Redis 的瓶颈，Redis 的瓶颈最\**有可能是机器内存的大小或者网络带宽**。既然单线程容易实现，而且 CPU 不会成为瓶颈，那就顺理成章地采用单线程的方案了。原文地址：https://redis.io/topics/faq。

**单线程好处？**

* 不会因为线程创建导致的性能消耗；
* 避免上下文切换引起的 CPU 消耗，没有多线程切换的开销；
* 避免了线程之间的竞争问题，比如添加锁、释放锁、死锁等，不需要考虑各种锁问题。
* 代码更清晰，处理逻辑简单。

#### I/O 多路复用模型

Redis 采用 I/O 多路复用技术，并发处理连接。采用了 epoll + 自己实现的简单的事件框架。

epoll 中的读、写、关闭、连接都转化成了事件，然后利用 epoll 的多路复用特性，绝不在 IO 上浪费一点时间。

![image-20210722165300783](D:\Desktop\知识整理\图片\image-20210722165300783.png)

Redis 线程不会阻塞在某一个特定的监听或已连接套接字上，也就是说，不会阻塞在某一个特定的客户端请求处理上。正因为此，Redis 可以同时和多个客户端连接并处理请求，从而提升并发性。





**--五种数据类型？**
Redis内部内存管理数据类型描述如下图：
![img](https://pic2.zhimg.com/80/v2-92afb6f1dd844e640fe40c242dede27d_720w.jpg)

首先redis内部使用一个redisObject对象来表示所有的key和value，redisObject最主要的信息如上图所示：type表示一个value对象具体是何种数据类型，encoding是不同数据类型在redis内部的存储方式。比如：type=string表示value存储的是一个普通字符串，那么encoding可以是raw或者int。
5种数据类型特点：
**1、**string是redis最基本的类型，可以理解成与memcached一模一样的类型，一个key对应一个value。value不仅是string，也可以是数字。string类型是二进制安全的，意思是redis的string类型可以包含任何数据，比如jpg图片或者序列化的对象。string类型的值最大能存储512M。
**2、**Hash是一个键值（key-value）的集合。redis的hash是一个string的key和value的映射表，Hash特别适合存储对象。常用命令：hget,hset,hgetall等。
**3、**list列表是简单的字符串列表，按照插入顺序排序。可以添加一个元素到列表的头部（左边）或者尾部（右边） 常用命令：lpush、rpush、lpop、rpop、lrange(获取列表片段)等。应用场景：list应用场景非常多，也是Redis最重要的数据结构之一，比如twitter的关注列表，粉丝列表都可以用list结构来实现。数据结构：list就是链表，可以用来当消息队列用。redis提供了List的push和pop操作，还提供了操作某一段的api，可以直接查询或者删除某一段的元素。实现方式：redis list的是实现是一个双向链表，既可以支持反向查找和遍历，更方便操作，不过带来了额外的内存开销。
**4、**set是string类型的无序集合。集合是通过hashtable实现的。set中的元素是没有顺序的，而且是没有重复的。常用命令：sdd、spop、smembers、sunion等。应用场景：redis set对外提供的功能和list一样是一个列表，特殊之处在于set是自动去重的，而且set提供了判断某个成员是否在一个set集合中。
**5、**zset和set一样是string类型元素的集合，且不允许重复的元素。常用命令：zadd、zrange、zrem、zcard等。使用场景：sorted set可以通过用户额外提供一个优先级（score）的参数来为成员排序，并且是插入有序的，即自动排序。当你需要一个有序的并且不重复的集合列表，那么可以选择sorted set结构。和set相比，sorted set关联了一个double类型权重的参数score，使得集合中的元素能够按照score进行有序排列，redis正是通过分数来为集合中的成员进行从小到大的排序。实现方式：Redis sorted set的内部使用HashMap和跳跃表(skipList)来保证数据的存储和有序，HashMap里放的是成员到score的映射，而跳跃表里存放的是所有的成员，排序依据是HashMap里存的score，使用跳跃表的结构可以获得比较高的查找效率，并且在实现上比较简单。
**数据类型应用场景总结如下图：**

![img](https://pic1.zhimg.com/80/v2-0b0e1d3eb01e47b3318318d49fb3de8c_720w.jpg)

**--Redis缓存**
**· **直接通过RedisTemplate来使用
**·** 使用spring cache集成Redis pom.xml中加入以下依赖：

```
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>
    <dependency>
        <groupId>org.apache.commons</groupId>
        <artifactId>commons-pool2</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.session</groupId>
        <artifactId>spring-session-data-redis</artifactId>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

- spring-boot-starter-data-redis:在spring boot 2.x以后底层不再使用Jedis，而是换成了Lettuce。

- commons-pool2：用作redis连接池，如不引入启动会报错

- spring-session-data-redis：spring session引入，用作共享session。配置文件application.yml的配置：

  ```yml
  server:
    port: 8082
    servlet:
      session:
        timeout: 30ms
  spring:
    cache:
      type: redis
    redis:
      host: 127.0.0.1
      port: 6379
      password:
      # redis默认情况下有16个分片，这里配置具体使用的分片，默认为0
      database: 0
      lettuce:
        pool:
          # 连接池最大连接数(使用负数表示没有限制),默认8
          max-active: 100
  ```

创建实体类User.java

```java
public class User implements Serializable{

    private static final long serialVersionUID = 662692455422902539L;

    private Integer id;

    private String name;

    private Integer age;

    public User() {
    }

    public User(Integer id, String name, Integer age) {
        this.id = id;
        this.name = name;
        this.age = age;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    @Override
    public String toString() {
        return "User{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
}
```

### **RedisTemplate的使用方式**

默认情况下的模板只能支持RedisTemplate<String, String>，也就是只能存入字符串，所以自定义模板很有必要。添加配置类RedisCacheConfig.java

```java
@Configuration
@AutoConfigureAfter(RedisAutoConfiguration.class)
public class RedisCacheConfig {

    @Bean
    public RedisTemplate<String, Serializable> redisCacheTemplate(LettuceConnectionFactory connectionFactory) {

        RedisTemplate<String, Serializable> template = new RedisTemplate<>();
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.setConnectionFactory(connectionFactory);
        return template;
    }
}
```

测试类

```java
@RestController
@RequestMapping("/user")
public class UserController {

    public static Logger logger = LogManager.getLogger(UserController.class);

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Autowired
    private RedisTemplate<String, Serializable> redisCacheTemplate;

    @RequestMapping("/test")
    public void test() {
        redisCacheTemplate.opsForValue().set("userkey", new User(1, "张三", 25));
        User user = (User) redisCacheTemplate.opsForValue().get("userkey");
        logger.info("当前获取对象：{}", user.toString());
    }
```

然后在浏览器访问，观察后台日志 http://localhost:8082/user/test
![img](https://pic4.zhimg.com/80/v2-391f19ea21521697a0443dc63a13a593_720w.jpg)

### **使用spring cache集成redis**

spring cache具备很好的灵活性，不仅能够使用SPEL(spring expression language)来定义缓存的key和各种condition，还提供了开箱即用的缓存临时存储方案，也支持和主流的专业缓存如EhCache、Redis、Guava的集成。定义接口UserService.java

```java
public interface UserService {

    User save(User user);

    void delete(int id);

    User get(Integer id);
}
```

接口实现类UserServiceImpl.java

```java
@Service
public class UserServiceImpl implements UserService{

    public static Logger logger = LogManager.getLogger(UserServiceImpl.class);

    private static Map<Integer, User> userMap = new HashMap<>();
    static {
        userMap.put(1, new User(1, "肖战", 25));
        userMap.put(2, new User(2, "王一博", 26));
        userMap.put(3, new User(3, "杨紫", 24));
    }


    @CachePut(value ="user", key = "#user.id")
    @Override
    public User save(User user) {
        userMap.put(user.getId(), user);
        logger.info("进入save方法，当前存储对象：{}", user.toString());
        return user;
    }

    @CacheEvict(value="user", key = "#id")
    @Override
    public void delete(int id) {
        userMap.remove(id);
        logger.info("进入delete方法，删除成功");
    }

    @Cacheable(value = "user", key = "#id")
    @Override
    public User get(Integer id) {
        logger.info("进入get方法，当前获取对象：{}", userMap.get(id)==null?null:userMap.get(id).toString());
        return userMap.get(id);
    }
}
```

为了方便演示数据库的操作，这里直接定义了一个Map<Integer,User> userMap，这里的核心是三个注解@Cachable、@CachePut和@CacheEvict。测试类：UserController

```java
@RestController
@RequestMapping("/user")
public class UserController {

    public static Logger logger = LogManager.getLogger(UserController.class);

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Autowired
    private RedisTemplate<String, Serializable> redisCacheTemplate;

    @Autowired
    private UserService userService;

    @RequestMapping("/test")
    public void test() {
        redisCacheTemplate.opsForValue().set("userkey", new User(1, "张三", 25));
        User user = (User) redisCacheTemplate.opsForValue().get("userkey");
        logger.info("当前获取对象：{}", user.toString());
    }


    @RequestMapping("/add")
    public void add() {
        User user = userService.save(new User(4, "李现", 30));
        logger.info("添加的用户信息：{}",user.toString());
    }

    @RequestMapping("/delete")
    public void delete() {
        userService.delete(4);
    }

    @RequestMapping("/get/{id}")
    public void get(@PathVariable("id") String idStr) throws Exception{
        if (StringUtils.isBlank(idStr)) {
            throw new Exception("id为空");
        }
        Integer id = Integer.parseInt(idStr);
        User user = userService.get(id);
        logger.info("获取的用户信息：{}",user.toString());
    }
}
```

用缓存要注意，启动类要加上一个注解开启缓存

```java
@SpringBootApplication(exclude=DataSourceAutoConfiguration.class)
@EnableCaching
public class Application {

  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }

}
```

1、先调用添加接口：http://localhost:8082/user/add

![img](https://pic3.zhimg.com/80/v2-db2c0ea967c884aa99b2aa29d1db5fce_720w.jpg)

2、再调用查询接口，查询id=4的用户信息：

![img](https://pic3.zhimg.com/80/v2-334b4a5282f033f1f4c716d058626f16_720w.jpg)

可以看出，这里已经从缓存中获取数据了，因为上一步add方法已经把id=4的用户数据放入了redis缓存 3、调用删除方法，删除id=4的用户信息，同时清除缓存

![img](https://pic4.zhimg.com/80/v2-79143e1b8bad6e4639f7143756d2090f_720w.jpg)

4、再次调用查询接口，查询id=4的用户信息：

![img](https://pic3.zhimg.com/80/v2-851ff6ae51bacc644fc7f56646e1364a_720w.jpg)

没有了缓存，所以进入了get方法，从userMap中获取。

**缓存注解**
1、@Cacheable 根据方法的请求参数对其结果进行缓存

- key：缓存的key，可以为空，如果指定要按照SPEL表达式编写，如果不指定，则按照方法的所有参数进行组合。
- value：缓存的名称，必须指定至少一个（如 @Cacheable (value='user')或者@Cacheable(value={'user1','user2'})）
- condition：缓存的条件，可以为空，使用SPEL编写，返回true或者false，只有为true才进行缓存。

2、@CachePut 根据方法的请求参数对其结果进行缓存，和@Cacheable不同的是，它每次都会触发真实方法的调用。参数描述见上。3、@CacheEvict 根据条件对缓存进行清空

- key：同上

- value：同上

- condition：同上

- allEntries：是否清空所有缓存内容，缺省为false，如果指定为true，则方法调用后将立即清空所有缓存

- beforeInvocation：是否在方法执行前就清空，缺省为false，如果指定为true，则在方法还没有执行的时候就清空缓存。缺省情况下，如果方法执行抛出异常，则不会清空缓存。

  **缓存问题**
  --在实际项目中使用缓存有遇到什么问题或者会遇到什么问题你知道吗？
  缓存和数据库数据一致性问题：分布式环境下非常容易出现缓存和数据库间数据一致性问题，针对这一点，如果项目对缓存的要求是强一致性的，那么就不要使用缓存。我们只能采取合适的策略来降低缓存和数据库间数据不一致的概率，而无法保证两者间的强一致性。合适的策略包括合适的缓存更新策略，更新数据库后及时更新缓存、缓存失败时增加重试机制。

  --Redis雪崩？
  目前电商首页以及热点数据都会做缓存，一般缓存都是定时任务去刷新，或者查不到之后去更新缓存，定时任务刷新就有一个问题。举个例子：如果首页所有Key的失效时间都是12小时，中午12点刷新，我零点有个大促活动大量用户涌入，假设每秒6000个请求，本来缓存可以抗住每秒5000个请求，但是缓存中所有key都失效了。此时6000个/秒的请求全部落在了数据库上，数据库必然扛不住，真实情况可能DBA都没反应过来直接挂了，此时，如果没什么特别的方案来处理，DBA很着急，重启数据库，但是数据库立马又被新流量给打死了。这就是我理解的缓存雪崩。同一时间大面积失效，瞬间Redis跟没有一样，那这个数量级别的请求直接打到数据库几乎是灾难性的，你想想如果挂的是一个用户服务的库，那其他依赖他的库所有接口几乎都会报错，如果没做熔断等策略基本上就是瞬间挂一片的节奏，你怎么重启用户都会把你打挂，等你重启好的时候，用户早睡觉去了，临睡之前，骂骂咧咧“什么垃圾产品”。

  --如何应对？
  处理缓存雪崩简单，在批量往Redis存数据的时候，把每个Key的失效时间都加个随机值就好了，这样可以保证数据不会再同一时间大面积失效。

  ```
  setRedis（key, value, time+Math.random()*10000）;
  ```

  如果Redis是集群部署，将热点数据均匀分布在不同的Redis库中也能避免全部失效。或者设置热点数据永不过期，有更新操作就更新缓存就好了（比如运维更新了首页商品，那你刷下缓存就好了，不要设置过期时间），电商首页的数据也可以用这个操作，保险。

  --说说缓存**穿透**和**击穿**与**雪崩**的区别？
  缓存穿透是指缓存和数据库中都没有的数据，而用户（黑客）不断发起请求，举个栗子：我们数据库的id都是从1自增的，如果发起id=-1的数据或者id特别大不存在的数据，这样的不断攻击导致数据库压力很大，严重会击垮数据库。
  至于缓存击穿嘛，这个跟缓存雪崩有点像，但是又有一点不一样，缓存雪崩是因为大面积的缓存失效，打崩了DB，而缓存击穿不同的是缓存击穿是指一个Key非常热点，在不停地扛着大量的请求，大并发集中对这一个点进行访问，当这个Key在失效的瞬间，持续的大并发直接落到了数据库上，就在这个Key的点上击穿了缓存。

  --分别怎么解决？
  缓存穿透我会在接口层增加校验，比如用户鉴权，参数做校验，不合法的校验直接return，比如id做基础校验，id<=0直接拦截。
  Redis里还有一个高级用法**布隆过滤器（Bloom Filter）**这个也能很好的预防缓存穿透的发生，他的原理也很简单，就是利用高效的数据结构和算法快速判断出你这个Key是否在数据库中存在，不存在你return就好了，存在你就去查DB刷新KV再return。缓存击穿的话，设置热点数据永不过期，或者加上互斥锁就搞定了。代码如下：

  ```java
  public static String getData(String key) throws InterruptedException {
          //从Redis查询数据
          String result = getDataByKV(key);
          //参数校验
          if (StringUtils.isBlank(result)) {
              try {
                  //获得锁
                  if (reenLock.tryLock()) {
                      //去数据库查询
                      result = getDataByDB(key);
                      //校验
                      if (StringUtils.isNotBlank(result)) {
                          //插进缓存
                          setDataToKV(key, result);
                      }
                  } else {
                      //睡一会再拿
                      Thread.sleep(100L);
                      result = getData(key);
                  }
              } finally {
                  //释放锁
                  reenLock.unlock();
              }
          }
          return result;
      }
  ```

--Redis为何这么快？
官方提供的数据可以达到100000+的QPS（每秒内的查询次数），这个数据不比Memcached差！
--redis这么快，它的“多线程模型”你了解吗？
Redis确实是单进程单线程的模型，因为Redis完全是基于内存的操作，CPU不是Redis的瓶颈，Redis的瓶颈最有可能是机器内存的大小或者网络带宽。既然单线程容易实现，而且CPU不会成为瓶颈，那就顺理成章的采用单线程的方案了（毕竟采用多线程会有很多麻烦）。
--Redis是单线程的，为什么还能这么快？
第一：Redis完全基于内存，绝大部分请求是纯粹的内存操作，非常迅速，数据存在内存中，类似于HashMap，HashMap的优势就是查找和操作的时间复杂度是O(1)。第二：数据结构简单，对数据操作也简单。第三：采用单线程，避免了不必要的上下文切换和竞争条件，不存在多线程导致的CPU切换，不用去考虑各种锁的问题，不存在加锁释放锁操作，没有死锁问题导致的性能消耗。第四：使用多路复用IO模型，非阻塞IO。

## **Redis和Memcached的区别**

- 面试官：嗯嗯，说的很详细。那你为什么选择Redis的缓存方案而不用memcached呢

- 我：

- - 1、存储方式上：memcache会把数据全部存在内存之中，断电后会挂掉，数据不能超过内存大小。redis有部分数据存在硬盘上，这样能保证数据的持久性。
  - 2、数据支持类型上：memcache对数据类型的支持简单，只支持简单的key-value，，而redis支持五种数据类型。
  - 3、使用底层模型不同：它们之间底层实现方式以及与客户端之间通信的应用协议不一样。redis直接自己构建了VM机制，因为一般的系统调用系统函数的话，会浪费一定的时间去移动和请求。
  - 4、value的大小：redis可以达到1GB，而memcache只有1MB。

## **淘汰策略**

- 面试官：那你说说你知道的redis的淘汰策略有哪些？
- 我：Redis有八种淘汰策略

| 策略            | 描述                                                         |
| --------------- | ------------------------------------------------------------ |
| volatile-LRU    | 从已设置过期时间的KV集中优先对**最近最少使用**（less recently used）的数据淘汰 |
| volitile-ttl    | 从已设置过期时间的KV集中优先对剩余时间短（time to live）的数据淘汰 |
| volitile-random | 从已设置过期时间的KV集中随机选择数据淘汰                     |
| volatile-LFU    | 从已设置过期时间的KV集中优先对最不经常使用（Least Frequently Used）的数据淘汰 |
| allkeys-LRU     | 从所有KV集中优先对最近最少使用（less recently used）的数据淘汰 |
| allkeys-random  | 从所有KV集中随机选择数据淘汰                                 |
| noeviction      | 不淘汰策略，若超过最大内存，返回错误信息                     |
| allkeys-LFU     | 从所有KV集中预先对最不经常使用（Least Frequently Used）的数据淘汰 |



补充一下：Redis4.0加入了LFU(least frequency use)淘汰策略，包括volatile-lfu和allkeys-lfu，通过统计访问频率，将访问频率最少，即最不经常使用的KV淘汰。

## **持久化**

- 面试官：你对redis的持久化机制了解吗？能讲一下吗？
- 我：redis为了保证效率，数据缓存在了内存中，但是会周期性的把更新的数据写入磁盘或者把修改操作写入追加的记录文件中，以保证数据的持久化。Redis的持久化策略有两种：1、RDB：快照形式是直接把内存中的数据保存到一个dump的文件中，定时保存，保存策略。2、AOF：把所有的对Redis的服务器进行修改的命令都存到一个文件里，命令的集合。Redis默认是快照RDB的持久化方式。当Redis重启的时候，它会优先使用AOF文件来还原数据集，因为AOF文件保存的数据集通常比RDB文件所保存的数据集更完整。你甚至可以关闭持久化功能，让数据只在服务器运行时存。
- 面试官：那你再说下RDB是怎么工作的？
- 我：默认Redis是会以快照"RDB"的形式将数据持久化到磁盘的一个二进制文件dump.rdb。工作原理简单说一下：当Redis需要做持久化时，Redis会fork一个子进程，子进程将数据写到磁盘上一个临时RDB文件中。当子进程完成写临时文件后，将原来的RDB替换掉，这样的好处是可以copy-on-write。
- 我：RDB的优点是：这种文件非常适合用于备份：比如，你可以在最近的24小时内，每小时备份一次，并且在每个月的每一天也备份一个RDB文件。这样的话，即使遇上问题，也可以随时将数据集还原到不同的版本。RDB非常适合灾难恢复。RDB的缺点是：如果你需要尽量避免在服务器故障时丢失数据，那么RDB不合适你。
- 面试官：那你要不再说下AOF？？
- 我：（说就一起说下吧）使用AOF做持久化，每一个写命令都通过write函数追加到appendonly.aof中，配置方式如下

```text
appendfsync yes
appendfsync always #每次有数据修改发生时都会写入AOF文件。
appendfsync everysec #每秒钟同步一次，该策略为AOF的缺省策略。
```

AOF可以做到全程持久化，只需要在配置中开启 appendonly yes。这样redis每执行一个修改数据的命令，都会把它添加到AOF文件中，当redis重启时，将会读取AOF文件进行重放，恢复到redis关闭前的最后时刻。

- 我顿了一下，继续说：使用AOF的优点是会让redis变得非常耐久。可以设置不同的fsync策略，aof的默认策略是每秒钟fsync一次，在这种配置下，就算发生故障停机，也最多丢失一秒钟的数据。缺点是对于相同的数据集来说，AOF的文件体积通常要大于RDB文件的体积。根据所使用的fsync策略，AOF的速度可能会慢于RDB。
- 面试官又问：你说了这么多，那我该用哪一个呢？
- 我：如果你非常关心你的数据，但仍然可以承受数分钟内的数据丢失，那么可以额只使用RDB持久。AOF将Redis执行的每一条命令追加到磁盘中，处理巨大的写入会降低Redis的性能，不知道你是否可以接受。数据库备份和灾难恢复：定时生成RDB快照非常便于进行数据库备份，并且RDB恢复数据集的速度也要比AOF恢复的速度快。当然了，redis支持同时开启RDB和AOF，系统重启后，redis会优先使用AOF来恢复数据，这样丢失的数据会最少。

## **主从复制**

- 面试官：redis单节点存在单点故障问题，为了解决单点问题，一般都需要对redis配置从节点，然后使用哨兵来监听主节点的存活状态，如果主节点挂掉，从节点能继续提供缓存功能，你能说说redis主从复制的过程和原理吗？
- 我有点懵，这个说来就话长了。但幸好提前准备了：主从配置结合哨兵模式能解决单点故障问题，提高redis可用性。从节点仅提供读操作，主节点提供写操作。对于读多写少的状况，可给主节点配置多个从节点，从而提高响应效率。
- 我顿了一下，接着说：关于复制过程，是这样的：1、从节点执行slaveof[masterIP][masterPort]，保存主节点信息 2、从节点中的定时任务发现主节点信息，建立和主节点的socket连接 3、从节点发送Ping信号，主节点返回Pong，两边能互相通信 4、连接建立后，主节点将所有数据发送给从节点（数据同步） 5、主节点把当前的数据同步给从节点后，便完成了复制的建立过程。接下来，主节点就会持续的把写命令发送给从节点，保证主从数据一致性。
- 面试官：那你能详细说下数据同步的过程吗？
- （我心想：这也问的太细了吧）我：可以。redis2.8之前使用sync[runId][offset]同步命令，redis2.8之后使用psync[runId][offset]命令。两者不同在于，sync命令仅支持全量复制过程，psync支持全量和部分复制。介绍同步之前，先介绍几个概念：runId：每个redis节点启动都会生成唯一的uuid，每次redis重启后，runId都会发生变化。offset：主节点和从节点都各自维护自己的主从复制偏移量offset，当主节点有写入命令时，offset=offset+命令的字节长度。从节点在收到主节点发送的命令后，也会增加自己的offset，并把自己的offset发送给主节点。这样，主节点同时保存自己的offset和从节点的offset，通过对比offset来判断主从节点数据是否一致。repl_backlog_size：保存在主节点上的一个固定长度的先进先出队列，默认大小是1MB。（1）主节点发送数据给从节点过程中，主节点还会进行一些写操作，这时候的数据存储在复制缓冲区中。从节点同步主节点数据完成后，主节点将缓冲区的数据继续发送给从节点，用于部分复制。（2）主节点响应写命令时，不但会把命名发送给从节点，还会写入复制积压缓冲区，用于复制命令丢失的数据补救。

![img](https://pic2.zhimg.com/80/v2-f6f5f0b7d08130b90474c3d11896ea91_720w.jpg)

上面是psync的执行流程：从节点发送psync[runId][offset]命令，主节点有三种响应：（1）FULLRESYNC：第一次连接，进行全量复制 （2）CONTINUE：进行部分复制 （3）ERR：不支持psync命令，进行全量复制

- 面试官：很好，那你能具体说下全量复制和部分复制的过程吗？
- 我：可以

![img](https://pic1.zhimg.com/80/v2-f559fae949480b58c76e7889fc3bff34_720w.jpg)

关于部分复制有以下几点说明：1、部分复制主要是Redis针对全量复制的过高开销做出的一种优化措施，使用psync[runId][offset]命令实现。当从节点正在复制主节点时，如果出现网络闪断或者命令丢失等异常情况时，从节点会向主节点要求补发丢失的命令数据，主节点的复制积压缓冲区将这部分数据直接发送给从节点，这样就可以保持主从节点复制的一致性。补发的这部分数据一般远远小于全量数据。2、主从连接中断期间主节点依然响应命令，但因复制连接中断命令无法发送给从节点，不过主节点内的复制积压缓冲区依然可以保存最近一段时间的写命令数据。3、当主从连接恢复后，由于从节点之前保存了自身已复制的偏移量和主节点的运行ID。因此会把它们当做psync参数发送给主节点，要求进行部分复制。4、主节点接收到psync命令后首先核对参数runId是否与自身一致，如果一致，说明之前复制的是当前主节点；之后根据参数offset在复制积压缓冲区中查找，如果offset之后的数据存在，则对从节点发送+COUTINUE命令，表示可以进行部分复制。因为缓冲区大小固定，若发生缓冲溢出，则进行全量复制。5、主节点根据偏移量把复制积压缓冲区里的数据发送给从节点，保证主从复制进入正常状态。

上面是全量复制的流程。主要有以下几步：

1、从节点发送psync ? -1命令（因为第一次发送，不知道主节点的runId，所以为?，因为是第一次复制，所以offset=-1）。

2、主节点发现从节点是第一次复制，返回FULLRESYNC {runId} {offset}，runId是主节点的runId，offset是主节点目前的offset。

3、从节点接收主节点信息后，保存到info中。

4、主节点在发送FULLRESYNC后，启动bgsave命令，生成RDB文件（数据持久化）。

5、主节点发送RDB文件给从节点。到从节点加载数据完成这段期间主节点的写命令放入缓冲区。

6、从节点清理自己的数据库数据。

7、从节点加载RDB文件，将数据保存到自己的数据库中。

8、如果从节点开启了AOF，从节点会异步重写AOF文件。

关于部分复制有以下几点说明：

1、部分复制主要是Redis针对全量复制的过高开销做出的一种优化措施，使用psync[runId][offset]命令实现。当从节点正在复制主节点时，如果出现网络闪断或者命令丢失等异常情况时，从节点会向主节点要求补发丢失的命令数据，主节点的复制积压缓冲区将这部分数据直接发送给从节点，这样就可以保持主从节点复制的一致性。补发的这部分数据一般远远小于全量数据。

2、主从连接中断期间主节点依然响应命令，但因复制连接中断命令无法发送给从节点，不过主节点内的复制积压缓冲区依然可以保存最近一段时间的写命令数据。

3、当主从连接恢复后，由于从节点之前保存了自身已复制的偏移量和主节点的运行ID。因此会把它们当做psync参数发送给主节点，要求进行部分复制。

4、主节点接收到psync命令后首先核对参数runId是否与自身一致，如果一致，说明之前复制的是当前主节点；之后根据参数offset在复制积压缓冲区中查找，如果offset之后的数据存在，则对从节点发送+COUTINUE命令，表示可以进行部分复制。因为缓冲区大小固定，若发生缓冲溢出，则进行全量复制。

5、主节点根据偏移量把复制积压缓冲区里的数据发送给从节点，保证主从复制进入正常状态。

## **哨兵**

面试官：那主从复制会存在哪些问题呢？

我：主从复制会存在以下问题：

1、一旦主节点宕机，从节点晋升为主节点，同时需要修改应用方的主节点地址，还需要命令所有从节点去复制新的主节点，整个过程需要人工干预。

2、主节点的写能力受到单机的限制。

3、主节点的存储能力受到单机的限制。

4、原生复制的弊端在早期的版本中也会比较突出，比如：redis复制中断后，从节点会发起psync。此时如果同步不成功，则会进行全量同步，主库执行全量备份的同时，可能会造成毫秒或秒级的卡顿。

面试官：那比较主流的解决方案是什么呢？

我：当然是哨兵啊。

面试官：那么问题又来了。那你说下哨兵有哪些功能？

![img](https://pic3.zhimg.com/80/v2-2d731a5fdc71a1635874ad3dd2854bc6_720w.jpg)

我：如图，是Redis Sentinel（哨兵）的架构图。Redis Sentinel（哨兵）主要功能包括主节点存活检测、主从运行情况检测、自动故障转移、主从切换。Redis Sentinel最小配置是一主一从。Redis的Sentinel系统可以用来管理多个Redis服务器，该系统可以执行以下四个任务：

1、监控：不断检查主服务器和从服务器是否正常运行。

2、通知：当被监控的某个redis服务器出现问题，Sentinel通过API脚本向管理员或者其他应用程序发出通知。

3、自动故障转移：当主节点不能正常工作时，Sentinel会开始一次自动的故障转移操作，它会将与失效主节点是主从关系的其中一个从节点升级为新的主节点，并且将其他的从节点指向新的主节点，这样人工干预就可以免了。

4、配置提供者：在Redis Sentinel模式下，客户端应用在初始化时连接的是Sentinel节点集合，从中获取主节点的信息。

面试官：那你能说下哨兵的工作原理吗？

我：话不多说，直接上图：

![img](https://pic2.zhimg.com/80/v2-27238c7f56309849b513e472e22763f1_720w.jpg)

1、每个Sentinel节点都需要定期执行以下任务：每个Sentinel以每秒一次的频率，向它所知的主服务器、从服务器以及其他的Sentinel实例发送一个PING命令。（如上图）

![img](https://pic2.zhimg.com/80/v2-bd313c0d82f3f443fbb76f4a6b79b01d_720w.jpg)

2、如果一个实例距离最后一次有效回复PING命令的时间超过down-after-milliseconds所指定的值，那么这个实例会被Sentinel标记为主观下线。（如上图）

![img](https://pic4.zhimg.com/80/v2-ec7daa270344165262587acacccd763f_720w.jpg)

3、如果一个主服务器被标记为主观下线，那么正在监视这个服务器的所有Sentinel节点，要以每秒一次的频率确认主服务器的确进入了主观下线状态。

![img](https://pic1.zhimg.com/80/v2-cffa464dd2cafcec1d2ff9f532390710_720w.jpg)

4、如果一个主服务器被标记为主观下线，并且有足够数量的Sentinel（至少要达到配置文件指定的数量）在指定的时间范围内同意这一判断，那么这个主服务器被标记为客观下线。

![img](https://pic2.zhimg.com/80/v2-f78c557e12068ee8ecb9c2d70c50bdfd_720w.jpg)

5、一般情况下，每个Sentinel会以每10秒一次的频率向它已知的所有主服务器和从服务器发送INFO命令，当一个主服务器被标记为客观下线时，Sentinel向下线主服务器的所有从服务器发送INFO命令的频率，会从10秒一次改为每秒一次。

![img](https://pic1.zhimg.com/80/v2-bac6f4f963257e3b11f4d84f52913b64_720w.jpg)

6、Sentinel和其他Sentinel协商客观下线的主节点的状态，如果处于SDOWN状态，则投票自动选出新的主节点，将剩余从节点指向新的主节点进行数据复制。

![img](https://pic2.zhimg.com/80/v2-47115f7018c3146f5074481d83e4425d_720w.jpg)

7、当没有足够数量的Sentinel同意主服务器下线时，主服务器的客观下线状态就会被移除。当主服务器重新向Sentinel的PING命令返回有效回复时，主服务器的主观下线状态就会被移除。

## Cluster 集群

#### 除了哨兵以外，还有其他的高可用手段么？

有 Cluster 集群实现高可用，哨兵集群监控的 Redis 集群是主从架构，无法横向拓展。**使用 Redis Cluster 集群，主要解决了大数据量存储导致的各种慢问题，同时也便于横向拓展。**

**在面向百万、千万级别的用户规模时，横向扩展的 Redis 切片集群会是一个非常好的选择。**

#### 什么是 Cluster 集群？

Redis 集群是一种分布式数据库方案，集群通过分片（sharding）来进行数据管理（「分治思想」的一种实践），并提供复制和故障转移功能。

将数据划分为 16384 的 slots，每个节点负责一部分槽位。槽位的信息存储于每个节点中。

它是去中心化的，如图所示，该集群由三个 Redis 节点组成，每个节点负责整个集群的一部分数据，每个节点负责的数据多少可能不一样。

![image-20210722180834695](D:\Desktop\知识整理\图片\image-20210722180834695.png)

三个节点相互连接组成一个对等的集群，它们之间通过 `Gossip`协议相互交互集群信息，最后每个节点都保存着其他节点的 slots 分配情况。

#### 哈希槽又是如何映射到 Redis 实例上呢？

1. 根据键值对的 key，使用 CRC16 算法，计算出一个 16 bit 的值；
2. 将 16 bit 的值对 16384 执行取模，得到 0 ～ 16383 的数表示 key 对应的哈希槽。
3. 根据该槽信息定位到对应的实例。

键值对数据、哈希槽、Redis 实例之间的映射关系如下：

![image-20210722181011974](D:\Desktop\知识整理\图片\image-20210722181011974.png)



#### Cluster 如何实现故障转移？

Redis 集群节点采用 `Gossip` 协议来广播自己的状态以及自己对整个集群认知的改变。比如一个节点发现某个节点失联了 (PFail)，它会将这条信息向整个集群广播，其它节点也就可以收到这点失联信息。

如果一个节点收到了某个节点失联的数量 (PFail Count) 已经达到了集群的大多数，就可以标记该节点为确定下线状态 (Fail)，然后向整个集群广播，强迫其它节点也接收该节点已经下线的事实，并立即对该失联节点进行主从切换。

#### 客户端又怎么确定访问的数据分布在哪个实例上呢？

Redis 实例会将自己的哈希槽信息通过 Gossip 协议发送给集群中其他的实例，实现了哈希槽分配信息的扩散。

这样，集群中的每个实例都有所有哈希槽与实例之间的映射关系信息。

当客户端连接任何一个实例，实例就将哈希槽与实例的映射关系响应给客户端，客户端就会将哈希槽与实例映射信息缓存在本地。

当客户端请求时，会计算出键所对应的哈希槽，再通过本地缓存的哈希槽实例映射信息定位到数据所在实例上，再将请求发送给对应的实例。

![image-20210722181246557](D:\Desktop\知识整理\图片\image-20210722181246557.png)

#### 什么是 Redis 重定向机制？

哈希槽与实例之间的映射关系由于新增实例或者负载均衡重新分配导致改变了，**客户端将请求发送到实例上，这个实例没有相应的数据，该 Redis 实例会告诉客户端将请求发送到其他的实例上**。

Redis 通过 MOVED 错误和 ASK 错误告诉客户端。

### MOVED

**MOVED** 错误（负载均衡，数据已经迁移到其他实例上）：当客户端将一个键值对操作请求发送给某个实例，而这个键所在的槽并非由自己负责的时候，该实例会返回一个 MOVED 错误指引转向正在负责该槽的节点。

同时，**客户端还会更新本地缓存，将该 slot 与 Redis 实例对应关系更新正确**。

![image-20210722181403581](D:\Desktop\知识整理\图片\image-20210722181403581.png)

### ASK

如果某个 slot 的数据比较多，部分迁移到新实例，还有一部分没有迁移。

如果请求的 key 在当前节点找到就直接执行命令，否则时候就需要 ASK 错误响应了。

槽部分迁移未完成的情况下，如果需要访问的 key 所在 Slot 正在从 实例 1 迁移到 实例 2（如果 key 已经不在实例 1），实例 1 会返回客户端一条 ASK 报错信息：**客户端请求的 key 所在的哈希槽正在迁移到实例 2 上，你先给实例 2 发送一个 ASKING 命令，接着发发送操作命令**。

比如客户端请求定位到 key = 「公众号:码哥字节」的槽 16330 在实例 172.17.18.1 上，节点 1 如果找得到就直接执行命令，否则响应 ASK 错误信息，并指引客户端转向正在迁移的目标节点 172.17.18.2。

![image-20210722181422060](D:\Desktop\知识整理\图片\image-20210722181422060.png)

注意：**ASK 错误指令并不会更新客户端缓存的哈希槽分配信息**。
