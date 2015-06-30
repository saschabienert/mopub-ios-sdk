//
//  HZHeyzapExchangeBannerClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeBannerClient.h"
#import "HZBannerAdOptions.h"
#import "HZMRAIDView.h"
#import "HZHeyzapExchangeAPIClient.h"


@interface HZHeyzapExchangeBannerClient()<HZMRAIDViewDelegate>

@property (nonatomic) HZBannerAdOptions *lastBannerAdOptions;
@property (nonatomic) HZMRAIDView *mraidBanner;
@property (nonatomic) BOOL mraidBannerFetchedAndReady;

@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) NSString *responseString;

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

- (void) fetch {
    if(self.mraidBannerFetchedAndReady) {
        // already fetched
        return;
    }
    
    self.apiClient = [[HZHeyzapExchangeAPIClient alloc] init];
    
    int width = [self screenWidth];
    int height = [self currentBannerHeight];
    
    NSString * url;
    url = [NSString stringWithFormat:@"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=4cd119700fff11605d38f197ae5435dc&ua=%@&width=%i&height=%i&fmt=xhtml&v=3.4.0&test=1&deviceid=&aid=3305397B-FB19-4812-86F3-AEC2367C2CE5&ate=1&machine=%@&vidsupport=0&clientip=198.228.200.41", @"SampleApp%202.1.3%20(iPhone;%20iPhone%20OS%208.1.1;%20it_IT)", width, height, @"iPhone4,1%208.1.1"];

    [self.apiClient GET:url parameters:nil
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                 {
                     NSData * data = (NSData *)responseObject;
                     if(!data || data.bytes == nil) {
                         NSLog(@"monroedebug failure");
                         [self.delegate fetchFailedWithClient:self];
                         return;
                     }
                     
                     self.responseString = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
                     
                     NSLog(@"monroedebug success, responseObject: %@", self.responseString);
                     
                     UIViewController * viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
                     self.mraidBanner = [[HZMRAIDView alloc] initWithFrame:CGRectMake(0, 0, [self screenWidth], [self currentBannerHeight])
                                                              withHtmlData:self.responseString
                                                               withBaseURL:[NSURL URLWithString:@"http://www.google.com"]
                                                         supportedFeatures:nil
                                                                  delegate:self
                                                           serviceDelegate:nil
                                                        rootViewController:viewController];
                 }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                {
                    NSLog(@"monroedebug failure");
                    [self.delegate fetchFailedWithClient:self];
                }
          redirectBlock:^NSURLRequest * (NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse)
                {
                    return request;
                }
     ];
}


#pragma mark - HZMRAIDViewDelegate (banners)

// These callbacks are for basic banner ad functionality.
- (void)mraidViewAdReady:(HZMRAIDView *)mraidView {
    self.mraidBanner = mraidView;
    //[self.delegate client:self didFetchAdWithType:HZAdTypeBanner];
    self.mraidBannerFetchedAndReady = YES;
}
- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView {
    self.mraidBanner = nil;
    //[self.delegate client:self didFailToFetchAdWithType:HZAdTypeBanner];
}
- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView{
    //[self.delegate didShowBannerWithClient:self];
}
- (void)mraidViewDidClose:(HZMRAIDView *)mraidView {
    //[self.delegate didCloseBannerWithClient:self];
}
- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url {
    self.clickTrackingWebView = [[UIWebView alloc] init];
    [self.clickTrackingWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    //[self.delegate adClickedWithClient:self];
}

// This callback is to ask permission to resize an ad.
- (BOOL)mraidViewShouldResize:(HZMRAIDView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen {
    return YES;
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

- (int) screenWidth {
    return (int) [[[UIApplication sharedApplication] keyWindow] bounds].size.width;
}
@end