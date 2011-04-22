module Padrino
  module Helpers
    module OutputHelpers
      ##
      # Set the method to capture html
      #
      # ==== Examples:
      #
      #   engine[:erubis] = "<%= yield(*args) %>"
      #   engine[:erb]    = "<% yield(*args) %>"
      #   engine[:slim]   = "== yield(*args)"
      #   engine[:haml]   = "!= capture_haml(*args, &block)"
      #
      def self.engine
        @_engine ||= {}
      end

      engine[:erubis] = "<%= yield(*args) %>"
      engine[:erb]    = "<% yield(*args) %>"
      engine[:slim]   = "== yield(*args)"
      engine[:haml]   = "!= capture_haml(*args, &block)"

      ##
      # Captures the html from a block of template code for any available handler
      #
      # ==== Examples
      #
      #   capture_html(&block) => "...html..."
      #
      def capture(*args, &block)
        # We use the sinatra render method to capture blocks.
        #
        #  Is something like:
        #
        #   render :erb, "<% yield %>" do
        #     <h1>I a block</h1>
        #
        eval '_buf, @_buf_was = "", _buf if defined?(_buf)', block.binding
        render(@current_engine, Padrino::Helpers::OutputHelpers.engine[@current_engine], { :layout => false }, :args => args, :block => block, &block)
      rescue NoMethodError
        # Invoking the block directly if we are not inside a sinatra/padrino application
        block.call(*args)
      ensure
        eval '_buf = @_buf_was if defined?(_buf)', block.binding
      end
      alias :capture_html :capture

      ##
      # Outputs the given text to the templates buffer directly
      #
      # ==== Examples
      #
      #   concat("This will be output to the template buffer")
      #
      def concat(content)
        case @current_engine
          when :haml                then haml_concat(content)
          when :erb, :erubis, :slim then @_out_buf << content
        end
      end
      alias :concat_html    :concat
      alias :concat_content :concat

      ##
      # Capture a block or text of content to be rendered at a later time.
      # Your blocks can also receive values, which are passed to them by <tt>yield_content</tt>
      #
      # ==== Examples
      #
      #   content_for(:name) { ...content... }
      #   content_for(:name) { |name| ...content... }
      #   content_for(:name, "I'm Jeff")
      #
      def content_for(key, content = nil, &block)
        content_blocks[key.to_sym] << (block_given? ? block : Proc.new { content })
      end

      ##
      # Render the captured content blocks for a given key.
      # You can also pass values to the content blocks by passing them
      # as arguments after the key.
      #
      # ==== Examples
      #
      #   yield_content :include
      #   yield_content :head, "param1", "param2"
      #   yield_content(:title) || "My page title"
      #
      def yield_content(key, *args)
        content_blocks[key.to_sym].map { |b| capture(*args, &b) }.join
      end

      protected
        ##
        # Retrieves content_blocks stored by content_for or within yield_content
        #
        # ==== Examples
        #
        #   content_blocks[:name] => ['...', '...']
        #
        def content_blocks
          @content_blocks ||= Hash.new {|h,k| h[k] = [] }
        end

      private
        ##
        # Capture from a pure sinatra app the engine used in the template
        # or if we are in a padrino application we use that.
        #
        def render(engine, *)
          @current_engine = engine # Sinatra use this: render :haml, but padrino can use this: render "/form/mine"
          super
          # So, now if we are under padrino @current_engine is overwritten from our custom render method
        end
    end # OutputHelpers
  end # Helpers
end # Padrino

# Make slim works with sinatra/padrino
Slim::Engine.set_default_options :buffer => '@_out_buf', :auto_escape => false if defined?(Slim)