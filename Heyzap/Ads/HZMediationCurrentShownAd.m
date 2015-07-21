//
//  HZMediationCurrentShownAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationCurrentShownAd.h"

@implementation HZMediationCurrentShownAd

- (instancetype)initWithEventReporter:(HZMediationEventReporter *)eventReporter adapter:(HZBaseAdapter *)adapter options:(HZShowOptions *)options {
    HZParameterAssert(eventReporter);
    HZParameterAssert(adapter);
    self = [super init];
    if (self) {
        _eventReporter = eventReporter;
        _tag = options.tag;
        _adapter = adapter;
        _adState = HZAdStateRequestedShow;
        _showOptions = options;
    }
    return self;
}

@end
