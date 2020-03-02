# dynatrace plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

Make sure you have the latest version of the DSS client, which is bundled with the agent. You can download it from here [Latest iOS Agent](https://downloads.dynatrace.com/clientservices/agent?version=latest&techtype=ios).

> Please note that sometimes the latest version of the DSS client may not be compatble with your environment if you have a managed cluster on an older version. In this case, please contact Dynatrace Support to obtain the correct version.

## About the Dynatrace fastlane plugin

This plugin allows you to decode and upload symbolication files to Dynatrace. You can also use it to first download your latest dSYM files from AppStore Connect if you use Bitcode.

## Action: `dynatrace_process_symbols`

| Supported Platforms | ios, android |
|---------------------|--------------|
| Author              | @MANassar    |


## Is your app Bitcode enabled?

> Only applies for apps distributed via the AppStore or TestFlight.


If your app is bitcode enabled, then the dSYMs that are generated during the Xcode build are **_not_** the dSYMs you want to upload to Dynatrace. This is because Apple recompiles your application on their servers, generating new dSYM files in the process. These newly generated dSYM files need to be downloaded from *AppStore Connect*, then processed and uploaded to Dynatrace.

### Important

There is a time gap between the application being uploaded to AppStore Connect and the dSYM files to be ready. So **_you have to introduce some "sleep" or "wait" time in your CI to accomodate for this._** Unfortunately, Apple does not specify how long this time is. But the recommended minimum is 300 seconds (5 minutes). 

### Automatically downloading dSYMs and using AppFile for authentication

#### AppFile

```ruby
app_identifier("com.yourcompany.yourappID") # The bundle identifier of your app
apple_id("user@email.com") # Your Apple email address
```

#### Fastfile

```ruby
dynatrace_process_symbols(
	downloadDsyms: true,
	dtxDssClientPath:"<path>/DTXDssClient",
	appId: "your DT appID",
	apitoken: "your DT API token",
	os: "<ios> or <android>",
	bundleName: "MyApp",
	versionStr: "1.0",
	version: "1",
	server: "<your dynatrace environment URL>",
	debugMode: true)

```

## If you are NOT using Bitcode, or if you have already downloaded your new symbols from AppStore Connect manually.

### Supply all parameters locally

```ruby
dynatrace_process_symbols(
	dtxDssClientPath:"<path>/DTXDssClient",
	appId: "your DT appID",
	apitoken: "your DT API token",
	os: "<ios> or <android>",
	bundleId: "com.yourcompany.yourApp",
	bundleName: "MyApp",
	versionStr: "1.0",
	version: "1",
	symbolsfile: "<path to my app>.app.dSYM",
	server: "<your dynatrace environment URL>",
	debugMode: true)

```

## List of all Parameters

| Key              | Description                                                                                                                                                                                                                           | default value  |
|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------|
| downloadDsyms    | Boolean variable that enables downloading the dSYMs from AppStore Connect (iOS only)                                                                                                                                                  | false          |
| username         | The username or the AppleID to use to download the dSYMs. You can also store this in your AppFile as "apple_id and it will be automatically retrieved."                                                                               |                |
| dtxDssClientPath | The full path to your DTXDssClient.  For example, it could be `./ios/agent/DTXDssClient`                                                                                                                                              | `./DTXDssClient` |
| action           | The action to perform. upload/decode                                                                                                                                                                                                  | `upload`         |
| appID            | The app ID you get from your Dynatrace WebUI                                                                                                                                                                                          |                |
| os               | The OperatingSystem of the symbol files. Either "ios" or "android"                                                                                                                                                                    |                |
| apitoken         | The Dynatrace API token. It should have the correct permissions.                                                                                                                                                                      |                |
| bundleId         | The CFBundlebundleId (iOS) / package (Android) of the Application. Usually in reverse com notation. Ex. com.your_company.your_app. This can also be stored in the AppFile as "app_identifier" and it will be automatically retrieved. |                |
| bundleName       | The CFBundleName of the Application (iOS only)                                                                                                                                                                                        |                |
| versionStr       | The CFBundleShortVersionString (iOS) / versionName (Android                                                                                                                                                                           |                |
| version          | The CFBundleVersion (iOS) / versionCode (Android). This will also be used for dSYM download.                                                                                                                                          |                |
| symbolsfile      | The path to a local symbol files to be processed and uploaded. You do not need to specify that if you use downloadDsyms.                                                                                                              |                |
| server           | The API endpoint for the Dynatrace environment. For example https://environmentID.live.dynatrace.com or https://dynatrace-managed.com/e/environmentID                                                                                                                                                                 |                |
| debugMode        | Debug logging enabled                                                                                                                                                                                                                 | false          |


## Example

Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.


## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository or contact Dynatrace Support.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
