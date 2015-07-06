//
//  HZHeyzapExchangeBannerClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeBannerClient.h"
#import "HZHeyzapExchangeAPIClient.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HZHeyzapExchangeConstants.h"
#import "HZHeyzapExchangeMRAIDServiceHandler.h"

@interface HZHeyzapExchangeBannerClient()<HZHeyzapExchangeMRAIDServiceHandlerDelegate, HZMRAIDViewDelegate>

@property (nonatomic) HZBannerAdOptions *lastBannerAdOptions;
@property (nonatomic) HZMRAIDView *mraidBanner;
@property (nonatomic) BOOL mraidBannerFetchedAndReady;

@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) NSDictionary *responseDict;
@property (nonatomic) NSString *adMediationId;
@property (nonatomic) NSNumber *adScore;
@property (nonatomic) NSString *adMarkup;
@property (nonatomic) NSString *adDataHash;//encryption hash for request validation
@property (nonatomic) HZHeyzapExchangeFormat format;

@property (nonatomic) HZHeyzapExchangeMRAIDServiceHandler *serviceHandler;

@property (nonatomic, weak) id<HZHeyzapExchangeBannerClientDelegate> delegate;

@property (nonatomic) UIWebView *clickTrackingWebView;
@end


@implementation HZHeyzapExchangeBannerClient

- (instancetype) init {
    self = [super init];
    if(self) {
        _lastBannerAdOptions = [[HZBannerAdOptions alloc] init];
        _lastBannerAdOptions.heyzapExchangeBannerSize = HZHeyzapExchangeBannerSizeFlexibleWidthHeight50; //default
    }
    
    return self;
}

- (void) fetchWithOptions:(HZBannerAdOptions *)options delegate:(id<HZHeyzapExchangeBannerClientDelegate>)delegate {
    if(self.mraidBannerFetchedAndReady) {
        // already fetched
        return;
    }
    self.lastBannerAdOptions = options;
    self.delegate = delegate;
    self.apiClient = [HZHeyzapExchangeAPIClient sharedClient];

    [self.apiClient GET:@"_/0/ad"
             parameters:[self apiRequestParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                 {
                     NSData * data = (NSData *)responseObject;
                     if(!data || data.bytes == nil) {
                         HZELog(@"Fetch failed - data null or empty");
                         [self.delegate fetchFailedWithClient:self];
                         return;
                     }
                     
                     NSError *jsonError;
                     /* expected format:
                      
                      {
                      "meta":
                      {
                      "id": "123...",
                      "score":10000,
                      "data":"{hash}"
                      }
                      "ad":
                      {
                      "format": 5, //enum for format
                      "markup": "<script src=\"mraid.js\"> ..." //VAST or MRAID tag
                      },
                      }
                     */
                     self.responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingMutableContainers
                                                                           error:&jsonError];
                     
                     
                     if(jsonError || !self.responseDict){
                         HZELog(@"JSON parse failed for exchange response. Error: %@", jsonError);
                         [self handleFailure];
                         return;
                     }
                     
                     NSDictionary *adDict = [HZDictionaryUtils hzObjectForKey:@"ad" ofClass:[NSDictionary class] default:nil withDict:self.responseDict];
                     
                     if(!adDict){
                         HZELog(@"JSON format unexpected for exchange response.");
                         [self handleFailure];
                         return;
                     }
                     
                     self.adMarkup = adDict[@"markup"];
                     NSDictionary *adMetaDict = self.responseDict[@"meta"];
                     self.adMediationId = adMetaDict[@"id"];
                     self.adScore = adMetaDict[@"score"];
                     self.adDataHash = adMetaDict[@"data"];
                     
                     self.format = [[HZDictionaryUtils hzObjectForKey:@"format" ofClass:[NSNumber class] default:@(0) withDict:adDict] intValue];
                     if(![self isSupportedFormat]) {
                         HZELog(@"Format of Exchange response unsupported (%lu).", (unsigned long)self.format);
                         [self handleFailure];
                         return;
                     }
                     
                     self.serviceHandler = [[HZHeyzapExchangeMRAIDServiceHandler alloc] initWithDelegate:self];
                     
                     self.mraidBanner = [[HZMRAIDView alloc] initWithFrame:CGRectMake(0, 0, [self currentBannerWidth], [self currentBannerHeight])
                                                              withHtmlData:self.adMarkup
                                                               withBaseURL:nil
                                                         supportedFeatures:[self.serviceHandler supportedFeatures]
                                                                  delegate:self
                                                           serviceDelegate:self.serviceHandler
                                                        rootViewController:options.presentingViewController];
                     [self.delegate fetchSuccessWithClient:self banner:self.mraidBanner];
                 }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                {
                    HZELog(@"Fetch failed. Error: %@", error);
                    [self handleFailure];
                }
     ];
}

- (void)handleFailure {
    [self.delegate fetchFailedWithClient:self];
}

- (void) reportImpression {
    [self.apiClient POST:[NSString stringWithFormat:@"_/0/ad/%@/impression", self.adMediationId]
             parameters:[self impressionParams]
                 success:^(HZAFHTTPRequestOperation *operation, id responseObject){}
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
     {
         HZELog(@"Heyzap Exchange Banner failed to report impression. Error: %@", error);
     }];
}

- (void) reportClick {
    [self.apiClient GET:[NSString stringWithFormat:@"_/0/ad/%@/click", self.adMediationId]
             parameters:[self clickParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject){}
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
     {
         HZELog(@"Heyzap Exchange Banner failed to report click. Error: %@", error);
     }];
}

#pragma mark - HZHeyzapExchangeMRAIDServiceHandlerDelegate
- (void) serviceEventProcessed:(NSString *)serviceEvent willLeaveApplication:(BOOL)willLeaveApplication {
    [self.delegate bannerInteractionWillLeaveApplication:willLeaveApplication];
}


#pragma mark - HZMRAIDViewDelegate (banners)

- (void)mraidViewAdReady:(HZMRAIDView *)mraidView {
    [self.delegate bannerReady:mraidView];
}

//sent when ad html is bad
- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView {
    [self.delegate bannerFailed];
}

- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView{
    [self.delegate bannerWillShow];
    [self reportImpression];
}

- (void)mraidViewDidClose:(HZMRAIDView *)mraidView {
    [self.delegate bannerDidClose];
}

- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url {
    [self.delegate bannerInteractionWillLeaveApplication:YES];
    [self reportClick];
    
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - Utilities
- (int) currentBannerHeight {
    switch (self.lastBannerAdOptions.heyzapExchangeBannerSize) {
        case HZHeyzapExchangeBannerSizeFlexibleWidthHeight50:
            return 50;
        case HZHeyzapExchangeBannerSizeFlexibleWidthHeight90:
            return 90;
    }
}

- (int) currentBannerWidth {
    return [self screenWidth];
}

- (int) screenWidth {
    return (int)[[self.lastBannerAdOptions.presentingViewController view]bounds].size.width;
}

- (BOOL) isSupportedFormat {
    return [[HZHeyzapExchangeBannerClient supportedFormats] containsObject:@(self.format)];
}

// banners only supported via MRAID
+ (NSArray *) supportedFormats {
    return @[
             @(HZHeyzapExchangeFormatMRAID_2)
            ];
}

+ (NSString *) supportedFormatsString {
    return [[HZHeyzapExchangeBannerClient supportedFormats] componentsJoinedByString:@","];
}

// add additional params that HZHeyzapExchangeRequestSerializer doesn't cover for banners
- (NSDictionary *) apiRequestParams {
    return @{
             @"banner_w":@([self currentBannerWidth]),
             @"banner_h":@([self currentBannerHeight]),
             @"sdk_api": [HZHeyzapExchangeBannerClient supportedFormatsString],
             @"impression_creativetype": @(HZHeyzapExchangeCreativeTypeBanner),
            };
}

- (NSDictionary *) impressionParams {
    NSMutableDictionary * allRequestParams = [[self apiRequestParams] mutableCopy];
    [allRequestParams addEntriesFromDictionary:@{
                                                 @"mediation_id":self.adMediationId,
                                                 @"data":self.adDataHash,
                                                 @"markup":self.adMarkup,
                                                 }];
    return allRequestParams;
}

- (NSDictionary *) clickParams {
    return [self apiRequestParams]; //no special params necessary for click events yet
}

@end