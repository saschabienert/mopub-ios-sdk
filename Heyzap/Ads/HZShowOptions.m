/*
 * Copyright (c) 2015, Heyzap, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'Heyzap, Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "HZShowOptions_Private.h"
#import "HZAdModel.h"

@implementation HZShowOptions

- (HZShowOptions *)copyWithZone:(NSZone *)zone {
    HZShowOptions *options = [[[self class] allocWithZone:zone] init];
    [options setTag:[self tag]];
    [options setViewController:[self viewController]];
    options.completion = self.completion;
    options.requestingAdType = self.requestingAdType;
    options.placementIDOverride = self.placementIDOverride;
    options.creativeType = self.creativeType;
    return options;
}

@synthesize tag = _tag;

- (NSString *)tag {
    if (_tag == nil) {
        _tag = [HeyzapAds defaultTagName];
    }

    return _tag;
}

- (void) setTag:(NSString *)tag {
    _tag = [HZAdModel normalizeTag:tag];
}

- (UIViewController *)viewController {
    if (_viewController == nil) {
        _viewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    }

    return _viewController;
}

@end
