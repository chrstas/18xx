# frozen_string_literal: true

require_relative '../meta'

module Engine
  module Game
    module G18HN
      module Meta
        include Game::Meta

        DEV_STAGE = :prealpha
        PROTOTYPE = true

        GAME_DESIGNER = 'Karsten Ockenfels and Dirk Steiner'
        GAME_IMPLEMENTER = 'bsnrl, Volker Schnell and Christian Stasius'
        GAME_LOCATION = 'Hesse, Germany'
        GAME_PUBLISHER = nil
        GAME_RULES_URL = 'https://boardgamegeek.com/filepage/322816/rulebook-en'
        GAME_SUBTITLE = 'Hessen & Nassau'
        GAME_TITLE = '18HN'

        PLAYER_RANGE = [3, 5].freeze
        OPTIONAL_RULES = [
          {
            sym: :Seidler,
            short_name: 'Seidler & Siebrecht',
            desc: 'Adds the private Seidler & Siebrecht to the auction; each player starts with 10 more',
          },
        ].freeze
      end
    end
  end
end
