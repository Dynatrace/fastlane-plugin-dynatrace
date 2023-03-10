require 'open-uri'

describe Fastlane::Actions::DynatraceProcessSymbolsAction do

  def mock_config ()
    return [
          FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :tempdir, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false)
        ]
  end

  def mock_dict (os, symbolsfile = Dir.pwd + "/spec/testdata/android-mapping-test.txt")
    return { 
          :apitoken => "",
          :os => os,
          :versionStr => "123",
          :version => "456",
          :server => "https://dynatrace.com",
          :bundleId => "com.dynatrace.fastlanetest",
          :symbolsfile => symbolsfile,
          :dtxDssClientPath => "",
          :appId => "abcdefg",
          :tempdir => "",
          :symbolsfileAutoZip => true
        } 
  end

  describe ".run" do
    context "processing symbols of unknown system" do
      it "can't process" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("windows"))

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end

    context "ios: non-macOS machine" do
      it "can't run on inferiour OSs" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("ios"))

        expect(OS).to receive(:mac?).and_return(false)

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end
    end

    context "android: full valid workflow" do
      it "uploads a local symbol file" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))

        response = Net::HTTPSuccess.new(1.0, '204', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
      end

      it "uploads a local symbol file exceeding the zip limit" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android", Dir.pwd + "/spec/testdata/android-mapping-test_bigger.txt"))

        response = Net::HTTPSuccess.new(1.0, '204', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
      end
    end

    context "android: failing upload" do
      it "uploads a local symbol file but has an error" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))  

        response = Net::HTTPClientError.new(1.0, '400', 'Bad Request')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }  

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it "uploads a local symbol file but auth token is invalid" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))     

        response = Net::HTTPClientError.new(1.0, '401', 'Unauthorized')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }  

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end  

      it "uploads a local symbol file but quota is exceeded" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))   

        response = Net::HTTPClientError.new(1.0, '413', 'Quota Exceeded')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }  

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it "uploads a local symbol file but has an unknown error response" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))   

        response = Net::HTTPClientError.new(1.0, '444', 'Idk')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect_any_instance_of(Net::HTTPClientError).to receive(:body).and_return(nil)

        expect{
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)
        }.to raise_error(FastlaneCore::Interface::FastlaneError)
      end

      it "uploads a local symbol file but has an unknown error response with message" do
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict("android"))  

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