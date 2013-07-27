//
//  Bookstore.h
//  LibXML2NSObject
//
//  Created by Kelvin Chan on 6/29/13.
//  Copyright (c) 2013 Kelvin Chan. All rights reserved.
//

#import "KEXMLNSModel.h"

@interface Bookstore : KEXMLNSModel
@property (nonatomic, strong, readonly) NSMutableArray *bookArray;
@end
