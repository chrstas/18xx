# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18HN
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          # 7.2: a corporation that never operated pays one step below, so the next smaller bundle counts at that price
          def selling_minimum_shares?(bundle)
            return super if bundle.corporation.operated?

            smallest = bundle.shares.map(&:percent).min
            next_smaller = bundle.price - (bundle.price_per_share * smallest / bundle.corporation.share_percent)
            next_smaller < needed_cash(bundle.owner) - available_cash(bundle.owner)
          end
        end
      end
    end
  end
end
