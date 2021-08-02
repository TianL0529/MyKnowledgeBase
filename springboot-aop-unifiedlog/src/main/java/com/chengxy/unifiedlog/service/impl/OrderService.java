package com.chengxy.unifiedlog.service.impl;

import com.chengxy.unifiedlog.entity.OrderDTO;
import com.chengxy.unifiedlog.entity.OrderVO;

/**
 * @Author: TianL
 * @Description:
 */
public interface OrderService {

    OrderDTO getOrderInfo(OrderVO orderVO);

}
