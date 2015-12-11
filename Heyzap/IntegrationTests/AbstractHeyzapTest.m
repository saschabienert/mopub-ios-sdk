//
//  AbstractHeyzapTest.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/10/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "AbstractHeyzapTest.h"

@implementation AbstractHeyzapTest

- (void)stubStartAndMediate {
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/start" withJSON:[TestJSON jsonForResource:@"start"]];
    [OHHTTPStubs stubRequestContainingString:@"med.heyzap.com/mediate" withJSON:[TestJSON jsonForResource:@"mediate"]];
}

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

@end
