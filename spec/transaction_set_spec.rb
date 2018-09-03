RSpec.describe Dabooks::TransactionSet do
  subject { described_class.new(transactions: [transaction]) }
  let(:transaction) do
    Dabooks::Transaction.new(date: Date.today, description: 'moo', entries: [])
  end

  it "is a value type" do
    is_expected.to have_attributes(transactions: [transaction])
  end

  it "is enumerable" do
    expect { |x| subject.each(&x) }.to yield_with_args(transaction)
  end
end
