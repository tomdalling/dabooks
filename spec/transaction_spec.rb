RSpec.describe Dabooks::Transaction do
  subject do
    Dabooks::Transaction.new(
      date: Date.new(2018, 1, 2),
      description: 'boo',
      entries: entries
    )
  end

  let(:entries) do
    [
      Dabooks::Entry.new(
        account: Dabooks::Account["cash"],
        amount: Dabooks::Amount[11],
      ),
      Dabooks::Entry.new(
        account: Dabooks::Account["bank"],
        amount: Dabooks::Amount[-11],
      )
    ]
  end

  it "is a value type" do
    expect(subject).to have_attributes(
      date: Date.new(2018, 1, 2),
      description: 'boo',
      entries: entries,
    )
  end

  it "balances entries" do
    expect(subject.balance).to be_zero
    expect(subject).to be_balanced
  end

  it "is fixed if all entries are fixed" do
    expect(subject).to be_fixed
  end

  context "with an unfixed entry" do
    let(:entries) do
      [
        Dabooks::Entry.new(
          account: Dabooks::Account["cash"],
          amount: Dabooks::Amount[11],
        ),
        Dabooks::Entry.new(
          account: Dabooks::Account["bank"],
          amount: Dabooks::Amount.unfixed,
        )
      ]
    end

    it "is not fixed" do
      is_expected.not_to be_fixed
    end

    it "can calcluate the fixed balance" do
      is_expected.to have_attributes(fixed_balance: Dabooks::Amount[11])
    end

    it "can normalize unfixed entries" do
      is_expected.to have_attributes(normalized_entries: [
        entries.first,
        entries.last.with(amount: Dabooks::Amount[-11]),
      ])
    end
  end
end
