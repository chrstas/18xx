# frozen_string_literal: true

require_relative '../../../step/buy_train'

module Engine
  module Game
    module G18HN
      module Step
        class BuyTrain < Engine::Step::BuyTrain
          # 8.4.6: a traded train keeps its normal or plus type
          def process_buy_train(action)
            train = action.train
            if train.owned_by_corporation? && action.variant && action.variant != train.name
              raise GameError, "Not a buyable train: #{train.id}"
            end

            super
            # 8.4: buying a train ends the building, so no bridge after it
            @game.close_bridge_window(action.entity)
            @game.deferred_president_change!(action.entity) if @corporations_sold.include?(action.entity)
          end

          # 8.4.7: a director sells shares in the train step only for a forced buy
          def can_ebuy_sell_shares?(entity)
            must_buy_train?(entity) && super
          end

          def causes_president_swap?(corporation, bundle)
            return false if @game.deferred_presidency?(bundle)

            super
          end

          # 7.2: a corporation that never operated pays one step below, so the next smaller bundle counts at that price
          def selling_minimum_shares?(bundle)
            return super if bundle.corporation.operated?

            smallest = bundle.shares.map(&:percent).min
            next_smaller = bundle.price - (bundle.price_per_share * smallest / bundle.corporation.share_percent)
            next_smaller < needed_cash(bundle.owner) - available_cash(bundle.owner)
          end

          # 8.4.7: after an emergency sale only variants that needed the sale stay buyable
          def buyable_train_variants(train, entity)
            variants = super
            return variants if variants.size < 2 || train.owned_by_corporation? || !@last_share_sold_price

            must_spend = entity.cash + entity.owner.cash - @last_share_sold_price + 1
            variants.reject { |v| v[:price] < must_spend }
          end

          # 8.4.7: in a forced buy the price for another company's train has no upper limit
          def spend_minmax(entity, train)
            return super unless must_buy_train?(entity)

            max = buying_power(entity) + entity.owner.cash
            min = @last_share_sold_price ? max - @last_share_sold_price + 1 : 1
            [min, max]
          end

          # 8.4.7: after an emergency sale another company's train stays buyable above the minimum
          def buyable_trains(entity)
            trains = super
            return trains if !@last_share_sold_price || !must_buy_train?(entity)

            trains | other_trains(entity)
          end
        end
      end
    end
  end
end
