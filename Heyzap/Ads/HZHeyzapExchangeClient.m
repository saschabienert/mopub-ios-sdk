//
//  HZHeyzapExchangeClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/25/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeClient.h"
#import "HZHeyzapExchangeAPIClient.h"
#import "HZHeyzapExchangeAdapter.h"
#import "HZHeyzapExchangeConstants.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HZSKVASTViewController.h"
#import "HZHeyzapExchangeMRAIDServiceHandler.h"
#import "HZMRAIDInterstitial.h"
#import "HZMRAIDServiceDelegate.h"
#import "HZMediationConstants.h"
#import "HeyzapMediation.h"
#import "HZShowOptions_Private.h"

@interface HZHeyzapExchangeClient() <HZSKVASTViewControllerDelegate, HZMRAIDInterstitialDelegate, HZHeyzapExchangeMRAIDServiceHandlerDelegate>

@property (nonatomic) HZHeyzapExchangeFormat format;

@property (nonatomic) HZSKVASTViewController *vastVC;
@property (nonatomic) BOOL vastAdFetchedAndReady;

@property (nonatomic) HZMRAIDInterstitial *mraidInterstitial;
@property (nonatomic) BOOL mraidInterstitialFetchedAndReady;

@property (nonatomic) NSDictionary *responseDict;
@property (nonatomic) NSString *adAuctionId;
@property (nonatomic) NSNumber *adScore;
@property (nonatomic) NSString *adMarkup;
@property (nonatomic) NSString *adExtrasHash;//encryption hash for request validation
@property (nonatomic) NSString *mediationId;//mediationId at the time of the show call
@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) UIWebView *clickTrackingWebView;
@property (nonatomic) HZHeyzapExchangeMRAIDServiceHandler *serviceHandler;

@property (nonatomic) HZHeyzapExchangeClientState state;

@property (nonatomic) HZShowOptions *showOptions; // showOptions for currently showing ad

@end

@implementation HZHeyzapExchangeClient

- (void) fetchForCreativeType:(HZCreativeType)creativeType {
    if(self.state == HZHeyzapExchangeClientStateFetching || self.state == HZHeyzapExchangeClientStateReady) {
        return;
    }
    
    if(creativeType == HZCreativeTypeBanner){
        HZELog(@"This is not the correct method to call for banner ad fetches. See HZHeyzapExchangeAdapter.");
        return;//wrong method to call
    }
    
    self.state = HZHeyzapExchangeClientStateFetching;
    
    self.apiClient = [HZHeyzapExchangeAPIClient sharedClient];
    _creativeType = creativeType;
    
    HZAFHTTPRequestOperation *request = [self.apiClient fetchAdWithExtraParams:[self apiRequestParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                {
                    NSData * data = (NSData *)responseObject;
                    if(!data || data.bytes == nil) {
                        HZELog(@"Fetch failed - data null or empty. Status code: %li", (long)operation.response.statusCode);
                        [self handleFetchFailure:@"no data"];
                        return;
                    }
                    
                    NSError *jsonError;
                    
                    /* expected format:
                     
                     {
                        "auction":
                        {
                            "id": "123...",
                            "score":10000,
                            "extras":"{hash}"
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
                        [self handleFetchFailure:@"bad data"];
                        return;
                    }
                    
                    NSDictionary *adDict = [HZDictionaryUtils objectForKey:@"ad" ofClass:[NSDictionary class] default:nil dict:self.responseDict];
                    
                    if(!adDict){
                        HZELog(@"JSON format unexpected for exchange response.");
                        [self handleFetchFailure:@"bad data"];
                        return;
                    }
                    
                    self.adMarkup = adDict[@"markup"];
                    HZDLog(@"Ad markup received: %@", self.adMarkup);
                    NSDictionary *adAuctionDict = self.responseDict[@"auction"];
                    self.adAuctionId = adAuctionDict[@"id"];
                    self.adScore = adAuctionDict[@"score"];
                    self.adExtrasHash = adAuctionDict[@"extras"];
                    
                    self.format = [[HZDictionaryUtils objectForKey:@"format" ofClass:[NSNumber class] default:@0 dict:adDict] intValue];
                    if(![self isSupportedFormat]) {
                        HZELog(@"Format of Exchange response unsupported (%lu).", (unsigned long)self.format);
                        [self handleFetchFailure:@"bad ad format"];
                        return;
                    }
                    
                    NSData *adMarkupData = [self.adMarkup dataUsingEncoding:NSUTF8StringEncoding];
                    
                    if(self.format == HZHeyzapExchangeFormatVAST_2_0){
                        self.vastVC = [[HZSKVASTViewController alloc] initWithDelegate:self forCreativeType:creativeType];
                        [self.vastVC loadVideoWithData:adMarkupData];
                        self.isWithAudio = YES;
                    }else if(self.format == HZHeyzapExchangeFormatMRAID_2){
                        UIViewController * viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                        self.serviceHandler = [[HZHeyzapExchangeMRAIDServiceHandler alloc]initWithDelegate:self];
                        self.mraidInterstitial = [[HZMRAIDInterstitial alloc] initWithSupportedFeatures:[self.serviceHandler supportedFeatures]
                                                                                           withHtmlData:self.adMarkup
                                                                                            withBaseURL:nil
                                                                                               delegate:self
                                                                                        serviceDelegate:self.serviceHandler
                                                                                     rootViewController:viewController];
                    }
                }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                {
                    HZELog(@"Fetch failed. Error: %@", error);
                    [self handleFetchFailure:@"request failed / no fill"];
                }
     ];
    
    HZDLog(@"Exchange fetch request URL: %@", request.request.URL);
}

- (void) handleFetchFailure:(NSString *)failureReason {
    self.state = HZHeyzapExchangeClientStateFailure;
    if(failureReason) {
        [self.delegate client:self didFailToFetchAdWithCreativeType:self.creativeType error:failureReason];
    }
}

- (void) reportImpression {
    [self.apiClient reportImpressionForAd:self.adAuctionId
                          withExtraParams:[self impressionParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                {
                    
                }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                {
                    HZELog(@"Heyzap Exchange failed to report impression. Error: %@", error);
                }];
}

- (void) reportClick {
    [self.apiClient reportClickForAd:self.adAuctionId
             withExtraParams:[self clickParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                 {
                     
                 }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                 {
                     HZELog(@"Heyzap Exchange failed to report click. Error: %@", error);
                 }];
}

- (void) reportVideoComplete {
    [self.apiClient reportVideoCompletionForAd:self.adAuctionId
             withExtraParams:[self videoCompleteParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                 {
                     
                 }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                 {
                     HZELog(@"Heyzap Exchange failed to report video completion. Error: %@", error);
                 }];
}

- (void) showWithOptions:(HZShowOptions *)options {
    //mediationId can change over time, we want to use the current id at the time of showing the ad for later reporting
    self.mediationId = [[HeyzapMediation sharedInstance] mediationId];
    self.showOptions = options;
    
    if(self.vastAdFetchedAndReady){
        self.vastVC.rootViewController = options.viewController;
        [self.vastVC play];
    }else if(self.mraidInterstitialFetchedAndReady){
        self.mraidInterstitial.rootViewController = options.viewController;
        [self.mraidInterstitial show];
    }
}

#pragma mark - HZSKVASTViewControllerDelegate
- (void) vastReady:(HZSKVASTViewController *)vastVC {
    self.vastVC = vastVC;
    self.vastAdFetchedAndReady = YES;
    self.state = HZHeyzapExchangeClientStateReady;
    [self.delegate client:self didFetchAdWithCreativeType:self.vastVC.creativeType];
}

- (void)vastError:(HZSKVASTViewController *)vastVC error:(HZSKVASTError)error {
    
    NSString * errorString = @"unknown";
    switch(error){
        case VASTErrorNone:
            errorString = @"VASTErrorNone";
            break;
        case VASTErrorXMLParse:
            errorString = @"VASTErrorXMLParse";
            break;
        case VASTErrorSchemaValidation:
            errorString = @"VASTErrorSchemaValidation";
            break;
        case VASTErrorTooManyWrappers:
            errorString = @"VASTErrorTooManyWrappers";
            break;
        case VASTErrorNoCompatibleMediaFile:
            errorString = @"VASTErrorNoCompatibleMediaFile";
            break;
        case VASTErrorNoInternetConnection:
            errorString = @"VASTErrorNoInternetConnection";
            break;
        case VASTErrorLoadTimeout:
            errorString = @"VASTErrorLoadTimeout";
            break;
        case VASTErrorPlayerNotReady:
            errorString = @"VASTErrorPlayerNotReady";
            break;
        case VASTErrorPlaybackError:
            errorString = @"VASTErrorPlaybackError";
            break;
        case VASTErrorMovieTooShort:
            errorString = @"VASTErrorMovieTooShort";
            break;
        case VASTErrorPlayerHung:
            errorString = @"VASTErrorPlayerHung";
            break;
        case VASTErrorPlaybackAlreadyInProgress:
            errorString = @"VASTErrorPlaybackAlreadyInProgress";
            break;
        case VASTErrorCacheFailed:
            errorString = @"VASTErrorCacheFailed";
            break;
    }

    if(!self.vastAdFetchedAndReady) {
        [self handleFetchFailure:[NSString stringWithFormat:@"VAST error: %@", errorString]];
    }else{
        [self.delegate client:self didHaveError:[NSString stringWithFormat:@"vast_playback_error: %@", errorString]];
    }
}

// These optional callbacks are for basic presentation, dismissal, and calling video clickthrough url browser.
- (void)vastWillPresentFullScreen:(HZSKVASTViewController *)vastVC {
    [self.delegate didStartAdWithClient:self];
    [self reportImpression];
}
- (void)vastDidDismissFullScreen:(HZSKVASTViewController *)vastVC {
    self.vastVC = nil;
    self.format = HZHeyzapExchangeFormatUnknown;
    self.responseDict = nil;
    
    self.vastAdFetchedAndReady = NO;
    self.state = HZHeyzapExchangeClientStateFinished;
    [self.delegate didEndAdWithClient:self successfullyFinished:vastVC.didFinishSuccessfully];
    if(vastVC.didFinishSuccessfully){
        [self reportVideoComplete];
    }
}
- (void)vastOpenBrowseWithUrl:(NSURL *)url {
    HZDLog(@"HZHeyzapExchangeClient VAST click url: '%@'", [url absoluteString]);
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.delegate adClickedWithClient:self];
    [self reportClick];
}
- (void)vastTrackingEvent:(NSString *)eventName { }


#pragma mark - HZMRAIDInterstitialDelegate

- (void)mraidInterstitialAdReady:(HZMRAIDInterstitial *)mraidInterstitial {
    self.mraidInterstitial = mraidInterstitial;
    self.mraidInterstitialFetchedAndReady = YES;
    self.state = HZHeyzapExchangeClientStateReady;
    [self.delegate client:self didFetchAdWithCreativeType:self.creativeType];
}

- (void)mraidInterstitialAdFailed:(HZMRAIDInterstitial *)mraidInterstitial {
    self.mraidInterstitial = nil;
    [self handleFetchFailure:@"bad mraid data"];
}

- (void)mraidInterstitialWillShow:(HZMRAIDInterstitial *)mraidInterstitial {
    [self.delegate didStartAdWithClient:self];
    [self reportImpression];
}

- (void)mraidInterstitialDidHide:(HZMRAIDInterstitial *)mraidInterstitial {
    self.mraidInterstitialFetchedAndReady = NO;
    self.mraidInterstitial = nil;
    self.format = HZHeyzapExchangeFormatUnknown;
    self.responseDict = nil;
    self.state = HZHeyzapExchangeClientStateFinished;
    [self.delegate didEndAdWithClient:self successfullyFinished:YES];
}

- (void)mraidInterstitialNavigate:(HZMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url {
    
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.delegate adClickedWithClient:self];
    [self reportClick];
}

#pragma mark - HZHeyzapExchangeMRAIDServiceHandlerDelegate
- (void) serviceEventProcessed:(NSString *)serviceEvent willLeaveApplication:(BOOL)willLeaveApplication{
    [self.delegate adClickedWithClient:self];
    [self reportClick];
}

#pragma mark - Utilities
- (BOOL) isSupportedFormat {
    return [[HZHeyzapExchangeClient supportedFormats] containsObject:@(self.format)];
}

+ (NSArray *) supportedFormats {
    return @[
             @(HZHeyzapExchangeFormatVAST_2_0),
             @(HZHeyzapExchangeFormatVAST_2_0_WRAPPER),
             @(HZHeyzapExchangeFormatMRAID_1),
             @(HZHeyzapExchangeFormatMRAID_2),
             ];
}

+ (NSString *) supportedFormatsString {
    return [[HZHeyzapExchangeClient supportedFormats] componentsJoinedByString:@","];
}

/**
 *  Returns additional params that should be sent to all exchange endpoints that HZHeyzapExchangeRequestSerializer doesn't/can't cover on it's own.
 */
- (NSDictionary *) apiRequestParams {
    // this conversion may seem unnecessary but the exchange server might not always use the creative type enum values we use for other things
    HZHeyzapExchangeCreativeType creativeType = HZHeyzapExchangeCreativeTypeUnknown;
    switch (self.creativeType) {
        case HZCreativeTypeBanner://ignore here
            break;
        case HZCreativeTypeIncentivized:
            creativeType = HZHeyzapExchangeCreativeTypeIncentivized;
            break;
        case HZCreativeTypeVideo:
            creativeType = HZHeyzapExchangeCreativeTypeVideo;
            break;
        case HZCreativeTypeStatic:
            creativeType = HZHeyzapExchangeCreativeTypeStatic;
            break;
        default:
            break;
    }
    
    return @{
             @"sdk_api": [HZHeyzapExchangeClient supportedFormatsString],
             @"impression_creativetype": @(creativeType),
            };
}

- (NSDictionary *) impressionParams {
    NSMutableDictionary * allRequestParams = [[self apiRequestParams] mutableCopy];
    [allRequestParams addEntriesFromDictionary:@{
                                                 @"mediation_id":self.mediationId,
                                                 @"auction_extras":self.adExtrasHash,
                                                 @"markup":self.adMarkup,
                                                 @"ad_unit":NSStringFromAdType(self.showOptions.requestingAdType),
                                                 @"mediation_tag":self.showOptions.tag,
                                                 }];
    return allRequestParams;
}

- (NSDictionary *) clickParams {
    NSMutableDictionary * allRequestParams = [[self apiRequestParams] mutableCopy];
    [allRequestParams addEntriesFromDictionary:@{
                                                 @"mediation_id":self.mediationId,
                                                 @"auction_extras":self.adExtrasHash,
                                                 @"ad_unit":NSStringFromAdType(self.showOptions.requestingAdType),
                                                 @"mediation_tag":self.showOptions.tag,
                                                 }];
    return allRequestParams;
}

- (NSDictionary *) videoCompleteParams {
    NSMutableDictionary * allRequestParams = [[self apiRequestParams] mutableCopy];
    [allRequestParams addEntriesFromDictionary:@{
                                                 @"mediation_id":self.mediationId,
                                                 @"auction_extras":self.adExtrasHash,
                                                 @"ad_unit":NSStringFromAdType(self.showOptions.requestingAdType),
                                                 @"mediation_tag":self.showOptions.tag,
                                                 }];
    return allRequestParams;
}

@end