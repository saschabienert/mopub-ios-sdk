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

@interface HZHeyzapExchangeBannerClient()

@property (nonatomic) HZBannerAdOptions *lastBannerAdOptions;
@property (nonatomic) HZMRAIDView *mraidBanner;
@property (nonatomic) BOOL mraidBannerFetchedAndReady;

@property (nonatomic) HZHeyzapExchangeAPIClient *apiClient;

@property (nonatomic) NSString *responseString;

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

- (void) fetchWithOptions:(HZBannerAdOptions *)options delegate:(id<HZMRAIDViewDelegate>)delegate {
    if(self.mraidBannerFetchedAndReady) {
        // already fetched
        return;
    }
    self.lastBannerAdOptions = options;
    
    self.apiClient = [[HZHeyzapExchangeAPIClient alloc] init];
    
    int width = [self screenWidth];
    int height = [self currentBannerHeight];
    
    NSString * url;
    url = [NSString stringWithFormat:@"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=4cd119700fff11605d38f197ae5435dc&ua=%@&width=%i&height=%i&fmt=xhtml&v=3.4.0&test=1&deviceid=&aid=3305397B-FB19-4812-86F3-AEC2367C2CE5&ate=1&machine=%@&vidsupport=0&clientip=198.228.200.41", @"SampleApp%202.1.3%20(iPhone;%20iPhone%20OS%208.1.1;%20it_IT)", width, height, @"iPhone4,1%208.1.1"];
    
    HZDLog(@"Exchange banner client fetching url: %@", url);

    [self.apiClient GET:url parameters:nil
                success:^(HZAFHTTPRequestOperation *operation, id responseObject)
                 {
                     NSData * data = (NSData *)responseObject;
                     if(!data || data.bytes == nil) {
                         HZELog(@"Fetch failed - data null or empty");
                         [self.delegate fetchFailedWithClient:self];
                         return;
                     }
                     
                     self.responseString = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
                     
                     HZDLog(@"Fetch success, response: %@", self.responseString);
                     
                     self.mraidBanner = [[HZMRAIDView alloc] initWithFrame:CGRectMake(0, 0, [self screenWidth], [self currentBannerHeight])
                                                              withHtmlData:self.responseString
                                                               withBaseURL:nil
                                                         supportedFeatures:nil
                                                                  delegate:delegate
                                                           serviceDelegate:nil
                                                        rootViewController:options.presentingViewController];
                     [self.delegate fetchSuccessWithClient:self banner:self.mraidBanner];
                 }
                failure:^(HZAFHTTPRequestOperation *operation, NSError *error)
                {
                    HZELog(@"Fetch failed. Error: %@", error);
                    [self.delegate fetchFailedWithClient:self];
                }
     ];
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
    return (int)[[self.lastBannerAdOptions.presentingViewController view]bounds].size.width;
}
@end