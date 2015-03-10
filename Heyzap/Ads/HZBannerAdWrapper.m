//
//  HZBannerAdWrapper.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdWrapper.h"
#import "HZMediationConstants.h"

@implementation HZBannerAdWrapper

- (instancetype)initWithBanner:(HZBannerAdapter *)adapter network:(NSString *const)network {
    self = [super init];
    if (self) {
//        _mediatedBanner = banner;
        _mediatedNetwork = network;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, mediatedNetwork: %@, mediatedBanner: %@>", NSStringFromClass([self class]), self, self.mediatedNetwork, self.mediatedBanner];
}


- (void)didReceiveAd {
    [self.delegate didReceiveAd];
}

- (void)didFailToReceiveAd:(NSError *)error {
    NSDictionary *const userInfo = error ? @{NSUnderlyingErrorKey: error} : nil;
    return [self.delegate didFailToReceiveAd:[[NSError alloc] initWithDomain:kHZMediationDomain code:1 userInfo:userInfo]];
}

- (void)userDidClick {
    [self.delegate userDidClick];
}

- (void)willPresentModalView {
    [self.delegate willPresentModalView];
}

- (void)didDismissModalView {
    [self.delegate didDismissModalView];
}

- (void)willLeaveApplication {
    [self.delegate willLeaveApplication];
}

@end
