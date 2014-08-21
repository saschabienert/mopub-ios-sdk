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

@interface HZInterstitialAdModel()<UIWebViewDelegate>

@end

@implementation HZInterstitialAdModel

- (id) initWithDictionary: (NSDictionary *) dict adUnit:(NSString *)adUnit {
    self = [super initWithDictionary: dict adUnit:adUnit];
    if (self) {
        _HTMLContent = [HZDictionaryUtils hzObjectForKey: @"ad_html" ofClass: [NSString class] default: @"<html></html>" withDict: dict];
        
        NSArray *dimensions = [HZDictionaryUtils hzObjectForKey:@"ad_dimensions" ofClass:[NSArray class] withDict: dict]; // Old model.
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
    
    [self sendInitializationMetrics];
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
        blockSelf.preloadWebview = [[UIWebView alloc] initWithFrame: CGRectMake(0.0, 0.0, 500.0, 500.0)];
        blockSelf.preloadWebview.delegate = blockSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                                 (unsigned long)NULL), ^(void) {
            [blockSelf.preloadWebview loadHTMLString: self.HTMLContent baseURL: baseURL];
        });
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

@end
