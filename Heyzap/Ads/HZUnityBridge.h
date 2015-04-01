/*
 * Copyright (c) 2015, Heyzap, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * * Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 *
 * * Neither the name of 'Heyzap, Inc.' nor the names of its contributors
 *   may be used to endorse or promote products derived from this software
 *   without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __Heyzap__UnityBridge__
#define __Heyzap__UnityBridge__

#include <stdio.h>
#import "HeyzapAds.h"

extern "C" {
    void hz_ads_start_app(const char *publisher_id, HZAdOptions flags);
    void hz_ads_show_interstitial(const char *tag);
    void hz_ads_hide_interstitial(void);
    void hz_ads_fetch_interstitial(const char *tag);
    bool hz_ads_interstitial_is_available(const char *tag);
    void hz_ads_show_video(const char *tag);
    void hz_ads_hide_video(void);
    void hz_ads_fetch_video(const char *tag);
    bool hz_ads_video_is_available(const char *tag);
    void hz_ads_show_incentivized(const char *tag);
    void hz_ads_hide_incentivized();
    void hz_ads_fetch_incentivized(const char *tag);
    bool hz_ads_incentivized_is_available(const char *tag);
    void hz_ads_incentivized_set_user_identifier(const char *identifier);
    void hz_ads_show_banner(const char *tag, const char *position);
    void hz_ads_hide_banner();
    void hz_ads_show_mediation_debug_view_controller();
}

#endif /* defined(__Heyzap__UnityBridge__) */