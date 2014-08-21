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

@property (nonatomic, readonly) NSString *impressionID;
@property (nonatomic, readonly) NSNumber *promotedGamePackage;
@property (nonatomic, readonly) NSString *creativeType;
@property (nonatomic, readonly) NSURL *clickURL;

@property (nonatomic, readonly) NSURL *launchURI;
@property (nonatomic, assign, readonly) BOOL useModalAppStore;
@property (nonatomic) NSString *tag;
@property (nonatomic) NSString *adUnit;
@property (nonatomic, readonly) int requiredAdOrientation;

@property (nonatomic) BOOL sentClick;
@property (nonatomic) BOOL sentImpression;
@property (nonatomic) BOOL sentIncentiveComplete;

#pragma mark - Initializers
- (id) initWithDictionary: (NSDictionary *) dict adUnit:(NSString *)adUnit;

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
+ (HZAdModel *) modelForResponse: (NSDictionary *) response adUnit:(NSString *)adUnit;

#pragma mark - Actions
- (void) doPostFetchActionsWithCompletion: (void (^)(BOOL result))completion;

#pragma mark - Cleanup
- (void) cleanup;

#pragma mark - Other
- (NSMutableDictionary *) paramsForEventCallback;
- (void) setEventCallbackParams: (NSMutableDictionary *) dict;

+ (NSString *) normalizeTag: (NSString *) tag;
- (void)sendInitializationMetrics;

@end
