//
//  OHHTTPStubs+Heyzap.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "OHHTTPStubs+Heyzap.h"
#import "OHHTTPStubsResponse+JSON.h"

@implementation OHHTTPStubs (Heyzap)

+ (id<OHHTTPStubsDescriptor>)stubRequestContainingString:(NSString *)string withJSON:(id)JSON
{
    return [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString containsString:@"fetch_ad"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithJSONObject:JSON
                                                statusCode:200
                                                   headers:nil];
    }];
}

@end
