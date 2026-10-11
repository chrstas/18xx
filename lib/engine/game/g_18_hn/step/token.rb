# frozen_string_literal: true

require_relative '../../../step/tokener'
require_relative '../../../step/token'

module Engine
  module Game
    module G18HN
      module Step
        class Token < Engine::Step::Token
          # 8.4.4: the Hanau station of FHB is placed by the FB exchange only
          def available_tokens(entity)
            super.reject { |token| token.type == :hanau }
          end

          # 8.4.4: open only for a free city the company may take, Frankfurt or Wetzlar alone do not count
          def can_place_token?(entity)
            super && takeable_city?(entity)
          end

          def takeable_city?(entity)
            tokens = available_tokens(entity)
            @game.token_graph_for_entity(entity).connected_nodes(entity).keys.any? do |node|
              node.city? && node.tokenable?(entity, free: true, tokens: tokens) && available_hex(entity, node.hex)
            end
          end

          # 8.4.4: an action naming the Hanau station is refused, the FB exchange places it
          def process_place_token(action)
            raise GameError, "#{action.entity.name} cannot place its Hanau station by hand" if action.token&.type == :hanau

            super
            @game.close_bridge_window(action.entity)
          end

          def available_hex(entity, hex)
            return nil unless @game.hex_operating_rights?(entity, hex)
            return nil if @game.token_blocked_hex?(hex)
            # 8.4.4: Hanau stays free for the Hanau station until FB is exchanged
            return nil if hex.id == @game.class::HANAU_HEX && entity.find_token_by_type(:hanau)

            super
          end
        end
      end
    end
  end
end
