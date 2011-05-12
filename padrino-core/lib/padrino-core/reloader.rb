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

      def enabled
        @_enabled ||= Kernel.respond_to?(:fork) && Padrino.env == :development
      end
      alias :enabled? :enabled

      def enable!
        @_enable = true
      end

      def disable!
        @_enable = false
      end

      def pids
        @_pids ||= []
      end

      def start!
        show_message and return unless enabled?

        loop do
          pid = fork

          # If we don't have the pid we are not in the child process.
          break unless pid

          pids << pid

          trap(:INT) do
            if @_exiting
              puts "\n<= Padrino has ended his set (crowd applauds)"
              exit(0)
            else
              Process.kill(5, pid) rescue exit(0)
            end
          end

          loop do
            ##
            # Waits for a child process to exit. Process::WNOHANG: do not block if no child available
            # Process::WNOHANG flag is not available on all platforms
            #
            begin
              p, status = Process.wait2(pid, Process::WNOHANG)
              if status && (status.termsig == 5 || status.exitstatus == 5)
                puts "\n<= Reloading ... or press CTRL+C to EXIT"
                @_exiting = true
                sleep 1.5
                @_exiting = false
                break
              end
            rescue Errno::ECHILD
            end
          end
        end
      end

      def running?
        pids.present?
      end

      def watch!
        return unless enabled?
        Thread.new do
          GC.start
          loop do
            Dir[Padrino.root("**/*.rb")].each do |file|
              file = File.expand_path(file)
              if MTIMES[file].blank?
                next if exclude.any? { |e| file =~ /^#{Regexp.quote(Padrino.root(e))}/ }
                logger.info "Detected new file #{file}"
                Padrino.require_dependencies(file)
                reload!
              elsif MTIMES[file] < File.mtime(file)
                logger.info "Reloading app because #{file} changed"
                reload!
              end
            end
            sleep 0.5
          end
          Thread.exit
        end
      end

      private
        def show_message
          logger.info "Reloader is not enabled in #{Padrino.env} environment, or your ruby version dosn't support forking"
        end
    end # self
  end # Reloader
end # Padrino