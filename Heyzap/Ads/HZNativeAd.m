//
//  HZNativeAd.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNativeAd.h"
#import "HZDictionaryUtils.h"
#import "HZAdModel.h"
#import "HZAdsAPIClient.h"
#import "HZLog.h"
#import "HZStorePresenter.h"
#import "HZNSURLUtils.h"
#import "HZNativeAdImage.h"
#import "HZNativeAdImage_Private.h"
#import "HZInitMacros.h"
#import "HZAdsManager.h"

@import StoreKit;

NSString *const kHZNativeAdCategoryKey = @"category";
NSString *const kHZNativeAdDescriptionKey = @"description";
NSString *const kHZNativeAdDeveloperNameKey = @"developer_name";
NSString *const kHZNativeAdAppNameKey = @"display_name";
NSString *const kHZNativeAdIconURLKey = @"icon_uri";
NSString *const kHZNativeAdRatingKey = @"rating";

@interface HZNativeAd()

@property (nonatomic, readonly) NSString *impressionID;
@property (nonatomic, readonly) NSNumber *promotedGameAppStoreID;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSURL *clickURL;

@property (nonatomic) BOOL sentImpression;
@property (nonatomic) BOOL sentClick;


@end

@implementation HZNativeAd

// Errors *must* have an NSLocalizedFailureReasonKey
- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    NSParameterAssert(error != NULL);
    self = [super init];
    if (self) {
        
        // Private properties
        _impressionID = [HZDictionaryUtils hzObjectForKey:@"impression_id" ofClass:[NSString class] withDict:dictionary];
        CHECK_NOT_NIL(_impressionID,@"Impression ID");
        
        _promotedGameAppStoreID = [HZDictionaryUtils hzObjectForKey:@"promoted_game_package" ofClass:[NSNumber class] withDict:dictionary];
        CHECK_NOT_NIL(_promotedGameAppStoreID,@"advertised game App Store ID");
        
        _clickURL = ({
            NSString *clickURLString = [HZDictionaryUtils hzObjectForKey: @"click_url" ofClass: [NSString class] withDict: dictionary];
            NSString *noPlaceHolderURL = [HZNSURLUtils substituteGetParams:clickURLString impressionID:_impressionID];
            [NSURL URLWithString:noPlaceHolderURL];
        });
        
        _tag = [HZDictionaryUtils hzObjectForKey:@"tag" ofClass:[NSString class] withDict:dictionary];
        
        // Developer Visible properties
        NSDictionary *const publicDictionary = [HZDictionaryUtils hzObjectForKey:@"data" ofClass:[NSDictionary class] withDict:dictionary];
        _rawResponse = publicDictionary;
        
        // Non-nil properties
        _appName = [HZDictionaryUtils hzObjectForKey:kHZNativeAdAppNameKey ofClass:[NSString class] withDict:publicDictionary];
        CHECK_NOT_NIL(_appName, @"advertised app name");

        _iconURL = [NSURL URLWithString:[HZDictionaryUtils hzObjectForKey:kHZNativeAdIconURLKey ofClass:[NSString class] withDict:publicDictionary]];
        CHECK_NOT_NIL(_iconURL, @"icon URL");
        
        /// Nullable properties
        
        // Large creatives
        NSError *error;
        
        NSDictionary *landscapeImageDict = [HZDictionaryUtils hzObjectForKey:@"landscape_image" ofClass:[NSDictionary class] withDict:publicDictionary];
        _landscapeCreative = [[HZNativeAdImage alloc] initWithDictionary:landscapeImageDict error:&error];
        
        NSDictionary *portraitImageDict = [HZDictionaryUtils hzObjectForKey:@"portrait_image" ofClass:[NSDictionary class] withDict:publicDictionary];
        _portraitCreative = [[HZNativeAdImage alloc] initWithDictionary:portraitImageDict error:&error];
        
        
        _rating = ({
            NSString *ratingString = [HZDictionaryUtils hzObjectForKey:kHZNativeAdRatingKey ofClass:[NSString class] withDict:publicDictionary];
            ratingString ? [NSNumber numberWithFloat:[ratingString floatValue]] : nil;
        });
        _category = [HZDictionaryUtils hzObjectForKey:kHZNativeAdCategoryKey ofClass:[NSString class] withDict:publicDictionary];
        _appDescription = [HZDictionaryUtils hzObjectForKey:kHZNativeAdDescriptionKey ofClass:[NSString class] withDict:publicDictionary];
        _developerName = [HZDictionaryUtils hzObjectForKey:kHZNativeAdDeveloperNameKey ofClass:[NSString class] withDict:publicDictionary];
    }
    return self;
}

- (NSDictionary *)eventParams {
    return @{@"impression_id": self.impressionID,
             @"promoted_game_package": self.promotedGameAppStoreID,
             @"tag": [HZAdModel normalizeTag: self.tag]};
}

- (void)reportImpression {
    HZVersionCheck

    if (self.sentImpression) {
        return;
    }
    
    [[HZAdsAPIClient sharedClient] post:kHZRegisterImpressionEndpoint
                             withParams:[self eventParams]
                                success:^(id JSON) {
        self.sentImpression = YES;
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
    }];
}

- (void)presentAppStoreFromViewController:(UIViewController *)viewController
                            storeDelegate:(id<SKStoreProductViewControllerDelegate>)storeDelegate
                               completion:(void (^)(BOOL result, NSError *error))completion {
    
    HZVersionCheck

    if (!self.sentClick) {
        [[HZAdsAPIClient sharedClient] post: kHZRegisterClickEndpoint withParams:[self eventParams] success:^(id JSON) {
            self.sentClick = YES;
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
        }];
    }
    
    [[HZStorePresenter sharedInstance] presentAppStoreForID:self.promotedGameAppStoreID
                                   presentingViewController:viewController
                                                   delegate:storeDelegate
                                           useModalAppStore:YES
                                                   clickURL:self.clickURL
                                               impressionID:self.impressionID
                                                 completion:completion];
}

#pragma mark - Util

- (NSString *)description {
    NSMutableString *const desc = [[NSMutableString alloc] initWithString:[super description]];
    [desc appendFormat:@" `appName` = %@",self.appName];
    [desc appendFormat:@" `iconURL` = %@",self.iconURL];
    [desc appendFormat:@" `rating` = %@",self.rating];
    [desc appendFormat:@" `category` = %@",self.category];
    [desc appendFormat:@" `description` = %@",self.appDescription];
    [desc appendFormat:@" `developerName` = %@",self.developerName];
    return desc;
}

@end
