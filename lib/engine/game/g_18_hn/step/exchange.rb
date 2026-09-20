# frozen_string_literal: true

require_relative '../../../step/exchange'

module Engine
  module Game
    module G18HN
      module Step
        class Exchange < Engine::Step::Exchange
          # 7.1: an exchanged reserved share is ordinary stock and must be buyable from the pool
          def process_buy_shares(action)
            action.bundle.shares.each { |share| share.buyable = true }
            super
          end
        end
      end
    end
  end
end
