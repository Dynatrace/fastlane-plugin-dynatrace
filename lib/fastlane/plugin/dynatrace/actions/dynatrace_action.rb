require 'fastlane/action'
require 'net/http'
require 'open-uri'
require 'zip'
require "fileutils"
require_relative '../helper/dynatrace_helper'

module Fastlane
  module Actions
    class DynatraceProcessSymbolsAction < Action

      def self.run(params)
        UI.message "DTXDssClientPath: #{params[:dtxDssClientPath]}"
        UI.message "Parameter API Token: #{params[:apitoken]}"
        UI.message "OS: #{params[:os]}"
        UI.message "Version string: #{params[:versionStr]}"
        UI.message "Version: #{params[:version]}"
        UI.message "Server URL: #{params[:server]}"

        UI.message "Checking AppFile for possible AppID"
        bundleId = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
        if (bundleId)
          UI.message "Using #{bundleId} from your AppFile"
        else
          bundleId = params[:bundleId]
          UI.message "BundleID: #{bundleId}"
        end

        dtxDssClientPath = Helper::DynatraceHelper.get_dss_client(params)

        dsym_paths = []
        symbolFilesKey = "symbolsfile" #default to iOS

        if (params[:os] == "ios")
          begin
            if (params[:versionStr])
              version = params[:versionStr]
            else
              version = 'latest'
            end

            if (params[:downloadDsyms] == true)
                UI.message("Checking AppFile for possible username/AppleID")
                username = CredentialsManager::AppfileConfig.try_fetch_value(:apple_id)
                UI.message("Using #{username} from your AppFile")

                if !(username)
                  UI.message "Didn't find a username in AppFile, using passed username: #{params[:username]}"
                  username = params[:username]
                end

                UI.message("Downloading dSYMs from AppStore Connect")
                Actions::DownloadDsymsAction.run(wait_for_dsym_processing: true,
                                                wait_timeout: 1800,
                                                app_identifier: bundleId,
                                                username: username,
                                                version: version,
                                                build_number: :versionStr)
                dsym_paths += Actions.lane_context[SharedValues::DSYM_PATHS] if Actions.lane_context[SharedValues::DSYM_PATHS]

                if dsym_paths.count > 0
                  UI.message("Downloaded the dSYMs from App Store Connect. Paths #{dsym_paths}")
                else
                  raise 'No dSYMs found error'
                end
             end

          rescue
            UI.error("Couldn't download dSYMs. Checking if we have a local path")
            dsym_paths << params[:symbolsfile] if params[:symbolsfile]
          end
        else #android
           dsym_paths << params[:symbolsfile] if params[:symbolsfile]
           symbolFilesKey = "file"
        end

        # check if we have dSYMs to proceed with
        if (dsym_paths.count == 0)
          UI.message "Symbol file path: #{params[:symbolsfile]}"
          dsym_paths = params[:symbolsfile]
          symbolFilesCommandSnippet = "#{symbolFilesKey}=\"#{dsym_paths}\""
        else
          symbolFilesCommandSnippet = "#{symbolFilesKey}=\"#{dsym_paths[0]}\""
        end

        # start constructing the command that will trigger the DTXDssClient
        command = []
        command << "#{dtxDssClientPath}"
        command << "-#{params[:action]}"  #"-upload"
        command << "appid=\"#{params[:appId]}\""
        command << "apitoken=\"#{params[:apitoken]}\""
        command << "os=#{params[:os]}"
        command << "bundleId=\"#{bundleId}\""
        if params[:os] == "ios"
          command << "versionStr=\"#{version}\""
        else
          command << "versionStr=\"#{params[:versionStr]}\""
        end
        command << "version=\"#{params[:version]}\""
        command << symbolFilesCommandSnippet
        command << "server=\"#{Helper::DynatraceHelper.get_server_base_url(params)}\""
        command << "DTXLogLevel=ALL -verbose" if params[:debugMode] == true
        command << "forced=1" # if the file already exists

        # Create the full shell command to trigger the DTXDssClient
        shell_command = command.join(' ')

        UI.message("dSYM paths: #{dsym_paths[0]}")
        UI.message("#{shell_command}")

        sh("#{shell_command}", error_callback: ->(result) {
          # ShAction doesn't return any reference to the return value -> parse it from the output
          result_groups = result.match /(?:ERROR: Execution failed, rc=)(\d*)(?:\sreason=)(.*)/
          if result_groups[1] == "413" 
            UI.user_error!("#{result_groups[2]} See https://www.dynatrace.com/support/help/shortlink/mobile-symbolication#manage-the-uploaded-symbol-files for more information.")
          else
            UI.user_error!("#{result_groups[2]}")
          end
        })

        UI.message("Cleaning build artifacts")
        Fastlane::Actions::CleanBuildArtifactsAction.run(exclude_pattern: nil)
      end

      def self.description
        "This action processes and uploads your symbol files to Dynatrace."
      end

      def self.details
        "This action allows you to process and upload symbol files to Dynatrace. If you use Bitcode you can also use it to download the latest DSYM files from App Store Connect."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :action,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_ACTION",
                                       description: "The action you need to perform. For example upload/decode",
                                       default_value: "upload",
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("Action needs to either be upload or decode") unless (value and value == "upload" or value == "decode")
                                       end),

          FastlaneCore::ConfigItem.new(key: :downloadDsyms,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS",
                                       default_value: false,
                                       is_string: false,
                                       description: "Boolean variable that enables downloading the Dsyms from AppStore Connect (iOS only)"),

          FastlaneCore::ConfigItem.new(key: :dsym_waiting_timeout,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS_WAIT_TIMEOUT",
                                       default_value: 900,
                                       is_string: false,
                                       description: "The timeout in milliseconds to wait for processing of dSYMs",
                                      ),

          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS_USERNAME",
                                       description: "The username or the AppleID to use to download the Dsyms",
                                      ),

         FastlaneCore::ConfigItem.new(key: :os,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_OS",
                                      description: "The OperatingSystem of the symbol files. Either \"ios\" or \"android\"",
                                      sensitive: false,
                                      optional: false,
                                      verify_block: proc do |value|
                                         UI.user_error!("Please specify the OperatingSystem of the symbol files. Possible values are \"ios\" or \"android\"") unless (value and not value.empty? and (value == "ios" || value =="android"))
                                      end),

          FastlaneCore::ConfigItem.new(key: :apitoken,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_apitoken",
                                       description: "The Dynatrace API token",
                                       verify_block: proc do |value|
                                          UI.user_error!("No API token for UploadToDynatraceAction given, pass using `apitoken: 'token'`") unless (value and not value.empty?)
                                       end),

          FastlaneCore::ConfigItem.new(key: :dtxDssClientPath,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DTXDssClientPath",
                                       description: "The path to your DTXDssClient",
                                       optional: true),

         FastlaneCore::ConfigItem.new(key: :appId,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_APP_ID",
                                      description: "The app ID you get from your Dynatrace WebUI",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide the appID for your app. Pass using `appId: 'appId'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :bundleId,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_BUNDLE_ID",
                                       description: "The CFBundlebundleId (iOS) / package (Android) of the Application. Usually in reverse com notation. Ex. com.your_company.your_app",
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
                                      description: "The CFBundleVersion (iOS) / versionCode (Android)",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide the version for your app. Pass using `version: 'version'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :symbolsfile,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_SYM_FILE_PATH",
                                       description: "The filename/path of the XCode iOS archive or iOS dSYM containing the symbol mappings",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide a value for the symbolFiles. Pass using `symbolsfile: 'symbolsfile'`") unless (value and not value.empty?)
                                      end),

         FastlaneCore::ConfigItem.new(key: :server,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_SERVER_URL",
                                      description: "The API endpoint for the Dynatrace environment. For example https://<environmentID.live.dynatrace.com/api/config/v1",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide your environment API endpoint. Pass using `server: 'server'`") unless (value and not value.empty?)
                                      end),

          FastlaneCore::ConfigItem.new(key: :debugMode,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DEBUG_MODE",
                                       description: "Debug logging enabled",
                                       is_string: false,
                                       optional: true)
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["MANassar/@MohamedANassar", "cynicer"]
      end

      def self.is_supported?(platform)
         [:ios, :android].include?(platform)
      end
    end
  end
end
