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
        end
      end
    end
  end
end
