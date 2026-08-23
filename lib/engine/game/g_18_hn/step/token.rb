# frozen_string_literal: true

require_relative '../../../step/tokener'
require_relative '../../../step/token'

module Engine
  module Game
    module G18HN
      module Step
        class Token < Engine::Step::Token
          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)
            return nil if @game.token_blocked_hex?(hex)

            super
          end

          def process_place_token(action)
            entity = action.entity
            hex = action.city.hex
            unless @game.hex_operating_rights?(entity, hex)
              raise GameError, 'Cannot place token without operating rights in the selected region'
            end
            raise GameError, "Cannot place a token in #{hex.tile.location_name}" if @game.token_blocked_hex?(hex)

            super
          end
        end
      end
    end
  end
end
