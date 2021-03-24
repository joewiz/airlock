# airlock

[![License][license-img]][license-url]
[![GitHub release][release-img]][release-url]
![exist-db CI](https://github.com/joewiz/airlock/workflows/exist-db%20CI/badge.svg)
[![Coverage percentage][coveralls-image]][coveralls-url]

<img src="icon.png" align="left" width="25%"/>

Take snapshots of Airtable bases for offline browsing and transformation

## Requirements

*   [exist-db](http://exist-db.org/exist/apps/homepage/index.html) version: `5.3.0-SNAPSHOT` or greater

*   [ant](http://ant.apache.org) version: `1.10.7` \(for building from source\)

*   [node](http://nodejs.org) version: `12.x` \(for building from source\)

*   [airtable.xq](https://github.com/joewiz/airtable.xq) version: `1.0.1` or greater \(for building from source\)
    

## Installation

1.  Download  the `airlock-2.0.2.xar` file from GitHub [releases](https://github.com/joewiz/airlock/releases) page.

2.  Open the [dashboard](http://localhost:8080/exist/apps/dashboard/index.html) of your eXist-db instance and click on `Package Manager`.

    1.  Click on the `add package` symbol in the upper left corner and select the `.xar` file you just downloaded.

3.  You have successfully installed airlock into exist.

4.  Load <http://localhost:8080/exist/apps/airlock> and create your first snapshot.

### Building from source

1.  Download, fork or clone this GitHub repository
2.  There are two default build targets in `build.xml`:
    *   `dev` including *all* files from the source folder including those with potentially sensitive information.
  
    *   `deploy` is the official release. It excludes files necessary for development but that have no effect upon deployment.
  
3.  Calling `ant`in your CLI will build both files:
  
```bash
cd airlock
ant
```

   1. to only build a specific target call either `dev` or `deploy` like this:
   ```bash   
   ant dev
   ```   

If you see `BUILD SUCCESSFUL` ant has generated a `airlock-*.xar` file in the `build/` folder. To install it, follow the instructions [above](#installation).



## Running Tests

To run tests locally your app needs to be installed in a running exist-db instance at the default port `8080` and with the default dba user `admin` with the default empty password.

A quick way to set this up for docker users is to simply issue:

```bash
docker run -dit -p 8080:8080 existdb/existdb:release
```

After you finished installing the application, you can run the full testsuite locally.

### Unit-tests

This app uses [mochajs](https://mochajs.org) as a test-runner. To run both xquery and javascript unit-tests type:

```bash
npm test
```

### Integration-tests

This app uses [cypress](https://www.cypress.io) for integration tests, just type:

```bash
npm run cypress
```

Alternatively, use npx:

```bash
npx cypress open
```


## Contributing

You can take a look at the [Contribution guidelines for this project](.github/CONTRIBUTING.md)

## License

AGPL-3.0 © [Joe Wicentowski](https://joewiz.org)

[license-img]: https://img.shields.io/badge/license-AGPL%20v3-blue.svg
[license-url]: https://www.gnu.org/licenses/agpl-3.0
[release-img]: https://img.shields.io/github/v/release/joewiz/airlock
[release-url]: https://github.com/joewiz/airlock/releases/latest
[coveralls-image]: https://coveralls.io/repos/joewiz/airlock/badge.svg
[coveralls-url]: https://coveralls.io/r/joewiz/airlock
