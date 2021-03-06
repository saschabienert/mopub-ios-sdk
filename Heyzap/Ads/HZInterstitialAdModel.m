//
//  HZInterstitialAdModel.m
//  Heyzap
//
//  Created by Daniel Rhodes on 12/4/13.
//  Copyright (c) 2013 Heyzap. All rights reserved.
//

#import "HZInterstitialAdModel.h"
#import "HZDictionaryUtils.h"
#import "HZUtils.h"
#import "HZWebViewPool.h"

@interface HZInterstitialAdModel()<UIWebViewDelegate>

@end

@implementation HZInterstitialAdModel

- (instancetype) initWithDictionary: (NSDictionary *) dict fetchableCreativeType:(HZFetchableCreativeType)fetchableCreativeType auctionType:(HZAuctionType)auctionType {
    self = [super initWithDictionary: dict fetchableCreativeType:fetchableCreativeType auctionType:auctionType];
    if (self) {
        _HTMLContent = [HZDictionaryUtils objectForKey: @"ad_html" ofClass: [NSString class] default: @"<html></html>" dict: dict];
        
        NSArray *dimensions = [HZDictionaryUtils objectForKey:@"ad_dimensions" ofClass:[NSArray class] dict: dict]; // Old model.
        id adHeight = [dict objectForKey:@"ad_height"];
        id adWidth = [dict objectForKey:@"ad_width"];
        
        if (adHeight && adWidth) {
            
            CGFloat height = 0;
            
            if (![adHeight isKindOfClass: [NSNull class]]) {
                if ([adHeight isKindOfClass:[NSString class]] && [adHeight isEqualToString:@"fill_parent"]) {
                    _fillParentHeight = YES;
                    _isFullScreen = YES;
                } else if ([adHeight respondsToSelector:@selector(floatValue)]) {
                    height = [adHeight floatValue];
                }
            }
            
            CGFloat width = 0;
            
            if (![adWidth isKindOfClass: [NSNull class]]) {
                if ([adWidth isKindOfClass:[NSString class]] && [adWidth isEqualToString:@"fill_parent"]) {
                    _fillParentWidth = YES;
                    _isFullScreen = YES;
                } else if ([adWidth respondsToSelector:@selector(floatValue)]) {
                    width = [adWidth floatValue];
                }
            }
            
            _dimensions = CGSizeMake(width, height);
        } else {
            if ([dimensions count] == 2) {
                _dimensions = CGSizeMake([[dimensions objectAtIndex:0] floatValue], [[dimensions objectAtIndex:1] floatValue]);
            } else {
                _dimensions = CGSizeMake(0, 0);
            }
        }
    }
    
    return self;
}

+ (BOOL) isValidForCreativeType: (NSString *) creativeType {
    return [creativeType isEqualToString: @"interstitial"];
}

- (void) doPostFetchActionsWithCompletion:(void (^)(BOOL))completion {
    
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    __block HZInterstitialAdModel *blockSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        blockSelf.preloadWebview = [[HZWebViewPool sharedPool] checkoutPool];
        blockSelf.preloadWebview.delegate = blockSelf;
        [blockSelf.preloadWebview loadHTMLString: self.HTMLContent baseURL: baseURL];
    });

    if (completion) {
        completion(YES);
        
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
}

- (void)dealloc {
    UIWebView *preload = self.preloadWebview;
    self.preloadWebview = nil;
    if (preload) {
        [[HZWebViewPool sharedPool] returnWebView:preload];
    }
}

@end
