//
//  HZAdFetchRequest.h
//  Heyzap
//
//  Created by Daniel Rhodes on 1/7/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HZAdFetchRequest : NSObject

@property (nonatomic, readonly) NSUUID *requestID;
@property (nonatomic, assign, readonly) int retriesRemaining;

@property (nonatomic, readonly) NSArray *creativeTypes;
@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, readonly) NSString *tag;

@property (nonatomic) NSString *rejectedImpressionID;
@property (nonatomic) NSNumber *alreadyInstalledGame;

@property (nonatomic) NSDictionary *lastResponse;
@property (nonatomic) NSError *lastError;
@property (nonatomic, getter = createParams) NSDictionary *params;

// Properties used for the test app
@property (nonatomic, readonly, getter = shouldSkipCache) BOOL skipCache;
@property (nonatomic, readonly, getter = shouldIgnoreAlreadyInstalledGame) BOOL ignoreAlreadyInstalledGame;

- (id) initWithCreativeTypes: (NSArray *) creativeTypes adUnit: (NSString *) adUnit tag: (NSString *) tag andAdditionalParams: (NSDictionary *) additionalParams;
- (BOOL) canRetry;
- (void) decrementTries;

@end
