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
    HZParameterAssert(error != NULL);
    self = [super init];
    if (self) {
        
        // Private properties
        _impressionID = [HZDictionaryUtils objectForKey:@"impression_id" ofClass:[NSString class] dict:dictionary];
        CHECK_NOT_NIL(_impressionID,@"Impression ID");
        
        _promotedGameAppStoreID = [HZDictionaryUtils objectForKey:@"promoted_game_package" ofClass:[NSNumber class] dict:dictionary];
        CHECK_NOT_NIL(_promotedGameAppStoreID,@"advertised game App Store ID");
        
        _clickURL = ({
            NSString *clickURLString = [HZDictionaryUtils objectForKey: @"click_url" ofClass: [NSString class] dict: dictionary];
            NSString *noPlaceHolderURL = [HZNSURLUtils substituteGetParams:clickURLString impressionID:_impressionID];
            [NSURL URLWithString:noPlaceHolderURL];
        });
        
        _tag = [HZDictionaryUtils objectForKey:@"tag" ofClass:[NSString class] dict:dictionary];
        
        // Developer Visible properties
        NSDictionary *const publicDictionary = [HZDictionaryUtils objectForKey:@"data" ofClass:[NSDictionary class] dict:dictionary];
        _rawResponse = publicDictionary;
        
        // Non-nil properties
        _appName = [HZDictionaryUtils objectForKey:kHZNativeAdAppNameKey ofClass:[NSString class] dict:publicDictionary];
        CHECK_NOT_NIL(_appName, @"advertised app name");

        _iconURL = [NSURL URLWithString:[HZDictionaryUtils objectForKey:kHZNativeAdIconURLKey ofClass:[NSString class] dict:publicDictionary]];
        CHECK_NOT_NIL(_iconURL, @"icon URL");
        
        /// Nullable properties
        
        // Large creatives
        NSError *error;
        
        NSDictionary *landscapeImageDict = [HZDictionaryUtils objectForKey:@"landscape_image" ofClass:[NSDictionary class] dict:publicDictionary];
        _landscapeCreative = [[HZNativeAdImage alloc] initWithDictionary:landscapeImageDict error:&error];
        
        NSDictionary *portraitImageDict = [HZDictionaryUtils objectForKey:@"portrait_image" ofClass:[NSDictionary class] dict:publicDictionary];
        _portraitCreative = [[HZNativeAdImage alloc] initWithDictionary:portraitImageDict error:&error];
        
        
        _rating = ({
            NSString *ratingString = [HZDictionaryUtils objectForKey:kHZNativeAdRatingKey ofClass:[NSString class] dict:publicDictionary];
            ratingString ? [NSNumber numberWithFloat:[ratingString floatValue]] : nil;
        });
        _category = [HZDictionaryUtils objectForKey:kHZNativeAdCategoryKey ofClass:[NSString class] dict:publicDictionary];
        _appDescription = [HZDictionaryUtils objectForKey:kHZNativeAdDescriptionKey ofClass:[NSString class] dict:publicDictionary];
        _developerName = [HZDictionaryUtils objectForKey:kHZNativeAdDeveloperNameKey ofClass:[NSString class] dict:publicDictionary];
    }
    return self;
}

- (NSDictionary *)eventParams {
    return @{@"impression_id": self.impressionID,
             @"promoted_game_package": self.promotedGameAppStoreID,
             @"tag": [HZAdModel normalizeTag: self.tag]};
}

- (void)reportImpression {
    HZVersionCheck()

    if (self.sentImpression) {
        return;
    }
    
    [[HZAdsAPIClient sharedClient] POST:kHZRegisterImpressionEndpoint parameters:[self eventParams] success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
        self.sentImpression = YES;
    } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
        [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
    }];
}

- (SKStoreProductViewController *)presentAppStoreFromViewController:(UIViewController *)viewController
                            storeDelegate:(id<SKStoreProductViewControllerDelegate>)storeDelegate
                               completion:(void (^)(BOOL result, NSError *error))completion {
    
    HZVersionCheckNil()

    if (!self.sentClick) {
        [[HZAdsAPIClient sharedClient] POST:kHZRegisterClickEndpoint parameters:[self eventParams] success:^(HZAFHTTPRequestOperation *operation, id responseObject) {
            self.sentClick = YES;
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            [HZLog debug: [NSString stringWithFormat: @"(IMPRESSION ERROR) %@, Error: %@", self, error]];
        }];
    }
    
    return [[HZStorePresenter sharedInstance] presentAppStoreForID:self.promotedGameAppStoreID
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
