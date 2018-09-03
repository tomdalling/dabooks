RSpec.describe Dabooks::Account do
  it "represents a nested structure" do
    acc = Dabooks::Account["a:b"]
    expect(acc.depth).to eq(1)
    expect(acc.parent).to eq(Dabooks::Account["a"])
    expect(acc.parent.parent).to eq(nil)
    expect(acc).to include(Dabooks::Account["a:b:c"])
    expect(acc.last_component).to eq("b")
  end
end
