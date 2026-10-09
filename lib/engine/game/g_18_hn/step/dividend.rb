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

          def round_state
            super.merge(non_paying_shares: Hash.new { |h, k| h[k] = Hash.new(0) })
          end
        end
      end
    end
  end
end
