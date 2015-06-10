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


#import "HZAdsManager.h"
#import "HZAdViewController.h"
#import "HZAdLibrary.h"
#import "HZAdFetchRequest.h"
#import "HZAdsFetchManager.h"

#define HZIncentivizedAdUnit @"incentivized"
#define HZIncentivizedAdCreativeTypes @[@"video", @"interstitial_video"]

#import "HZIncentivizedAd.h"
#import "HeyzapMediation.h"
#import "HZHeyzapIncentivizedAd.h"

@implementation HZIncentivizedAd

#pragma mark - Delegation

+ (void)setDelegate:(id<HZIncentivizedAdDelegate>)delegate
{
    HZVersionCheck()
    
    [[HeyzapMediation sharedInstance] setDelegate:delegate forAdType:HZAdTypeIncentivized];
}

#pragma mark - Showing Ads

+ (void) show {
    [[self class] showForTag:[HeyzapAds defaultTagName]];
}

+ (void)showForTag:(NSString *)tag {
    HZShowOptions *options = [HZShowOptions new];
    options.tag = tag;

    [self showWithOptions:options];
}

+ (void)showWithOptions:(HZShowOptions *)options {
    HZVersionCheck()

    if (!options) {
        options = [HZShowOptions new];
    }

    [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeIncentivized additionalParams:nil options:options];
}

#pragma mark - Fetching Ads

+ (void) fetch {
    [self fetchForTag: [HeyzapAds defaultTagName] withCompletion: nil];
}

+ (void)fetchForTag:(NSString *)tag {
    [[self class] fetchForTag:tag withCompletion:nil];
}

+ (void) fetchWithCompletion:(void (^)(BOOL, NSError *))completion {
    [[self class] fetchForTag:[HeyzapAds defaultTagName] withCompletion:completion];
}

+ (void) fetchForTag: (NSString *) tag withCompletion:(void (^)(BOOL, NSError *))completion
{
    HZVersionCheck()

    [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeIncentivized
                                                 tag:tag
                                    additionalParams:nil
                                          completion:completion];
}

#pragma mark - Querying Status

+ (BOOL) isAvailable {
    return [[self class] isAvailableForTag:[HeyzapAds defaultTagName]];
}

+ (BOOL)isAvailableForTag:(NSString *)tag
{
    HZVersionCheckBool()

    return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeIncentivized tag:tag];
}

#pragma mark - Heyzap specific

+ (void) setUserIdentifier: (NSString *) userIdentifier {
    HZVersionCheck()

    [HZHeyzapIncentivizedAd setUserIdentifier:userIdentifier];
}

+ (void) setCreativeID:(int)creativeID {
    HZVersionCheck()

    [HZHeyzapIncentivizedAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZIncentivizedAd' is a static class and cannot be instantiated."];
    return nil;
}


@end
