//
//  KEXMLNSModel.h
//  KEXMLNSModel
//
//  Created by Kelvin Chan on 7/27/13.
//  Copyright (c) 2013 Kelvin Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import "NSString+Cleanse.h"
#import "GDataXMLNode.h"

@interface KEXMLNSModel : NSObject

@property (nonatomic, strong) GDataXMLDocument *xmlDoc;   // copy and made local
@property (nonatomic, strong) GDataXMLElement *rootXMLElement;   // reference to part of global copy

// This is used to stored dynamics properties that have NSString as their values
@property (nonatomic, strong) NSMutableDictionary *propertiesDictionary;

+(id) loadContentsFromXMLFile:(NSString *)filename;       // from file
+(id) loadContentsFromXMLData:(NSData *)xmlData;   // from NSdata thats XML
+(id) loadContentsFromXMLString:(NSString *)xmlString;    // from NSString thats XML

// The following will establish a shared copy among the entire hierarchy of XML objects
+(id) loadContentsFromGDataXMLElement:(GDataXMLElement *) gDataXMLElement;

// Init
-(id) initWithData:(NSData*)data;
-(id) initWithGDataXMLElement:(GDataXMLElement *)gDataXMLElement;


// Helpers
+(NSMutableData *) getXMLDataFromXMLFile:(NSString *)filename;

// subclass needs to override this
-(void) parseAndBuildObject:(GDataXMLElement *)root;

@end
