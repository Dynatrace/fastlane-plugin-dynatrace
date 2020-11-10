# Dynatrace Fastlane plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-dynatrace)

> :information_source: We changed the default branch's name to `main`.  
The necessary steps to update your local clone are described by Scott Hanselman on his [Blog](https://www.hanselman.com/blog/EasilyRenameYourGitDefaultBranchFromMasterToMain.aspx)
We encourage you to rename your default branch in your forks too.

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-dynatrace`, add it to your project by running:

```bash
fastlane add_plugin dynatrace
```

### Dynatrace Managed
If the installation is on version 1.195 or earlier the Symbolication Client has to be manually download and specified (`dtxDssClientPath`), else it's fetched and updated automatically. A matching version can be downloaded manually with this link [https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz](https://api.mobileagent.downloads.dynatrace.com/sprint-latest-dss-client/xyz) by replacing `xyz` with the 3-digit sprint version of your Dynatrace Managed installation.

## About the Dynatrace fastlane plugin

This plugin allows you to decode and upload symbol files (iOS) or just upload obfuscation mapping files (Android) to Dynatrace. You can also use it to first download your latest dSYM files from AppStore Connect if you use Bitcode.

## Action: `dynatrace_process_symbols`

| Supported Platforms | ios, android |
|---------------------|--------------|

## Is your app Bitcode enabled?

> Only applies for apps distributed via the AppStore or TestFlight.

If your app is bitcode enabled, then the dSYMs that are generated during the Xcode build are **_not_** the dSYMs you want to upload to Dynatrace. This is because Apple recompiles the application on their servers, generating new dSYM files in the process. These newly generated dSYM files need to be downloaded from *AppStore Connect*, then processed and uploaded to Dynatrace.

### Important

There is a time gap between the application being uploaded to AppStore Connect and the dSYM files to be ready. So **_you have to introduce some "wait" time in your CI to accomodate for this._** Unfortunately, Apple does not specify how long this time is. But the minimum is 600 seconds (10 minutes). However, we recommend 1800 seconds (30 mins) as this ensures the symbols are ready for download. You can however increase this timeout if needed. 

> Notice that this timeout is only the maximum waiting time. If the symbol files are processed and are ready sooner, it will execute sooner and will not wait for the whole duration of the timeout.

### Automatically downloading dSYMs and using AppFile for authentication

#### AppFile

```ruby
app_identifier("com.yourcompany.yourappID") # The bundle identifier of your app
apple_id("user@email.com") # Your Apple email address
```

#### Fastfile

```ruby

lane :downloadAndProcessBitcodeSymbols do
		
	# Define variables
	version = <the version on AppStoreConnect (CFBundleShortVersionString)>
	build = <your uploaded build number (CFBundleVersion)>
	symbols_wait_timeout = 1800

	# Get Bitcode dsyms from AppStoreConnect and store locally
	download_dsyms(
		wait_for_dsym_processing: true,
		wait_timeout: symbols_wait_timeout,
		app_identifier: "<your application bundle id (CFBundleIdentifier)>",
		version: version,
		build_number: build
	)

	#Pass the dsyms to Dynatrace for processing
	dynatrace_process_symbols(
		symbolsfile: lane_context[SharedValues::DSYM_PATHS][0],
		appId: "<your Dynatrace application ID>",
		apitoken: "<your Dynatrace API token>",
		os: "ios",
		versionStr: build,
		version: version,
		server: "<your dynatrace environment URL>",
	)
end

```


## If you are NOT using Bitcode, or if you have already downloaded your new symbols from AppStore Connect manually.

### Supply all parameters locally

```ruby
dynatrace_process_symbols(
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
| username         | The username or the AppleID to use to download the dSYMs. You can also store this in your AppFile as "apple_id and it will be automatically retrieved."                                                                               |                |
| dtxDssClientPath | **DEPRECATED** The full path to your DTXDssClient. For example, it could be `./ios/agent/DTXDssClient`. The DTXDssClient is downloaded and updated automatically, unless this key is set.                                                                                                                                          |  |
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

For any other issues and feedback about this plugin, please submit it to this repository or contact [Dynatrace Support](https://support.dynatrace.com).

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
