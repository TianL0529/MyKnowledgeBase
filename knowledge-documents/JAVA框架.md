### 框架

框架：框架是整个或部分系统的可重用设计，表现为一组抽象构建实例间交互的方法；解决技术整合的问题，软件企业的研发将集中在应用的设计上，而不是具体的技术实现，技术实现是应用的底层支撑，它不应该直接对应用产生影响。

#### 一、持久层框架-MyBatis

​		内部封装了jdbc，使开发者只需要关注sql语句本身，而不需要花费精力处理加载驱动、创建链接、创建statement等繁杂的过程。

​		mybatis 通过 xml 或注解的方式将要执行的各种 statement 配置起来，并通过 java 对象和 statement 中sql 的动态参数进行映射生成最终执行的 sql 语句，最后由 mybatis 框架执行 sql 并将结果映射为 java 对象并返回。

​		采用 ORM（Object Relational Mapping 对象关系映射） 思想解决了实体和数据库映射的问题，对 jdbc 进行了封装，屏蔽了 jdbc api 底层访问细节，使我们不用与 jdbc api 打交道，就可以完成对数据库的持久化操作。

**测试方法：**

```
//1.读取配置文件
InputStream in = Resources.getResourceAsStream("SqlMapConfig.xml");
//2.创建 SqlSessionFactory 的构建者对象
SqlSessionFactoryBuilder builder = **new** SqlSessionFactoryBuilder();
//3.使用构建者创建工厂对象 SqlSessionFactory
SqlSessionFactory factory = builder.build(in);
//4.使用 SqlSessionFactory 生产 SqlSession 对象
SqlSession session = factory.openSession();
//5.使用 SqlSession 创建 dao 接口的代理对象
IUserDao userDao = session.getMapper(IUserDao.**class**);
//6.使用代理对象执行查询所有方法
List<User> users = userDao.findAll();
for(User user : users) {
System.out.println(user);
}
//7.释放资源
session.close();
in.close();
```

**图解：**

![自定义mybatis开发流程图](D:\Desktop\我的电脑\JAVA\05-Mybatis\02-第二天\截图\自定义mybatis开发流程图.png)

**标签配置：**

```
-properties（属性）

--property

-settings（全局配置参数）

--setting

-typeAliases（类型别名）

--typeAliase

--package

-typeHandlers（类型处理器）

-objectFactory（对象工厂）

-plugins（插件）

-environments（环境集合属性对象）

--environment（环境子属性对象）

---transactionManager（事务管理）

---dataSource（数据源）

-mappers（映射器）

--mapper

--package
```

**延迟加载**：

就是在需要用到数据时才进行加载，不需要用到数据时就不加载数据。延迟加载也称懒加载.
**好处：**先从单表查询，需要时再从关联表去关联查询，大大提高数据库性能，因为查询单表要比关联查询多张表速度要快。

**坏处：**

因为只有当需要用到数据时，才会进行数据库查询，这样在大批量数据查询时，因为查询工作也要消耗时间，所以可能造成用户等待时间变长，造成用户体验下降。

#### 二、Spring

##### **Spring的优势：**

###### 方便解耦，简化开发

通过Spring提供的IOC容器，可以将对象间的依赖关系交由Spring进行控制，避免硬编码所造成的过度程序耦合。用户也不必再为单例模式类、属性文件解析等这些很底层的需求编码代码，可以更专注于上层的应用。

###### AOP变成的支持

通过Spring的AOP功能，方便进行面向切面的编程，许多不容易用传统OOP实现的功能可以通过AOP轻松应付

###### 声明式事务的支持

可以将我们从单调烦闷的事务管理代码中解脱出来，通过声明式灵活的进行事务的管理，提高开发效率和质量

###### 方便程序的测试

可以用非容器依赖的编程方式进行几乎所用的测试工作，测试不再是昂贵的操作，而是随手可做的事情。

###### **方便集成各种优秀框架**

Spring 可以降低各种框架的使用难度，提供了对各种优秀框架（Struts、Hibernate、Hessian、Quartz等）的直接支持。

###### **降低** **JavaEE API** **的使用难度**

Spring 对 JavaEE API（如 JDBC、JavaMail、远程调用等）进行了薄薄的封装层，使这些 API 的使用难度大为降低。

###### **Java** **源码是经典学习范例**

Spring 的源代码设计精妙、结构清晰、匠心独用，处处体现着大师对 Java 设计模式灵活运用以及对 Java 技术的高深造诣。它的源代码无意是 Java 技术的最佳实践的范例。







#### 四、SpringBoot

##### SpringBoot的特点

- 为基于Spring的开发提供更快的入门体验
- 开箱即用，没有代码生成，也无需XML配置。同时也可以修改默认值来满足特定的需求
- 提供了一些大型项目中常见的非功能性特性，如嵌入式服务器、安全、指标，健康检测、外部配置等
- SpringBoot不是对Spring功能上的增强，而是提供了一种快速使用Spring的方式

##### SpringBoot的核心功能

- 起步依赖

  起步依赖本质上是一个Maven项目对象模型（Project Object Model，POM），定义了对其他库的传递依赖，这些东西加在一起即支持某项功能。

  简单的说，起步依赖就是将具备某种功能的坐标打包到一起，并提供一些默认的功能。

- 自动配置

  Spring Boot的自动配置是一个运行时（更准确地说，是应用程序启动时）的过程，考虑了众多因素，才决定Spring配置应该用哪个，不该用哪个。该过程是Spring自动完成的。



#### 五、SpringCloud

微服务是一种架构方式，如：SpringCloud，Dubbo

Spring最擅长的就是继承，把世界上最好的框架拿过来，集成到自己的项目中。
SpringCloud也是将现在非常流行的一些技术整合到一起，实现了诸如：配置管理、服务发现、智能路由、负载均衡、熔断器、控制总线、集群状态等功能。其主要涉及的组件包括：

- Eureka：服务治理组件，包含服务注册中心，服务注册与发现机制的实现。（服务治理，服务注册/发现） 
- Zuul：网关组件，提供智能路由，访问过滤功能 
- Ribbon：客户端负载均衡的服务调用组件（客户端负载） 
- Feign：服务调用，给予Ribbon和Hystrix的声明式服务调用组件 （声明式服务调用） 
- Hystrix：容错管理组件，实现断路器模式，帮助服务依赖中出现的延迟和为故障提供强大的容错能力。(熔断、断路器，容错) 

![1525575656796](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day02-springcloud\笔记\assets\1525575656796.png)



##### 注测中心 Eureka

![1525597885059](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day02-springcloud\笔记\assets\1525597885059.png)

- Eureka：就是服务注册中心（可以是一个集群），对外暴露自己的地址
- 提供者：启动后向Eureka注册自己信息（地址，提供什么服务）
- 消费者：向Eureka订阅服务，Eureka会将对应服务的所有提供者地址列表发送给消费者，并且定期更新
- 心跳(续约)：提供者定期通过http方式向Eureka刷新自己的状态

##### 负载均衡Ribbon

![1525619257397](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day02-springcloud\笔记\assets\1525619257397.png)

##### Hystrix

Hystrix,英文意思是豪猪，全身是刺，看起来就不好惹，**是一种保护机制。**

![1525658740266](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1525658740266.png?lastModify=1623649449)

Hystix是Netflix开源的一个延迟和容错库，用于隔离访问远程服务、第三方库，防止出现级联失败。

###### 雪崩问题

微服务中，服务间调用关系错综复杂，一个请求，可能需要调用多个微服务接口才能实现，会形成非常复杂的调用链路：
![1533829099748](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1533829099748.png?lastModify=1623649511)

如图，一次业务请求，需要调用A、P、H、I四个服务，这四个服务又可能调用其它服务。

如果此时，某个服务出现异常：

 ![1533829198240](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day03-springcloud\笔记\assets\1533829198240.png)

例如微服务I发生异常，请求阻塞，用户不会得到响应，则tomcat的这个线程不会释放，于是越来越多的用户请求到来，越来越多的线程会阻塞：

 ![1533829307389](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day03-springcloud\笔记\assets\1533829307389.png)

服务器支持的线程和并发数有限，请求一直阻塞，会导致服务器资源耗尽，从而导致所有其它服务都不可用，形成雪崩效应。

这就好比，一个汽车生产线，生产不同的汽车，需要使用不同的零件，如果某个零件因为种种原因无法使用，那么就会造成整台车无法装配，陷入等待零件的状态，直到零件到位，才能继续组装。  此时如果有很多个车型都需要这个零件，那么整个工厂都将陷入等待的状态，导致所有生产都陷入瘫痪。一个零件的波及范围不断扩大。 

**Hystix解决雪崩问题的手段有两个：**

- **线程隔离**
- **服务熔断**

###### 线程隔离，服务降级

线程隔离示意图：

 ![1533829598310](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day03-springcloud\笔记\assets\1533829598310.png)

解读：

Hystrix为每个依赖服务调用分配一个小的线程池，如果线程池已满调用将被立即拒绝，默认不采用排队.加速失败判定时间。

用户的请求将不再直接访问服务，而是通过线程池中的空闲线程来访问服务，如果**线程池已满**，或者**请求超时**，则会进行降级处理，什么是服务降级？

> 服务降级：优先保证核心服务，而非核心服务不可用或弱可用。

用户的请求故障时，不会被阻塞，更不会无休止的等待或者看到系统崩溃，至少可以看到一个执行结果（例如返回友好的提示信息） 。

服务降级虽然会导致请求失败，但是不会导致阻塞，而且最多会影响这个依赖服务对应的线程池中的资源，对其它服务没有响应。

**触发Hystix服务降级的情况：**

- **线程池已满**
- **请求超时**

###### 服务熔断

熔断器，也叫断路器，其英文单词为：Circuit Breaker 

![1525658640314](D:\Desktop\我的电脑\JAVA\11-乐优商城\leyou\day03-springcloud\笔记\assets\1525658640314.png)

熔断状态机3个状态：

- Closed：关闭状态，所有请求都正常访问。
- Open：打开状态，所有请求都会被降级。Hystix会对请求情况计数，当一定时间内失败请求百分比达到阈值，则触发熔断，断路器会完全打开。默认失败比例的阈值是50%，请求次数最少不低于20次。
- Half Open：半开状态，open状态不是永久的，打开后会进入休眠时间（默认是5S）。随后断路器会自动进入半开状态。此时会释放部分请求通过，若这些请求都是健康的，则会完全关闭断路器，否则继续保持打开，再次进行休眠计时

#### Feign

在前面的学习中，我们使用了Ribbon的负载均衡功能，大大简化了远程调用时的代码：

```java
String user = this.restTemplate.getForObject("http://service-provider/user/" + id, String.class);
```

如果就学到这里，你可能以后需要编写类似的大量重复代码，格式基本相同，无非参数不一样。有没有更优雅的方式，来对这些代码再次优化呢？

这就是我们接下来要学的Feign的功能了。

![1528855057359](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1528855057359.png?lastModify=1623650814)

为什么叫伪装？

Feign可以把Rest的请求进行隐藏，伪装成类似SpringMVC的Controller一样。你不用再自己拼接url，拼接参数等等操作，一切都交给Feign去做。

![1525652009416](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1525652009416.png?lastModify=1623650863)

#### Zuul网关

服务网关是微服务架构中一个不可或缺的部分。通过服务网关统一向外系统提供REST API的过程中，除了具备`服务路由`、`均衡负载`功能之外，它还具备了`权限控制`等功能。Spring Cloud Netflix中的Zuul就担任了这样的一个角色，为微服务架构提供了前门保护的作用，同时将权限控制这些较重的非业务逻辑内容迁移到服务路由层面，使得服务集群主体能够具备更高的可复用性和可测试性。

![1525675168152](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1525675168152.png?lastModify=1623656337)

###### Zuul加入前的架构

![1525674644660](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1525674644660.png?lastModify=1623656421)

Zuul加入后的架构

![1525675648881](file://D:\Desktop\%E6%88%91%E7%9A%84%E7%94%B5%E8%84%91\JAVA\11-%E4%B9%90%E4%BC%98%E5%95%86%E5%9F%8E\leyou\day03-springcloud\%E7%AC%94%E8%AE%B0\assets\1525675648881.png?lastModify=1623656430)

不管是来自于客户端（PC或移动端）的请求，还是服务内部调用。一切对服务的请求都会经过Zuul这个网关，然后再由网关来实现 鉴权、动态路由等等操作。Zuul就是我们服务的统一入口。













