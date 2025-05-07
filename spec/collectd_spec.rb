require "./src/collectd"
require "./spec/config_context"

RSpec.describe Host, "host0000" do
  include_context "config"
  subject(:host) { Host.new("host0000") }

  it "can read plugins" do
    subject.plugins
  end

  it "has plugins" do
    expect(subject.plugins).to_not be_empty
  end

  it "has plugin000 plugin" do
    expect(subject.has_plugin?("plugin000")).to eq true
  end

  it "does not have 'foo' plugin" do
    expect(subject.has_plugin?("foo")).to eq false
  end

  describe Plugin, "plugin000" do
    subject(:plugin) { host["plugin000"] }
    it "has a single instance" do
      expect(subject.instances.length).to eq 1
    end
  end

end

RSpec.describe Host, "non-existing" do
  include_context "config"
  subject { Host.new "foo" }
  it { should_not exist }
end
