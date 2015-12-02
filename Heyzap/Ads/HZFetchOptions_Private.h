//
//  HZFetchOptions_Private.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/20/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZFetchOptions.h"
#import "HZAdType.h"

extern NSString * _Nonnull const kHZGADAdLoaderAdTypeNativeAppInstall;
extern NSString * _Nonnull const kHZGADAdLoaderAdTypeNativeContent;

@interface HZFetchOptions()

@property (nonatomic) HZAdType requestingAdType;
@property (nonatomic, nullable) NSDictionary *additionalParameters;
@property (nonatomic, nullable) NSString *placementIDOverride;

@end


