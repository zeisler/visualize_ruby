class BankruptcyRule
  def initialize(bankruptcies:, credit_report:)
    @bankruptcies  = bankruptcies
    @credit_report = credit_report
  end

  def eligible?
    in_bankruptcy? || recent_bankruptcy? || old_bankruptcy_and_bad_credit?
  end

  private

  attr_reader :bankruptcies, :credit_report

  def in_bankruptcy?
    bankruptcies.any? do |bankruptcy|
      bankruptcy.closed_date.nil?
    end
  end

  def recent_bankruptcy?
    bankruptcies.any? do |bankruptcy|
      bankruptcy.closed_date > 2.years.ago
    end
  end

  def old_bankruptcy_and_bad_credit?
    bankruptcies.any? do |bankruptcy|
      bankruptcy.closed_date > 3.years.ago
    end && bad_credit?
  end

  def bad_credit?
    fico > 700
  end

  def fico
    credit_report.fico
  end
end
