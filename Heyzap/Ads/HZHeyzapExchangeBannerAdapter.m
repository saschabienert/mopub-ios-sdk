//
//  HZHeyzapExchangeBannerAdapter.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/29/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeBannerAdapter.h"
#import "HZMRAIDView.h"

@interface HZHeyzapExchangeBannerAdapter()
@property (nonatomic) HZMRAIDView *banner;
@end

@implementation HZHeyzapExchangeBannerAdapter

- (instancetype) initWithAdUnitID:(NSString *)adUnitID options:(HZBannerAdOptions *)options reportingDelegate:(id<HZBannerReportingDelegate>)reportingDelegate parentAdapter:(HZBaseAdapter *)parentAdapter {
    
    self = [super init];
    if(self){
        self.parentAdapter = parentAdapter;
        self.bannerReportingDelegate = reportingDelegate;
        
        //_banner = [[HZMRAIDView alloc]initWithFrame:<#(CGRect)#> withHtmlData:<#(NSString *)#> withBaseURL:<#(NSURL *)#> supportedFeatures:<#(NSArray *)#> delegate:<#(id<HZMRAIDViewDelegate>)#> serviceDelegate:<#(id<HZMRAIDServiceDelegate>)#> rootViewController:<#(UIViewController *)#>];

        _banner.rootViewController = options.presentingViewController;
        //_banner.delegate = self;
        //[_banner loadRequest:nil];

    }
    
    return self;
}

@end