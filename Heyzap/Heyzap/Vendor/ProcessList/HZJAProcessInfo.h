//
//  JAProcessInfo.h
//  HeyZap
//
//  Created by Andrew Evans on 5/18/11.
//  Copyright 2011 Smart Balloon, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZJAProcessInfo : NSObject {
    int numberOfProcesses;
    NSMutableArray *processList;
}

- (id) init;
- (int)numberOfProcesses;
- (NSArray *)processList;
- (void)obtainFreshProcessList;
- (BOOL)findProcessWithName:(NSString *)procNameToSearch;

@end