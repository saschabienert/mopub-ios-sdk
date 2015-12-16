//
//  HZGADNativeAd.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/16/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZClassProxy.h"

@protocol HZGADNativeAdDelegate;

@interface HZGADNativeAd : HZClassProxy

/// Optional delegate to receive state change notifications.
@property(nonatomic, weak) id<HZGADNativeAdDelegate> delegate;

/// Root view controller for handling ad actions.
@property(nonatomic, weak) UIViewController *rootViewController;

/// Dictionary of assets which aren't processed by the receiver.
@property(nonatomic, readonly, copy) NSDictionary *extraAssets;

/// The ad network class name that fetched the current ad. For both standard and mediated Google
/// AdMob ads, this method returns @"GADMAdapterGoogleAdMobAds". For ads fetched via mediation
/// custom events, this method returns @"GADMAdapterCustomEvents".
@property(nonatomic, readonly, copy) NSString *adNetworkClassName;

@end
