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
        end
      end
    end
  end
end
