# Dynatrace Fastlane plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

## About the Dynatrace fastlane plugin
The Dynatrace fastlane plugin manages pre-processing and uploading of dSYM files (iOS, tvOS) or uploading of obfuscation mapping files (Android) to the Dynatrace cluster. Symbol and mapping files are used to make reported stack traces human-readable.

The plugin provides a single action `dynatrace_process_symbols`. The configuration depends on whether the app is an iOS/tvOS or an Android app.

## Usage
To get started, ask your Dynatrace administrator for an [API token ](https://www.dynatrace.com/support/help/shortlink/api-authentication) with **Mobile symbolication file management** permission . To generate the API token, go to **Integration** > **Dynatrace API**. The token is used by the authenticate the plugin into Dynatrace and upload the symbol and mapping files.

Add the action `dynatrace_process_symbols` to your Fastfile. You'll find all the configuration options and a default configuration below. Use the parameter `symbolsfile` to provide a relative path to the symbols file (dSYM or Android mapping).

```ruby
dynatrace_process_symbols(
	appId: "<Dynatrace application ID>",
	apitoken: "<Dynatrace API Token>",
	os: "<ios>, <tvos> or <android>",
	bundleId: "<CFBundlebundleId (iOS, tvOS) / package (Android)>",
	versionStr: "<CFBundleShortVersionString (iOS, tvOS) / versionName (Android)>",
	version: "<CFBundleVersion (iOS, tvOS) / versionCode (Android)>",
	server: "<Dynatrace Environment URL>",
	symbolsfile: "<Symbols File Path>"
)
```

Now, when you run fastlane, the Dynatrace plugin will manage the symbol files of your app as configured.


## List of all Parameters
| Key                     | Description                                                                                                                                                                                                                     | default value |
|-------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| action                  | *(iOS/tvOS only)* Action to be performed by DTXDssClient (`upload` or `decode`).                                                                                                                                                | `upload`      |
| username                | *(iOS/tvOS only)* The username/AppleID to use to download the dSYMs. Alternatively you can specify this in your AppFile as `apple_id`.                                                                                          |               |
| os                      | The type of the symbol files, either `ios`, `tvOS` or `android`.                                                                                                                                                                |               |
| apitoken                | Dynatrace API token with mobile symbolication permissions.                                                                                                                                                                      |               |
| appID                   | The application ID you get from your Dynatrace environment.                                                                                                                                                                     |               |
| bundleId                | The CFBundlebundleId (iOS, tvOS) / package (Android) of the application. Alternatively you can specify this in your AppFile as `app_identifier`.                                                                                |               |
| versionStr              | The CFBundleShortVersionString (iOS, tvOS) / versionName (Android)                                                                                                                                                              |               |
| version                 | The CFBundleVersion (iOS, tvOS) / versionCode (Android). Is also used for the dSYM download.                                                                                                                                    |               |
| symbolsfile             | Path to the dSYM or Android mapping file to be processed. *(Android only)*: If the file exceeds 10MiB and doesn't end with `*.zip` it's zipped before uploading. This can be disabled by setting `symbolsfileAutoZip` to false. |               |
| symbolsfileAutoZip      | *(Android only)* Automatically zip symbolsfile if it exceeds 10MiB and doesn't already end with `*.zip`.                                                                                                                        | `true`        |
| server                  | The API endpoint for the Dynatrace environment (e.g. `https://environmentID.live.dynatrace.com` or `https://dynatrace-managed.com/e/environmentID`).                                                                            |               |
| cleanBuildArtifacts     | Clean build artifacts after processing.                                                                                                                                                                                         | `false`       |
| tempdir                 | (OPTIONAL) Custom temporary directory for the DTXDssClient. **The plugin does not take care of cleaning this directory.**                                                                                                       |               |
| debugMode               | Enable debug logging.                                                                                                                                                                                                           | `false`       |
| customLLDBFrameworkPath | (OPTIONAL) Custom path to the LLDB framework used as runtime dependency by DTXDssClient (e.g. `/Users/test/Documents/LLDB.framework`).                                                                                          |               |
| autoSymlinkLLDB         | (OPTIONAL) Automatically find and create a symlink to the LLDB framework into the DTXDssClient's temporary folder.                                                                                                              | `true`        |

## Example
Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

## Tests
This plugin includes a set of RSpec unit tests, which can be executed by running `bundle exec rspec spec`.

## Issues and Feedback
For any other issues and feedback about this plugin, please submit it to this repository or contact [Dynatrace Support](https://support.dynatrace.com).

## Troubleshooting
If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins
For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_
_fastlane_ is the easiest way to automate beta deployments and releases for your iOS, tvOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
