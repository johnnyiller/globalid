require 'global_id'
require 'active_support/message_verifier'

class SignedGlobalID < GlobalID
  class << self
    attr_accessor :verifier

    def parse(sgid, options = {})
      if sgid.is_a? self
        sgid
      else
        super verify(sgid, options)
      end
    end

    # Grab the verifier from options and fall back to SignedGlobalID.verifier.
    # Raise ArgumentError if neither is available.
    def pick_verifier(options)
      options.fetch :verifier do
        verifier || raise(ArgumentError, 'Pass a `verifier:` option with an `ActiveSupport::MessageVerifier` instance, or set a default SignedGlobalID.verifier.')
      end
    end

    DEFAULT_PURPOSE = "default"

    def pick_purpose(options)
      options.fetch :for, DEFAULT_PURPOSE
    end

    private
      def verify(sgid, options)
        gid, parsed_purpose = pick_verifier(options).verify(sgid)
        gid if pick_purpose(options) == parsed_purpose
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end
  end

  attr_reader :verifier, :purpose

  def initialize(gid, options = {})
    super
    @verifier = self.class.pick_verifier(options)
    @purpose = self.class.pick_purpose(options)
  end

  def to_s
    @sgid ||= @verifier.generate([super, @purpose])
  end
  alias to_param to_s

  def ==(other)
    super && @purpose == other.purpose
  end
end
