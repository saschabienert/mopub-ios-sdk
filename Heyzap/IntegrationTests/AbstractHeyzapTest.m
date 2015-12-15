//
//  AbstractHeyzapTest.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/10/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "AbstractHeyzapTest.h"

NSString * const kCloseButtonAccessibilityLabel = @"X";

@implementation AbstractHeyzapTest

- (void)stubWebViewContent {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path isEqualToString:@"/assets/ads/fastclick-62c1d38f8e964c75f8de61457fd6dd2d.js"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"fastclick" withExtension:@"js"];
        return [[OHHTTPStubsResponse alloc] initWithFileURL:url statusCode:200 headers:@{@"content-type":@"application/javascript"}];
    }];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest * _Nonnull request) {
        return [request.URL.path containsString:@"/assets/ads/flat_ios-e54b2fe012a7581343586c20d28138b9.css"];
    } withStubResponse:^OHHTTPStubsResponse * _Nonnull(NSURLRequest * _Nonnull request) {
        NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"flat_ios" withExtension:@"css"];
        return [[OHHTTPStubsResponse alloc] initWithFileURL:url statusCode:200 headers:@{@"content-type":@"text/css"}];
    }];
}

- (void)stubHeyzapEventEndpoints {
    NSArray *const endpoints = @[
      @"/in_game_api/ads/register_impression",
      @"/in_game_api/ads/register_click",
      @"/in_game_api/ads/event/video_impression_complete",
      ];
    for (NSString *endpoint in endpoints) {
        [OHHTTPStubs stubRequestContainingString:endpoint
                                        withJSON:@{@"status":@200}];
    }
}

- (void)closeHeyzapWebView {
    [system runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        NSParameterAssert(error);
        UIWebView *webview = [self findWebview];
        if (webview) {
            [webview stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"close-button\").click()"];
            return KIFTestStepResultSuccess;
        } else {
            *error = [NSError errorWithDomain:@"Couldn't find webview" code:1 userInfo:nil];
            return KIFTestStepResultFailure;
        }
    }];
}

- (UIWebView *)findWebview {
    return [self findWebviewInView:[UIApplication sharedApplication].keyWindow];
}

- (UIWebView *)findWebviewInView:(UIView *)view {
    if ([view isKindOfClass:[UIWebView class]] || [view isKindOfClass:[UIWebView class]]) {
        return (UIWebView *)view;
    } else {
        for (UIView *subview in view.subviews) {
            id maybeWebView = [self findWebviewInView:subview];
            if (maybeWebView) {
                return maybeWebView;
            }
        }
        return nil;
    }
}

@end
