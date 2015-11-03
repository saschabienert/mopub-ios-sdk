//
//  HZMediationAdAvailabilityDataProvider.m
//  Heyzap
//
//  Created by Monroe Ekilah on 11/2/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZMediationAdAvailabilityDataProvider.h"


@implementation HZMediationAdAvailabilityDataProvider

- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(nullable NSString *)placementIDOverride tag:(nonnull NSString *)tag {
    self = [super init];
    if (self) {
        _tag = tag;
        _creativeType = creativeType;
        _placementIDOverride = placementIDOverride;
    }
    
    return self;
}

- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType {
    return [self initWithCreativeType:creativeType placementIDOverride:nil tag:[HeyzapAds defaultTagName]];
}

- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType placementIDOverride:(NSString *)placementIDOverride {
    return [self initWithCreativeType:creativeType placementIDOverride:placementIDOverride tag:[HeyzapAds defaultTagName]];
}

- (nullable instancetype) initWithCreativeType:(HZCreativeType)creativeType tag:(NSString *)tag {
    return [self initWithCreativeType:creativeType placementIDOverride:nil tag:tag];
}

@end