//
//  main.m
//  ChapterX
//
//  Created by Oleksandr Tymoshenko on 11-07-31.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Chapter.h"

int main (int argc, const char * argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSURL *xmlURL;
    NSError *xmlError;
    
    if (argc < 2) {
        fprintf(stderr, "Missing input XML file\n"); 
        fprintf(stderr, "Usage: ChapterX file.xml\n");
        exit(1);
    }
    
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
    
    for (NSXMLNode *n in nodes) {
        Chapter *chapter = [[Chapter alloc] initWithXMLNode:n];
    }

    [pool drain];
    return 0;
}

