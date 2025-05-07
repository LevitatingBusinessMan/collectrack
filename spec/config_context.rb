require "./src/config/config"

RSpec.shared_context "config" do
  # load a test config
  before do
    f = Tempfile.create
    f << <<~EOF
    BaseDir "#{Dir.pwd}/spec/data/collectd"
    EOF
    f.rewind
    Config.load f.path
  end
end
