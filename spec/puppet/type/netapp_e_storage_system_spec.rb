require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_storage_system) do
  before :each do
    @storage_system = { :name => 'storage_system',
                        :controllers => '10.250.117.116' }
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
    [:name, :controllers].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name, false
    end

    context 'for password' do
      it_behaves_like 'a string param/property', :password, true
    end

    context 'for controllers' do
      it_behaves_like 'a IPv4 param/property', :controllers
      it_behaves_like 'a IPv6 param/property', :controllers
      it_behaves_like 'a array_matching param', :controllers, '10.250.117.116', %w(10.250.117.116 10.250.117.117)
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
      it 'should not support empty hash' do
        resource[:meta_tags] = [{}]
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
      it 'should not support hash with wrong keys' do
        tags = [{ 'wrong_key' => 'third_key', 'valueList' => %w(343 ab) }]
        resource[:meta_tags] = tags
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError

        tags = [{ 'key' => 'third_key', 'wrong_key' => %w(343 ab) }]
        resource[:meta_tags] = tags
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
      it 'should not support hash with extra keys' do
        tag = tags[0].dup
        tag['extra_key'] = 'extra_value'
        resource[:meta_tags] = [tag]
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
      it 'should not support hash with missing keys' do
        tags = [{ 'valueList' => %w(343 ab) }]
        resource[:meta_tags] = tags
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError

        tags = [{ 'key' => 'third_key' }]
        resource[:meta_tags] = tags
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
      it 'should support empty valueList' do
        tag = tags[0].dup
        tag['valueList'] = []
        resource[:meta_tags] = [tag]
        described_class.new(resource)[:meta_tags][0]['valueList'].should == []
      end
      it 'should not support valueList as array of not strings' do
        [1, :symbol, true, :false, ['array'], { 'hash' => 'value' }].each do |val|
          tag = tags[0].dup
          tag['valueList'] = [val, 'string', val]
          resource[:meta_tags] = [tag]
          expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
        end
      end
      it 'should not support key  as not string' do
        [1, :symbol, true, :false, ['array'], { 'hash' => 'value' }].each do |val|
          tag = tags[0].dup
          tag['key'] = val
          resource[:meta_tags] = [tag]
          expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
        end
      end
      describe 'when calling insync?' do
        before(:each) do
          resource[:meta_tags] = tags
          @property = described_class.new(resource).property('meta_tags')
        end
        it 'should return false if "is" is empty' do
          expect(@property.insync? '').to be false
        end
        it 'should return true if "is" is equal to should' do
          expect(@property.insync? tags.dup).to be true
        end
        it 'should return false if "is" array have less values' do
          expect(@property.insync? [tags[0]]).to be false
        end
        it 'should return false if  "is" have more values' do
          is = tags.dup
          is << { 'key' => 'third_key', 'valueList' => %w(343 ab) }
          expect(@property.insync? is).to be false
        end
        it 'should return false if "should" array have less values' do
          resource[:meta_tags] = [tags[0]]
          property = described_class.new(resource).property('meta_tags')
          expect(property.insync? tags).to be false
        end
        it 'should return false if "should" have more values' do
          resource[:meta_tags] = tags.dup
          resource[:meta_tags] << { 'key' => 'third_key', 'valueList' => %w(343 ab) }
          property = described_class.new(resource).property('meta_tags')
          expect(property.insync? tags).to be false
        end
        it 'should fail if "should" is empty' do
          resource[:meta_tags] = []
          property = described_class.new(resource).property('meta_tags')
          expect { property.insync? tags }.to raise_error Puppet::Error
        end
        it 'should return true if "is" and "should" are same but in diffrent order' do
          expect(@property.insync? tags.dup.reverse).to be true
        end
      end
    end
  end
end
