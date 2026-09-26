# frozen_string_literal: true

module Engine
  module Game
    module G18HN
      module G18HNSpecHelpers
        # Builds a fresh game; no fixture, no actions replayed.
        def build_game(players: 3, optional_rules: [])
          Engine::Game::G18HN::Game.new(%w[a b c d e].first(players), optional_rules: optional_rules)
        end

        # Advances the phase by calling Phase#next! until the target name is reached.
        def advance_to_phase(game, target)
          game.phase.next! until game.phase.name == target
        end
      end
    end
  end
end
