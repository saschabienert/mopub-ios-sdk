//
//  HZWebViewPopup.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/5/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZWebView.h"
#import "HZUtils.h"

@interface HZWebView()
@property (nonatomic) UIInterfaceOrientation currOrientation;
@property (nonatomic) NSString *HTMLContent;
@property (nonatomic) UIWebView *webview;
@property (nonatomic) BOOL ready;
@property (nonatomic) BOOL isFullscreen;
@end

@implementation HZWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor: [UIColor clearColor]];
        _ready = NO;
        _webview = [[UIWebView alloc] initWithFrame: self.bounds];
        _webview.delegate = self;
        _webview.backgroundColor = [UIColor clearColor];
        _webview.allowsInlineMediaPlayback = YES;
        _webview.mediaPlaybackRequiresUserAction = NO;
        if ([_webview respondsToSelector: @selector(scrollView)]) {
            _webview.scrollView.scrollEnabled = NO;
        }
        [_webview setOpaque: NO];
        
        [self addSubview: _webview];
        
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

- (void) dealloc {
    
    // Supposedly gets rid of memory leak
    [self.webview loadHTMLString: @"" baseURL: nil];
    [self.webview stopLoading];
    self.webview.delegate = nil;
    [self.webview removeFromSuperview];
    
    self.webview = nil;
}

- (void) setHTML: (NSString *) html {
    self.HTMLContent = html;
    [self.webview loadHTMLString: self.HTMLContent baseURL: [NSURL URLWithString: [HZUtils cacheDirectoryPath]]];
}

#pragma mark - Views

- (void) layoutSubviews {
    [super layoutSubviews];
    self.webview.frame = self.bounds;
}

- (void) removeFromSuperview {
    [self.webview stringByEvaluatingJavaScriptFromString: @"adViewHidden();"];
    [super removeFromSuperview];
}

#pragma mark - Web View Delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.actionDelegate != nil) {
        [self.actionDelegate onActionError: self];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    NSURL *url = request.URL;
    
    if (navigationType == UIWebViewNavigationTypeReload) {
        // Reloading is convenient when using Safari Web Inspector http://stackoverflow.com/questions/20026846/how-can-i-see-the-size-in-bytes-of-a-resource-in-a-uiwebview-using-safari-7-we/20026957#20026957
        [webView loadHTMLString:self.HTMLContent baseURL:nil];
        return YES;
    }
    
    // resource specific =>  //close?undefined (what's up with the undefined thing? that's bad.)
    if ([url.absoluteString rangeOfString:@"Heyzap.close"].location != NSNotFound) {
        if (self.actionDelegate) {
            [self.actionDelegate onActionHide: self];
        }
        return NO;
    } else if ([url.absoluteString rangeOfString:@"Heyzap.installHeyzap"].location != NSNotFound) {
        if (self.actionDelegate) {
            [self.actionDelegate onActionInstallHeyzap: self];
        }
        
        return NO;
    } else if ([url.absoluteString rangeOfString:@"Heyzap.clickAd"].location != NSNotFound) {
        if (self.actionDelegate) {
            [self.actionDelegate onActionClick: self withURL: url];
        }
        return NO;
    } else if ([url.absoluteString rangeOfString:@"Heyzap.impressAd"].location != NSNotFound){
        return NO;
    } else if ([url.absoluteString rangeOfString:@"Heyzap.restart"].location != NSNotFound) {
        if (self.actionDelegate) {
            [self.actionDelegate performSelector: @selector(onActionRestart:) withObject: self];
        }
        return NO;
    } else if(url.host && [url.host rangeOfString:@"itunes.apple"].location != NSNotFound){
        //We've loaded a click URL in the webview, don't redirect to itunes since we are launching
        //the store kit product view
        return NO;
    } else {
        
    }
    
    return YES;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.ready = YES;
    [self.webview stringByEvaluatingJavaScriptFromString:@"adViewShown();"];
    if (self.actionDelegate != nil) {
        
        [self.actionDelegate onActionReady: self];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

@end
