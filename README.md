# Dynatrace Fastlane plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

⚠️  Apple enabled two-factor authentication in a way which interferes with a fully automated workflow. The workaround requires manual interaction see section 'App Store Connect Two-Factor-Authentication' below for details.

### Dynatrace Managed (1.195 and earlier)
For cluster versions 1.195 and earlier the Symbolication Client has to be manually download and specified (`dtxDssClientPath`). For all cluster versions above 1.195 it is fetched and updated automatically. A matching version can be downloaded manually with this link [https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz](https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz) by replacing `xyz` with the 3-digit sprint version of your Dynatrace Managed installation.

## About the Dynatrace fastlane plugin
The Dynatrace fastlane plugin manages uploading symbol files (iOS) or obfuscation mapping files (Android) to Dynatrace. Symbol and mapping files are used to make reported stack traces human-readable. The plugin also allows you to download the latest dSYM files from App Store Connect, which enables full automation of the mobile app deployment.

The plugin provides a single action `dynatrace_process_symbols`. The configuration depends on whether the app is (A) iOS and Bitcode-enabled or (B) iOS and not Bitcode-enabled or an Android app.

For Bitcode-enabled iOS apps we recommend to let the plugin handle upload of the app to App Store Connect and download of the dSYM files


## Usage
To get started, first, ask your Dynatrace administrator to generate an API token. The token needs the permission 'Mobile symbolication file management' and is used to obtain permission to upload the symbol and mapping files to Dynatrace.

Then add the action `dynatrace_process_symbols` to your Fastfile, see below for all configuration options.

When you now run fastlane, the Dynatrace plugin will manage the symbol files of your app as configured.

## Action: `dynatrace_process_symbols`

| Supported Platforms | ios, android |
|---------------------|--------------|

## (A) Bitcode-enabled iOS apps
> Only applies for apps distributed via the AppStore or TestFlight.

If your app is bitcode enabled, then the dSYMs that are generated during the Xcode build are **_not_** the dSYMs you want to upload to Dynatrace. This is because Apple recompiles the application on their servers, generating new dSYM files in the process. These newly generated dSYM files need to be downloaded from *App Store Connect*, then processed and uploaded to Dynatrace.

### Automatically downloading dSYMs

Make sure the following information is present in `AppFile` to allow authentication with App Store Connect.

#### AppFile
```ruby
app_identifier("com.yourcompany.yourappID") # bundle identifier of your app
apple_id("user@email.com")
```

#### Fastfile
```ruby
dynatrace_process_symbols(
	appId: "<Dynatrace application ID>",
	apitoken: "<Dynatrace API token>",
	os: "ios",
	bundleId: "<CFBundlebundleId>",
	versionStr: "<Build Number (CFBundleVersion)>",
	version: "<App Version (CFBundleShortVersionString)>",
	server: "<Dynatrace Environment URL>",
	downloadDsyms: true
)
```

### Waiting time between app upload and dSYM file download
There is a waiting time after the application has finished uploading to App Store Connect until the dSYM files are ready to be downloaded. The Dynatrace fastlane plugin waits and downloads the symbol files if setting the `waitForDsymProcessing` is true and a waiting period is provided via `waitForDsymProcessingTimeout`. We recommend 1800 seconds (30 mins) as the default waiting time. In our exprience this is sufficiently long for the processing to happen. If this duration is not long enough it needs to be increased. 

> Note: this timeout is the **maximum** waiting time. If the symbol files are ready sooner, the plugin will continue to the download and will not wait for the whole duration of the timeout.


## Not Bitcode-enabled iOS apps or Android apps
If you are NOT using Bitcode, or if you have already downloaded the new symbol files from App Store Connect manually, do use the parameter `symbolsfile` to provide a relative path to the symbols file. The parameter `downloadDsyms` must be _false_ or removed.

#### Fastfile
```ruby
dynatrace_process_symbols(
	appId: "<Dynatrace application ID>",
	apitoken: "<Dynatrace API Token>",
	os: "<ios> or <android>",
	bundleId: "<CFBundlebundleId (iOS) / package (Android)>",
	versionStr: "<CFBundleShortVersionString (iOS) / versionName (Android)>",
	version: "<CFBundleVersion (iOS) / versionCode (Android)>",
	server: "<Dynatrace Environment URL>",
	symbolsfile: "<Symbols File Path>"
)
```

## List of all Parameters
| Key                          | Description                                                                                                                                                           | default value  |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| action                       | *(iOS only)* Action to be performed by DTXDssClient (`upload` or `decode`).                                                                                           | `upload`       |
| downloadDsyms                | *(iOS only)* Download the dSYMs from App Store Connect.                                                                                                               | `false`        |
| waitForDsymProcessing        | *(iOS only)* Wait for dSYM processing to be finished.                                                                                                                  | `true`         |
| waitForDsymProcessingTimeout | *(iOS only)* Timeout in seconds to wait for the dSYMs be downloadable.                                                                                                | `1800`         |
| username                     | *(iOS only)* The username/AppleID to use to download the dSYMs. Alternatively you can specify this in your AppFile as `apple_id`.                                     |                |
| os                           | The type of the symbol files, either `ios` or `android`.                                                                                                              |                |
| apitoken                     | Dynatrace API token with mobile symbolication permissions.                                                                                                            |                |
| dtxDssClientPath             | **(DEPRECATED)** The path to your DTXDssClient. The DTXDssClient is downloaded and updated automatically, unless this key is set.                                     |                |
| appID                        | The application ID you get from your Dynatrace environment.                                                                                                           |                |
| bundleId                     | The CFBundlebundleId (iOS) / package (Android) of the application. Alternatively you can specify this in your AppFile as `app_identifier`.                            |                |
| versionStr                   | The CFBundleShortVersionString (iOS) / versionName (Android)                                                                                                          |                |
| version                      | The CFBundleVersion (iOS) / versionCode (Android). Is also used for the dSYM download.                                                                                |                |
| symbolsfile                  | Path to the dSYM file to be processed. If downloadDsyms is set, this is only a fallback.                                                                              |                |
| server                       | The API endpoint for the Dynatrace environment (e.g. `https://environmentID.live.dynatrace.com` or `https://dynatrace-managed.com/e/environmentID`).                  |                |
| debugMode                    | Enable debug logging.                                                                                                                                                 | false          |

## App Store Connect Two-Factor-Authentication
When the plugin is used to download symbols from *App Store Connect* automatically (`downloadDsyms: true`)  valid login credentials to an account with permissions to access the dSYM files are required. The preferred method of doing so is by setting the `FASTLANE_USER` and `FASTLANE_PASSWORD` environment variables to their respective values.

[Apple announced](https://github.com/fastlane/fastlane/discussions/17655) that 2-Factor-Authentication for the *App Store Connect* API will be enforced starting February 2021. This limits the ability to automate the symbol processing, because it will most likely involve manual interaction, which is not suitable for CI automation. The only workaround at this point in time is to pre-generate a session and cache it in CI.

### Fastlane Session
The full documentation for this can be found on the [fastlane docs](https://docs.fastlane.tools/best-practices/continuous-integration/#two-step-or-two-factor-auth
) under **spaceauth**.

You can generate a session by running `fastlane spaceauth -u user@email.com` on your machine and copy the output into an environment variable `FASTLANE_SESSION` on the target system (e.g. CI).

### NOTE
- Session is only valid in the "region" you create it. If you CI is in a different geographical location the authentication might fail.

- Generated sessions are valid up to one month. Apple's API doesn't specify details about that, so it will only be visible by a failing build.

## Example
Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## Tests
This plugin includes a set of RSpec unit tests, which can be executed by running ` bundle exec rspec spec`.

## Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this repository or contact [Dynatrace Support](https://support.dynatrace.com).

## Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins
For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_
_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
