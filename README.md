# SmogWatch

This is an app I'm building for my blog post series "[WatchKit Adventure](https://mackuba.eu/2018/10/29/watchkit-adventure-0-intro/)". Its goal is to display the level of PM10 smog pollution (fetched from a local monitoring station) on the Apple Watch's watch face. Initially it only works for a single preset station in Kraków, Poland.

The second goal is for me to learn programming for watchOS and also get some experience that I can share in the blog posts :)


## Installation & Running

If you want to try out the app, clone the repo (or download a zip) and open it in Xcode. There are currently no external dependencies, so just build the project.

Running a watch app in the simulator is about 100x easier than getting an actual device to cooperate, so try that first. Then, to run on the real watch, you will probably need to edit at least the developer team and the app ID. If you manage to run it, let me know what else you needed to do :)

The app currently uses http://monitoring.krakow.pios.gov.pl for the data and has a hardcoded ID of PM10 parameter on the Kurdwanów station. If you want a different station (as long as it's from the Małopolska monitoring system) then open the site in the browser, select only PM10 parameter only on one selected station, load the data and check in the web inspector what parameter was sent in the request. [The query in KrakowPiosDataLoader.swift](https://github.com/mackuba/SmogWatch/blob/master/SmogWatch%20WatchKit%20Extension/KrakowPiosDataLoader.swift#L70) is the place you need to update.

Yup, it's all very very rough right now - did I ever say this was a finished app? It's basically version 0.0.1 :)

It's possible that there are other regional monitoring systems in Poland that use the same API, so let me know if you find one.


## Complications

The part that's working so far is complications. Not all families are supported, currently Modular Small works best since that's what I primarily use (on Modular or Siri watch faces). If you really want to use a different complication that isn't supported yet, look in [ComplicationHandler.swift](https://github.com/mackuba/SmogWatch/blob/master/SmogWatch%20WatchKit%20Extension/ComplicationHandler.swift), and also enable the complication family in the target settings.


## Main UI

The app itself has currently no UI whatsoever, so if you see a black screen, don't worry, it's not broken. First things first, you know...


## Credits

Copyright © 2019 [Kuba Suder](https://mackuba.eu). Licensed under [WTFPL License](http://www.wtfpl.net).

I've made the code available under WTFPL because the whole idea is for other people to be able to learn this stuff together with me and reuse any pieces they need from my app to build their own. So take what you need and build cool shit, and don't worry about licences. Of course if you want to mention me somewhere, I'll be very happy :)
