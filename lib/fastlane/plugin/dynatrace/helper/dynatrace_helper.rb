require 'fastlane_core/ui/ui'
require 'digest'
require 'net/https'
require 'tempfile'
require 'uri'

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
          UI.important "DEPRECATION WARNING: dtxDssClientPath doesn't need to be specified anymore, the #{dtxDssClientBin} is downloaded and updated automatically."
          return params[:dtxDssClientPath]
        end

        # get latest version info
        clientUri = URI("#{self.get_host_name(params)}/api/config/v1/symfiles/dtxdss-download?Api-Token=#{params[:apitoken]}")
        response = Net::HTTP.get_response(clientUri)

        # filter any http errors
        if not response.kind_of? Net::HTTPSuccess
          error_msg = "Couldn't update #{dtxDssClientBin} (invalid response: #{response.message} (#{response.code})) for URL: #{self.to_redacted_api_token_string(clientUri)})"
          self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          return dtxDssClientPath
        end

        # parse body
        begin
          responseJson = JSON.parse(response.body)
        rescue JSON::GeneratorError, 
               JSON::JSONError, 
               JSON::NestingError, 
               JSON::ParserError
          error_msg = "Error parsing response body: #{response.body} from URL (#{self.to_redacted_api_token_string(clientUri)}), failed with error #{$!}"
          self.check_fallback_or_raise(dtxDssClientPath, error_msg)
          return dtxDssClientPath
        end

        # parse url
        remoteClientUrl = responseJson["dssClientUrl"]
        if remoteClientUrl.nil? or remoteClientUrl.empty?
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
          updatedClient = false

          # extract and save client
          zipped_tmp = self.save_to_tempfile(remoteClientUrl)
          if File.size(zipped_tmp) <= 0
            error_msg = "Downloaded symbolication client archive is empty (0 bytes)."
            self.check_fallback_or_raise(dtxDssClientPath, error_msg)
            return dtxDssClientPath
          end

          begin
            UI.message "Unzipping fetched file with MD5 hash: #{Digest::MD5.new << IO.read(zipped_tmp)}"
            Zip::InputStream.open(zipped_tmp) do |unzipped|
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
          rescue Zip::DecompressionError, 
                 Zip::DestinationFileExistsError, 
                 Zip::EntryExistsError, 
                 Zip::EntryNameError, 
                 Zip::EntrySizeError, 
                 Zip::GPFBit3Error, 
                 Zip::InternalError,
                 Zip::CompressionMethodError 
            error_msg = "Could not update/extract #{dtxDssClientBin}, please try again."
            self.check_fallback_or_raise(dtxDssClientPath, error_msg)
            return dtxDssClientPath
          end

          if updatedClient
            UI.success "Successfully updated DTXDssClient."
          else
            error_msg = "#{dtxDssClientBin} not found in served archive, please try again."
            self.check_fallback_or_raise(dtxDssClientPath, error_msg)
            return dtxDssClientPath
          end
        end
        return dtxDssClientPath
      end

      def self.get_host_name(params)
        uri = URI.split(params[:server])

        unless uri[2].nil?
          return uri[2]
        end

        # no procotol prefix -> host name is with path
        if uri[5][-1] == '/'
          return uri[5][0..-2] # remove trailing /
        else
          return uri[5]
        end
      end

      def self.put_android_symbols(params, bundleId)
        path = "/api/config/v1/symfiles/#{params[:appId]}/#{bundleId}/ANDROID/#{params[:version]}/#{params[:versionStr]}"

        req = Net::HTTP::Put.new(path, initheader = { 'Content-Type' => 'text/plain',
                                                      'Authorization' => "Api-Token #{params[:apitoken]}"} )

        req.body = IO.read(params[:symbolsfile])
        http = Net::HTTP.new(self.get_host_name(params), 443)
        http.use_ssl = true
        response = http.request(req)

        response.code
      end

      private
      def self.check_fallback_or_raise(fallback_client, error)
        UI.important "If this error persists create an issue on our Github project (https://github.com/Dynatrace/fastlane-plugin-dynatrace/issues) or contact our support at https://www.dynatrace.com/support/contact-support/."
        UI.important error
        if File.exists?(fallback_client) and File.size(fallback_client) > 0
          UI.important "Using cached client: #{fallback_client}"
        else
          UI.important "No cached fallback found."
          raise error
        end
      end

      # assumes the token parameter is appended last (there is only one parameter anyway)
      def self.to_redacted_api_token_string(url)
        urlStr = url.to_s
        str = "Api-Token="
        idx = urlStr.index(str)
        token_len = urlStr.length - idx - str.length
        urlStr[idx + str.length..idx + str.length + token_len] = "-" * token_len
        return urlStr
      end

      # for test mocking
      def self.save_to_tempfile(url)
        open(url)
      end
    end
  end
end
