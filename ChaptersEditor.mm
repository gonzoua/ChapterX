/*
 *  MetaEditor.cpp
 *  AudioBookBinder
 *
 *  Created by Oleksandr Tymoshenko on 11-07-31.
 *  Copyright 2010 Bluezbox Software. All rights reserved.
 *
 */

extern "C" {
#include "ChaptersEditor.h"
};
#include <vector>
#include <mp4v2/mp4v2.h>
#import "Chapter.h"
#include "empty.h"

#import <Cocoa/Cocoa.h>

using namespace std;

#define ITUNES_COVER_SIZE 300
#define HAVE_SUBTITLES 1

static
NSData *loadImage(NSString *path)
{
    if (path == nil)
        return nil;

    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path]; 
    NSImage *scaledImage = nil;
    
    if (image == nil)
        return nil;
    
    NSImageRep *rep = [[image representations] objectAtIndex:0]; 
    [image setScalesWhenResized:YES]; 
    [image setSize:NSMakeSize([rep pixelsWide], [rep pixelsHigh])]; 
    
    NSSize origSize = NSMakeSize([rep pixelsWide], [rep pixelsHigh]);
    
    {
        NSSize scaledSize;
        if (origSize.width > origSize.height) {
            scaledSize.width = ITUNES_COVER_SIZE;
            scaledSize.height = origSize.height * ITUNES_COVER_SIZE/origSize.width;
        }
        else {
            scaledSize.height = ITUNES_COVER_SIZE;
            scaledSize.width = origSize.width * ITUNES_COVER_SIZE/origSize.height;                
        }

        scaledImage = [[[NSImage alloc] initWithSize:scaledSize] retain];
        
        // Composite image appropriately
        [scaledImage lockFocus];
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        [image drawInRect:NSMakeRect(0, 0, scaledSize.width, scaledSize.height) 
                    fromRect:NSMakeRect(0, 0, origSize.width, origSize.height)
                   operation:NSCompositeSourceOver 
                    fraction:1.0];
        [scaledImage unlockFocus];
    }

    // Cache the reduced image
    NSData *imageData = [scaledImage TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];

    [image release];
    return imageData;
}

static
NSData *generateSample(NSString *text, NSString *url)
{
    int textLength = [text lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    int urlLength = [url lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    int atomLength = urlLength + 14;
    int fullLength = textLength + urlLength + 14;
    int ptr;

    unsigned char *atom = (unsigned char*)malloc(textLength + urlLength + 16);
    if (atom == NULL)
        return nil;
    atom[0] = (textLength >> 8) & 0xff;
    atom[1] = textLength & 0xff;
    if (textLength)
        memcpy(atom+2, [text UTF8String], textLength);
    ptr = textLength + 2;
    atom[ptr++] = (atomLength >> 24) & 0xff;
    atom[ptr++] = (atomLength >> 16) & 0xff;
    atom[ptr++] = (atomLength >>  8) & 0xff;
    atom[ptr++] = atomLength & 0xff;
    memcpy(atom+ptr, "href", 4);
    ptr += 4;

    // start position
    atom[ptr++] = 0;
    atom[ptr++] = 0;

    // stop position
    atom[ptr++] = (textLength >> 8) & 0xff;
    atom[ptr++] = textLength & 0xff;
    atom[ptr++] = urlLength & 0xff;
    if (urlLength)
        memcpy(atom+ptr, [url UTF8String], urlLength);
    ptr += urlLength;
    atom[ptr++] = 0; // no hint
    NSData *result = [NSData dataWithBytes:atom length:ptr];

#if 0
    NSLog(@"-- %@ -- %@ -- %d/%d", text, url, ptr, atomLength);
    for (int i = 0; i < atomLength + 2; i++) {
        fprintf(stderr, "%02x ", atom[i]);
        if ((i % 16) == 0xf)
            fprintf(stderr, "\n");
    }
    fprintf(stderr, "\n");
#endif

    return result;
}


int addChapters(const char *mp4, NSArray *chapters)
{ 
    if ([chapters count] == 0)
        return 0;

    MP4FileHandle mp4File = MP4Modify( mp4 );
    
    if( mp4File == MP4_INVALID_FILE_HANDLE )
        return -1;
    
    MP4TrackId refTrack = MP4_INVALID_TRACK_ID;
    uint32_t trackCount = MP4GetNumberOfTracks( mp4File );

    for( uint32_t i = 0; i < trackCount; ++i ) {
        MP4TrackId id = MP4FindTrackId( mp4File, i );
        const char* type = MP4GetTrackType( mp4File, id );
        if( MP4_IS_AUDIO_TRACK_TYPE( type ) ) {
            refTrack = id;
            break;
        }
    }
    
    if( !MP4_IS_VALID_TRACK_ID(refTrack) )
        return -1;

    MP4Duration origTrackDuration = MP4GetTrackDuration( mp4File, refTrack ); 
    uint32_t trackTimeScale = MP4GetTrackTimeScale( mp4File, refTrack );
    MP4Duration trackDuration = origTrackDuration / trackTimeScale;
    vector<MP4Chapter_t> mp4chapters;

    MP4TrackId jpegTrack = MP4AddJpegVideoTrack(mp4File, trackTimeScale, MP4_INVALID_DURATION,
        300, 300);

#ifdef HAVE_SUBTITLES
    // Add subtitles
    MP4TrackId subtitlesTrack = MP4AddSubtitleTrack( mp4File, trackTimeScale, 300, 300 );

    const uint8_t textColor[4] = { 0,0,0,255 };

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "tkhd.alternate_group", 0);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.dataReferenceIndex", 1);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.horizontalJustification", 1);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.verticalJustification", 255);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.bgColorAlpha", 0);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.defTextBoxBottom", 0);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.defTextBoxRight", 0);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontID", 1);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontSize", 0);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontColorRed", textColor[0]);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontColorGreen", textColor[1]);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontColorBlue", textColor[2]);
    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "mdia.minf.stbl.stsd.tx3g.fontColorAlpha", textColor[3]);

    MP4SetTrackIntegerProperty(mp4File, subtitlesTrack, "tkhd.flags", 0xf);
#endif
    
    Chapter *firstChapter = [chapters objectAtIndex:0];
    if (firstChapter.startTime != 0) {
        MP4Chapter_t chap;
        chap.title[0] = '\0';
        chap.duration = firstChapter.startTime;
        mp4chapters.push_back( chap );

        NSData *img = [NSData dataWithBytes:__1x1_png length:__1x1_png_len];
        MP4WriteSample(mp4File, jpegTrack, 
		    (const uint8_t *)[img bytes], [img length], chap.duration*trackTimeScale/1000);

#ifdef HAVE_SUBTITLES
		NSData* subtitlesSample = generateSample(@"", @" ");

        MP4WriteSample(mp4File, subtitlesTrack, 
		    (const uint8_t *)[subtitlesSample bytes], [subtitlesSample length], chap.duration*trackTimeScale/1000);
#endif
    }

    for (int idx = 0; idx < [chapters count]; idx++) {
        Chapter *chapter = [chapters objectAtIndex:idx];
        MP4Chapter_t chap;
        if (idx == [chapters count] -1) {
            if (trackDuration*1000 > chapter.startTime)
                chap.duration = trackDuration*1000 - chapter.startTime;
            else
                chap.duration = 0;
        }
        else {
            Chapter *nextChapter = [chapters objectAtIndex:(idx+1)];
            chap.duration = nextChapter.startTime - chapter.startTime;
        }
        strncpy(chap.title, 
                [chapter.title UTF8String], sizeof(chap.title)-1);
        
        mp4chapters.push_back( chap );

        NSData *img = nil;
        if (chapter.artPath)
            img = loadImage(chapter.artPath);
        if (img == nil)
            img = [NSData dataWithBytes:__1x1_png length:__1x1_png_len];

        NSString *name = [NSString stringWithFormat:@"%d.jpg", idx];
        [img writeToFile:name atomically:nil];

        MP4WriteSample(mp4File, jpegTrack, 
		    (const uint8_t *)[img bytes], [img length], chap.duration*trackTimeScale/1000);

#ifdef HAVE_SUBTITLES
		NSData* subtitlesSample;
        if (chapter.link != nil)
		    subtitlesSample = generateSample(chapter.linkText, chapter.link);
        else
		    subtitlesSample = generateSample(@"", @" ");

        MP4WriteSample(mp4File, subtitlesTrack, 
		    (const uint8_t *)[subtitlesSample bytes], [subtitlesSample length], chap.duration*trackTimeScale/1000);
#endif
    }
    
#define TRACK_DISABLED 0x0
#define TRACK_ENABLED 0x1
#define TRACK_IN_MOVIE 0x2
#define TRACK_IN_PREVIEW 0x4
#define TRACK_IN_POSTER 0x8

    MP4SetTrackIntegerProperty(mp4File, jpegTrack, "tkhd.flags", 
        (TRACK_ENABLED | TRACK_IN_MOVIE | TRACK_IN_PREVIEW | TRACK_IN_POSTER));
    MP4SetChapters(mp4File, &mp4chapters[0], (int)mp4chapters.size(), MP4ChapterTypeQt);

    MP4AddTrackReference(mp4File, "tref.chap", jpegTrack, refTrack);

    MP4SetTrackLanguage(mp4File, refTrack, "eng");
    MP4SetTrackLanguage(mp4File, jpegTrack, "eng");
    MP4SetTrackLanguage(mp4File, subtitlesTrack, "eng");
    MP4Close(mp4File);
    
    return 0;
}
