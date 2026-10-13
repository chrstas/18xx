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

          # ch. 6: the short OR of the initial auction has no company, it ends once FL has acted
          def start_operating
            return super unless @game.auction_paused?

            @privates_acted = true
          end

          def privates_acted?
            @privates_acted
          end

          def finished?
            return !active_step if @game.auction_paused?

            super
          end

          def after_process(action)
            super unless @game.auction_paused?
          end
        end
      end
    end
  end
end
