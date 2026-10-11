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
            bridges = @game.buildable_bridges(entity)
            paid = paid_bridge?(entity) ? bridges.map { |index| bridge_items[index] } : []
            free = @game.free_bridge?(entity) ? bridges.map { |index| free_bridge_items[index] } : []
            rights + paid + free
          end

          def short_description
            'Concessions, Rights & Bridges'
          end

          def process_special_buy(action)
            return process_bridge(action, bridge_items.index(action.item), false) if bridge_items.include?(action.item)
            return process_bridge(action, free_bridge_items.index(action.item), true) if free_bridge_items.include?(action.item)

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
            @free_bridge_items ||= @game.class::BRIDGES.each_index.map do |index|
              Item.new(description: "Bridge #{@game.bridge_name(index)} (free)", cost: 0)
            end
          end

          private

          attr_reader :concession_items, :bridge_items, :free_bridge_items

          def paid_bridge?(entity)
            @game.buying_power(entity) >= @game.class::BRIDGE_COST
          end

          def process_bridge(action, index, free)
            entity = action.entity
            allowed = @game.buildable_bridges(entity).include?(index) &&
                      (free ? @game.free_bridge?(entity) : paid_bridge?(entity))
            raise GameError, "#{entity.name} cannot build the #{action.item.description}" if !@game.loading && !allowed

            @game.build_bridge(entity, index, free: free)
          end
        end
      end
    end
  end
end
