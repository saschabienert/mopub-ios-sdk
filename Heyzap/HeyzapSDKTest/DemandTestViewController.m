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

#import <Masonry/Masonry.h>



#define kHZBannerViewTag 1
#define kHZInterstitialViewTag 2
#define kHZSupportedFeatures @[HZMRAIDSupportsSMS, HZMRAIDSupportsTel, HZMRAIDSupportsCalendar, HZMRAIDSupportsStorePicture, HZMRAIDSupportsInlineVideo]


NSString * const HZDemandSourceMRAIDMediabrixPhone = @"<script src=\"mraid.js\"></script><script type=\"text/javascript\">var ord = window.ord || Math.floor(Math.random() * 1e16);document.write('<script type=\"text/javascript\" src=\"http://ad.doubleclick.net/N16825456/adj/Heyzap_Network_Mobile/IOS_Flex_MRAID20;sz=4x4;ord=' + ord + '?\" id=\"mb_mraid_js\"><\\/script>');</script>";
NSString * const HZDemandSourceMRAIDMediabrixTablet = @"";
NSString * const HZDemandSourceMRAIDDiagnosticURL = @"http://admarvel.s3.amazonaws.com/demo/mraid/MRAID_v2_diagnostics.txt";
NSString * const HZDemandSourceMRAIDBannerExpandLockedPortrait = @"http://admarvel.s3.amazonaws.com/demo/mraid/MRAID_v2_expand_with_locked_portrait_orientation.txt";
NSString * const HZDemandSourceMRAIDBannerExpandCentered = @"http://admarvel.s3.amazonaws.com/demo/mraid/MRAID_v2_expand_stay_centered.txt";
NSString * const HZDemandSourceMRAIDBannerResize = @"http://admarvel.s3.amazonaws.com/demo/mraid/MRAID_v2_simple_resize.txt";
NSString * const HZDemandSourceMRAIDVideoInterstitial = @"http://admarvel.s3.amazonaws.com/demo/mraid/MRAID_v2_video_interstitial.txt";

@interface DemandTestViewController ()<HZMRAIDServiceDelegate, HZMRAIDInterstitialDelegate, HZMRAIDViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) HZMRAIDInterstitial *interstitial;
@property (nonatomic) HZMRAIDView *bannerView;

@property (nonatomic, strong) UIButton *interstitialShowButton;
@property (nonatomic, strong) UIButton *interstitialFetchButton;
@property (nonatomic, strong) UIButton *bannerShowButton;
@property (nonatomic, strong) UIButton *bannerHideButton;

@property (nonatomic, strong) UIPickerView *adTypePicker;

@property (nonatomic, strong) NSString *MRAIDSource;

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
    
    self.MRAIDSource = HZDemandSourceMRAIDMediabrixPhone;
    
    self.adTypePicker = [[UIPickerView alloc] initWithFrame: CGRectZero];
    self.adTypePicker.delegate = self;
    [self.view addSubview: self.adTypePicker];
    
    self.interstitialShowButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.interstitialShowButton.backgroundColor = [UIColor lightGrayColor];
    [self.interstitialFetchButton setTitleColor: [UIColor greenColor] forState: UIControlStateNormal];
    [self.interstitialFetchButton setTitleColor: [UIColor redColor] forState: UIControlStateDisabled];
    self.interstitialShowButton.layer.cornerRadius = 3.0;
    self.interstitialShowButton.tag = kHZInterstitialViewTag;
    [self.interstitialShowButton addTarget: self action: @selector(onShow:) forControlEvents: UIControlEventTouchUpInside];
    [self.interstitialShowButton setTitle: @"Show" forState: UIControlStateNormal];
    self.interstitialFetchButton.enabled = NO;
    [self.view addSubview: self.interstitialShowButton];
    
    self.interstitialFetchButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.interstitialFetchButton.backgroundColor = [UIColor lightGrayColor];
    self.interstitialFetchButton.layer.cornerRadius = 3.0;
    self.interstitialFetchButton.tag = kHZInterstitialViewTag;
    [self.interstitialFetchButton addTarget: self action: @selector(onFetch:) forControlEvents: UIControlEventTouchUpInside];
    [self.interstitialFetchButton setTitle: @"Fetch" forState: UIControlStateNormal];
    [self.view addSubview: self.interstitialFetchButton];
    
    UILabel *mraidLabel = [[UILabel alloc] init];
    mraidLabel.text = @"MRAID v2";
    mraidLabel.font = [UIFont boldSystemFontOfSize: 22.0];
    mraidLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview: mraidLabel];
    
    UILabel *interstitialLabel = [[UILabel alloc] init];
    interstitialLabel.text = @"Interstitial";
    interstitialLabel.font = [UIFont boldSystemFontOfSize: 18.0];
    [self.view addSubview: interstitialLabel];
    
    [mraidLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@50);
        make.right.equalTo(self.view.mas_right).offset(20.0);
        make.left.equalTo(self.view.mas_left).offset(20.0);
        make.top.equalTo(self.view.mas_top).offset(20);
    }];
    
    [interstitialLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(mraidLabel.mas_bottom);
        make.left.equalTo(self.view.mas_left).offset(20.0);
    }];
    
    [self.interstitialFetchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(mraidLabel.mas_bottom);
        make.left.equalTo(interstitialLabel.mas_right).offset(20.0);
    }];
    
    [self.interstitialShowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(mraidLabel.mas_bottom);
        make.left.equalTo(self.interstitialFetchButton.mas_right).offset(20.0);
    }];
    
    self.bannerShowButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.bannerShowButton.backgroundColor = [UIColor lightGrayColor];
    self.bannerShowButton.layer.cornerRadius = 3.0;
    self.bannerShowButton.tag = kHZBannerViewTag;
    [self.bannerShowButton addTarget: self action: @selector(onShow:) forControlEvents: UIControlEventTouchUpInside];
    [self.bannerShowButton setTitle: @"Show" forState: UIControlStateNormal];
    [self.view addSubview: self.bannerShowButton];
    
    self.bannerHideButton = [UIButton buttonWithType: UIButtonTypeRoundedRect];
    self.bannerHideButton.backgroundColor = [UIColor lightGrayColor];
    self.bannerHideButton.layer.cornerRadius = 3.0;
    self.bannerHideButton.tag = kHZBannerViewTag;
    [self.bannerHideButton addTarget: self action: @selector(onHide:) forControlEvents: UIControlEventTouchUpInside];
    [self.bannerHideButton setTitle: @"Hide" forState: UIControlStateNormal];
    [self.view addSubview: self.bannerHideButton];
    
    UILabel *bannerLabel = [[UILabel alloc] init];
    bannerLabel.text = @"Banner";
    bannerLabel.font = [UIFont boldSystemFontOfSize: 18.0];
    [self.view addSubview: bannerLabel];
    
    [bannerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(interstitialLabel.mas_bottom).offset(20.0);
        make.left.equalTo(self.view.mas_left).offset(20.0);
    }];
    
    [self.bannerShowButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(interstitialLabel.mas_bottom).offset(20.0);
        make.left.equalTo(bannerLabel.mas_right).offset(20.0);
    }];
    
    [self.bannerHideButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.height.equalTo(@50);
        make.top.equalTo(interstitialLabel.mas_bottom).offset(20.0);
        make.left.equalTo(self.bannerShowButton.mas_right).offset(20.0);
    }];
    
    [self.adTypePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bannerLabel.mas_bottom).offset(20.0);
        make.height.equalTo(@100);
        make.left.equalTo(self.view.mas_left).offset(20.0);
        make.right.equalTo(self.view.mas_right).offset(-20.0);
    }];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
- (NSUInteger)supportedInterfaceOrientations
#else
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#endif
{
    return UIInterfaceOrientationMaskAll;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) onFetch: (UIView *) sender {
    NSString *adHtml = nil;
    NSURL *bundleUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
    
    if ([self.MRAIDSource hasPrefix: @"http"]) {
        NSError *error;
        NSURL *url = [NSURL URLWithString: self.MRAIDSource];
        adHtml = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error: &error];
        if (error) {
            [[[UIAlertView alloc] initWithTitle: @"Error" message: [NSString stringWithFormat: @"Could not fetch: %@", [url absoluteString]] delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil] show];
        }
    } else {
        adHtml = self.MRAIDSource;
    }
    
    if (adHtml != nil) {
        switch (sender.tag) {
            case kHZBannerViewTag:
                if (self.bannerView != nil) {
                    [self.bannerView removeFromSuperview];
                }
                
                self.bannerView = [[HZMRAIDView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 50.0)
                                                        withHtmlData: adHtml
                                                         withBaseURL: bundleUrl
                                                   supportedFeatures: kHZSupportedFeatures
                                                            delegate: self
                                                     serviceDelegate: self
                                                  rootViewController: self];
                break;
            default:
                self.interstitial = [[HZMRAIDInterstitial alloc] initWithSupportedFeatures: kHZSupportedFeatures
                                                                              withHtmlData:adHtml
                                                                               withBaseURL:bundleUrl
                                                                                  delegate:self
                                                                           serviceDelegate:self
                                                                        rootViewController:self];
                break;
        }
    }
}

- (void) onShow: (UIView *) sender {
    switch (sender.tag) {
        case kHZBannerViewTag:
            if (self.bannerView == nil || self.bannerView.superview == nil) {

                [self onFetch: sender];
                
                [self.view addSubview: self.bannerView];
                [self.bannerView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(self.view.mas_left);
                    make.right.equalTo(self.view.mas_right);
                    make.width.equalTo(@320.0);
                    make.height.equalTo(@50.0);
                    make.bottom.equalTo(self.view.mas_bottom);
                }];
            }
            break;
        default:
            if (self.interstitial != nil && [self.interstitial isAdReady]) {
                [self.interstitial show];
            }
            
            break;
    }
}

- (void) onHide: (UIView *) sender {
    switch (sender.tag) {
        case kHZBannerViewTag:
            if (self.bannerView != nil && self.bannerView.superview != nil) {
                [self.bannerView removeFromSuperview];
                self.bannerView = nil;
            }
            break;
        default:
            break;
    }
}

#pragma mark - MRAID Interstitial Ad Ready

- (void)mraidInterstitialAdReady:(HZMRAIDInterstitial *)mraidInterstitial {
    [self.interstitialShowButton setTitleColor: [UIColor greenColor] forState: UIControlStateNormal];
    self.interstitialShowButton.enabled = YES;
}
- (void)mraidInterstitialAdFailed:(HZMRAIDInterstitial *)mraidInterstitial {
    
    
    
}
- (void)mraidInterstitialWillShow:(HZMRAIDInterstitial *)mraidInterstitial {
    
    
    
}
- (void)mraidInterstitialDidHide:(HZMRAIDInterstitial *)mraidInterstitial {
    self.interstitialShowButton.enabled = NO;
}



- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON {
    
    
    
}

- (void)mraidServicePlayVideoWithURL:(NSURL *)URL {
    [self dismissViewControllerAnimated: YES completion:^{
        [self presentMoviePlayerViewControllerAnimated: [[MPMoviePlayerViewController alloc] initWithContentURL: URL]];
    }];
}

- (void)mraidServiceOpenBrowserWithURL:(NSURL *)URL {
    [[UIApplication sharedApplication] openURL: URL];
}

- (void)mraidServiceStorePictureWithURL:(NSURL *)URL {
    [[UIApplication sharedApplication] openURL: URL];
    
}

- (void)mraidInterstitialNavigate:(HZMRAIDInterstitial *)mraidInterstitial withURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL: url];
}

// This callback is to ask permission to resize an ad.
- (BOOL)mraidViewShouldResize:(HZMRAIDView *)mraidView toPosition:(CGRect)position allowOffscreen:(BOOL)allowOffscreen {
    return YES;
}

#pragma mark - HZMRAIDViewDelegate

- (void)mraidViewAdReady:(HZMRAIDView *)mraidView {
    
    
    
}
- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView {
    
    
    
}

- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView {
    
    
    
}

- (void)mraidViewDidClose:(HZMRAIDView *)mraidView {
    
    
    
}

- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL: url];
}

#pragma mark - Blah

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSArray *options = @[HZDemandSourceMRAIDMediabrixPhone, HZDemandSourceMRAIDMediabrixTablet, HZDemandSourceMRAIDDiagnosticURL, HZDemandSourceMRAIDBannerExpandLockedPortrait, HZDemandSourceMRAIDBannerExpandCentered, HZDemandSourceMRAIDBannerResize, HZDemandSourceMRAIDVideoInterstitial];
    self.MRAIDSource = [options objectAtIndex: row];
}

#define kSourceNames @[@"MediaBrix Phone", @"MediaBrix Tablet", @"Diagnostic", @"Banner Expanded Locked Portrait", @"Banner Expand Center", @"Banner Resizable", @"Video Interstitial"];

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return pickerView.frame.size.width;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 20.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray *options = kSourceNames;
    return [options objectAtIndex: row];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    NSArray *options = kSourceNames;

    return [options count];
}
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

@end
