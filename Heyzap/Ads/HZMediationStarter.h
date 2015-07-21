//
//  HZMediationStarter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 5/5/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HZMediationStartStatus) {
    HZMediationStartStatusNotStarted,
    HZMediationStartStatusSuccess,
};

@protocol HZMediationStarting <NSObject>

- (void)startWithDictionary:(NSDictionary *)dictionary fromCache:(BOOL)fromCache;

@end

@interface HZMediationStarter : NSObject

- (instancetype)initWithStartingDelegate:(id<HZMediationStarting>)startingDelegate NS_DESIGNATED_INITIALIZER;

- (void)start;
@property (nonatomic, readonly) HZMediationStartStatus status;
/**
 *  Note: This property will be updated with the /start call from the network after the cached version is used.
 */
@property (nonatomic, readonly) NSDictionary *networkNameToCredentials;

@end
