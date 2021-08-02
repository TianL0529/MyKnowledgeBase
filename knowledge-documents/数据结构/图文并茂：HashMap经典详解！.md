### 图文并茂：HashMap经典详解！

------

基础知识：

![image-20210721173929736](D:\Desktop\知识整理\图片\image-20210721173929736.png)

为什么要使用hash表
hash结构是为了查询效率而诞生的，是使查询速度最快化的结构，时间复杂度为O(1)，真正达到了瞬间查找的目的。
（这个道理可能人人都懂，但是吧，你写的 HashMap 可能真的没法跟 jdk 源码里的 HashMap 比）

#### hash表如何达到高效的存储及查找效率

> 散列表（Hash table，也叫哈希表），是根据关键码值(Key value)而直接进行访问的数据结构。也就是说，它通过把关键码值映射到表中一个位置来访问记录，以加快查找的速度。这个映射函数叫做散列函数，存放记录的数组叫做散列表。给定表M，存在函数f(key)，对任意给定的关键字值key，代入函数后若能得到包含该关键字的记录在表中的地址，则称表M为哈希(Hash）表，函数f(key)为哈希(Hash) 函数。

就像这样：
有一堆 key，value 成双成对在一张表里的各个位置

![image-20210721154816108](D:\Desktop\知识整理\图片\image-20210721154816108.png)
比如我们要找 Mike，和他的老婆。就要先找到他的位置

```java
function(Mike.hashCode()) = 2
```

我们通过一个哈希函数计算出 Mike 的位置在2
然后到表中一看，就找到了 Mike 的老婆是 Therese

|    0     |  1   |    2    |    3     |  4   |  …   |  n   |
| :------: | :--: | :-----: | :------: | :--: | :--: | :--: |
|   Tony   | null |  Mike   | XiaoMing | null |  …   |  …   |
| XiaoHong | null | Therese |  Daria   | null |  …   |  …   |

存放键值对，删除也是同样的道理
只需要一个函数进行计算，就可以知道键值对在表中的位置。

#### HashMap中采用何种哈希函数

乍一看 HashMap 的源码似乎很复杂，然而实际上，哈希函数只是
**取余(取模)！！！**
就比如 7%5=2，4%3=1，8%4=0
虽然看起来源码好像不是这么写的，但实际上就是这个作用。

由于在计算机语言中，数字使用补码表示的，而对数值进行取模时，考虑到了效率，采用了位运算，没有将数字转换为原码再进行取模。
正数的原码与补码相同，因此取模结果也相同。
而负数补码与原码不同，取模是对补码进行的，所以会与传统取模结果不符。
（如果你还不会再日常代码中写位运算，那你可能就 out 了）

#### HashMap中对hashCode()值做了什么处理

* 众所周知，一个对象的 hashCode() 值可能是一串很长很大的数字，就是 int 数字。

* int 数字在二进制一共有32位，所以有2的32次方个取值。

* 而我们平时使用的 HashMap 中的数组容量可能很小，可能只有几十，因此我们取模时，只需要用到 hashCode() 值的最后几位，而前面高位数的数字特征就都被浪费掉了，由于少了一部分数字特征，所以出现数据集中的可能性会变大。

* 比如：
  10100010110100100101111111001000
  01010100101000100101111111001000
  101001011111010101101111111001000
  这些数字虽然整体差异大，但后很多位都没有差异，在平时只对小的数字取模，所以得到的位置都会相同，则会产生碰撞。

* 因此，HashMap 中用了一个方法，对对象的 hashCode() 值做了前后16位的值做异或操作。这样，得到的结果的后16位中也保留了前16位的特征，因此能获得更好的离散型程度。

  ```java
  static final int hash(Object key) {
      int h;
      return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
  }
  ```

* 我们再对上面第一个数字操作一下
  10100010110100100101111111001000 这是原数字
  00000000000000001010001011010010 这是右移16位的数字
  10100010110100101111110100011010 异或操作后的数字
  这样融合了前后16位的数字可以拥有更好地离散程度

* 这样在进行取模操作时，产生冲突碰撞的可能性就降低了。
  （据说 HashMap 用这个方法将碰撞概率降低了0.2）
  （同时也是防止程序猿写的 hashCode 太差劲了，于是再平均一下）

#### HashMap中是如何保证哈希函数计算地址高效的

* 前面提到了哈希函数是采用了取模运算
* 但是不是使用的 h%n 的方式
* 在 jdk 源码中，是使用了 h & (n - 1) 来计算出桶位置
* 有人可能要提出疑问了，这明显不是取模操作。
* 这个问题先放一边，我们了解一下这个函数的计算过程，我们很快便能明白了。
* 我们知道 & 运算，对于对应位数上的两个数字：
  0 & 0 = 0，0 & 1 = 0，1 & 1 = 1。
* 当长度为16时，16 - 1 的二进制表示就是
  00000000000000000000000000001111
* 和 hash 后的值进行 & 运算，则最后的结果一定是
  0000000000000000000000000000xxxx
  最后4位就是原 hash 值的后4位
* 可万一 n - 1 的二进制数字不是最后几位都是1，比如：
  000000000000000000000000 11010100
  000000000000000000000000 10101111
  这样进行位运算之后的结果就不一定是原值的最后几位
  这就牵扯到 HashMap 中数组的容量大小
  （我就当给不知道位运算的补课了）

#### HashMap的默认初始容量，以及其他情况下的容量

我们知道，HashMap 的默认初始容量为16
可为什么是16呢
仔细地翻出 jdk 源码一看

```java
static final int DEFAULT_INITIAL_CAPACITY = 1 << 4;
```

* 哦，1 << 4 = 16

* 我们发现，源码中用到了位运算，不管左移多少位，都是2的次方数。
  在扩容时也是如此，用了左移操作。
  ** 什么，还有扩容？我们等会再说。

* 但是，默认是16，在乘2的情况下可以永远保证是2的次方数
  如果我们初始值给他赋值3，那这样，容量岂不是永远有个因数3？

* 这就要引出我们下一个方法，对初始容量做一次计算，不使用原容量，而是使用计算过后的值作为容量。
  我们来慢慢品尝源码

  ```java
  static final int tableSizeFor(int cap) {
      int n = cap - 1;
      n |= n >>> 1;
      n |= n >>> 2;
      n |= n >>> 4;
      n |= n >>> 8;
      n |= n >>> 16;
      return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
  }
  ```

* 首先，先对原 cap - 1。(我们先不管 T_T)

* 先看第二行，有两种运算符，>>> 和 | 。

* 运算符 >>>：无符号位右移，指将二进制数值不管第一位符号位，所有的位上的数值向右移动。

* 比如：16 和 -16 右移四位
  数 字 16： 00000000000000000000000000010000
  右移四位：00000000000000000000000000000001
  得到结果：1。

* 数字 -16： 10000000000000000000000000010000
  右移四位：00001000000000000000000000000001
  得到结果：2的27次方+1

* 由于不理会符号位，所以符号位1右移之后首位一定变为0，则负数会因此变为正数。

* 接下来我们再看 | 运算符，它表示二进制数上对应位的两个数值，如果有一个为1，则为1，否则为0。

* 1 | 1 = 1，0 | 1 = 1，1 | 0 = 1，0 | 0 = 0。

* a |= b 是 a = a | b 的简写

* 现在我们很容易理解代码的第二行

* 首先有这么一个正数，不管它是多少，它的二进制第一位一定为1。
  00001xxxxxxxxxxxxxxxxxxxxxxxxxxx，对它右移1位，然后和原数异或。
  000001xxxxxxxxxxxxxxxxxxxxxxxxxx
  000011xxxxxxxxxxxxxxxxxxxxxxxxxx，我们可以发现，前两位一定是1。

* 这样，在对它右移2位异或，则前4位一定为1
  然后4位，8位，16位，就可以保证首位以后的所有位一定都是1。
  最后加上1就是容量了。

* 这样就保证了容量永远是2的次方数

* 但是如果本身输入参数已经是2的次方数了呢
  这样在计算过后会变成本身的2倍
  所以在开头要 - 1，先减小，然后执行变大为2的次方数。

* 这样，在满足了容量一直为2的次方数时，在进行 h & (n - 1) 时，才能得到我们想要的结果。

#### HashMap中是如何处理冲突的

只不过在用哈希函数计算位置时，有可能出现两个不同的键得出同一个数值的情况，这样两对人就要共同挤在一个小房间里。但一个房间肯定是不能装两对夫妻的，因此，还需要有方法来处理冲突。

* 在每个桶有超过1个数据时，将其作为链表中的结点插入
* 在 jdk1.8 往后，在链表长度大于等于8时，会转化为红黑树结构
  （可能有些人还没听说过红黑树。。。）

![在这里插入图片描述](D:\Desktop\知识整理\图片\20200129174552321.jpg)

* 在 jdk1.7 及以前，每一个结点类叫 Entry，jdk1.8 以后将其改为 Node。
* 在 jdk1.8 以前都是采用头插法，因为他们认为，后插入的数据更有可能查找的频率更高，因此插入在头部，可以提高查询效率。
* 而在 jdk1.8 以后则改为了尾插法，结点都放置在链表的尾部。因此在1.8版本以后，HashMap 不易出现环形链表。

#### 扩容操作

* 当数组的容量大时，且插入的数据很少，则产生碰撞的概率很小
* 但随着插入数据的不断增多，越来越多的键值对不停地拥挤在这一块狭小的数组之中，则会经常产生碰撞，导致每个桶中链表变长，这样在对 Map 进行操作时效率会受到很大的影响。
* 所以我们需要对数组进行扩容，可以让数据分布更均匀，尽量减少碰撞。
* 在 HashMap 中，对数组扩容的判定条件则是在 put 进入数据后，如果存放数据的数量大于了 threshold(也就是 length * loadFactory)，就会执行扩容操作。
* 扩容时会新建一个数组，容量为原数组的两倍，然后将原数组中的对象放入新数组中。
* 在移动数据时，会查看数据的 hash 值，如果对于新的长度，多出的那一位要做 & 运算的数字为0，则在数组中的位置就是原位置，如果是1，那在数组中的位置就是原数组位置加上原数组长度。

#### 初始化操作

* 为了不占用资源，HashMap 中的数组不是在 HashMap 建立时变创建，只有等到真正存储数据时，才会创建数组。

* 在 jdk1.7 中，初始化有一个专门的方法。

* 不过到了 jdk1.8 以后，初始化就被整合进了 resize() 方法中。

* 但原理至少是不变的，都是等到要存储数据时才初始化数组。

  （懒加载？是不是不提醒你也想不到）

#### 树化操作

* jdk1.8 的很大的一个特性就是增加了红黑树结构。

* 如果存在树结构，当树的节点数降低到6时，会重新转化为链表

* 首先，要存在树结构，先要保证的是数组的容量达到64，否则数组较小时，则会优先扩容，而不是选择转化为复杂的红黑树

* 而链表转化为红黑树的第二条件则是一条链表上节点数达到8

* jdk源码中的注释是这么写的

  > Because TreeNodes are about twice the size of regular nodes, we
  > use them only when bins contain enough nodes to warrant use
  > (see TREEIFY_THRESHOLD). And when they become too small (due to
  > removal or resizing) they are converted back to plain bins. In
  > usages with well-distributed user hashCodes, tree bins are
  > rarely used. Ideally, under random hashCodes, the frequency of
  > nodes in bins follows a Poisson distribution
  > (http://en.wikipedia.org/wiki/Poisson_distribution) with a
  > parameter of about 0.5 on average for the default resizing
  > threshold of 0.75, although with a large variance because of
  > resizing granularity. Ignoring variance, the expected
  > occurrences of list size k are (exp(-0.5) * pow(0.5, k) /
  > factorial(k)). The first values are:
  > 0: 0.60653066
  > 1: 0.30326533
  > 2: 0.07581633
  > 3: 0.01263606
  > 4: 0.00157952
  > 5: 0.00015795
  > 6: 0.00001316
  > 7: 0.00000094
  > 8: 0.00000006
  > more: less than 1 in ten million

翻译过来就是

> 因为TreeNodes的大小大约是常规节点的两倍，只有当容器包含足够的节点以保证使用时才使用它们。
> 当它们变得太小时（由于移除或调整大小）它们被转换回普通的结点。
> 在使用分布良好的用户哈希码、树结点很少使用。
> 理想情况下，在随机哈希码下容器中的节点遵循泊松分布带有默认大小调整的参数平均约为0.5阈值为0.75，但由于调整粒度。忽略方差，期望的列表大小k的出现次数为（exp（-0.5）*pow（0.5，k）/阶乘（k）。第一个值是：
> 0： 0.60653066
> 1： 0.30326533
> 2： 0.07581633
> 3： 0.01263606
> 4： 0.00157952
> 5： 0.00015795
> 6： 0.00001316
> 7： 0.00000094
> 8： 0.00000006
> 更多：不到千万分之一

* 所以实际上，jdk 设计者本身是不希望用到树节点的。

* 在统计学原理下，进行精确计算得出：

  在 hashCode() 离散性良好的情况下，节点数达到8及以上的概率已经不足千万分之1，几乎是不可能的。

* 但是由于不能保证每个程序员给出的 hashCode() 方法都具有良好的离散性。

  当遇到不够优秀的 hashCode() 方法时，可能会出现大量碰撞的情况，从而导致性能下降。

  而此时将链表转化为红黑树，则可以一定程度上提升性能。
  （说白了，就是避免不知名的程序猿写的 hashCode 太烂，用红黑树拉扯一下）

#### 总结：

HashMap 毕竟也是 jdk 很基础的源码之一，里面涉及到了很多知识点可供学习。

比如位运算，重哈希，转红黑树，链表头插改尾插…

这些细小的点虽然编码不难，但是能想到这样的细微修改，就能使性能因此而提高，这是很高的一种修为。

我们不仅仅是去学习里面的编码，更是去学习这种思维，能在实际情况中敏捷思考，写出高效，高质量的代码。

------

代码中的注解多看几遍，其中HashMap的扩容机制是要必懂知识！结合图片一起理解！

#### 什么是 HashMap?

HashMap 是基于哈希表的 Map 接口的非同步实现。此实现提供所有可选的映射操作，并允许使用 null 值和 null 键。此类不保证映射的顺序，特别是它不保证该顺序恒久不变。HashMap 的数据结构 在 Java 编程语言中，最基本的结构就是两种，一个是数组，另外一个是模拟指针（引用），所有的数据结构都可以用这两个基本结构来构造的，HashMap 也不例外。HashMap 实际上是一个 “链表散列” 的数据结构，即数组和链表的结合体。文字描述永远要配上图才能更好的讲解数据结构，HashMap 的结构图如下。

![img](https://pic1.zhimg.com/80/v2-70fb14458c696a387e24f435be26ef2c_720w.jpg)

从上图中可以看出，HashMap 底层就是一个数组结构，数组中的每一项又是一个链表或者红黑树。当新建一个 HashMap 的时候，就会初始化一个数组。下面先通过大概看下 HashMap 的核心成员。

```java
public class HashMap<K,V> extends AbstractMap<K,V>
    implements Map<K,V>, Cloneable, Serializable {

    // 默认容量，默认为16，必须是2的幂
    static final int DEFAULT_INITIAL_CAPACITY = 1 << 4;

    // 最大容量，值是2^30
    static final int MAXIMUM_CAPACITY = 1 << 30

    // 装载因子，默认的装载因子是0.75
    static final float DEFAULT_LOAD_FACTOR = 0.75f;

    // 解决冲突的数据结构由链表转换成树的阈值，默认为8
    static final int TREEIFY_THRESHOLD = 8;

    // 解决冲突的数据结构由树转换成链表的阈值，默认为6
    static final int UNTREEIFY_THRESHOLD = 6;

    /* 当桶中的bin被树化时最小的hash表容量。
     * 如果没有达到这个阈值，即hash表容量小于MIN_TREEIFY_CAPACITY，当桶中bin的数量太多时会执行resize扩容操作。
     * 这个MIN_TREEIFY_CAPACITY的值至少是TREEIFY_THRESHOLD的4倍。
     */
    static final int MIN_TREEIFY_CAPACITY = 64;

    static class Node<K,V> implements Map.Entry<K,V> {
        //...
    }
    // 存储数据的数组
    transient Node<K,V>[] table;

    // 遍历的容器
    transient Set<Map.Entry<K,V>> entrySet;

    // Map中KEY-VALUE的数量
    transient int size;

    /**
     * 结构性变更的次数。
     * 结构性变更是指map的元素数量的变化，比如rehash操作。
     * 用于HashMap快速失败操作，比如在遍历时发生了结构性变更，就会抛出ConcurrentModificationException。
     */
    transient int modCount;

    // 下次resize的操作的size值。
    int threshold;

    // 负载因子，resize后容量的大小会增加现有size * loadFactor
    final float loadFactor;
}
```

#### HashMap 的初始化

```java
public HashMap() {
        this.loadFactor = DEFAULT_LOAD_FACTOR; // 其他值都是默认值
    }
```

通过源码可以看出初始化时并没有初始化数组 table，那只能在 put 操作时放入了，为什么要这样做？估计是避免初始化了 HashMap 之后不使用反而占用内存吧，哈哈哈。

#### HashMap 的存储操作

```java
public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);
    }
```

下面我们详细讲一下 HashMap 是如何确定数组索引的位置、进行 put 操作的详细过程以及扩容机制 (resize)

#### hash 计算，确定数组索引位置

不管增加、删除、查找键值对，定位到哈希桶数组的位置都是很关键的第一步。前面说过 HashMap 的数据结构是数组和链表的结合，所以我们当然希望这个 HashMap 里面的元素位置尽量分布均匀些，尽量使得每个位置上的元素数量只有一个，那么当我们用 hash 算法求得这个位置的时候，马上就可以知道对应位置的元素就是我们要的，不用遍历链表，大大优化了查询的效率。HashMap 定位数组索引位置，直接决定了 hash 方法的离散性能。看下源码的实现:

```java
static final int hash(Object key) { //jdk1.8
     int h;
     // h = key.hashCode() 为第一步 取hashCode值
     // h ^ (h >>> 16) 为第二步 高位参与运算
     return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

通过 hashCode() 的高 16 位异或低 16 位实现的：(h = k.hashCode()) ^ (h >>> 16)，主要是从速度、功效、质量来考虑的，这么做可以在数组 table 的 length 比较小的时候，也能保证考虑到高低 Bit 都参与到 Hash 的计算中，同时不会有太大的开销。

大家都知道上面代码里的 key.hashCode() 函数调用的是 key 键值类型自带的哈希函数，返回 int 型散列值。理论上散列值是一个 int 型，如果直接拿散列值作为下标访问 HashMap 主数组的话，考虑到 2 进制 32 位带符号的 int 表值范围从‑2147483648 到 2147483648。前后加起来大概 40 亿的映射空间。

只要哈希函数映射得比较均匀松散，一般应用是很难出现碰撞的。但问题是一个 40 亿长度的数组，内存是放不下的。你想，HashMap 扩容之前的数组初始大小才 16。所以这个散列值是不能直接拿来用的。用之前还要先做对数组的长度取模运算，得到的余数才能用来访问数组下标。源码中模运算是在这个 indexFor( ) 函数里完成。

```java
bucketIndex = indexFor(hash, table.length);
//indexFor的代码也很简单，就是把散列值和数组长度做一个"与"操作，
static int indexFor(int h, int length) {
   return h & (length-1);
}
```

顺便说一下，这也正好解释了为什么 HashMap 的数组长度要取 2 的整次幂。因为这样（数组长度‑1）正好相当于一个 “低位掩码”。“与” 操作的结果就是散列值的高位全部归零，只保留低位值，用来做数组下标访问。以初始长度 16 为例，16‑1=15。2 进制表示是 00000000 0000000000001111。和某散列值做 “与” 操作如下，结果就是截取了最低的四位值。

```java
10100101 11000100 00100101
& 00000000 00000000 00001111
----------------------------------
  00000000 00000000 00000101 //高位全部归零，只保留末四位
```

但这时候问题就来了，这样就算我的散列值分布再松散，要是只取最后几位的话，碰撞也会很严重。更要命的是如果散列本身做得不好，分布上成等差数列的漏洞，恰好使最后几个低位呈现规律性重复，就无比蛋疼。这时候 “扰动函数” 的价值就出来了，说到这大家应该都明白了，看下图。

![img](https://pic4.zhimg.com/80/v2-216a0a11e5c55cc20883943cac46fbfb_720w.jpg)

右位移 16 位，正好是 32bit 的一半，自己的高半区和低半区做异或，就是为了混合原始哈希码的高位和低位，以此来加大低位的随机性。而且混合后的低位掺杂了高位的部分特征，这样高位的信息也被变相保留下来。

#### putVal 方法

HashMap 的 put 方法执行过程可以通过下图来理解，自己有兴趣可以去对比源码更清楚地研究学习。

![img](https://pic1.zhimg.com/80/v2-e06a2b65844d39c7f1e983485e9dd004_720w.jpg)

源码以及解释如下:

```java
// 真正的put操作
    final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        // 如果table没有初始化，或者初始化的大小为0，进行resize操作
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length;
        // 如果hash值对应的桶内没有数据，直接生成结点并且把结点放入桶中
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null);
        // 如果hash值对应的桶内有数据解决冲突，再放入桶中
        else {
            Node<K,V> e; K k;
            //判断put的元素和已经存在的元素是相同(hash一致，并且equals返回true)
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p;
            // put的元素和已经存在的元素是不相同(hash一致，并且equals返回true)
            // 如果桶内元素的类型是TreeNode，也就是解决hash解决冲突用的树型结构，把元素放入树种
            else if (p instanceof TreeNode)
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                // 桶内元素的类型不是TreeNode，而是链表时，把数据放入链表的最后一个元素上
                for (int binCount = 0; ; ++binCount) {
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        // 如果链表的长度大于转换为树的阈值(TREEIFY_THRESHOLD)，将存储元素的数据结构变更为树
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                            treeifyBin(tab, hash);
                        break;
                    }
                    // 如果查已经存在key，停止遍历
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            // 已经存在元素时
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        // 如果K-V数量大于阈值，进行resize操作
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
```

扩容机制HashMap 的扩容机制用的很巧妙，以最小的性能来完成扩容。扩容后的容量就变成了变成了之前容量的 2 倍，初始容量为 16，所以经过 rehash 之后，元素的位置要么是在原位置，要么是在原位置再向高下标移动上次容量次数的位置，也就是说如果上次容量是 16，下次扩容后容量变成了 16+16，如果一个元素在下标为 7 的位置，下次扩容时，要不还在 7 的位置，要不在 7+16 的位置。我们下面来解释一下 Java8 的扩容机制是怎么做到的？n 为 table 的长度，图（a）表示扩容前的 key1 和 key2 两种 key 确定索引位置的示例，图（b）表示扩容后 key1 和 key2 两种 key 确定索引位置的示例，其中 hash1 是 key1 对应的哈希与高位运算结果。

![img](https://pic2.zhimg.com/80/v2-7e65a3c8493f161c0a66ba607a2732b1_720w.jpg)

元素在重新计算 hash 之后，因为 n 变为 2 倍，那么 n-1 的 mask 范围在高位多 1bit(红色)，因此新的 index 就会发生这样的变化：

![img](https://pic2.zhimg.com/80/v2-7e65a3c8493f161c0a66ba607a2732b1_720w.jpg)

因此，我们在扩充 HashMap 的时候，不需要像 JDK1.7 的实现那样重新计算 hash，只需要看看原来的 hash 值新增的那个 bit 是 1 还是 0 就好了，是 0 的话索引没变，是 1 的话索引变成 “原索引 + oldCap”，可以看看下图为 16 扩充为 32 的 resize 示意图：

![img](https://pic4.zhimg.com/80/v2-3e68f29f25592eb66d60f7ed9158ceef_720w.jpg)

而 hash 值的高位是否为 1，只需要和扩容后的长度做与操作就可以了，因为扩容后的长度为 2 的次幂，所以高位必为 1，低位必为 0，如 10000 这种形式，源码中有 e.hash & oldCap 来做到这个逻辑。

这个设计确实非常的巧妙，既省去了重新计算 hash 值的时间，而且同时，由于新增的 1bit 是 0 还是 1 可以认为是随机的，因此 resize 的过程，均匀的把之前的冲突的节点分散到新的 bucket 了。这一块就是 JDK1.8 新增的优化点。有一点注意区别，JDK1.7 中 rehash 的时候，旧链表迁移新链表的时候，如果在新表的数组索引位置相同，则链表元素会倒置，但是从上图可以看出，JDK1.8 不会倒置。下面是 JDK1.8 的 resize 源码，写的很赞，如下:

```java
final Node<K,V>[] resize() {
        Node<K,V>[] oldTab = table;
        int oldCap = (oldTab == null) ? 0 : oldTab.length;
        int oldThr = threshold;
        int newCap, newThr = 0;
        // 计算新的容量值和下一次要扩展的容量
        if (oldCap > 0) {
        // 超过最大值就不再扩充了，就只好随你碰撞去吧
            if (oldCap >= MAXIMUM_CAPACITY) {
                threshold = Integer.MAX_VALUE;
                return oldTab;
            }
            // 没超过最大值，就扩充为原来的2倍
            else if ((newCap = oldCap << 1) < MAXIMUM_CAPACITY &&
                     oldCap >= DEFAULT_INITIAL_CAPACITY)
                newThr = oldThr << 1; // double threshold
        }
        else if (oldThr > 0) // initial capacity was placed in threshold
            newCap = oldThr;
        else { // zero initial threshold signifies using defaults
            newCap = DEFAULT_INITIAL_CAPACITY;
            newThr = (int)(DEFAULT_LOAD_FACTOR * DEFAULT_INITIAL_CAPACITY);
        }
        // 计算新的resize上限
        if (newThr == 0) {
            float ft = (float)newCap * loadFactor;
            newThr = (newCap < MAXIMUM_CAPACITY && ft < (float)MAXIMUM_CAPACITY ?
                      (int)ft : Integer.MAX_VALUE);
        }
        threshold = newThr;
        @SuppressWarnings({"rawtypes","unchecked"})
            Node<K,V>[] newTab = (Node<K,V>[])new Node[newCap];
        table = newTab;
        if (oldTab != null) {
            // 把每个bucket都移动到新的buckets中
            for (int j = 0; j < oldCap; ++j) {
                Node<K,V> e;
                //如果位置上没有元素，直接为null
                if ((e = oldTab[j]) != null) {
                    oldTab[j] = null;
                    //如果只有一个元素，新的hash计算后放入新的数组中
                    if (e.next == null)
                        newTab[e.hash & (newCap - 1)] = e;
                    //如果是树状结构，使用红黑树保存
                    else if (e instanceof TreeNode)
                        ((TreeNode<K,V>)e).split(this, newTab, j, oldCap);
                    //如果是链表形式
                    else { // preserve order
                        Node<K,V> loHead = null, loTail = null;
                        Node<K,V> hiHead = null, hiTail = null;
                        Node<K,V> next;
                        do {
                            next = e.next;
                            //hash碰撞后高位为0，放入低Hash值的链表中
                            if ((e.hash & oldCap) == 0) {
                                if (loTail == null)
                                    loHead = e;
                                else
                                    loTail.next = e;
                                loTail = e;
                            }
                            //hash碰撞后高位为1，放入高Hash值的链表中
                            else {
                                if (hiTail == null)
                                    hiHead = e;
                                else
                                    hiTail.next = e;
                                hiTail = e;
                            }
                        } while ((e = next) != null);
                        // 低hash值的链表放入数组的原始位置
                        if (loTail != null) {
                            loTail.next = null;
                            newTab[j] = loHead;
                        }
                        // 高hash值的链表放入数组的原始位置 + 原始容量
                        if (hiTail != null) {
                            hiTail.next = null;
                            newTab[j + oldCap] = hiHead;
                        }
                    }
                }
            }
        }
        return newTab;
    }
```