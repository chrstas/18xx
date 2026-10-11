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

          def round_state
            super.merge(frankfurt_decided: false)
          end

          def setup
            super
            # 5.3 / 8.2: FL is asked only at the start of the OR, a later phase change opens nothing
            @round.frankfurt_decided ||= !pending_company
          end

          def abilities(entity, **kwargs, &block)
            return unless entity == @game.company_by_id('FL')

            @game.abilities(entity, :tile_lay, time: 'or_start', strict_time: false, **kwargs, &block)
          end

          def process_lay_tile(action)
            super
            @round.frankfurt_decided = true
            # 8.2: the raised income is paid in this OR, on top of the old one paid at its start
            owner = action.entity.owner
            @game.bank.spend(FRANKFURT_INCOME, owner)
            @log << "#{owner.name} collects #{@game.format_currency(FRANKFURT_INCOME)} from #{action.entity.name}"
          end

          def process_pass(action)
            @log << "#{action.entity.owner.name} passes the Frankfurt tile of #{action.entity.name}"
            @round.frankfurt_decided = true
          end

          private

          def pending_company
            return if @round.frankfurt_decided

            fl = @game.company_by_id('FL')
            return if fl.closed?

            # not @game.abilities: it asks blocks? of this step again via ability_blocking_step
            return unless (ability = fl.all_abilities.find { |a| a.type == :tile_lay })

            fl if @game.class::FRANKFURT_HEXES.any? { |id| fits?(ability, @game.hex_by_id(id)) }
          end

          def fits?(ability, hex)
            @game.tiles.any? do |tile|
              ability.tiles.include?(tile.name) &&
                @game.tile_valid_for_phase?(tile, hex: hex) &&
                @game.upgrades_to?(hex.tile, tile)
            end
          end
        end
      end
    end
  end
end
