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

    MP4FileHandle h = MP4Modify( mp4 );
    
    if( h == MP4_INVALID_FILE_HANDLE )
        return -1;
    
    MP4TrackId refTrackId = MP4_INVALID_TRACK_ID;
    uint32_t trackCount = MP4GetNumberOfTracks( h );

    for( uint32_t i = 0; i < trackCount; ++i ) {
        MP4TrackId    id = MP4FindTrackId( h, i );
        const char* type = MP4GetTrackType( h, id );
        if( MP4_IS_AUDIO_TRACK_TYPE( type ) ) {
            refTrackId = id;
            break;
        }
    }
    
    if( !MP4_IS_VALID_TRACK_ID(refTrackId) )
        return -1;

    MP4Duration trackDuration = MP4GetTrackDuration( h, refTrackId ); 
    uint32_t trackTimeScale = MP4GetTrackTimeScale( h, refTrackId );
    trackDuration /= trackTimeScale;
    vector<MP4Chapter_t> mp4chapters;
    
    Chapter *firstChapter = [chapters objectAtIndex:0];
    if (firstChapter.startTime != 0) {
        MP4Chapter_t chap;
        chap.title[0] = '\0';
        chap.duration = firstChapter.startTime;
        mp4chapters.push_back( chap );
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
    }
    
    MP4SetChapters(h, &mp4chapters[0], (int)mp4chapters.size(), MP4ChapterTypeQt);
    MP4Close(h);
    
    return 0;
}
