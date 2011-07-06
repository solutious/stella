
module Familia
  module Tools
    extend self
    def move_keys(filter, source_uri, target_uri, &each_key)
      if target_uri == source_uri
        raise "Source and target are the same (#{target_uri})"
      end
      Familia.connect target_uri
      source_keys = Familia.redis(source_uri).keys(filter)
      puts "Moving #{source_keys.size} keys from #{source_uri} to #{target_uri} (filter: #{filter})"
      source_keys.each_with_index do |key,idx|
        type = Familia.redis(source_uri).type key
        ttl = Familia.redis(source_uri).ttl key
        if source_uri.host == target_uri.host && source_uri.port == target_uri.port
          Familia.redis(source_uri).move key, target_uri.db
        else
          case type
          when "string"
            value = Familia.redis(source_uri).get key
          when "list"
            value = Familia.redis(source_uri).lrange key, 0, -1
          when "set"
            value = Familia.redis(source_uri).smembers key
          else
            raise Familia::Problem, "unknown key type: #{type}"
          end
          raise "Not implemented"
        end
        each_key.call(idx, type, key, ttl) unless each_key.nil?
      end
    end
    # Use the return value from each_key as the new key name
    def rename(filter, source_uri, target_uri=nil, &each_key)
      target_uri ||= source_uri
      move_keys filter, source_uri, target_uri if source_uri != target_uri
      source_keys = Familia.redis(source_uri).keys(filter)
      puts "Renaming #{source_keys.size} keys from #{source_uri} (filter: #{filter})"
      source_keys.each_with_index do |key,idx|
        Familia.trace :RENAME1, Familia.redis(source_uri), "#{key}", ''
        type = Familia.redis(source_uri).type key
        ttl = Familia.redis(source_uri).ttl key
        newkey = each_key.call(idx, type, key, ttl) unless each_key.nil?
        Familia.trace :RENAME2, Familia.redis(source_uri), "#{key} -> #{newkey}", caller[0]
        ret = Familia.redis(source_uri).renamenx key, newkey
      end
    end
    
    def get_any keyname, uri=nil
      type = Familia.redis(uri).type keyname
      case type
      when "string"
        Familia.redis(uri).get keyname
      when "list"
        Familia.redis(uri).lrange(keyname, 0, -1) || []
      when "set"
        Familia.redis(uri).smembers( keyname) || []
      when "zset"
        Familia.redis(uri).zrange(keyname, 0, -1) || []
      when "hash"
        Familia.redis(uri).hgetall(keyname) || {}
      else
        nil
      end
    end
  end
end
