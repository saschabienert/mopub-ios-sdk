//
//  KAProgressLabel.h
//  KAProgressLabel
//
//  Created by Alex on 09/06/13.
//  Copyright (c) 2013 Alexis Creuzot. All rights reserved.
//
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.
//
// Modified by Monroe Ekilah on 06/03/2015 for Heyzap

#import "HZTPPropertyAnimation.h"

@class HZKAProgressLabel;
typedef void(^labelValueChangedCompletion)(HZKAProgressLabel *label);


@interface HZKAProgressLabel : UILabel

@property (nonatomic, copy) labelValueChangedCompletion labelVCBlock;

// Style
@property (nonatomic) CGFloat trackWidth; 
@property (nonatomic) CGFloat progressWidth;
@property (nonatomic) CGFloat roundedCornersWidth;
@property (nonatomic, copy) UIColor * fillColor;
@property (nonatomic, copy) UIColor * trackColor;
@property (nonatomic, copy) UIColor * progressColor;

// Logic
@property (nonatomic) CGFloat startDegree;
@property (nonatomic) CGFloat endDegree;
@property (nonatomic) CGFloat progress;

// Getters
- (float)radius;

// Animations
- (void)setStartDegree:(CGFloat)startDegree
               timing:(HZTPPropertyAnimationTiming)timing
             duration:(CGFloat)duration
                delay:(CGFloat)delay;

- (void)setEndDegree:(CGFloat)endDegree
             timing:(HZTPPropertyAnimationTiming)timing
           duration:(CGFloat)duration
              delay:(CGFloat)delay;

- (void)setProgress:(CGFloat)progress
            timing:(HZTPPropertyAnimationTiming)timing
          duration:(CGFloat)duration
             delay:(CGFloat)delay;

- (void)stopAnimations;
@end
