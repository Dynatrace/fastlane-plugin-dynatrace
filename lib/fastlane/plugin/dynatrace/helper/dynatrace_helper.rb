require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DynatraceHelper
      def self.get_dss_client(params)
        dynatraceDir = "dynatrace"
        versionFile = "version"
        dtxDssClientBin = "DTXDssClient"
        dtxDssClientPath = "#{dynatraceDir}/#{dtxDssClientBin}"

        if (params.all_keys.include? :dtxDssClientPath and not params[:dtxDssClientPath].nil?)
          UI.message "DEPRECATION WARNING: DTXDssClientPath doesn't need to be specified anymore, the DTXDssClient is downloaded and updated automatically."
          dtxDssClientPath = params[:dtxDssClientPath]
        else
          # get latest version info
          clientUri = URI("#{params[:server]}/api/config/v1/symfiles/dtxdss-download?Api-Token=#{params[:apitoken]}")
          response = Net::HTTP.get_response(clientUri)

          if not response.kind_of? Net::HTTPSuccess
            raise "Can't connect to server, invalid response #{response.message} (#{response.code}) for URL: #{clientUri}"
          end

          remoteClientUrl = JSON.parse(response.body)["dssClientUrl"]
          UI.message "Remote DSS client: #{remoteClientUrl}"

          # check local state
          if (!File.directory?(dynatraceDir))
            Dir.mkdir(dynatraceDir) 
          end

          if (!File.exists?("#{dynatraceDir}/#{versionFile}") or
              !File.exists?("#{dynatraceDir}/#{dtxDssClientBin}") or 
              File.read("#{dynatraceDir}/#{versionFile}") != remoteClientUrl)
            # update local state
            UI.message "Found a different remote DTXDssClient client. Updating local version."
            File.delete("#{dynatraceDir}/#{versionFile}") if File.exist?("#{dynatraceDir}/#{versionFile}")
            File.delete("#{dynatraceDir}/#{dtxDssClientBin}") if File.exist?("#{dynatraceDir}/#{dtxDssClientBin}")

            File.write("#{dynatraceDir}/#{versionFile}", remoteClientUrl)

            # get client from served archive
            open(remoteClientUrl) do |zipped|
              Zip::InputStream.open(zipped) do |unzipped|
                entry = unzipped.get_next_entry
                if (entry.name == dtxDssClientBin)
                  IO.copy_stream(entry.get_input_stream, "#{dynatraceDir}/#{dtxDssClientBin}")
                  FileUtils.chmod("+x", "#{dynatraceDir}/#{dtxDssClientBin}")
                end
              end
            end
          end
        end
        return dtxDssClientPath
      end
    end
  end
end
