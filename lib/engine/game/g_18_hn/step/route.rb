# frozen_string_literal: true

require_relative '../../../step/route'

module Engine
  module Game
    module G18HN
      module Step
        class Route < Engine::Step::Route
          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex) || @game.national_hexes('ALL').include?(hex.name)

            super
          end
        end
      end
    end
  end
end
