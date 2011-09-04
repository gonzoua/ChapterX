//
//  main.m
//  ChapterX
//
//  Created by Oleksandr Tymoshenko on 11-07-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chapter.h"
#import "ChaptersEditor.h"

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSURL *xmlURL;
    NSError *xmlError;
    
    if (argc < 3) {
        fprintf(stderr, "Not enough arguments\n"); 
        fprintf(stderr, "Usage: ChapterX file.xml file.m4b\n");
        exit(1);
    }
    
    NSURL *testURL = [NSURL fileURLWithPath:[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]];
    NSString *xmlPath = [[testURL path] stringByDeletingLastPathComponent];
    xmlURL = [NSURL fileURLWithPath:[NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]];

    NSXMLDocument *document = [[NSXMLDocument alloc] initWithContentsOfURL:xmlURL options:0 error:&xmlError];
    if (!document) {
        NSLog(@"XML parsing error: %@\n", [xmlError localizedDescription]);
        exit(1);
    }
    
    NSArray *nodes = [document nodesForXPath:@"./chapters/chapter"
                                      error:&xmlError];
    if (xmlError) {
        NSLog(@"Internal XML error: %@\n", [xmlError localizedDescription]);
        exit(1);
    }
    
    NSMutableArray *chapters = [[NSMutableArray alloc] init];
    for (NSXMLNode *n in nodes) {
        Chapter *chapter = [[Chapter alloc] initWithXMLNode:n path:xmlPath];
        [chapters addObject:chapter];
    }
    
    addChapters(argv[2], chapters);

    [pool drain];
    return 0;
}

