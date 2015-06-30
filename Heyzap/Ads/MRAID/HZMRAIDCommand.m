//
//  SKMRAIDParser.m
//  MRAID
//
//  Created by Jay Tucker on 9/13/13.
//  Copyright (c) 2013 Nexage, Inc. All rights reserved.
//

#import "HZMRAIDCommand.h"
#import "HZSKLogger.h"
#import "HZUtils.h"

NSString * const HZMRAIDJSCommandCreateCalendarEvent = @"createCalendarEvent";
NSString * const HZMRAIDJSCommandClose = @"close";
NSString * const HZMRAIDJSCommandExpand = @"expand";
NSString * const HZMRAIDJSCommandOpen = @"open";
NSString * const HZMRAIDJSCommandPlayVideo = @"playVideo";
NSString * const HZMRAIDJSCommandResize = @"resize";
NSString * const HZMRAIDJSCommandSetOrientationProperties = @"setOrientationProperties";
NSString * const HZMRAIDJSCommandSetResizeProperties = @"setResizeProperties";
NSString * const HZMRAIDJSCommandStorePicture = @"storePicture";
NSString * const HZMRAIDJSCommandUseCustomClose = @"useCustomClose";

@interface HZMRAIDCommand ()

@property (nonatomic, strong) NSDictionary *commandsWithParams;
@property (nonatomic, strong) NSDictionary *commandMapping;

@end

@implementation HZMRAIDCommand

- (id) initWithURL: (NSURL *) url {
    if (self = [super init]) {
        // Mapping of JS command to enum representation and required params
        _commandMapping = @{
           HZMRAIDJSCommandCreateCalendarEvent:      @[@(HZMRAIDInternalCommandCreateCalendarEvent), @[@"eventJSON"]],
           HZMRAIDJSCommandClose:                    @[@(HZMRAIDInternalCommandClose), @[]],
           HZMRAIDJSCommandExpand:                   @[@(HZMRAIDInternalCommandExpand), @[]], //"url" is optional
           HZMRAIDJSCommandOpen:                     @[@(HZMRAIDInternalCommandOpen), @[@"url"]],
           HZMRAIDJSCommandPlayVideo:                @[@(HZMRAIDInternalCommandPlayVideo), @[@"url"]],
           HZMRAIDJSCommandResize:                   @[@(HZMRAIDInternalCommandResize), @[]],
           HZMRAIDJSCommandSetOrientationProperties: @[@(HZMRAIDInternalCommandSetOrientationProperties), @[@"allowOrientationChange",@"forceOrientation"]],
           HZMRAIDJSCommandSetResizeProperties:      @[@(HZMRAIDInternalCommandSetResizeProperties), @[@"width",@"height",@"offsetX",@"offsetY",@"customClosePosition",@"allowOffscreen"]],
           HZMRAIDJSCommandStorePicture:             @[@(HZMRAIDInternalCommandStorePicture),   @[@"url"]],
           HZMRAIDJSCommandUseCustomClose:           @[@(HZMRAIDInternalCommandUseCustomClose), @[@"useCustomClose"]],
        };
        
        _url = url;
        
        [self parseURL: url];
    }
    
    return self;
}

- (void) setURL:(NSURL *)url {
    _url = url;
    [self parseURL: _url];
}

- (void) parseURL: (NSURL *) url {
    /*
     The command is a URL string that looks like this:
     
     mraid://command?param1=val1&param2=val2&...
     
     We need to parse out the command, create a dictionary of the paramters and their associated values,
     and then send an appropriate message back to the MRAIDView to run the command.
     */
    
    [HZSKLogger debug:@"MRAID - Parser" withMessage:[NSString stringWithFormat:@"%@ %@", NSStringFromSelector(_cmd), url]];

    NSString *commandStr = [_url host];
    NSMutableDictionary *params = [HZUtils hzQueryDictionaryFromURL: url];
    
    // Check for valid command.
    if (![self isValidCommand:commandStr]) {
        [HZSKLogger warning:@"MRAID - Parser" withMessage:[NSString stringWithFormat:@"command '%@' is unknown", commandStr]];
        _command = HZMRAIDInternalCommandUndefined;
        _params = @{};
        return;
    }
    
    // Check for valid parameters for the given command.
    if (![self checkParamsForCommand:commandStr params:params]) {
        [HZSKLogger warning:@"MRAID - Parser" withMessage:[NSString stringWithFormat:@"command URL %@ is missing parameters", url]];
        _command = HZMRAIDInternalCommandUndefined;
        _params = @{};
        return;
    }
    
    self.command = [[[_commandMapping objectForKey: commandStr] objectAtIndex:0] intValue];
    self.params = params;
}

- (BOOL)isValidCommand:(NSString *)command {
    return [[_commandMapping allKeys] containsObject:command];
}

- (BOOL)checkParamsForCommand:(NSString *)command params:(NSDictionary *)presentParams {
    NSArray *presentParamKeys = [presentParams allKeys];
    NSArray *paramsForCommand = [[self.commandsWithParams objectForKey: command] objectAtIndex: 1];
    for (NSString *paramName in paramsForCommand) {
        if (![presentParamKeys containsObject: paramName]) return  NO;
    }
    
    return YES;
}

@end
