---------------- MODULE OmegaAts_MulticastLevel2_v2_01_Udp -----------------
(***************************************************************************)
(* Tradelogiq Markets Inc. Omega Multicast Level 2 v2.01                   *)
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
(* Stock Trading Action Message: 15 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ tradingState : Sample(1),
      instrumentId : Sample(2),
      timestamp    : Sample(8),
      reason       : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.tradingState
        \o message.instrumentId
        \o message.timestamp
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET tradingState == ReadBytes(bytes, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradingState.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET reason == ReadBytes(timestamp.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ tradingState |-> tradingState.value,
         instrumentId |-> instrumentId.value,
         timestamp    |-> timestamp.value,
         reason       |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ tradingState |-> [i \in 1 .. 1 |-> 0],
      instrumentId |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      reason       |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 27 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ buySellIndicator     : Sample(1),
      instrumentId         : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(4),
      shares               : Sample(4),
      price                : Sample(4),
      execBrokerId         : Sample(2),
      reserved2            : Sample(2) ]

EncodeAddOrderMessage(message) ==
    message.buySellIndicator
        \o message.instrumentId
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.shares
        \o message.price
        \o message.execBrokerId
        \o message.reserved2

DecodeAddOrderMessage(bytes) ==
    LET buySellIndicator == ReadBytes(bytes, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(buySellIndicator.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET execBrokerId == ReadBytes(price.rest, 2) IN IF ~execBrokerId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(execBrokerId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ buySellIndicator     |-> buySellIndicator.value,
         instrumentId         |-> instrumentId.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         shares               |-> shares.value,
         price                |-> price.value,
         execBrokerId         |-> execBrokerId.value,
         reserved2            |-> reserved2.value ], reserved2.rest)

ZeroAddOrderMessage ==
    [ buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      instrumentId         |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      execBrokerId         |-> [i \in 1 .. 2 |-> 0],
      reserved2            |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.execBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Executed Message: 27 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ marker               : Sample(1),
      instrumentId         : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(4),
      executedShares       : Sample(4),
      matchNumber          : Sample(4),
      contraBrokerId       : Sample(2),
      reserved2            : Sample(2) ]

EncodeOrderExecutedMessage(message) ==
    message.marker
        \o message.instrumentId
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber
        \o message.contraBrokerId
        \o message.reserved2

DecodeOrderExecutedMessage(bytes) ==
    LET marker == ReadBytes(bytes, 1) IN IF ~marker.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(marker.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET contraBrokerId == ReadBytes(matchNumber.rest, 2) IN IF ~contraBrokerId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(contraBrokerId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ marker               |-> marker.value,
         instrumentId         |-> instrumentId.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value,
         contraBrokerId       |-> contraBrokerId.value,
         reserved2            |-> reserved2.value ], reserved2.rest)

ZeroOrderExecutedMessage ==
    [ marker               |-> [i \in 1 .. 1 |-> 0],
      instrumentId         |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      contraBrokerId       |-> [i \in 1 .. 2 |-> 0],
      reserved2            |-> [i \in 1 .. 2 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.marker = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Executed With Price Message: 31 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ marker               : Sample(1),
      instrumentId         : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(4),
      executedShares       : Sample(4),
      executionPrice       : Sample(4),
      matchNumber          : Sample(4),
      contraBrokerId       : Sample(2),
      reserved2            : Sample(2) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.marker
        \o message.instrumentId
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.executionPrice
        \o message.matchNumber
        \o message.contraBrokerId
        \o message.reserved2

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET marker == ReadBytes(bytes, 1) IN IF ~marker.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(marker.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(executedShares.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executionPrice.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET contraBrokerId == ReadBytes(matchNumber.rest, 2) IN IF ~contraBrokerId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(contraBrokerId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ marker               |-> marker.value,
         instrumentId         |-> instrumentId.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         executionPrice       |-> executionPrice.value,
         matchNumber          |-> matchNumber.value,
         contraBrokerId       |-> contraBrokerId.value,
         reserved2            |-> reserved2.value ], reserved2.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ marker               |-> [i \in 1 .. 1 |-> 0],
      instrumentId         |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      executionPrice       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 4 |-> 0],
      contraBrokerId       |-> [i \in 1 .. 2 |-> 0],
      reserved2            |-> [i \in 1 .. 2 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.marker = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.contraBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Delete Message: 15 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ reserved1            : Sample(1),
      instrumentId         : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(4) ]

EncodeOrderDeleteMessage(message) ==
    message.reserved1
        \o message.instrumentId
        \o message.timestamp
        \o message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ reserved1            |-> reserved1.value,
         instrumentId         |-> instrumentId.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ reserved1            |-> [i \in 1 .. 1 |-> 0],
      instrumentId         |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Message: 27 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ reserved1                    : Sample(1),
      instrumentId                 : Sample(2),
      timestamp                    : Sample(8),
      originalOrderReferenceNumber : Sample(4),
      newOrderReferenceNumber      : Sample(4),
      shares                       : Sample(4),
      price                        : Sample(4) ]

EncodeOrderReplaceMessage(message) ==
    message.reserved1
        \o message.instrumentId
        \o message.timestamp
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.shares
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 4) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ reserved1                    |-> reserved1.value,
         instrumentId                 |-> instrumentId.value,
         timestamp                    |-> timestamp.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         shares                       |-> shares.value,
         price                        |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ reserved1                    |-> [i \in 1 .. 1 |-> 0],
      instrumentId                 |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 8 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 4 |-> 0],
      shares                       |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 19 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ reserved1            : Sample(1),
      instrumentId         : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(4),
      cancelledShares      : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.reserved1
        \o message.instrumentId
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.cancelledShares

DecodeOrderCancelMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 4) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET cancelledShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~cancelledShares.ok THEN Fail ELSE
    Ok([ reserved1            |-> reserved1.value,
         instrumentId         |-> instrumentId.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         cancelledShares      |-> cancelledShares.value ], cancelledShares.rest)

ZeroOrderCancelMessage ==
    [ reserved1            |-> [i \in 1 .. 1 |-> 0],
      instrumentId         |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 4 |-> 0],
      cancelledShares      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledShares = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 31 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ side              : Sample(1),
      instrumentId      : Sample(2),
      timestamp         : Sample(8),
      midpointBookTrade : Sample(4),
      shares            : Sample(4),
      price             : Sample(4),
      matchNumber       : Sample(4),
      buyBrokerId       : Sample(2),
      sellBrokerId      : Sample(2) ]

EncodeTradeMessage(message) ==
    message.side
        \o message.instrumentId
        \o message.timestamp
        \o message.midpointBookTrade
        \o message.shares
        \o message.price
        \o message.matchNumber
        \o message.buyBrokerId
        \o message.sellBrokerId

DecodeTradeMessage(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(side.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET midpointBookTrade == ReadBytes(timestamp.rest, 4) IN IF ~midpointBookTrade.ok THEN Fail ELSE
    LET shares == ReadBytes(midpointBookTrade.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(matchNumber.rest, 2) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 2) IN IF ~sellBrokerId.ok THEN Fail ELSE
    Ok([ side              |-> side.value,
         instrumentId      |-> instrumentId.value,
         timestamp         |-> timestamp.value,
         midpointBookTrade |-> midpointBookTrade.value,
         shares            |-> shares.value,
         price             |-> price.value,
         matchNumber       |-> matchNumber.value,
         buyBrokerId       |-> buyBrokerId.value,
         sellBrokerId      |-> sellBrokerId.value ], sellBrokerId.rest)

ZeroTradeMessage ==
    [ side              |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 2 |-> 0],
      timestamp         |-> [i \in 1 .. 8 |-> 0],
      midpointBookTrade |-> [i \in 1 .. 4 |-> 0],
      shares            |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 4 |-> 0],
      buyBrokerId       |-> [i \in 1 .. 2 |-> 0],
      sellBrokerId      |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.midpointBookTrade = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.buyBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.sellBrokerId = one] : one \in Sample(2) }

(***************************************************************************)
(* Cross Trade Message: 31 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ crossType      : Sample(1),
      instrumentId   : Sample(2),
      timestamp      : Sample(8),
      shares         : Sample(4),
      price          : Sample(4),
      matchNumber    : Sample(4),
      buyBrokerId    : Sample(2),
      sellBrokerId   : Sample(2),
      bypass         : Sample(1),
      settlementType : Sample(1),
      reserved2      : Sample(2) ]

EncodeCrossTradeMessage(message) ==
    message.crossType
        \o message.instrumentId
        \o message.timestamp
        \o message.shares
        \o message.price
        \o message.matchNumber
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.bypass
        \o message.settlementType
        \o message.reserved2

DecodeCrossTradeMessage(bytes) ==
    LET crossType == ReadBytes(bytes, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(crossType.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET shares == ReadBytes(timestamp.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(matchNumber.rest, 2) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 2) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET bypass == ReadBytes(sellBrokerId.rest, 1) IN IF ~bypass.ok THEN Fail ELSE
    LET settlementType == ReadBytes(bypass.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(settlementType.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ crossType      |-> crossType.value,
         instrumentId   |-> instrumentId.value,
         timestamp      |-> timestamp.value,
         shares         |-> shares.value,
         price          |-> price.value,
         matchNumber    |-> matchNumber.value,
         buyBrokerId    |-> buyBrokerId.value,
         sellBrokerId   |-> sellBrokerId.value,
         bypass         |-> bypass.value,
         settlementType |-> settlementType.value,
         reserved2      |-> reserved2.value ], reserved2.rest)

ZeroCrossTradeMessage ==
    [ crossType      |-> [i \in 1 .. 1 |-> 0],
      instrumentId   |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      shares         |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      buyBrokerId    |-> [i \in 1 .. 2 |-> 0],
      sellBrokerId   |-> [i \in 1 .. 2 |-> 0],
      bypass         |-> [i \in 1 .. 1 |-> 0],
      settlementType |-> [i \in 1 .. 1 |-> 0],
      reserved2      |-> [i \in 1 .. 2 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.buyBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.sellBrokerId = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.bypass = one] : one \in Sample(1) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Bust Message: 15 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ reserved1    : Sample(1),
      instrumentId : Sample(2),
      timestamp    : Sample(8),
      matchNumber  : Sample(4) ]

EncodeTradeBustMessage(message) ==
    message.reserved1
        \o message.instrumentId
        \o message.timestamp
        \o message.matchNumber

DecodeTradeBustMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timestamp.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ reserved1    |-> reserved1.value,
         instrumentId |-> instrumentId.value,
         timestamp    |-> timestamp.value,
         matchNumber  |-> matchNumber.value ], matchNumber.rest)

ZeroTradeBustMessage ==
    [ reserved1    |-> [i \in 1 .. 1 |-> 0],
      instrumentId |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      matchNumber  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Amend Message: 39 bytes                                           *)
(***************************************************************************)

TradeAmendMessage ==
    [ reserved1           : Sample(1),
      instrumentId        : Sample(2),
      timestamp           : Sample(8),
      originalTradeId     : Sample(4),
      originalTradePrice  : Sample(8),
      originalTradeSize   : Sample(4),
      correctedTradePrice : Sample(8),
      correctedTradeSize  : Sample(4) ]

EncodeTradeAmendMessage(message) ==
    message.reserved1
        \o message.instrumentId
        \o message.timestamp
        \o message.originalTradeId
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.correctedTradePrice
        \o message.correctedTradeSize

DecodeTradeAmendMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(reserved1.rest, 2) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(timestamp.rest, 4) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeId.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 4) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(originalTradeSize.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 4) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    Ok([ reserved1           |-> reserved1.value,
         instrumentId        |-> instrumentId.value,
         timestamp           |-> timestamp.value,
         originalTradeId     |-> originalTradeId.value,
         originalTradePrice  |-> originalTradePrice.value,
         originalTradeSize   |-> originalTradeSize.value,
         correctedTradePrice |-> correctedTradePrice.value,
         correctedTradeSize  |-> correctedTradeSize.value ], correctedTradeSize.rest)

ZeroTradeAmendMessage ==
    [ reserved1           |-> [i \in 1 .. 1 |-> 0],
      instrumentId        |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      originalTradeId     |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice  |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize   |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice |-> [i \in 1 .. 8 |-> 0],
      correctedTradeSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Amend Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeAmendMessage ==
    { ZeroTradeAmendMessage }
        \cup { [ZeroTradeAmendMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.instrumentId = one] : one \in Sample(2) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.originalTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.originalTradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
ExtendedStockDirectoryMessageCode == 114  \* "r"
StockTradingActionMessageCode == 72  \* "H"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
OrderCancelMessageCode == 88  \* "X"
TradeMessageCode == 80  \* "P"
CrossTradeMessageCode == 81  \* "Q"
TradeBustMessageCode == 66  \* "B"
TradeAmendMessageCode == 77  \* "M"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {ExtendedStockDirectoryMessageCode}, body : ExtendedStockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {TradeAmendMessageCode}, body : TradeAmendMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = ExtendedStockDirectoryMessageCode -> EncodeExtendedStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = TradeAmendMessageCode -> EncodeTradeAmendMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = ExtendedStockDirectoryMessageCode -> DecodeExtendedStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = TradeAmendMessageCode -> DecodeTradeAmendMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> ExtendedStockDirectoryMessageCode, body |-> one] : one \in CheckedExtendedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> CrossTradeMessageCode, body |-> one] : one \in CheckedCrossTradeMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> TradeAmendMessageCode, body |-> one] : one \in CheckedTradeAmendMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExtendedStockDirectoryMessageCode, body |-> ZeroExtendedStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossTradeMessageCode, body |-> ZeroCrossTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeAmendMessageCode, body |-> ZeroTradeAmendMessage]] }

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

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossTradeMessage ==
    \A message \in CheckedCrossTradeMessage :
        LET read == DecodeCrossTradeMessage(EncodeCrossTradeMessage(message))
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

(* Every Trade Amend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeAmendMessage ==
    \A message \in CheckedTradeAmendMessage :
        LET read == DecodeTradeAmendMessage(EncodeTradeAmendMessage(message))
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
