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
    </CollectRack>
    <Plugin unixsock>
      SocketFile "/run/collectd.sock"
    </Plugin>
    EOF
    f.rewind
    Config.load f.path
  end

  it "has hosts" do
    expect(Config.hosts).to_not be_empty
  end

  it "has a unix socket" do
    expect(Config.unixsock).to_not be_nil
  end

end
