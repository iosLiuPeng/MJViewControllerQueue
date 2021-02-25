//
//  PresentQueue.h
//  MJViewControllerQueue
//
//  Created by liupeng on 2021/2/24.
//  Copyright © 2021 wuhan.musjoy. All rights reserved.
//  按顺序执行任务

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PresentQueue : NSObject

/// 开始、继续所有任务（默认暂停，需手动开始）
+ (void)start;
/// 暂停所有任务
+ (void)suspend;

/// 添加任务，自动执行
+ (void)addOperation:(void (^)(void))block;

/// 任务完成，继续下一个
+ (void)operationComplete;

/// 添加前置任务依赖(需确保前置任务已加入队列中)
+ (void)addDependencyWithOperation:(NSString *)name preOperation:(NSString *)preName;
/// 移除前置任务依赖
+ (void)removeDependencyWithOperation:(NSString *)name preOperation:(NSString *)preName;
/// 取消任务
+ (void)cancelOperation:(NSString *)name;

/// 取队列中任务
+ (NSOperation *)operationForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
