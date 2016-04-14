//
//  MonitorController.m
//  RunloopMonitorDemo
//
//  Created by game3108 on 16/4/13.
//  Copyright © 2016年 game3108. All rights reserved.
//

#import "MonitorController.h"
#import <libkern/OSAtomic.h>
#import <execinfo.h>

@interface MonitorController(){
    CFRunLoopObserverRef _observer;
    double _lastRecordTime;
    NSMutableArray *_backtrace;
}

@end

@implementation MonitorController

static double _waitStartTime;


+ (instancetype) sharedInstance{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void) startMonitor{
    [self addMainThreadObserver];
    [self addSecondaryThreadAndObserver];
}

- (void) endMonitor{
    if (!_observer) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

#pragma mark printLogTrace
- (void)printLogTrace{
    NSLog(@"====================堆栈\n %@ \n",_backtrace);
}


#pragma mark addMainThreadObserver
- (void) addMainThreadObserver {
    dispatch_async(dispatch_get_main_queue(), ^{
        //建立自动释放池
        @autoreleasepool {
            //获得当前thread的Run loop
            NSRunLoop *myRunLoop = [NSRunLoop currentRunLoop];
            
            //设置Run loop observer的运行环境
            CFRunLoopObserverContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
            
            //创建Run loop observer对象
            //第一个参数用于分配observer对象的内存
            //第二个参数用以设置observer所要关注的事件，详见回调函数myRunLoopObserver中注释
            //第三个参数用于标识该observer是在第一次进入run loop时执行还是每次进入run loop处理时均执行
            //第四个参数用于设置该observer的优先级
            //第五个参数用于设置该observer的回调函数
            //第六个参数用于设置该observer的运行环境
            _observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, &myRunLoopObserver, &context);
            
            if (_observer) {
                //将Cocoa的NSRunLoop类型转换成Core Foundation的CFRunLoopRef类型
                CFRunLoopRef cfRunLoop = [myRunLoop getCFRunLoop];
                //将新建的observer加入到当前thread的run loop
                CFRunLoopAddObserver(cfRunLoop, _observer, kCFRunLoopDefaultMode);
            }
        }
    });
}

void myRunLoopObserver(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    switch (activity) {
            //The entrance of the run loop, before entering the event processing loop.
            //This activity occurs once for each call to CFRunLoopRun and CFRunLoopRunInMode
        case kCFRunLoopEntry:
            NSLog(@"run loop entry");
            break;
            //Inside the event processing loop before any timers are processed
        case kCFRunLoopBeforeTimers:
            NSLog(@"run loop before timers");
            break;
            //Inside the event processing loop before any sources are processed
        case kCFRunLoopBeforeSources:
            NSLog(@"run loop before sources");
            break;
            //Inside the event processing loop before the run loop sleeps, waiting for a source or timer to fire.
            //This activity does not occur if CFRunLoopRunInMode is called with a timeout of 0 seconds.
            //It also does not occur in a particular iteration of the event processing loop if a version 0 source fires
        case kCFRunLoopBeforeWaiting:{
            _waitStartTime = 0;
            NSLog(@"run loop before waiting");
            break;
        }
            //Inside the event processing loop after the run loop wakes up, but before processing the event that woke it up.
            //This activity occurs only if the run loop did in fact go to sleep during the current loop
        case kCFRunLoopAfterWaiting:{
            _waitStartTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"run loop after waiting");
            break;
        }
            //The exit of the run loop, after exiting the event processing loop.
            //This activity occurs once for each call to CFRunLoopRun and CFRunLoopRunInMode
        case kCFRunLoopExit:
            NSLog(@"run loop exit");
            break;
            /*
             A combination of all the preceding stages
             case kCFRunLoopAllActivities:
             break;
             */
        default:
            break;
    }
}

#pragma mark addSecondaryThreadAndObserver
- (void) addSecondaryThreadAndObserver{
    NSThread *thread = [self secondaryThread];
    [self performSelector:@selector(addSecondaryTimer) onThread:thread withObject:nil waitUntilDone:YES];
}

- (NSThread *)secondaryThread {
    static NSThread *_secondaryThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _secondaryThread =
        [[NSThread alloc] initWithTarget:self
                                selector:@selector(networkRequestThreadEntryPoint:)
                                  object:nil];
        [_secondaryThread start];
    });
    return _secondaryThread;
}

- (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"monitorControllerThread"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
        [runLoop run];
    }
}

- (void) addSecondaryTimer{
    NSTimer *myTimer = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
}

- (void)timerFired:(NSTimer *)timer{
    if ( _waitStartTime < 1 ){
        return;
    }
    double currentTime = [[NSDate date] timeIntervalSince1970];
    double timeDiff = currentTime - _waitStartTime;
    if (timeDiff > 2.0){
        if (_lastRecordTime - _waitStartTime < 0.001 && _lastRecordTime != 0){
            NSLog(@"last time no :%f %f",timeDiff, _waitStartTime);
            return;
        }
        [self logStack];
        _lastRecordTime = _waitStartTime;
    }
}

- (void)logStack{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    _backtrace = [NSMutableArray arrayWithCapacity:frames];
    for ( i = 0 ; i < frames ; i++ ){
        [_backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
}

@end

