------------------ MODULE BruceEquities_DepthOfBook_v3_3 -------------------
(***************************************************************************)
(* Bruce ATS Depth Of Book v3.3                                            *)
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
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
    [ stockLocate : Sample(2),
      timestamp   : Sample(8),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ stockLocate |-> stockLocate.value,
         timestamp   |-> timestamp.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ stockLocate |-> [i \in 1 .. 2 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 24 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stockLocate    : Sample(2),
      timestamp      : Sample(8),
      stock          : Sample(8),
      marketCategory : Sample(1),
      roundLotSize   : Sample(4),
      authenticity   : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.marketCategory
        \o message.roundLotSize
        \o message.authenticity

DecodeStockDirectoryMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(marketCategory.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET authenticity == ReadBytes(roundLotSize.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         marketCategory |-> marketCategory.value,
         roundLotSize   |-> roundLotSize.value,
         authenticity   |-> authenticity.value ], authenticity.rest)

ZeroStockDirectoryMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      marketCategory |-> [i \in 1 .. 1 |-> 0],
      roundLotSize   |-> [i \in 1 .. 4 |-> 0],
      authenticity   |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 19 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stockLocate  : Sample(2),
      timestamp    : Sample(8),
      stock        : Sample(8),
      tradingState : Sample(1) ]

EncodeStockTradingActionMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.tradingState

DecodeStockTradingActionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ stockLocate  |-> stockLocate.value,
         timestamp    |-> timestamp.value,
         stock        |-> stock.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroStockTradingActionMessage ==
    [ stockLocate  |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      stock        |-> [i \in 1 .. 8 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 19 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ stockLocate  : Sample(2),
      timestamp    : Sample(8),
      stock        : Sample(8),
      regShoAction : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.stock
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ stockLocate  |-> stockLocate.value,
         timestamp    |-> timestamp.value,
         stock        |-> stock.value,
         regShoAction |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ stockLocate  |-> [i \in 1 .. 2 |-> 0],
      timestamp    |-> [i \in 1 .. 8 |-> 0],
      stock        |-> [i \in 1 .. 8 |-> 0],
      regShoAction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message: 39 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ stockLocate          : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      shares               : Sample(4),
      stock                : Sample(8),
      price                : Sample(8) ]

EncodeAddOrderMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 30 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ stockLocate          : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(8),
      executedShares       : Sample(4),
      matchNumber          : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Message: 22 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ stockLocate          : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(8),
      cancelledShares      : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.cancelledShares

DecodeOrderCancelMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET cancelledShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~cancelledShares.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         cancelledShares      |-> cancelledShares.value ], cancelledShares.rest)

ZeroOrderCancelMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelledShares      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledShares = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Delete Message: 18 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ stockLocate          : Sample(2),
      timestamp            : Sample(8),
      orderReferenceNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replace Message: 38 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ stockLocate                  : Sample(2),
      timestamp                    : Sample(8),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      shares                       : Sample(4),
      price                        : Sample(8) ]

EncodeOrderReplaceMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.shares
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ stockLocate                  |-> stockLocate.value,
         timestamp                    |-> timestamp.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         shares                       |-> shares.value,
         price                        |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ stockLocate                  |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 8 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      shares                       |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Correction Message: 38 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ stockLocate    : Sample(2),
      timestamp      : Sample(8),
      matchNumber    : Sample(8),
      newMatchNumber : Sample(8),
      shares         : Sample(4),
      price          : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.matchNumber
        \o message.newMatchNumber
        \o message.shares
        \o message.price

DecodeTradeCorrectionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timestamp.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET newMatchNumber == ReadBytes(matchNumber.rest, 8) IN IF ~newMatchNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(newMatchNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         timestamp      |-> timestamp.value,
         matchNumber    |-> matchNumber.value,
         newMatchNumber |-> newMatchNumber.value,
         shares         |-> shares.value,
         price          |-> price.value ], price.rest)

ZeroTradeCorrectionMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      matchNumber    |-> [i \in 1 .. 8 |-> 0],
      newMatchNumber |-> [i \in 1 .. 8 |-> 0],
      shares         |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.newMatchNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 18 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ stockLocate : Sample(2),
      timestamp   : Sample(8),
      matchNumber : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.stockLocate
        \o message.timestamp
        \o message.matchNumber

DecodeTradeBreakMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET timestamp == ReadBytes(stockLocate.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timestamp.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ stockLocate |-> stockLocate.value,
         timestamp   |-> timestamp.value,
         matchNumber |-> matchNumber.value ], matchNumber.rest)

ZeroTradeBreakMessage ==
    [ stockLocate |-> [i \in 1 .. 2 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0],
      matchNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
AddOrderMessageCode == 65  \* "A"
OrderExecutedMessageCode == 69  \* "E"
OrderCancelMessageCode == 88  \* "X"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
TradeCorrectionMessageCode == 67  \* "C"
TradeBreakMessageCode == 66  \* "B"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]] }

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

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
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

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
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

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
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
