--概念
HTTP：超文本传输协议，无状态协议
FTP：文件传输协议
DNS：域名系统，提供域名到IP地址之间的解析服务，计算机既可以被赋予 IP 地址，也可以被赋予主机名和域名。比如 www.hackr.jp。
TCP：传输控制协议
UDP：用户数据报协议
ARP：一种用以解析地址的协议，根据通信方的IP地址就可以反查出对应的 MAC 地址
URI：统一资源标识符，用字符串标识某一互联网资源
URL：统一资源定位符   http://hackr.jp/  ，表示资源的地点（互联 网上所处的位置）。可见 URL是 URI 的子集。
GRT：获取资源
POST：传输实体主体
PUT：传输文件
HEAD：获得报文首部
DELETE：删除文件
OPTIONS：询问支持的方法
TRACE：追踪路径
COMMECT：要求用隧道协议连接代理
持久连接：只要任意一端没有明确提出断开链接，则保持TCP连接状态
管线化技术：不用等待响应即可直接发送下一个请求
Cookie：通过在请求和响应报文中写入Cookie信息来控制客户端的状态  Set-Cookie
CR + LF：HTTP报文数据的换行符
分块传输编码：把实体主体分块
MIME：多用途因特网邮件扩展
隧道：可按要求建立起一条与其他服务器的通信线路，目的是确保客户端能与服务器进行安全的通信
SSL：安全套接层，当今世界上引用最为广泛的网络安全技术
TLS：安全层传输协议
HTTPS：超文本传输安全协议，HEEP + 通信加密 + 证书 + 完整性保护，身披SSL外壳的HTTP，HTTPS采用共享密钥加密和公开密钥加密两者并用的混合加密机制
DOS：拒绝服务攻击
网络通信方式大致分为两种：电路交换（电话网）和分组交换（TCP/IP）
IP地址分网络号和主机号
地址转发表  MAC寻址中所参考的
路由控制表  IP寻址中所参考的
传输速率（带宽）：两个设备之间数据流动的物理速度称为传输速率，单位 每秒比特数
吞吐量：主机之间实际的传输率速率
中继器：再生信号放大器，通过物理层的连接延长网络，中继器无法改变传输速率
网关：负责协议的转换与数据的转发，在同一种类型的协议之间转发数据叫做应用网关，负责将从传输层到应用层的数据进行转换和转发的设别
TCP段（TCP Segmeng） TCP协议中的每个分块
SYN(synchronize)：同步序列编号（握手信号）
ACK(ACKnowlegment)：确认字符，在数据通信中，接收站发给发送站的一种传输类控制字符，表示发来的数据已确认接收无误
RST(Reset)：表示复位，用来异常的关闭连接，在TCP的设计中它是不可或缺的
FIN(finish)：断开标识
RTT(Round-Trip Time 往返时延) = 传播时延（往返哒）+排队时延（路由器和交换机的）+数据处理时延（应用程序的）。
ISN:Initial Sequence Number 初始序列号
CRL：称为证书吊销列表（Certificate Revocation List），这个列表是由 CA 定期更新，列表内容都是被撤销信任的证书序号，如果服务器的证书在此列表，就认为证书已经失效，不在的话，则认为证书是有效的。
OCSP：名为在线证书状态协议（Online Certificate Status Protocol）来查询证书的有效性，它的工作方式是向 CA 发送查询请求，让 CA 返回证书的有效状态。
重放攻击：避免᯿放攻击的方式就是需要对会话密钥设定一个合理的过期时间。
帧的类型：一般分为数据帧和控制帧两类
MSS(Maximum Segment Size)：最大报文长度
MTU(Maximum Transmission Unit)：最大传输单元
MSL(Maximum Segment Lifetime)：报文最大生存时间，它是任何报文在网络上存在的最大时间，超过这个时间报文将被丢弃。
TTL(Time To Live)：是IP数据报可以经过的最大路由数，每经过一个处理他的路由器此值就减1，当此值为0则数据报将被丢弃，同时发送ICMP报文通知源主机。
RTO(Retransmission Timeout)：超时重传时间
SACK：Selective Acknowledgment 选择性确认
D-SACK：使⽤了 SACK 来告诉「发送方」有哪些数据被重复接收了。
cwnd：拥塞窗口
swnd：发送窗口
rwnd：接收窗口
ssthresh慢启动门限
环回地址：在同一台计算机上的程序之间进行网络通信时所使用的一个默认地址，例如：IP地址：127.0.0.1
DNS 域名解析
ARP：求得下一跳的MAC地址  
RARP 协议 ：已知MAC地址获取IP地址
DHCP 动态获取 IP 地址
NAT 网络地址转换
ICMP（IP协议的助手）：Internet Control Message Protocol， 互联网控制报文协议,主要功能为：确认IP包是否
成功发送目标地址、报告发送过程中IP包被废弃的原因和改善网络设置等。
IGMP: 因特网组管理协议 
保活机制：一段时间内没有任何连接活动，TCP保活机制开始起作用，每隔一个时间间隔发送一个探测报文，如果连续几个探测报文都美哟得到响应，则认为当前的tCP连接已经死亡，系统内核将错误信息通知上层应用程序
net.ipv4.tcp_keepalive_time=7200 //保活时间s
net.ipv4.tcp_keepalive_intvl=75  //检测间隔s
net.ipv4.tcp_keepalive_probes=9  //检测次数
累计确认：又称累计应答。
NAPT：Network Address Port Translation(Port-Level NAT)













