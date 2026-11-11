# Nhận webhook từ hệ thống bên ngoài.
#
# App đã là MVC nên Rails bật bảo vệ CSRF cho mọi POST. Hệ thống bên ngoài không có
# CSRF token, nên endpoint này phải tắt CSRF. (Thay vào đó, ở production bạn xác thực
# bằng chữ ký HMAC trong header; ở bài học này ta bỏ qua cho đơn giản.)
class WebhooksController < ApplicationController
  skip_forgery_protection

  def payments
    result = Webhooks::HandlePaymentEvent.call(
      event_id: params[:event_id], order_id: params[:order_id], status: params[:status]
    )

    if result.success?
      render json: { ok: true, duplicate: result.replayed? }
    else
      render json: { ok: false, error: result.error }, status: (result.error == :order_not_found ? :not_found : :unprocessable_content)
    end
  end
end
