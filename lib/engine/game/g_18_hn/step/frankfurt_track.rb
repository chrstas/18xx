# frozen_string_literal: true

require_relative 'special_track'

module Engine
  module Game
    module G18HN
      module Step
        # 5.3 / 8.2: FL may lay one Frankfurt tile at the start of each OR, before its income is paid
        class FrankfurtTrack < SpecialTrack
          ACTIONS = %w[lay_tile pass].freeze

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

          def abilities(entity, **kwargs, &block)
            return unless entity == @game.company_by_id('FL')

            @game.abilities(entity, :tile_lay, time: 'any', **kwargs, &block)
          end

          def process_lay_tile(action)
            super
            # 8.2: the raised income is paid in this OR, on top of the old one paid at its start
            owner = action.entity.owner
            @game.bank.spend(FRANKFURT_INCOME, owner)
            @log << "#{owner.name} collects #{@game.format_currency(FRANKFURT_INCOME)} from #{action.entity.name}"
            @round.start_operating
          end

          def process_pass(action)
            @log << "#{action.entity.owner.name} passes the Frankfurt tile of #{action.entity.name}"
            @round.start_operating
          end

          private

          def pending_company
            # 8.2: only before the first company operates
            return if @round.privates_acted?

            fl = @game.company_by_id('FL')
            # ch. 6: an unsold FL does not lay in the short OR of the initial auction
            return unless fl.owner&.player?

            fl if @game.class::FRANKFURT_HEXES.any? { |id| !potential_tiles(fl, @game.hex_by_id(id)).empty? }
          end
        end
      end
    end
  end
end
