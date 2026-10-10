# frozen_string_literal: true

require_relative '../../../step/base'

module Engine
  module Game
    module G18HN
      module Step
        class Exchange < Engine::Step::Base
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

            # 7.1: the 60 percent limit does not apply to an exchange
            !@game.exchange_share(entity).nil?
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
              if @game.abilities(entity, :tile_lay, time: 'exchange')
                @round.exchanged_companies << entity
              else
                entity.close!
              end
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
