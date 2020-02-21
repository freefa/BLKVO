//
//  RootViewController.m
//  BLKVO
//
//  Created by Louis.B on 2020/2/18.
//  Copyright © 2020 Louis.B. All rights reserved.
//

#import "RootViewController.h"
#import "KVOViewController.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    NSLog(@"%s", __func__);
}

- (IBAction)testKvoButtonTouched:(id)sender {
    KVOViewController *controller = [[KVOViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
