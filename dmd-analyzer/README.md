DMD Analyzer
============

Analyze PIN2DMD dump files (such as can be generated from
https://playfield.dev) an extract game information from them.

Current just a selection of tools.

Motivation for the project is to one day analyze a live stream from a game to
automatically capture statistics, in the spirit of
https://github.com/ferocia/kartalytics.

A test dump file from Demolition Man is provided in `data` to experiment with.

Usage
-----

Inspecting a PIN2DMD dump file. These can be created at https://playfield.dev
by clicking the `DMD DUMP` button in the top right of the UI.

    > bin/inspect-dump data/test-dump-1.raw | head -n 20
    I, [2022-07-31T13:20:08.073870 #29891]  INFO -- : Loading data/test-dump-1.raw
    I, [2022-07-31T13:20:08.578854 #29891]  INFO -- : Loaded data/test-dump-1.raw
    I, [2022-07-31T13:20:08.578930 #29891]  INFO -- : Dimensions: x
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


You can inspect the mask you just created:

    > bin/inspect-mask masks/dm/ball.raw
    Mask:













                  ▄▄▄▄▄▄▄▄▄
                  █████████
                  █████████

    Image:













                  ▄▖ ▄ ▖ ▖
                  ▙▞▐▄▌▌ ▌
                  ▙▞▐ ▌▙▖▙▖

Development
-----------

We have the initial stirrings of a test suite:

    rspec
