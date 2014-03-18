//
//  HZAdModel.h
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HZAdModel : NSObject

@property (nonatomic) NSString *impressionID;
@property (nonatomic) NSNumber *promotedGamePackage;
@property (nonatomic) NSString *creativeType;
@property (nonatomic) NSURL *clickURL;
@property (nonatomic) NSNumber *refreshTime;
@property (nonatomic) NSString *adStrategy;
@property (nonatomic) NSNumber *creativeID;
@property (nonatomic) NSURL *launchURI;
@property (nonatomic, assign) BOOL useModalAppStore;
@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *adUnit;
@property (nonatomic, readonly) BOOL hideOnOrientationChange;
@property (nonatomic, readonly) int requiredAdOrientation;
@property (nonatomic) NSDate *fetchDate;

@property (nonatomic, assign) BOOL sentClick;
@property (nonatomic, assign) BOOL sentImpression;
@property (nonatomic, assign) BOOL sentIncentiveComplete;

#pragma mark - Initializers
- (id) initWithDictionary: (NSDictionary *) dict;

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
+ (HZAdModel *) modelForResponse: (NSDictionary *) response;

#pragma mark - Actions
- (void) doPostFetchActionsWithCompletion: (void (^)(BOOL result))completion;

#pragma mark - Cleanup
- (void) cleanup;

#pragma mark - Other
- (NSMutableDictionary *) paramsForEventCallback;
- (void) setEventCallbackParams: (NSMutableDictionary *) dict;

+ (NSString *) normalizeTag: (NSString *) tag;

@end
