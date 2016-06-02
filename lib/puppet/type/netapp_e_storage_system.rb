require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_storage_system) do
  @doc = 'Manage Netapp E series storage system creation, modification and deletion.'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a storage system name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storage system controllers.' unless @parameters.include?(:controllers)
  end

  newparam(:name, :namevar => true) do
    desc 'Storage System ID'
    validate do |value|
     unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
       fail("#{value} is not a valid storage system id.")
     end
    end
  end

  newparam(:password) do
    desc 'Storage system password'
  end

  newparam(:controllers, :array_matching => :all) do
    desc 'Array of controllers IP addresses or host names.'
    def valid_ipv4?(addr)
      if /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ =~ addr
        return $~.captures.all? {|i| i = i.to_i; i >= 0 and i <= 255 }
      end
      false
    end

    def valid_ipv6?(addr)
      # http://forums.dartware.com/viewtopic.php?t=452
      # ...and, yes, it is this hard. Doing it programatically is harder.
      return true if addr =~ /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/
      false
    end

    validate do |value|
      if value.is_a?(Array)
        value.each do |ip|
          unless valid_ipv4?(ip) || valid_ipv6?(ip)
            fail("#{value} is not a valid IP address")
          end
        end
      else
        unless valid_ipv4?(value.to_s) || valid_ipv6?(value.to_s)
            fail("#{value} is not a valid IP address")
          end
      end
    end
  end

  newproperty(:meta_tags, :array_matching => :all) do
    desc 'Optional meta tags to associate to this storage system.'
    validate do |value|
      if not value.is_a?(Hash)
        fail("#{value} is not a Hash")
      elsif value.empty?
        fail('Do not pass empty hash') 
      end

      fail('You need to pass key and valueList keys in hash') unless ['key', 'valueList'].all? {|k| value.has_key? k}
      fail('Do not pass another keys than: key, valueList') if not (value.keys - ['key', 'valueList']).empty?
      fail('value of key should be a String') unless value['key'].is_a? String
      value['valueList'].each do |val|
        fail('valueList should only contain strings') unless val.is_a? String
      end
    end

    def insync?(is)
       sync = true

       fail('You must pass some hash') if should.empty?
       return false unless is.length == @should.length
       return false if is.empty? and not should.empty?
       current = is.sort_by {|hsh| hsh['key']} unless is.empty?
       new = @should.sort_by {|hsh| hsh['key']}

       current.zip(new).each do |x, y|
         return false if  x.nil? or y.nil?
         sync = false unless x['valueList'].sort == y['valueList'].sort
         sync = false unless x['key'] == y['key']
       end
       sync
    end
  end
end
