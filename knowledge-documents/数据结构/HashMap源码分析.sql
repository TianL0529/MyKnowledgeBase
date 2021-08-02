
public V put(K key, V value) {
        return putVal(hash(key), key, value, false, true);--计算key的目标hash值
    }


final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        if ((tab = table) == null || (n = tab.length) == 0)
            n = (tab = resize()).length; --table为空记得初始化
        if ((p = tab[i = (n - 1) & hash]) == null)
            tab[i] = newNode(hash, key, value, null); --目标位置为空，直接放数据
        else {
		--目前该table表不为空则继续查找
            Node<K,V> e; K k;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                e = p; --如果当前节点的hash值跟key都一样则直接将目标节点认为e就是我们的目标节点
            else if (p instanceof TreeNode) --如果p是一个红黑树则要调用红黑树的put方法
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
			--能走到这代表p节点为普通链表节点，则调用普通的链表方法进行查找，使用binCount统计链表的节点数
                for (int binCount = 0; ; ++binCount) {
				--如果p的next节点为空时，则代表找不到目标节点，则新增一个节点并插入链表尾部
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st --减一是因为循环是从p节点的下一个节点开始的
                            treeifyBin(tab, hash);
							--校验节点总数>=8个，如果超过则调用 treeifybin方法将链表节点转为红黑树节点
                        break;
                    }
					--如果e节点存在hash值和key值都与传入的相同，则e节点即为目标节点。跳出循环
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e; --将p指向下一个节点
                }
            }
			--如果e节点不为空，则代表目标节点存在，使用传入的value覆盖该节点的balue，并返回oldValue
            if (e != null) { // existing mapping for key
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null) --onlyIfAbsent 跟redis的set 类似
                    e.value = value;
                afterNodeAccess(e); --用于LinkedHashMap
                return oldValue;
            }
        }
        ++modCount; --版本控制
		--如果插入节点数量超过阈值，则调用resize方法进行扩容
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict); --用于LinkedHashMap
        return null;
    }