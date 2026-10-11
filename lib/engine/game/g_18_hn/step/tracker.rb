# frozen_string_literal: true

require_relative '../../../step/tracker'

module Engine
  module Game
    module G18HN
      module Tracker
        include Engine::Step::Tracker

        # 8.4.2: no track may lead into the Rhine or the Main estuary
        def hex_neighbor_exists?(entity, hex, edge)
          return false if @game.bridge_edges(hex).include?(edge)

          super
        end

        # the new tile need not keep a bridge path, lay_tile puts it back
        def legal_tile_rotation?(entity_or_entities, hex, tile)
          @game.without_bridge_paths(hex.tile) { super }
        end

        # 8.4.2: a built bridge stays when the tile on either side is replaced
        def lay_tile(action, **kwargs)
          @game.remove_bridge_paths!(action.hex.tile)
          super
        ensure
          @game.restore_bridge_paths(action.hex)
        end
      end
    end
  end
end
