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
            return [] unless entity == pending_company

            ACTIONS
          end

          def description
            "Lay Track for #{pending_company.name}"
          end

          def blocks?
            pending_company
          end

          def active_entities
            pending_company ? [pending_company] : super
          end

          def round_state
            super.merge(exchanged_companies: [])
          end

          def abilities(entity, **kwargs, &block)
            return unless entity == pending_company

            @game.abilities(entity, :tile_lay, time: 'exchange', **kwargs, &block)
          end

          def process_lay_tile(action)
            super
            @round.exchanged_companies.shift
            action.entity.close!
          end

          private

          def pending_company
            @round.exchanged_companies.first
          end
        end
      end
    end
  end
end
