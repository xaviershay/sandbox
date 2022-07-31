DMD Analyzer
============

Analyze PIN2DMD dump files (such as can be generated from
https://playfield.dev) and extract game information from them.

Currently just an assorted selection of tools that don't do much, but it can
extract single player scores from Demolition Man which is pretty neat.

Motivation for the project is to one day analyze a live stream from a game to
automatically capture statistics, in the spirit of
https://github.com/ferocia/kartalytics.

A test dump file from Demolition Man is provided in `data` to experiment with.

Usage
-----

### Inspect PIN2DMD Dump

These can be created at https://playfield.dev by clicking the `DMD DUMP` button
in the top right of the UI.

    > bin/inspect-dump data/test-dump-1.raw | head -n 20
    I, [2022-07-31T13:20:08.073870 #29891]  INFO -- : Loading data/test-dump-1.raw
    I, [2022-07-31T13:20:08.578854 #29891]  INFO -- : Loaded data/test-dump-1.raw
    I, [2022-07-31T13:20:08.578941 #29891]  INFO -- : Frames: 437
    I, [2022-07-31T13:20:08.613364 #29891]  INFO -- : Frame 0, timestamp 2294275:
              ▄▄
           ▗▟████▙     ▟          ▗▄   ▄▖
          ▗█▛▀  ▜█▌   ▟▛         ▗█▛  ▟█▘
         ▗█▛ ▐▖ ▐█▙  ▟█▌  ▄ ▄    ██▘ ▐█▛  ▄
         █▛  ▟▌ ▟██ ▗██  ▟▛▐█▌  ▐█▛  ██▘ ▐█▌
        ▐█   █▌ ██▌▗██▌ ▟▛ ▝█▘ ▗██▘ ▟█▛  ▝█▘
     ▗  █▌  ▐█▘▐██▚███▘▟▛      ▟█▛ ▗██▘
    ▗█▘ █  ▗██ ███████▟█▘     ▐██  ██▌
    █▌  █▖▗██▘▐████████▘▗▟█▌ ▗██▌ ▟██  ▄██  ▗▟██▄██ ▗▟█▖ ▟█▖ ▄█▙   ▟
    █▌  ▝██▛▘ ███▛▐███▛▗███▘ ▟██ ▗██▌ ▟██▛ ▗██▘▐██▌▗███▙████▟███▌ ▟█
    ▐█       ▟██▛ ████ ▟██▛ ▟██▌▗██▛ ▐███ ▗██▛ ▐██ █▛▟██▛▐███▚██▘▟█▘
    ▟█▖     ▗██▛  ███▌▐███ ▟███▗███▘▗███▌▗███  ██▌▟█▐███ ███▘██▛▗█▘
    ███▌   ▗██▛   ███  ██▌▟███▙███▛▗████▗███▌ ▟██▗█▘███▘▐██▘▐██▘▟█▙▗
    ██▛   ▗██▘    ██▌  ████▘███▛▝███▛▐███▘██ ▟██▙█▘▐██▘ ██▛ ▐██▟▛▜▛▟
    █▛   ▗█▀      ▝█   ▝█▛▘ ▝█▛  ▜█▛  ▜▛▘ ▝██▘▝█▛▘ ██▛ ▐█▛   ▜█▀ ▝██


### Create Mask

A mask can be created to identify frames of a particular type, for further
analysis later.

    > bin/create-mask \
      -i data/test-dump-1.raw \
      -o masks/dm/ball.raw \
      --frame 399 \
      --mask 28,27,18,5 \
      -v
    I, [2022-07-31T13:21:11.747669 #29954]  INFO -- : Loading data/test-dump-1.raw
    I, [2022-07-31T13:21:12.247765 #29954]  INFO -- : Loaded data/test-dump-1.raw
    I, [2022-07-31T13:21:12.276365 #29954]  INFO -- : Extracted frame 399:


                      ▗████  ▄██  ▟████▖ ▟████▖ ▄██  ▟████▖
                      █████  ███  █████▌ █████▌ ███  █████▌
                      ██▘     ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▄▄▖   ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      █████▖  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▀▜█▌  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██ ▐█▌  ██  ██ ▐█▌ ██ ▐█▌  ██  ██ ▐█▌
                      ██▄▟█▌▗▄██▄▖██▄▟█▌ ██▄▟█▌▗▄██▄▖██▄▟█▌
                      ▜████▘▐████▌█████▌▖█████▌▐████▌█████▌
                       ▀▀▀▘ ▝▀▀▀▀▘▝▀▀▀▀▗▘▝▀▀▀▀ ▝▀▀▀▀▘▝▀▀▀▀

                  ▄▖ ▄ ▖ ▖   ▗          ▄▄▗▄ ▄▄▗▄▖ ▗▄ ▖ ▗▖▗ ▗
                  ▙▞▐▄▌▌ ▌   ▜          ▙▖▐▄▘▙▖▐▄  ▐▄▘▌ ▙▟ ▚▘
                  ▙▞▐ ▌▙▖▙▖  ▟▖         ▌ ▐ ▌▙▄▐▄▖ ▐  ▙▖▌▐ ▐ ▗
    I, [2022-07-31T13:21:12.307175 #29954]  INFO -- : Mask [28, 27, 18, 5]:













                  ▄▄▄▄▄▄▄▄▄
                  █████████
                  █████████
    I, [2022-07-31T13:21:12.337726 #29954]  INFO -- : Masked image:













                  ▄▖ ▄ ▖ ▖
                  ▙▞▐▄▌▌ ▌
                  ▙▞▐ ▌▙▖▙▖


### Inspect mask

    > bin/inspect-mask masks/dm/ball.raw
    I, [2022-07-31T15:48:17.456906 #40472]  INFO -- : Mask:
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                  ▄▄▄▄▄▄▄▄▄                                         
                  █████████                                         
                  █████████                                         
    I, [2022-07-31T15:48:17.484671 #40472]  INFO -- : Image:
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                                                                    
                  ▄▖ ▄ ▖ ▖                                          
                  ▙▞▐▄▌▌ ▌                                          
                  ▙▞▐ ▌▙▖▙▖                                         

### Generate digit templates

Need to repeat this for all digits, finding appropriate frames.

    > bin/extract-dm-digit-templates \
        -i data/dm-all-digits.raw \
        -o masks/dm \
        --frame 70 \
        --score 1,300,000 \
        -v

### Extract scores from a dump

    > bin/extract-dm-scores data/dm-all-digits.raw
    I, [2022-07-31T15:42:58.514501 #39806]  INFO -- : Loading data/dm-all-digits.raw
    I, [2022-07-31T15:42:58.755891 #39806]  INFO -- : Loaded data/dm-all-digits.raw
    I, [2022-07-31T15:42:58.755930 #39806]  INFO -- : Frames: 195
    I, [2022-07-31T15:42:58.867055 #39806]  INFO -- : Extracted new score 0/5.418243: 1000000
    I, [2022-07-31T15:43:00.746469 #39806]  INFO -- : Extracted new score 18/5.64864: 1100000
    I, [2022-07-31T15:43:02.753638 #39806]  INFO -- : Extracted new score 40/5.89952: 1200000
    I, [2022-07-31T15:43:04.449306 #39806]  INFO -- : Extracted new score 59/6.1248: 1300000
    I, [2022-07-31T15:43:05.900162 #39806]  INFO -- : Extracted new score 74/6.3296: 1400000
    I, [2022-07-31T15:43:07.571794 #39806]  INFO -- : Extracted new score 90/6.52928: 1500000
    I, [2022-07-31T15:43:09.381414 #39806]  INFO -- : Extracted new score 107/6.734336: 1600000
    I, [2022-07-31T15:43:11.271907 #39806]  INFO -- : Extracted new score 125/6.959616: 1700000
    I, [2022-07-31T15:43:12.964140 #39806]  INFO -- : Extracted new score 141/7.159296: 1800000
    I, [2022-07-31T15:43:14.852314 #39806]  INFO -- : Extracted new score 159/7.384576: 1900000

Development
-----------

We have the initial stirrings of a test suite.

    rspec
