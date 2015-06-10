/*
 * Copyright (c) 2015, Heyzap, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'Heyzap, Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "HeyzapAds.h"
#import "HZUtils.h"
#import "HZLog.h"
#import "HZAdsManager.h"

#import "HeyzapMediation.h"

#import "HZTestActivityViewController.h"

// Warning: Read first please.
// Do NOT change these values. They are shared
// with the server side and Android.
NSString * const HZNetworkHeyzap = @"heyzap";
NSString * const HZNetworkCrossPromo = @"heyzap_cross_promo";
NSString * const HZNetworkFacebook = @"facebook";
NSString * const HZNetworkUnityAds = @"unityads";
NSString * const HZNetworkAppLovin = @"applovin";
NSString * const HZNetworkVungle = @"vungle";
NSString * const HZNetworkChartboost = @"chartboost";
NSString * const HZNetworkAdColony = @"adcolony";
NSString * const HZNetworkAdMob = @"admob";
NSString * const HZNetworkIAd = @"iad";
NSString * const HZNetworkHyperMX = @"hyprmx";

// Warning! Read first please.
// Do NOT change the values. They are shared
// with the server side and Android.

NSString * const HZNetworkCallbackInitialized = @"initialized";
NSString * const HZNetworkCallbackShow = @"show";
NSString * const HZNetworkCallbackAvailable = @"available";
NSString * const HZNetworkCallbackHide = @"hide";
NSString * const HZNetworkCallbackFetchFailed = @"fetch_failed";
NSString * const HZNetworkCallbackClick = @"click";
NSString * const HZNetworkCallbackDismiss = @"dismiss";
NSString * const HZNetworkCallbackIncentivizedResultIncomplete = @"incentivized_result_incomplete";
NSString * const HZNetworkCallbackIncentivizedResultComplete = @"incentivized_result_complete";
NSString * const HZNetworkCallbackAudioStarting = @"audio_starting";
NSString * const HZNetworkCallbackAudioFinished = @"audio_finished";
NSString * const HZNetworkCallbackBannerLoaded = @"banner-loaded";
NSString * const HZNetworkCallbackBannerClick = @"banner-click";
NSString * const HZNetworkCallbackBannerHide = @"banner-hide";
NSString * const HZNetworkCallbackBannerDismiss = @"banner-dismiss";
NSString * const HZNetworkCallbackBannerFetchFailed = @"banner-fetch_failed";
NSString * const HZNetworkCallbackLeaveApplication = @"leave_application";

// Chartboost Specific
NSString * const HZNetworkCallbackChartboostMoreAppsFetchFailed = @"moreapps-fetch_failed";
NSString * const HZNetworkCallbackChartboostMoreAppsDismiss = @"moreapps-dismiss";
NSString * const HZNetworkCallbackChartboostMoreAppsHide = @"moreapps-hide";
NSString * const HZNetworkCallbackChartboostMoreAppsClick = @"moreapps-click";
NSString * const HZNetworkCallbackChartboostMoreAppsShow = @"moreapps-show";
NSString * const HZNetworkCallbackChartboostMoreAppsAvailable = @"moreapps-available";
NSString * const HZNetworkCallbackChartboostMoreAppsClickFailed = @"moreapps-click_failed";

// Facebook Specific
NSString * const HZNetworkCallbackFacebookLoggingImpression = @"logging_impression";

@implementation HeyzapAds

#define _HZAFNetworking_ALLOW_INVALID_SSL_CERTIFICATES_ @"true"
#define kHZDefaultTagName @"default"

+ (void) startWithPublisherID:(NSString *)publisherID {
    [self startWithPublisherID: publisherID andOptions: HZAdOptionsNone andFramework: nil];
}

+ (void) startWithPublisherID:(NSString *)publisherID andOptions:(HZAdOptions)options {
    [self startWithPublisherID: publisherID andOptions: options andFramework: nil];
}

+ (void) startWithPublisherID:(NSString *)publisherID andOptions:(HZAdOptions)options andFramework:(NSString *)framework {
    HZVersionCheck()

    if (options & HZAdOptionsDisableMedation) {
        [HeyzapMediation forceOnlyHeyzapSDK];
    }
    
    // call start even if we aren't mediating - allows for server config, etc., to still occur
    [[HeyzapMediation sharedInstance] start];
    
    if (framework && ![framework isEqualToString:@""]) {
        [[HZAdsManager sharedManager] setFramework:framework];
    }
        
    [[HZAdsManager sharedManager] setPublisherID: publisherID];
    [[HZAdsManager sharedManager] setOptions: options];
    [[HZAdsManager sharedManager] setIsDebuggable: NO];
    [[HZAdsManager sharedManager] onStart];
}

+ (BOOL) isStarted {
    HZVersionCheckBool()

    return [HZAdsManager isEnabled];
}

+ (void) setDebugLevel:(HZDebugLevel)debugLevel {
    HZVersionCheck()

    [HZLog setDebugLevel: debugLevel];
}

+ (void) setDebug:(BOOL)choice {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setIsDebuggable: choice];
}

+ (void) setOptions: (HZAdOptions) options {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setOptions: options];
}

+ (void) setDelegate: (id<HZAdsDelegate>) delegate {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setInterstitialDelegate: delegate];
    [[HZAdsManager sharedManager] setVideoDelegate: delegate];
}

+ (void) setIncentiveDelegate: (id<HZIncentivizedAdDelegate>) delegate {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setIncentivizedDelegate: delegate];
}

+ (void) setFramework: (NSString *) framework {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setFramework: framework];
}

+ (void) setMediator: (NSString *) mediator {
    HZVersionCheck()

    [[HZAdsManager sharedManager] setMediator: mediator];
}

+ (void)setDelegate:(id)delegate forNetwork:(NSString *)network {
    HZVersionCheck()
    
    if (![HeyzapMediation isOnlyHeyzapSDK]) {
        [[HeyzapMediation sharedInstance] setDelegate:delegate forNetwork:network];
    }
}

+ (void) networkCallbackWithBlock: (void (^)(NSString *network, NSString *callback))block {
    HZVersionCheck()
    
    if (![HeyzapMediation isOnlyHeyzapSDK]) {
        [[HeyzapMediation sharedInstance] setNetworkCallbackBlock: block];
    }
}

+ (BOOL) isNetworkInitialized:(NSString *)network {
    HZVersionCheckBool()
    
    if (![HeyzapMediation isOnlyHeyzapSDK]) {
        return [[HeyzapMediation sharedInstance] isNetworkInitialized:network];
    } else if ([network isEqualToString: HZNetworkHeyzap]) {
        return [HZAdsManager isEnabled];
    } else {
        return NO;
    }
}

+ (NSString *) defaultTagName {
    return kHZDefaultTagName;
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HeyzapAds' is a static class and cannot be instantiated."];
    return nil;
}

+ (void)presentMediationDebugViewController {
    HZVersionCheck()

    [HZTestActivityViewController show];
}

+ (void)pauseExpensiveWork {
    HZVersionCheck();
    [[HeyzapMediation sharedInstance] pauseExpensiveWork];
}
+ (void)resumeExpensiveWork {
    HZVersionCheck();
    [[HeyzapMediation sharedInstance] resumeExpensiveWork];
    
}


@end

