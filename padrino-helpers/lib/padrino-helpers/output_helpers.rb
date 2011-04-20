module Padrino
  module Helpers
    module OutputHelpers

      def self.engine
        @_engine ||= {}
      end

      engine[:haml]   = "!= capture_haml(*args, &block)"
      engine[:erb]    = "<% yield(*args) %>"
      engine[:erubis] = "<%= yield(*args) %>"
      engine[:slim]   = "== yield(*args)"

      ##
      # Captures the html from a block of template code for any available handler
      #
      # ==== Examples
      #
      #   capture_html(&block) => "...html..."
      #
      def capture(*args, &block)
        render(current_engine, Padrino::Helpers::OutputHelpers.engine[@current_engine], { :layout => false }, :args => args, :block => block, &block)
      end
      alias :capture_html :capture

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
    end # OutputHelpers
  end # Helpers
end # Padrino