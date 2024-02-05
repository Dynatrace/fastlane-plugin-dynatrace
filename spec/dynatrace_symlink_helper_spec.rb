require 'rspec'

describe Fastlane::Helper::DynatraceSymlinkHelper do

  context "when path_exists? is called" do
    context "with invalid path" do
      it "should return false" do
        expect(Fastlane::Helper::DynatraceSymlinkHelper.path_exists?(nil)).to eql(false)
        expect(Fastlane::Helper::DynatraceSymlinkHelper.path_exists?("path/that/does/not/exist")).to eql(false)
      end
    end

    context "with valid file path" do
      before do
        @file_path = Tempfile.new("temp-file")
      end

      after do
        FileUtils.remove_entry(@file_path) if File.exist?(@file_path)
      end

      it "should return true" do
        expect(Fastlane::Helper::DynatraceSymlinkHelper.path_exists?(@file_path)).to eql(true)
      end
    end

    context "with valid directory path" do
      before do
        @dir_path = "temp-dir"
        FileUtils.mkdir(@dir_path)
      end

      after do
        FileUtils.remove_entry(@dir_path) if File.exist?(@dir_path)
      end

      it "should return true" do
        expect(Fastlane::Helper::DynatraceSymlinkHelper.path_exists?(@dir_path)).to eql(true)
      end
    end
  end

  context "when symlink_custom_lldb is called" do
    context "with invalid lldb_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(nil, anything)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb("something/that/does/not/exist", anything)
        }.to raise_error(RuntimeError)
      end
    end

    context "with invalid destination_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(anything, nil)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(anything, "something/that/does/not/exist")
        }.to raise_error(RuntimeError)
        expect(lldb_symlink_exists?("something/that/does/not/exist")).to eql(false)
      end
    end

    context "with valid lldb_path and valid destination_path" do
      before do
        @destination_path = "symlink_custom_lldb-destination-test"
        FileUtils.mkdir(@destination_path)
        @lldb_path = "symlink_custom_lldb-lldb-test"
        FileUtils.mkdir(@lldb_path)
      end

      after do
        FileUtils.remove_entry(@destination_path)
        FileUtils.remove_entry(@lldb_path)
      end

      it "should successfully create the symlink" do
        Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(@lldb_path, @destination_path)

        puts "Destination-path Dir exists?: #{Dir.exist?(@destination_path)}"
        puts "Destination-path File exists?: #{File.exist?(@destination_path)}"
        puts "Destination-path File symlink exists?: #{File.symlink?(@destination_path)}"
        puts "LLDB-path Dir exists?: #{Dir.exist?(@lldb_path)}"
        puts "LLDB-path File exists?: #{File.exist?(@lldb_path)}"
        puts "LLDB-path File symlink exists?: #{File.symlink?(@lldb_path)}"

        symlink = File.join(@destination_path, "LLDB.framework")
        puts "FULL_PATH = #{symlink}"
        sleep(10)
        expect(lldb_symlink_exists?(@destination_path)).to eql(true)
      end
    end
  end

  context "when auto_symlink_lldb is called" do
    context "with invalid destination_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.auto_symlink_lldb(nil)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::DynatraceSymlinkHelper.auto_symlink_lldb("something/that/does/not/exist")
        }.to raise_error(RuntimeError)
      end
    end

    context "with valid destination_path" do
      before do
        @destination_path = "auto_symlink_lldb-destination-test"
        FileUtils.mkdir(@destination_path)
      end

      after do
        FileUtils.remove_entry(@destination_path)
      end

      it "should successfully create the symlink" do
        Fastlane::Helper::DynatraceSymlinkHelper.auto_symlink_lldb(@destination_path)

        puts "VD Destination-path Dir exists?: #{Dir.exist?(@destination_path)}"
        puts "VD Destination-path File exists?: #{File.exist?(@destination_path)}"
        puts "VD Destination-path File symlink exists?: #{File.symlink?(@destination_path)}"

        expect(lldb_symlink_exists?(@destination_path)).to eql(true)
      end
    end
  end

  context "when active_lldb_path is called" do
    context "and xcode_path ends with `Developer`" do
      it "should return the correct path" do
        xcode_path = "some_path/Developer"
        expected_path = "some_path/SharedFrameworks/LLDB.framework"

        active_lldb_path = Fastlane::Helper::DynatraceSymlinkHelper.active_lldb_path(xcode_path)

        expect(active_lldb_path).to eql(expected_path)
      end
    end

    context "and xcode_path does not end with `Developer`" do
      it "should return nil" do
        xcode_path = "some_path/CommandLineTools"

        active_lldb_path = Fastlane::Helper::DynatraceSymlinkHelper.active_lldb_path(xcode_path)

        expect(active_lldb_path).to be_nil
      end
    end
  end

  context "when delete_existing_lldb_symlinks is called" do
    before do
      @destination_path = "dt-symlink-helper-test"
      FileUtils.mkdir(@destination_path)
    end

    after do
      FileUtils.remove_entry(@destination_path)
    end

    context "and there is a file but not a symlink" do
      before do
        @file = Tempfile.new("not-a-symlink.txt", @destination_path)
      end

      after do
        FileUtils.remove_entry(@file)
      end

      it "should do nothing" do
        Fastlane::Helper::DynatraceSymlinkHelper.delete_existing_lldb_symlinks(@destination_path)

        expect(File.exist?(@file)).to eql(true)
      end
    end

    context "and there is a symlink" do
      before do
        @lldb_path = "dt-lldb-test"
        FileUtils.mkpath(@lldb_path)
        FileUtils.symlink(@lldb_path, @destination_path)
      end

      after do
        FileUtils.remove_entry(@lldb_path)
      end

      it "should delete the symlink" do
        Fastlane::Helper::DynatraceSymlinkHelper.delete_existing_lldb_symlinks(@destination_path)

        expect(lldb_symlink_exists?(@destination_path)).to eql(false)
        expect(File.exist?(@lldb_path)).to eql(true)
      end
    end
  end

  def lldb_symlink_exists?(destination_path)
    symlink = File.join(destination_path, "LLDB.framework")
    puts "##### Symlink-path Dir exists?: #{Dir.exist?(symlink)}"
    puts "##### Symlink-path File exists?: #{File.exist?(symlink)}"
    puts "##### Symlink-path File symlink exists?: #{File.symlink?(symlink)}"
    return (Dir.exist?(symlink) || File.exist?(symlink)) && File.symlink?(symlink)
  end
end
