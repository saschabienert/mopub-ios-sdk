//
//  SKMRAIDParser.h
//  MRAID
//
//  Created by Jay Tucker on 9/13/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// A parser class which validates MRAID commands passed from the creative to the native methods.
// This takes a commandUrl of type "mraid://command?param1=val1&param2=val2&..." and return a
// dictionary of key/value pairs which include command name and all the parameters. It checks
// if the command itself is a valid MRAID command and also a simpler parameters validation.

typedef NS_ENUM(NSUInteger, HZMRAIDInternalCommand) {
    HZMRAIDInternalCommandUndefined,
    HZMRAIDInternalCommandCreateCalendarEvent,
    HZMRAIDInternalCommandClose,
    HZMRAIDInternalCommandExpand,
    HZMRAIDInternalCommandOpen,
    HZMRAIDInternalCommandPlayVideo,
    HZMRAIDInternalCommandResize,
    HZMRAIDInternalCommandSetOrientationProperties,
    HZMRAIDInternalCommandSetResizeProperties,
    HZMRAIDInternalCommandStorePicture,
    HZMRAIDInternalCommandUseCustomClose
};

@interface HZMRAIDCommand : NSObject

@property (nonatomic, strong, setter=setURL:) NSURL *url;
@property (nonatomic) HZMRAIDInternalCommand command;
@property (nonatomic, strong) NSDictionary *params;

- (id) initWithURL: (NSURL *) url;

@end
