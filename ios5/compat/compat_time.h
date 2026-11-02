// clock_gettime() appeared in iOS 10. Emulate it on top of gettimeofday()
// and mach_absolute_time() for code that requires it (libc++ chrono, filesystem).
#pragma once

#include <mach/mach_time.h>
#include <sys/time.h>
#include <time.h>

#ifndef CLOCK_REALTIME
#define CLOCK_REALTIME 0
#define CLOCK_MONOTONIC_RAW 4
#define CLOCK_MONOTONIC 6

static inline int fh2_clock_gettime( int clockId, struct timespec * tp )
{
    if ( clockId == CLOCK_REALTIME ) {
        struct timeval tv;
        gettimeofday( &tv, 0 );
        tp->tv_sec = tv.tv_sec;
        tp->tv_nsec = tv.tv_usec * 1000;
        return 0;
    }

    static mach_timebase_info_data_t timebase;
    if ( timebase.denom == 0 ) {
        mach_timebase_info( &timebase );
    }
    const unsigned long long ns = mach_absolute_time() * timebase.numer / timebase.denom;
    tp->tv_sec = (time_t)( ns / 1000000000ULL );
    tp->tv_nsec = (long)( ns % 1000000000ULL );
    return 0;
}

#define clock_gettime fh2_clock_gettime
#endif
