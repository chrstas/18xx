# frozen_string_literal: true

require_relative '../../../step/tokener'
require_relative '../../../step/token'

module Engine
  module Game
    module G18HN
      module Step
        class Token < Engine::Step::Token
          def actions(entity)
            super
          end

          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)

            super
          end

          def process_place_token(action)
            entity = action.entity
            hex = action.city.hex
            unless @game.hex_operating_rights?(entity, hex)
              raise GameError, 'Cannot place token without operating rights in the selected region'
            end

            super
          end
        end
      end
    end
  end
end
