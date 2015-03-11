//
//  HZBannerAdWrapper.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/6/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBannerAdWrapper.h"
#import "HZMediationConstants.h"
#import "HeyzapMediation.h"
#import "HZBannerAdapter.h"

@interface HZBannerAdWrapper()

@property (nonatomic, strong, readonly) HZBannerAdapter *adapter;

@end

@implementation HZBannerAdWrapper
///
- (instancetype)initWithBanner:(HZBannerAdapter *)adapter network:(NSString *const)network {
    self = [super init];
    if (self) {
        _adapter = adapter;
        _mediatedNetwork = network;
    }
    return self;
}

+ (instancetype)getWrapperForViewController:(UIViewController *)controller {
    HZBannerAdapter *adapter = [[HeyzapMediation sharedInstance] getBannerWithRootViewController:controller];
    return [[self alloc] initWithBanner:adapter network:@"facebook"];
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

- (UIView *)mediatedBanner {
    return self.adapter.mediatedBanner;
}

@end
