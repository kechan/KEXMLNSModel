//
//  Book.h
//  LibXML2NSObject
//
//  Created by Kelvin Chan on 6/29/13.
//  Copyright (c) 2013 Kelvin Chan. All rights reserved.
//

#import "KEXMLNSModel.h"

@interface Book : KEXMLNSModel
@property (nonatomic, strong, readonly) NSString *category;
@property (nonatomic, strong, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSString *author;
@property (nonatomic, strong, readonly) NSString *year;
@property (nonatomic, strong, readonly) NSString *price;

// This is undefined in the XML, used in Unit Testing
@property (nonatomic, strong, readonly) NSString *bogus;
@end
