module CanadaPost
  class Rate

    attr_accessor :service_type, :service_code, :service_link, :total_net_charge, :rate_type,
                  :total_base_charge, :guaranteed_delivery, :expected_transit_time,
                  :expected_delivery_date, :am_delivery

    def initialize(options={})
      @service_type = options[:service_name]
      @service_code = options[:service_code]
      @service_link = options[:service_link]
      @total_net_charge = options[:price_details][:due]
      @total_base_charge = options[:price_details][:base]
      @gst_taxes = options[:price_details][:taxes][:gst]
      @pst_taxes = options[:price_details][:taxes][:pst]
      @hst_taxes = options[:price_details][:taxes][:hst]
      @expected_transit_time = options[:service_standard][:expected_transit_time]
      @expected_delivery_date = options[:service_standard][:expected_delivery_date]
      @guaranteed_delivery = options[:service_standard][:guaranteed_delivery]
      @am_delivery = options[:service_standard][:am_delivery]
    end

    def total_taxes
      (@gst_taxes.to_f + @pst_taxes.to_f + @hst_taxes.to_f).to_s
    end
  end
end
