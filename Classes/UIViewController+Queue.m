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

static dispatch_queue_t queue;  // 串行队列
static dispatch_semaphore_t semaphore;  // 信号量
static NSMutableArray<NSString *> *arrHash;// 记录弹出控制器的hash值

@implementation UIViewController (Queue)
#pragma mark - Life Circle
+(void)load {
    [super load];
    
    // 交换 dismissViewControllerAnimated:completion: 方法
    Method methoda = class_getInstanceMethod([UIViewController class], @selector(dismissViewControllerAnimated:completion:));
    Method methodb = class_getInstanceMethod([self class], @selector(mydismissViewControllerAnimated:completion:));
    method_exchangeImplementations(methoda, methodb);
    
    // 交换 dismissModalViewControllerAnimated: 方法
    Method methodc = class_getInstanceMethod([UIViewController class], @selector(dismissModalViewControllerAnimated:));
    Method methodd = class_getInstanceMethod([self class], @selector(mydismissModalViewControllerAnimated:));
    method_exchangeImplementations(methodc, methodd);
}

#pragma Public
/// 添加控制器（按数组顺序弹出）
+ (void)addViewControlersForName:(NSArray<NSString *> *)arrVC
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
    
    [[self class] addViewControlers:muarrVC];
}

/// 添加控制器（按数组顺序弹出）
+ (void)addViewControlers:(NSArray<UIViewController *> *)arrVC
{
    queue = dispatch_queue_create("custom.UIViewController+Queue", DISPATCH_QUEUE_SERIAL);
    dispatch_suspend(queue);
    
    semaphore = dispatch_semaphore_create(0);
    
    arrHash = [[NSMutableArray alloc] init];
    
    dispatch_async(queue, ^{
        for (UIViewController *vc in arrVC) {
            [[self class] addViewController:vc];
        }
    });
}

/// 开始
+ (void)start
{
    dispatch_resume(queue);
    dispatch_semaphore_signal(semaphore);
}

#pragma mark - Private
/// 添加控制器
+ (void)addViewController:(UIViewController *)vc;
{
    if (vc == nil) {
        return;
    }

    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *hash = [NSString stringWithFormat:@"%lu", (unsigned long)vc.hash];
        [arrHash addObject:hash];
        
#ifdef MODULE_CONTROLLER_MANAGER
        UIViewController *topVC = [MJControllerManager topViewController];
#else
        UIViewController *topVC = [[self class] topViewController];
#endif
        // 弹出
        [topVC presentViewController:vc animated:YES completion:nil];
    });
}

#pragma mark - Runtime
- (void)mydismissViewControllerAnimated:(BOOL)flag completion: (void (^ __nullable)(void))completion {
    [self mydismissViewControllerAnimated:flag completion:^{
        if (completion) {
            completion();
        }
        
        NSString *hash = [NSString stringWithFormat:@"%lu", (unsigned long)self.hash];
        if ([arrHash containsObject:hash]) {
            dispatch_semaphore_signal(semaphore);
        }
    }];
}

- (void)mydismissModalViewControllerAnimated:(BOOL)animated {
    [self mydismissModalViewControllerAnimated:animated];
    
    NSString *hash = [NSString stringWithFormat:@"%lu", (unsigned long)self.hash];
    if ([arrHash containsObject:hash]) {
        dispatch_semaphore_signal(semaphore);
    }
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
