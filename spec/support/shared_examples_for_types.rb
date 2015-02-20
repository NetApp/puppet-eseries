def unlist(value)
  # returns first element of array, but only when array has size of 1
  # returns vlaue if value isn't array
  # It's for params/properties, that are array_matching
  return value[0] if value.is_a?(Array) && value.size == 1
  value
end

shared_examples 'a string param/property' do |param_name, special_characters|
  it 'should support letters' do
    value = ('a'..'z').to_a.join ''
    resource[param_name] = value
    unlist(described_class.new(resource)[param_name]).should == value
  end
  it 'should support digits' do
    value = ('0'..'9').to_a.join ''
    resource[param_name] = value
    unlist(described_class.new(resource)[param_name]).should == value
  end
  it 'should support underscore' do
    value = '__'
    resource[param_name] = value
    unlist(described_class.new(resource)[param_name]).should == value
  end
  if special_characters
    it 'should support special characters and spaces' do
      '!£§!@#$%^&*()-+=[]{};\':"\|?/.>,<~` '.split('').each do |char|
        value = 'my' + char + 'name'
        resource[param_name] = value
        unlist(described_class.new(resource)[param_name]).should == value
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

shared_examples 'a enum param/property' do |param_name, enum, default|
  context 'should acccept' do
    enum.each do |val|
      it "#{val}" do
        resource[param_name] = val
        expected = val
        if val.instance_of?(String)
          expected = val.to_sym
        elsif ( !!val == val) # if boolean type
          expected = val.to_s.to_sym
        end
        described_class.new(resource)[param_name].should == expected
      end
    end
  end
  describe 'should not accept' do
    [1, 'string', :symbol, true, :false, ['array'], { 'hash' => 'value' }].each do |val|
      next if enum.include? val
      it "#{val}" do
        resource[param_name] = val
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
    end
  end
  unless default.nil?
    it "should have default value set to #{default}" do
      default = default.to_sym if default.instance_of?(String)
      described_class.new(resource)[param_name].should == default
    end
  end
end

shared_examples 'a boolish property' do |param_name, default|
   include_examples 'a enum param/property', param_name, [true, false, :true, :false], default
end

shared_examples 'a boolean param' do |param_name, default|
  values =  [true, :true, false, :false]
  context 'should acccept' do
    values.each do |val|
      it "#{val}" do
        resource[param_name] = val
        expected = val
        if val == :true
          expected = true
        elsif val == :false
          expected = false
        elsif val.instance_of?(String) 
          expected = val.to_sym
        end
        described_class.new(resource)[param_name].should == expected
      end
    end
  end
  describe 'should not accept' do
    [1, 'string', :symbol, ['array'], { 'hash' => 'value' }].each do |val|
      it "#{val}" do
        resource[param_name] = val
        expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
      end
    end
  end
  unless default.nil?
    it "should have default value set to #{default}" do
      default = default.to_sym if default.instance_of?(String)
      described_class.new(resource)[param_name].should == default
    end
  end
end

shared_examples 'a array_matching param' do |param_name, single, array|
  it 'should support array' do
    resource[param_name] = array
    described_class.new(resource)[param_name].should == array
  end
  it 'should support single value' do
    resource[param_name] = single
    unlist(described_class.new(resource)[param_name]).should == single
  end
end

shared_examples 'a IPv4 param/property' do |param_name|
  it 'should support single value IPv4' do
    value = '10.250.117.116'
    resource[param_name] = value
    described_class.new(resource)[param_name].should == value
  end
  it 'should not support bad IPv4' do
    %w(10.350.117.116, 10.350.117).each do |val|
      resource[param_name] = val
      expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
    end
  end
end

shared_examples 'a IPv6 param/property' do |param_name|
  it 'should support single value IPv6' do
    %w(2001:0db8:0:0::1428:57ab 2001:0db8:0000:0000:0000:0000:1428:57ab).each do |val|
      resource[param_name] = val
      described_class.new(resource)[param_name].should == val
    end
  end
  it 'should not support bad IPv6' do
    value = '2001:0db8:0:0::1428:5abbla'
    resource[param_name] = value
    expect { described_class.new(resource) }.to raise_error Puppet::ResourceError
  end
end
