//
//  MonitorController.h
//  RunloopMonitorDemo
//
//  Created by game3108 on 16/4/13.
//  Copyright © 2016年 game3108. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MonitorController : NSObject
+ (instancetype) sharedInstance;
- (void) startMonitor;
- (void) endMonitor;
- (void) printLogTrace;
@end
