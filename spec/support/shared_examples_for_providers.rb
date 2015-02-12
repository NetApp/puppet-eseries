shared_examples 'a method with error handling' do |transport_method, provider_method|
  it 'should raise Puppet::Error when something went wrong' do
    expect(@transport).to receive(transport_method).and_raise('some message')
    allow(described_class).to receive(:transport) { @transport }
    m = resource.provider.method(provider_method)
    expect { m.call }.to raise_error(Puppet::Error, 'some message')
  end
end
