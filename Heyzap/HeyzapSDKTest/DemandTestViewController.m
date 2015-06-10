//
//  MRAIDTestViewController.m
//  Heyzap
//
//  Created by Daniel Rhodes on 6/9/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "DemandTestViewController.h"
#import "HZMRAIDInterstitial.h"
#import "HZShowOptions.h"
#import "HZMRAIDView.h"
#import "HZMRAIDServiceDelegate.h"

@interface DemandTestViewController ()<HZMRAIDServiceDelegate, HZMRAIDInterstitialDelegate>

@property (nonatomic) HZMRAIDInterstitial *interstitial;

@end

@implementation DemandTestViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Demand";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *showButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    showButton.frame = CGRectMake(0.0, 0.0, 100, 40);
    [showButton addTarget: self action: @selector(onShow:) forControlEvents: UIControlEventTouchUpInside];
    [showButton setTitle: @"Show" forState: UIControlStateNormal];
    [self.view addSubview: showButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) onFetch: (id) sender {
    
}

- (void) onShow: (id) sender {
    
    NSString *adHtml = @"<script src=\"mraid.js\"></script><script type=\"text/javascript\">var ord = window.ord || Math.floor(Math.random() * 1e16);document.write('<script type=\"text/javascript\" src=\"http://ad.doubleclick.net/N16825456/adj/Heyzap_Network_Mobile/IOS_Flex_MRAID20;sz=4x4;ord=' + ord + '?\" id=\"mb_mraid_js\"><\\/script>');</script>";
    
    NSURL *bundleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
//    NSString *adHtml = @"Hello World";
//    
//    NSString *adHtml = [NSString stringWithFormat:
//                                                      @"<html>"
//                                                      "<style type='text/css'>html,body {margin: 0;padding: 0;width: 100%%;height: 100%%;}</style>"
//                                                      "<body>"
//                                                      "<table style='border:1px solid gray; border-radius: 5px; overflow: hidden;color:white;font-size:10pt' cellspacing=\"0\" cellpadding=\"1\" align='right'><tr>"
//                                                      "<td>Hello</td><td>There</td>"
//                                                      "</tr></table>"
//                                                      "</body></html>"
//                                                      ];
    
//    HZMRAIDAd *ad = [[HZMRAIDAd alloc] initWithHTML: adHtml andAdType: HZMRAIDAdTypeInterstitial];
//
//    HZShowOptions *options = [[HZShowOptions alloc] init];
//    options.viewController = self.navigationController;
//    
//    [ad showWithOptions: options];
    
//    NSURL *url = [NSURL URLWithString: @"http://ads.mdotm.com/ads/feed.php?partnerkey=heyzap&apikey=heyzapmediation&appkey=47824d830f2dca70a36385b1de09a32a&ua=Mozilla%2F5.0+%28Linux%3B+U%3B+Android+2.3.6%3B+es-us%3B+GT-S5360L+Build%2FGINGERBREAD%29+AppleWebKit%2F533.1+%28KHTML%2C+like+Gecko%29+Version%2F4.0+Mobile+Safari%2F533.1&width=320&height=480&fmt=xhtml&test=0&vidsupport=0&istablet=0&clientip=198.228.200.41"];
//    
//    NSError *error;
//    adHtml = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error: &error];
//    
//    NSLog(@"%@", adHtml);
    
    self.interstitial = [[HZMRAIDInterstitial alloc] initWithSupportedFeatures:@[HZMRAIDSupportsSMS, HZMRAIDSupportsTel, HZMRAIDSupportsCalendar, HZMRAIDSupportsStorePicture, HZMRAIDSupportsInlineVideo]
                                                             withHtmlData:adHtml
                                                              withBaseURL:bundleUrl
                                                                 delegate:self
                                                          serviceDelegate:self
                                                       rootViewController:self];
    
    [self.interstitial setBackgroundColor: [UIColor clearColor]];

    
    
}

#pragma mark - MRAID Interstitial Ad Ready

- (void)mraidInterstitialAdReady:(HZMRAIDInterstitial *)mraidInterstitial {
    [self.interstitial show];
}
- (void)mraidInterstitialAdFailed:(HZMRAIDInterstitial *)mraidInterstitial {
    
}
- (void)mraidInterstitialWillShow:(HZMRAIDInterstitial *)mraidInterstitial {
    
}
- (void)mraidInterstitialDidHide:(HZMRAIDInterstitial *)mraidInterstitial {
    
}
- (void)mraidInterstitialNavigate:(HZMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url {
    NSLog(@"%@", url);
}

#pragma mark -

@end
