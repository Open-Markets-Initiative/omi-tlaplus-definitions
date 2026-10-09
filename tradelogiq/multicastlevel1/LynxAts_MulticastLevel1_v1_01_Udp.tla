----------------- MODULE LynxAts_MulticastLevel1_v1_01_Udp -----------------
(***************************************************************************)
(* Tradelogiq Markets Inc. Lynx Multicast Level 1 v1.01                    *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(*                                                                         *)
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Quote Message: 43 bytes                                                 *)
(***************************************************************************)

QuoteMessage ==
    [ reserved1    : Sample(1),
      stockSymbol  : Sample(10),
      timestamp    : Sample(8),
      bestBidPrice : Sample(8),
      bestBidSize  : Sample(4),
      bestAskPrice : Sample(8),
      bestAskSize  : Sample(4) ]

EncodeQuoteMessage(message) ==
    message.reserved1
        \o message.stockSymbol
        \o message.timestamp
        \o message.bestBidPrice
        \o message.bestBidSize
        \o message.bestAskPrice
        \o message.bestAskSize

DecodeQuoteMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(reserved1.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockSymbol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(timestamp.rest, 8) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidSize.rest, 8) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestAskSize == ReadBytes(bestAskPrice.rest, 4) IN IF ~bestAskSize.ok THEN Fail ELSE
    Ok([ reserved1    |-> reserved1.value,
         stockSymbol  |-> stockSymbol.value,
         timestamp    |-> timestamp.value,
         bestBidPrice |-> bestBidPrice.value,
         bestBidSize  |-> bestBidSize.value,
         bestAskPrice |-> bestAskPrice.value,
         bestAskSize  |-> bestAskSize.value ], bestAskSize.rest)

ZeroQuoteMessage ==
    [ reserved1    |-> [i \in 1 .. 1 |-> 0],
      stockSymbol  |-> [i \in 1 .. 10 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      bestBidPrice |-> [i \in 1 .. 8 |-> 0],
      bestBidSize  |-> [i \in 1 .. 4 |-> 0],
      bestAskPrice |-> [i \in 1 .. 8 |-> 0],
      bestAskSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMessage ==
    { ZeroQuoteMessage }
        \cup { [ZeroQuoteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroQuoteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.bestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMessage EXCEPT !.bestAskPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMessage EXCEPT !.bestAskSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report Message: 43 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ conditions  : Sample(5),
      stockSymbol : Sample(10),
      timestamp   : Sample(8),
      tradeId     : Sample(4),
      tradePrice  : Sample(8),
      tradeSize   : Sample(4),
      buyBroker   : Sample(2),
      sellBroker  : Sample(2) ]

EncodeTradeReportMessage(message) ==
    message.conditions
        \o message.stockSymbol
        \o message.timestamp
        \o message.tradeId
        \o message.tradePrice
        \o message.tradeSize
        \o message.buyBroker
        \o message.sellBroker

DecodeTradeReportMessage(bytes) ==
    LET conditions == ReadBytes(bytes, 5) IN IF ~conditions.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(conditions.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockSymbol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeId == ReadBytes(timestamp.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeId.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET buyBroker == ReadBytes(tradeSize.rest, 2) IN IF ~buyBroker.ok THEN Fail ELSE
    LET sellBroker == ReadBytes(buyBroker.rest, 2) IN IF ~sellBroker.ok THEN Fail ELSE
    Ok([ conditions  |-> conditions.value,
         stockSymbol |-> stockSymbol.value,
         timestamp   |-> timestamp.value,
         tradeId     |-> tradeId.value,
         tradePrice  |-> tradePrice.value,
         tradeSize   |-> tradeSize.value,
         buyBroker   |-> buyBroker.value,
         sellBroker  |-> sellBroker.value ], sellBroker.rest)

ZeroTradeReportMessage ==
    [ conditions  |-> [i \in 1 .. 5 |-> 0],
      stockSymbol |-> [i \in 1 .. 10 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0],
      tradeId     |-> [i \in 1 .. 4 |-> 0],
      tradePrice  |-> [i \in 1 .. 8 |-> 0],
      tradeSize   |-> [i \in 1 .. 4 |-> 0],
      buyBroker   |-> [i \in 1 .. 2 |-> 0],
      sellBroker  |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.conditions = one] : one \in Sample(5) }
        \cup { [ZeroTradeReportMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.buyBroker = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessage EXCEPT !.sellBroker = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Bust Message: 23 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ reserved1   : Sample(1),
      stockSymbol : Sample(10),
      timestamp   : Sample(8),
      tradeId     : Sample(4) ]

EncodeTradeBustMessage(message) ==
    message.reserved1
        \o message.stockSymbol
        \o message.timestamp
        \o message.tradeId

DecodeTradeBustMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(reserved1.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockSymbol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradeId == ReadBytes(timestamp.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ reserved1   |-> reserved1.value,
         stockSymbol |-> stockSymbol.value,
         timestamp   |-> timestamp.value,
         tradeId     |-> tradeId.value ], tradeId.rest)

ZeroTradeBustMessage ==
    [ reserved1   |-> [i \in 1 .. 1 |-> 0],
      stockSymbol |-> [i \in 1 .. 10 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0],
      tradeId     |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Correction Message: 47 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ reserved1           : Sample(1),
      stockSymbol         : Sample(10),
      timestamp           : Sample(8),
      originalTradeId     : Sample(4),
      originalTradePrice  : Sample(8),
      originalTradeSize   : Sample(4),
      correctedTradePrice : Sample(8),
      correctedTradeSize  : Sample(4) ]

EncodeTradeCorrectionMessage(message) ==
    message.reserved1
        \o message.stockSymbol
        \o message.timestamp
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.correctedTradePrice
        \o message.correctedTradeSize

DecodeTradeCorrectionMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET stockSymbol == ReadBytes(reserved1.rest, 10) IN IF ~stockSymbol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockSymbol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(timestamp.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(originalTradeSize.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    Ok([ reserved1           |-> reserved1.value,
         stockSymbol         |-> stockSymbol.value,
         timestamp           |-> timestamp.value,
         originalTradeId     |-> originalTradeId.value,
         originalTradePrice  |-> originalTradePrice.value,
         originalTradeSize   |-> originalTradeSize.value,
         correctedTradePrice |-> correctedTradePrice.value,
         correctedTradeSize  |-> correctedTradeSize.value ], correctedTradeSize.rest)

ZeroTradeCorrectionMessage ==
    [ reserved1           |-> [i \in 1 .. 1 |-> 0],
      stockSymbol         |-> [i \in 1 .. 10 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      originalTradeId     |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice  |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize   |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice |-> [i \in 1 .. 8 |-> 0],
      correctedTradeSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.stockSymbol = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ eventCode : Sample(1),
      reserved2 : Sample(2),
      timestamp : Sample(8) ]

EncodeSystemEventMessage(message) ==
    message.eventCode
        \o message.reserved2
        \o message.timestamp

DecodeSystemEventMessage(bytes) ==
    LET eventCode == ReadBytes(bytes, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(eventCode.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved2.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ eventCode |-> eventCode.value,
         reserved2 |-> reserved2.value,
         timestamp |-> timestamp.value ], timestamp.rest)

ZeroSystemEventMessage ==
    [ eventCode |-> [i \in 1 .. 1 |-> 0],
      reserved2 |-> [i \in 1 .. 2 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Stock Directory Message: 39 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ market            : Sample(1),
      stock             : Sample(10),
      timestamp         : Sample(8),
      boardLotSize      : Sample(4),
      instrumentId      : Sample(2),
      shortable         : Sample(1),
      dividendIndicator : Sample(1),
      reserved9         : Sample(9),
      currency          : Sample(3) ]

EncodeStockDirectoryMessage(message) ==
    message.market
        \o message.stock
        \o message.timestamp
        \o message.boardLotSize
        \o message.instrumentId
        \o message.shortable
        \o message.dividendIndicator
        \o message.reserved9
        \o message.currency

DecodeStockDirectoryMessage(bytes) ==
    LET market == ReadBytes(bytes, 1) IN IF ~market.ok THEN Fail ELSE
    LET stock == ReadBytes(market.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stock.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(timestamp.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(boardLotSize.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET shortable == ReadBytes(instrumentId.rest, 1) IN IF ~shortable.ok THEN Fail ELSE
    LET dividendIndicator == ReadBytes(shortable.rest, 1) IN IF ~dividendIndicator.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(dividendIndicator.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved9.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    Ok([ market            |-> market.value,
         stock             |-> stock.value,
         timestamp         |-> timestamp.value,
         boardLotSize      |-> boardLotSize.value,
         instrumentId      |-> instrumentId.value,
         shortable         |-> shortable.value,
         dividendIndicator |-> dividendIndicator.value,
         reserved9         |-> reserved9.value,
         currency          |-> currency.value ], currency.rest)

ZeroStockDirectoryMessage ==
    [ market            |-> [i \in 1 .. 1 |-> 0],
      stock             |-> [i \in 1 .. 10 |-> 0],
      timestamp         |-> [i \in 1 .. 8 |-> 0],
      boardLotSize      |-> [i \in 1 .. 4 |-> 0],
      instrumentId      |-> [i \in 1 .. 2 |-> 0],
      shortable         |-> [i \in 1 .. 1 |-> 0],
      dividendIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved9         |-> [i \in 1 .. 9 |-> 0],
      currency          |-> [i \in 1 .. 3 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortable = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.dividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }

(***************************************************************************)
(* Extended Stock Directory Message: 71 bytes                              *)
(***************************************************************************)

ExtendedStockDirectoryMessage ==
    [ market       : Sample(1),
      stock        : Sample(10),
      timestamp    : Sample(8),
      boardLotSize : Sample(4),
      instrumentId : Sample(2),
      shortable    : Sample(1),
      frequency    : Sample(1),
      reserved9    : Sample(9),
      currency     : Sample(3),
      securityType : Sample(1),
      expiryDate   : Sample(8),
      description  : Sample(20),
      reserved3    : Sample(3) ]

EncodeExtendedStockDirectoryMessage(message) ==
    message.market
        \o message.stock
        \o message.timestamp
        \o message.boardLotSize
        \o message.instrumentId
        \o message.shortable
        \o message.frequency
        \o message.reserved9
        \o message.currency
        \o message.securityType
        \o message.expiryDate
        \o message.description
        \o message.reserved3

DecodeExtendedStockDirectoryMessage(bytes) ==
    LET market == ReadBytes(bytes, 1) IN IF ~market.ok THEN Fail ELSE
    LET stock == ReadBytes(market.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stock.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET boardLotSize == ReadBytes(timestamp.rest, 4) IN IF ~boardLotSize.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(boardLotSize.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET shortable == ReadBytes(instrumentId.rest, 1) IN IF ~shortable.ok THEN Fail ELSE
    LET frequency == ReadBytes(shortable.rest, 1) IN IF ~frequency.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(frequency.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET currency == ReadBytes(reserved9.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET securityType == ReadBytes(currency.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(securityType.rest, 8) IN IF ~expiryDate.ok THEN Fail ELSE
    LET description == ReadBytes(expiryDate.rest, 20) IN IF ~description.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(description.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ market       |-> market.value,
         stock        |-> stock.value,
         timestamp    |-> timestamp.value,
         boardLotSize |-> boardLotSize.value,
         instrumentId |-> instrumentId.value,
         shortable    |-> shortable.value,
         frequency    |-> frequency.value,
         reserved9    |-> reserved9.value,
         currency     |-> currency.value,
         securityType |-> securityType.value,
         expiryDate   |-> expiryDate.value,
         description  |-> description.value,
         reserved3    |-> reserved3.value ], reserved3.rest)

ZeroExtendedStockDirectoryMessage ==
    [ market       |-> [i \in 1 .. 1 |-> 0],
      stock        |-> [i \in 1 .. 10 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      boardLotSize |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 2 |-> 0],
      shortable    |-> [i \in 1 .. 1 |-> 0],
      frequency    |-> [i \in 1 .. 1 |-> 0],
      reserved9    |-> [i \in 1 .. 9 |-> 0],
      currency     |-> [i \in 1 .. 3 |-> 0],
      securityType |-> [i \in 1 .. 1 |-> 0],
      expiryDate   |-> [i \in 1 .. 8 |-> 0],
      description  |-> [i \in 1 .. 20 |-> 0],
      reserved3    |-> [i \in 1 .. 3 |-> 0] ]

(* Extended Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedExtendedStockDirectoryMessage ==
    { ZeroExtendedStockDirectoryMessage }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.boardLotSize = one] : one \in Sample(4) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.shortable = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.frequency = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.expiryDate = one] : one \in Sample(8) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.description = one] : one \in Sample(20) }
        \cup { [ZeroExtendedStockDirectoryMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Stock Status Message: 23 bytes                                          *)
(***************************************************************************)

StockStatusMessage ==
    [ tradingState : Sample(1),
      stock        : Sample(10),
      timestamp    : Sample(8),
      reason       : Sample(4) ]

EncodeStockStatusMessage(message) ==
    message.tradingState
        \o message.stock
        \o message.timestamp
        \o message.reason

DecodeStockStatusMessage(bytes) ==
    LET tradingState == ReadBytes(bytes, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET stock == ReadBytes(tradingState.rest, 10) IN IF ~stock.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stock.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reason == ReadBytes(timestamp.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ tradingState |-> tradingState.value,
         stock        |-> stock.value,
         timestamp    |-> timestamp.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockStatusMessage ==
    [ tradingState |-> [i \in 1 .. 1 |-> 0],
      stock        |-> [i \in 1 .. 10 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      reason       |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStatusMessage ==
    { ZeroStockStatusMessage }
        \cup { [ZeroStockStatusMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockStatusMessage EXCEPT !.stock = one] : one \in Sample(10) }
        \cup { [ZeroStockStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockStatusMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

QuoteMessageCode == 87  \* "W"
TradeReportMessageCode == 84  \* "T"
TradeBustMessageCode == 78  \* "N"
TradeCorrectionMessageCode == 77  \* "M"
SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
ExtendedStockDirectoryMessageCode == 114  \* "r"
StockStatusMessageCode == 72  \* "H"

Payload ==
    [ tag : {QuoteMessageCode}, body : QuoteMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {ExtendedStockDirectoryMessageCode}, body : ExtendedStockDirectoryMessage ]
        \cup [ tag : {StockStatusMessageCode}, body : StockStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = QuoteMessageCode -> EncodeQuoteMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = ExtendedStockDirectoryMessageCode -> EncodeExtendedStockDirectoryMessage(message.body)
      [] message.tag = StockStatusMessageCode -> EncodeStockStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = QuoteMessageCode -> DecodeQuoteMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = ExtendedStockDirectoryMessageCode -> DecodeExtendedStockDirectoryMessage(bytes)
              [] tag = StockStatusMessageCode -> DecodeStockStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> QuoteMessageCode, body |-> one] : one \in CheckedQuoteMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> ExtendedStockDirectoryMessageCode, body |-> one] : one \in CheckedExtendedStockDirectoryMessage }
        \cup { [tag |-> StockStatusMessageCode, body |-> one] : one \in CheckedStockStatusMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> QuoteMessageCode, body |-> ZeroQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedStockDirectoryMessageCode, body |-> ZeroExtendedStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockStatusMessageCode, body |-> ZeroStockStatusMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMessage ==
    \A message \in CheckedQuoteMessage :
        LET read == DecodeQuoteMessage(EncodeQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustMessage ==
    \A message \in CheckedTradeBustMessage :
        LET read == DecodeTradeBustMessage(EncodeTradeBustMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedStockDirectoryMessage ==
    \A message \in CheckedExtendedStockDirectoryMessage :
        LET read == DecodeExtendedStockDirectoryMessage(EncodeExtendedStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStatusMessage ==
    \A message \in CheckedStockStatusMessage :
        LET read == DecodeStockStatusMessage(EncodeStockStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
