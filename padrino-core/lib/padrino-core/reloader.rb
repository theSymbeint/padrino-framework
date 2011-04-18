require 'pathname'

module Padrino
  ##
  # High performance source code reloader based on fork
  #
  module Reloader
    class << self
      def start!
        unless Kernel.respond_to?(:fork)
          puts "<= Your ruby env doesn't support fork so reloading is not available!"
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
        trap(:ABRT) { reap }
        trap(:HUP)  { reap(18) }
      end

      def reload!
        reap(18)
      end

      def reap(status = 0)
        exit(status)
      end
    end # self
  end # Reloader
end # Padrino