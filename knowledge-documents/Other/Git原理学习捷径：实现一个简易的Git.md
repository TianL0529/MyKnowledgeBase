

Git 是每个程序员都要学的技能啦，下面这个是当时学习 Git 的时候，仿写的简化版本，代码仓库地址如下：

https://github.com/liuyj24/jun

项目目录地址： [jun-main.zip](D:\Desktop\知识整理\dataDirectory\jun-main.zip) 

学技术只懂操作可能会比较虚，深入点点原理会对我们驾驭技术有很大帮助，所以希望这篇文章能帮助到想要学习 **Git 基本原理**的同学。文章有八千字比较长......



![图片](https://mmbiz.qpic.cn/mmbiz_png/u9qCVeDZvZ1ZoAE2oflyibxYPicrQLG5icick1FRwtVUuSYIObAahtJIQiczyZHrHfUiamSiaib963pxNZKBalVFbP69JA/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1&wx_co=1)

# 1. init

在学习 git 原理之前，我们先忘掉平时用的 commit，branch，tag 这些炫酷的 git 指令，**后面我们会摸清楚它们的本质的。**



要知道，git 是 Linus 在写 Linux 的时候顺便写出来的，用于对 Linux 进行版本管理，所以，记录文件项目在不同版本的变更信息是 git 最核心的功能。



大牛们在设计软件的时候**总是会做相应的抽象**，想要理解他们的设计思路，我们就得在他们的抽象下进行思考。虽然说的有点玄乎，但是这些抽象最终都会落实到代码上的，所以不必担心，很好理解的。



首先，我们要奠定一个 ojbect 的概念，这是 git 最底层的抽象，你可以把 git 理解成一个 object 数据库。（这个概念我们会在接下来的科普中稍作解释，两篇文章结合起来看就好懂啦）



废话不多说，跟着指令操作，你会对 git 有一个全新的认识。首先我们在任意目录下创建一个 git 仓库：



> 本文操作的环境是 win10 + git bash

```
$ git init git-test
Initialized empty Git repository in C:/git-test/.git/
```



可以看到 git 为我们创建了一个空的 git 仓库，里面有一个`.git`目录，目录结构如下：

```
$ ls
config  description  HEAD  hooks/  info/  objects/  refs/
```



在`.git`目录下我们先重点关注 `.git/objects`这个目录，我们一开始说 git 是一个 object 数据库，这个目录就是 git 存放 object 的地方。



进入`.git/objects`目录后我们能看到`info`和`pack`两个目录，不过这和核心功能无关，我们只需要知道现在`.git/objects`目录下除了两个空目录其他啥都没有就行了。



> 到这里我们停停，先把这部分实现了吧，逻辑很简单，我们只需要编写一个入口函数，解析命令行的参数，在得到 init 指令后在指定目录下创建相应的目录与文件即可。



这里是当时的实现：init-链接：

https://github.com/liuyj24/jun/tree/b5e0f0ed8005436af182b454d6717ef3841bd5d3



为了易读暂时没有对创建文件/目录进行错误处理。



# 2.object

接下来我们进入 git 仓库目录并添加一个文件：

```
$ echo "version1" > file.txt
```



然后我们把对这个文件的记录添加进 git 系统。**要注意的是**，我们暂不使用`add`指令添加，尽管我们平时很可能这么做，但这是一篇揭示原理的文章，这里我们要引入一条平时大家可能没有听到过的 git 指令`git hash-object`。

```
$ git hash-object -w file.txt
5bdcfc19f119febc749eef9a9551bc335cb965e2
```



指令执行后返回了一个哈希值，实际上这条指令已经把对 file.txt 的内容以一个 object 的形式添加进 object 数据库中了，而这个哈希值就对应着这个 object。



为了验证 git 把这个 object 写入了数据库（以文件的形式保存下来），我们查看一下`.git/objects`目录：

```
$ find .git/objects/ -type f    #-type用于制定类型，f表示文件
.git/objects/5b/dcfc19f119febc749eef9a9551bc335cb965e2
```



发现多了一个文件夹`5b`，该文件夹下有一个名为`dcfc19f119febc749eef9a9551bc335cb965e2`的文件，也就是说 git 把该 object 哈希值的前2个字符作为目录名，后38个字符作为文件名，存放到了 object 数据库中。



> 关于 git hash-object 指令的官方介绍，这条指令用于计算一个 ojbect 的 ID 值。-w 是可选参数，表示把 object 写入到 object 数据库中；还有一个参数是 -t，用于指定 object 的类型，如果不指定类型，默认是 blob 类型。



现在你可能好奇 object 里面保存了什么信息，我们使用`git cat-file`指令去查看一下：

```
$ git cat-file -p 5bdc  # -p：查看 object 的内容，我们可以只给出哈希值的前缀
version1

$ git cat-file -t 5bdc  # -t：查看 object 的类型
blob
```



有了上面的铺垫之后，接下来我们就揭开 git 实现版本控制的秘密！

我们改变 file.txt 的内容，并重新写入 object 数据库中：

```
$ echo "version2" > file.txt
$ git hash-object -w file.txt
df7af2c382e49245443687973ceb711b2b74cb4a
```



控制台返回了一个新的哈希值，我们再查看一下 object 数据库：

```
$ find .git/objects -type f
.git/objects/5b/dcfc19f119febc749eef9a9551bc335cb965e2
.git/objects/df/7af2c382e49245443687973ceb711b2b74cb4a
```



`(ﾟДﾟ)`发现多了一个 object！



我们查看一下新 object 的内容：

```
$ git cat-file -p df7a
version2

$ git cat-file -t df7a
blob
```



看到这里，你可能对 git 是一个 object 数据库的概念有了进一步的认识：git 把文件每个版本的内容都保存到了一个 object 里面。

如果你想把 file.txt 恢复到第一个版本的状态，只需要这样做：

```
$ git cat-file -p 5bdc > file.txt
```



然后查看 file.txt 的内容：

```
$ cat file.txt
version1
```



至此，一个能记录文件版本，并能把文件恢复到任何版本状态的版本控制系统完成`(ง •_•)ง`！



是不是感觉还行，不是那么难？你可以把 git 理解成一个 key - value 数据库，一个哈希值对应一个 object。



> 到这里我们停停，把这部分实现了吧。



我一开始有点好奇，为啥查看 object 不直接用 cat 指令，而是自己编了一条 git cat-file 指令呢？后来想了一下，git 肯定不会把文件的内容原封不动保存进 object ，应该是做了压缩，所以我们还要专门的指令去解压读取。



这两条指令我们参照官方的思路进行实现，先说 git hash-object，一个 object 存储的内容是这样的：



\1. 首先要构造头部信息，头部信息由对象类型，一个空格，数据内容的字节数，一个空字节拼接而成，格式是这样：

```
blob 9\u0000
```



\2. 然后把头部信息和原始数据拼接起来，格式是这样：

```
blob 9\u0000version1
```



\3. 接着用 zlib 把上面拼接好的信息进行压缩，然后存进 object 文件中。



git cat-file 指令的实现则是相反，先把 object 文件里存放的数据用 zlib 进行解压，根据空格和空字节对解压后的数据进行划分，然后根据参数 -t 或 -p 返回 object 的内容或者类型。



这里是我的实现：hash-object and cat-file 

-链接：https://github.com/liuyj24/jun/tree/3fcd38d04b0e8d232e48f54962c12d473324b297



采用了简单粗暴的面向过程实现，但是我已经隐隐约约感到后面会用很多重用的功能，所以先把单元测试写上，方便后面重构`(ง •_•)ง`。



# 3. tree object

在上一章中，细心的小伙伴可能会发现，git 会把我们的文件内容以 blob 类型的 object 进行保存。这些 blob 类型的 object 似乎只保存了文件的内容，没有保存文件名。



而且当我们在开发项目的时候，不可能只有一个文件，通常情况下我们是需要对一个项目进行版本管理的，一个项目会包含多个文件和文件夹。



所以最基础的 blob object 已经满足不了我们使用了，我们需要引入一种新的 object，叫 tree object，它不仅能保存文件名，还能将多个文件组织到一起。



但是问题来了，引入概念很容易，但是具体落实到代码上怎么写呢？`(T_T)`，我脑袋里的第一个想法是先在内存里创建一个 tree objct，然后我们往这个指定的 tree object 里面去添加内容。但这样似乎很麻烦，每次添加东西都要给出 tree object 的哈希值。而且这样的话 tree object 就是可变的了，一个可变的 object 已经违背了保存固定版本信息的初衷。



我们还是看 git 是怎么思考这个问题的吧，git 在创建 tree object 的时候引入了一个叫暂存区概念，这是个不错的主意！你想，我们的 tree object 是要保存整个项目的版本信息的，项目有很多个文件，于是我们把文件都放进缓冲区里，git 根据缓冲区里的内容一次性创建一个 tree object，这样不就能记录版本信息了吗！



我们先操作一下 git 的缓冲区加深一下理解，首先引入一条新的指令 git update-index，它可以人为地把一个文件加入到一个新的缓冲区中，而且要加上一个 --add 的参数，因为这个文件之前还不存在于缓冲区中。

```
$ git update-index --add file.txt
```



然后我们观察一下`.git`目录的变化

```
$ ls
config  description  HEAD  hooks/  index  info/  objects/  refs/

$ find .git/objects/ -type f
objects/5b/dcfc19f119febc749eef9a9551bc335cb965e2
objects/df/7af2c382e49245443687973ceb711b2b74cb4a
```



发现`.git`目录下多了一个名为`index`的文件，这估计就是我们的缓冲区了。而`objects`目录下的 object 倒没什么变化。



我们查看一下缓冲区的内容，这里用到一条指令：git ls-files --stage

```
$ git ls-files --stage
100644 df7af2c382e49245443687973ceb711b2b74cb4a 0       file.txt
```



我们发现缓冲区是这样来存储我们的添加记录的：一个文件模式的代号，文件内容的 blob object，一个数字和文件的名字。



然后我们把当前缓冲区的内容以一个 tree object 的形式进行保存。引入一条新的指令：git write-tree

```
$ git write-tree
907aa76a1e4644e31ae63ad932c99411d0dd9417
```



输入指令后，我们得到了新生成的 tree object 的哈希值，我们去验证一下它是否存在，并看看它的内容：

```
$ find .git/objects/ -type f
.git/objects/5b/dcfc19f119febc749eef9a9551bc335cb965e2 #文件内容为 version1 的 blob object
.git/objects/90/7aa76a1e4644e31ae63ad932c99411d0dd9417 #新的 tree object
.git/objects/df/7af2c382e49245443687973ceb711b2b74cb4a #文件内容为 version2 的 blob object

$ git cat-file -p 907a
100644 blob df7af2c382e49245443687973ceb711b2b74cb4a    file.txt
```



估计看到这里，大家对暂存区与 tree object 的关系就有了初步的了解。



现在我们进一步了解两点：一个内容未被 git 记录的文件会被怎样记录，一个文件夹又会被怎样记录？



下面我们一步步来，创建一个新的文件，并加入暂存区：

```
$ echo abc > new.txt

$ git update-index --add new.txt

$ git ls-files --stage
100644 df7af2c382e49245443687973ceb711b2b74cb4a 0       file.txt
100644 8baef1b4abc478178b004d62031cf7fe6db6f903 0       new.txt
```



查看缓冲区后，我们发现新文件的记录以追加的方式加入了暂存区，而且也对应了一个哈希值。我们查看一下哈希值的内容：

```
$ find .git/objects/ -type f
.git/objects/5b/dcfc19f119febc749eef9a9551bc335cb965e2 #新的 object
.git/objects/8b/aef1b4abc478178b004d62031cf7fe6db6f903 #文件内容为 version1 的 blob object
.git/objects/90/7aa76a1e4644e31ae63ad932c99411d0dd9417 #tree object
.git/objects/df/7af2c382e49245443687973ceb711b2b74cb4a #文件内容为 version2 的 blob object

$ git cat-file -p 8bae
abc

$ git cat-file -t 8bae
blob
```



我们发现，在把 new.txt 加入到暂存区时，git 自动给 new.txt 的内容创建了一个 blob object。

我们再尝试一下创建一个文件夹，并添加到暂存区中：

```
$ mkdir dir

$ git update-index --add dir
error: dir: is a directory - add files inside instead
fatal: Unable to process path dir
```



结果 git 告诉我们不能添加一个空文件夹，需要在文件夹中添加文件，那么我们就往文件夹中加一个文件，然后再次添加到暂存区：

```
$ echo 123 > dir/dirFile.txt

$ git update-index --add dir/dirFile.txt
```



成功了~然后查看暂存区的内容：

```
$ git ls-files --stage
100644 190a18037c64c43e6b11489df4bf0b9eb6d2c9bf 0       dir/dirFile.txt
100644 df7af2c382e49245443687973ceb711b2b74cb4a 0       file.txt
100644 8baef1b4abc478178b004d62031cf7fe6db6f903 0       new.txt

$ git cat-file -t 190a
blob
```



和之前的演示一样，自动帮我们为文件内容创建了一个 blob object。

接下来我们把当前的暂存区保存成为一个 tree object：

```
$ git write-tree
dee1f9349126a50a52a4fdb01ba6f573fa309e8f

$ git cat-file -p dee1
040000 tree 374e190215e27511116812dc3d2be4c69c90dbb0    dir
100644 blob df7af2c382e49245443687973ceb711b2b74cb4a    file.txt
100644 blob 8baef1b4abc478178b004d62031cf7fe6db6f903    new.txt
```



新的 tree object 保存了暂存区的当前版本信息，值得注意的是，暂存区是以 blob object 的形式记录`dir/dirFile.txt`的，而在保存树对象的过程中，git 为目录 `dir` 创建了一个树对象，我们验证一下：

```
$ git cat-file -p 374e
100644 blob 190a18037c64c43e6b11489df4bf0b9eb6d2c9bf    dirFile.txt

$ git cat-file -t 374e
tree
```



发现这个为 `dir` 目录而创的树对象保存了 `difFile.txt` 的信息，是不是感觉似曾相似！这个 tree object 就是对文件目录的模拟呀！



> 我们停停！开始动手！



这次我们需要实现上述的三条指令：

1. **git update-index --add**

git update-index更新暂存区，官方的这条指令是带有很多参数的，我们只实现 --add，也就是添加文件到暂存区。总体的流程是这样的：如果是第一次添加文件进缓冲区，我们需要创建一个 index 文件，如果 index 文件已经存在则直接把暂存区的内容读取出来，注意要有个解压的过程。然后把新的文件信息添加到暂存区中，把暂存区的内容压缩后存入 index 文件。



这里涉及到一个序列化和反序列的操作，请允许我偷懒通过 json 进行模拟`ψ(._. )>`。



1. **git ls-files --stage**

git ls-files 用来查看暂存区和工作区的文件信息，同样有很多参数，我们只实现 --stage，查看暂存区的内容（不带参数的 ls-files 指令是列出当前目录包括子目录下的所有文件）。实现流程：从 index 文件中读取暂存区的内容，解压后按照一定的格式打印到标准输出。



1. **git write-tree**

git write-tree 用于把暂存区的内容转换成一个 tree object，根据我们之前演示的例子，对于文件夹我们需要递归下降解析 tree object，这应该是本章最难实现的地方了。



代码如下：update-index --add, ls-files --stage, write-tree 

-链接：https://github.com/liuyj24/jun/tree/bee0e5fa5d38b5806046ec48bf73c70f17b37968



感觉可以把 object 抽象一下，于是重构了一下和 object 相关的代码：refactor object part 

-链接：https://github.com/liuyj24/jun/tree/1de3e9185f9ecbdb42c97ba144d2497063a69378



当这部分完成后，我们已经拥有一个能够对文件夹进行版本管理的系统了`(ง •_•)ง`。



# 4.commit object

虽然我们已经可以用一个 tree object 来表示整个项目的版本信息了，但是似乎还是有些不足的地方：



tree object 只记录了文件的版本信息，这个版本是谁修改的？是因什么而修改的？它的上一个版本是谁？这些信息没有被保存下来。



这个时候，就该 commit object 出场了！怎么样，从底层一路向上摸索的感觉是不是很爽！？



我们先用 git 操作一遍，然后再考虑如何实现。下面我们使用 commit-tree 指令来创建一个 commit object，这个 commit object 指向第三章最后生成的 tree object。

```
$ git commit-tree dee1 -m 'first commit'
893fba19d63b401ae458c1fc140f1a48c23e4873
```



由于生成时间和作者不同，你得到的哈希值会不一样，我们查看一下这个新生成的 commit object：

```
$ git cat-file -p 893f
tree dee1f9349126a50a52a4fdb01ba6f573fa309e8f
author liuyj24 <liuyijun2017@email.szu.edu.cn> 1608981484 +0800
committer liuyj24 <liuyijun2017@email.szu.edu.cn> 1608981484 +0800

first commit
```



可以看到，这个commit ojbect 指向一个 tree object，第二第三行是作者和提交者的信息，空一行后是提交信息。

下面我们修改我们的项目，模拟版本的变更：

```
$ echo version3 > file.txt

$ git update-index --add file.txt

$ git write-tree
ff998d076c02acaf1551e35d76368f10e78af140
```



然后我们创建一个新的提交对象，把它的父对象指向第一个提交对象：

```
$ git commit-tree ff99 -m 'second commit' -p 893f
b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0
```



我们再修改我们的项目，然后创建第三个提交对象：

```
$ echo version4 >file.txt

$ git update-index --add file.txt

$ git write-tree
1403e859154aee76360e0082c4b272e5d145e13e

$ git commit-tree 1403 -m 'third commit' -p b05c
fe2544fb26a26f0412ce32f7418515a66b31b22d
```



然后我们执行 git log 指令查看我们的提交历史：

```
$ git log fe25
commit fe2544fb26a26f0412ce32f7418515a66b31b22d
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:36:31 2020 +0800

    third commit

commit b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:34:25 2020 +0800

    second commit

commit 893fba19d63b401ae458c1fc140f1a48c23e4873
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit
```



怎么样？是不是有种豁然开朗的感觉！



> 下面我们停停，把这一部分给实现了。



一共是两条指令

1. **commit-tree**

创建一个 commit object，让它指向一个 tree object，添加作者信息，提交者信息，提交信息，再增加一个父节点即可（父节点可以不指定）。作者信息和提交者信息我们暂时写死，这个可以通过 git config 指令设置，你可以查看一下`.git/config`，其实就是一个读写配置文件的操作。



1. **log**

根据传入的 commit object 的哈希值向上找它的父节点并打印信息，通过递归能快速实现。



这里是我的实现：commit-tree, log 

-链接：https://github.com/liuyj24/jun/tree/84b7a51eda011e8a48a6b4e84d2de16ca54d4064



# 5. references

在前面的四章我们铺垫了很多 git 的底层指令，从这章开始，我们将对 git 的常用功能进行讲解，这绝对会有一种势如破竹的感觉。



虽然我们的 commit object 已经能够很完整地记录版本信息了，但是还有一个致命的缺点：我们需要通过一个很长的SHA1散列值来定位这个版本，如果在开发的过程中你和同事说：



嘿！能帮我 review 一下 32h52342 这个版本的代码吗？



那他肯定会回你：哪。。。哪个版本来着？`(+_+)?`



所以我们要得考虑给我们的 commit object 起名字，比如起名叫 master。



我们实际操作一下 git，给我们最新的提交对象起名叫 master：

```
$ git update-ref refs/heads/master fe25
```



然后通过新的名字查看提交记录：

```
$ git log master
commit fe2544fb26a26f0412ce32f7418515a66b31b22d (HEAD -> master)
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:36:31 2020 +0800

    third commit

commit b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:34:25 2020 +0800

    second commit

commit 893fba19d63b401ae458c1fc140f1a48c23e4873
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit
```



好家伙`(→_→)`，要不我们给这个功能起个牛逼的名字，就叫**分支**吧！



这个时候你可能会想，平时我们在 master 分支上进行提交，都是一个 git commit -m 指令就搞定的，现在背后的原理我似乎也懂：

1. 首先是通过命令 write-tree 把暂存区的记录写到一个树对象里，得到树对象的 SHA1 值。
2. 然后通过命令 commit-tree 创建一个新的提交对象。



问题是：commit-tree 指令所用到的的树对象 SHA1 值，-m 提交信息都有了，但是 -p 父提交对象的 SHA1 值我们怎么获得呢？



这就要提到我们的 HEAD 引用了！你会发现我们的`.git`目录中有一个`HEAD`文件，我们查看一下它的内容：

```
$ ls
config  description  HEAD  hooks/  index  info/  logs/  objects/  refs/

$ cat HEAD
ref: refs/heads/master
```



所以当我们进行 commit 操作的时候，git 会到 HEAD 文件中取出当前的引用，也就是当前的提交对象的 SHA1 值作为新提交对象的父对象，这样整个提交历史就能串联起来啦！



看到这里，你是不是对 git branch 创建分支，git checkout 切换分支也有点感觉了呢？！



现在我们有三个提交对象，我们尝试在第二个提交对象上创建分支，同样先用底层指令完成，我们使用 git update-ref 指令对第二个提交创建一个 reference：

```
$ git update-ref refs/heads/bugfix b05c

$ git log bugfix
commit b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0 (bugfix)
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:34:25 2020 +0800

    second commit

commit 893fba19d63b401ae458c1fc140f1a48c23e4873
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit
```



然后我们改变我们当前所处的分支，也就是修改 `.git/HEAD`文件的值，我们用到 git symbolic-ref 指令：

```
git symbolic-ref HEAD refs/heads/bugfix
```



我们再次通过 log 指令查看日志，如果不加参数的话，默认就是查看当前分支：

```
$ git log
commit b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0 (HEAD -> bugfix)
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:34:25 2020 +0800

    second commit

commit 893fba19d63b401ae458c1fc140f1a48c23e4873
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit
```



当前分支就切换到 bugfix 啦！



> 我们停停，把这部分给实现了，基本都是简单的文件读写操作。



**1. update-ref**

把提交对象的哈希值写到`.git/refs/heads`下指定的文件中。由于之前 log 指令实现的不够完善，这里要重构一下，支持对 ref 名字的查找。



1. **symbolic-ref**

用于修改 ref，我们就简单实现吧，对`HEAD`文件进行修改。



1. **commit**

有了上面两条指令打下的基础，我们就可以把 commit 命令给实现了。再重复一遍流程：首先是通过命令 write-tree 把暂存区的记录写到一个树对象里，得到树对象的 SHA1 值。然后通过命令 commit-tree 创建一个新的提交对象，新提交对象的父对象从`HEAD`文件中获取。最后更新对应分支的提交对象信息。



这个是我的实现：update-ref, symbolic-ref, commit 

-链接：https://github.com/liuyj24/jun/tree/7d7cfb40fbc7ad2915857b9483bc5c7eced379b1



实现到这里，估计你已经对 checkout，branch 等命令没啥兴趣了，checkout 就是封装一下 symbolic-ref，branch 就是封装一下 update-ref。



git 为了增加指令的灵活性，为指令提供了不少可选参数，但实际上都是这几个底层指令的调用。而且有了这些底层指令，你会发现其他扩展功能很轻松地实现，这里就不展开啦`(ง •_•)ง`。



# 6. tag

完成了上面这些功能，估计大家会对 git 有个较为深刻的认识了，但不知道大家有没发现一个小问题：



当我们开发出了分支功能后，我们会基于分支做版本管理。但随着分支有了新的提交，分支又会指向新的提交对象，也就是说我们的分支是变动的。但是我们总会有一些比较重要的版本需要记录，我们需要一些不变的东西来记录某个提交版本。



又由于记录某个提交版本的 SHA1 值不是很好，所以我们给这些重要的提交版本取个名字，以 tag 的形式进行存储。估计大家在实现 references 的时候也有留意到`.git/refs/`下除了`heads`还有一个`tags`目录，其实原理和 reference 一样，也是记录一个提交对象的哈希值。我们用 git 实际操作一下，给当前分支的第一个提交对象打一个 tag：

```
$ git log
commit b05c65b6fdd7e13a51aaf1abb8ff3e795835bfb0 (HEAD -> bugfix)
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:34:25 2020 +0800

    second commit

commit 893fba19d63b401ae458c1fc140f1a48c23e4873
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit

$ git tag v1.0 893f
```



然后查看一下这个 tag

```
$ git show v1.0
commit 893fba19d63b401ae458c1fc140f1a48c23e4873 (tag: v1.0)
Author: liuyj24 <liuyijun2017@email.szu.edu.cn>
Date:   Sat Dec 26 19:18:04 2020 +0800

    first commit

······
```



这样我们就能通过 v1.0 这个 tag 定位到某个版本了。



# 7. more

这篇文章，当时是边看官方文档，一边实现一边写的，其实写到这里整个 git 的轮廓已经很清晰了。因为 git 本身已经足够优秀了，我们也没有必要重写一个，本文这种造小轮子的方式意在学习 git 的核心思想，也就是如何搭建一个用于版本管理的 object 数据库。



其实我们可以展望一下 git 的其他功能（纸上谈兵`(→_→)`）：

1. add 指令：其实就是对我们 update-index 指令的封装，我们平常都是直接`add .`把所有修改过的文件添加进缓存区。想要实现这样的功能可以递归遍历目录，使用 diff 工具对修改过的文件执行一次 update-index。
2. merge 指令：这个我感觉比较难实现，目前思路是这样的：通过递归，借助 diff 工具，把 merge 项目中多出来的部分追加到被 merge 项目中，如果 diff 指示出现冲突，就让用户解决冲突。
3. rebase 指令：其实就是修改提交对象的顺序，具体实现就是修改它们的 parent 值。类似往链表中间插入一个节点或一个链表这样的问题，就是调整链表。
4. ······



除了这些，git 还有远程仓库的概念，而远程仓库和本地仓库的本质是一样的，不过里面涉及了很多同步协作的问题。感觉现在继续学 git 的其他功能轻松了一些，更加自信了！



> 最后是关于自己这个迷你 git 的一些回顾



最后要对自己已经实现的部分作一些总结，和开源代码比起来有啥要可以提高改进的地方：



\1. 没有实现一个寻址的函数。git 可以在仓库的任何目录下工作，而我的只能工作在仓库根目录下。应该实现一个查找当前仓库下`.git`目录的函数，这样整个系统在文件目录寻址的时候可以有统一的入口。





\2. 对 object 的抽象不够完善。迷你项目只是实现了把版本添加进对象数据库，不能从对象数据库中恢复版本，想要实现恢复版本，需要给每个对象制定相应的反序列化方法，也就是说，object应该实现这样一套接口：

```
type obj interface {
 serialize(Object) []byte
 deserialize([]byte) Object
}
```



\3. 目录分隔符的问题，由于我用 windows 开发，在 git bash 上测试，所有把分隔符写死成了`/`，这不太好。



\4. 目前可以不停 commit，commit 的时候应该检查一下暂存区是否有更新，没有更新就不让 commit 了。



\5. 对命令行参数的判断有点丑，暂时还没找到好办法······