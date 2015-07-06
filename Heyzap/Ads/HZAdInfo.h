//
//  HZAdLibraryKey.h
//  Heyzap
//
//  Created by Maximilian Tagher on 9/3/14.
//  Copyright (c) 2014 Heyzap. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HZAdInfoProvider <NSObject>

- (NSString *)adUnit;
- (HZAuctionType)auctionType;

@end

/**
 *  This class is used by HZAdLibrary as an immutable dictionary key
 */
@interface HZAdInfo : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *adUnit;
@property (nonatomic, readonly) HZAuctionType auctionType;

/**
 *  Initializer
 *
 *  @param adUnit      adUnit, e.g. "interstitial" or "video"; required property.
 *  @param auctionType auctionType
 *
 *  @return The key.
 */
- (instancetype)initWithAdUnit:(NSString *)adUnit auctionType:(HZAuctionType)auctionType;

- (instancetype)initWithProvider:(id<HZAdInfoProvider>)provider;

@end
