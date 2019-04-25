require 'fastlane/action'
require_relative '../helper/dynatrace_helper'

module Fastlane
  module Actions
    class DynatraceProcessSymbolsAction < Action

      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        UI.message "DTXDssClientPath: #{params[:dtxDssClientPath]}"
        UI.message "Parameter API Token: #{params[:apitoken]}"
        UI.message "OS: #{params[:os]}"
        UI.message "Bundle name: #{params[:bundleName]}" if params[:os] == "ios"
        UI.message "Version string: #{params[:versionStr]}"
        UI.message "Version: #{params[:version]}"
        UI.message "Server URL: #{params[:server]}"

        UI.message("Checking AppFile for possible AppID")
        bundleId = CredentialsManager::AppfileConfig.try_fetch_value(:app_identifier)
        UI.message("Using #{bundleId} from your AppFile")

        if !(bundleId)
          UI.message "BundleID: #{params[:bundleId]}"
        end


        dsym_paths = []

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
                  UI.message "Username: #{params[:username]}"
                end

                UI.message("Downloading Dsyms from AppStore Connect")
                Fastlane::Actions::DownloadDsymsAction.run(app_identifier: bundleId,
                                                       username: username,
                                                       version: version)
                dsym_paths += Actions.lane_context[SharedValues::DSYM_PATHS] if Actions.lane_context[SharedValues::DSYM_PATHS]

                if dsym_paths.count > 0
                  UI.message("Downloaded the Dsyms from AppStore Connect. Paths #{dsym_paths}")

                else
                  raise 'No dsyms found error'
                end
             end

          rescue
            UI.error("Couldn't download Dsyms. Checking if we have a local path")
            dsym_paths << params[:symbolsfile] if params[:symbolsfile]
          end #end the begin-rescue block

      else #android
         dsym_paths << params[:symbolsfile] if params[:symbolsfile]
      end

      #check if we have dsyms to proceed with
      if (dsym_paths.count == 0)
        UI.message "Symbol file path: #{params[:symbolsfile]}" #Ask the user for the symbolFiles path
        dsym_paths = params[:symbolsfile]
        symbolFilesCommandSnippet = "symbolsfile=\"#{dsym_paths}\""
      else
        symbolFilesCommandSnippet = "symbolsfile=\"#{dsym_paths[0]}\""
      end

        #Start constructing the command that will trigger the DTXDssClient
        command = []
        command << "#{params[:dtxDssClientPath]}"
        command << "-#{params[:action]}"  #"-upload"
        command << "appid=\"#{params[:appId]}\""
        command << "apitoken=\"#{params[:apitoken]}\""
        command << "os=#{params[:os]}"
        command << "bundleId=\"#{bundleId}\""
        command << "bundleName=\"#{params[:bundleName]}\""
        command << "versionStr=\"#{version}\""
        command << "version=\"#{params[:version]}\""
        command << symbolFilesCommandSnippet
        command << "server=\"#{params[:server]}\""
        command << "DTXLogLevel=ALL -verbose" if params[:debugMode] == true
        command << "forced=1" #So that we do not waste time with errors if the file already exists

        # Create the full shell command to trigger the DTXDssClient
        shell_command = command.join(' ')


        UI.message("Dsym paths: #{dsym_paths[0]}")
        UI.message("#{shell_command}")

        # Execute the shell command
         sh "#{shell_command}"

        UI.message("Cleaning build artifacts")
        Fastlane::Actions::CleanBuildArtifactsAction.run(exclude_pattern: nil)

      end #end the run functions

      def self.description
        "This action processes and uploads your symbol files to Dynatrace"
      end

      def self.details
        "This action allows you to process and upload symbol files to Dynatrace. You can also use it to first download your latest dSym files from AppStore Connect if you use Bitcode"
      end

      def self.available_options
        # Define all options your action supports.
        [
          FastlaneCore::ConfigItem.new(key: :action,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_ACTION",
                                       description: "The action you need to perform. For example upload/decode",
                                       default_value: "upload",
                                       is_string: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("Action needs to either be upload or decode") unless (value and value == "upload" or value == "decode")
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),

          FastlaneCore::ConfigItem.new(key: :downloadDsyms,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS", # The name of the environment variable
                                       default_value: false,
                                       is_string: false,
                                       description: "Boolean variable that enables downloading the Dsyms from AppStore Connect (iOS only)", # a short description of this parameter
                                      ),

          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DOWNLOAD_DSYMS_USERNAME", # The name of the environment variable
                                       description: "The username or the AppleID to use to download the Dsyms", # a short description of this parameter
                                      ),

         FastlaneCore::ConfigItem.new(key: :os,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_OS", # The name of the environment variable
                                      description: "The OperatingSystem of the symbol files. Either \"ios\" or \"android\"",
                                      sensitive: false,
                                      optional: false,
                                      verify_block: proc do |value|
                                         UI.user_error!("Please specify the OperatingSystem of the symbol files. Possible values are \"ios\" or \"android\"") unless (value and not value.empty? and (value == "ios" || value =="android"))
                                      end),

          FastlaneCore::ConfigItem.new(key: :apitoken,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_apitoken", # The name of the environment variable
                                       description: "The Dynatrace API token", # a short description of this parameter
                                       verify_block: proc do |value|
                                          UI.user_error!("No API token for UploadToDynatraceAction given, pass using `apitoken: 'token'`") unless (value and not value.empty?)
                                          # UI.user_error!("Couldn't find file at path '#{value}'") unless File.exist?(value)
                                       end),

          FastlaneCore::ConfigItem.new(key: :dtxDssClientPath,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DTXDssClientPath",
                                       description: "The path to your DTXDssClient",
                                       default_value: "./DTXDssClient",
                                       verify_block: proc do |value|
                                          UI.user_error!("We need the path to the DTXDssClient in your iOS agent folder. For example . Pass using `dtxDssClientPath: 'path'`") unless (value and not value.empty?)
                                       # is_string: true # true: verifies the input is a string, false: every kind of value
                                       # default_value: false) # the default value if the user didn't provide one
                                     end),

         FastlaneCore::ConfigItem.new(key: :appId,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_APP_ID",
                                      description: "The app ID you get from your Dynatrace WebUI",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide the appID for your app. Pass using `appId: 'appId'`") unless (value and not value.empty?)
                                      # is_string: true # true: verifies the input is a string, false: every kind of value
                                      # default_value: false) # the default value if the user didn't provide one
                                    end),

          FastlaneCore::ConfigItem.new(key: :bundleId,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_BUNDLE_ID",
                                       description: "The CFBundlebundleId (iOS) / package (Android) of the Application. Usually in reverse com notation. Ex. com.your_company.your_app",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the BundleID for your app. Pass using `bundleId: 'bundleId'`") unless (value and not value.empty?)
                                       # is_string: true # true: verifies the input is a string, false: every kind of value
                                       # default_value: false) # the default value if the user didn't provide one
                                     end),

         FastlaneCore::ConfigItem.new(key: :bundleName,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_BUNDLE_NAME",
                                      description: "The CFBundleName of the Application (iOS only)",
                                      sensitive: false,
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide the bundleName for your app. Pass using `bundleName: 'bundleName'`") unless (value and not value.empty?)
                                    end),

          FastlaneCore::ConfigItem.new(key: :versionStr,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_VERSION_STRING",
                                       description: "The CFBundleShortVersionString (iOS) / versionName (Android)",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide the CFBundleShortVersionString for your app. Pass using `versionStr: 'versionStr'`") unless (value and not value.empty?)
                                       # is_string: true # true: verifies the input is a string, false: every kind of value
                                       # default_value: false) # the default value if the user didn't provide one
                                     end),

         FastlaneCore::ConfigItem.new(key: :version,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_VERSION",
                                      description: "The CFBundleVersion (iOS) / versionCode (Android)",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide the version for your app. Pass using `version: 'version'`") unless (value and not value.empty?)
                                      # is_string: true # true: verifies the input is a string, false: every kind of value
                                      # default_value: false) # the default value if the user didn't provide one
                                    end),

          FastlaneCore::ConfigItem.new(key: :symbolsfile,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_SYM_FILE_PATH",
                                       description: "The filename/path of the XCode iOS archive or iOS dSYM containing the symbol mappings",
                                       verify_block: proc do |value|
                                          UI.user_error!("Please provide a value for the symbolFiles. Pass using `symbolsfile: 'symbolsfile'`") unless (value and not value.empty?)
                                       # is_string: true # true: verifies the input is a string, false: every kind of value
                                       # default_value: false) # the default value if the user didn't provide one
                                     end),

         FastlaneCore::ConfigItem.new(key: :server,
                                      env_name: "FL_UPLOAD_TO_DYNATRACE_SERVER_URL",
                                      description: "The API endpoint for the Dynatrace environment. For example https://<environmentID.live.dynatrace.com/api/config/v1",
                                      verify_block: proc do |value|
                                         UI.user_error!("Please provide your environment API endpoint. Pass using `server: 'server'`") unless (value and not value.empty?)
                                      # is_string: true # true: verifies the input is a string, false: every kind of value
                                      # default_value: false) # the default value if the user didn't provide one
                                    end),

          FastlaneCore::ConfigItem.new(key: :debugMode,
                                       env_name: "FL_UPLOAD_TO_DYNATRACE_DEBUG_MODE",
                                       description: "Debug logging enabled",
                                       is_string: false,
                                       optional: true
                                     )
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["MANassar/@MohamedANassar"]
      end

      def self.is_supported?(platform)
         [:ios, :android].include?(platform)
      end
    end
  end
end
