# frozen_string_literal: true

require_relative '../../../round/operating'

module Engine
  module Game
    module G18HN
      module Round
        class Operating < Engine::Round::Operating
          # 8.2: the privates act before the first company operates
          def after_setup
            super unless @steps.any? { |step| step.is_a?(G18HN::Step::FrankfurtTrack) && step.blocks? }
          end

          def name
            @game.auction_paused? ? 'Short Operating Round' : super
          end

          # 8.2 / ch. 6: the privates' turn ends when the first company starts or, without a company, once FL has acted
          def start_operating
            @privates_acted = true
            super unless no_company?
          end

          def privates_acted?
            @privates_acted
          end

          def finished?
            return !active_step if no_company?

            super
          end

          def after_process(action)
            super unless no_company?
            # 8.5: after super no active step means the whole OR is over, so exchange before the game end check
            @game.forced_exchanges! unless active_step
          end

          def skip_steps
            super unless no_company?
          end

          private

          def no_company?
            @entities.empty?
          end
        end
      end
    end
  end
end
