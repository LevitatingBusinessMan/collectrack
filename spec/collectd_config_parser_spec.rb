require "./src/config/config"
require 'tempfile'

RSpec.describe CollectdConfigParser do
  before do
    @parser = CollectdConfigParser.new
  end

  it "scans hostname" do
    tokens = @parser.tokens('Hostname    "r-desktop"')
    expect(tokens).to eq([
      [:UNQUOTED_STRING, "Hostname"],
      [:QUOTED_STRING, '"r-desktop"']
    ])
  end

  it "ignores whitespace" do
    tokens = @parser.tokens(" \t\b")
    expect(tokens).to be_empty
  end

  it "ignores commented blocks when scanning" do
    tokens = @parser.tokens <<~EOF
    #<Plugin "battery">
    #  ValuesPercentage false
    #  ReportDegraded false
    #  QueryStateFS false
    #</Plugin>
    EOF
    expect(tokens).to eq([[:EOL, "\n"]] * 5)
  end

  it "scans a hex" do
    tokens = @parser.tokens("0xdeadc0de")
    expect(tokens).to eq([[:NUMBER, "0xdeadc0de".to_i(16)]])
  end

  it "parses hostname" do
    stmts = @parser.scan_str <<~EOF
    Hostname "r-desktop"
    EOF
    expect(stmts.first.class).to be(Option)
    expect(stmts.first.identifier).to eq("Hostname")
    expect(stmts.first.arguments).to eq(["r-desktop"])
   end

   it "ignores comments" do
    stmts = @parser.scan_str <<~EOF
    #Hostname "r-desktop"
    EOF
    expect(stmts).to be_empty
   end

   it "ignores commented block" do
    stmts = @parser.scan_str <<~EOF
    #<Plugin "battery">
    #  ValuesPercentage false
    #  ReportDegraded false
    #  QueryStateFS false
    #</Plugin>
   EOF
   expect(stmts).to be_empty
   end

   it "parses a block" do
    stmts = @parser.scan_str <<~EOF
    <Plugin "battery">
      ValuesPercentage false
      ReportDegraded false
      QueryStateFS false
    </Plugin>
   EOF
   expect(stmts.length).to eq(1)
   block = stmts.first
   expect(block.class).to eq(Block)
   expect(block.identifier).to eq("Plugin")
   expect(block.arguments).to eq(["battery"])
   expect(block.statements.first.class).to eq(Option)
   expect(block.statements.first.identifier).to eq("ValuesPercentage")
   expect(block.statements.first.arguments).to eq([false])
   expect(block.statements.last.identifier).to eq("QueryStateFS")
   expect(block.statements.last.arguments).to eq([false])
   end

   it "parses an option spit over two lines" do
    stmts = @parser.scan_str <<~EOF
    Hostname \
    "r-desktop"
    EOF
    expect(stmts.first.class).to be(Option)
    expect(stmts.first.identifier).to eq("Hostname")
    expect(stmts.first.arguments).to eq(["r-desktop"])
   end

   it "parses a block after EOLs" do
    stmts = @parser.scan_str <<~EOF
#
# Config file for collectd(1).
# Please read collectd.conf(5) for a list of options.
# http://collectd.org/
#

##############################################################################
# Global                                                                     #
#----------------------------------------------------------------------------#
# Global settings for the daemon.                                            #
##############################################################################

<CollectTrack>
    Option argument
</CollectTrack>
    EOF

  expect(stmts.length).to eq(1)
  block = stmts.first
  expect(block.class).to eq(Block)
  end

  it "parses from files" do
    f = Tempfile.create
    f << <<~EOF
    Hostname "r-desktop"
    EOF
    f.rewind
    stmts = @parser.scan_file f.path
    expect(stmts.first.class).to be(Option)
    expect(stmts.first.identifier).to eq("Hostname")
    expect(stmts.first.arguments).to eq(["r-desktop"])
  end

end
