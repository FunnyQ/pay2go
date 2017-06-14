require 'net/http'
require 'openssl'
require 'cgi'
require 'digest'
require 'pay2go_invoice/errors'
require 'pay2go_invoice/core_ext/hash'

module Pay2goInvoice
  class Client
    INVOICE_ISSUE_API_ENDPOINTS = {
      test: 'https://cinv.pay2go.com/API/invoice_issue',
      production: 'https://inv.pay2go.com/API/invoice_issue'
    }.freeze
    INVOICE_INVALID_API_ENDPOINTS = {
      test: 'https://cinv.pay2go.com/API/invoice_invalid',
      production: 'https://inv.pay2go.com/API/invoice_invalid'
    }.freeze
    ALLOWANCE_ISSUE_API_ENDPOINTS = {
      test: 'https://cinv.pay2go.com/API/allowance_issue',
      production: 'https://inv.pay2go.com/API/allowance_issue'
    }.freeze
    INVOICE_SEARCH_API_ENDPOINTS = {
      test: 'https://cinv.pay2go.com/API/invoice_search',
      production: 'https://inv.pay2go.com/API/invoice_search'
    }
    NEED_CHECK_VALUE_APIS = [
      :query_trade_info # Transaction API
    ]

    attr_reader :options

    def initialize options = {}
      @options = { mode: :production }.merge!(options)

      case @options[:mode]
      when :test, :production
        option_required! :merchant_id, :hash_key, :hash_iv
      else
        raise InvalidMode, %Q{option :mode is either :test or :production}
      end

      @options.freeze
    end

    def verify_check_code params = {}
      stringified_keys = params.stringify_keys
      check_code = stringified_keys.delete('CheckCode')
      make_check_code(stringified_keys) == check_code
    end

    def generate_mpg_params params = {}
      param_required! params, [:MerchantOrderNo, :Amt, :ItemDesc, :Email, :LoginType]

      post_params = {
        RespondType: 'String',
        TimeStamp: Time.now.to_i,
        Version: '1.2'
      }.merge!(params)

      generate_params(:mpg, post_params)
    end

    def make_check_value type, params = {}
      case type
      when :mpg
        check_value_fields = [:Amt, :MerchantID, :MerchantOrderNo, :TimeStamp, :Version]
        padded = "HashKey=#{@options[:hash_key]}&%s&HashIV=#{@options[:hash_iv]}"
      when :query_trade_info
        check_value_fields = [:Amt, :MerchantID, :MerchantOrderNo]
        padded = "IV=#{@options[:hash_iv]}&%s&Key=#{@options[:hash_key]}"
      when :credit_card_period
        check_value_fields = [:MerchantID, :MerchantOrderNo, :PeriodAmt, :PeriodType, :TimeStamp]
        padded = "HashKey=#{@options[:hash_key]}&%s&HashIV=#{@options[:hash_iv]}"
      else
        raise UnsupportedType, "Unsupported API type."
      end

      param_required! params, check_value_fields

      raw = params.select { |key, value| key.to_s.match(/^(#{check_value_fields.join('|')})$/) }
        .sort_by{ |k, v| k.downcase }.map!{ |k, v| "#{k}=#{v}" }.join('&')

      padded = padded % raw

      Digest::SHA256.hexdigest(padded).upcase!
    end

    def encode_post_data data
      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.encrypt
      cipher.padding = 0
      cipher.key = @options[:hash_key]
      cipher.iv = @options[:hash_iv]
      data = add_padding(data)
      encrypted = cipher.update(data) + cipher.final
      encrypted.unpack('H*').first
    end

    def invoice_issue params = {}
      param_required! params, %i[
                                  MerchantOrderNo
                                  Status
                                  Category
                                  BuyerName
                                  PrintFlag
                                  TaxType
                                  TaxRate
                                  Amt
                                  TaxAmt
                                  TotalAmt
                                  ItemName
                                  ItemCount
                                  ItemUnit
                                  ItemPrice
                                  ItemAmt
                                ]

      post_params = {
        RespondType: 'String',
        Version: '1.4',
        TimeStamp: Time.now.to_i
      }.merge!(params)

      post_params.delete_if { |key, value| value.nil? }

      res = request :invoice_issue, post_params
      Hash[res.body.split('&').map!{|i| URI::decode(i.force_encoding('ASCII-8BIT').force_encoding('UTF-8')).split('=')}]
    end

    private

      def option_required! *option_names
        option_names.each do |option_name|
          raise MissingOption, %Q{option "#{option_name}" is required.} if @options[option_name].nil?
        end
      end

      def param_required! params, param_names
        param_names.each do |param_name|
          raise MissingParameter, %Q{param "#{param_name}" is required.} if params[param_name].nil?
        end
      end

      def make_check_code params = {}
        raw = params.select { |key, value| key.to_s.match(/^(Amt|MerchantID|MerchantOrderNo|TradeNo)$/) }
          .sort_by{ |k, v| k.downcase }.map!{ |k, v| "#{k}=#{v}" }.join('&')
        padded = "HashIV=#{@options[:hash_iv]}&#{raw}&HashKey=#{@options[:hash_key]}"
        Digest::SHA256.hexdigest(padded).upcase!
      end

      def generate_params type, overwrite_params = {}
        result = overwrite_params.clone
        result[:MerchantID] = @options[:merchant_id]
        result[:CheckValue] = make_check_value(type, result)
        result
      end

      def request type, params = {}
        case type
        when :invoice_issue
          api_url = INVOICE_ISSUE_API_ENDPOINTS[@options[:mode]]
        end

        if NEED_CHECK_VALUE_APIS.include?(type)
          post_params = generate_params(type, params)
        else
          post_params = {
            MerchantID_: @options[:merchant_id],
            PostData_: encode_post_data(URI.encode(params.map{ |key, value| "#{key}=#{value}" }.join("&")))
          }
        end

        Net::HTTP.post_form URI(api_url), post_params
      end

      def add_padding text, size = 32
        len = text.length
        pad = size - (len % size)
        text = text + (pad.chr * pad)
      end
  end
end
