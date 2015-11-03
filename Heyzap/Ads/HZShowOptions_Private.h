//
//  HZShowOptions_Private.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/19/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZShowOptions.h"
#import "HZAdType.h"

@interface HZShowOptions()<HZMediationAdAvailabilityDataProviderProtocol>

@property (nonatomic) HZAdType requestingAdType;
@property (nonatomic) HZCreativeType creativeType;
@property (nonatomic, nullable) NSString *placementIDOverride;

@end