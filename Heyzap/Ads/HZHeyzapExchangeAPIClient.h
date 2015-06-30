//
//  HZHeyzapExchangeAPIClient.h
//  Heyzap
//
//  Created by Monroe Ekilah on 6/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HZAPIClient.h"

@interface HZHeyzapExchangeAPIClient : HZAPIClient

+ (HZHeyzapExchangeAPIClient *)sharedClient;
- (HZAFHTTPRequestOperation *)GET:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(HZAFHTTPRequestOperation *operation, id responseObject))success
                          failure:(void (^)(HZAFHTTPRequestOperation *operation, NSError *error))failure
                    redirectBlock: (NSURLRequest * (^)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse))block;
@end
