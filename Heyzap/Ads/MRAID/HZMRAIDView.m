//
//  SKMRAIDView.m
//  MRAID
//
//  Created by Jay Tucker on 9/13/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDView.h"
#import "HZMRAIDOrientationProperties.h"
#import "HZMRAIDResizeProperties.h"
#import "HZMRAIDCommand.h"
#import "HZMRAIDModalViewController.h"
#import "HZMRAIDServiceDelegate.h"
#import "HZMRAIDUtil.h"
#import "HZMRAIDSettings.h"

#import "HZMRAIDLogger.h"

#import "HZMRAIDJS.h"
#import "CloseButton.h"

#define kCloseEventRegionSize 50
#define SYSTEM_VERSION_LESS_THAN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

typedef enum {
    HZMRAIDStateLoading,
    HZMRAIDStateDefault,
    HZMRAIDStateExpanded,
    HZMRAIDStateResized,
    HZMRAIDStateHidden
} HZMRAIDState;

@interface HZMRAIDView () <UIWebViewDelegate, HZMRAIDModalViewControllerDelegate, UIGestureRecognizerDelegate>
{
    HZMRAIDState state;
    // This corresponds to the MRAID placement type.
    BOOL isInterstitial;
    
    // The only property of the MRAID expandProperties we need to keep track of
    // on the native side is the useCustomClose property.
    // The width, height, and isModal properties are not used in MRAID v2.0.
    BOOL useCustomClose;
    
    HZMRAIDOrientationProperties *orientationProperties;
    HZMRAIDResizeProperties *resizeProperties;
    
    HZMRAIDModalViewController *modalVC;
    
    NSString *mraidjs;
    
    NSURL *baseURL;
    
    NSArray *mraidFeatures;
    NSArray *supportedFeatures;
    
    UIWebView *webView;
    UIWebView *webViewPart2;
    UIWebView *currentWebView;
    
    UIButton *closeEventRegion;
    
    UIView *resizeView;
    UIButton *resizeCloseRegion;
    
    CGSize previousMaxSize;
    CGSize previousScreenSize;
    
    UITapGestureRecognizer *tapGestureRecognizer;
    BOOL bonafideTapObserved;
    
    BOOL _isViewable;
}

@end

@implementation HZMRAIDView

- (id)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class MRAIDView"
                                 userInfo:nil];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-initWithFrame is not a valid initializer for the class MRAIDView"
                                 userInfo:nil];
    return nil;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-initWithCoder is not a valid initializer for the class MRAIDView"
                                 userInfo:nil];
    return nil;
}

- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
  supportedFeatures:(NSArray *)features
           delegate:(id<HZMRAIDViewDelegate>)delegate
   serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController
{
    return [self initWithFrame:frame
                  withHtmlData:htmlData
                   withBaseURL:bsURL
                asInterstitial:NO
             supportedFeatures:features
                      delegate:delegate
              serviceDelegate:serviceDelegate
            rootViewController:rootViewController];
}

// designated initializer
- (id)initWithFrame:(CGRect)frame
       withHtmlData:(NSString*)htmlData
        withBaseURL:(NSURL*)bsURL
     asInterstitial:(BOOL)isInter
  supportedFeatures:(NSArray *)currentFeatures
           delegate:(id<HZMRAIDViewDelegate>)delegate
   serviceDelegate:(id<HZMRAIDServiceDelegate>)serviceDelegate
 rootViewController:(UIViewController *)rootViewController
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpTapGestureRecognizer];
        isInterstitial = isInter;
        _delegate = delegate;
        _serviceDelegate = serviceDelegate;
        self.rootViewController = rootViewController;
        
        state = HZMRAIDStateLoading;
        
        self.isViewable = NO;
        useCustomClose = NO;
        
        orientationProperties = [[HZMRAIDOrientationProperties alloc] init];
        resizeProperties = [[HZMRAIDResizeProperties alloc] init];
        
        mraidFeatures = @[
                          HZMRAIDSupportsSMS,
                          HZMRAIDSupportsTel,
                          HZMRAIDSupportsCalendar,
                          HZMRAIDSupportsStorePicture,
                          HZMRAIDSupportsInlineVideo,
                          ];
        
        if([self isValidFeatureSet:currentFeatures] && serviceDelegate){
            supportedFeatures=currentFeatures;
        }
        
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        webView.opaque = NO;
        webView.backgroundColor = [UIColor clearColor];
        [self initWebView:webView];
        currentWebView = webView;
        [self addSubview:webView];
        
        previousMaxSize = CGSizeZero;
        previousScreenSize = CGSizeZero;
        
        [self addObserver:self forKeyPath:@"self.frame" options:NSKeyValueObservingOptionOld context:NULL];
 
        // Get mraid.js as binary data
        NSData* mraidJSData = [NSData dataWithBytesNoCopy:__Ads_MRAID_mraid_js
                                                   length:__Ads_MRAID_mraid_js_len
                                             freeWhenDone:NO];
        mraidjs = [[NSString alloc] initWithData:mraidJSData encoding:NSUTF8StringEncoding];
        mraidJSData = nil;
        
        baseURL = bsURL;
        state = HZMRAIDStateLoading;
        
        if (mraidjs) {
            [self injectJavaScript:mraidjs];
        }
        
        htmlData = [HZMRAIDUtil processRawHtml:htmlData];
        if (htmlData) {
            [currentWebView loadHTMLString:htmlData baseURL:baseURL];
        } else {
            [HZMRAIDLogger error:@"MRAID - View" withMessage:@"Ad HTML is invalid, cannot load"];
            if ([self.delegate respondsToSelector:@selector(mraidViewAdFailed:)]) {
                [self.delegate mraidViewAdFailed:self];
            }
        }
        if (isInter) {
            bonafideTapObserved = YES;  // no autoRedirect suppression for Interstitials
        }
    }
    return self;
}

- (void)cancel
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:@"cancel"];
    [currentWebView stopLoading];
    currentWebView = nil;
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)dealloc
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    
    [self removeObserver:self forKeyPath:@"self.frame"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (BOOL)isValidFeatureSet:(NSArray *)features
{
    NSArray *kFeatures = @[
                           HZMRAIDSupportsSMS,
                           HZMRAIDSupportsTel,
                           HZMRAIDSupportsCalendar,
                           HZMRAIDSupportsStorePicture,
                           HZMRAIDSupportsInlineVideo,
                           ];
    
    // Validate the features set by the user
    for (id feature in features) {
        if (![kFeatures containsObject:feature]) {
            [HZMRAIDLogger warning:@"MRAID - View" withMessage:[NSString stringWithFormat:@"feature %@ is unknown, no supports set", feature]];
            return NO;
        }
    }
    return YES;
}

- (void)setIsViewable:(BOOL)newIsViewable
{
    if(newIsViewable!=_isViewable){
        _isViewable=newIsViewable;
        [self fireViewableChangeEvent];
    }
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"isViewable: %@", _isViewable?@"YES":@"NO"]];
}

- (BOOL)isViewable
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    return _isViewable;
}

- (void)setRootViewController:(UIViewController *)newRootViewController
{
    if(newRootViewController!=_rootViewController) {
        _rootViewController=newRootViewController;
    }
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"setRootViewController: %@", _rootViewController]];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@ %@", [self.class description], NSStringFromSelector(_cmd)]];
    @synchronized (self) {
        [self setScreenSize];
        [self setMaxSize];
        [self setDefaultPosition];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (!([keyPath isEqualToString:@"self.frame"])) {
        return;
    }
    
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:@"self.frame has changed"];
    
    CGRect oldFrame = CGRectNull;
    CGRect newFrame = CGRectNull;
    if (change[@"old"] != [NSNull null]) {
        oldFrame = [change[@"old"] CGRectValue];
    }
    if ([object valueForKeyPath:keyPath] != [NSNull null]) {
        newFrame = [[object valueForKeyPath:keyPath] CGRectValue];
    }
    
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"old %@", NSStringFromCGRect(oldFrame)]];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"new %@", NSStringFromCGRect(newFrame)]];
    
    if (state == HZMRAIDStateResized) {
        [self setResizeViewPosition];
    }
    [self setDefaultPosition];
    [self setMaxSize];
    [self fireSizeChangeEvent];
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    currentWebView.backgroundColor = backgroundColor;
}

#pragma mark - interstitial support

- (void)showAsInterstitial
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@", NSStringFromSelector(_cmd)]];
    [self expand:nil];
}

#pragma mark - JavaScript --> native support

// These methods are (indirectly) called by JavaScript code.
// They provide the means for JavaScript code to talk to native code

- (void)executeCommand:(HZMRAIDCommand *) command {
    
    SEL selector;
    BOOL validCommand = YES;
    
    switch (command.command) {
        case HZMRAIDInternalCommandCreateCalendarEvent: selector = @selector(createCalendarEvent:); break;
        case HZMRAIDInternalCommandClose: selector = @selector(close:); break;
        case HZMRAIDInternalCommandExpand: selector = @selector(expand:); break;
        case HZMRAIDInternalCommandOpen: selector = @selector(open:); break;
        case HZMRAIDInternalCommandPlayVideo: selector = @selector(playVideo:); break;
        case HZMRAIDInternalCommandSetOrientationProperties: selector = @selector(setOrientationProperties:); break;
        case HZMRAIDInternalCommandSetResizeProperties: selector = @selector(setResizeProperties:); break;
        case HZMRAIDInternalCommandStorePicture: selector = @selector(storePicture:); break;
        case HZMRAIDInternalCommandUseCustomClose: selector = @selector(useCustomClose:); break;
        case HZMRAIDInternalCommandResize: selector = @selector(resize:); break;
        case HZMRAIDInternalCommandUndefined:
        default:
            validCommand = NO;
            break;
    }
    
    
    
    if (validCommand && [self respondsToSelector: selector]) {
        // Turn off the warning "PerformSelector may cause a leak because its selector is unknown".
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector: selector withObject: command.params];
#pragma clang diagnostic pop
    } else {
        [HZMRAIDLogger warning:@"MRAID - View" withMessage:[NSString stringWithFormat:@"invalid command attempted"]];
    }
}

- (void)close: (id) obj
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@", NSStringFromSelector(_cmd)]];
    
    if (state == HZMRAIDStateLoading ||
        (state == HZMRAIDStateDefault && !isInterstitial) ||
        state == HZMRAIDStateHidden) {
        // do nothing
        return;
    }
    
    if (state == HZMRAIDStateResized) {
        [self closeFromResize];
        return;
    }
    
    if (modalVC) {
        [closeEventRegion removeFromSuperview];
        closeEventRegion = nil;
        [currentWebView removeFromSuperview];
        if ([modalVC respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            // used if running >= iOS 6
            [modalVC dismissViewControllerAnimated:NO completion:nil];
        } else {
            // Turn off the warning about using a deprecated method.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [modalVC dismissModalViewControllerAnimated:NO];
#pragma clang diagnostic pop
        }
    }
    
    modalVC = nil;
    
    if (webViewPart2) {
        // Clean up webViewPart2 if returning from 2-part expansion.
        webViewPart2.delegate = nil;
        currentWebView = webView;
        webViewPart2 = nil;
    } else {
        // Reset frame of webView if returning from 1-part expansion.
        webView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    }
    
    [self addSubview:webView];
    
    if (!isInterstitial) {
        [self fireSizeChangeEvent];
    } else {
        self.isViewable = NO;
        [self fireViewableChangeEvent];
    }
    
    if (state == HZMRAIDStateDefault && isInterstitial) {
        state = HZMRAIDStateHidden;
    } else if (state == HZMRAIDStateExpanded || state == HZMRAIDStateResized) {
        state = HZMRAIDStateDefault;
    }
    [self fireStateChangeEvent];
    
    if ([self.delegate respondsToSelector:@selector(mraidViewDidClose:)]) {
        [self.delegate mraidViewDidClose:self];
    }
}

// This is a helper method which is not part of the official MRAID API.
- (void)closeFromResize
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback helper %@", NSStringFromSelector(_cmd)]];
    [self removeResizeCloseRegion];
    state = HZMRAIDStateDefault;
    [self fireStateChangeEvent];
    [webView removeFromSuperview];
    webView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:webView];
    [resizeView removeFromSuperview];
    resizeView = nil;
    [self fireSizeChangeEvent];
    if ([self.delegate respondsToSelector:@selector(mraidViewDidClose:)]) {
        [self.delegate mraidViewDidClose:self];
    }
}

- (void)createCalendarEvent:(NSDictionary *)params
{
    
    NSString *eventJSON = [params objectForKey: @"eventJSON"];
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.createCalendarEvent() when no UI touch event exists."];
        return;  // ignore programmatic touches (taps)
    }

    eventJSON=[eventJSON stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), eventJSON]];
    
    if ([supportedFeatures containsObject:HZMRAIDSupportsCalendar]) {
        if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceCreateCalendarEventWithEventJSON:)]) {
            [self.serviceDelegate mraidServiceCreateCalendarEventWithEventJSON:eventJSON];
        }
    } else {
        [HZMRAIDLogger warning:@"MRAID - View" withMessage:[NSString stringWithFormat:@"No calendar support has been included."]];
   }
}

// Note: This method is also used to present an interstitial ad.
- (void)expand:(NSDictionary *)params {
    
    NSString *urlString = nil;
    if (params != nil) {
        urlString = [params objectForKey: @"url"];
    }
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.expand() when no UI touch event exists."];
        return;  // ignore programmatic touches (taps)
    }
    
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), (urlString ? urlString : @"1-part")]];
    
    // The only time it is valid to call expand is when the ad is currently in either default or resized state.
    if (state != HZMRAIDStateDefault && state != HZMRAIDStateResized) {
        // do nothing
        return;
    }
    
    modalVC = [[HZMRAIDModalViewController alloc] initWithOrientationProperties:orientationProperties];
    CGRect frame = [[UIScreen mainScreen] bounds];
    modalVC.view.frame = frame;
    modalVC.delegate = self;
    
    if (!urlString) {
        // 1-part expansion
        webView.frame = frame;
        [webView removeFromSuperview];
    } else {
        // 2-part expansion
        webViewPart2 = [[UIWebView alloc] initWithFrame:frame];
        [self initWebView:webViewPart2];
        currentWebView = webViewPart2;
        bonafideTapObserved = YES; // by definition for 2 part expand a valid tap has occurred
        
        if (mraidjs) {
            [self injectJavaScript:mraidjs];
        }
        
        // Check to see whether we've been given an absolute or relative URL.
        // If it's relative, prepend the base URL.
        urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (![[NSURL URLWithString:urlString] scheme]) {
            // relative URL
            urlString = [[[baseURL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAppendingString:urlString];
        }
        
        // Need to escape characters which are URL specific
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSString *content = [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            [webViewPart2 loadHTMLString:content baseURL:baseURL];
        } else {
            // Error! Clean up and return.
            [HZMRAIDLogger error:@"MRAID - View" withMessage:[NSString stringWithFormat:@"Could not load part 2 expanded content for URL: %@" ,urlString]];
            currentWebView = webView;
            webViewPart2.delegate = nil;
            webViewPart2 = nil;
            modalVC = nil;
            return;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(mraidViewWillExpand:)]) {
        [self.delegate mraidViewWillExpand:self];
    }
    
    [modalVC.view addSubview:currentWebView];
    
    // always include the close event region
    [self addCloseEventRegion];
    
    if ([self.rootViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        // used if running >= iOS 6
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {  // respect clear backgroundColor
            self.rootViewController.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
        } else {
            self.rootViewController.providesPresentationContextTransitionStyle = YES;
            self.rootViewController.definesPresentationContext = YES;
            modalVC.modalPresentationStyle = UIModalPresentationCustom;
        }
        
        [self.rootViewController presentViewController:modalVC animated: NO completion:nil];
    } else {
        // Turn off the warning about using a deprecated method.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.rootViewController presentModalViewController:modalVC animated:NO];
#pragma clang diagnostic pop
    }
    
    if (!isInterstitial) {
        state = HZMRAIDStateExpanded;
        [self fireStateChangeEvent];
    }
    
    [self fireSizeChangeEvent];
    self.isViewable = YES;
}

- (void)open:(NSDictionary *) params {
    NSString *urlString = [params objectForKey: @"url"];
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.open() when no UI touch event exists."];
       return;  // ignore programmatic touches (taps)
    }
    
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), urlString]];
    
    NSURL *url = [NSURL URLWithString: urlString];
    
    // Notify the callers
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceOpenBrowserWithURL:)]) {
        [self.serviceDelegate mraidServiceOpenBrowserWithURL:url];
    }
}

- (void)playVideo:(NSDictionary *) params {
    
    NSString *urlString = [params objectForKey: @"url"];
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.playVideo() when no UI touch event exists."];
        return;  // ignore programmatic touches (taps)
    }
    
    urlString = [urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString: urlString];
    
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), urlString]];
    if ([self.serviceDelegate respondsToSelector:@selector(mraidServicePlayVideoWithURL:)]) {
        [self.serviceDelegate mraidServicePlayVideoWithURL:url];
    }
}

- (void)resize: (NSDictionary *) params {
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.resize when no UI touch event exists."];
        return;  // ignore programmatic touches (taps)
    }
    
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@", NSStringFromSelector(_cmd)]];
    // If our delegate doesn't respond to the mraidViewShouldResizeToPosition:allowOffscreen: message,
    // then we can't do anything. We need help from the app here.
    if (![self.delegate respondsToSelector:@selector(mraidViewShouldResize:toPosition:allowOffscreen:)]) {
        return;
    }
    
    CGRect resizeFrame = CGRectMake(resizeProperties.offsetX, resizeProperties.offsetY, resizeProperties.width, resizeProperties.height);
    // The offset of the resize frame is relative to the origin of the default banner.
    CGPoint bannerOriginInRootView = [self.rootViewController.view convertPoint:CGPointZero fromView:self];
    resizeFrame.origin.x += bannerOriginInRootView.x;
    resizeFrame.origin.y += bannerOriginInRootView.y;
    
    if (![self.delegate mraidViewShouldResize:self toPosition:resizeFrame allowOffscreen:resizeProperties.allowOffscreen]) {
        return;
    }
    
    // resize here
    state = HZMRAIDStateResized;
    [self fireStateChangeEvent];
    
    if (!resizeView) {
        resizeView = [[UIView alloc] initWithFrame:resizeFrame];
        [webView removeFromSuperview];
        [resizeView addSubview:webView];
        [self.rootViewController.view addSubview:resizeView];
    }
    
    resizeView.frame = resizeFrame;
    webView.frame = resizeView.bounds;
    [self showResizeCloseRegion];
    [self fireSizeChangeEvent];
}

- (void)setOrientationProperties:(NSDictionary *)properties {
    
    BOOL allowOrientationChange = [[properties valueForKey:@"allowOrientationChange"] boolValue];
    NSString *forceOrientation = [properties valueForKey:@"forceOrientation"];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@ %@", NSStringFromSelector(_cmd), (allowOrientationChange ? @"YES" : @"NO"), forceOrientation]];
    orientationProperties.allowOrientationChange = allowOrientationChange;
    orientationProperties.forceOrientation = [HZMRAIDOrientationProperties MRAIDForceOrientationFromString:forceOrientation];
    [modalVC forceToOrientation:orientationProperties];
}

- (void)setResizeProperties:(NSDictionary *)properties {
    
    int width = [[properties valueForKey:@"width"] intValue];
    int height = [[properties valueForKey:@"height"] intValue];
    int offsetX = [[properties valueForKey:@"offsetX"] intValue];
    int offsetY = [[properties valueForKey:@"offsetY"] intValue];
    NSString *customClosePosition = [properties valueForKey:@"customClosePosition"];
    BOOL allowOffscreen = [[properties valueForKey:@"allowOffscreen"] boolValue];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %d %d %d %d %@ %@", NSStringFromSelector(_cmd), width, height, offsetX, offsetY, customClosePosition, (allowOffscreen ? @"YES" : @"NO")]];
    resizeProperties.width = width;
    resizeProperties.height = height;
    resizeProperties.offsetX = offsetX;
    resizeProperties.offsetY = offsetY;
    resizeProperties.customClosePosition = [HZMRAIDResizeProperties MRAIDCustomClosePositionFromString:customClosePosition];
    resizeProperties.allowOffscreen = allowOffscreen;
}

-(void)storePicture:(NSDictionary *) params {
    
    NSString *urlString = [params objectForKey: @"url"];
    
    if(!bonafideTapObserved && SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        [HZMRAIDLogger info:@"MRAID - View" withMessage:@"Suppressing an attempt to programmatically call mraid.storePicture when no UI touch event exists."];
        return;  // ignore programmatic touches (taps)
    }
    
    urlString=[urlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), urlString]];
    
    NSURL *url = [NSURL URLWithString: urlString];
    
    if ([supportedFeatures containsObject:HZMRAIDSupportsStorePicture]) {
        if ([self.serviceDelegate respondsToSelector:@selector(mraidServiceStorePictureWithURL:)]) {
            [self.serviceDelegate mraidServiceStorePictureWithURL:url];
        }
    } else {
        [HZMRAIDLogger warning:@"MRAID - View" withMessage:[NSString stringWithFormat:@"No MRAIDSupportsStorePicture feature has been included"]];
    }
}

- (void)useCustomClose:(NSDictionary *)params {
    
    BOOL isCustomClose = [(NSString *)[params objectForKey: @"isCustomClose"] boolValue];
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@ %@", NSStringFromSelector(_cmd), (isCustomClose ? @"YES" : @"NO")]];
    useCustomClose = isCustomClose;
}

#pragma mark - JavaScript --> native support helpers

// These methods are helper methods for the ones above.

- (void)addCloseEventRegion
{
    closeEventRegion = [UIButton buttonWithType:UIButtonTypeCustom];
    closeEventRegion.backgroundColor = [UIColor clearColor];
    [closeEventRegion addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    
    if (!useCustomClose) {
        // get button image from header file
        NSData* buttonData = [NSData dataWithBytesNoCopy:__Ads_MRAID_CloseButton_png
                                                  length:__Ads_MRAID_CloseButton_png_len
                                            freeWhenDone:NO];
        UIImage *closeButtonImage = [UIImage imageWithData:buttonData];
        [closeEventRegion setBackgroundImage:closeButtonImage forState:UIControlStateNormal];
    }
    
    closeEventRegion.frame = CGRectMake(0, 0, kCloseEventRegionSize, kCloseEventRegionSize);
    CGRect frame = closeEventRegion.frame;
    
    // align on top right
    int x = CGRectGetWidth(modalVC.view.frame) - CGRectGetWidth(frame);
    frame.origin = CGPointMake(x, 0);
    closeEventRegion.frame = frame;
    // autoresizing so it stays at top right (flexible left and flexible bottom margin)
    closeEventRegion.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [modalVC.view addSubview:closeEventRegion];
}

- (void)showResizeCloseRegion
{
    if (!resizeCloseRegion) {
        resizeCloseRegion = [UIButton buttonWithType:UIButtonTypeCustom];
        resizeCloseRegion.frame = CGRectMake(0, 0, kCloseEventRegionSize, kCloseEventRegionSize);
        resizeCloseRegion.backgroundColor = [UIColor clearColor];
        [resizeCloseRegion addTarget:self action:@selector(closeFromResize) forControlEvents:UIControlEventTouchUpInside];
        [resizeView addSubview:resizeCloseRegion];
    }
    
    // align appropriately
    int x;
    int y;
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingNone;
    
    switch (resizeProperties.customClosePosition) {
        case HZMRAIDCustomClosePositionTopLeft:
        case HZMRAIDCustomClosePositionBottomLeft:
            x = 0;
            break;
        case HZMRAIDCustomClosePositionTopCenter:
        case HZMRAIDCustomClosePositionCenter:
        case HZMRAIDCustomClosePositionBottomCenter:
            x = (CGRectGetWidth(resizeView.frame) - CGRectGetWidth(resizeCloseRegion.frame)) / 2;
            autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case HZMRAIDCustomClosePositionTopRight:
        case HZMRAIDCustomClosePositionBottomRight:
            x = CGRectGetWidth(resizeView.frame) - CGRectGetWidth(resizeCloseRegion.frame);
            autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            break;
    }
    
    switch (resizeProperties.customClosePosition) {
        case HZMRAIDCustomClosePositionTopLeft:
        case HZMRAIDCustomClosePositionTopCenter:
        case HZMRAIDCustomClosePositionTopRight:
            y = 0;
            break;
        case HZMRAIDCustomClosePositionCenter:
            y = (CGRectGetHeight(resizeView.frame) - CGRectGetHeight(resizeCloseRegion.frame)) / 2;
            autoresizingMask |= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        case HZMRAIDCustomClosePositionBottomLeft:
        case HZMRAIDCustomClosePositionBottomCenter:
        case HZMRAIDCustomClosePositionBottomRight:
            y = CGRectGetHeight(resizeView.frame) - CGRectGetHeight(resizeCloseRegion.frame);
            autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
            break;
    }
    
    CGRect resizeCloseRegionFrame = resizeCloseRegion.frame;
    resizeCloseRegionFrame.origin = CGPointMake(x, y);
    resizeCloseRegion.frame = resizeCloseRegionFrame;
    resizeCloseRegion.autoresizingMask = autoresizingMask;
}

- (void)removeResizeCloseRegion
{
    if (resizeCloseRegion) {
        [resizeCloseRegion removeFromSuperview];
        resizeCloseRegion = nil;
    }
}

- (void)setResizeViewPosition
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@", NSStringFromSelector(_cmd)]];
    CGRect oldResizeFrame = resizeView.frame;
    CGRect newResizeFrame = CGRectMake(resizeProperties.offsetX, resizeProperties.offsetY, resizeProperties.width, resizeProperties.height);
    // The offset of the resize frame is relative to the origin of the default banner.
    CGPoint bannerOriginInRootView = [self.rootViewController.view convertPoint:CGPointZero fromView:self];
    newResizeFrame.origin.x += bannerOriginInRootView.x;
    newResizeFrame.origin.y += bannerOriginInRootView.y;
    if (!CGRectEqualToRect(oldResizeFrame, newResizeFrame)) {
        resizeView.frame = newResizeFrame;
    }
}

#pragma mark - native -->  JavaScript support

- (void)injectJavaScript:(NSString *)js
{    
    [currentWebView stringByEvaluatingJavaScriptFromString:js];
}

// convenience methods
- (void)fireErrorEventWithAction:(NSString *)action message:(NSString *)message
{
    [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireErrorEvent('%@','%@');", message, action]];
}

- (void)fireReadyEvent
{
    [self injectJavaScript:@"mraid.fireReadyEvent()"];
}

- (void)fireSizeChangeEvent
{
    @synchronized(self){
        int x;
        int y;
        int width;
        int height;
        
        UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
        [HZMRAIDLogger debug: @"Orienatation" withMessage: (isLandscape ?  @"landscape" : @"portrait")];
        
        if (state == HZMRAIDStateExpanded || isInterstitial) {
            
            x = (int)currentWebView.frame.origin.x;
            y = (int)currentWebView.frame.origin.y;
            
            width = (int)currentWebView.frame.size.width;
            height = (int)currentWebView.frame.size.height;
            
        } else if (state == HZMRAIDStateResized) {
            
            x = (int)resizeView.frame.origin.x;
            y = (int)resizeView.frame.origin.y;
            width = (int)resizeView.frame.size.width;
            height = (int)resizeView.frame.size.height;
            
        } else {
            // Per the MRAID spec, the current or default position is relative to the rectangle defined by the getMaxSize method,
            // that is, the largest size that the ad can resize to.
            CGPoint originInRootView = [self.rootViewController.view convertPoint:CGPointZero fromView:self];
            x = originInRootView.x;
            y = originInRootView.y;
            width = (int)self.frame.size.width;
            height = (int)self.frame.size.height;
        }
        
        BOOL adjustOrientationForIOS8 = NO;
        
        //BOOL adjustOrientationForIOS8 = isInterstitial &&  isLandscape && !SYSTEM_VERSION_LESS_THAN(@"8.0");
        
        //[self injectJavaScript: [NSString stringWithFormat: @"mraid.fireSizeChangeEvent(%d, %d);", adjustOrientationForIOS8?height:width, adjustOrientationForIOS8?width:height]];
        
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setCurrentPosition(%d,%d,%d,%d);", x, y, adjustOrientationForIOS8?height:width, adjustOrientationForIOS8?width:height]];
    }
}

- (void)fireStateChangeEvent
{
    @synchronized(self) {
        NSArray *stateNames = @[
                                @"loading",
                                @"default",
                                @"expanded",
                                @"resized",
                                @"hidden",
                                ];
        
        NSString *stateName = stateNames[state];
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireStateChangeEvent('%@');", stateName]];
    }
}

- (void)fireViewableChangeEvent
{
    [self injectJavaScript:[NSString stringWithFormat:@"mraid.fireViewableChangeEvent(%@);", (self.isViewable ? @"true" : @"false")]];
}

- (void)setDefaultPosition
{
    if (isInterstitial) {
        // For interstitials, we define defaultPosition to be the same as screen size, so set the value there.
        return;
    }
    
    // getDefault position from the parent frame if we are not directly added to the rootview
    if(self.superview != self.rootViewController.view) {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(%f,%f,%f,%f);", self.superview.frame.origin.x, self.superview.frame.origin.y, self.superview.frame.size.width, self.superview.frame.size.height]];
    } else {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(%f,%f,%f,%f);", self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height]];
    }
}

-(void)setMaxSize
{
    if (isInterstitial) {
        // For interstitials, we define maxSize to be the same as screen size, so set the value there.
        return;
    }
    CGSize maxSize = self.rootViewController.view.bounds.size;
    if (!CGSizeEqualToSize(maxSize, previousMaxSize)) {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setMaxSize(%d,%d);",
                                (int)maxSize.width,
                                (int)maxSize.height]];
        previousMaxSize = CGSizeMake(maxSize.width, maxSize.height);
    }
}

-(void)setScreenSize
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    // screenSize is ALWAYS for portrait orientation, so we need to figure out the
    // actual interface orientation to get the correct current screenRect.
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    // [SKLogger debug:[NSString stringWithFormat:@"orientation is %@", (isLandscape ?  @"landscape" : @"portrait")]];
   
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        screenSize = CGSizeMake(screenSize.width, screenSize.height);
    } else {
        if (isLandscape) {
            screenSize = CGSizeMake(screenSize.height, screenSize.width);
        }
    }
    if (!CGSizeEqualToSize(screenSize, previousScreenSize)) {
        [self injectJavaScript:[NSString stringWithFormat:@"mraid.setScreenSize(%d,%d);",
                                (int)screenSize.width,
                                (int)screenSize.height]];
        previousScreenSize = CGSizeMake(screenSize.width, screenSize.height);
        if (isInterstitial) {
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setMaxSize(%d,%d);",
                                    (int)screenSize.width,
                                    (int)screenSize.height]];
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setDefaultPosition(0,0,%d,%d);",
                                    (int)screenSize.width,
                                    (int)screenSize.height]];
        }
    }
}

-(void)setSupports:(NSArray *)currentFeatures
{
    for (id aFeature in mraidFeatures) {
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setSupports('%@',%@);", aFeature,[currentFeatures containsObject:aFeature]?@"true":@"false"]];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)wv
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@", NSStringFromSelector(_cmd)]];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv
{
    @synchronized(self) {
        [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@", NSStringFromSelector(_cmd)]];
        
        // If wv is webViewPart2, that means the part 2 expanded web view has just loaded.
        // In this case, state should already be MRAIDStateExpanded and should not be changed.
        // if (wv != webViewPart2) {
        
        if (SK_ENABLE_JS_LOG) {
            [wv stringByEvaluatingJavaScriptFromString:@"var enableLog = true"];
        }
        
        if (SK_SUPPRESS_JS_ALERT) {
            [wv stringByEvaluatingJavaScriptFromString:@"function alert(){}; function prompt(){}; function confirm(){}"];
        }
        
        if (state == HZMRAIDStateLoading) {
            state = HZMRAIDStateDefault;
            [self injectJavaScript:[NSString stringWithFormat:@"mraid.setPlacementType('%@');", (isInterstitial ? @"interstitial" : @"inline")]];
            [self setSupports:supportedFeatures];
            [self setDefaultPosition];
            [self setMaxSize];
            [self setScreenSize];
            [self fireStateChangeEvent];
            [self fireSizeChangeEvent];
            [self fireReadyEvent];
            
            if ([self.delegate respondsToSelector:@selector(mraidViewAdReady:)]) {
                [self.delegate mraidViewAdReady:self];
            }
            
            // Start monitoring device orientation so we can reset max Size and screenSize if needed.
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(deviceOrientationDidChange:)
                                                         name:UIDeviceOrientationDidChangeNotification
                                                       object:nil];
        }
    }
}

- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)error
{
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"JS callback %@", NSStringFromSelector(_cmd)]];
}

- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSString *scheme = [url scheme];
    NSString *absUrlString = [url absoluteString];
    
    if ([request.URL.scheme isEqualToString:@"mraid"]) {
        HZMRAIDCommand *command = [[HZMRAIDCommand alloc] initWithURL: request.URL];
        [self executeCommand: command];
    } else if ([scheme isEqualToString:@"console-log"]) {
        [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"JS console: %@",
                          [[absUrlString substringFromIndex:14] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding ]]];
    } else {
        [HZMRAIDLogger info:@"MRAID - View" withMessage:[NSString stringWithFormat:@"Found URL %@ with type %@", absUrlString, @(navigationType)]];
        
        // Links, Form submissions
        if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            // For banner views
            if ([self.delegate respondsToSelector:@selector(mraidViewNavigate:withURL:)]) {
                [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat:@"JS webview load: %@",
                                                                    [absUrlString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                [self.delegate mraidViewNavigate:self withURL:url];
            }
        } else {
            // Need to let browser to handle rendering and other things
            return YES;
        }
    }
    return NO;
}

#pragma mark - MRAIDModalViewControllerDelegate

- (void)mraidModalViewControllerDidRotate:(HZMRAIDModalViewController *)modalViewController {
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:[NSString stringWithFormat: @"%@", NSStringFromSelector(_cmd)]];
    
    @synchronized (self) {
        [self setScreenSize];
        [self setMaxSize];
        [self setDefaultPosition];
        [self fireSizeChangeEvent];
    }
}

#pragma mark - internal helper methods

- (void)initWebView:(UIWebView *)wv
{
    wv.delegate = self;
    wv.opaque = NO;
    wv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight |
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    wv.autoresizesSubviews = YES;
    
    if ([supportedFeatures containsObject:HZMRAIDSupportsInlineVideo]) {
        wv.allowsInlineMediaPlayback = YES;
        wv.mediaPlaybackRequiresUserAction = NO;
    } else {
        wv.allowsInlineMediaPlayback = NO;
        wv.mediaPlaybackRequiresUserAction = YES;
        [HZMRAIDLogger warning:@"MRAID - View" withMessage:[NSString stringWithFormat:@"No inline video support has been included, videos will play full screen without autoplay."]];
    }
    
    // disable scrolling
    UIScrollView *scrollView;
    if ([wv respondsToSelector:@selector(scrollView)]) {
        // UIWebView has a scrollView property in iOS 5+.
        scrollView = [wv scrollView];
    } else {
        // We have to look for the UIWebView's scrollView in iOS 4.
        for (id subview in [self subviews]) {
            if ([subview isKindOfClass:[UIScrollView class]]) {
                scrollView = subview;
                break;
            }
        }
    }
    scrollView.scrollEnabled = NO;
    
    // disable selection
    NSString *js = @"window.getSelection().removeAllRanges();";
    [wv stringByEvaluatingJavaScriptFromString:js];
    
    // Alert suppression
    if (SK_SUPPRESS_JS_ALERT)
        [wv stringByEvaluatingJavaScriptFromString:@"function alert(){}; function prompt(){}; function confirm(){}"];
}

#pragma mark - Gesture Methods

-(void)setUpTapGestureRecognizer
{
    if(!SK_SUPPRESS_BANNER_AUTO_REDIRECT){
        return;  // return without adding the GestureRecognizer if the feature is not enabled
    }
    // One finger, one tap
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerOneTap)];
    
    // Set up
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [tapGestureRecognizer setNumberOfTouchesRequired:1];
    [tapGestureRecognizer setDelegate:self];
    
    // Add the gesture to the view
    [self addGestureRecognizer:tapGestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;   // required to allow UIWebview to work correctly, see  http://stackoverflow.com/questions/2909807/does-uigesturerecognizer-work-on-a-uiwebview
}

-(void)oneFingerOneTap
{
    bonafideTapObserved=YES;
    tapGestureRecognizer.delegate=nil;
    tapGestureRecognizer=nil;
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:@"tapGesture oneFingerTap observed"];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view == resizeCloseRegion || touch.view == closeEventRegion){
        [HZMRAIDLogger debug:@"MRAID - View" withMessage:@"tapGesture 'shouldReceiveTouch'=NO"];
        return NO;
    }
    [HZMRAIDLogger debug:@"MRAID - View" withMessage:@"tapGesture 'shouldReceiveTouch'=YES"];
    return YES;
}

@end
