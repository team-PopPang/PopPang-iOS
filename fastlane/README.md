fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the modular PopPang app

### ios test

```sh
[bundle exec] fastlane ios test
```

Run the maintained modular test schemes

### ios ci

```sh
[bundle exec] fastlane ios ci
```

Build PopPangApp and run Core/Data tests

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Archive and upload the modular app to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Release a new modular app version to the App Store

### ios release_status

```sh
[bundle exec] fastlane ios release_status
```

Compare the App Store versions with the project version without changing anything

### ios download_store_metadata

```sh
[bundle exec] fastlane ios download_store_metadata
```

Download App Store metadata, and screenshots with screenshots:true, without changing App Store Connect

### ios upload_store_metadata

```sh
[bundle exec] fastlane ios upload_store_metadata
```

Upload the edited App Store metadata without uploading a build or submitting for review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
