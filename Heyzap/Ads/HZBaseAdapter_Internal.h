//
//  HZBaseAdapter_Internal.h
//  Heyzap
//
//  Created by Monroe Ekilah on 9/11/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZBaseAdapter.h"

/**
 *  Methods that should only be used internally by HZBaseAdapter and it's subclasses are declared here.
 */
@interface HZBaseAdapter()


/**
 *  These properties exist for subclasses to use. Other callers must use `lastErrorForCreativeType:` and `clearErrorForCreativeType:`.
 */
@property (nonatomic, strong) NSError *lastStaticError;
@property (nonatomic, strong) NSError *lastIncentivizedError;
@property (nonatomic, strong) NSError *lastVideoError;

/**
 *  Subclasses should implement this method to read their credentials dictionary (`self.credentials`) into properties. The default implementation of this method does nothing, so can be left unimplemented for networks like iAds that don't have credentials.
 */
- (void)loadCredentials;


/**
 *  Show an ad. This is called by the base adapter implementation after it verifies that the requested creativeType is supported by the subclass.
 */
- (void)internalShowAdForCreativeType:(HZCreativeType)creativeType options:(HZShowOptions *)options;
@end