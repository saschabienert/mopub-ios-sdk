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
#import "HZHeyzapExchangeFormat.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"
#import "HZSKVASTViewController.h"
#import "HZHeyzapExchangeMRAIDServiceHandler.h"
#import "HZMRAIDInterstitial.h"
#import "HZMRAIDServiceDelegate.h"



@interface HZHeyzapExchangeClient() <HZSKVASTViewControllerDelegate, HZMRAIDInterstitialDelegate, HZHeyzapExchangeMRAIDServiceHandlerDelegate>

@property (nonatomic) HZHeyzapExchangeFormat format;

@property (nonatomic) HZSKVASTViewController *vastVC;
@property (nonatomic) BOOL vastAdFetchedAndReady;

@property (nonatomic) HZMRAIDInterstitial *mraidInterstitial;
@property (nonatomic) BOOL mraidInterstitialFetchedAndReady;
@property (nonatomic) HZAdType lastMRAIDAdType;

@property (nonatomic) NSDictionary *responseDict;
@property (nonatomic) NSString *adMediationId;
@property (nonatomic) NSDictionary *adMetaDict;
@property (nonatomic) NSString *adMarkup;

@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) UIWebView *clickTrackingWebView;

@property (nonatomic) HZHeyzapExchangeMRAIDServiceHandler *serviceHandler;
@end

@implementation HZHeyzapExchangeClient

- (void) fetchForAdType:(HZAdType)adType {
    if(self.vastAdFetchedAndReady || self.mraidInterstitialFetchedAndReady) {
        // already fetched
        return;
    }
    
    if(adType == HZAdTypeBanner){
        HZELog(@"This is not the correct method to call for banner ad fetches. See HZHeyzapExchangeAdapter.");
        return;//wrong method to call
    }
    
    self.apiClient = [HZHeyzapExchangeAPIClient sharedClient];
    _adType = adType;
    
    [self.apiClient GET:@"_/0/ad"
             parameters:[self apiRequestParams]
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                {
                    NSData * data = (NSData *)responseObject;
                    if(!data || data.bytes == nil) {
                        HZELog(@"Fetch failed - data null or empty");
                        [self.delegate client:self didFailToFetchAdWithType:adType];
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
                    self.adMetaDict = self.responseDict[@"meta"];
                    self.adMediationId = self.adMetaDict[@"id"];
                    
                    self.format = [[HZDictionaryUtils hzObjectForKey:@"format" ofClass:[NSNumber class] default:@(0) withDict:adDict] intValue];
                    if(![self isSupportedFormat]) {
                        HZELog(@"Format of Exchange response unsupported (%lu).", (unsigned long)self.format);
                        [self handleFailure];
                        return;
                    }
                    
                    NSData *adMarkupData = [self.adMarkup dataUsingEncoding:NSUTF8StringEncoding];
                    
                    if(self.format == HZHeyzapExchangeFormatVAST_2_0){
                        self.vastVC = [[HZSKVASTViewController alloc] initWithDelegate:self forAdType:adType];
                        [self.vastVC loadVideoWithData:adMarkupData];
                        self.isWithAudio = YES;
                    }else if(self.format == HZHeyzapExchangeFormatMRAID_2){
                        UIViewController * viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                        self.serviceHandler = [[HZHeyzapExchangeMRAIDServiceHandler alloc]initWithDelegate:self];
                        self.lastMRAIDAdType = adType;
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
                    [self handleFailure];
                }
     ];
}

- (void)handleFailure {
    [self.delegate client:self didFailToFetchAdWithType:self.adType];
}

- (void) showWithOptions:(HZShowOptions *)options {
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
    [self.delegate client:self didFetchAdWithType:self.vastVC.adType];
    self.vastAdFetchedAndReady = YES;
}

- (void)vastError:(HZSKVASTViewController *)vastVC error:(HZSKVASTError)error {
    if(!self.vastAdFetchedAndReady) {
        [self.delegate client:self didFailToFetchAdWithType:vastVC.adType];
    }else{
        [self.delegate client:self didHaveError:[NSString stringWithFormat:@"vast_playback_error: %i", error]];
    }
}

// These optional callbacks are for basic presentation, dismissal, and calling video clickthrough url browser.
- (void)vastWillPresentFullScreen:(HZSKVASTViewController *)vastVC {
    [self.delegate didStartAdWithClient:self];
}
- (void)vastDidDismissFullScreen:(HZSKVASTViewController *)vastVC {
    self.vastVC = nil;
    self.format = HZHeyzapExchangeFormatUnknown;
    self.adMarkup = nil;
    self.adMetaDict = nil;
    self.adMediationId = nil;
    self.responseDict = nil;
    
    self.vastAdFetchedAndReady = NO;
    [self.delegate didEndAdWithClient:self successfullyFinished:vastVC.didFinishSuccessfully];
}
- (void)vastOpenBrowseWithUrl:(NSURL *)url {
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.delegate adClickedWithClient:self];
}
- (void)vastTrackingEvent:(NSString *)eventName { }


#pragma mark - HZMRAIDInterstitialDelegate

- (void)mraidInterstitialAdReady:(HZMRAIDInterstitial *)mraidInterstitial {
    self.mraidInterstitial = mraidInterstitial;
    [self.delegate client:self didFetchAdWithType:self.lastMRAIDAdType];
    self.mraidInterstitialFetchedAndReady = YES;
}

- (void)mraidInterstitialAdFailed:(HZMRAIDInterstitial *)mraidInterstitial {
    self.mraidInterstitial = nil;
    [self.delegate client:self didFailToFetchAdWithType:self.lastMRAIDAdType];
}

- (void)mraidInterstitialWillShow:(HZMRAIDInterstitial *)mraidInterstitial {
    [self.delegate didStartAdWithClient:self];
}

- (void)mraidInterstitialDidHide:(HZMRAIDInterstitial *)mraidInterstitial {
    [self.delegate didEndAdWithClient:self successfullyFinished:YES];
}

- (void)mraidInterstitialNavigate:(HZMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url {
    
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    [self.delegate adClickedWithClient:self];
}

#pragma mark - HZHeyzapExchangeMRAIDServiceHandlerDelegate
- (void) serviceEventProcessed:(NSString *)serviceEvent willLeaveApplication:(BOOL)willLeaveApplication{
    [self.delegate adClickedWithClient:self];
}

#pragma mark - Utilities
- (BOOL) isSupportedFormat {
    return [[HZHeyzapExchangeClient supportedFormats] containsObject:@(self.format)];
}

+ (NSArray *) supportedFormats {
    return @[
             @(HZHeyzapExchangeFormatVAST_2_0),
             @(HZHeyzapExchangeFormatMRAID_2)
             ];
}

+ (NSString *) supportedFormatsString {
    return [[HZHeyzapExchangeClient supportedFormats] componentsJoinedByString:@","];
}

- (int) screenWidth {
    return (int) [[[UIApplication sharedApplication] keyWindow] bounds].size.width;
}

// add additional params that HZHeyzapExchangeRequestSerializer doesn't cover
- (NSDictionary *) apiRequestParams {
    int creativeType = 0;
    switch (self.adType) {
        case HZAdTypeBanner://ignore here
            break;
        case HZAdTypeIncentivized:
            creativeType = 4;
            break;
        case HZAdTypeVideo:
            creativeType = 2;
            break;
        case HZAdTypeInterstitial:
            creativeType = 1;
            break;
        default:
            break;
    }
    
    return @{
             @"sdk_api": [HZHeyzapExchangeClient supportedFormatsString],
             @"impression_creativetype": @(creativeType),
            };
}

@end