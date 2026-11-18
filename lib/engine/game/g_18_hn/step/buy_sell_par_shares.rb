# frozen_string_literal: true

require_relative '../../../step/buy_sell_par_shares'

module Engine
  module Game
    module G18HN
      module Step
        class BuySellParShares < Engine::Step::BuySellParShares
          # 7.1: the 60 percent limit applies to shares from the IPO only
          def can_gain?(entity, bundle, exchange: false)
            return super unless bundle&.owner == @game.share_pool

            @game.num_certs(entity) < @game.cert_limit(entity)
          end
        end
      end
    end
  end
end
