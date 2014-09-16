//
//  HZAdLibraryKey.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZAdInfoProvider <NSObject>

- (NSString *)tag;
- (NSString *)adUnit;
- (HZAuctionType)auctionType;

@end

/**
 *  This class is used by HZAdLibrary as an immutable dictionary key
 */
@interface HZAdInfo : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, readonly) HZAuctionType auctionType;

/**
 *  Initializer
 *
 *  @param tag         Tag of the ad; required property.
 *  @param adUnit      adUnit, e.g. "interstitial" or "video"; required property.
 *  @param auctionType auctionType
 *
 *  @return The key.
 */
- (instancetype)initWithTag:(NSString *)tag adUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType;

- (instancetype)initWithProvider:(id<HZAdInfoProvider>)provider;

@end
