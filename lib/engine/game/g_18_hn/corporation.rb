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
      end
    end
  end
end
