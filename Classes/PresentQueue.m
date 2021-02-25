//
//  PresentQueue.m
//  MJViewControllerQueue
//
//  Created by liupeng on 2021/2/24.
//  Copyright © 2021 wuhan.musjoy. All rights reserved.
//

#import "PresentQueue.h"

static NSOperationQueue *queue;  // 队列
static dispatch_semaphore_t semaphore;  // 信号量
static NSMutableArray<NSOperation *> *arrOperation;// 加入队列中的操作

@implementation PresentQueue
#pragma mark - Life Cycle
+ (void)load
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    queue.suspended = YES;

    semaphore = dispatch_semaphore_create(0);
    
    arrOperation = [[NSMutableArray alloc] init];
}

#pragma mark - Public
/// 开始、继续所有任务（默认暂停，需手动开始）
+ (void)start
{
    queue.suspended = NO;
}

/// 暂停所有任务
+ (void)suspend
{
    queue.suspended = YES;
}

/// 添加任务，自动执行
+ (void)addOperation:(void (^)(void))block
{
    [self addOperation:nil priority:NSOperationQueuePriorityNormal block:block];
}

/// 添加任务，指定名称、优先级
+ (void)addOperation:(nullable NSString *)name priority:(NSOperationQueuePriority)priority block:(void (^)(void))block
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block();
            }
        });

        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }];
    
    // 名字
    if (name.length) {
        operation.name = name;
    }

    // 优先级
    operation.queuePriority = priority;
    
    [arrOperation addObject:operation];
    
    [queue addOperation:operation];
}

/// 任务完成，继续下一个
+ (void)operationComplete
{
    dispatch_semaphore_signal(semaphore);
    
    // 移除已执行或者取消的任务
    NSMutableArray *arrRemove = [[NSMutableArray alloc] init];
    for (NSOperation *op in arrOperation) {
        if (op.finished || op.cancelled) {
            [arrRemove addObject:op];
        }
    }
    [arrOperation removeObjectsInArray:arrRemove];
}

/// 添加前置任务依赖(需确保前置任务已加入队列中)
+ (void)addDependencyWithOperation:(NSString *)name preOperation:(NSString *)preName
{
    NSOperation *operation = [self operationForName:name];
    NSOperation *preOperation = [self operationForName:preName];
    
    if (operation && preOperation) {
        [operation addDependency:preOperation];
    }
}

/// 移除前置任务依赖
+ (void)removeDependencyWithOperation:(NSString *)name preOperation:(NSString *)preName
{
    NSOperation *operation = [self operationForName:name];
    NSOperation *preOperation = [self operationForName:preName];
    
    if (operation && preOperation) {
        [operation removeDependency:preOperation];
    }
}

/// 取消任务
+ (void)cancelOperation:(NSString *)name
{
    NSOperation *operation = [self operationForName:name];
    if (operation) {
        [operation cancel];
        
        [arrOperation removeObject:operation];
    }
}

/// 取队列中任务
+ (NSOperation *)operationForName:(NSString *)name
{
    NSOperation *operation = nil;
    for (NSOperation *op in arrOperation) {
        if ([op.name isEqualToString:name]) {
            operation = op;
            break;
        }
    }
    return operation;
}


@end
