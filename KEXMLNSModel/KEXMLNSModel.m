//
//  KEXMLNSModel.m
//  KEXMLNSModel
//
//  Created by Kelvin Chan on 7/27/13.
//  Copyright (c) 2013 Kelvin Chan. All rights reserved.
//

#import "KEXMLNSModel.h"

@implementation KEXMLNSModel

+(id) loadContentsFromXMLFile:(NSString *)filename {
    NSMutableData *xmlData = [self getXMLDataFromXMLFile:filename];
    return [self loadContentsFromXMLData:xmlData];
}

+(id) loadContentsFromXMLString:(NSString *)xmlString {
    NSMutableData *xmlData = [[xmlString dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    return [self loadContentsFromXMLData:xmlData];
}

+(id) loadContentsFromXMLData:(NSData *)xmlData {
    return [[self alloc] initWithData:xmlData];
}

+(id) loadContentsFromGDataXMLElement:(GDataXMLElement *)gDataXMLElement {
    return [[self alloc] initWithGDataXMLElement:gDataXMLElement];
}

#pragma mark - Helpers

+ (NSString *)propertyTypeStringOfProperty:(objc_property_t) property {
    
    // TODO: Auto-doc this with Xcode 5
    // return the String representing the name of the property's type, eg. "NSMutableArray", "NSString", etc.
    
    const char *attr = property_getAttributes(property);
    NSString *const attributes = [NSString stringWithCString:attr encoding:NSUTF8StringEncoding];
    
    NSRange const typeRangeStart = [attributes rangeOfString:@"T@\""];  // start of type string
    if (typeRangeStart.location != NSNotFound) {
        NSString *const typeStringWithQuote = [attributes substringFromIndex:typeRangeStart.location + typeRangeStart.length];
        NSRange const typeRangeEnd = [typeStringWithQuote rangeOfString:@"\""]; // end of type string
        if (typeRangeEnd.location != NSNotFound) {
            NSString *const typeString = [typeStringWithQuote substringToIndex:typeRangeEnd.location];
            return typeString;
        }
    }
    return nil;
}

// Helper to extract content of a file as NSData
+(NSMutableData *) getXMLDataFromXMLFile:(NSString *)filename {
    NSString *fullfilename = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullfilename]) {
        return nil;
    }
    
    return [[NSMutableData alloc] initWithContentsOfFile:fullfilename];
}

+(NSString *)removeSuffixArray:(NSString *)inputString {
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Array$" options:NSRegularExpressionCaseInsensitive error:&error];
    
    NSMutableString *str = [inputString mutableCopy];
    
    [regex replaceMatchesInString:str options:0 range:NSMakeRange(0, inputString.length) withTemplate:@""];
    
    return str;
}

+(NSString *)camelCaseStyleToDashStyle:(NSString *)inputString {
    
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"([a-z])([A-Z])" options:0 error:NULL];
    NSString *dashString = [[regexp stringByReplacingMatchesInString:inputString options:0 range:NSMakeRange(0, inputString.length) withTemplate:@"$1-$2"] lowercaseString];
    
    return dashString;
}

#pragma mark - Getters & Setters
-(NSMutableDictionary *)propertiesDictionary {
    if (_propertiesDictionary == nil) {
        _propertiesDictionary = [[NSMutableDictionary alloc] init];
    }
    return _propertiesDictionary;
}

#pragma mark - LifeCycles

-(id) initWithData:(NSData*)data {
    self = [super init];
    if (self) {
        NSError *error;
        GDataXMLDocument *doc = [[GDataXMLDocument alloc] initWithData:data options:0 error:&error];
        // FIXME: check for error?
        self.xmlDoc = doc;
        
        if (self.xmlDoc == nil)
            return nil;
        else {
            GDataXMLElement *root = self.xmlDoc.rootElement;
            [self parseAndBuildObject:root];
        }
        
    }
    return self;
}

-(id) initWithGDataXMLElement:(GDataXMLElement *)gDataXMLElement {
    self = [super init];
    if (self) {
        self.rootXMLElement = gDataXMLElement;
        if (self.rootXMLElement == nil)
            return nil;
        else {
            GDataXMLElement *root = self.rootXMLElement;
            [self parseAndBuildObject:root];
        }
    }
    return self;
}

#pragma mark - Parsing & Object Building
-(void) parseAndBuildObject:(GDataXMLElement *)root {
    // Subclass should override this
}

#pragma mark - The Dynamic Gymastic
// This is to allow construction of accessors at runtime, on the fly.

+(BOOL) resolveInstanceMethod:(SEL)sel {
    
    // TODO: handle <title lang="en">Everyday Italian</title>, ie. presence of attribute at leaf node.
    
    NSString *methodName = NSStringFromSelector(sel);
    NSString *instanceVar;
    
    if ([methodName hasPrefix:@"set"]) {
        NSRange range = [methodName rangeOfString:@"set"];
        instanceVar = [[[methodName stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    else if ([methodName hasPrefix:@"get"]) {
        NSRange range = [methodName rangeOfString:@"get"];
        instanceVar = [[[methodName stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    else {
        instanceVar = methodName;
    }
    
    // Introspect on the instanceVar's datatype (or its class)
    objc_property_t property = class_getProperty([self class], [instanceVar UTF8String]);
    if (property == nil)   // this class has no such property
        return [super resolveInstanceMethod:sel];
    
    NSString *propertyType = [[self class] propertyTypeStringOfProperty:property];
    Class classOfInstanceVar = NSClassFromString(propertyType);
    
    BOOL isAKindOfXMLNode = NO;
    if ([classOfInstanceVar isSubclassOfClass:[KEXMLNSModel class]]) {
        isAKindOfXMLNode = YES;
    }
    
    // System may call instance that may begin with "_", do NOT interfere with that.
    if (![[instanceVar substringToIndex:1] isEqualToString:@"_"]) {
        
        if ([methodName hasPrefix:@"set"]) {
            if ([propertyType isEqualToString:@"NSMutableArray"]) {
                class_addMethod([self class], sel, (IMP) accessorSetterForNSMutableArray, "v@:@");
                return YES;
            }
            else if (isAKindOfXMLNode) {
                class_addMethod([self class], sel, (IMP) accessorSetterForNode, "v@:@");
                return YES;
            }
            else {
                class_addMethod([self class], sel, (IMP) accessorSetter, "v@:@");
                return YES;
            }
        }
        else
        {
            if ([propertyType isEqualToString:@"NSMutableArray"]) {
                class_addMethod([self class], sel, (IMP) accessorGetterForNSMutableArray, "@@:");
                return YES;
            }
            else if (isAKindOfXMLNode) {
                class_addMethod([self class], sel, (IMP) accessorGetterForNode, "@@:");
                return YES;
            }
            else {
                class_addMethod([self class], sel, (IMP) accessorGetter, "@@:");
                return YES;
            }
        }
    }
    
    return [super resolveInstanceMethod:sel];
}

void accessorSetter(id self, SEL _cmd, id newValue) {
    
    NSString *method = NSStringFromSelector(_cmd);
    
    NSRange range = [method rangeOfString:@"set"];
    
    NSString *instanceVar = [[[method stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (newValue != nil) {
        [propertiesFromDictionary setObject:newValue forKey:instanceVar];
    }
    else
        [propertiesFromDictionary removeObjectForKey:instanceVar];
    
}

void accessorSetterForNSMutableArray(id self, SEL _cmd, id newValue) {
    NSString *method = NSStringFromSelector(_cmd);
    
    NSRange range = [method rangeOfString:@"set"];
    
    NSString *instanceVar = [[[method stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (newValue != nil)
        [propertiesFromDictionary setObject:newValue forKey:instanceVar];
    else
        [propertiesFromDictionary removeObjectForKey:instanceVar];
}

void accessorSetterForNode(id self, SEL _cmd, id newValue) {
    NSString *method = NSStringFromSelector(_cmd);
    
    NSRange range = [method rangeOfString:@"set"];
    
    NSString *instanceVar = [[[method stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (newValue != nil)
        [propertiesFromDictionary setObject:newValue forKey:instanceVar];
    else
        [propertiesFromDictionary removeObjectForKey:instanceVar];
}

id accessorGetter(id self, SEL _cmd) {
    NSString *method = NSStringFromSelector(_cmd);
    
    NSString *instanceVar;
    if ([method hasPrefix:@"get"]) {
        NSRange range = [method rangeOfString:@"get"];
        instanceVar = [[[method stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    else
        instanceVar = method;
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (propertiesFromDictionary[instanceVar] == nil) {
        // get it from XML root, we need to check both
        //   - xmlDoc.rootElement, initialized from external byte (file, xmlstring, data)
        //   - rootXMLElement, initialized from GDataXMLElement object in memory.
        
        GDataXMLElement *root, *xmlElem;
        
        if ([self rootXMLElement] != nil)
            root = [self rootXMLElement];
        else if ([self xmlDoc] != nil)
            root = [self xmlDoc].rootElement;
        else
            ;
        
        // A node can have attribute as well as innerText,
        // Rule: if attribute exist for that name, this will be used and the innerText will be ignored.
        //       if attribute does not exist for that name, then innerText will be used.
        //
        // Exception: All attribute value and innerText are assmed to be NSString, except version, which is NSNumber
        
        id value;
        NSString *instanceVarWithDash = [[self class] camelCaseStyleToDashStyle:instanceVar];
        
        if ([instanceVar isEqualToString:@"version"] && [root attributeForName:@"version"] != nil)
            value = @([root attributeForName:@"version"].stringValue.cleanse.floatValue);
        else if ([root attributeForName:instanceVarWithDash] != nil)
            value = [root attributeForName:instanceVarWithDash].stringValue.cleanse;
        else {
            xmlElem = [root elementsForName:instanceVarWithDash][0];
            if ([xmlElem.stringValue.cleanse isNumeric])
                value = @(xmlElem.stringValue.cleanse.floatValue);
            else {
                // This is a non-numeric string, format the \n and \t
                value = [[xmlElem.stringValue.cleanse stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"] stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
            }
        }
        if (value != nil)
            propertiesFromDictionary[instanceVar] = value;
    }
    
    return propertiesFromDictionary[instanceVar];
}

id accessorGetterForNSMutableArray(id self, SEL _cmd) {
    NSString *method = NSStringFromSelector(_cmd);
    
    NSString *instanceVar = method;
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (propertiesFromDictionary[instanceVar] == nil) {
        // get it from XML root, we need to check both
        //   - xmlDoc.rootElement, initialized from external byte (file, xmlstring, data)
        //   - rootXMLElement, initialized from GDataXMLElement object in memory.
        
        GDataXMLElement *root;
        
        if ([self rootXMLElement] != nil)
            root = [self rootXMLElement];
        else if ([self xmlDoc] != nil)
            root = [self xmlDoc].rootElement;
        else
            ;
        
        // Need to find out the class of the object populating the array "myObjectArray" by following this "convention":
        // (1) Remove the suffix "Array" from the instance variable name, eg. "myObject"
        // (2) Capitalise the first letter of the instance variable, eg. "MyObject"
        // (3) For the name of the XML tag, convert the camel case "MyObject" to "my-object" (using dashes).
        
        // (2) Convert the first letter from lowercase to uppercase
        NSString *firstChar = [[instanceVar substringToIndex:1] uppercaseString];
        NSString *tmp = [firstChar stringByAppendingString:[instanceVar substringFromIndex:1]];
        
        // (1) remove the suffix "Array"
        NSString *nodeClassName = [[self class] removeSuffixArray:tmp];
        
        Class nodeClass = NSClassFromString(nodeClassName);
        
        NSString *elemName = [[self class] removeSuffixArray:instanceVar];
        
        // (3) Convert camel case -> dash convention ususally seen in XML (eg. "my-object")
        NSString *elemNameWithDash = [[self class] camelCaseStyleToDashStyle:elemName];
        
        NSArray *xmlElems = [root elementsForName:elemNameWithDash];
        NSMutableArray *returnArray = [NSMutableArray new];
        for (GDataXMLElement *elem in xmlElems) {
            id v = [nodeClass performSelector:@selector(loadContentsFromGDataXMLElement:) withObject:elem];
            
            [returnArray addObject:v];
        }
        
        propertiesFromDictionary[instanceVar] = returnArray;
        
    }
    
    return propertiesFromDictionary[instanceVar];
}

id accessorGetterForNode(id self, SEL _cmd) {
    NSString *method = NSStringFromSelector(_cmd);
    
    NSString *instanceVar;
    if ([method hasPrefix:@"get"]) {
        NSRange range = [method rangeOfString:@"get"];
        instanceVar = [[[method stringByReplacingCharactersInRange:range withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];
    }
    else
        instanceVar = method;
    
    NSMutableDictionary *propertiesFromDictionary = [self propertiesDictionary];
    
    if (propertiesFromDictionary[instanceVar] == nil) {
        // get it from XML root, we need to check both
        //   - xmlDoc.rootElement, initialized from external byte (file, xmlstring, data)
        //   - rootXMLElement, initialized from GDataXMLElement object in memory.
        
        GDataXMLElement *root;
        
        if ([self rootXMLElement] != nil)
            root = [self rootXMLElement];
        else if ([self xmlDoc] != nil)
            root = [self xmlDoc].rootElement;
        else
            ;
        
        // Introspect on the instanceVar's datatype
        objc_property_t property = class_getProperty([self class], [instanceVar UTF8String]);
        NSString *propertyType = [[self class] propertyTypeStringOfProperty:property];
        
        Class nodeClass = NSClassFromString(propertyType);
        
        // TODO: instead of just using instanceVar to look for the corresponding XML node tag, should do a camelcase to dash conversion.
        // eg. responseInfo -> response-info
        NSString *instanceVarWithDash = [[self class] camelCaseStyleToDashStyle:instanceVar];
        NSArray *xmlElems = [root elementsForName:instanceVarWithDash];
        id value;
        if (xmlElems != nil && xmlElems.count == 1) {
            value = [nodeClass performSelector:@selector(loadContentsFromGDataXMLElement:) withObject:xmlElems[0]];
            propertiesFromDictionary[instanceVar] = value;
        }
    }
    
    return propertiesFromDictionary[instanceVar];
    
}

@end
