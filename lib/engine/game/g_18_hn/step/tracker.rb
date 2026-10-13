# frozen_string_literal: true

require_relative '../../../step/tracker'

module Engine
  module Game
    module G18HN
      module Tracker
        # no include of Engine::Step::Tracker: the host steps have it, and Opal would insert it a second time

        # 8.4.2: no track may lead into the Rhine or the Main estuary
        def hex_neighbor_exists?(entity, hex, edge)
          return false if @game.bridge_edges(hex).include?(edge)

          super
        end

        # every exit of a city or town tile joins its node, and lay_tile puts the bridge path back on
        def hex_neighbors(entity, hex)
          edges = super
          bridges = @game.built_bridge_edges(hex)
          return edges if !edges || (edges & bridges).empty?

          nodes = @game.graph_for_entity(entity).connected_nodes(entity)
          return edges if hex.tile.city_towns.none? { |node| nodes[node] }

          (edges | hex.neighbors.keys) - bridges
        end

        # the new tile need not keep a bridge path, lay_tile puts it back
        def legal_tile_rotation?(entity_or_entities, hex, tile)
          # build the graph before the bridge path is hidden, or it is cached without the bridge
          hex_neighbors(Array(entity_or_entities).first, hex)
          @game.without_bridge_paths(hex.tile) { super }
        end

        # 8.4.2: a built bridge stays when the tile on either side is replaced
        def lay_tile(action, **kwargs)
          # build the graph while the bridge path is still on the tile, as in legal_tile_rotation?
          hex_neighbors(action.entity, action.hex)
          @game.remove_bridge_paths!(action.hex.tile)
          super
        ensure
          @game.restore_bridge_paths(action.hex)
        end
      end
    end
  end
end
