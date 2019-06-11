require File.expand_path("../../lib/stupidedi", __FILE__)

config = Stupidedi::Config.hipaa
parser = Stupidedi::Parser.build(config)

input  = File.open("spec/fixtures/005010/X221A1 HP835 Health Care Claim Payment Advice/pass/dollars-and-data-sent-separate.edi", :encoding => "ISO-8859-1")


# Reader.build accepts IO (File), String, and DelegateInput
parser, result = parser.read(Stupidedi::Reader.build(input))

# Report fatal tokenizer failures
if result.fatal?
  result.explain{|reason| raise reason + " at #{result.position.inspect}" }
end

# Helper function: fetch an element from the current segment
def el(m, *ns, &block)
  if Stupidedi::Either === m
    m.tap{|m| el(m, *ns, &block) }
  else
    yield(*ns.map{|n| m.elementn(n).map(&:value).fetch })
  end
end

# Print some information
parser.first
  .flatmap{|m| m.find(:GS) }
  .flatmap{|m| m.find(:ST) }
  .tap do |m|
    el(m.find(:N1, "PR"), 2){|e| puts "Payer: #{e}" }
    el(m.find(:N1, "PE"), 2){|e| puts "Payee: #{e}" }
  end
  .flatmap{|m| m.find(:LX) }
  .flatmap{|m| m.find(:CLP) }
  .flatmap{|m| m.find(:NM1, "QC") }
  .tap{|m| el(m, 3, 4){|l,f| puts "Patient: #{l}, #{f}" }}