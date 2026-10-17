# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18HN
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          # 10.2: a traded train keeps its normal or plus type
          def process_buy_train(action)
            train = action.train
            if train.owned_by_corporation? && action.variant && action.variant != train.name
              raise GameError, "Not a buyable train: #{train.id}"
            end

            super
          end

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
