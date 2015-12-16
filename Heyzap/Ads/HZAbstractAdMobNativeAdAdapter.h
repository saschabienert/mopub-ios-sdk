//
//  HZAbstractAdMobNativeAdAdapter.h
//  Heyzap
//
//  Created by Maximilian Tagher on 11/17/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import "HZNativeAdAdapter.h"

@interface HZAbstractAdMobNativeAdAdapter : HZNativeAdAdapter

+ (Class)wrapperViewSubclass:(NSString *)subclassName forSuperclass:(NSString *)superclassName;
- (void)admobWrapperMovedToWindow;

@end
