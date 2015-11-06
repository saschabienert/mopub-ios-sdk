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
 *  A simple class implementing the HZMediationAdAvailabilityDataProviderProtocol for inline use when an object that implements the HZMediationAdAvailabilityDataProviderProtocol protocol is not already available.
 */
@interface HZMediationAdAvailabilityDataProvider : NSObject <HZMediationAdAvailabilityDataProviderProtocol>

@property (nonnull, nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) HZCreativeType creativeType;
@property (nullable, nonatomic, readonly) NSString *placementIDOverride;


- (nonnull instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(nullable NSString *)placementIDOverride tag:(nonnull NSString *)tag;

// these other initializers provided to make inlining this protocol-abiding class easier.
// ONLY use the shortcut initializers in situations where you know you do not care about one or more of the properties (i.e., in adapters, you'll never care about ad tags, and most adapters will also not care about placement ID overrides.)
// otherwise, you should populate all the fields with the verbose initializer
- (nonnull instancetype) initWithCreativeType:(HZCreativeType)creativeType; // uses the default tag & nil placementIDOverride
- (nonnull instancetype) initWithCreativeType:(HZCreativeType)creativeType tag:(nonnull NSString *)tag; // uses nil placementIDOverride
- (nonnull instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(nullable NSString *)placementIDOverride; // uses the default tag

@end