require! {
  \ledger-cli : { Ledger }
  express
  \body-parser
}

const PORT = process.env.PORT or 8080

ledger = new Ledger do
  binary: '/usr/bin/ledger'
  file: '/home/amar/src/qif2ledger/ledger.dat'

parse-commodity = ->
  value = it.trim!.replace /[^\d.-]/ ''
  currency = it.replace value, '' .trim!
  currency: currency
  value: parse-float value

parse-info = -> it

parse-posting = ->
  # TODO: Ignore comments
  parts = it.trim!.split /(?:\t|[ ]{2,})+/
  posting = {}
  if parts.length < 2
    return account: parts[0]
  else
    return account: parts[0], commodity: parse-commodity parts[1]

parse-transaction = ->
  lines = it.split \\n

  info = lines.shift!
  postings = []

  sum = {}
  without = null

  for posting in lines
    posting = parse-posting posting
    unless posting.commodity?
      if without?
        throw new Error "Transaction with postings with empty values: #info"
      without := posting
      continue
    sum[posting.commodity.currency] ||= 0
    sum[posting.commodity.currency] += posting.commodity.value
    postings.push posting

  if without?
    for currency, value of sum
      postings.push do
        account: without.account
        commodity:
          currency: currency
          value: -value

  { info, postings }


express!

  #..enable 'trust proxy'

  ..use express.static \www

  ..use body-parser.urlencoded extended: false strict: false

  ..use (req, res, next) !->
    #res.header 'Access-Control-Allow-Origin' \*
    res.header 'Content-Type' \application/json
    next!

  ..get \/accounts (req, res) !->
    #ledger.accounts!.pipe res
    accounts = []
    ledger.accounts!
      ..on \data !-> accounts.push it
      ..on \end !-> accounts |> JSON.stringify |> res.send

  ..get \/transactions (req, res) !->
    transactions = []
    ledger.print!
      ..on \data do ->
        buffer = ''
        !->
          buffer += it
          while ~buffer.index-of \\n\n
            buffer .= split \\n\n
            transactions.push parse-transaction buffer.shift!
            buffer .= join \\n\n
      ..on \end !->  transactions |> JSON.stringify |> res.send

  ..listen PORT
