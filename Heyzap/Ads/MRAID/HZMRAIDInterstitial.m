//
//  SKMRAIDInterstitial.m
//  MRAID
//
//  Created by Jay Tucker on 10/18/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDInterstitial.h"
#import "HZMRAIDView.h"
#import "HZSKLogger.h"
#import "HZMRAIDServiceDelegate.h"
#import "HZLog.h"

@interface HZMRAIDInterstitial () <HZMRAIDViewDelegate, HZMRAIDServiceDelegate>

@property (nonatomic) BOOL isReady;
@property (nonatomic, strong) HZMRAIDView *mraidView;
@property (nonatomic, strong) NSArray *supportedFeatures;

@end

@interface HZMRAIDView()


- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
     asInterstitial:(BOOL)isInter
  supportedFeatures:(NSArray *)features
           delegate:(id<HZMRAIDViewDelegate>)delegate
   serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController;

@end

@implementation HZMRAIDInterstitial

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class MRAIDInterstitial"
                                 userInfo:nil];
    return nil;
}

// designated initializer
- (id)initWithSupportedFeatures:(NSArray *)features
                   withHtmlData:(NSString*)htmlData
                    withBaseURL:(NSURL*)bsURL
                       delegate:(id<HZMRAIDInterstitialDelegate>)delegate
               serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
             rootViewController:(UIViewController *)rootViewController
{
    self = [super init];
    if (self) {
        self.supportedFeatures = features;
        self.delegate = delegate;
        self.serviceDelegate = serviceDelegate;
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        self.mraidView = [[HZMRAIDView alloc] initWithFrame:screenRect
                                        withHtmlData:htmlData
                                         withBaseURL:bsURL
                                      asInterstitial:YES
                                   supportedFeatures:self.supportedFeatures
                                            delegate:self
                                    serviceDelegate:self
                                  rootViewController:rootViewController];
        self.isViewable = NO;
        _isReady = NO;
    }
    return self;
}

- (BOOL)isAdReady
{
    return _isReady;
}

- (void)show
{
    if (!self.isReady) {
        [HZSKLogger warning:@"MRAID - Interstitial" withMessage:@"interstitial is not ready to show"];
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [self.mraidView performSelector:@selector(showAsInterstitial)];
#pragma clang diagnostic pop
}

#pragma mark - isViewable

- (BOOL) isViewable {
    return self.mraidView.isViewable;
}

- (void) setIsViewable:(BOOL)newIsViewable
{
    [HZSKLogger debug:@"MRAID - Interstitial" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    self.mraidView.isViewable=newIsViewable;
}

#pragma mark - rootViewController

- (UIViewController *) rootViewController {
    return self.mraidView.rootViewController;
}

- (void) setRootViewController:(UIViewController *)newRootViewController
{
    self.mraidView.rootViewController = newRootViewController;
    [HZSKLogger debug:@"MRAID - Interstitial" withMessage:[NSString stringWithFormat:@"setRootViewController: %@", newRootViewController]];

}

#pragma mark - setBackgroundColor

- (UIColor *) backgroundColor {
    return self.mraidView.backgroundColor;
}

-(void) setBackgroundColor:(UIColor *)newBackgroundColor {
    self.mraidView.backgroundColor = newBackgroundColor;
}

#pragma mark - MRAIDViewDelegate

- (void)mraidViewAdReady:(HZMRAIDView *)mraidView
{
    HZDLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    self.isReady = YES;
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialAdReady:)]) {
        [self.delegate mraidInterstitialAdReady:self];
    }
}

- (void)mraidViewAdFailed:(HZMRAIDView *)mraidView
{
    HZDLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    self.isReady = YES;
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialAdFailed:)]) {
        [self.delegate mraidInterstitialAdFailed:self];
    }
}

- (void)mraidViewWillExpand:(HZMRAIDView *)mraidView
{
    HZDLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialWillShow:)]) {
        [self.delegate mraidInterstitialWillShow:self];
    }
}

- (void)mraidViewDidClose:(HZMRAIDView *)mv
{
    HZDLog(@"%@ MRAIDViewDelegate %@", [[self class] description], NSStringFromSelector(_cmd));
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialDidHide:)]) {
        [self.delegate mraidInterstitialDidHide:self];
    }
    self.mraidView.delegate = nil;
    self.mraidView.rootViewController = nil;
    self.mraidView = nil;
    self.isReady = NO;
}

- (void)mraidViewNavigate:(HZMRAIDView *)mraidView withURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(mraidInterstitialNavigate:withURL:)]) {
        [self.delegate mraidInterstitialNavigate:self withURL:url];
    }
}

#pragma mark - MRAIDServiceDelegate callbacks

- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSON
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceCreateCalendarEventWithEventJSON:)]) {
        [self.serviceDelegate mraidServiceCreateCalendarEventWithEventJSON:eventJSON];
    }
}

- (void)mraidServicePlayVideoWithURL:(NSURL *)URL
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServicePlayVideoWithURL:)]) {
        [self.serviceDelegate mraidServicePlayVideoWithURL:URL];
    }
}

- (void)mraidServiceOpenBrowserWithURL:(NSURL *)URL
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceOpenBrowserWithURL:)]) {
        [self.serviceDelegate mraidServiceOpenBrowserWithURL:URL];
    }
}

- (void)mraidServiceStorePictureWithURL:(NSURL *)URL
{
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceStorePictureWithURL:)]) {
        [self.serviceDelegate mraidServiceStorePictureWithURL:URL];
    }
}

@end
