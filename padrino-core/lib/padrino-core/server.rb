module Padrino
  ##
  # Run the Padrino apps as a self-hosted server using:
  # thin, mongrel, webrick in that order.
  #
  # ==== Examples
  #
  #   Padrino.run! # with these defaults => host: "localhost", port: "3000", adapter: the first found
  #   Padrino.run!("localhost", "4000", "mongrel") # use => host: "localhost", port: "3000", adapter: "mongrel"
  #
  def self.run!(options={})
    Padrino.load!
    Server.start(Padrino.application, options)
  end

  ##
  # This module build a Padrino server
  #
  module Server
    def self.start(app, options={})
      options[:signals] = false
      port = options.delete(:port) || 3000
      host = options.delete(:host) || 'localhost'

      if Padrino::Reloader.running?
        logger.info "Restarted #{Padrino.env} on #{port} with Thin"
      else
        puts "=> Padrino/#{Padrino.version} has taken the stage #{Padrino.env} on #{port} with Thin"
      end

      Thin::Logging.silent = true
      server = Thin::Server.new(host, port, app, options)
      trap(:INT) { server.stop! }
      server.start!
    rescue RuntimeError => e
      if e.message =~ /no acceptor/
        if port < 1024 && RUBY_PLATFORM !~ /mswin|win|mingw/ && Process.uid != 0
          puts "=> Only root may open a priviledged port #{port}!"
        else
          puts "=> Someone is already performing on port #{port}!"
        end
      else
        raise e
      end
    rescue Errno::EADDRINUSE
      puts "=> Someone is already performing on port #{port}!"
    end
  end # Server
end # Padrino