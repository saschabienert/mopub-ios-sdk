//
//  HZSelectorReplacer.m
//  Heyzap
//
//  Created by Simon Maynard on 9/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HZSelectorReplacer.h"

@implementation HZSelectorReplacer

+(BOOL) replaceSelector: (SEL)originalSelector onClass: (Class)originalClass withSelector: (SEL)newSelector onClass: (Class)newClass {
    Method origMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method newMethod = class_getInstanceMethod(newClass, newSelector);    
    if(class_addMethod(originalClass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(originalClass, originalSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        return NO;
    } else {
        method_exchangeImplementations(origMethod, newMethod);
        return YES;
    }
}

@end
