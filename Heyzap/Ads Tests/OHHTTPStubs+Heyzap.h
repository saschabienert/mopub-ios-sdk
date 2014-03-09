//
//  OHHTTPStubs+Heyzap.h
//  Heyzap
//
//  Created by Maximilian Tagher on 3/8/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "OHHTTPStubs.h"

@interface OHHTTPStubs (Heyzap)

/**
 *  Stubs an HTTP request to return the JSON object with a 200 status code.
 *
 *  @param string A substring of the NSURL for the request to match against, e.g. "fetch_ad"
 *  @param JSON   A JSON object, i.e. an array or dictionary
 *
 *  @return The descriptor for the stub.
 */
+ (id<OHHTTPStubsDescriptor>)stubRequestContainingString:(NSString *)string withJSON:(id)JSON;

@end
