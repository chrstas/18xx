# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G18HN
      module Meta
        include Game::Meta

        DEV_STAGE = :prealpha
        PROTOTYPE = true

        GAME_DISPLAY_TITLE = '18HN'

        GAME_DESIGNER = 'Karsten Ockenfels and Dirk Steiner'
        GAME_IMPLEMENTER = 'bsnrl and Volker Schnell'
        GAME_INFO_URL = 'https://github.com/tobymao/18xx/wiki/18HN'
        GAME_LOCATION = 'Hesse, Germany'
        GAME_PUBLISHER = nil
        GAME_RULES_URL = 'https://github.com/tobymao/18xx/wiki/18HN'
        GAME_SUBTITLE = 'Hessen & Nassau'
        GAME_TITLE = '18HN'

        PLAYER_RANGE = [3, 5].freeze
        OPTIONAL_RULES = [
          {
            sym: :Seidler,
            short_name: 'Seidler & Siebrecht',
            desc: 'new minor, allow one building with costs',
          },
        ].freeze
      end
    end
  end
end
