//
//  HZAdapterDelegate.h
//  Heyzap
//
//  Created by Mike Urbach on 3/31/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"
#import "HZFBInterstitialAd.h"
#import "HZUnityAds.h"
#import "HZAppLovinDelegateReceiver.h"
#import "HZVungleSDK.h"
#import "HZAdColony.h"
#import "HZGADInterstitial.h"
#import <iAd/iAd.h>

@class HZBaseAdapter;

@interface HZAdapterDelegate : NSObject <ADInterstitialAdDelegate, HZFBInterstitialAdDelegate, HZUnityAdsDelegate, HZAppLovinDelegateReceiver, HZVungleSDKDelegate, HZAdColonyDelegate, HZGADInterstitialDelegate>

@property (nonatomic, strong) HZBaseAdapter *adapter;

@end
