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

using namespace std;

int addChapters(const char *mp4, NSArray *chapters)
{ 
    if ([chapters count] == 0)
        return 0;

    MP4FileHandle mp4File = MP4Modify( mp4 );
    
    if( mp4File == MP4_INVALID_FILE_HANDLE )
        return -1;
    
    MP4TrackId refTrackId = MP4_INVALID_TRACK_ID;
    uint32_t trackCount = MP4GetNumberOfTracks( mp4File );

    for( uint32_t i = 0; i < trackCount; ++i ) {
        MP4TrackId    id = MP4FindTrackId( mp4File, i );
        const char* type = MP4GetTrackType( mp4File, id );
        if( MP4_IS_AUDIO_TRACK_TYPE( type ) ) {
            refTrackId = id;
            break;
        }
    }
    
    if( !MP4_IS_VALID_TRACK_ID(refTrackId) )
        return -1;

    MP4Duration origTrackDuration = MP4GetTrackDuration( mp4File, refTrackId ); 
    uint32_t trackTimeScale = MP4GetTrackTimeScale( mp4File, refTrackId );
    MP4Duration trackDuration = origTrackDuration / trackTimeScale;
    vector<MP4Chapter_t> mp4chapters;

    // MP4TrackId urlTrackId = MP4AddHrefTrack(mp4File, 1000, MP4_INVALID_DURATION);
    MP4TrackId videoTrackId = MP4AddJpegVideoTrack(mp4File, trackTimeScale, MP4_INVALID_DURATION,
        160, 160);
    
    Chapter *firstChapter = [chapters objectAtIndex:0];
    if (firstChapter.startTime != 0) {
        MP4Chapter_t chap;
        chap.title[0] = '\0';
        chap.duration = firstChapter.startTime;
        mp4chapters.push_back( chap );

        const char *url = [firstChapter.link UTF8String];
        NSData *img = [NSData dataWithContentsOfFile:@"art/00788059234619.jpg"];
        MP4WriteSample(mp4File, videoTrackId, 
		    (const uint8_t *)[img bytes], [img length], origTrackDuration);
#if 0
        if (url != NULL)
            MP4WriteSample(mp4File, urlTrackId, 
			    (u_int8_t*)url, (uint32_t)strlen(url) + 1, (MP4Duration)chap.duration);
        else
            MP4WriteSample(mp4File, urlTrackId, (const uint8_t *)"", 1, (MP4Duration)chap.duration);
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

        // write href to link
        const char *url = [firstChapter.link UTF8String];
#if 0
        if (url != NULL)
            MP4WriteSample(mp4File, urlTrackId, 
			    (u_int8_t*)url, (uint32_t)strlen(url) + 1, (MP4Duration)chap.duration);
        else
            MP4WriteSample(mp4File, urlTrackId, (const uint8_t *)"", 1, (MP4Duration)chap.duration);
#endif
    }
    
    uint64_t flags;
    MP4GetTrackIntegerProperty(mp4File, videoTrackId, "tkhd.flags", &flags);
    NSLog(@"--> %lld\n", flags);
    flags |= 7;
    MP4SetTrackIntegerProperty(mp4File, videoTrackId, "tkhd.flags", flags);
    MP4SetChapters(mp4File, &mp4chapters[0], (int)mp4chapters.size(), MP4ChapterTypeQt);
    MP4Close(mp4File);
    
    return 0;
}
