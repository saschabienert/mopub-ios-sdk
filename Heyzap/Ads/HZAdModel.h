//
//  HZAdModel.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HZCreativeType.h"
#import "HZAdType.h"

@interface HZAdModel : NSObject <HZAdInfoProvider>

@property (nonatomic, readonly) NSString *impressionID;
@property (nonatomic, readonly) NSNumber *promotedGamePackage;
@property (nonatomic, readonly) NSString *creativeType;
@property (nonatomic, readonly) NSURL *clickURL;

@property (nonatomic, readonly) NSURL *launchURI;
@property (nonatomic, readonly) BOOL useModalAppStore;
@property (nonatomic) HZFetchableCreativeType fetchableCreativeType;
@property (nonatomic, readonly) HZAuctionType auctionType;
@property (nonatomic, readonly) int requiredAdOrientation;

// Properties set on show.
@property (nonatomic) HZAdType requestingAdType;
@property (nonatomic) NSString *tag;

@property (nonatomic) BOOL sentClick;
@property (nonatomic) BOOL sentImpression;
@property (nonatomic) BOOL sentIncentiveComplete;

// iOS 8 Server Side Configurable Properties
@property (nonatomic, readonly) BOOL enable90DegreeTransform;

#pragma mark - Initializers
- (instancetype) initWithDictionary: (NSDictionary *) dict fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;

#pragma mark - Validity
+ (BOOL) isResponseValid:(NSDictionary *)response withError: (NSError **) error;
+ (BOOL) isValidForCreativeType: (NSString *) creativeType;

#pragma mark - Expiry
- (BOOL) isExpired;

#pragma mark - Attribution
- (BOOL) isInstalled;
- (BOOL) onImpression;
- (BOOL) onClick;

#pragma mark - Controller
- (Class) controller;

#pragma mark - Factory
+ (HZAdModel *) modelForResponse: (NSDictionary *) response fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType;

#pragma mark - Actions
- (void) doPostFetchActionsWithCompletion: (void (^)(BOOL result))completion;

#pragma mark - Cleanup
- (void) cleanup;

#pragma mark - Other
- (NSMutableDictionary *) paramsForEventCallback;
- (void) setEventCallbackParams: (NSMutableDictionary *) dict;

+ (NSString *) normalizeTag: (NSString *) tag;

@end
