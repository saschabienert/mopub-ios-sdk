//
//  HZNativeAdImage.m
//  Heyzap
//
//  Created by Maximilian Tagher on 12/19/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import "HZNativeAdImage.h"
#import "HZDictionaryUtils.h"
#import "HZInitMacros.h"
#import <UIKit/UIKit.h>

NSString * const kHZImageURLKey = @"uri";
NSString * const kHZImageWidthKey = @"width";
NSString * const kHZImageHeightKey = @"height";

@implementation HZNativeAdImage

- (instancetype)initWithDictionary:(NSDictionary *)dictionary error:(NSError **)error {
    HZParameterAssert(error != NULL);
    
    NSURL *url = [NSURL URLWithString:[HZDictionaryUtils objectForKey:kHZImageURLKey ofClass:[NSString class] dict:dictionary]];
    CHECK_NOT_NIL(url,@"URL");
    
    NSNumber *width = [HZDictionaryUtils objectForKey:kHZImageWidthKey ofClass:[NSNumber class] dict:dictionary];
    CHECK_NOT_NIL(width,@"Width");
    
    NSNumber *height = [HZDictionaryUtils objectForKey:kHZImageHeightKey ofClass:[NSNumber class] dict:dictionary];
    CHECK_NOT_NIL(height,@"Height");
    
    return [self initWithURL:url width:[width integerValue] height:[height integerValue]];
}

- (instancetype)initWithURL:(NSURL *)url width:(CGFloat)width height:(CGFloat)height {
    self = [super init];
    if (self) {
        _url = url;
        _width = width;
        _height = height;
    }
    return self;
}

- (CGSize)size {
    return CGSizeMake(self.width, self.height);
}

#pragma mark - Util

- (NSString *)description {
    
    NSMutableString *const desc = [[NSMutableString alloc] initWithString:[super description]];
    [desc appendFormat:@" `url` = %@",self.url];
    [desc appendFormat:@" `size` = %@",NSStringFromCGSize(self.size)];
    return desc;
}

@end
