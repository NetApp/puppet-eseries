require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_password).provider(:netapp_e_password) do
  before :each do
    Puppet::Type.type(:netapp_e_password).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_password).new(
        :storagesystem => 'storagesystem',
        :ensure => :set,
        :current => 'current',
        :new => 'new_password',
        :admin => :true,
        :force => :true,
        :provider => provider

    )
  end

  let :provider do
    described_class.new(
        :storagesystem => 'storage_system'
    )
  end

  context 'for set_password' do
    it 'should change password' do
      expect(@transport).to receive(:change_password).with('storagesystem',
                                                           :currentAdminPassword => resource[:current],
                                                           :adminPassword => resource[:admin],
                                                           :newPassword => resource[:new])
      allow(described_class).to receive(:transport) { @transport }
      resource.provider.set_password
    end
  end
  context 'for password_status' do
    it_behaves_like 'a method with error handling', :get_passwords_status, :passwords_status
    context 'when :admin is true' do
      it 'should return :set if password is set' do
        expect(@transport).to receive(:get_passwords_status).with('storagesystem') { { 'adminPasswordSet' => true } }
        allow(described_class).to receive(:transport) { @transport }
        expect(resource.provider.passwords_status).to eq(:set)
      end
      it 'should return :notset if password is not set' do
        expect(@transport).to receive(:get_passwords_status).with('storagesystem') { { 'adminPasswordSet' => false } }
        allow(described_class).to receive(:transport) { @transport }
        expect(resource.provider.passwords_status).to eq(:notset)
      end
    end
    context 'when :admin is false' do
      before :each do
        resource[:admin] = false
      end
      it 'should return :set if password is set' do
        expect(@transport).to receive(:get_passwords_status).with('storagesystem') { { 'readOnlyPasswordSet' => true } }
        allow(described_class).to receive(:transport) { @transport }
        expect(resource.provider.passwords_status).to eq(:set)
      end
      it 'should return :notset if password is not set' do
        expect(@transport).to receive(:get_passwords_status).with('storagesystem') { { 'readOnlyPasswordSet' => false } }
        allow(described_class).to receive(:transport) { @transport }
        expect(resource.provider.passwords_status).to eq(:notset)
      end
    end
  end
end
