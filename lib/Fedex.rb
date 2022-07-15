require "Fedex/version"
require "httparty"
require 'nokogiri'

module Fedex
  class Rates
    def self.rates_info(credentials, quote_params)
      options = create_xml(credentials, quote_params)
      response = HTTParty.post("https://wsbeta.fedex.com:443/xml", body: options)

      rates = []
      rates_replies = response.dig("RateReply", "RateReplyDetails").first(3)

      rates_replies.each do |rate_reply|
        shipment_detail = rate_reply.dig("RatedShipmentDetails").first.dig("ShipmentRateDetail", "TotalNetChargeWithDutiesAndTaxes")
        rate_reply_type = rate_reply.dig("ServiceType")

        rates << create_rate_response(shipment_detail, rate_reply_type)
      end

      rates
    end

    def self.create_rate_response(shipment_detail, rate_reply_type)
      { price: shipment_detail.dig("Amount"),
        currency: shipment_detail.dig("Currency"),
        service_level: {
          name: rate_reply_type.gsub("_", " ").capitalize,
          token: rate_reply_type
        }
      }
    end

    def self.create_xml(credentials, quote_params)
      "<RateRequest xmlns='http://fedex.com/ws/rate/v13'>
        <WebAuthenticationDetail>
          <UserCredential>
            <Key>#{ credentials.dig(:UserCredential,:Key) }</Key>
            <Password>#{ credentials.dig(:UserCredential,:Password) }</Password>
          </UserCredential>
        </WebAuthenticationDetail>
        <ClientDetail>
          <AccountNumber>#{ credentials.dig(:ClientDetail,:AccountNumber) }</AccountNumber>
          <MeterNumber>#{ credentials.dig(:ClientDetail, :MeterNumber) }</MeterNumber>
          <Localization>
            <LanguageCode>#{ credentials.dig(:ClientDetail, :Localization, :LanguageCode) }</LanguageCode>
            <LocaleCode>#{ credentials.dig(:ClientDetail, :Localization, :LocaleCode) }</LocaleCode>
          </Localization>
        </ClientDetail>
        <Version>
          <ServiceId>crs</ServiceId>
          <Major>13</Major>
          <Intermediate>0</Intermediate>
          <Minor>0</Minor>
        </Version>
        <ReturnTransitAndCommit>true</ReturnTransitAndCommit>
        <RequestedShipment>
          <DropoffType>REGULAR_PICKUP</DropoffType>
          <PackagingType>YOUR_PACKAGING</PackagingType>
          <Shipper>
            <Address>
              <StreetLines></StreetLines>
              <City></City>
              <StateOrProvinceCode>XX</StateOrProvinceCode>
              <PostalCode>#{ quote_params.dig(:address_from, :zip ) }</PostalCode>
              <CountryCode>#{ quote_params.dig(:address_from, :country ) }</CountryCode>
            </Address>
          </Shipper>
          <Recipient>
            <Address>
              <StreetLines></StreetLines>
              <City></City>
              <StateOrProvinceCode>XX</StateOrProvinceCode>
              <PostalCode>#{ quote_params.dig(:address_to, :zip) }</PostalCode>
              <CountryCode>#{ quote_params.dig(:address_to, :country) }</CountryCode>
              <Residential>false</Residential>
            </Address>
          </Recipient>
          <ShippingChargesPayment>
            <PaymentType>SENDER</PaymentType>
          </ShippingChargesPayment>
          <RateRequestTypes>ACCOUNT</RateRequestTypes>
          <PackageCount>1</PackageCount>
          <RequestedPackageLineItems>
            <GroupPackageCount>1</GroupPackageCount>
            <Weight>
              <Units>#{ quote_params.dig(:parcel, :mass_unit).upcase }</Units>
              <Value>#{ quote_params.dig(:parcel, :weight).to_i }</Value>
            </Weight>
            <Dimensions>
            <Length>#{quote_params.dig(:parcel, :length).to_i}</Length>
            <Width>#{quote_params.dig(:parcel, :width).to_i}</Width>
            <Height>#{quote_params.dig(:parcel, :height).to_i}</Height>
            <Units>#{quote_params.dig(:parcel, :distance_unit).upcase}</Units>
            </Dimensions>
          </RequestedPackageLineItems>
        </RequestedShipment>
      </RateRequest>"
    end
  end
end
