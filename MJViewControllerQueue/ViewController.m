//
//  ViewController.m
//  MJViewControllerQueue
//
//  Created by 刘鹏i on 2018/9/25.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import "ViewController.h"
#import "PresentQueue.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btnPresent;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UILabel *lblIndex;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _btnPresent.hidden = _index != 0;
    _btnClose.hidden = _index == 0;
    
    _lblIndex.text = @(_index).stringValue;
}

- (IBAction)clickedPresent:(id)sender {
    for (NSInteger i = 1; i <= 5; i++) {
        [PresentQueue addOperation:^{
            NSLog(@"== 创建控制器: %ld ==", i);
            ViewController *vc = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
            vc.index = i;
            UIViewController *topVC = [self.class topViewController];
            NSLog(@"topVC: %@  presentVC: %@", topVC, vc);
            [topVC presentViewController:vc animated:YES completion:nil];
        }];
    }
    
    [PresentQueue start];
}

- (IBAction)clickedCLose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [PresentQueue operationComplete];
    }];
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

@end
