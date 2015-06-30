//
//  HZHeyzapExchangeClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/25/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeClient.h"
#import "HZHeyzapExchangeAPIClient.h"
#import "HZLog.h"

#import "HZSKVASTViewController.h"

#import "HZMRAIDInterstitial.h"



typedef NS_ENUM(NSUInteger, HZHeyzapExchangeClientFormat) {
    HZHeyzapExchangeClientFormatUnknown,
    HZHeyzapExchangeClientFormatVAST,
    HZHeyzapExchangeClientFormatMRAID
};

@interface HZHeyzapExchangeClient() <HZSKVASTViewControllerDelegate, HZMRAIDInterstitialDelegate>
@property (nonatomic) NSString *responseString;
@property (nonatomic) HZHeyzapExchangeClientFormat format;

@property (nonatomic) HZSKVASTViewController *vastVC;
@property (nonatomic) BOOL vastAdFetchedAndReady;

@property (nonatomic) HZMRAIDInterstitial *mraidInterstitial;
@property (nonatomic) BOOL mraidInterstitialFetchedAndReady;
@property (nonatomic) HZAdType lastMRAIDAdType;


@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) UIWebView *clickTrackingWebView;
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
    
    self.apiClient = [[HZHeyzapExchangeAPIClient alloc] init];
    _adType = adType;
    int width = [self screenWidth];
    int height = [[[UIApplication sharedApplication] keyWindow] bounds].size.height;
    
    NSString * url;
    
    //    NSURL* url = [NSURL URLWithString:@"https://hz-temp.s3.amazonaws.com/dsp-source-test/vast/vast_doubleclick_inline_comp.xml"];
    //    //url = [NSURL URLWithString:@"https://hz-temp.s3.amazonaws.com/dsp-source-test/vast/simple_tracking.xml"];//intel ad
    //    //url = [NSURL URLWithString:@"https://hz-temp.s3.amazonaws.com/dsp-source-test/vast/vast_missing_mediafile.xml"];//erroroneous xml
    //    //url = [NSURL URLWithString:@"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=4cd119700fff11605d38f197ae5435dc&ua=SampleApp%202.1.3%20(iPhone;%20iPhone%20OS%208.1.1;%20it_IT)&width=320&height=480&fmt=xhtml&v=3.4.0&test=0&deviceid=&aid=3305397B-FB19-4812-86F3-AEC2367C2CE5&ate=1&machine=iPhone4,1%208.1.1&vidsupport=2&clientip=198.228.200.41"];//mdotm
    //    url = [NSURL URLWithString:@"https://hz-temp.s3.amazonaws.com/dsp-source-test/vast/mdotm_vast.xml"];//mdotm hosted
    
    switch (adType) {
        case HZAdTypeVideo:
        case HZAdTypeIncentivized:
            //url = @"https://hz-temp.s3.amazonaws.com/dsp-source-test/vast/mdotm_vast.xml";
            url = [NSString stringWithFormat:@"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=4cd119700fff11605d38f197ae5435dc&ua=%@&width=%i&height=%i&fmt=xhtml&v=3.4.0&test=1&deviceid=&aid=3305397B-FB19-4812-86F3-AEC2367C2CE5&ate=1&machine=%@&vidsupport=2&clientip=198.228.200.41", @"SampleApp%202.1.3%20(iPhone;%20iPhone%20OS%208.1.1;%20it_IT)", width, height, @"iPhone4,1%208.1.1"];
            break;
            case HZAdTypeInterstitial:
                url = [NSString stringWithFormat:@"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=4cd119700fff11605d38f197ae5435dc&ua=%@&width=%i&height=%i&fmt=xhtml&v=3.4.0&test=1&deviceid=&aid=3305397B-FB19-4812-86F3-AEC2367C2CE5&ate=1&machine=%@&vidsupport=0&clientip=198.228.200.41", @"SampleApp%202.1.3%20(iPhone;%20iPhone%20OS%208.1.1;%20it_IT)", width, height, @"iPhone4,1%208.1.1"];
            break;
        case HZAdTypeBanner:
            break;
    }
    
    HZDLog(@"Exchange client fetching url: %@", url);
    
    [self.apiClient GET:url parameters:nil
        success:^(HZAFHTTPRequestOperation *operation, id responseObject)
            {
                NSData * data = (NSData *)responseObject;
                if(!data || data.bytes == nil) {
                    HZELog(@"Fetch failed - data null or empty");
                    [self.delegate client:self didFailToFetchAdWithType:adType];
                    return;
                }
                
                self.responseString = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
                self.format = [HZHeyzapExchangeClient guessFormatOfResponse:self.responseString];
                if(self.format == HZHeyzapExchangeClientFormatUnknown) {
                    HZELog(@"Format of Exchange response could not be determined.");
                    [self.delegate client:self didFailToFetchAdWithType:adType];
                    return;
                }
                
                HZDLog(@"Fetch success, response: %@", self.responseString);
                
                if(self.format == HZHeyzapExchangeClientFormatVAST){
                    self.vastVC = [[HZSKVASTViewController alloc] initWithDelegate:self forAdType:adType];
                    [self.vastVC loadVideoWithData:data];
                    self.isWithAudio = YES;
                }else if(self.format == HZHeyzapExchangeClientFormatMRAID){
                    UIViewController * viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                    
                    self.lastMRAIDAdType = adType;
                    self.mraidInterstitial = [[HZMRAIDInterstitial alloc] initWithSupportedFeatures:nil
                                                                                       withHtmlData:self.responseString
                                                                                        withBaseURL:nil
                                                                                           delegate:self
                                                                                    serviceDelegate:nil
                                                                                 rootViewController:viewController];
                }
            }
     
        failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
            {
                HZELog(@"Fetch failed. Error: %@", error);
                [self.delegate client:self didFailToFetchAdWithType:adType];
            }
     ];
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
    self.format = HZHeyzapExchangeClientFormatUnknown;
    self.responseString = nil;
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


#pragma mark - Utilities

+ (HZHeyzapExchangeClientFormat) guessFormatOfResponse:(NSString *)response {
    if([response containsString:@"<VAST"]) {
        return HZHeyzapExchangeClientFormatVAST;
    }
    
    if([response containsString:@"mraid.js"]) {
        return HZHeyzapExchangeClientFormatMRAID;
    }
    
    return HZHeyzapExchangeClientFormatUnknown;
}
                    
- (int) screenWidth {
    return (int) [[[UIApplication sharedApplication] keyWindow] bounds].size.width;
}

@end