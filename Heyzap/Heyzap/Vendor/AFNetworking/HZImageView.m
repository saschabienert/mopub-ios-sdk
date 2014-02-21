//
//  HZImageView.m
//  Heyzap
//
//  Created by Daniel Rhodes on 2/13/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZImageView.h"
#import "HZAFNetworking.h"
#import <objc/runtime.h>

@interface HZAFImageCache : NSCache
- (UIImage *)cachedImageForRequest:(NSURLRequest *)request;
- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request;
@end

#pragma mark -

static char kHZAFImageRequestOperationObjectKey;

@interface UIImageView (_HZAFNetworking)
@property (readwrite, nonatomic, strong, setter = hz_af_setImageRequestOperation:) HZAFImageRequestOperation *hz_af_imageRequestOperation;
@end

@implementation UIImageView (_HZAFNetworking)
@dynamic hz_af_imageRequestOperation;
@end

#pragma mark -

@implementation HZImageView

- (HZAFHTTPRequestOperation *)hz_af_imageRequestOperation {
    return (HZAFHTTPRequestOperation *)objc_getAssociatedObject(self, &kHZAFImageRequestOperationObjectKey);
}

- (void)hz_af_setImageRequestOperation:(HZAFImageRequestOperation *)imageRequestOperation {
    objc_setAssociatedObject(self, &kHZAFImageRequestOperationObjectKey, imageRequestOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSOperationQueue *)hz_af_sharedImageRequestOperationQueue {
    static NSOperationQueue *_hz_af_imageRequestOperationQueue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _hz_af_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_hz_af_imageRequestOperationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    });
    
    return _hz_af_imageRequestOperationQueue;
}

+ (HZAFImageCache *)hz_af_sharedImageCache {
    static HZAFImageCache *_hz_af_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _hz_af_imageCache = [[HZAFImageCache alloc] init];
    });
    
    return _hz_af_imageCache;
}

#pragma mark -

- (void)HZsetImageWithURL:(NSURL *)url {
    [self HZsetImageWithURL:url placeholderImage:nil];
}

- (void)HZsetImageWithURL:(NSURL *)url
         placeholderImage:(UIImage *)placeholderImage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPShouldHandleCookies:NO];
    [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
    
    [self HZsetImageWithURLRequest:request placeholderImage:placeholderImage success:nil failure:nil];
}

- (void)HZsetImageWithURLRequest:(NSURLRequest *)urlRequest
                placeholderImage:(UIImage *)placeholderImage
                         success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                         failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    [self HZcancelImageRequestOperation];
    
    UIImage *cachedImage = [[[self class] hz_af_sharedImageCache] cachedImageForRequest:urlRequest];
    if (cachedImage) {
        self.image = cachedImage;
        self.hz_af_imageRequestOperation = nil;
        
        if (success) {
            success(nil, nil, cachedImage);
        }
    } else {
        self.image = placeholderImage;
        
        HZAFImageRequestOperation *requestOperation = [[HZAFImageRequestOperation alloc] initWithRequest:urlRequest];
        [requestOperation setCompletionBlockWithSuccess:^(HZAFHTTPRequestOperation *operation, id responseObject) {
            if ([[urlRequest URL] isEqual:[[self.hz_af_imageRequestOperation request] URL]]) {
                self.image = responseObject;
                self.hz_af_imageRequestOperation = nil;
            }
            
            if (success) {
                success(operation.request, operation.response, responseObject);
            }
            
            [[[self class] hz_af_sharedImageCache] cacheImage:responseObject forRequest:urlRequest];
            
            
        } failure:^(HZAFHTTPRequestOperation *operation, NSError *error) {
            if ([[urlRequest URL] isEqual:[[self.hz_af_imageRequestOperation request] URL]]) {
                self.hz_af_imageRequestOperation = nil;
            }
            
            if (failure) {
                failure(operation.request, operation.response, error);
            }
            
        }];
        
        self.hz_af_imageRequestOperation = requestOperation;
        
        [[[self class] hz_af_sharedImageRequestOperationQueue] addOperation:self.hz_af_imageRequestOperation];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)HZcancelImageRequestOperation {
    [self.hz_af_imageRequestOperation cancel];
    self.hz_af_imageRequestOperation = nil;
}

@end

#pragma mark -

static inline NSString * HZAFImageCacheKeyFromURLRequest(NSURLRequest *request) {
    return [[request URL] absoluteString];
}

@implementation HZAFImageCache

- (UIImage *)cachedImageForRequest:(NSURLRequest *)request {
    switch ([request cachePolicy]) {
        case NSURLRequestReloadIgnoringCacheData:
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            return nil;
        default:
            break;
    }
    
	return [self objectForKey:HZAFImageCacheKeyFromURLRequest(request)];
}

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request
{
    if (image && request) {
        [self setObject:image forKey:HZAFImageCacheKeyFromURLRequest(request)];
    }
}

@end