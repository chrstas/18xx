# frozen_string_literal: true

require_relative '../../../step/base'
require_relative '../../../step/share_buying'

module Engine
  module Game
    module G18HN
      module Step
        class Exchange < Engine::Step::Base
          include Engine::Step::ShareBuying

          ACTIONS = %w[choose].freeze
          CHOICES = { exchange: 'Exchange', decline: 'Decline' }.freeze

          def actions(entity)
            return [] unless entity == current_entity
            return [] unless can_exchange?(entity)

            ACTIONS
          end

          def description
            'Exchange'
          end

          # 5.3 / 8.1: privates can be exchanged from the green phase on
          def can_exchange?(entity)
            return false unless @game.phase.available?('3')
            return false unless (share = @game.exchange_share(entity))

            can_gain?(entity.owner, share.to_bundle, exchange: true)
          end

          def choice_name
            "Exchange #{current_entity.id} for a #{@game.exchange_share(current_entity).corporation.id} share"
          end

          def choices
            CHOICES.values
          end

          def log_skip(entity)
            super if @game.phase.available?('3')
          end

          def process_choose(action)
            entity = action.entity
            if action.choice == CHOICES[:exchange]
              @game.exchange_private!(entity)
            else
              @log << "#{entity.id} declines exchange"
              pass!
            end
          end
        end
      end
    end
  end
end
