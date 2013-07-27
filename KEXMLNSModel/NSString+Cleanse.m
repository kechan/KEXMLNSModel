//
//  NSString+Cleanse.m
//  SLPOC
//
//  Created by Kelvin Chan on 10/14/12.
//
//

#import "NSString+Cleanse.h"

@implementation NSString (Cleanse)

-(NSString *) cleanse {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

-(BOOL) isNumeric {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    NSNumber *number = [formatter numberFromString:self];
    return !!number;
}

@end
