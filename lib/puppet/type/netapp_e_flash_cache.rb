require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_flash_cache) do
  @doc = 'Manage Netapp E series flash cache'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a flash cachename.' unless @parameters.include?(:cachename)
    raise Puppet::Error, 'You must specify a flash cache block name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storagesystem.' unless @parameters.include?(:storagesystem)
  end

  newparam(:name, :namevar => true) do
    desc 'block name.'
  end

  newparam(:cachename) do
    desc 'Flash Cache Name.'
    validate do | value | 
      raise Puppet::Error, 'Value of cachename must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid cachename - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:storagesystem) do
    desc 'Storage system id.'
    validate do | value | 
      raise Puppet::Error, 'Value of storagesystem must not be empty.' if value.strip() == ''
    end
  end

  newparam(:diskids, :array_matching => :all) do
    desc 'Disk id.'
  end

  newparam(:enableexistingvolumes, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'Enable Existing Volume.'
  end

  newparam(:ignorestate, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'Ignore state value.'
  end

  newproperty(:ensure) do
    defaultto :created

    newvalue :created do
      if @resource['diskids']
        if @resource['diskids'].length == 0
          fail("Parameter diskids is empty")  
        else
          @resource['diskids'].each do |data|
            fail("value of diskids must not be empty.") if data.strip() == ''
          end
        end
      else 
        fail('You must specify diskid(s).')
      end
      @resource[:enableexistingvolumes] = false if @resource[:enableexistingvolumes] == nil
      provider.create
    end

    newvalue :suspended do
      @resource[:ignorestate] = false if @resource[:ignorestate] == nil
      provider.suspend
    end

    newvalue :resumed do
      @resource[:ignorestate] = false if @resource[:ignorestate] == nil
      provider.resume
    end

    newvalue :deleted do
      provider.delete
    end

    newvalue :updated do
      if not (@resource[:newname] || @resource[:configtype])
        fail('You must specify either newname/configtype or both.')
      end
      if @resource[:newname]
        fail('Newname must not be empty.') if @resource[:newname].strip() == ''
      end
      provider.update
    end

  end

  newparam(:newname) do
    desc 'New name for flash cache.'
    validate do | value | 
      raise Puppet::Error, 'Value of newname must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid newname - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:configtype) do
    newvalues('filesystem', 'database', 'multimedia')
  end

end  
