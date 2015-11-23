//
//  HZMediatedNativeAdManager.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZFetchOptions.h"

@class HZMediatedNativeAd;

@interface HZMediatedNativeAdManager : NSObject

+ (void)fetchNativeAdWithOptions:(HZFetchOptions *)fetchOptions;
+ (HZMediatedNativeAd *)getNextNativeAdForTag:(NSString *)tag error:(NSError **)error;

@end
