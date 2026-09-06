# frozen_string_literal: true

require_relative '../../../step/special_track'

module Engine
  module Game
    module G18HN
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          FRANKFURT_INCOME = 10

          def process_lay_tile(action)
            super
            add_frankfurt_income(action.entity)
          end

          private

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
