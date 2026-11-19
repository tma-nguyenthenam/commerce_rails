module TrainingAdminEngine
  module Api
    module V1
      class DashboardController < ActionController::API
        def stats
          current   = period_range(0)
          previous  = period_range(1)

          logger.info "Get dashboard stats..."
          logger.info current

          revenue_now  = Order.where(created_at: current).sum(:total)
          revenue_prev = Order.where(created_at: previous).sum(:total)

          orders_now  = Order.where(created_at: current).count
          orders_prev = Order.where(created_at: previous).count

          customers_now  = User.where(created_at: current).count
          customers_prev = User.where(created_at: previous).count

          # refunds_now  = Refund.where(created_at: current).sum(:amount)
          # refunds_prev = Refund.where(created_at: previous).sum(:amount)

          render json: {
            stats: [
              build_stat("Total Revenue", revenue_now, revenue_prev, format: :currency),
              build_stat("Orders",        orders_now,  orders_prev,  format: :number),
              build_stat("Customers",     customers_now, customers_prev, format: :number),
              # build_stat("Refunds",       refunds_now, refunds_prev, format: :currency, invert_trend: true)
            ]
          }
        end

        def orders
          orders = Order
                     .includes(:user, items: :product)
                     .order(id: :desc)
                     .limit(100)
        
          rows = orders.flat_map { |order| flatten_order(order) }
        
          render json: { rows: rows }
        end
          
        private

        PERIOD_DAYS = 30

        # 0 = current period, 1 = previous period
        def period_range(offset = 0)
          now          = Time.zone.now
          period_end   = now - offset * PERIOD_DAYS.days
          period_start = period_end - PERIOD_DAYS.days
        
          period_start..period_end   # half-open: start inclusive, end exclusive
        end

        def build_stat(label, current, previous, format:, invert_trend: false)
          change = previous.zero? ? 0.0 : ((current - previous) / previous.to_f * 100).round(1)

          # For refunds, a decrease is good — so flip the visual direction
          direction = change >= 0 ? "up" : "down"
          direction = direction == "up" ? "down" : "up" if invert_trend

          {
            label:     label,
            value:     format_value(current, format),
            raw_value: current,
            change:    change.abs,
            direction: direction,
            period:    "30d"
          }
        end

        def format_value(value, format)
          case format
          when :currency then ActionController::Base.helpers.number_to_currency(value,  unit: "₫", delimiter: ".", separator: ",")
          when :number   then ActionController::Base.helpers.number_with_delimiter(value)
          end
        end

        def flatten_order(order)
          # Handle orders with zero items gracefully — still show the order
          return [order_row(order)] if order.items.empty?
        
          order.items.map do |item|
            order_row(order).merge(
              product_id:   item.product_id,
              product_name: item.product&.name,
              quantity:     item.quantity,
              unit_price:   item.unit_price,
              line_total:   item.quantity * item.unit_price
            )
          end
        end
        
        def order_row(order)
          {
            order_id:      order.id,
            order_status:  order.status,
            order_total:   ActionController::Base.helpers.number_to_currency(order.total,  unit: "₫", delimiter: ".", separator: ","),
            created_at:    order.created_at.strftime('%FT%T'),
            customer_id:   order.user_id,
            customer_name: order.user&.name || "Deleted customer"
          }
        end
      end
    end
  end
end