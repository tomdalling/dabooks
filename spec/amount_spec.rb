RSpec.describe Dabooks::Amount do
  let(:ten) { Dabooks::Amount[10] }
  let(:twenty) { Dabooks::Amount[20] }
  let(:zero) { Dabooks::Amount[0] }
  let(:unfixed) { Dabooks::Amount.unfixed }

  it 'has a coercing constructor' do
    expect(Dabooks::Amount.new(cents: '15').cents).to eq(15)
  end

  it 'does basic arithmetic' do
    expect(ten + twenty).to eq(Dabooks::Amount[30])
    expect(twenty - ten).to eq(ten)
    expect(-ten).to eq(Dabooks::Amount[-10])
  end

  it 'defines comparison operators' do
    expect(ten).to be < twenty
    expect(twenty).to be > ten
    expect(ten).to eq(twenty - ten)
    expect(zero).to be_zero
  end

  it 'has fixed and unfixed amounts' do
    expect(ten).to be_fixed
    expect(unfixed).not_to be_fixed
  end

  it 'has a nice inspect string' do
    expect(ten.inspect).to eq('<Amount 10>')
  end
end
