//
//  HZLog.m
//  Heyzap
//
//  Created by Daniel Rhodes on 11/30/12.
//
//

#import "HZLog.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static HZDebugLevel kHZGlobalDebugLevel = HZDebugLevelSilent;

@interface HZLog()
+ (void) log: (NSString *) message atDebugLevel: (HZDebugLevel) debugLevel;
@end

@implementation HZLog

+ (void) setDebugLevel:(HZDebugLevel)debugLevel {
    kHZGlobalDebugLevel = debugLevel;
}

#pragma mark - Debug Methods

+ (void) info:(NSString *)message {
    [self log: message atDebugLevel: HZDebugLevelInfo];
}

+ (void) error:(NSString *)message {
    [self log: message atDebugLevel: HZDebugLevelError];
}

+ (void) debug:(NSString *)message {
    [self log: message atDebugLevel: HZDebugLevelVerbose];
}

+ (void) log: (NSString *) message atDebugLevel: (HZDebugLevel) debugLevel {
    if (debugLevel <= kHZGlobalDebugLevel) {
        NSLog(@"[ Heyzap ] %@", message);
    }
}

@end
