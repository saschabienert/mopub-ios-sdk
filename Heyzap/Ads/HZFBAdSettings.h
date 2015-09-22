//
//  HZFBAdSettings.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/5/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@interface HZFBAdSettings : HZClassProxy

typedef NS_ENUM(NSInteger, HZFBAdLogLevel) {
    HZFBAdLogLevelNone,
    HZFBAdLogLevelNotification,
    HZFBAdLogLevelError,
    HZFBAdLogLevelWarning,
    HZFBAdLogLevelLog,
    HZFBAdLogLevelDebug,
    HZFBAdLogLevelVerbose
};

+ (void) addTestDevice:(NSString *)deviceHash;
+ (void) setLogLevel:(HZFBAdLogLevel)level;
@end
