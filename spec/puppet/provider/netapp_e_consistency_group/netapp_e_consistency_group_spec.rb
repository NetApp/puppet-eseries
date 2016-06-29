require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_consistency_group).provider(:netapp_e_consistency_group) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_group).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_group).new(
        :name => 'Create_CG1',
        :id => 'id',
        :consistencygroup => 'CGname',
        :storagesystem => 'ssid116117',
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name => 'Create_CG1',
    )
  end

  describe 'when asking if consistency group exist?' do
    it_behaves_like 'a method with error handling', :get_consistency_groups, :exist?
    it 'should return :present if consistency group is present' do

      expect(@transport).to receive(:get_consistency_groups) {JSON.parse(File.read(my_fixture('consistency_group-list.json'))) }

      resource.provider.set(:consistencygroup => 'CGname')
      resource.provider.set(:id => '123456')
      resource.provider.set(:storagesystem => 'ssid116117')
      resource.provider.set(:repositoryfullpolicy => 'purgepit')
      resource.provider.set(:fullwarnthresholdpercent => 0)
      resource.provider.set(:autodeletethreshold => 0)
      resource.provider.set(:rollbackpriority => 'high')
      resource.provider.set(:ensure => :present)

      resource[:repositoryfullpolicy] = 'failbasewrites'
      resource[:fullwarnthresholdpercent] = 70
      resource[:autodeletethreshold] =5
      resource[:rollbackpriority] = 'high'

      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exist?).to eq(:present)
    end
    it 'should return :absent if consistency group is absent' do

      expect(@transport).to receive(:get_consistency_groups) {[]}
      allow(resource.provider).to receive(:transport) { @transport }

      resource[:consistencygroup] = 'CGnameInvalid'
      resource[:repositoryfullpolicy] = 'failbasewrites'
      resource[:fullwarnthresholdpercent] = 70
      resource[:autodeletethreshold] = 5
      resource[:rollbackpriority] = 'high'

      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exist?).to eq(:absent)
    end
  end

  context 'when creating consistency group' do
    before :each do
      resource.provider.set(:ensure => :absent)
    end
    it_behaves_like 'a method with error handling', :create_consistency_group, :create
    context 'with all parameters' do
      it 'should be able to create it' do

        resource[:repositoryfullpolicy] = 'purgepit'
        resource[:fullwarnthresholdpercent] = 75
        resource[:autodeletethreshold] = 32
        resource[:rollbackpriority] = 'high'

        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup],
                                                                      :fullWarnThresholdPercent => resource[:fullwarnthresholdpercent],
                                                                      :autoDeleteThreshold => resource[:autodeletethreshold],
                                                                      :repositoryFullPolicy => resource[:repositoryfullpolicy],
                                                                      :rollbackPriority => resource[:rollbackpriority]                              
                              )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with only mandatory parameters' do
      it 'should be able to create it' do
        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup]
                                                                      )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with rollbackpriority value :lowest' do
      it 'should be able to create it' do

        resource[:rollbackpriority] = 'lowest'

        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup],                          
                                                                      :rollbackPriority => resource[:rollbackpriority]                                
                              )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with rollbackpriority value :low and full warning threshold 75 percent' do
      it 'should be able to create it' do

        resource[:fullwarnthresholdpercent] = 75
        resource[:rollbackpriority] = 'low'

        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup],                          
                                                                      :rollbackPriority => resource[:rollbackpriority],
                                                                      :fullWarnThresholdPercent => resource[:fullwarnthresholdpercent]
                                                                      )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with rollbackpriority value :medium and auto delete threshold 10 count' do
      it 'should be able to create it' do
        resource[:autodeletethreshold] = 25
        resource[:rollbackpriority] = 'medium'
        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup],                          
                                                                      :rollbackPriority => resource[:rollbackpriority],
                                                                      :autoDeleteThreshold => resource[:autodeletethreshold]                             
                              )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with rollbackpriority value :highest and repo full policy to failbasewrites' do
      it 'should be able to create it' do
        resource[:repositoryfullpolicy] = 'failbasewrites'
        resource[:rollbackpriority] = 'highest'
        expect(@transport).to receive(:create_consistency_group).with(resource[:storagesystem],
                                                                      :name => resource[:consistencygroup], 
                                                                      :rollbackPriority => resource[:rollbackpriority],
                                                                      :repositoryFullPolicy => resource[:repositoryfullpolicy]
                              )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
  end

  context 'when destroying a consistency group' do
    before :each do
      resource.provider.destroy
      resource.provider.set(:id => resource[:id])
    end
    it_behaves_like 'a method with error handling', :delete_consistency_group, :flush
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_consistency_group).with(resource[:storagesystem],resource[:id])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.flush
    end
  end

  context 'when modifying a consistency group' do
    before :each do
      @expected_body = {  :name => resource[:consistencygroup],
                          :rollbackPriority => resource[:rollbackpriority],
                          :repositoryFullPolicy => resource[:repositoryfullpolicy],
                          :autoDeleteThreshold => resource[:autodeletethreshold],
                          :fullWarnThresholdPercent => resource[:fullwarnthresholdpercent]  }
      resource.provider.flush
      resource.provider.set(:ensure => :present)
      resource.provider.set(:id => resource[:id])
    end
    shared_examples 'a changable param/property' do |param_name, expected_name|
      it "if #{param_name} changes" do
        m = resource.provider.method((param_name.to_s + '=').to_sym)
        m.call(resource[param_name])
        @expected_body[expected_name] = resource[param_name]
        expect(@transport).to receive(:update_consistency_group).with(resource[:storagesystem], resource[:id], @expected_body)
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.flush
      end
    end
  end

end
