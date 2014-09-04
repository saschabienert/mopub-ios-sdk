//
//  HZAdFetchRequest.h
//  Heyzap
//
//  Created by Daniel Rhodes on 1/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HZEnums.h"
#import "HZAdInfo.h"

@interface HZAdFetchRequest : NSObject <HZAdInfoProvider>

@property (nonatomic, readonly) NSUUID *requestID;
@property (nonatomic, assign, readonly) int retriesRemaining;

@property (nonatomic, readonly) NSArray *creativeTypes;
@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) HZAuctionType auctionType;

@property (nonatomic) NSString *rejectedImpressionID;
@property (nonatomic) NSNumber *alreadyInstalledGame;

@property (nonatomic) NSDictionary *lastResponse;
@property (nonatomic) NSInteger lastFailingStatusCode;
@property (nonatomic) NSError *lastError;
@property (nonatomic, getter = createParams, readonly) NSDictionary *params;

// Properties used for the test app
@property (nonatomic, readonly, getter = shouldSkipCache) BOOL skipCache;
@property (nonatomic, readonly, getter = shouldIgnoreAlreadyInstalledGame) BOOL ignoreAlreadyInstalledGame;

- (id) initWithCreativeTypes:(NSArray *)creativeTypes
                      adUnit:(NSString *)adUnit
                         tag:(NSString *)tag
                 auctionType:(HZAuctionType)auctionType
         andAdditionalParams:(NSDictionary *)additionalParams;

- (BOOL) canRetry;
- (void) decrementTries;

@end
