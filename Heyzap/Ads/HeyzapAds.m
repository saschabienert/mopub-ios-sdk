/*
 * Copyright (c) 2014, Smart Balloon, Inc.
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
 * * Neither the name of 'Smart Balloon, Inc.' nor the names of its contributors
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
#import "HZAnalytics.h"
#import "HZAdsManager.h"

#import "HeyzapMediation.h"

#define _HZAFNetworking_ALLOW_INVALID_SSL_CERTIFICATES_ @"true"
#define kHZDefaultTagName @"default"

@implementation HeyzapAds

+ (void) start {
    [self startWithOptions: HZAdOptionsNone];
}

// Deprecated
+ (void) startWithAppStoreID: (int) appID andOptions: (HZAdOptions) options {
    [self startWithOptions: options];
}

+ (void) startWithOptions:(HZAdOptions)options andFramework: (NSString *) framework {
    [[HZAdsManager sharedManager] setFramework: framework];
    [self startWithOptions: options];
}

+ (void) startWithOptions: (HZAdOptions) options {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [HZAdsManager sharedManager];
        [[HZAdsManager sharedManager] setOptions: options];
        [[HZAdsManager sharedManager] setIsDebuggable: NO];
        [[HZAdsManager sharedManager] onStart];
    } else {
        [[HeyzapMediation sharedInstance] start];
    }
}

+ (BOOL) isStarted {
    return [HZAdsManager isEnabled];
}

+ (void) setDebugLevel:(HZDebugLevel)debugLevel {
    [HZLog setDebugLevel: debugLevel];
}

+ (void) setDebug:(BOOL)choice {
    [[HZAdsManager sharedManager] setIsDebuggable: choice];
}

+ (void) setOptions: (HZAdOptions) options {
    [[HZAdsManager sharedManager] setOptions: options];
}

+ (void) setDelegate: (id<HZAdsDelegate>) delegate {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [[HZAdsManager sharedManager] setStatusDelegate: delegate];
    } else {
        [[HeyzapMediation sharedInstance] setDelegate:delegate];
    }
}

+ (void) setIncentiveDelegate: (id<HZIncentivizedAdDelegate>) delegate {
    if ([HeyzapMediation isOnlyHeyzapSDK]) {
        [[HZAdsManager sharedManager] setIncentivizedDelegate: delegate];
    } else {
        [[HeyzapMediation sharedInstance] setIncentiveDelegate:delegate];
    }
}

+ (void) setFramework: (NSString *) framework {
    [[HZAdsManager sharedManager] setFramework: framework];
}

+ (void) setMediator: (NSString *) mediator {
    [[HZAdsManager sharedManager] setMediator: mediator];
}

+ (NSString *) defaultTagName {
    return kHZDefaultTagName;
}

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HeyzapAds' is a static class and cannot be instantiated."];
    return nil;
}


@end