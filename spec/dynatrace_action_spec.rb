require 'open-uri'

describe Fastlane::Actions::DynatraceProcessSymbolsAction do

  def mock_config
    return [
          FastlaneCore::ConfigItem.new(key: :action, type: String, optional: true),
          FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :os, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :versionStr, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :version, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :bundleId, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :appId, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :cleanBuildArtifacts, type: Object, optional: true),
          FastlaneCore::ConfigItem.new(key: :tempdir, type: String, optional: false),
          FastlaneCore::ConfigItem.new(key: :debugMode, type: Object, optional: true),
          FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false),
          FastlaneCore::ConfigItem.new(key: :customLLDBFrameworkPath, type: String, optional: true),
          FastlaneCore::ConfigItem.new(key: :autoSymlinkLLDB, type: Object, optional: true)
        ]
  end

  def mock_dict (
    os,
    symbolsfile = Dir.pwd + "/spec/testdata/android-mapping-test.txt",
    customLLDBFrameworkPath: nil,
    autoSymlinkLLDB: nil
  )
    dict = {
      :action => "-upload",
      :apitoken => "",
      :os => os,
      :versionStr => "123",
      :version => "456",
      :server => "https://dynatrace.com",
      :bundleId => "com.dynatrace.fastlanetest",
      :symbolsfile => symbolsfile,
      :dtxDssClientPath => "",
      :appId => "abcdefg",
      :cleanBuildArtifacts => false,
      :tempdir => "",
      :debugMode => false,
      :symbolsfileAutoZip => true
    }

    unless customLLDBFrameworkPath.nil?
      dict[:customLLDBFrameworkPath] = customLLDBFrameworkPath
    end

    unless autoSymlinkLLDB.nil?
      dict[:autoSymlinkLLDB] = autoSymlinkLLDB
    end

    return dict
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

    context "ios: workflow" do
      before do
        dss_client_path = "dt-action-ios-workflow-test/dynatrace"
        FileUtils::mkdir_p dss_client_path
        @destination_path = File.dirname(dss_client_path)
        allow(Fastlane::Helper::DynatraceHelper).to receive(:get_dss_client).and_return(dss_client_path)
      end

      after do
        FileUtils.remove_entry @destination_path
      end

      context "when valid customLLDBFrameWorkPath provided" do
        before do
          @custom_lldb_path = Dir.mktmpdir("lldb-test")
          @flhash = FastlaneCore::Configuration.create(mock_config, mock_dict("ios", customLLDBFrameworkPath: @custom_lldb_path))
        end

        after do
          FileUtils.remove_entry @custom_lldb_path
        end

        it "should create the symlink successfully" do
          Fastlane::Actions::DynatraceProcessSymbolsAction.run(@flhash)
          verify_symlink_exists(@custom_lldb_path, @destination_path)
        end
      end

      context "when there is no valid customLLDBFrameWorkPath provided" do
        context "and autoSymlinkLLDB is true" do
          it "should create the symlink successfully" do
            flhash = FastlaneCore::Configuration.create(mock_config, mock_dict("ios", autoSymlinkLLDB: true))
            expected_symlink = Fastlane::Helper::SymlinkHelper.active_lldb_path("#{%x(xcrun xcode-select --print-path)}".chomp)

            Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)

            verify_symlink_exists(expected_symlink, @destination_path)
          end
        end

        context "and autoSymlinkLLDB is false" do
          it "should not create the symlink" do
            flhash = FastlaneCore::Configuration.create(mock_config, mock_dict("ios", autoSymlinkLLDB: false))

            Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)

            verify_no_symlink_exists(@destination_path)
          end
        end

        context "and autoSymlinkLLDB is nil" do
          it "should not create the symlink" do
            flhash = FastlaneCore::Configuration.create(mock_config, mock_dict("ios"))

            Fastlane::Actions::DynatraceProcessSymbolsAction.run(flhash)

            verify_no_symlink_exists(@destination_path)
          end
        end
      end

      def verify_symlink_exists(expected_symlink, destination_path)
        symlink_files = Dir.glob("#{destination_path}/*").map { |file| File.readlink(file) if File.symlink?(file) }.compact
        expect(symlink_files.include? expected_symlink).to eql(true)
      end

      def verify_no_symlink_exists(destination_path)
        symlink_files = Dir.glob("#{destination_path}/*").map { |file| File.readlink(file) if File.symlink?(file) }.compact
        expect(symlink_files.empty?).to eql(true)
      end
    end
  end
end