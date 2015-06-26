//
//  HZMediationCurrentShownAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationCurrentShownAd.h"

@implementation HZMediationCurrentShownAd

- (instancetype)initWithSession:(HZMediationSession *)session tag:(NSString *)tag adapter:(HZBaseAdapter *)adapter {
    HZParameterAssert(session);
    HZParameterAssert(adapter);
    self = [super init];
    if (self) {
        _session = session;
        _tag = tag;
        _adapter = adapter;
        _adState = HZAdStateRequestedShow;
    }
    return self;
}

@end
