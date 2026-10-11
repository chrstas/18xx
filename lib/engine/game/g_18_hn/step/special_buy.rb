# frozen_string_literal: true

require_relative '../../../step/special_buy'

module Engine
  module Game
    module G18HN
      module Step
        class SpecialBuy < Engine::Step::SpecialBuy
          def actions(entity)
            return [] unless entity == current_entity

            super
          end

          def buyable_items(entity)
            rights = concession_items.select { |id, _item| @game.can_buy_right?(entity, id) }.values
            rights + @game.buildable_bridges(entity).map { |index| bridge_items[index] }
          end

          def short_description
            'Concessions, Rights & Bridges'
          end

          def process_special_buy(action)
            return process_bridge(action, bridge_items.index(action.item)) if bridge_items.include?(action.item)

            id, = concession_items.find { |_id, item| item == action.item }
            raise GameError, "Cannot buy unknown item: #{action.item.description}" unless id
            if !@game.loading && !@game.can_buy_right?(action.entity, id)
              raise GameError, "#{action.entity.name} cannot buy #{action.item.description}"
            end

            @game.buy_right(action.entity, id)
          end

          def setup
            super
            @concession_items ||= @game.concession_companies.transform_values do |company|
              Item.new(description: company.name, cost: @game.class::RIGHT_COST)
            end
            @bridge_items ||= @game.class::BRIDGES.each_index.map do |index|
              Item.new(description: "Bridge #{@game.bridge_name(index)}", cost: @game.class::BRIDGE_COST)
            end
          end

          private

          attr_reader :concession_items, :bridge_items

          def process_bridge(action, index)
            if !@game.loading && !@game.buildable_bridges(action.entity).include?(index)
              raise GameError, "#{action.entity.name} cannot build the #{action.item.description}"
            end

            @game.build_bridge(action.entity, index)
          end
        end
      end
    end
  end
end
