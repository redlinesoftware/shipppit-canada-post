# CanadaPost REST API V3 Wrapper

[![Build Status](https://semaphoreci.com/api/v1/projects/719f5dd5-e5ff-47f3-a6ff-833ad667ef76/646929/badge.svg)](https://semaphoreci.com/olimart/shipppit-canada-post)

A Ruby wrapper for the CanadaPost REST API. Based extensively off the [fedex](https://github.com/jazminschroeder/fedex) gem.
Thanks to [jazminschroeder](https://github.com/jazminschroeder) and all contributors who helped make that a gem worth recreating for the Canada Post API

For more info see the [Official Canada Post Developer Docs](https://www.canadapost.ca/cpotools/apps/drc/home)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'canada-post-api', github: 'shipppit/shipppit-canada-post'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install canada-post-api

## Usage

Require the gem:

```ruby
require 'canada_post'
```

Create a service:

```ruby
canada_post_service = CanadaPost::Client.new( username: 'xxxx',
									password: 'xxxx',
									customer_number: 'xxxx',
									mode: 'development' )
# mode can be 'development' or 'production'
```

### Define shipper:

```ruby
shipper = { postal_code: 'M5X1B8', country_code: 'CA' }
# Post Code is required for US and CA shipments, not for International Shipments
```

### Define recipient:

```ruby
recipient = { postal_code: 'M5R1C6', country_code: 'CA' }
```

### Define package:

```ruby
package = { weight: { value: 1, units: 'KG' },
            dimensions: { length: 25, width: 15, height: 10, units: 'CM' } }
# weight is the only requirement for your package, Canada Post only accepts KG and CM for the time being
```

### To get service codes:
see [Canada Post Rating API docs](https://www.canadapost.ca/cpo/mc/business/productsservices/developers/services/rating/getrates/default.jsf) for service code descriptions
```ruby
$ CanadaPost::Request::Rate::SERVICE_CODES
$ => ["DOM.RP", "DOM.EP", "DOM.XP", "DOM.XP.CERT", "DOM.PC.CERT", "DOM.PC", "DOM.DT", "DOM.LIB", "USA.EP", "USA.PW.ENV", "USA.PW.PAK", "USA.PW.PARCEL", "USA.SP.AIR", "USA.TP", "USA.TP.LVM", "USA.XP", "INT.XP", "INT.IP.AIR", "INT.IP.SURF", "INT.PW.ENV", "INT.PW.PAK", "INT.PW.PARCEL", "INT.SP.AIR", "INT.SP.SURF", "INT.TP"]
```

### Get Rates:

```ruby
$ rates = canada_post_service.rate( shipper: shipper,
                                    recipient: recipient,
                                    package: package )
```

Not specifying a service type will return an array of all available rates

```ruby
# complete response
$ [#<CanadaPost::Rate:0x007fd783f42a88 @service_type="Expedited Parcel", @service_code="DOM.EP", @total_net_charge="8.76", @total_base_charge="7.77", @gst_taxes="0.00", @pst_taxes="0.00", @hst_taxes="1.01", @expected_transit_time="1">, #<CanadaPost::Rate:0x007fd783f42a60 @service_type="Priority", @service_code="DOM.PC", @total_net_charge="19.14", @total_base_charge="16.21", @gst_taxes="0.00", @pst_taxes="0.00", @hst_taxes="2.20", @expected_transit_time="1">, #<CanadaPost::Rate:0x007fd783f42a10 @service_type="Regular Parcel", @service_code="DOM.RP", @total_net_charge="8.76", @total_base_charge="7.77", @gst_taxes="0.00", @pst_taxes="0.00", @hst_taxes="1.01", @expected_transit_time="2">, #<CanadaPost::Rate:0x007fd783f429e8 @service_type="Xpresspost", @service_code="DOM.XP", @total_net_charge="11.31", @total_base_charge="9.58", @gst_taxes="0.00", @pst_taxes="0.00", @hst_taxes="1.30", @expected_transit_time="1">]
```

Specifying the service type will return one result

```ruby
$ service_type = 'DOM.EP'
$ rates = canada_post_service.rate( shipper: shipper,
                                    recipient: recipient,
                                    package: package,
                                    service_type: service_type )
# complete response
$ [
	#<CanadaPost::Rate:0x007fd783fea238
		@service_type="Expedited Parcel",
		@service_code="DOM.EP",
		@total_net_charge="8.76",
		@total_base_charge="7.77",
		@gst_taxes="0.00",
		@pst_taxes="0.00",
		@hst_taxes="1.01",
		@expected_transit_time="1",
    @expected_delivery_date="2015-12-25",
    @guaranteed_delivery="false",
    @am_delivery="false">
  ]
```


### Create Shipping

```ruby
sender = {
  name: 'John Doe',
  company: 'sender company',
  shipping_point: 'M5X1B8',
  address_details: {
    address: '123 street',
    phone: '343434',
    state: 'QC'
    zip: 'M5X1B8',
    city: 'Gatineau',
    country: 'CA'
  }
}
destination = {
  name: 'John Doe',
  company: 'receiver company',
  address_details: {
    address: '4394 Rue Saint-Denis',
    state: 'QC'
    zip: 'H2J2L1',
    city: 'Montréal',
    country: 'CA'
  }
}
package = {
 weight: 2,
 unpackaged: false,
 mailing_tube: false,
 dimensions: {
   length: 2,
   width: 2
   height: 2
 }
}
notification = {
  email: 'example@gmail.com',
  on_shipment: true,
  on_exception: true,
  on_delivery: true
}
preferences = {
  show_packing_instructions: true,
  show_postage_rate: true,
  show_insured_value: true
}
settlement_info = {
  contract_id: 2514533 // 2514533 for sendbox mode
}

canada_post_service.create(
  sender: sender,
  destination: destination,
  package: package,
  notification: notification,
  preferences: preferences,
  settlement_info: settlement_info,
  group_id: '5241556',
  mailing_date: '2016-01-20',
  contract_id: '2514533',
  service_code: 'DOM.RP'
)

Response:
{
  create_shipping: {create shipping response},
  transmit_shipping: {transmit shipping response}
}

Error Code:

{
  create_shipping: {errors: 'comma separated error essages'},
  transmit_shipping: {errors: 'comma separated error messages'}
}
```

### Create shipping on behalf of

```ruby
Pass additional information to create shipment on behalf of merchant.
Merchant information can be retrieved after registering merchant in your platform.

canada_post_service.create(
  mobo: {
     username: 'xxx',
     password: 'password',
     customer_number: '123456789',
     contract_number: '987654321'
  }
)
```

### Merchant registration

Use this call to get a unique registration token (token-id) required to launch a merchant into the Canada Post sign-up process.

```ruby
@token = canada_post_service.registration
{'token-id' => '11111111111111111111111'}
```

With the token-id in hand, complete the registration process by making another POST request to https://www.canadapost.ca/cpotools/apps/drc/merchant with the following fields:
- return-url // callback url to your application
- token-id
- platform-id

Canada Post service will redirect the user to the designated callback URL along with the required information to perform shipping transactions for the merchant (username, password, customer_number and contract_number).


### Get shipping price

```ruby
response = canada_post_service.get_price(shipping_id)

{
  :shipment_price=>{
    :xmlns=>"http://www.canadapost.ca/ws/shipment-v7", :service_code=>"DOM.EP", :base_amount=>"10.21",
    :priced_options=>{
      :priced_option=> {:option_code=>"DC", :option_price=>"0.00"}
    },
    :adjustments=>{
      :adjustment=>{
        :adjustment_code=>"FUELSC", :adjustment_amount=>"0.43"
      }
    },
    :pre_tax_amount=>"10.64", :gst_amount=>"0.53", :pst_amount=>"0.00", :hst_amount=>"0.00", :due_amount=>"11.17", :service_standard=>{
      :am_delivery=>"false", :guaranteed_delivery=>"true", :expected_transmit_time=>"1", :expected_delivery_date=>"2016-01-14"
    },
    :rated_weight=>"2.000"
  }
}
```

### Get shipping details

```ruby
response = canada_post_service.details(shipping_id)

{:shipment_details=>{:xmlns=>"http://www.canadapost.ca/ws/shipment-v7", :shipment_status=>"created", :final_shipping_point=>"M5X1C0", :shipping_point_id=>"7100", :tracking_pin=>"123456789012", :shipment_detail=>{:group_id=>"5241556", :expected_mailing_date=>"2016-01-13", :delivery_spec=>{:service_code=>"DOM.EP", :sender=>{:name=>"John Doe", :company=>"Apple", :contact_phone=>"343434", :address_details=>{:address_line_1=>"600 blvd Alexandre Taché", :city=>"Gatineau", :prov_state=>"QC", :country_code=>"CA", :postal_zip_code=>"M5X1B8"}}, :destination=>{:name=>"receiver", :company=>"receiver company", :address_details=>{:address_line_1=>"4394 Rue Saint-Denis", :city=>"Montréal", :prov_state=>"QC", :country_code=>"CA", :postal_zip_code=>"H2J2L1"}}, :options=>{:option=>{:option_code=>"DC"}}, :parcel_characteristics=>{:weight=>"2.000", :dimensions=>{:length=>"2.0", :width=>"2.0", :height=>"2.0"}, :unpackaged=>"false", :mailing_tube=>"false", :oversized=>"false"}, :notification=>{:email=>"user@gmail.com", :on_shipment=>"true", :on_exception=>"false", :on_delivery=>"true"}, :print_preferences=>{:output_format=>"8.5x11", :encoding=>"PDF"}, :preferences=>{:show_packing_instructions=>"true", :show_postage_rate=>"false", :show_insured_value=>"true"}, :settlement_info=>{:paid_by_customer=>"0002004381", :contract_id=>"0042708517", :intended_method_of_payment=>"Account"}}}}}

```

### Get shipping label

```ruby
canada_post_service.get_label(label_url)
```
this return a pdf response with label details.

### Get manifest

```ruby
response = canada_post_service.get_manifest(manifest_url)

{:manifest=>{:xmlns=>"http://www.canadapost.ca/ws/manifest-v7", :po_number=>"P123456789", :links=>{:link=>[{:rel=>"self", :href=>"https://ct.soa-gw.canadapost.ca/rs/0002004381/0002004381/manifest/96011452532284803", :media_type=>"application/vnd.cpc.manifest-v7+xml"}, {:rel=>"details", :href=>"https://ct.soa-gw.canadapost.ca/rs/0002004381/0002004381/manifest/96011452532284803/details", :media_type=>"application/vnd.cpc.manifest-v7+xml"}, {:rel=>"manifestShipments", :href=>"https://ct.soa-gw.canadapost.ca/rs/0002004381/0002004381/shipment?manifestId=96011452532284803", :media_type=>"application/vnd.cpc.shipment-v7+xml"}, {:rel=>"artifact", :href=>"https://ct.soa-gw.canadapost.ca/ers/artifact/6e93d53968881714/400811/0", :media_type=>"application/pdf"}]}}}
```

### Get artifact
```ruby
response = canada_post_service.get_artifact(artifact_url)
Response:
{
  status: true,
  artifact: artifact // pdf response
}

Error:
{
  status: false,
  error: 'artifact error message'
}
```

Your final amount will be under `total_net_charge`:

```ruby
$ rates.first.total_net_charge => '8.76' # all monetary values are CAD
```

This is still a work in progress but feel free to contribute if it will benefit you!

## Contributing

1. Fork it ( https://github.com/[my-github-username]/canada-post-api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Run test suite `bundle exec rspec spec`
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
