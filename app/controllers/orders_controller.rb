# ════════════════════════════════════════════════════════════════════════════
# Controller MỎNG: chỉ dịch HTTP <-> use case.
#   * Đọc params, gọi service, nhìn Result, quyết định redirect/render.
#   * KHÔNG chứa luật nghiệp vụ (trừ kho, tính giá... nằm ở service).
# ════════════════════════════════════════════════════════════════════════════
class OrdersController < ApplicationController
  # Thông báo hiển thị cho người dùng, ứng với `result.error` của service.
  ERROR_MESSAGES = {
    invalid_items: "Hãy chọn ít nhất một sản phẩm với số lượng hợp lệ.",
    invalid_product: "Có sản phẩm không tồn tại.",
    insufficient_stock: "Một sản phẩm không đủ hàng. Không có gì bị trừ kho.",
    invalid_discount: "Mã giảm giá không hợp lệ hoặc đã hết lượt.",
    missing_idempotency_key: "Thiếu idempotency key.",
    already_paid: "Đơn này đã được thanh toán.",
    payment_in_progress: "Đơn đang được thanh toán, vui lòng đợi.",
    gateway_error: "Cổng thanh toán bị lỗi/timeout. Bấm thanh toán lại là an toàn: không bị tính tiền hai lần.",
    invalid_status: "Trạng thái đơn không cho phép thanh toán.",
    nothing_to_pay: "Đơn không có số tiền cần thanh toán."
  }.freeze

  def index
    @orders = Order.includes(:user).order(id: :desc)
  end

  def show
    @order = Order.includes(:user, items: :product, payments: []).find(params[:id])
  end

  def new
    @products = Product.order(:id)
    # Key sinh ở lúc HIỂN THỊ form (không phải lúc submit). Bấm đúp nút "Đặt hàng"
    # hay refresh lại trang POST đều gửi CÙNG key -> chỉ tạo đúng một đơn (idempotency).
    @idempotency_key = SecureRandom.uuid
  end

  def create
    result = Orders::Create.call(
      user: current_user,
      items: items_from_params,
      idempotency_key: params[:idempotency_key],
      request_id: request.request_id,
      discount_code: params[:discount_code].presence
    )

    if result.success?
      notice = result.replayed? ? "Đơn này đã được tạo trước đó (cùng idempotency key)." : "Đặt hàng thành công."
      redirect_to result.order, notice: notice
    else
      @products = Product.order(:id)
      @idempotency_key = params[:idempotency_key].presence || SecureRandom.uuid
      flash.now[:alert] = ERROR_MESSAGES.fetch(result.error, result.error.to_s)
      render :new, status: :unprocessable_content
    end
  end

  def pay
    # Dev: gateway chậm 1 giây, lỗi 20% (đổi bằng GATEWAY_LATENCY / GATEWAY_FAILURE_RATE).
    # Dùng chung một instance qua class-level để nhớ idempotency_key giữa các lần bấm.
    result = Orders::Pay.call(params[:id], gateway: self.class.gateway)

    if result.success?
      redirect_to order_path(params[:id]), notice: "Thanh toán thành công."
    else
      redirect_to order_path(params[:id]), alert: ERROR_MESSAGES.fetch(result.error, result.error.to_s)
    end
  end

  def self.gateway
    @gateway ||= Payments::FakeGateway.from_env
  end

  private

  # Không có đăng nhập trong bài học: coi người dùng đầu tiên là "người đang mua".
  def current_user = User.order(:id).first!

  # Form gửi items[<product_id>] = số lượng. Bỏ qua các ô để trống hoặc 0.
  def items_from_params
    raw = params.fetch(:items, {}).to_unsafe_h
    raw.filter_map do |product_id, quantity|
      next if quantity.to_i <= 0

      { product_id: product_id, quantity: quantity }
    end
  end
end
