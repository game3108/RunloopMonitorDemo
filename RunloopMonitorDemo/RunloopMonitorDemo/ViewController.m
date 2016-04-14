//
//  ViewController.m
//  RunloopMonitorDemo
//
//  Created by game3108 on 16/4/13.
//  Copyright © 2016年 game3108. All rights reserved.
//

#import "ViewController.h"
#import "MonitorController.h"
#import "SeMonitorController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[SeMonitorController sharedInstance] startMonitor];
    
    UIButton *longTimeButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 50, 100, 100)];
    longTimeButton.backgroundColor = [UIColor blackColor];
    [longTimeButton addTarget:self action:@selector(runLongTime) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:longTimeButton];
    
    UIButton *printLogButton = [[UIButton alloc]initWithFrame:CGRectMake(100, 200, 100, 100)];
    printLogButton.backgroundColor = [UIColor grayColor];
    [printLogButton addTarget:self action:@selector(printLog) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:printLogButton];
}

- (void)runLongTime{
    for ( int i = 0 ; i < 10000 ; i ++ ){
        NSLog(@"%d",i);
    }
}

- (void)printLog{
    [[SeMonitorController sharedInstance] printLogTrace];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
