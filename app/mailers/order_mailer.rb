class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order = order
    mail(to: order.user.email, subject: "Xác nhận đơn hàng ##{order.id}")
  end
end
