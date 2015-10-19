//
//  OHHTTPStubs+Heyzap.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "OHHTTPStubs+Heyzap.h"
#import "OHHTTPStubsResponse+JSON.h"
#import "NSString+Tests.h"

@implementation OHHTTPStubs (Heyzap)

+ (id<OHHTTPStubsDescriptor>)stubRequestContainingString:(NSString *)string withJSON:(id)JSON
{
    return [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString hzContainsString:string];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithJSONObject:JSON
                                                statusCode:200
                                                   headers:nil];
    }];
}

+ (id<OHHTTPStubsDescriptor>)stubRequestContainingString:(NSString *)string withVideoFile:(NSString *)videoFileName {
    NSParameterAssert(string);
    NSParameterAssert(videoFileName);
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:videoFileName withExtension:@"mp4"];
    NSParameterAssert(url);
    
    return [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString hzContainsString:string];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [[OHHTTPStubsResponse alloc] initWithFileURL:url statusCode:200 headers:@{@"content-type":@"video/mp4"}];
    }];
}

@end
