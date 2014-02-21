//
//  HZSelectorReplacer.h
//  Heyzap
//
//  Created by Simon Maynard on 9/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "objc/runtime.h"

@interface HZSelectorReplacer : NSObject

+(BOOL) replaceSelector: (SEL)originalSelector onClass: (Class)originalClass withSelector: (SEL)newSelector onClass: (Class)newClass;

@end
