# frozen_string_literal: true

require_relative '../../../step/special_track'
require_relative 'tracker'

module Engine
  module Game
    module G18HN
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          include G18HN::Tracker

          FRANKFURT_INCOME = 10

          def available_hex(entity, hex)
            return super unless seidler?(entity)

            track_step.available_hex(@round.current_operator, hex)
          end

          def hex_neighbors(entity, hex)
            return super unless seidler?(entity)

            track_step.hex_neighbors(@round.current_operator, hex)
          end

          def process_lay_tile(action)
            check_track_rights!(@round.current_operator, action.hex) if seidler?(action.entity)
            super
            add_frankfurt_income(action.entity)
            @game.check_obligations!
          end

          private

          def seidler?(entity)
            entity == @game.company_by_id('SS')
          end

          def track_step
            @round.steps.find { |step| step.is_a?(G18HN::Step::Track) }
          end

          # 5.3: the FL earns 10 per Frankfurt tile it lays; the ability's count of 4 caps this at 40
          def add_frankfurt_income(company)
            return unless company == @game.company_by_id('FL')

            company.revenue += FRANKFURT_INCOME
            @log << "#{company.name} income increases to #{@game.format_currency(company.revenue)}"
          end
        end
      end
    end
  end
end
