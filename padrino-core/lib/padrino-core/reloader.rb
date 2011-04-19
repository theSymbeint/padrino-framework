require 'pathname'

module Padrino
  ##
  # High performance source code reloader based on fork
  #
  module Reloader
    MTIMES = {}
    class << self
      ##
      # Specified folders can be excluded from the code reload detection process.
      # Default excluded directories at Padrino.root are: test, spec, features, tmp, config, db and public
      #
      def exclude
        @_exclude ||= %w(test spec tmp features config public db)
      end

      def start!
        unless Kernel.respond_to?(:fork)
          puts "<= Your ruby env doesn't support fork so reloading is not available!"
          return
        end

        if Padrino.env == :production
          puts "<= Reloader is not enabled in production environment"
          return
        end


        # Enable REE garbage collection
        if GC.respond_to?(:copy_on_write_friendly=)
          GC.copy_on_write_friendly = true
        end

        puts "=> Parent pid: #{Process.pid}"

        loop do
          pid = fork

          # If we don't have the pid we are not in the child process.
          break unless pid

          # Add some traps to our worker
          trap(:INT) do
            begin
              Process.kill(:KILL, pid)
            rescue SystemCallError
            end
            # Process.waitall
          end

          trap(:HUP) { Process.kill(:HUP, pid) }

          loop do
            # Waits for a child process to exit. Process::WNOHANG: do not block if no child available
            # Process::WNOHANG flag is not available on all platforms
            begin
              p, status = Process.wait2(pid, Process::WNOHANG)
              status.exitstatus == 18 ? break : exit(status) if status
            rescue Errno::ECHILD
            end
          end
        end

        # Some traps to our worker
        trap(:ABRT) { exit(0) }
        trap(:HUP)  { reload! }
      end

      def reload!
        exit(18)
      end

      def watch!
        return if Padrino.env == :production
        Thread.new do
          GC.start
          loop do
            Dir[Padrino.root("**/*.rb")].each do |file|
              file = File.expand_path(file)
              if MTIMES[file].blank?
                next if exclude.any? { |e| file =~ /^#{Padrino.root(e)}/ }
                logger.debug "Detected new file #{file}"
                Padrino.require_dependencies(file)
                reload!
              elsif MTIMES[file] < File.mtime(file)
                logger.debug "Reloading app because #{file} changed"
                reload!
              end
            end
            sleep 0.5
          end
          Thread.exit
        end
      end
    end # self
  end # Reloader
end # Padrino