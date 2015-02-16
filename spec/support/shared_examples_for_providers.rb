shared_examples 'a method with error handling' do |transport_method, provider_method|
  it 'should raise Puppet::Error when something went wrong' do
    begin
      provider = resource.provider
      m = resource.provider.method(provider_method)
    rescue NameError
      # it's class method then
      provider = described_class
      m = described_class.method(provider_method)
    end
    expect(@transport).to receive(transport_method).and_raise('some message')
    allow(provider).to receive(:transport) { @transport }
    expect { m.call }.to raise_error(Puppet::Error, 'some message')
  end
end
