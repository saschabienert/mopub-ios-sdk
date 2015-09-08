//
//  VASTXMLUtil.h
//  VAST
//
//  Created by Jay Tucker on 10/15/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VASTXMLUtil validates a VAST document for correct XML syntax and conformance to the VAST 2.0.1.xsd schema.

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

BOOL hzValidateXMLDocSyntax(NSData *document);                         // check for valid XML syntax using xmlReadMemory
BOOL hzValidateXMLDocAgainstSchema(NSData *document, NSData *schema);  // check for valid VAST 2.0 syntax using xmlSchemaValidateDoc & vast_2.0.1.xsd schema
NSArray *hzPerformXMLXPathQuery(NSData *document, NSString *query);    // parse the document for the xpath in 'query' using xmlXPathEvalExpression

void hzDocumentParserErrorCallback(void *ctx, const char *msg, ...);
void hzSchemaParserErrorCallback(void *ctx, const char *msg, ...);
void hzSchemaParserWarningCallback(void *ctx, const char *msg, ...);
void hzSchemaValidationErrorCallback(void *ctx, const char *msg, ...);
void hzSchemaValidationWarningCallback(void *ctx, const char *msg, ...);
NSDictionary *hzDictionaryForNode(xmlNodePtr currentNode, NSMutableDictionary *parentResult);
NSArray *hzPerformXPathQuery(xmlDocPtr doc, NSString *query);
