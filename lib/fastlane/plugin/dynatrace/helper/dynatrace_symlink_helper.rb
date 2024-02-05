module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DynatraceSymlinkHelper
      def self.path_exists?(path)
        unless path.nil?
          return Dir.exist?(path) || File.exist?(path)
        end
        return false
      end

      def self.symlink_custom_lldb(lldb_path, destination_path)
        require_path(destination_path)
        require_path(lldb_path)
        UI.message "Preparing to symlink custom LLDB framework path to: #{destination_path}"
        symlink(lldb_path, destination_path)
      end

      def self.auto_symlink_lldb(destination_path)
        require_path(destination_path)
        UI.message "Preparing to automatically symlink LLDB framework path to: #{destination_path}"
        current_xcode_path = %x(xcrun xcode-select --print-path).chomp
        active_lldb_path = active_lldb_path(current_xcode_path)
        unless active_lldb_path.nil?
          UI.message "LLDB framework found at: #{active_lldb_path}"
          symlink(active_lldb_path, destination_path)
        end
      end

      def self.delete_existing_lldb_symlinks(destination_path)
        symlink_path = make_symlink_path_name(destination_path)
        if path_exists?(symlink_path) and File.symlink?(symlink_path)
          UI.message "Deleting existing LLDB symlink: #{file}"
          FileUtils.rm(symlink_path)
        else
          UI.message "No existing LLDB symlink at destination: #{symlink_path}"
        end
      end

      def self.require_path(path)
        if path.nil?
          raise "Path should not be nil."
        end

        unless path.instance_of?(String)
          raise "Path should be a string."
        end

        unless path_exists?(path)
          raise "Path: #{path} does not exist."
        end
      end

      def self.symlink(source, destination_path)
        destination = make_symlink_path_name(destination_path)
        UI.message "Creating a symlink of #{source} at #{destination}"
        puts "################ Creating a symlink of #{source} at #{destination}"
        FileUtils.symlink(source, destination)
      end

      def self.active_lldb_path(xcode_path)
        unless xcode_path.end_with? "/Developer"
          UI.important "Could not find proper Xcode path. It should end `.../Developer`, but got: #{xcode_path}"
          return nil
        end

        parent_dir = File.dirname(xcode_path)
        return File.join(parent_dir, "SharedFrameworks", "LLDB.framework")
      end

      def self.make_symlink_path_name(destination_path)
        File.join(destination_path, "LLDB.framework")
      end

      private_class_method :require_path, :symlink, :make_symlink_path_name
    end
  end
end