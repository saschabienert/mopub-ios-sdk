//
//  HZMediationCurrentShownAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZShowOptions.h"

@class HZBaseAdapter;
@class HZMediationEventReporter;

typedef NS_ENUM(NSUInteger, HZAdState) {
    HZAdStateRequestedShow,
    HZAdStateShown,
};

@interface HZMediationCurrentShownAd : NSObject

@property (nonatomic, readonly) HZMediationEventReporter *eventReporter;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) HZBaseAdapter *adapter;
@property (nonatomic) HZAdState adState; // Mutable
@property (nonatomic, readonly) HZShowOptions *showOptions;

- (instancetype)initWithEventReporter:(HZMediationEventReporter *)eventReporter adapter:(HZBaseAdapter *)adapter withOptions:(HZShowOptions *)options;

@end
