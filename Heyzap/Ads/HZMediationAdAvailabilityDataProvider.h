//
//  HZMediationAdAvailabilityDataProvider.h
//  Heyzap
//
//  Created by Monroe Ekilah on 11/2/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZCreativeType.h"
#import "HZAdType.h"


@protocol HZMediationAdAvailabilityDataProviderProtocol <NSObject>
- (nonnull NSString *) tag;
- (HZCreativeType) creativeType;
- (nullable NSString *) placementIDOverride;
@end


/**
 *  A simple class impelementing the HZMediationAdAvailabilityDataProviderProtocol for inline use when a HZMediationAdAvailabilityDataProviderProtocol object is not available.
 */
@interface HZMediationAdAvailabilityDataProvider : NSObject <HZMediationAdAvailabilityDataProviderProtocol>

@property (nonnull, nonatomic) NSString *tag;
@property (nonatomic) HZCreativeType creativeType;
@property (nullable, nonatomic) NSString *placementIDOverride;


- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(nullable NSString *)placementIDOverride tag:(nonnull NSString *)tag;

// these other initializers provided to make inlining this protocol-abiding class easier.
- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType; // uses the default tag & nil placementIDOverride
- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag; // uses nil placementIDOverride
- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(nullable NSString *)placementIDOverride; // uses the default tag

@end