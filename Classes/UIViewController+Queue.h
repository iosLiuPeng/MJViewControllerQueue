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
 MARK: 可能存在的问题：
 1.使用控制器的hash判断两个控制器是否相同， 以此作为判断是否为队列中弹出的控制器的依据。如果这么判断不准确，那可以使用“控制器内存地址”或者“控制器内存地址 + hash”作为控制器唯一依据
 
 2.信号量用在主线程中，但是目前未发现堵塞主线程的情况，也许存在特殊情况下会堵塞主线程（只是猜想）
 
 3.因为GCD队列没有取消任务的方法，所以在移除队列方法中，新建了一个队列，将之前的队列置为nil，经检查没有内存泄漏的问题，不知道会不会有其他潜在问题
 */


/// 添加一组控制器（按数组顺序弹出）
+ (void)addViewControlerArrayForName:(NSArray <NSString *>*)arrVC;

/// 添加一组控制器（按数组顺序弹出）
+ (void)addViewControlerArray:(NSArray <UIViewController *> *)arrVC;

/**
 添加控制器
 
 @param vcName 控制器名称
 @param completion present后回调
 */
+ (void)addViewControllerForName:(NSString *)vcName withPresentCompletion:(void (^ __nullable)(void))completion;

/**
 添加控制器
 
 @param vc 控制器
 @param completion present后回调
 */
+ (void)addViewController:(UIViewController *)vc withPresentCompletion:(void (^ __nullable)(void))completion;

/// 开始
+ (void)activeQueue;

/// 移除队列中任务
/// (如果不想复用之前的任务，想重建新的任务，需要调用此方法将之前的任务移除)
+ (void)removeQueue;

@end

NS_ASSUME_NONNULL_END
