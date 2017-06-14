# 智付寶電子發票加值服務平台 Pay2go invoice

這是智付寶電子發票加值服務平台 API 的 Ruby 包裝，更多資訊請參閱 [API 文件專區](https://inv.pay2go.com/Invoice_index/download)。

- 這不是 Rails 插件，只是個 API 包裝。
- 使用時只需要傳送需要的參數即可，不用產生檢查碼，`pay2go_invoice_client` 會自己產生。
- 感謝[大兜](https://github.com/tonytonyjan)撰寫的 [allpay](https://github.com/tonytonyjan/allpay)

## 安裝

```bash
gem install pay2go_invoice_client
```

## 使用

```ruby
test_client = Pay2goInvoice::Client.new({
  merchant_id: 'MERCHANT_ID',
  hash_key: 'HASH_KEY',
  hash_iv: 'HASH_IV',
  mode: :test
})

production_client = Pay2goInvoice::Client.new({
  merchant_id: 'MERCHANT_ID',
  hash_key: 'HASH_KEY',
  hash_iv: 'HASH_IV'
})

test_client.query_trade_info({
  MerchantOrderNo: '4e19cab1',
  Amt: 100
})
```

本文件撰寫時，智付寶電子發票加值服務平台共有 5 個 API：

API 名稱           | 說明
---                  | ---
開立發票              | ...
觸發開立發票          | ...
作廢發票              | ...
折讓發票              | ...
查詢發票              | ...

詳細 API 參數請參閱智付寶技術串接手冊，注意幾點：

- 使用時不用煩惱 `MerchantID`、`RespondType`、`CheckValue`、`TimeStamp` 及 `Version`，正如上述範例一樣。

## Pay2goInvoice::Client

實體方法                                                   | 回傳       | 說明
---                                                       | ---       | ---
`verify_check_code(params)`                               | `Boolean` | 用於檢查收到的參數，其檢查碼是否正確，用於智付寶的 `NotifyURL` 參數及檢核資料回傳的合法性。
`generate_mpg_params(params)`                             | `Hash`    | 用於產生 MPG API 表單需要的參數。
`invoice_issue(params)`                                   | `Hash`    | 用於立即開立發票。

## 使用範例

##### 開立發票

...

## License
MIT

![Analytics](https://ga-beacon.appspot.com/UA-44933497-3/CalvertYang/pay2go?pixel)
