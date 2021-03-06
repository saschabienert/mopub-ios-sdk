//
//  HZMediationSettings.h
//  Heyzap
//
//  Created by Monroe Ekilah on 7/23/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZMediationSettings : NSObject

@property (nonatomic, readonly) NSNumber *incentivizedDailyLimit;
@property (nonatomic, readonly) NSDictionary *remoteDataDictionary;
@property (nonatomic, readonly) NSSet<NSString *> *disabledTags;
@property (nonatomic, readonly) NSTimeInterval IAPAdsTimeOut;
@property (nonatomic, readonly) NSString *remoteDataJsonString;

extern NSString * const kHZMediationUserDefaultsKeyIncentivizedCounter;
extern NSString * const kHZMediationUserDefaultsKeyIncentivizedDate;

- (void) setupWithDict:(NSDictionary *)dict fromCache:(BOOL)fromCache;
- (BOOL) tagIsEnabled:(NSString *)tag;
- (BOOL) shouldAllowIncentivizedAd;
- (void) incentivizedAdShown;
- (void) startIAPAdsTimeOut;
@end