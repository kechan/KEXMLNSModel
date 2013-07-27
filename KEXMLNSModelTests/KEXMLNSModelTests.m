//
//  KEXMLNSModelTests.m
//  KEXMLNSModelTests
//
//  Created by Kelvin Chan on 7/27/13.
//  Copyright (c) 2013 Kelvin Chan. All rights reserved.
//

#import "KEXMLNSModelTests.h"
#import "Bookstore.h"
#import "Book.h"

@interface KEXMLNSModelTests ()
@property (nonatomic, strong) Bookstore *bookstore;
@end

@implementation KEXMLNSModelTests

- (void)setUp
{
    [super setUp];
    
    NSString *fullfilename = [[NSBundle bundleForClass:[self class]] pathForResource:@"sample" ofType:@"xml"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullfilename]) {
        STFail(@"sample.xml not found in LibXML2NSObjectTests");
    }
    
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:fullfilename];
    self.bookstore = [Bookstore loadContentsFromXMLData:data];
}

- (void)tearDown
{
    self.bookstore = nil;
    [super tearDown];
}

- (void)testDotProperty
{
    //    STFail(@"Unit tests are not implemented yet in LibXML2NSObjectTests");
    NSLog(@"count = %d", self.bookstore.bookArray.count);
    STAssertTrue(self.bookstore.bookArray.count == 3, @"Number of books not equal 3.");
    
    // 1st book
    Book *book1 = self.bookstore.bookArray[0];
    STAssertTrue([book1.category isEqualToString:@"COOKING"], @"1st book's category is not COOKING.");
    STAssertTrue([book1.title isEqualToString:@"Everyday Italian"], @"1st book's title is not Everyday Italian");
    STAssertTrue([book1.author isEqualToString:@"Giada De Laurentiis"], @"1st book author is not Giada De Laurentiis");
    
    // 2nd book
    Book *book2 = self.bookstore.bookArray[1];
    STAssertTrue([book2.category isEqualToString:@"CHILDREN"], @"2nd book's category is not CHILDREN");
    STAssertTrue([book2.title isEqualToString:@"Harry Potter"], @"2nd book's title is not Harry Potter");
    STAssertTrue([book2.author isEqualToString:@"J K. Rowling"], @"2nd book author is not J K. Rowling");
    
    // 3rd book
    Book *book3 = self.bookstore.bookArray[2];
    STAssertTrue([book3.category isEqualToString:@"WEB"], @"3rd book's category is not WEB");
    STAssertTrue([book3.title isEqualToString:@"Learning XML"], @"3rd book's title is not Learning XML");
    STAssertTrue([book3.author isEqualToString:@"Erik T. Ray"], @"3rd book author is not Erik T. Ray");
    
}

-(void)testKVC {
    NSLog(@"Testing KVC calls");
    
    NSArray *books = (NSArray*)[self.bookstore valueForKey:@"bookArray"];
    Book *book1 = books[0];
    
    STAssertTrue([[book1 valueForKey:@"category"] isEqualToString:@"COOKING"], @"1st book's category is not COOKING.");
    STAssertTrue([[book1 valueForKey:@"title"] isEqualToString:@"Everyday Italian"], @"1st book's title is not Everyday Italian");
    STAssertTrue([[book1 valueForKey:@"author"] isEqualToString:@"Giada De Laurentiis"], @"1st book author is not Giada De Laurentiis");
}

-(void)testUndefinedProperty {
    Book *book1 = self.bookstore.bookArray[0];
    NSString *bogus = book1.bogus;
    
    STAssertTrue(bogus == nil, @"Undefined key 'bogus' is not nil. Unit test actually should have crashed before even reaching here.");
}

@end
