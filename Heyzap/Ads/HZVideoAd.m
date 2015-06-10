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


#import "HZVideoAd.h"
#import "HZAdsManager.h"
#import "HZAdLibrary.h"
#import "HZAdViewController.h"
#import "HZAdsFetchManager.h"
#import "HZAdFetchRequest.h"
#import "HZAdsAPIClient.h"
#import "HeyzapMediation.h"
#import "HZHeyzapVideoAd.h"

@implementation HZVideoAd

#pragma mark - Delegation

+ (void)setDelegate:(id<HZAdsDelegate>)delegate
{
    HZVersionCheck()

    [[HeyzapMediation sharedInstance] setDelegate:delegate forAdType:HZAdTypeVideo];
}

#pragma mark - Showing

+ (void) show {
    [self showForTag: nil];
}

+ (void) showForTag:(NSString *)tag {
    [self showForTag: tag completion: nil];
}

+ (void)showForTag:(NSString *)tag completion:(void (^)(BOOL result, NSError *error))completion {
    HZShowOptions *options = [HZShowOptions new];
    options.tag = tag;
    options.completion = completion;

    [self showWithOptions:options];
}

+ (void) showWithOptions:(HZShowOptions *)options {
    HZVersionCheck()

    if (!options) {
        options = [HZShowOptions new];
    }

    [[HeyzapMediation sharedInstance] showAdForAdUnitType:HZAdTypeVideo additionalParams:nil options:options];
}

+ (void) showWithCompletion:(void (^)(BOOL result, NSError *error))completion {
    [self showForTag: nil completion: completion];
}

#pragma mark - Fetching


+ (void) fetch {
    [self fetchForTag:nil withCompletion: nil];
}

+ (void) fetchForTag: (NSString *) tag {
    [self fetchForTag: tag withCompletion: nil];
}

+ (void) fetchWithCompletion: (void (^)(BOOL result, NSError *error))completion {
    [self fetchForTag:nil withCompletion:completion];
}

+ (void) fetchForTag:(NSString *)tag withCompletion: (void (^)(BOOL result, NSError *error))completion {
    HZVersionCheck()

    tag = tag ?: [HeyzapAds defaultTagName];

    [[HeyzapMediation sharedInstance] fetchForAdType:HZAdTypeVideo tag:tag additionalParams:nil completion:completion];
}

#pragma mark - Querying

+ (BOOL) isAvailable {
    return [self isAvailableForTag:nil];
}

+ (BOOL) isAvailableForTag: (NSString *) tag {
    HZVersionCheckBool()

    tag = tag ?: [HeyzapAds defaultTagName];

    return [[HeyzapMediation sharedInstance] isAvailableForAdUnitType:HZAdTypeVideo tag:tag];
}

#pragma mark - Heyzap Only

+ (void) setCreativeID:(int)creativeID {
    HZVersionCheck()

    [HZHeyzapVideoAd setCreativeID:creativeID];
}

#pragma mark - Bookkeeping

+ (id)alloc {
    [NSException raise:@"CannotInstantiateStaticClass" format:@"'HZVideoAd' is a static class and cannot be instantiated."];
    return nil;
}

@end
