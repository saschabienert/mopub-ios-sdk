//
//  HZMediationLoadData.h
//  Heyzap
//
//  Created by Maximilian Tagher on 6/16/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZMediationLoadData : NSObject

@property (nonatomic, readonly) NSUInteger load;
@property (nonatomic, readonly) NSTimeInterval timeout;
@property (nonatomic, readonly) Class adapterClass;
@property (nonatomic, readonly) NSString *networkName;
@property (nonatomic, readonly) NSSet *creativeTypeSet;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error;


@end
