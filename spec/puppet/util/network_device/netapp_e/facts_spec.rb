require 'spec/spec_helper'

describe Puppet::Util::NetworkDevice::Netapp_e::Facts do
  before(:each) do
    @transport = double('transport')
    @facts = Puppet::Util::NetworkDevice::Netapp_e::Facts.new(@transport)
  end

  it 'should have facts only readable' do
    expect(@facts.facts).to be_nil
    expect { @facts.facts = 'some new facts' }.to raise_error NoMethodError
  end
  it 'should have facts only readable' do
    expect(@facts.transport).to be @transport
    expect { @facts.transport = 'new transport' }.to raise_error NoMethodError
  end

  context 'initialize:' do
    it 'should set transport readable' do
      transport = double('transport')
      facts = Puppet::Util::NetworkDevice::Netapp_e::Facts.new(transport)
      expect(facts.transport).to be(transport)
    end
  end

  context 'retreive:' do
    it 'should return facts with empty "initialized_systems"" array if no storage systems' do
      allow(@transport).to receive(:get_storage_systems).and_return([])
      expect(@facts.retrieve).to eq('initialized_systems' => [])
    end
    it 'should return facts with initialized_systems containing only ids of storage systems in status "optimal" or "needsAttn"' do
      systems = [{ 'status' => 'unrelated', 'id' => '1' },
                 { 'status' => 'optimal', 'id' => '2' },
                 { 'status' => 'needsAttn', 'id' => '3' },
                 { 'status' => 'optimal', 'id' => '4' },
                 { 'status' => 'needsAttn', 'id' => '5' },
                 { 'status' => 'unrelated', 'id' => '6' }]
      allow(@transport).to receive(:get_storage_systems).and_return(systems)
      expect(@facts.retrieve).to eq('initialized_systems' => systems[1..4].map { |i| i['id'] })
    end
  end
end
