//
//  HZMediationCurrentShownAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 6/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZMediationCurrentShownAd.h"

@implementation HZMediationCurrentShownAd

- (instancetype)initWithSessionKey:(HZMediationSessionKey *)key session:(HZMediationSession *)session tag:(NSString *)tag adapter:(HZBaseAdapter *)adapter {
    HZParameterAssert(key);
    HZParameterAssert(session);
//    HZParameterAssert(tag); // TODO: not sure about this
    HZParameterAssert(adapter);
    self = [super init];
    if (self) {
        _key = key;
        _session = session;
        _tag = tag;
        _adapter = adapter;
        _adState = HZAdStateRequestedShow;
    }
    return self;
}

@end
