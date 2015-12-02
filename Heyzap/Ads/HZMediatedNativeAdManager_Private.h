//
//  HZMediatedNativeadManager_Private.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediatedNativeAdManager.h"

@interface HZMediatedNativeAdManager()

+ (HZMediatedNativeAd *)getNextNativeAdForTag:(NSString *)tag additionalParams:(NSDictionary *)additionalParams error:(NSError **)error;

@end
