require 'rspec'

describe Fastlane::Helper::SymlinkHelper do

  context "when symlink_lldb is called" do
    context "with invalid lldb_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::SymlinkHelper.symlink_lldb(nil, anything)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::SymlinkHelper.symlink_lldb("something/that/does/not/exist", anything)
        }.to raise_error(RuntimeError)
      end
    end

    context "with invalid destination_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::SymlinkHelper.symlink_lldb(anything, nil)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::SymlinkHelper.symlink_lldb(anything, "something/that/does/not/exist")
        }.to raise_error(RuntimeError)
        verify_no_symlink_exists("something/that/does/not/exist")
      end
    end

    context "with valid lldb_path and valid destination_path" do
      it "should successfully create the symlink" do
        destination_path = Dir.mktmpdir("destination-test")
        lldb_path = Dir.mktmpdir("lldb-test")

        Fastlane::Helper::SymlinkHelper.symlink_lldb(lldb_path, destination_path)

        verify_symlink_exists(lldb_path, destination_path)
      end
    end
  end

  context "when auto_symlink_lldb is called" do
    context "with invalid destination_path" do
      it "should raise error" do
        expect {
          Fastlane::Helper::SymlinkHelper.auto_symlink_lldb(nil)
        }.to raise_error(RuntimeError)

        expect {
          Fastlane::Helper::SymlinkHelper.auto_symlink_lldb("something/that/does/not/exist")
        }.to raise_error(RuntimeError)
      end
    end

    context "with valid destination_path" do
      it "should successfully create the symlink" do
        destination_path = Dir.mktmpdir("destination-test")
        expected_symlink = Fastlane::Helper::SymlinkHelper.active_lldb_path("#{%x(xcrun xcode-select --print-path)}".chomp)

        Fastlane::Helper::SymlinkHelper.auto_symlink_lldb(destination_path)

        verify_symlink_exists(expected_symlink, destination_path)
      end
    end
  end

  context "when active_lldb_path is called" do
    context "and xcode_path ends with `Developer`" do
      it "should return the correct path" do
        xcode_path = "some_path/Developer"
        expected_path = "some_path/SharedFrameworks/LLDB.framework"

        active_lldb_path = Fastlane::Helper::SymlinkHelper.active_lldb_path(xcode_path)

        expect(active_lldb_path).to eql(expected_path)
      end
    end

    context "and xcode_path ends with `CommandLineTools`" do
      it "should return the correct path" do
        xcode_path = "some_path/CommandLineTools"
        expected_path = "some_path/CommandLineTools/Library/PrivateFrameworks/LLDB.framework"

        active_lldb_path = Fastlane::Helper::SymlinkHelper.active_lldb_path(xcode_path)

        expect(active_lldb_path).to eql(expected_path)
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
