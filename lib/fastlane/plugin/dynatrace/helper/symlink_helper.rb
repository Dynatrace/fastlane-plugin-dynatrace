module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class SymlinkHelper
      def self.path_exists?(path)
        unless path.nil?
          return Dir.exist?(path) || File.exist?(path)
        end
        return false
      end

      def self.symlink_lldb(lldb_path, destination_path)
        require_path(destination_path)
        require_path(lldb_path)
        UI.message "Starting process to create symlink of custom LLDB Framework at: #{destination_path}"
        symlink(lldb_path, destination_path)
      end

      def self.auto_symlink_lldb(destination_path)
        require_path(destination_path)
        UI.message "Starting process to auto-symlink LLDB framework at: #{destination_path}"
        current_xcode_path = %x(xcrun xcode-select --print-path).chomp
        active_lldb_path = active_lldb_path(current_xcode_path)
        UI.message "LLDB framework found at: #{active_lldb_path}"
        symlink(active_lldb_path, destination_path)
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

      def self.symlink(source, destination)
        UI.message "Creating a symlink of #{source} at #{destination}"
        %x(ln -s #{source} #{destination})
      end

      def self.active_lldb_path(xcode_path)
        if xcode_path.end_with? "/Developer"
          parent_dir = File.dirname(xcode_path)
          return "#{parent_dir}/SharedFrameworks/LLDB.framework"
        end

        if xcode_path.end_with? "/CommandLineTools"
          return "#{xcode_path}/Library/PrivateFrameworks/LLDB.framework"
        end
      end

      private_class_method :require_path, :symlink
    end
  end
end