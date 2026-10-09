# frozen_string_literal: true

require_relative '../../../step/exchange'

module Engine
  module Game
    module G18HN
      module Step
        class Exchange < Engine::Step::Exchange
          # 5.3 / 8.1: privates can be exchanged from the green phase on
          def can_exchange?(entity, bundle = nil)
            return false unless @game.phase.available?('3')

            super
          end

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
