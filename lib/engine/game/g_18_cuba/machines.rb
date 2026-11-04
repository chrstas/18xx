# frozen_string_literal: true

module Engine
  module Game
    module G18Cuba
      module Machines
        MACHINE_BONUS = { yellow: 10, green: 20, brown: 40 }.freeze

        def machines_setup
          @machines = {}
        end

        def add_machine(corporation, generation)
          (@machines[corporation] ||= []) << generation
        end

        def extra_revenue(entity, routes)
          return 0 if routes.empty?

          @machines.fetch(entity, []).sum { |generation| MACHINE_BONUS[generation] }
        end
      end
    end
  end
end
