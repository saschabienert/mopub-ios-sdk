//
//  AppLovinDelegate.m
//  Heyzap
//
//  Created by Maximilian Tagher on 4/11/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZAppLovinDelegate.h"
#import "HZBaseAdapter.h"
#import "HZAppLovinAdapter.h"
#import "HZMediationConstants.h"

@interface HZAppLovinDelegate()

@property (nonatomic) HZAdType adType;
@property (nonatomic, weak) id<HZAppLovinDelegateReceiver>delegate;

@end

@implementation HZAppLovinDelegate

- (id)initWithAdType:(HZAdType)adType delegate:(id<HZAppLovinDelegateReceiver>)delegate
{
    self = [super init];
    if (self) {
        
        _adType = adType;
        _delegate = delegate;
    }
    return self;
}

#pragma mark - App Lovin Delegation

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    
    if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ALAdLoadDelegate"]) {
        return YES;
    } else if ([NSStringFromProtocol(aProtocol) isEqualToString:@"ALAdDisplayDelegate"]) {
        return YES;
    } else {
        return [super conformsToProtocol:aProtocol];
    }
}

#pragma mark - Ad Load Delegate

- (void)adService:(HZALAdService *)adService didLoadAd:(HZALAd *)ad
{
    // did load ad for type
    
    [self.delegate didLoadAdOfType:self.adType];
}

- (void)adService:(HZALAdService *)adService didFailToLoadAdWithError:(int)code
{
    
    [self.delegate didFailToLoadAdOfType:self.adType
                                   error:[NSError errorWithDomain:kHZMediationDomain code:code userInfo:nil]];
}

#pragma mark - Display Delegate

- (void)ad:(HZALAd *)ad wasDisplayedIn:(UIView *)view
{
    // ignored
}

- (void)ad:(HZALAd *)ad wasHiddenIn:(UIView *)view
{
    [self.delegate didDismissAd];
}

- (void)ad:(HZALAd *)ad wasClickedIn:(UIView *)view
{
    [self.delegate didClickAd];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    
    return [super respondsToSelector:aSelector];
}

@end
