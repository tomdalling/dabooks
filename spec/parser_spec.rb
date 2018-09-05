RSpec.describe Dabooks::Parser do
  it 'parses stuff' do
    transaction_set = described_class.parse(StringIO.new(<<~END_TRANSACTIONS))
      2021-02-01 Went to the bar
        assets:bank                       $-24.00
        expenses:alcohol                  $_____

      # this is a comment
      2021-02-03 Grog and biscuits
        assets:bank                       $-29.88
        expenses:alcohol                  $17.99
        expenses:biscuits                 $_____
    END_TRANSACTIONS

    expect(transaction_set).to eq(
      Dabooks::TransactionSet.new(transactions: [
        Dabooks::Transaction.new(
          date: Date.new(2021, 2, 1),
          description: "Went to the bar",
          entries: [
            Dabooks::Entry.new(
              account: Dabooks::Account["assets:bank"],
              amount: Dabooks::Amount[-2400],
            ),
            Dabooks::Entry.new(
              account: Dabooks::Account["expenses:alcohol"],
              amount: Dabooks::Amount.unfixed,
            ),
          ]
        ),
        Dabooks::Transaction.new(
          date: Date.new(2021, 2, 3),
          description: "Grog and biscuits",
          entries: [
            Dabooks::Entry.new(
              account: Dabooks::Account["assets:bank"],
              amount: Dabooks::Amount[-2988],
            ),
            Dabooks::Entry.new(
              account: Dabooks::Account["expenses:alcohol"],
              amount: Dabooks::Amount[1799],
            ),
            Dabooks::Entry.new(
              account: Dabooks::Account["expenses:biscuits"],
              amount: Dabooks::Amount.unfixed,
            ),
          ]
        ),
      ])
    )
  end
end
