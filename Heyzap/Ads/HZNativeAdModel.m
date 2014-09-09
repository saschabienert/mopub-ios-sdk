//
//  HZNativeAdModel.m
//  Heyzap
//
//  Created by Maximilian Tagher on 9/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNativeAdModel.h"
#import "HZDictionaryUtils.h"
#import "HZAdModel.h"
#import "HZAdsAPIClient.h"
#import "HZLog.h"
#import "HZStorePresenter.h"
@import StoreKit;

NSString *const kHZNativeAdCategoryKey = @"category";
NSString *const kHZNativeAdDescriptionKey = @"description";
NSString *const kHZNativeAdDeveloperNameKey = @"developer_name";
NSString *const kHZNativeAdAppNameKey = @"display_name";
NSString *const kHZNativeAdIconURLKey = @"icon_uri";
NSString *const kHZNativeAdRatingKey = @"rating";

@interface HZNativeAdModel()

@property (nonatomic, readonly) NSString *impressionID;
@property (nonatomic, readonly) NSNumber *promotedGameAppStoreID;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSURL *clickURL;

@property (nonatomic) BOOL sentImpression;
@property (nonatomic) BOOL sentClick;


@end

@implementation HZNativeAdModel

#define CHECK_NOT_NIL(value) do { \
if (value == nil) { \
return nil; \
} \
} while (0)

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        
        // Private properties
        _impressionID = [HZDictionaryUtils hzObjectForKey:@"impression_id" ofClass:[NSString class] withDict:dictionary];
        CHECK_NOT_NIL(_impressionID);
        
        _promotedGameAppStoreID = [HZDictionaryUtils hzObjectForKey:@"promoted_game_package" ofClass:[NSNumber class] withDict:dictionary];
        CHECK_NOT_NIL(_promotedGameAppStoreID);
        
        _clickURL = [NSURL URLWithString:[HZDictionaryUtils hzObjectForKey:@"click_url" ofClass:[NSString class] withDict:dictionary]];
        CHECK_NOT_NIL(_clickURL);
        
        _tag = [HZDictionaryUtils hzObjectForKey:@"tag" ofClass:[NSString class] withDict:dictionary];
        
        // Developer Visible properties
        NSDictionary *const publicDictionary = [HZDictionaryUtils hzObjectForKey:@"data" ofClass:[NSDictionary class] withDict:dictionary];
        _rawResponse = publicDictionary;
        
        // Non-nil properties
        _appName = [HZDictionaryUtils hzObjectForKey:kHZNativeAdAppNameKey ofClass:[NSString class] withDict:publicDictionary];
        CHECK_NOT_NIL(_appName);

        _iconURL = [NSURL URLWithString:[HZDictionaryUtils hzObjectForKey:kHZNativeAdIconURLKey ofClass:[NSString class] withDict:publicDictionary]];
        CHECK_NOT_NIL(_iconURL);

        _rating = [NSNumber numberWithFloat:[[HZDictionaryUtils hzObjectForKey:kHZNativeAdRatingKey ofClass:[NSString class] withDict:publicDictionary] floatValue]];
        CHECK_NOT_NIL(_rating);
        
        // Nullable properties
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
