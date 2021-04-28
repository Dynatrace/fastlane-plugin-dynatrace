require 'open-uri'

describe Fastlane::Actions::DynatraceProcessSymbolsAction do
  describe ".run" do
    context "processing symbols of unknown system" do
        it "can't process" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)

            dict = { :apitoken => "",
                     :os => "windows_mobile_lol",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end
    end

    context "ios: non-macOS machine" do
        it "can't run on inferiour OSs" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)

            dict = { :apitoken => "",
                     :os => "ios",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)

            expect(OS).to receive(:mac?).and_return(false)

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end
    end

    context "android: full valid workflow" do
        it "uploads a local symbol file" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)

            response = Net::HTTPSuccess.new(1.0, '204', 'OK')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }

            Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        end
    end

    context "android: failing upload" do
        it "uploads a local symbol file but has an error" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)    

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }    

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)    

            response = Net::HTTPClientError.new(1.0, '400', 'Bad Request')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }    

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

        it "uploads a local symbol file but auth token is valid" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)    

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }    

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)    

            response = Net::HTTPClientError.new(1.0, '401', 'Unauthorized')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }    

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end  

        it "uploads a local symbol file but quota is exceeded" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)    

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }    

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)    

            response = Net::HTTPClientError.new(1.0, '413', 'Quota Exceeded')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }    

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end

        it "uploads a local symbol file but has an unknown error response" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)    

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }    

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)    

            response = Net::HTTPClientError.new(1.0, '444', 'Idk')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }
            expect_any_instance_of(Net::HTTPClientError).to receive(:body).and_return(nil)

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end

        it "uploads a local symbol file but has an unknown error response with message" do
            # mock config
            apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
            os = FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false)
            versionStr = FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false)
            version = FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false)
            server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
            bundleId = FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false)
            symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
            dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
            appId = FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false)    

            dict = { :apitoken => "",
                     :os => "android",
                     :versionStr => "123",
                     :version => "456",
                     :server => "https://dynatrace.com",
                     :bundleId => "com.dynatrace.fastlanetest",
                     :symbolsfile => Dir.pwd + "/spec/testdata/android-mapping-test.txt",
                     :dtxDssClientPath => "",
                     :appId => "abcdefg" }    

            flhash = FastlaneCore::Configuration.create([apitoken, os, versionStr, version, server, bundleId, symbolsfile, dtxDssClientPath, appId], dict)    

            response = Net::HTTPClientError.new(1.0, '444', 'Idk')
            expect_any_instance_of(Net::HTTP).to receive(:request) { response }
            expect_any_instance_of(Net::HTTPClientError).to receive(:body).and_return('{ "error": { "message": "test message" } }')
            expect_any_instance_of(Net::HTTPClientError).to receive(:body).and_return('{ "error": { "message": "test message" } }')

            expect{
                Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
            }.to raise_error(FastlaneCore::Interface::FastlaneError)
        end
    end
  end
end