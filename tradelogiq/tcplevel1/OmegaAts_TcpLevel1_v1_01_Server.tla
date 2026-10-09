------------------ MODULE OmegaAts_TcpLevel1_v1_01_Server ------------------
(***************************************************************************)
(* Tradelogiq Markets Inc. Omega Tcp Level 1 v1.01                         *)
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
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

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
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ payload : Payload ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

DecodeSequencedDataPacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

ZeroSequencedDataPacket ==
    [ payload |-> ZeroPayload ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
ServerHeartbeatCode == 72  \* "H"
SequencedDataPacketCode == 83  \* "S"

ServerPayload ==
    [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Soup Tcp Packet, framed by Packet Length                         *)
(***************************************************************************)

ServerSoupTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupTcpPacket(message) ==
    LET body == EncodeServerSoupTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupTcpPacket ==
    { ZeroServerSoupTcpPacket }
        \cup { [ZeroServerSoupTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupTcpPacketList(_)
EncodeServerSoupTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupTcpPacket(Head(messages)) \o EncodeServerSoupTcpPacketList(Tail(messages))

(* As many Server Soup Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupTcpPacketAll(_)
ReadServerSoupTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupTcpPacket ==
    { [ZeroServerSoupTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupTcpPacket : SampleLists(OneServerSoupTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupTcpPacketList(message.serverSoupTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupTcpPacket == ReadServerSoupTcpPacketAll(bytes) IN IF ~serverSoupTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupTcpPacket |-> serverSoupTcpPacket.value ], serverSoupTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupTcpPacket = one] : one \in SampleLists(OneServerSoupTcpPacket) }

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

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupTcpPacket ==
    \A message \in CheckedServerSoupTcpPacket :
        LET read == DecodeServerSoupTcpPacket(EncodeServerSoupTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupTcpPacket ==
    \A message \in CheckedServerSoupTcpPacket :
        LET bytes == EncodeServerSoupTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
