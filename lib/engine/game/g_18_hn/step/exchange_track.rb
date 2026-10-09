# frozen_string_literal: true

require_relative 'special_track'

module Engine
  module Game
    module G18HN
      module Step
        # 5.3: BE, TB and OB lay their special tile right after the exchange, before they close
        class ExchangeTrack < SpecialTrack
          ACTIONS = %w[lay_tile].freeze

          def actions(entity)
            return [] unless entity == @round.exchanged_company

            ACTIONS
          end

          def description
            "Lay Track for #{@round.exchanged_company.name}"
          end

          def blocks?
            @round.exchanged_company
          end

          def round_state
            super.merge(exchanged_company: nil)
          end

          def abilities(entity, **kwargs, &block)
            return unless entity == @round.exchanged_company

            @game.abilities(entity, :tile_lay, time: 'exchange', **kwargs, &block)
          end

          def process_lay_tile(action)
            super
            @round.exchanged_company = nil
            action.entity.close!
          end
        end
      end
    end
  end
end
