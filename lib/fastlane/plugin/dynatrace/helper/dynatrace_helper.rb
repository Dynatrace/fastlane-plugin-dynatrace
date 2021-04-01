require 'fastlane_core/ui/ui'
require 'digest'
require 'open-uri'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DynatraceHelper
      def self.get_dss_client(params)
        dynatraceDir = "dynatrace"
        dtxDssClientBin = "DTXDssClient"
        versionFilePath = "#{dynatraceDir}/version"
        dtxDssClientPath = "#{dynatraceDir}/#{dtxDssClientBin}"

        if params.all_keys.include? :dtxDssClientPath and not params[:dtxDssClientPath].nil?
          UI.important "DEPRECATION WARNING: DTXDssClientPath doesn't need to be specified anymore, the #{dtxDssClientBin} is downloaded and updated automatically."
          return params[:dtxDssClientPath]
        end

        # get latest version info
        clientUri = URI("#{self.get_server_base_url(params)}/api/config/v1/symfiles/dtxdss-download?Api-Token=#{params[:apitoken]}")
        response = Net::HTTP.get_response(clientUri)

        # filter any http errors
        if not response.kind_of? Net::HTTPSuccess
          error_msg = "Couldn't update #{dtxDssClientBin} (invalid response: #{response.message} (#{response.code})) for URL: #{clientUri})"
          self.check_fallback_or_raise(dtxDssClientPath, error_msg)
        end

        # parse body
        begin
          responseJson = JSON.parse(response.body)
        rescue JSON::GeneratorError, 
               JSON::JSONError, 
               JSON::NestingError, 
               JSON::ParserError
          error_msg = "Error parsing response body: #{response.body} from URL (#{clientUri}), failed with error #{$!}"
          self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          return dtxDssClientPath
        end

        # parse url
        remoteClientUrl = responseJson["dssClientUrl"]
        if remoteClientUrl == nil or remoteClientUrl == ""
          error_msg = "No value for dssClientUrl in response body (#{response.body})."
          self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          return dtxDssClientPath
        end
        UI.message "Remote DSS client: #{remoteClientUrl}"

        # check/update local state
        if !File.directory?(dynatraceDir)
          Dir.mkdir(dynatraceDir) 
        end

        # only update if a file is missing or the local version is different
        if !(File.exists?(versionFilePath) and
           File.exists?(dtxDssClientPath) and 
           File.read(versionFilePath) == remoteClientUrl and
           File.size(dtxDssClientPath) > 0)
          # extract and save client
          updatedClient = false

          # prevents from creating a StringIO object instead of FileIO in URI.open if <10kB
          OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
          OpenURI::Buffer.const_set 'StringMax', 0

          begin
            URI.open(remoteClientUrl) do |zipped|
              UI.message "Unzipping fetched file with MD5 hash: #{Digest::MD5.new << IO.read(zipped)}"
              Zip::InputStream.open(zipped) do |unzipped|
                entry = unzipped.get_next_entry
                if (entry.name == dtxDssClientBin)
                  # remove old client
                  UI.message "Found a different remote #{dtxDssClientBin} client. Removing local version and updating."
                  File.delete(versionFilePath) if File.exist?(versionFilePath)
                  File.delete(dtxDssClientPath) if File.exist?(dtxDssClientPath)

                  # write new client
                  File.write(versionFilePath, remoteClientUrl)
                  IO.copy_stream(entry.get_input_stream, dtxDssClientPath)
                  FileUtils.chmod("+x", dtxDssClientPath)
                  updatedClient = true
                end
              end
            end
          rescue Zip::DecompressionError, 
                 Zip::DestinationFileExistsError, 
                 Zip::EntryExistsError, 
                 Zip::EntryNameError, 
                 Zip::EntrySizeError, 
                 Zip::GPFBit3Error, 
                 Zip::InternalError 
            error_msg = "Could not update/extract #{dtxDssClientBin}, please try again."
            self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          end

          if updatedClient
            UI.success "Successfully updated DTXDssClient."
          else
            error_msg = "#{dtxDssClientBin} not found in served archive, please try again."
            self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          end
        end
        return dtxDssClientPath
      end

      def self.get_server_base_url(params)
        if params[:server][-1] == '/'
          return params[:server][0..-2]
        else
          return params[:server]
        end
      end

      private
      def self.check_fallback_or_raise(fallback_client, error)
        UI.important "If this error persists create an issue on our Github project (https://github.com/Dynatrace/fastlane-plugin-dynatrace/issues) or contact our support at https://www.dynatrace.com/support/contact-support/."
        if File.exists?(fallback_client) and File.size(fallback_client) > 0
          UI.important error
          UI.important "Using cached client: #{fallback_client}"
        else
          raise error
        end
      end
    end
  end
end
