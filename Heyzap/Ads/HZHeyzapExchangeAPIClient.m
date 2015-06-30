//
//  HZHeyzapExchangeAPIClient.m
//  Heyzap
//
//  Created by Monroe Ekilah on 6/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZHeyzapExchangeAPIClient.h"
#import "HZMediationRequestSerializer.h"
#import "HZAFURLResponseSerialization.h"

NSString * const kHZHeyzapExchangeAPIBaseURLString = @"https://x.heyzap.com/";

@implementation HZHeyzapExchangeAPIClient

+ (HZHeyzapExchangeAPIClient *)sharedClient {
    static HZHeyzapExchangeAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[HZHeyzapExchangeAPIClient alloc] initWithBaseURL:[NSURL URLWithString: kHZHeyzapExchangeAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [HZMediationRequestSerializer serializer]; //monroe: this is where custom server params should probably go later
        self.responseSerializer = [[HZAFHTTPResponseSerializer alloc] init];
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/xml", @"text/html", nil];
    }
    return self;
}

- (HZAFHTTPRequestOperation *)GET:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(HZAFHTTPRequestOperation *operation, id responseObject))success
                          failure:(void (^)(HZAFHTTPRequestOperation *operation, NSError *error))failure
                    redirectBlock: (NSURLRequest * (^)(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse))block {
    NSString *finalurl =[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString];
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:@"GET" URLString:finalurl parameters:parameters error:nil];
    
    HZAFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
    [operation setRedirectResponseBlock:block];
    
    [self.operationQueue addOperation:operation];
    return operation;
}

@end
