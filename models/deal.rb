class Deal
  attr_accessor :initial_quantity

  def percentage_of_quantity(amount)
    (amount.to_f / initial_quantity.to_f * 100.0).floor.to_s + "%"
  end
end
