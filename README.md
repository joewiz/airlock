# Airlock

[![License][license-img]][license-url]
[![GitHub release][release-img]][release-url]
![exist-db CI](https://github.com/joewiz/airlock/workflows/exist-db%20CI/badge.svg)
[![Coverage percentage][coveralls-image]][coveralls-url]

<img src="icon.png" align="left" width="25%"/>

Take snapshots of Airtable bases for offline browsing and transformation

## Requirements

*   [eXist-db](https://exist-db.org) version: `5.3.0-SNAPSHOT` or greater
    
*   [ant](https://ant.apache.org) version: `1.10.7` \(for building from source\)

*   [node](https://nodejs.org) version: `12.x` \(for building from source\)


## Installation

This package is published to [the eXist-db public repository](https://exist-db.org/exist/apps/public-repo). To install it from there:

1.  Open [Dashboard](http://localhost:8080/exist/apps/dashboard/index.html) on your local eXist-db instance, log into Dashboard as an administrator (user `admin` and the password you set for this user; the password may be blank if you did not set one up after installing eXist) and click on `Package Manager`. 

2.  In the `Package Manager` window, click on the `Available` tab, where you will find the package listed. To download and install the package, click on the downward-facing arrow icon in the package description.

> Or, if you prefer to download the package from GitHub Releases, follow these directions:
> 
> 1.  Download the `airlock-3.0.0.xar` file from GitHub [Releases](https://github.com/joewiz/airlock/releases) page.
> 
> 2.  Open [Dashboard](http://localhost:8080/exist/apps/dashboard/index.html) as described above, click on the `Upload` button in the upper left corner, and select the `.xar` file you just downloaded. (For a full offline installation, you will need to download the latest `.xar` release of: [airtable.xq](https://github.com/joewiz/airtable.xq), [Roaster](https://github.com/eeditiones/roaster), and [exist-markdown](https://github.com/eXist-db/exist-markdown) too.)

Having installed Airlock, open <http://localhost:8080/exist/apps/airlock>, log into the app as a user in the `airlock` group (by default, the app creates a user `airlock` with password `airlock`), enter your Airtable personal access token or service access token and associated username, enter a base ID, and take your first snapshot.

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

To run tests locally your app needs to be installed in a running eXist-db instance at the default port `8080` and with the default dba user `admin` with the default empty password.

A quick way to set this up for Docker users is to simply issue:

```bash
docker run -dit -p 8080:8080 existdb/existdb:release
```

After you finished installing the application, you can run the full test suite locally.

### Unit-tests

This app uses [mochajs](https://mochajs.org) as a test-runner. To run both XQuery and Javascript unit-tests, type:

```bash
npm test
```

### Integration-tests

This app uses [cypress](https://www.cypress.io) for integration tests, type:

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
