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
#import "HZBannerAdOptions.h"

@interface HZBannerAdWrapper()

@property (nonatomic, strong, readonly) HZBannerAdapter *adapter;

@end

@implementation HZBannerAdWrapper
///
- (instancetype)initWithBanner:(HZBannerAdapter *)adapter network:(NSString *const)network {
    NSParameterAssert(adapter);
    NSParameterAssert(network);
    self = [super init];
    if (self) {
        _adapter = adapter;
        _mediatedNetwork = network; // Maybe remove this property and just call out to the underlying adapter
        adapter.reportingDelegate = self;
    }
    return self;
}

+ (instancetype)getWrapperForViewController:(UIViewController *)controller options:(HZBannerAdOptions *)options {
    if (!options) {
        options = [[HZBannerAdOptions alloc] init];
    }
    
    [[HeyzapMediation sharedInstance] requestBannerWithOptions:options completion:^(NSError *error, HZBannerAdapter *adapter) {
        
    }];
    
    HZBannerAdapter *adapter = [[HeyzapMediation sharedInstance] getBannerWithOptions:options];
    return [[self alloc] initWithBanner:adapter network:adapter.networkName];
}

+ (void)requestBannerWithOptions:(HZBannerAdOptions *)options completion:(void (^)(NSError *error, HZBannerAdWrapper *wrapper))completion {
    if (!options) {
        options = [[HZBannerAdOptions alloc] init];
    }
    NSParameterAssert(completion);
    
    NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
    [[HeyzapMediation sharedInstance] requestBannerWithOptions:options completion:^(NSError *error, HZBannerAdapter *adapter) {
        NSLog(@"<%@:%@:%d",[self class],NSStringFromSelector(_cmd),__LINE__);
        if (error) {
            completion(error, nil);
        } else if (adapter) {
            HZBannerAdWrapper *wrapper = [[HZBannerAdWrapper alloc] initWithBanner:adapter network:adapter.networkName];
            completion(nil, wrapper);
        }
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, mediatedNetwork: %@, mediatedBanner: %@>", NSStringFromClass([self class]), self, self.mediatedNetwork, self.mediatedBanner];
}


- (void)didReceiveAd {
    [self.delegate bannerDidReceiveAd];
}

- (void)didFailToReceiveAd:(NSError *)error {
    NSDictionary *const userInfo = error ? @{NSUnderlyingErrorKey: error} : nil;
    return [self.delegate bannerDidFailToReceiveAd:[[NSError alloc] initWithDomain:kHZMediationDomain code:1 userInfo:userInfo]];
}

- (void)userDidClick {
    [self.delegate bannerWasClicked];
}

- (void)willPresentModalView {
    [self.delegate bannerWillPresentModalView];
}

- (void)didDismissModalView {
    [self.delegate bannerDidDismissModalView];
}

- (void)willLeaveApplication {
    [self.delegate bannerWillLeaveApplication];
}

- (UIView *)mediatedBanner {
    return self.adapter.mediatedBanner;
}

@end
