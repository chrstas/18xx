# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G18HN
      module Step
        class Track < Engine::Step::Track
          def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
            if %w[921 922 923 924].include?(action.tile.name)
              @game.company_by_id('FL').revenue += 10
              @log << 'FL revenue +10'
            end
            super
          end

          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)
            return nil if @game.frankfurt_track_blocked?(hex)

            super
          end

          def process_lay_tile(action)
            entity = action.entity
            hex = action.hex
            unless @game.hex_operating_rights?(entity, hex)
              raise GameError, 'Cannot lay track without operating rights in the selected region'
            end
            raise GameError, 'Only the FL private may build in Frankfurt' if @game.frankfurt_track_blocked?(hex)

            super
          end
        end
      end
    end
  end
end
