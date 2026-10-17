# frozen_string_literal: true

module Engine
  module Game
    module G18HN
      module G18HNSpecHelpers
        # Builds a fresh game; no fixture, no actions replayed.
        def build_game(players: 3, optional_rules: [], id: 0)
          Engine::Game::G18HN::Game.new(%w[a b c d e].first(players), id: id, optional_rules: optional_rules)
        end

        # Advances the phase by calling Phase#next! until the target name is reached.
        def advance_to_phase(game, target)
          game.phase.next! until game.phase.name == target
        end

        def lay(entity, hex_id, tile_name, rotation)
          tile = game.tiles.find { |t| t.name == tile_name }
          act(Action::LayTile.new(entity, tile: tile, hex: game.hex_by_id(hex_id), rotation: rotation))
        end

        def build_bridge(entity, name)
          step = game.round.steps.find { |candidate| candidate.is_a?(G18HN::Step::SpecialBuy) }
          item = step.buyable_items(entity).find { |candidate| candidate.description == "Bridge #{name}" }
          act(Action::SpecialBuy.new(entity, item: item))
        end

        def single_route(train, connection_hexes)
          route = Engine::Route.new(game, game.phase, train, connection_hexes: connection_hexes, routes: [])
          route.routes = [route]
          route
        end
      end
    end
  end
end
