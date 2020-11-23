# Dynatrace Fastlane plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

### Dynatrace Managed
If the installation is on version 1.195 or earlier the Symbolication Client has to be manually download and specified (`dtxDssClientPath`), else it's fetched and updated automatically. A matching version can be downloaded manually with this link [https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz](https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz) by replacing `xyz` with the 3-digit sprint version of your Dynatrace Managed installation.

## About the Dynatrace fastlane plugin
This plugin allows you to decode and upload symbol files (iOS) or just upload obfuscation mapping files (Android) to Dynatrace. You can also use it to first download your latest dSYM files from App Store Connect if you use Bitcode.

## Action: `dynatrace_process_symbols`

| Supported Platforms | ios, android |
|---------------------|--------------|

## Is your app Bitcode enabled?
> Only applies for apps distributed via the AppStore or TestFlight.

If your app is bitcode enabled, then the dSYMs that are generated during the Xcode build are **_not_** the dSYMs you want to upload to Dynatrace. This is because Apple recompiles the application on their servers, generating new dSYM files in the process. These newly generated dSYM files need to be downloaded from *App Store Connect*, then processed and uploaded to Dynatrace.

### Important
There is a time gap between the application being uploaded to App Store Connect and the dSYM files to be ready. So **_we have to introduce some "wait" time in the CI to accomodate for this_**. You can do this by setting the `waitForDsymProcessing` to true. Unfortunately, Apple does not specify how long this time is. We recommend 1800 seconds (30 mins) as this is usually enough for the symbols are ready for download. You can increase this timeout if needed (`waitForDsymProcessingTimeout`). 

> Notice that this timeout is only the **maximum** waiting time. If the symbol files are ready sooner, it will continue processing and will not wait for the whole duration of the timeout.

### Automatically downloading dSYMs and using AppFile for authentication

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
	bundleId: "<CFBundlebundleId (iOS) / package (Android)>",
	versionStr: "<Build Number (CFBundleVersion)>",
	version: "<App Version (CFBundleShortVersionString)>",
	server: "<Dynatrace Environment URL>",
	downloadDsyms: true
)
```


## If you are NOT using Bitcode, or if you have already downloaded your new symbols from App Store Connect manually.

### Supply all parameters locally
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


## Example
Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this repository or contact [Dynatrace Support](https://support.dynatrace.com).

## Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins
For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_
_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
