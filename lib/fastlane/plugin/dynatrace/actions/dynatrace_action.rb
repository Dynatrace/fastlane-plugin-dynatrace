require 'fastlane/action'
require 'net/http'
require 'open-uri'
require 'zip'
require 'fileutils'
require 'os'
require 'json'
require_relative '../helper/dynatrace_helper'

module Fastlane
  module Actions
    class DynatraceProcessSymbolsAction < Action

      def self.run(params)
        UI.message "Parameter API Token: #{params[:apitoken]}"
        UI.message "OS: #{params[:os]}"
        UI.message "Version string: #{params[:versionStr]}"
        UI.message "Version: #{params[:version]}"
        UI.message "Server URL: #{params[:server]}"
        UI.message "Tempdir: #{params[:tempdir]}"
        UI.message "Symbols file path: #{params[:symbolsfile]}"

        UI.message "Checking AppFile for possible AppID"
        bundleId = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
        if bundleId
          UI.message "Using #{bundleId} from your AppFile"
        else
          bundleId = params[:bundleId]
          UI.message "BundleID: #{bundleId}"
        end

        if params[:os] == "android"
          symbols_path = Helper::DynatraceHelper.zip_if_required(params)
          response, request = Helper::DynatraceHelper.put_android_symbols(params, bundleId, symbols_path)
          case response.code
            when '204'
              UI.success "Success. The file has been uploaded and stored."
            when '400'
              UI.user_error! "Failed. The input is invalid."
            when '401'
              UI.user_error! "Invalid Dynatrace API token. See https://www.dynatrace.com/support/help/dynatrace-api/basics/dynatrace-api-authentication/#token-permissions and https://www.dynatrace.com/support/help/dynatrace-api/configuration-api/mobile-symbolication-api/"
            when '413'
              UI.user_error! "Failed. The symbol file storage quota is exhausted. See https://www.dynatrace.com/support/help/shortlink/mobile-symbolication#manage-the-uploaded-symbol-files for more information."
            else
              message = nil
              unless response.body.nil?
                message = JSON.parse(response.body)["error"]["message"]
              end
              if message.nil?
                UI.user_error! "Symbol upload error (Response Code: #{response.code}). Please try again in a few minutes or contact the Dynatrace support (https://www.dynatrace.com/services-support/)." 
              else
                UI.user_error! "Symbol upload error (Response Code: #{response.code}). #{message}" 
              end
          end
          return
        elsif params[:os] != "ios" && params[:os] != "tvos"
          UI.user_error! "Unsopported value os=#{params[:os]}"
        end

        # iOS/tvOS workflow
        dtxDssClientPath = Helper::DynatraceHelper.get_dss_client(params)

        if !OS.mac?
          UI.user_error! "A macOS machine is required to process iOS symbols."
        end

        # start constructing the command that will trigger the DTXDssClient
        command = []
        command << "#{dtxDssClientPath}"
        command << "-#{params[:action]}"  #"-upload"
        command << "appid=\"#{params[:appId]}\""
        command << "apitoken=\"#{params[:apitoken]}\""
        command << "os=#{params[:os]}"
        command << "bundleId=\"#{bundleId}\""
        command << "versionStr=\"#{params[:versionStr]}\""
        command << "version=\"#{params[:version]}\""
        command << "symbolsfile=\"#{params[:symbolsfile]}\""
        command << "server=\"#{Helper::DynatraceHelper.without_trailing_slash(params[:server])}\""
        command << "DTXLogLevel=ALL -verbose" if params[:debugMode] == true
        command << "forced=1" # if the file already exists
        command << "tempdir=\"#{params[:tempdir]}\"" if params[:tempdir]

        # Create the full shell command to trigger the DTXDssClient
        shell_command = command.join(' ')

        UI.message "#{shell_command}"

        sh("#{shell_command}", error_callback: ->(result) {
          # ShAction doesn't return any reference to the return value -> parse it from the output
          result_groups = result.match /(?:ERROR: Execution failed, rc=)(-?\d*)(?:\sreason=)(.*)/
          if result_groups and result_groups.length() >= 2
            if result_groups[1] == "413" 
              UI.user_error!("DTXDssClient: #{result_groups[2]} See https://www.dynatrace.com/support/help/shortlink/mobile-symbolication#manage-the-uploaded-symbol-files for more information.")
            else
              UI.user_error!("DTXDssClient: #{result_groups[2]}")
            end
          else
            UI.user_error!("DTXDssClient finished with errors.")
          end
        })

        if params[:cleanBuildArtifacts]
          UI.message "Cleaning build artifacts"
          Fastlane::Actions::CleanBuildArtifactsAction.run(exclude_pattern: nil)
        end
      end

      def self.description
        "This action processes and uploads your symbol files to Dynatrace."
      end

      def self.details
        "This action allows you to process and upload symbol files to Dynatrace. If you use Bitcode you can also use it to download the latest dSYM files from App Store Connect."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :action,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_ACTION",
                                       description: "(iOS only) Action to be performed by DTXDssClient (\"upload\" or \"decode\")",
                                       default_value: "upload",
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("Action needs to either be \"upload\" or \"decode\"") unless (value and value == "upload" or value == "decode")
                                       end),

          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS_USERNAME",
                                       description: "(iOS only) The username/AppleID to use to download the dSYMs"),

          FastlaneCore::ConfigItem.new(key: :os,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_OS",
                                       description: "The type of the symbol files, either \"ios\", \"tvos\" or \"android\"",
                                       sensitive: false,
                                       optional: false,
                                       verify_block: proc do |value|
                                          UI.user_error!("Please specify the type of the symbol files. Possible values are \"ios\", \"tvos\" or \"android\".") unless (value and not value.empty? and (value == "ios" || value == "tvos" || value =="android"))
                                       end),

          FastlaneCore::ConfigItem.new(key: :apitoken,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_APITOKEN",
                                       description: "Dynatrace API token with mobile symbolication permissions",
                                       verify_block: proc do |value|
                                          UI.user_error!("No Dynatrade API token for specified, pass using `apitoken: 'token'`") unless (value and not value.empty?)
                                       end),

          FastlaneCore::ConfigItem.new(key: :appId,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_APP_ID",
                                       description: "The app ID you get from your Dynatrace environment",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the appID for your application. Pass using `appId: 'appId'`") unless (value and not value.empty?)
                                       end),

          FastlaneCore::ConfigItem.new(key: :bundleId,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_BUNDLE_ID",
                                       description: "The CFBundlebundleId (iOS) / package (Android) of the application",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the BundleID for your app. Pass using `bundleId: 'bundleId'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :versionStr,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_VERSION_STRING",
                                       description: "The CFBundleShortVersionString (iOS) / versionName (Android)",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the CFBundleShortVersionString for your app. Pass using `versionStr: 'versionStr'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_VERSION",
                                       description: "The CFBundleVersion (iOS) / versionCode (Android). Is also used for the dSYM download",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the version for your app. Pass using `version: 'version'`") unless (value and not value.empty?)
                                       end),

          FastlaneCore::ConfigItem.new(key: :symbolsfile,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_SYM_FILE_PATH",
                                       description: "Path to the dSYM or Android mapping file to be processed. Android only: If the file exceeds 10MiB and doesn't end with *.zip it's zipped before uploading. This can be disabled by setting `symbolsfileAutoZip` to false",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide a value for the symbol files. Pass using `symbolsfile: 'symbolsfile'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_SYM_FILE_AUTO_ZIP",
                                       default_value: true,
                                       is_string: false,
                                       description: "(Android only) Automatically zip symbolsfile if it exceeds 10MiB and doesn't already end with *.zip"),

          FastlaneCore::ConfigItem.new(key: :server,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_SERVER_URL",
                                       description: "The API endpoint for the Dynatrace environment (e.g. https://environmentID.live.dynatrace.com or https://dynatrace-managed.com/e/environmentID)",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide your environment API endpoint. Pass using `server: 'server'`") unless (value and not value.empty?)
                                       end),

          FastlaneCore::ConfigItem.new(key: :cleanBuildArtifacts,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_CLEAN_BUILD_ARTIFACTS",
                                       default_value: false,
                                       is_string: false,
                                       description: "Clean build artifacts after processing"),

          FastlaneCore::ConfigItem.new(key: :tempdir,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_TEMP_DIR",
                                       description: "(OPTIONAL) Custom temporary directory for the DTXDssClient. The plugin does not take care of cleaning this directory",
                                       optional: true),

          FastlaneCore::ConfigItem.new(key: :debugMode,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DEBUG_MODE",
                                       description: "Enable debug logging",
                                       default_value: false,
                                       is_string: false,
                                       optional: true)
        ]
      end

      def self.authors
        ["MANassar/@MohamedANassar", "cynicer"]
      end

      def self.is_supported?(platform)
         [:ios, :android].include?(platform)
      end
    end
  end
end
