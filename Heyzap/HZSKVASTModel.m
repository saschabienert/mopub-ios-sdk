//
//  SKVASTModel.m
//  VAST
//
//  Created by Jay Tucker on 10/4/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//

#import "HZSKVASTModel.h"
#import "HZSKVASTUrlWithId.h"
#import "HZSKVASTMediaFile.h"
#import "HZVASTXMLUtil.h"
#import "HZSKLogger.h"

@interface HZSKVASTModel ()
{
    NSMutableArray *vastDocumentArray;
}

// returns an array of VASTUrlWithId objects
- (NSArray *)resultsForQuery:(NSString *)query;

// returns the text content of both simple text and CDATA sections
- (NSString *)content:(NSDictionary *)node;

@end

@implementation HZSKVASTModel

#pragma mark - "private" method

// We deliberately do not declare this method in the header file in order to hide it.
// It should be used only be the VAST2Parser to build the model.
// It should not be used by anybody else receiving the model object.
- (void)addVASTDocument:(NSData *)vastDocument
{
    if (!vastDocumentArray) {
        vastDocumentArray = [NSMutableArray array];
    }
    [vastDocumentArray addObject:vastDocument];
}

#pragma mark - public methods

- (NSString *)vastVersion
{
    // sanity check
    if ([vastDocumentArray count] == 0) {
        return nil;
    }
    
    NSString *version;
    NSString *query = @"/VAST/@version";
    NSArray *results = performXMLXPathQuery(vastDocumentArray[0], query);
    // there should be only a single result
    if ([results count] > 0) {
        NSDictionary *attribute = results[0];
        version = attribute[@"nodeContent"];
    }
    return version;
}

- (NSArray *)errors
{
    NSString *query = @"//Error";
    return [self resultsForQuery:query];
}

- (NSArray *)impressions
{
    NSString *query = @"//Impression";
    return [self resultsForQuery:query];
}

- (NSDictionary *)trackingEvents
{
    NSMutableDictionary *eventDict;
    NSString *query = @"//Linear//Tracking";

    for (NSData *document in vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
            // use lazy initialization
            if (!eventDict) {
                eventDict = [NSMutableDictionary dictionary];
            }
            NSString *urlString = [self content:result];
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                if ([name isEqualToString:@"event"]) {
                    NSString *event = attribute[@"nodeContent"];
                    NSMutableArray *newEventArray = [NSMutableArray array];
                    NSArray *oldEventArray = [eventDict valueForKey:event];
                    if (oldEventArray) {
                        [newEventArray addObjectsFromArray:oldEventArray];
                    }
                    NSURL *eventURL = [self urlWithCleanString:urlString];
                    if (eventURL) {
                        [newEventArray addObject:[self urlWithCleanString:urlString]];
                        [eventDict setValue:newEventArray forKey:event];
                    }
                }
            }
        }
    }
    
    [HZSKLogger debug:@"VAST - Model" withMessage:[NSString stringWithFormat:@"returning event dictionary with %lu event(s)", (unsigned long)[eventDict count]]];
    for (NSString *event in [eventDict allKeys]) {
        NSArray *array = (NSArray *)[eventDict valueForKey:event];
        [HZSKLogger debug:@"VAST - Model" withMessage:[NSString stringWithFormat:@"%@ has %lu URL(s)", event, (unsigned long)[array count]]];
    }
    
    return eventDict;
}

- (HZSKVASTUrlWithId *)clickThrough
{
    NSString *query = @"//ClickThrough";
    NSArray *array = [self resultsForQuery:query];
    // There should be at most only one array element.
    return ([array count] > 0) ? array[0] : nil;
}

- (NSArray *)clickTracking
{
    NSString *query = @"//ClickTracking";
    return [self resultsForQuery:query];
}

- (NSArray *)mediaFiles
{
    NSMutableArray *mediaFileArray;
    NSString *query = @"//MediaFile";
    
    for (NSData *document in vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
 
            // use lazy initialization
            if (!mediaFileArray) {
                mediaFileArray = [NSMutableArray array];
            }
            
            NSString *id_;
            NSString *delivery;
            NSString *type;
            NSString *bitrate;
            NSString *width;
            NSString *height;
            NSString *scalable;
            NSString *maintainAspectRatio;
            NSString *apiFramework;
            
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                NSString *content = attribute[@"nodeContent"];
                if ([name isEqualToString:@"id"]) {
                    id_ = content;
                } else  if ([name isEqualToString:@"delivery"]) {
                    delivery = content;
                } else  if ([name isEqualToString:@"type"]) {
                    type = content;
                } else  if ([name isEqualToString:@"bitrate"]) {
                    bitrate = content;
                } else  if ([name isEqualToString:@"width"]) {
                    width = content;
                } else  if ([name isEqualToString:@"height"]) {
                    height = content;
                } else  if ([name isEqualToString:@"scalable"]) {
                    scalable = content;
                } else  if ([name isEqualToString:@"maintainAspectRatio"]) {
                    maintainAspectRatio = content;
                } else  if ([name isEqualToString:@"apiFramework"]) {
                    apiFramework = content;
                }
            }
            NSString *urlString = [self content:result];
            if (urlString != nil) {
                urlString = [[self urlWithCleanString:urlString] absoluteString];
            }
            
            HZSKVASTMediaFile *mediaFile = [[HZSKVASTMediaFile alloc]
                                        initWithId:id_
                                        delivery:delivery
                                        type:type
                                        bitrate:bitrate
                                        width:width
                                        height:height
                                        scalable:scalable
                                        maintainAspectRatio:maintainAspectRatio
                                        apiFramework:apiFramework
                                        url:urlString];
            
            [mediaFileArray addObject:mediaFile];
        }
    }
    
    return mediaFileArray;
}

// returns nil if unsuccessful, otherwise a NSNumber (double) value for how long before a skip button should be presented
- (NSNumber *) skipOffsetSeconds {
    // sanity check
    if ([vastDocumentArray count] == 0) {
        return nil;
    }
    
    NSString *skipOffsetRaw = nil;
    NSString *query = @"//Linear/@skipoffset";
    NSArray *results = performXMLXPathQuery(vastDocumentArray[0], query);
    if ([results count] > 0) {
        NSDictionary *attribute = results[0];
        skipOffsetRaw = attribute[@"nodeContent"];
    }else{
        return nil;
    }
    
    // use duration to calculate seconds
    NSNumber *duration = [self durationInSeconds];
    if(!duration) {
        return nil;
    }
    long durationLong = [duration longValue];
    
    // XML validation guarantees one of:
    // - a 1-3 digit number as a %
    // - HH:MM:SS
    // - HH:MM:SS.mmm
    // for this field, or an empty string
    if([skipOffsetRaw containsString:@"%"]) {
        //process \d{1,3}%
        int percentageInt = [[skipOffsetRaw stringByReplacingOccurrencesOfString:@"%" withString:@""] intValue];

        //ensure that duration >= skipOffset
        return [NSNumber numberWithDouble:MIN((durationLong * percentageInt / 100.0), durationLong)];
    } else {
        long skipTime = [[self secondsFromHHMMSS:skipOffsetRaw] longValue];
        //ensure that duration >= skipOffset
        return [NSNumber numberWithLong:MIN(skipTime, durationLong)];
    }
}

- (NSNumber *) durationInSeconds{
    NSString *duration = nil;
    NSString *query = @"//Creative//Duration";
    NSArray *results = performXMLXPathQuery(vastDocumentArray[0], query);
    
    if ([results count] > 0) {
        NSDictionary *attribute = results[0];
        duration = attribute[@"nodeContent"];
    } else {
        return nil;
    }
    
    if(!duration) {
        return nil;
    }
    
    return [self secondsFromHHMMSS:duration];
}

#pragma mark - helper methods

- (NSNumber *) secondsFromHHMMSS:(NSString *) str {
    if([str length] == 0){
        // nil or empty
        return @(0);
    }
    
    //process HH:MM:SS or HH:MM:SS.mmm
    NSArray *components = [str componentsSeparatedByString:@":"];
    
    if([components count] != 3){
        // invalid format
        return @(0);
    }
    
    NSArray *secondsComponents = [[components objectAtIndex:2] componentsSeparatedByString:@"."];
    if([secondsComponents count] != 1 && [secondsComponents count] != 2){
        // invalid format
        return @(0);
    }
    
    NSInteger hours         = [[components objectAtIndex:0] integerValue];
    NSInteger minutes       = [[components objectAtIndex:1] integerValue];
    NSInteger seconds       = [[secondsComponents objectAtIndex:0] integerValue];
    NSInteger milliseconds  = 0;
    if([secondsComponents count] == 2) {
        milliseconds = [[secondsComponents objectAtIndex:1] integerValue];
    }
    
    return [NSNumber numberWithDouble:((hours * 60 * 60) + (minutes * 60) + seconds + (milliseconds / 1000.0))];
}

- (NSArray *)resultsForQuery:(NSString *)query
{
    NSMutableArray *array;
    NSString *elementName = [query stringByReplacingOccurrencesOfString:@"/" withString:@""];
    
    for (NSData *document in vastDocumentArray) {
        NSArray *results = performXMLXPathQuery(document, query);
        for (NSDictionary *result in results) {
            // use lazy initialization
            if (!array) {
                array = [NSMutableArray array];
            }
            NSString *urlString = [self content:result];
            
            NSString *id_; // add underscore to avoid confusion with kewyord id
            NSArray *attributes = result[@"nodeAttributeArray"];
            for (NSDictionary *attribute in attributes) {
                NSString *name = attribute[@"attributeName"];
                if ([name isEqualToString:@"id"]) {
                    id_ = attribute[@"nodeContent"];
                    break;
                }
            }
            HZSKVASTUrlWithId *impression = [[HZSKVASTUrlWithId alloc] initWithID:id_ url:[self urlWithCleanString:urlString]];
            [array addObject:impression];
        }
    }
    
    [HZSKLogger debug:@"VAST - Model" withMessage:[NSString stringWithFormat:@"returning %@ array with %lu element(s)", elementName, (unsigned long)[array count]]];
    return array;
}

- (NSString *)content:(NSDictionary *)node
{
    // this is for string data
    if ([node[@"nodeContent"] length] > 0) {
        return node[@"nodeContent"];
    }
    
    // this is for CDATA
    NSArray *childArray = node[@"nodeChildArray"];
    if ([childArray count] > 0) {
        // return the first array element that is not a comment
        for (NSDictionary *childNode in childArray) {
            if ([childNode[@"nodeName"] isEqualToString:@"comment"]) {
                continue;
            }
            return childNode[@"nodeContent"];
        }
    }
    
    return nil;
}

- (NSURL*)urlWithCleanString:(NSString *)string
{
    NSString *cleanUrlString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  // remove leading, trailing \n or space
    cleanUrlString = [cleanUrlString stringByReplacingOccurrencesOfString:@"|" withString:@"%7c"];
    return [NSURL URLWithString:cleanUrlString];                                                                            // return the resulting URL
}

@end
