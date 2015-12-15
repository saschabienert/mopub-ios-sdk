//
//  HZKIFTestCase.h
//  Heyzap
//
//  Created by Maximilian Tagher on 10/15/15.
//  Copyright © 2015 Heyzap. All rights reserved.
//

#import <KIF/KIF.h>
#import "OHHTTPStubs+Heyzap.h"
#import "HeyzapAds.h"
#import "HZUtils.h"
#import "TestJSON.h"

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@interface HZKIFTestCase : KIFTestCase

- (void)stubStartAndMediate;

#pragma mark - Searching the view (controller) hierarchy

/**
 *  Calls `findViewOfClass:inView:`, passing the keyWindow as the starting view.
 */
- (id)findViewOfClass:(Class)class;

/**
 *  Searches for a view of a given class in the view hierarchy.
 *
 *  @param class The kind of class the view must be.
 *  @param view  The view to start the search from.
 *
 *  @return A view, if it was found. The return type is `id` for the convenience of casting.
 */
- (id)findViewOfClass:(Class)class inView:(UIView *)view;

@end
