require "./src/config/config"
require 'tempfile'

RSpec.describe Config, "test config" do
  # load a test config
  before do
    f = Tempfile.create
    f << <<~EOF
    BaseDir "#{Dir.pwd}/spec/data/collectd"

    <CollectRack>
      asdas asd
      CollectdMiddleware true
      <Host rlyeh>
        Overview load
      </Host>
    </CollectRack>

    <Plugin unixsock>
      SocketFile "/run/collectd.sock"
    </Plugin>

    <Test>
      <Foo "Bar">
      </Foo>
    </Test>
    EOF
    f.rewind
    Config.load f.path
  end

  it "has hosts" do
    expect(Config.hosts).to_not be_empty
  end

  it "has a unix socket" do
    expect(Config.unixsock).to eq("/run/collectd.sock")
  end

  it "has CollectdMiddleware enabled" do
    expect(Config.collectd_middleware).to eq(true)
  end

  describe Block, "CollectRack" do
    subject(:collect_rack_block) { Config[:collect_rack] }
    it { should_not be_nil } 
    
    describe Option, "CollectdMiddleware" do
      subject(:collectd_middleware_option) { collect_rack_block[:collectd_middleware] }
      describe "first argument" do
        subject { collectd_middleware_option.arguments.first }
        it { should eq(true) }
      end
      describe "#to_s" do
        subject() { collectd_middleware_option.to_s }
        it { should eq("CollectdMiddleware true") }
      end
    end
  end

  it "has a default plugin directory" do
    expect(Config.plugin_config_dir).to_not be_nil
  end

  it "has a default interval" do
    expect(Config.interval).to_not be_nil
  end

  it "has flushsocket enabled by default" do
    expect(Config.flush_socket).to be_truthy
  end

  it "has a default collectd middleware name" do
    expect(Config.collectd_middleware_name).to_not be_nil
  end

  describe Block, "Test" do
    subject { Config[:test] }
    it { should_not be_nil }
    it "can find a block statement using its first argument" do
      expect(subject[:foo, "Bar"]).to_not be_nil
    end
  end

  describe Block, "Host rlyeh" do
    subject { Config[:collect_rack][:host, "rlyeh"] }
    it { should_not be_nil }
    it "has an overview" do
      expect(subject[:overview]).to_not be_nil
    end
  end

end
