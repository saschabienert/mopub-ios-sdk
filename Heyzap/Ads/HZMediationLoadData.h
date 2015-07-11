//
//  HZMediationLoadData.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZAdType.h"

typedef NS_OPTIONS(NSUInteger, HZCreativeType) {
    HZCreativeTypeUnknown = 1 << 0,
    HZCreativeTypeStatic = 1 << 1,
    HZCreativeTypeVideo = 1 << 2,
    HZCreativeTypeIncentivized = 1 << 3,
};


@interface HZMediationLoadData : NSObject

@property (nonatomic, readonly) NSUInteger load;
@property (nonatomic, readonly) NSTimeInterval timeout;
@property (nonatomic, readonly) Class adapterClass;
@property (nonatomic, readonly) NSString *networkName;
@property (nonatomic, readonly) NSSet *creativeTypeSet;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;


@end
