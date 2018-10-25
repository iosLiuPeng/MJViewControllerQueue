//
//  UIViewController+Queue.m
//  test
//
//  Created by 刘鹏i on 2018/9/25.
//  Copyright © 2018 刘鹏. All rights reserved.
//

#import "UIViewController+Queue.h"
#import <objc/runtime.h>

#ifdef MODULE_CONTROLLER_MANAGER
#import <MJControllerManager/MJControllerManager.h>
#endif

static dispatch_queue_t queue;  // 队列
static dispatch_semaphore_t semaphore;  // 信号量
static NSMutableArray<NSString *> *arrRecord;// 控制器的弹出记录

@implementation UIViewController (Queue)
#pragma mark - Life Circle
+(void)load {
    [super load];
    
    // 交换 dismissViewControllerAnimated:completion: 方法
    Method methoda = class_getInstanceMethod([UIViewController class], @selector(dismissViewControllerAnimated:completion:));
    Method methodb = class_getInstanceMethod([self class], @selector(mydismissViewControllerAnimated:completion:));
    method_exchangeImplementations(methoda, methodb);
    
    queue = dispatch_queue_create("custom.UIViewController+Queue", DISPATCH_QUEUE_SERIAL);
    dispatch_suspend(queue);
    
    semaphore = dispatch_semaphore_create(0);
    
    arrRecord = [[NSMutableArray alloc] init];
}

#pragma Public
/// 添加一组控制器（按数组顺序弹出）
+ (void)addViewControlerArrayForName:(NSArray<NSString *> *)arrVC
{
    NSMutableArray *muarrVC = [NSMutableArray arrayWithCapacity:arrVC.count];
    for (NSString *vcName in arrVC) {
#ifdef MODULE_CONTROLLER_MANAGER
        UIViewController *vc = [MJControllerManager getViewControllerWithName:vcName];
#else
        UIViewController *vc = [[self class] getViewControllerWithName:vcName];
#endif
        [muarrVC addObject:vc];
    }
    
    [[self class] addViewControlerArray:muarrVC];
}

/// 添加一组控制器（按数组顺序弹出）
+ (void)addViewControlerArray:(NSArray<UIViewController *> *)arrVC
{
    for (UIViewController *vc in arrVC) {
        [[self class] addViewController:vc];
    }
}

/// 开始
+ (void)activeQueue
{
    dispatch_resume(queue);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_semaphore_signal(semaphore);
    });
}

/// 移除队列中任务
+ (void)removeQueue
{
    queue = dispatch_queue_create("custom.UIViewController+Queue", DISPATCH_QUEUE_SERIAL);
    dispatch_suspend(queue);
}

#pragma mark - Private
/// 添加控制器
+ (void)addViewController:(UIViewController *)vc;
{
    [[self class] addViewController:vc withPresentCompletion:nil];
}

/**
 添加控制器
 
 @param vcName 控制器名称
 @param completion present后回调
 */
+ (void)addViewControllerForName:(NSString *)vcName withPresentCompletion:(void (^ __nullable)(void))completion
{
#ifdef MODULE_CONTROLLER_MANAGER
    UIViewController *vc = [MJControllerManager getViewControllerWithName:vcName];
#else
    UIViewController *vc = [[self class] getViewControllerWithName:vcName];
#endif
    
    [[self class] addViewController:vc withPresentCompletion:completion];
}

/**
 添加控制器
 
 @param vc 控制器
 @param completion present后回调
 */
+ (void)addViewController:(UIViewController *)vc withPresentCompletion:(void (^ __nullable)(void))completion
{
    dispatch_async(queue, ^{
        if (vc == nil) {
            return;
        }
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_main_queue(), ^{
#ifdef MODULE_CONTROLLER_MANAGER
            UIViewController *topVC = [MJControllerManager topViewController];
#else
            UIViewController *topVC = [[self class] topViewController];
#endif
            UIViewController *containerVC = topVC.parentViewController? topVC.parentViewController: topVC;
            NSString *record = [NSString stringWithFormat:@"%p -> %p", containerVC, vc];
            [arrRecord addObject:record];
            // 弹出
            [topVC presentViewController:vc animated:YES completion:completion];
        });
    });
}

#pragma mark - Runtime
- (void)mydismissViewControllerAnimated:(BOOL)flag completion: (void (^ __nullable)(void))completion
{
    NSString *record = nil;
    if (self.presentedViewController) {
        record = [NSString stringWithFormat:@"%p -> %p", self, self.presentedViewController];
    } else {
        record = [NSString stringWithFormat:@"%p -> %p", self.presentingViewController, self];
    }
    
    [self mydismissViewControllerAnimated:flag completion:^{
        if (completion) {
            completion();
        }
        
        if ([arrRecord containsObject:record]) {
            dispatch_semaphore_signal(semaphore);
            [arrRecord removeObject:record];
        }
    }];
}

#pragma mark - Other


#ifndef MODULE_CONTROLLER_MANAGER
+ (UIViewController *)getViewControllerWithName:(NSString *)aVCName
{
    if (aVCName.length == 0) {
        return nil;
    }
    Class classVC = NSClassFromString(aVCName);
    if (classVC) {
        // 存在该类
        NSString *filePath = [[NSBundle mainBundle] pathForResource:aVCName ofType:@"nib"];
        UIViewController *aVC = nil;
        if (filePath.length > 0) {
            aVC = [[classVC alloc] initWithNibName:aVCName bundle:nil];
        } else {
            aVC = [[classVC alloc] init];
        }
        return aVC;
    }
    return nil;
}

+ (UIViewController *)topViewController
{
    UIViewController *topVC = nil;
    UINavigationController *navVC = (UINavigationController *)[[self class] topWindow].rootViewController;
    while (navVC.presentedViewController != nil) {
        navVC = (UINavigationController *)navVC.presentedViewController;
    }
    if ([navVC isKindOfClass:[UINavigationController class]]) {
        topVC = navVC.topViewController;
    } else {
        topVC = navVC;
    }
    
    while ([topVC isKindOfClass:[UINavigationController class]] || [topVC isKindOfClass:[UITabBarController class]]) {
        if ([topVC isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tabBarVC = (UITabBarController *)topVC;
            NSInteger selectedIndex = tabBarVC.selectedIndex;
            if (selectedIndex < 0 || selectedIndex >= tabBarVC.viewControllers.count) {
                selectedIndex = 0;
            }
            topVC = [tabBarVC.viewControllers objectAtIndex:selectedIndex];
        } else {
            UINavigationController *navVC = (UINavigationController *)topVC;
            topVC = navVC.topViewController;
        }
    }
    
    return topVC;
}

+ (UIWindow *)topWindow
{
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    UIWindow *mainWindow = [delegate window];
    UIWindow *topWindow = [[UIApplication sharedApplication] keyWindow];
    if (topWindow != mainWindow) {
        NSArray *arrWindows = [[UIApplication sharedApplication].windows sortedArrayUsingComparator:^NSComparisonResult(UIWindow *win1, UIWindow *win2) {
            return win1.windowLevel - win2.windowLevel;
        }];
        for (NSInteger i = arrWindows.count - 1; i >=0 ; i--) {
            UIWindow *aWindow = arrWindows[i];
            if (![aWindow isKindOfClass:NSClassFromString(@"UITextEffectsWindow")]
                && aWindow.windowLevel <= UIWindowLevelNormal + 10
                && aWindow.rootViewController
                && !aWindow.rootViewController.view.isHidden) {
                topWindow = aWindow;
                break;
            }
        }
    }
    return topWindow;
}
#endif

@end
