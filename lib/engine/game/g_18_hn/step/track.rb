# frozen_string_literal: true

require_relative '../../../step/track'

module Engine
  module Game
    module G18HN
      module Step
        class Track < Engine::Step::Track
          def actions(entity)
            super
          end

          def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
            tile = action.tile
            case tile.name
            when '921', '922'
              corp = @game.company_by_id('FL')
              corp.revenue += 10
              @log << 'FL revenue +10'
            when '923', '924'
              corp = @game.company_by_id('FL')
              corp.revenue += 10
            end
            super
          end

          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)

            super
          end
        end
      end
    end
  end
end
