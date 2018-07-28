class BankruptcyRule
  def initialize(public_records:, credit_report:)
    @public_records = public_records
    @credit_report  = credit_report
  end

  def eligible?
    in_bankruptcy? || recent_bankrutpcy? || old_bankruptcy_and_bad_credit?
  end

  private

  attr_reader :public_records, :credit_report

  def in_bankruptcy?
    bankruptcies.any?
  end

  def recent_bankrutpcy?
    bankruptcies.any? { |bankruptcy| bankruptcy.closed_date > 2.years.ago }
  end

  def old_bankruptcy_with_good_credit?
    bankruptcies.any? { |bankruptcy| bankruptcy.closed_date > 3.years.ago } && bad_credit?
  end

  def bad_credit?
    fico > 700
  end

  def fico
    credit_report.fico
  end

  def bankruptcies
    public_records.select(&:bankruptcy)
  end
end
