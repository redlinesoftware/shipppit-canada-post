module CanadaPost
  module Helpers

    private
    # Helper method to validate required fields
    def requires!(hash, *params)
       params.each { |param| raise RateError, "Missing Required Parameter #{param}" if hash[param].nil? }
    end

    def underscorize(key) #:nodoc:
      key.to_s.sub(/^(v[0-9]+|ns):/, "").gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
    end

    def dasherize(key)
      key.to_s.gsub('_','-').to_sym
    end

    def hash_to_xml(hash, xml)
      hash.each do |k,v|
        if v.is_a?(Hash)
          xml.send(dasherize(k)) {
            hash_to_xml v, xml
          }
        else
          xml.send dasherize(k), v
        end
      end
    end
  end
end
