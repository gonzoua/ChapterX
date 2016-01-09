//
//  Chapter.h
//  ChapterX
//
//  Created by Oleksandr Tymoshenko on 11-07-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Chapter : NSObject {
    NSInteger _startTime;
    NSString *_artPath;
    NSString *_title;
    NSString *_link;
    NSString *_linkText;
    NSString *_xmlPath;
}

@property (nonatomic,retain) NSString *artPath;
@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSString *link;
@property (nonatomic,retain) NSString *linkText;
@property (nonatomic,assign) NSInteger startTime;

- (id) initWithXMLNode: (NSXMLNode*)node;
- (id) initWithXMLNode: (NSXMLNode*)node path:(NSString*)path;

@end
