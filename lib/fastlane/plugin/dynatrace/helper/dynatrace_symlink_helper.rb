module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class DynatraceSymlinkHelper
      @symlink_pattern = "*LLDB.framework"

      def self.path_exists?(path)
        unless path.nil?
          return Dir.exist?(path) || File.exist?(path)
        end
        return false
      end

      def self.symlink_custom_lldb(lldb_path, destination_path)
        require_path(destination_path)
        require_path(lldb_path)
        UI.message "Starting process to create symlink of custom LLDB Framework at: #{destination_path}"
        delete_existing_lldb_symlinks(destination_path)
        symlink(lldb_path, destination_path)
      end

      def self.auto_symlink_lldb(destination_path)
        require_path(destination_path)
        UI.message "Preparing to set up auto-symlink for LLDB framework to: #{destination_path}"
        current_xcode_path = %x(xcrun xcode-select --print-path).chomp
        active_lldb_path = active_lldb_path(current_xcode_path)
        unless active_lldb_path.nil?
          UI.message "LLDB framework found at: #{active_lldb_path}"
          delete_existing_lldb_symlinks(destination_path)
          symlink(active_lldb_path, destination_path)
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

      def self.delete_existing_lldb_symlinks(destination)
        Dir.glob("#{destination}/#{@symlink_pattern}").map do |file|
          if File.symlink?(file)
            UI.message "Deleting existing LLDB symlink: #{file}"
            FileUtils.rm(file)
          end
        end
      end

      def self.symlink(source, destination)
        UI.message "Creating a symlink of #{source} at #{destination}"
        FileUtils.symlink(source, destination)
      end

      def self.active_lldb_path(xcode_path)
        unless xcode_path.end_with? "/Developer"
          UI.important "Could not find proper Xcode path. It should end `.../Developer`, but got: #{xcode_path}"
          return nil
        end

        parent_dir = File.dirname(xcode_path)
        return "#{parent_dir}/SharedFrameworks/LLDB.framework"
      end

      private_class_method :require_path, :delete_existing_lldb_symlinks, :symlink
    end
  end
end