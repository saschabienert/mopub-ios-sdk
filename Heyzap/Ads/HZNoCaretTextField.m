//
//  HZNoCaretTextField.m
//  Heyzap
//
//  Created by Maximilian Tagher on 3/26/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//

#import "HZNoCaretTextField.h"

@implementation HZNoCaretTextField

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

@end
