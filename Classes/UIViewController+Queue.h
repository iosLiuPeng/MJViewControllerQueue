//
//  UIViewController+Queue.h
//  test
//
//  Created by 刘鹏i on 2018/9/25.
//  Copyright © 2018 刘鹏. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (Queue)

/*
 可能存在的问题：
 1.使用控制器的hash判断两个控制器是否相同， 以此作为判断是否为队列中弹出的控制器的依据。如果这么判断不准确，那可以使用“控制器内存地址”或者“控制器内存地址 + hash”作为控制器唯一依据
 
 2.信号量用在主线程中，但是目前未发现堵塞主线程的情况，也许存在特殊情况下会堵塞主线程（只是猜想）
 */


/// 添加控制器（按数组顺序弹出）
+ (void)addViewControlersForName:(NSArray <NSString *>*)arrVC;
/// 添加控制器（按数组顺序弹出）
+ (void)addViewControlers:(NSArray <UIViewController *> *)arrVC;
/// 开始
+ (void)start;
@end

NS_ASSUME_NONNULL_END
