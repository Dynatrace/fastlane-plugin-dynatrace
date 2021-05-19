# Dynatrace Fastlane plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

⚠️  The way Apple introduced the two-factor authentication interferes with a fully automated workflow. The workaround requires manual interaction. For more information, see **App Store Connect Two-Factor-Authentication** section below for details.

## About the Dynatrace fastlane plugin
The Dynatrace fastlane plugin manages uploading symbol files (iOS) or obfuscation mapping files (Android) to the Dynatrace cluster. Symbol and mapping files are used to make reported stack traces human-readable. The plugin also allows to download the latest dSYM files from App Store Connect, which enables full automation of the mobile app deployment, and the pre-processing of dSYM files, a step that is necessary for the Dynatrace cluster to be able to symbolicate.

The plugin provides a single action `dynatrace_process_symbols`. The configuration depends on whether the app is (A) iOS and Bitcode-enabled or (B) iOS and not Bitcode-enabled or an Android app.

For Bitcode-enabled iOS apps we recommend to let the plugin handle the download of the dSYM files from App Store Connect and upload to Dynatrace.


## Usage
To get started, ask your Dynatrace administrator for an [API token ](https://www.dynatrace.com/support/help/shortlink/api-authentication) with **Mobile symbolication file management** permission . To generate the API token, go to **Integration** > **Dynatrace API**.  The token is used by the authenticate the plugin into Dynatrace and upload the symbol and mapping files.

Add the action `dynatrace_process_symbols` to your Fastfile. You'll find all the configuration options and a default configuration later in the readme.

Now, when you run fastlane, the Dynatrace plugin will manage the symbol files of your app as configured.

### Dynatrace Managed (1.195 and earlier)
For cluster versions 1.195 and earlier, the Dynatrace application 'Symbolication Client' has to be downloaded manually and explicitly specified (`dtxDssClientPath`). For all cluster versions above 1.195 it is fetched and updated automatically. A matching version can be downloaded manually with this link [https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz](https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz) by replacing `xyz` with the 3-digit sprint version of your Dynatrace Managed installation.


## A) Bitcode-enabled iOS apps
This is the right approach if your app is distributed via Apple's App Store or TestFlight and Bitcode-enabled. For all other cases, follow the approach B below.

Background: If your app is Bitcode-enabled, then the dSYMs that are generated during the Xcode build are **not** the dSYMs that need to be uploaded to Dynatrace. Apple recompiles the application on their servers, generating new dSYM files in the process. These newly generated dSYM files need to be downloaded from *App Store Connect*, processed and uploaded to Dynatrace.

### Automatically downloading dSYMs

To fully automate the following five-step workflow, add the snippets below to the respective files and fill in the placeholders. Uploading the app the App Store Connect is a necessary prerequisite and either handled manually or by fastlane directly:

1. Wait until the build is processed
2. Download the resulting dSYM files
3. Process dSYM files into the format that Dynatrace requires
4. Upload processed dSYM files to Dynatrace


#### AppFile
Make sure the following information is present in `AppFile` to authenticate with App Store Connect.

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

#### Waiting time between app upload and dSYM file download
After a completed upload to App Store Connect, there is some waiting time before the dSYM files are ready to be downloaded. The Dynatrace fastlane plugin waits and downloads the symbol files if setting the `waitForDsymProcessing` is true and a waiting period is provided via `waitForDsymProcessingTimeout`. We recommend 1800 seconds (30 mins) as the default waiting time. In our experience, this is sufficiently long for the processing to happen. If this duration is not long enough, you need to increase it. 

> Note: this timeout is the **maximum** waiting time. If the symbol files are ready sooner, the plugin will continue to the download and will not wait for the whole duration of the timeout.


## B) Not Bitcode-enabled iOS apps or Android apps
If at least one of the following conditions is true, you should follow this approach:

* **not** using Bitcode for your iOS app
* already downloaded the new symbol files from App Store Connect manually
* deploy an Android app

#### Fastfile
Use the parameter `symbolsfile` to provide a relative path to the symbols file.

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
When the plugin is used to download symbols from *App Store Connect* automatically (`downloadDsyms: true`),  valid App Store Connect credentials with access to the dSYM files are required. The preferred method of doing so is by setting the `FASTLANE_USER` and `FASTLANE_PASSWORD` environment variables to their respective values.

Apple started enforcing 2-Factor-Authentication for the *App Store Connect* API in February 2021. This [limits the ability to automate the symbol processing](https://github.com/fastlane/fastlane/discussions/17655), because it will most likely involve manual interaction, which is not suitable for CI automation. The only workaround at this point in time is to pre-generate a session and cache it in CI.

### Fastlane Session
The full documentation for this can be found on the [fastlane docs](https://docs.fastlane.tools/best-practices/continuous-integration/#two-step-or-two-factor-auth
) under **spaceauth**.

You can generate a session by running `fastlane spaceauth -u user@email.com` on your machine and copy the output into an environment variable `FASTLANE_SESSION` on the target system (e.g. CI).

> Note: 
> - Session is only valid for the "region" you created it in. If your CI is in a different geographical location, the authentication might fail
> - Generated sessions are valid for up to one month. Apple's API doesn't specify details about that, so it is only noticable by a failing build

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
