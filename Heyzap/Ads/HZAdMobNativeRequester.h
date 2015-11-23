//
//  HZAdMobNativeRequester.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/29/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HZNativeAdAdapter;
@class HZMediatedNativeAdRequestOptions;

@interface HZAdMobNativeRequester : NSObject

@property (nonatomic, readonly) NSUInteger adCount;

- (nonnull instancetype)initWithNativeAdUnitID:(nonnull NSString *)nativeAdUnitID parentAdapter:(nonnull HZBaseAdapter *)parentAdapter NS_DESIGNATED_INITIALIZER;

- (void)fetchNative:(HZAdapterFetchOptions  * _Nonnull)options;
- (nullable HZNativeAdAdapter *)getNativeOrError:(NSError *  _Nonnull * _Nullable)error metadata:(nonnull id<HZMediationAdAvailabilityDataProviderProtocol>)dataProvider;

@end
