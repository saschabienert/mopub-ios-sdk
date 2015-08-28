//
//  HZFetchOptions_HeyzapMediationPrivate.h
//  Heyzap
//
//  Created by Monroe Ekilah on 8/27/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZFetchOptions.h"

/**
 *  HeyzapMediation uses the HZFetchOptions to track the fetch throughout it's lifecycle. These properties help it do so, but are not to be used/modified by classes calling `fetchWithOptions:` external to HeyzapMediation
 */
@interface HZFetchOptions()

@property (nonatomic, nonnull) NSSet * creativeTypesToFetch; // all creativeTypes to be fetched
@property (nonatomic, nonnull) NSSet *creativeTypesFetchesFinished; // creativeType fetches that have succeeded or failed
@property (nonatomic) BOOL alreadyNotifiedDelegateOfSuccess; // helps mediation only send one success callback

@end