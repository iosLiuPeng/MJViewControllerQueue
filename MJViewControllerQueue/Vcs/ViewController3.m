//
//  ViewController3.m
//  test
//
//  Created by 刘鹏i on 2018/9/25.
//  Copyright © 2018 刘鹏. All rights reserved.
//

#import "ViewController3.h"

@interface ViewController3 ()

@end

@implementation ViewController3

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"关闭 ViewController3");
    }];
}

- (void)dealloc
{
    NSLog(@"销毁 ViewController3");
}
@end
