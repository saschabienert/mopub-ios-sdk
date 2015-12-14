# Integration Test Videos

## Warning about audio in videos

Both Circle CI and Travis CI seem to have trouble playing audio in videos. They'll encounter errors like the following:

```
2015-12-11 11:45:52.066 IntegrationTestHost[22153:28457] 11:45:52.065 WARNING:  40: ERROR: couldn't get default input device, ID = 0, err = 0!
2015-12-11 11:45:52.066 IntegrationTestHost[22153:28457] 11:45:52.066 WARNING:  40: ERROR: couldn't get default output device, ID = 0, err = 0!
2015-12-11 11:45:52.066 IntegrationTestHost[22153:28457] 11:45:52.066 ERROR:    708: Error finding valid input or output devices!
2015-12-11 11:45:52.066 IntegrationTestHost[22153:28457] 11:45:52.066 ERROR:    312: error -66680
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28517] 11:45:52.067 ERROR:    312: error -66680
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28457] 11:45:52.067 ERROR:    130: * * * NULL AQIONode object
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28517] 11:45:52.067 ERROR:    312: error -66680
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28517] 11:45:52.067 ERROR:    312: error -66680
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28517] 11:45:52.067 ERROR:    312: error -66680
2015-12-11 11:45:52.067 IntegrationTestHost[22153:28457] 11:45:52.067 ERROR:    753: Can't make UISound Renderer
2015-12-11 11:45:52.072 IntegrationTestHost[22153:28385] [ Heyzap ] Mediation: ad shown from heyzap_cross_promo
2015-12-11 11:45:52.120 IntegrationTestHost[22153:28385] Showing video
2015-12-11 11:45:52.122 IntegrationTestHost[22153:28385] [ Heyzap ] Success reporting fetch
2015-12-11 11:45:52.128 IntegrationTestHost[22153:28385] [ Heyzap ] Media Playback: Load State Unknown
```

which will cause your video to fail to complete. This can break tests that e.g. expect the video to finish.

I have not found a solution to this, but as a workaround you can remove the audio channel from videos. See this StackExchange post for one way to do that: http://unix.stackexchange.com/questions/6402/how-to-remove-an-audio-track-from-an-mp4-video-file