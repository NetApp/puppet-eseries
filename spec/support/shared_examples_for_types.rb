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

shared_examples 'a enum param/property' do |param_name, enum, default|
  context 'should acccept' do
    enum.each do |val|
      it "#{val}" do
        resource[param_name] = val
        expected = val
        if val == true
          expected = :true
        elsif val == false
          expected = :false
        elsif val.instance_of?(String)
          expected = val.to_sym
        end
        described_class.new(resource)[param_name].should == expected.to_sym
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
      described_class.new(resource)[param_name].should == default.to_sym
    end
  end
end

shared_examples 'a boolish param/property' do |param_name, default|
  include_examples 'a enum param/property', param_name, [true, :true, false, :false], default
end

shared_examples 'a array_matching param' do |param_name, single, array|
  it 'should support array' do
    resource[param_name] = array
    described_class.new(resource)[param_name].should == array
  end
  it 'should support single value' do
    resource[param_name] = single
    described_class.new(resource)[param_name].should == single
  end
end
