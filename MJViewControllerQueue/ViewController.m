//
//  ViewController.m
//  MJViewControllerQueue
//
//  Created by 刘鹏i on 2018/9/25.
//  Copyright © 2018 wuhan.musjoy. All rights reserved.
//

#import "ViewController.h"
#import "UIViewController+Queue.h"
#import "ViewController1.h"
#import "ViewController2.h"
#import "ViewController3.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)present:(id)sender {
    [UIViewController addViewControlerArrayForName:@[@"ViewController1", @"ViewController2", @"ViewController3"]];
    
    
    [UIViewController addViewControllerForName:@"ViewController1" withPresentCompletion:^{
        NSLog(@"已经弹出 ViewController1");
    }];
    
    [UIViewController addViewControllerForName:@"ViewController2" withPresentCompletion:^{
        NSLog(@"已经弹出 ViewController2");
    }];
    
    [UIViewController activeQueue];
}


- (IBAction)remove:(id)sender {
    [UIViewController removeQueue];
}

- (IBAction)present2:(id)sender {
    UIViewController *vc1 = [[ViewController1 alloc] init];
    UIViewController *vc2 = [[ViewController2 alloc] init];
    UIViewController *vc3 = [[ViewController3 alloc] init];

    [UIViewController addViewControlerArray:@[vc1, vc2]];

    [UIViewController addViewController:vc3 withPresentCompletion:^{
        NSLog(@"已经弹出 ViewController3");
    }];
    
    [UIViewController activeQueue];
}
@end
