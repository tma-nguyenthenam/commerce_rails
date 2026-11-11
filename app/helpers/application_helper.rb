module ApplicationHelper
  def vnd(amount)
    "#{number_with_delimiter(amount.to_i, delimiter: '.')} ₫"
  end

  def status_badge(status)
    tag.span(status.humanize, class: "badge badge-#{status}")
  end

  def stock_badge(stock)
    css = stock.zero? ? "badge-out" : (stock < 5 ? "badge-low" : "badge-ok")
    tag.span(stock.zero? ? "Hết hàng" : "Còn #{stock}", class: "badge #{css}")
  end
end
