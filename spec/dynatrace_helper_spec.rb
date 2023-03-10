require 'open-uri'

describe Fastlane::Helper::DynatraceHelper do

  describe ".get_dss_client" do
    context "full valid workflow" do
      it "fetches and unzips the newest dss client successfully" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false)
        #expect(File).to receive(:read).and_return("http://127.0.0.1:8000/DTXDssClient.zip")
        #expect(File).to receive(:size).and_return(1)
        #expect(File).to receive(:delete).and_return(1, 1)
        expect(File).to receive(:write).and_return(1)

        expect(IO).to receive(:copy_stream).and_return(1)
        expect(FileUtils).to receive(:chmod).and_return(1)

        # no exception and returned path -> looks like we successfully installed the client
        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "uses deprecated client path parameter" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls",
                 :dtxDssClientPath => "dynatrace/DTXDssClient123" }

        flhash = FastlaneCore::Configuration.create([server, apitoken, dtxDssClientPath], dict)
        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient123")
      end
    end

    context "invalid server response code - no fallback" do
      it "fetches the dss client config, but gets an error code" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPUnauthorized.new(1.0, '401', 'Unauthorized')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "fetches the dss client config, but gets an error code" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPUnauthorized.new(1.0, '401', 'Unauthorized')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end
    end

    context "gets empty json a json response" do
      it "is empty json - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is empty json - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "is missing the json key - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl1": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is missing the json key - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl1": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "is malformed json - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{""dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is malformed json - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{""dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end
    end

    context "retrieved dss client archive successfully" do
      it "is damaged - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_broken.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(1)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is damaged - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_broken.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(1).twice

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end

      it "is missing the client binary - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_no client.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(1)
        
        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is missing the client binary - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_no client.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(1).twice

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end

      it "is a 0 byte archive - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_empty.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(0)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is a 0 byte archive - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "this_is_just_a_mock_token_dont_report_pls" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_empty.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(0, 1)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end
    end
  end

  describe ".without_trailing_slash" do
    context "given 'https://dynatrace.com/'" do
      it "returns https://dynatrace.com" do
        expect(Fastlane::Helper::DynatraceHelper.without_trailing_slash("https://dynatrace.com/")).to eql("https://dynatrace.com")
      end
    end

    context "given 'https://your-domain.com/e/your-environment-id/'" do
      it "returns https://your-domain.com/e/your-environment-id" do
        expect(Fastlane::Helper::DynatraceHelper.without_trailing_slash("https://your-domain.com/e/your-environment-id/")).to eql("https://your-domain.com/e/your-environment-id")
      end
    end

    context "given 'https://your-domain.com/e/your-environment-id'" do
      it "returns https://your-domain.com/e/your-environment-id" do
        expect(Fastlane::Helper::DynatraceHelper.without_trailing_slash("https://your-domain.com/e/your-environment-id")).to eql("https://your-domain.com/e/your-environment-id")
      end
    end
  end

  describe ".get_host_name" do
    context "given 'https://dynatrace.com/'" do
      it "returns dynatrace.com" do
        dict = { :server => "https://dynatrace.com/" }
        expect(Fastlane::Helper::DynatraceHelper.get_host_name(dict)).to eql("dynatrace.com")
      end
    end

    context "given 'dynatrace.com/'" do
      it "returns dynatrace.com" do
        dict = { :server => "dynatrace.com/" }
        expect(Fastlane::Helper::DynatraceHelper.get_host_name(dict)).to eql("dynatrace.com")
      end
    end

    context "given 'https://your-domain.com/e/your-environment-id/api/blablub'" do
      it "returns your-domain.com" do
        dict = { :server => "https://your-domain.com/e/your-environment-id/api/blablub" }
        expect(Fastlane::Helper::DynatraceHelper.get_host_name(dict)).to eql("your-domain.com")
      end
    end
  end

  describe ".check_fallback_or_raise" do
    context "given valid fallback client mocks" do
      it "throws no error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
      end
    end

    context "empty client binary found" do
      it "throws an error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(true)

        expect{
          Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
        }.to raise_error(error_msg)
      end
    end

    context "no client binary found" do
      it "throws an error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
        }.to raise_error(error_msg)
      end
    end
  end

  describe ".to_redacted_api_token_string" do
    context "given 'https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345'" do
      it "return https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----" do
        uri = URI("https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345")
        str_redacted = "https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----"
        expect(Fastlane::Helper::DynatraceHelper.to_redacted_api_token_string(uri)).to eql(str_redacted)
      end
    end

    context "given 'https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345&tesArg=123'" do
      it "calls the method with multiple arguments on url -> not designed to work with multiple args" do
        uri = URI("https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345&tesArg=123")
        str_redacted = "https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----&tesArg=123"
        expect(Fastlane::Helper::DynatraceHelper.to_redacted_api_token_string(uri)).not_to eql(str_redacted)
      end
    end
  end

  describe ".zip_if_required" do
    context "given no auto zip param" do
      it "doesn't auto zip" do
        symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
        symbolsfileAutoZip = FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false)
        dict = { :symbolsfile => "samplepath",
                 :symbolsfileAutoZip => false }

        flhash = FastlaneCore::Configuration.create([symbolsfile, symbolsfileAutoZip], dict)

        preprocessed_symbolspath = Fastlane::Helper::DynatraceHelper.zip_if_required(flhash)
        expect(preprocessed_symbolspath).to eql(dict[:symbolsfile])
      end
    end

    context "it's already zipped" do
      it "doesn't zip again" do
        symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
        symbolsfileAutoZip = FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false)
        dict = { :symbolsfile => "samplepath.zip",
                 :symbolsfileAutoZip => true }

        flhash = FastlaneCore::Configuration.create([symbolsfile, symbolsfileAutoZip], dict)

        preprocessed_symbolspath = Fastlane::Helper::DynatraceHelper.zip_if_required(flhash)
        expect(preprocessed_symbolspath).to eql(dict[:symbolsfile])
      end
    end

    context "doesn't exceed the limit" do
      it "doesn't zip" do
        tmpfile = Tempfile.new('testfile.txt')
        tmpfile.write ("a" * 10 * 1024 * 1024).freeze
        tmpfile.rewind

        symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
        symbolsfileAutoZip = FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false)
        dict = { :symbolsfile => tmpfile.path(),
                 :symbolsfileAutoZip => true }

        flhash = FastlaneCore::Configuration.create([symbolsfile, symbolsfileAutoZip], dict)

        preprocessed_symbolspath = Fastlane::Helper::DynatraceHelper.zip_if_required(flhash)
        expect(preprocessed_symbolspath).to eql(dict[:symbolsfile])
      end
    end

    context "exceeds the limit" do
      it "zips" do
        tmpfile = Tempfile.new('testfile.txt')
        tmpfile.write ("a" * 10 * 1024 * 1024).freeze + "b"
        tmpfile.rewind

        symbolsfile = FastlaneCore::ConfigItem.new(key: :symbolsfile, type: String, optional: false)
        symbolsfileAutoZip = FastlaneCore::ConfigItem.new(key: :symbolsfileAutoZip, type: Object, optional: false)
        dict = { :symbolsfile => tmpfile.path(),
                 :symbolsfileAutoZip => true }

        flhash = FastlaneCore::Configuration.create([symbolsfile, symbolsfileAutoZip], dict)

        preprocessed_symbolspath = Fastlane::Helper::DynatraceHelper.zip_if_required(flhash)
        expect(preprocessed_symbolspath).to eql(dict[:symbolsfile] + ".zip")
        expect(File.exist?(preprocessed_symbolspath)).to eql(true)
      end
    end
  end

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

  describe ".put_android_symbols" do
    context "regular saas request without zip" do
      it "generates the correct request" do
        mock_dict = mock_dict("android")
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict)

        response = Net::HTTPSuccess.new(1.0, '204', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        response, request = Fastlane::Helper::DynatraceHelper.put_android_symbols(mock_dict, "com.dynatrace.fastlanetest", Dir.pwd + "/spec/testdata/android-mapping-test.txt")

        expect(request['Content-Type']).to eql('text/plain')
        expect(request['Authorization']).to eql('Api-Token')
        expect(request.path).to eql('/api/config/v1/symfiles/abcdefg/com.dynatrace.fastlanetest/ANDROID/456/123')
      end
    end

    context "regular saas request with zip" do
      it "generates the correct request" do
        mock_dict = mock_dict("android")
        flhash = FastlaneCore::Configuration.create(mock_config(), mock_dict)

        response = Net::HTTPSuccess.new(1.0, '204', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        Fastlane::Helper::DynatraceHelper.zip_if_required(flhash)

        response, request = Fastlane::Helper::DynatraceHelper.put_android_symbols(mock_dict, "com.dynatrace.fastlanetest", Dir.pwd + "/spec/testdata/android-mapping-test_bigger.txt.zip")

        expect(request['Content-Type']).to eql('application/zip')
        expect(request['Authorization']).to eql('Api-Token')
        expect(request.path).to eql('/api/config/v1/symfiles/abcdefg/com.dynatrace.fastlanetest/ANDROID/456/123')
      end
    end
  end
end