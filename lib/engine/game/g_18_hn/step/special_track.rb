# frozen_string_literal: true

require_relative '../../../step/special_track'

module Engine
  module Game
    module G18HN
      module Step
        class SpecialTrack < Engine::Step::SpecialTrack
          FRANKFURT_INCOME = 10

          def lay_tile(action, extra_cost: 0, entity: nil, spender: nil)
            super
            add_frankfurt_income(action.entity)
          end

          private

          # 5.3: the FL private earns 10 for each Frankfurt tile it lays, max 40
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
