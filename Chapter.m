//
//  Chapter.m
//  ChapterX
//
//  Created by Oleksandr Tymoshenko on 11-07-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Chapter.h"

@implementation NSXMLNode (oneChildXPath)

-(NSString *) stringForXPath:(NSString*)xpath error:(NSError**)error
{
    NSArray *nodes = [self nodesForXPath:xpath error:error];

    if ([nodes count])
        return [[nodes objectAtIndex:0] stringValue];
    else
        return nil;
}

@end

@implementation Chapter

@synthesize startTime = _startTime;
@synthesize title = _title;
@synthesize link = _link;
@synthesize artPath = _artPath;

- (id)init
{
    self = [super init];
    if (self) {
        _title = nil;
        _link = nil;
        _artPath = nil;
        _startTime = 0;
    }
    
    return self;
}

- (id) initWithXMLNode: (NSXMLNode*)node
{
    NSError *xmlError;
    self = [self init];
    
    self.title = [node stringForXPath:@"./title[1]" error:&xmlError];
    self.link = [node stringForXPath:@"./link[1]" error:&xmlError];
    self.artPath = [node stringForXPath:@"./picture[1]" error:&xmlError];
    
    return self;
}

@end
