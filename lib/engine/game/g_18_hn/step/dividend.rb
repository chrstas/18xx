# frozen_string_literal: true

require_relative '../../../step/dividend'

module Engine
  module Game
    module G18HN
      module Step
        class Dividend < Engine::Step::Dividend
          # 5.3: a share exchanged when brown starts pays no dividend in that OR
          def dividends_for_entity(entity, holder, per_share)
            ((holder.num_shares_of(entity, ceil: false) - @round.non_paying_shares[holder][entity]) * per_share).ceil
          end

          # 8.4.5: the dividend of pool shares stays with the bank
          def corporation_dividends(_entity, _per_share)
            0
          end

          def round_state
            super.merge(non_paying_shares: Hash.new { |h, k| h[k] = Hash.new(0) })
          end
        end
      end
    end
  end
end
