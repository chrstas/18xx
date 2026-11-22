# frozen_string_literal: true

require_relative '../../../step/track'
require_relative 'tracker'

module Engine
  module Game
    module G18HN
      module Step
        class Track < Engine::Step::Track
          include G18HN::Tracker

          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)
            return nil if @game.frankfurt_track_blocked?(hex)

            super
          end

          def process_lay_tile(action)
            check_track_rights!(action.entity, action.hex)
            super
            @game.check_obligations!
          end
        end
      end
    end
  end
end
