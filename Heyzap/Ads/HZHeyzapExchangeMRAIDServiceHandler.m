//
//  HZHeyzapExchangeMRAIDServiceHandler.m
//  Heyzap
//
//  Created by Monroe Ekilah on 7/1/15.
//  Copyright (c) 2015 Heyzap. All rights reserved.
//
#import <EventKit/EventKit.h>
#import "HZHeyzapExchangeAdapter.h"
#import "HZHeyzapExchangeMRAIDServiceHandler.h"
#import "HZLog.h"
#import "HZDictionaryUtils.h"

@interface HZHeyzapExchangeMRAIDServiceHandler()
@property (nonatomic, weak) id<HZHeyzapExchangeMRAIDServiceHandlerDelegate> delegate;
@end

@implementation HZHeyzapExchangeMRAIDServiceHandler

- (instancetype) initWithDelegate:(id<HZHeyzapExchangeMRAIDServiceHandlerDelegate>)delegate{
    self = [super init];
    if(self){
        _delegate = delegate;
    }
    
    return self;
}

/**
 Only make one of these because the EKEventStore is a heavy object according to the docs: https://developer.apple.com/library/ios/documentation/DataManagement/Conceptual/EventKitProgGuide/ReadingAndWritingEvents.html
 */
+(EKEventStore *)sharedEventStore {
    static EKEventStore *sharedStore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStore = [[EKEventStore alloc]init];
    });
    
    return sharedStore;
}

- (NSArray *) supportedFeatures {
    // test if calls can be made from this device. this does not test for a SIM card or reception,
    // only if there is an app that can handle this url. Note: iOS 8 returns YES even for iPads because of new features.
    BOOL canCall = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:111111"]];
    
    if(canCall){
        return @[
                 HZMRAIDSupportsSMS,
                 HZMRAIDSupportsTel,
                 HZMRAIDSupportsCalendar,
                 HZMRAIDSupportsStorePicture,
                 //HZMRAIDSupportsInlineVideo,//not yet implemented
                 ];
    }else{
        return @[
                 HZMRAIDSupportsSMS,
                 HZMRAIDSupportsCalendar,
                 HZMRAIDSupportsStorePicture,
                 //HZMRAIDSupportsInlineVideo,//not yet implemented
                 ];
    }
}


#pragma mark - HZMRAIDServiceDelegate
- (void)mraidServiceCreateCalendarEventWithEventJSON:(NSString *)eventJSONString {
    HZDLog(@"MRAID - calendar event json: %@", eventJSONString);
    [self.delegate serviceEventProcessed:@"calendar" willLeaveApplication:NO];
    
    /*
     expected format:
     
     {
     "description":"...",
     "location":"...",
     "start":"2013-12-21T00:00-05:00",
     "end":"2013-12-22T00:00-05:00"
     }
     */
    NSError *jsonError;
    NSData *objectData = [eventJSONString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *eventJSON = [NSJSONSerialization JSONObjectWithData:objectData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&jsonError];
    if(jsonError){
        HZELog(@"Calendar event could not be parsed into JSON. Error: %@ Event: %@", jsonError, eventJSONString);
        return;
    }
    
    EKEventStore *store = [HZHeyzapExchangeMRAIDServiceHandler sharedEventStore];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) { return; }
        EKEvent *event = [EKEvent eventWithEventStore:store];
        event.title = [HZDictionaryUtils hzObjectForKey:@"description" ofClass:[NSString class] default:@"New event" withDict:eventJSON];
        event.location =[HZDictionaryUtils hzObjectForKey:@"location" ofClass:[NSString class] withDict:eventJSON];
        event.startDate = [self dateWithString:[HZDictionaryUtils hzObjectForKey:@"start" ofClass:[NSString class] withDict:eventJSON]];
        event.endDate = [self dateWithString:[HZDictionaryUtils hzObjectForKey:@"end" ofClass:[NSString class] withDict:eventJSON]];
        event.calendar = [store defaultCalendarForNewEvents];
        NSError *err = nil;
        [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
        if(err){
            HZELog(@"Calendar event could not be saved. Error: %@ Event: %@", err, eventJSONString);
        }
    }];
}

- (void)mraidServicePlayVideoWithURL:(NSURL *)url {
    HZELog(@"MRAID UNIMPLEMENTED - play video at url: %@",url);
    [self.delegate serviceEventProcessed:@"video" willLeaveApplication:NO];//would be YES if implemented
}

- (void)mraidServiceOpenBrowserWithURL:(NSURL *)url {
    HZDLog(@"MRAID - open url: %@",url);
    [self.delegate serviceEventProcessed:@"url" willLeaveApplication:YES];
    
    [[UIApplication sharedApplication] openURL:url];
}

- (void)mraidServiceStorePictureWithURL:(NSURL *)url {
    HZDLog(@"MRAID - store pic at url: %@",url);
    [self.delegate serviceEventProcessed:@"picture" willLeaveApplication:NO];
    
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:imageData];
    if(image){
        // don't care if it fails right now
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil);
    }else{
        HZELog(@"MRAID - Image could not be saved.");
    }
}


#pragma mark - Utilities

/* Converts date of format `2008-12-29T00:27:42GMT-08:00` and defaults to "now" if it fails or if `nil` is passed*/
-(NSDate *) dateWithString:(NSString *)dateString {
    if(!dateString){
        return [NSDate date];
    }
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mmZZZZ"];
    NSDate *date = [dateFormatter dateFromString:dateString];
    if(!date) {
        return [NSDate date];
    }
    return date;
}
@end