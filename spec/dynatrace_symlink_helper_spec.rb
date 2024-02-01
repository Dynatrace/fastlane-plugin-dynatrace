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
        @dir_path = Dir.mktmpdir("temp-dir")
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
        expect_no_symlinks("something/that/does/not/exist")
      end
    end

    context "with valid lldb_path and valid destination_path" do
      before do
        @destination_path = Dir.mktmpdir("destination-test")
        @lldb_path = Dir.mktmpdir("lldb-test")
      end

      after do
        FileUtils.remove_entry(@destination_path) if File.exist?(@destination_path)
        FileUtils.remove_entry(@lldb_path) if File.exist?(@lldb_path)
      end

      it "should successfully create the symlink" do
        Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(@lldb_path, @destination_path)

        expect(symlink_exists?(@lldb_path, @destination_path)).to eql(true)
      end

      context "when there is already an existing symlink for LLDB framework" do
        before do
          @other_lldb_path = Tempfile.new("test-LLDB.framework")
          # Dir.mkdir(@other_lldb_path)
          FileUtils.symlink(@other_lldb_path, @destination_path)
        end

        after do
          FileUtils.remove_entry(@other_lldb_path) if File.exist?(@other_lldb_path)
        end

        it "should replace the symlink with the new one successfully" do
          Fastlane::Helper::DynatraceSymlinkHelper.symlink_custom_lldb(@lldb_path, @destination_path)

          expect(symlink_exists?(@lldb_path, @destination_path)).to eql(true)
          expect(symlink_exists?(@other_lldb_path, @destination_path)).to eql(false)
        end
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
        @destination_path = Dir.mktmpdir("destination-test")
        @expected_symlink = Fastlane::Helper::DynatraceSymlinkHelper.active_lldb_path("#{%x(xcrun xcode-select --print-path)}".chomp)
      end

      after do
        FileUtils.remove_entry(@destination_path) if File.exist?(@destination_path)
        FileUtils.remove_entry(@expected_symlink) if File.exist?(@expected_symlink)
      end

      it "should successfully create the symlink" do
        Fastlane::Helper::DynatraceSymlinkHelper.auto_symlink_lldb(@destination_path)

        expect(symlink_exists?(@expected_symlink, @destination_path)).to eql(true)
      end

      context "when there is already an existing symlink for LLDB framework" do
        before do
          @other_lldb_path = Tempfile.new("test-LLDB.framework")
          FileUtils.symlink(@other_lldb_path, @destination_path)
        end

        after do
          FileUtils.remove_entry(@other_lldb_path) if File.exist?(@other_lldb_path)
        end

        it "should replace the symlink with the new one successfully" do
          Fastlane::Helper::DynatraceSymlinkHelper.auto_symlink_lldb(@destination_path)

          expect(symlink_exists?(@expected_symlink, @destination_path)).to eql(true)
          expect(symlink_exists?(@other_lldb_path, @destination_path)).to eql(false)
        end
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

  def symlink_exists?(expected_symlink, destination_path)
    symlinks = Dir.glob("#{destination_path}/*").map { |file| File.readlink(file) if File.symlink?(file) }.compact
    return symlinks.include? expected_symlink
  end

  def expect_no_symlinks(destination_path)
    symlinks = Dir.glob("#{destination_path}/*").map { |file| File.readlink(file) if File.symlink?(file) }.compact
    expect(symlinks.empty?).to eql(true)
  end
end
