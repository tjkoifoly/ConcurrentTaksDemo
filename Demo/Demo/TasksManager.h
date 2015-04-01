//
//  ThreeManager.h
//  Demo
//
//  Created by NGUYEN CHI CONG on 3/31/15.
//  Copyright (c) 2015 if. All rights reserved.
//

#import <UIKit/UIKit.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface TasksManager : NSObject

@property (atomic, strong) NSMutableArray *list;

+ (id)sharedManager;

- (void)startTasks;
- (void)stopTasks;

- (BOOL)isRunning;

- (void)getBatteryInfoWithComplete:(void (^)(NSString *info))completion;
- (void)getUserLocationInfoWithComplete:(void (^)(NSString *info))completion;

@end
