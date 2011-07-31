//
//  Chapter.m
//  ChapterX
//
//  Created by Oleksandr Tymoshenko on 11-07-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Chapter.h"

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

@end
