RSpec.describe Dabooks::Formatter do
  subject { described_class.new(transaction_set) }
  let(:transaction_set) do
    instance_double(Dabooks::TransactionSet, transactions: [t1, t2])
  end
  let(:t1) do
    instance_double(Dabooks::Transaction,
      date: Date.new(2018, 12, 11),
      description: 'early',
      entries: [e1, e2],
    )
  end
  let(:t2) do
    instance_double(Dabooks::Transaction,
      date: Date.new(2018, 12, 13),
      description: 'late',
      entries: [e1, e2],
    )
  end
  let(:e1) do
    instance_double(Dabooks::Entry,
      account: Dabooks::Account["cash"],
      amount: Dabooks::Amount[32],
    )
  end
  let(:e2) do
    instance_double(Dabooks::Entry,
      account: Dabooks::Account["bank"],
      amount: Dabooks::Amount.unfixed,
    )
  end

  it "works" do
    output = StringIO.new
    subject.write_to(output)
    expect(output.string).to eq(<<~END_OUTPUT)
      2018-12-11 early
        cash  $0.32
        bank  $_____

      2018-12-13 late
        cash  $0.32
        bank  $_____

    END_OUTPUT
  end
end
