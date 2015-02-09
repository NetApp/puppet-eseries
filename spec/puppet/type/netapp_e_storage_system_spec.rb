require 'spec/spec_helper'
require 'rspec/expectations'

shared_examples 'a string param/property' do |param_name, special_characters|
  it 'should support letters' do
    value = ('a'..'z').to_a.join ''
    resource[param_name] = value
    described_class.new(resource)[param_name].should == value
  end
  it 'should support digits' do
    value = ('0'..'9').to_a.join ''
    resource[param_name] = value
    described_class.new(resource)[param_name].should == value
  end
  it 'should support underscore' do
    value = '__'
    resource[param_name] = value
    described_class.new(resource)[param_name].should == value
  end
  if special_characters
    it 'should support special characters and spaces' do
      '!£§!@#$%^&*()-+=[]{};\':"\|?/.>,<~` '.split('').each do |char|
        value = 'my' + char + 'name'
        resource[param_name] = value
        described_class.new(resource)[param_name].should == value
      end
    end
  else
    it 'should not support special characters and spaces' do
      '!£§!@#$%^&*()-+=[]{};\':"\|?/.>,<~` '.split('').each do |char|
        resource[param_name] = char
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
    end
  end
end

describe Puppet::Type.type(:netapp_e_storage_system) do
  before :each do
    @storage_system = { :name => 'storage_system' }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @storage_system
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :password, :controllers].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :meta_tags].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name
    end
    context 'for password' do
      it_behaves_like 'a string param/property', :password, true
    end

    context 'for controllers' do
      it 'should support ip v4' do
        controllers = %w(10.250.117.116 10.250.117.117)
        resource[:controllers] = controllers
        described_class.new(resource)[:controllers].should == controllers
      end
      it 'should support ip v6' do
        controllers = %w(2001:0db8:0000:0000:0000:0000:1428:57ab 2001:0db8:0:0::1428:57ab)
        resource[:controllers] = controllers
        described_class.new(resource)[:controllers].should == controllers
      end
      it 'should support single value vp4' do
        controller = '10.250.117.116'
        resource[:controllers] = controller
        described_class.new(resource)[:controllers].should == controller
      end
      it 'should support single value vp6' do
        controller = '2001:0db8:0:0::1428:57ab'
        resource[:controllers] = controller
        described_class.new(resource)[:controllers].should == controller
      end
    end

    context 'for meta_tags' do
      let :tags do
        [{ 'key' => 'poweron', 'valueList' => ['true'] },
         { 'key' => 'u89', 'valueList' => %w(11 aab) }]
      end
      it 'should support array of tags' do
        resource[:meta_tags] = tags
        described_class.new(resource)[:meta_tags].should == tags
      end
      it 'should support single tag' do
        resource[:meta_tags] = tags[0]
        described_class.new(resource)[:meta_tags].should == [tags[0]]
      end
      it 'should not support array of strings' do
        resource[:meta_tags] = %w(first_tag second_tag)
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
      it 'should not support string' do
        resource[:meta_tags] = 'tag'
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
    end
  end
end
