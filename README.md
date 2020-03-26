# AllTube Cloudron App

This repository contains the Cloudron app package source for [AllTube](https://alltubedownload.net/).

## Installation

[![Install](https://cloudron.io/img/button.svg)](https://cloudron.io/button.html?app=net.alltubedownload.cloudronapp)

or using the [Cloudron command line tooling](https://cloudron.io/references/cli.html)

```
cloudron install --appstore-id net.alltubedownload.cloudronapp
```

## Building

The app package can be built using the [Cloudron command line tooling](https://cloudron.io/references/cli.html).

```
cd alltube-app
cloudron build
cloudron install
```

## Testing

The e2e tests are located in the `test/` folder and require [nodejs](http://nodejs.org/). They are creating a fresh build, install the app on your Cloudron, verify auth, upload a file, backup, restore and verify the file still being present.

```
cd alltube-app/test

npm install
USERNAME=<cloudron username> PASSWORD=<cloudron password> mocha test.js
```



