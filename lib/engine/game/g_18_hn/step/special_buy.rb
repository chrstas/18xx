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
            concession_items.select { |id, _item| @game.can_buy_right?(entity, id) }.values
          end

          def short_description
            'Concessions & Rights'
          end

          def process_special_buy(action)
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
          end

          private

          attr_reader :concession_items
        end
      end
    end
  end
end
