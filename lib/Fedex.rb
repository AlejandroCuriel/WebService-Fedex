require "Fedex/version"
require "httparty"
require 'nokogiri'

module Fedex
  class Rates
    def self.rates_info
      #Test
      #Delete: originally they will arrive by parameters
      quote_params = {
        address_from: {
          zip: "28040",
          country: "MX"
        },
        address_to: {
          zip: "28040",
          country: "MX"
        },
        parcel: {
          length: 30.0,
          width: 30.0,
          height: 60.0,
          distance_unit: "cm",
          weight: 12.5,
          mass_unit: "kg"
        }
      }
      credentials = {
        UserCredential: {
          Key: "bkjIgUhxdghtLw9L",
          Password: "6p8oOccHmDwuJZCyJs44wQ0Iw"
        },
        ClientDetail: {
          AccountNumber: "510087720",
          MeterNumber: "119238439",
          Localization: {
            LanguageCode: "es",
            LocaleCode: "mx"
          }
        }
      }

      options = create_xml(credentials, quote_params)
      parsed_info = Nokogiri::XML(options)
      response = HTTParty.post("https://wsbeta.fedex.com:443/xml", body: options)
      puts response.code

      #here you can optimize
      price = response["RateReply"]["RateReplyDetails"][0]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Amount"]
      price2 = response["RateReply"]["RateReplyDetails"][1]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Amount"]
      price3 = response["RateReply"]["RateReplyDetails"][2]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Amount"]

      currency = response["RateReply"]["RateReplyDetails"][0]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Currency"]
      currency2 = response["RateReply"]["RateReplyDetails"][1]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Currency"]
      currency3 = response["RateReply"]["RateReplyDetails"][2]["RatedShipmentDetails"][0]["ShipmentRateDetail"]["TotalNetChargeWithDutiesAndTaxes"]["Currency"]

      name = response["RateReply"]["RateReplyDetails"][0]["ServiceType"].gsub("_"," ").split.map(&:capitalize)
      .join(' ')
      name2 = response["RateReply"]["RateReplyDetails"][1]["ServiceType"].gsub("_"," ").split.map(&:capitalize)
      .join(' ')
      name3 = response["RateReply"]["RateReplyDetails"][2]["ServiceType"].gsub("_"," ").split.map(&:capitalize)
      .join(' ')

      token = response["RateReply"]["RateReplyDetails"][0]["ServiceType"]
      token2 = response["RateReply"]["RateReplyDetails"][1]["ServiceType"]
      token3 = response["RateReply"]["RateReplyDetails"][2]["ServiceType"]


      puts test = [{"price" => "#{price}", "currency" => "#{currency}","service_level" => { "name" => "#{name}", "toke" => "#{token}"} },{"price" => "#{price2}", "currency" => "#{currency2}","service_level" => { "name" => "#{name2
        }", "token" => "#{token2}"} },{"price" => "#{price3}", "currency" => "#{currency3}","service_level" => { "name" => "#{name3}", "token" => "#{token3}"} },]
      # puts response.body
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
