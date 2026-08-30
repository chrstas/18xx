# frozen_string_literal: true

require_relative '../../corporation'

module Engine
  module Game
    module G18HN
      class Corporation < Engine::Corporation
        def initialize(sym:, name:, **opts)
          ipo_shares = opts[:ipo_shares] || []
          reserved_shares = opts[:reserved_shares] || []
          opts[:shares] = ipo_shares + reserved_shares if !ipo_shares.empty? || !reserved_shares.empty?
          super(sym: sym, name: name, **opts)

          reserved_shares.each do |share_percent|
            share = shares.reverse.find { |s| s.percent == share_percent && s.buyable }
            share.buyable = false
          end
        end

        def floated?
          return false unless @floatable

          @floated ||= (percent_to_float <= 0)
        end

        # a reserved share exchanged for a private counts towards the float
        def percent_to_float
          return 0 if @floated

          [@float_percent - (100 - percent_ipo), 0].max
        end

        def percent_ipo
          @ipo_owner.shares_by_corporation[self].sum(&:percent)
        end
      end
    end
  end
end
