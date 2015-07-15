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

BOOL validateXMLDocSyntax(NSData *document);                         // check for valid XML syntax using xmlReadMemory
BOOL validateXMLDocAgainstSchema(NSData *document, NSData *schema);  // check for valid VAST 2.0 syntax using xmlSchemaValidateDoc & vast_2.0.1.xsd schema
NSArray *performXMLXPathQuery(NSData *document, NSString *query);    // parse the document for the xpath in 'query' using xmlXPathEvalExpression

void documentParserErrorCallback(void *ctx, const char *msg, ...);
void schemaParserErrorCallback(void *ctx, const char *msg, ...);
void schemaParserWarningCallback(void *ctx, const char *msg, ...);
void schemaValidationErrorCallback(void *ctx, const char *msg, ...);
void schemaValidationWarningCallback(void *ctx, const char *msg, ...);
NSDictionary *dictionaryForNode(xmlNodePtr currentNode, NSMutableDictionary *parentResult);
NSArray *performXPathQuery(xmlDocPtr doc, NSString *query);