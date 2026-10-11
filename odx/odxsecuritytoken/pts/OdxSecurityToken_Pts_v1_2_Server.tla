----------------- MODULE OdxSecurityToken_Pts_v1_2_Server ------------------
(***************************************************************************)
(* Osaka Digital Exchange Proprietary Trading System v1.2                  *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

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
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ seconds : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.seconds

DecodeSecondsMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSecondsMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      group       : Sample(4),
      systemEvent : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.group
        \o message.systemEvent

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET group == ReadBytes(nanoseconds.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET systemEvent == ReadBytes(group.rest, 1) IN IF ~systemEvent.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         group       |-> group.value,
         systemEvent |-> systemEvent.value ], systemEvent.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      group       |-> [i \in 1 .. 4 |-> 0],
      systemEvent |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.systemEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Price Tick Size Message: 16 bytes                                       *)
(***************************************************************************)

PriceTickSizeMessage ==
    [ nanoseconds          : Sample(4),
      priceTickSizeTableId : Sample(4),
      priceTickSize        : Sample(4),
      priceStart           : Sample(4) ]

EncodePriceTickSizeMessage(message) ==
    message.nanoseconds
        \o message.priceTickSizeTableId
        \o message.priceTickSize
        \o message.priceStart

DecodePriceTickSizeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET priceTickSizeTableId == ReadBytes(nanoseconds.rest, 4) IN IF ~priceTickSizeTableId.ok THEN Fail ELSE
    LET priceTickSize == ReadBytes(priceTickSizeTableId.rest, 4) IN IF ~priceTickSize.ok THEN Fail ELSE
    LET priceStart == ReadBytes(priceTickSize.rest, 4) IN IF ~priceStart.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         priceTickSizeTableId |-> priceTickSizeTableId.value,
         priceTickSize        |-> priceTickSize.value,
         priceStart           |-> priceStart.value ], priceStart.rest)

ZeroPriceTickSizeMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      priceTickSizeTableId |-> [i \in 1 .. 4 |-> 0],
      priceTickSize        |-> [i \in 1 .. 4 |-> 0],
      priceStart           |-> [i \in 1 .. 4 |-> 0] ]

(* Price Tick Size Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceTickSizeMessage ==
    { ZeroPriceTickSizeMessage }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceTickSize = one] : one \in Sample(4) }
        \cup { [ZeroPriceTickSizeMessage EXCEPT !.priceStart = one] : one \in Sample(4) }

(***************************************************************************)
(* Orderbook Directory Message: 59 bytes                                   *)
(***************************************************************************)

OrderbookDirectoryMessage ==
    [ nanoseconds              : Sample(4),
      orderbookId              : Sample(4),
      orderbookCode            : Sample(12),
      exchangeSymbol           : Sample(12),
      group                    : Sample(4),
      roundLotSize             : Sample(4),
      priceTickSizeTableId     : Sample(4),
      priceDecimals            : Sample(4),
      upperPriceLimit          : Sample(4),
      lowerPriceLimit          : Sample(4),
      restrictionOfMarketOrder : Sample(1),
      attentionFlag            : Sample(1),
      terminationFlag          : Sample(1) ]

EncodeOrderbookDirectoryMessage(message) ==
    message.nanoseconds
        \o message.orderbookId
        \o message.orderbookCode
        \o message.exchangeSymbol
        \o message.group
        \o message.roundLotSize
        \o message.priceTickSizeTableId
        \o message.priceDecimals
        \o message.upperPriceLimit
        \o message.lowerPriceLimit
        \o message.restrictionOfMarketOrder
        \o message.attentionFlag
        \o message.terminationFlag

DecodeOrderbookDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET orderbookCode == ReadBytes(orderbookId.rest, 12) IN IF ~orderbookCode.ok THEN Fail ELSE
    LET exchangeSymbol == ReadBytes(orderbookCode.rest, 12) IN IF ~exchangeSymbol.ok THEN Fail ELSE
    LET group == ReadBytes(exchangeSymbol.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(group.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET priceTickSizeTableId == ReadBytes(roundLotSize.rest, 4) IN IF ~priceTickSizeTableId.ok THEN Fail ELSE
    LET priceDecimals == ReadBytes(priceTickSizeTableId.rest, 4) IN IF ~priceDecimals.ok THEN Fail ELSE
    LET upperPriceLimit == ReadBytes(priceDecimals.rest, 4) IN IF ~upperPriceLimit.ok THEN Fail ELSE
    LET lowerPriceLimit == ReadBytes(upperPriceLimit.rest, 4) IN IF ~lowerPriceLimit.ok THEN Fail ELSE
    LET restrictionOfMarketOrder == ReadBytes(lowerPriceLimit.rest, 1) IN IF ~restrictionOfMarketOrder.ok THEN Fail ELSE
    LET attentionFlag == ReadBytes(restrictionOfMarketOrder.rest, 1) IN IF ~attentionFlag.ok THEN Fail ELSE
    LET terminationFlag == ReadBytes(attentionFlag.rest, 1) IN IF ~terminationFlag.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         orderbookId              |-> orderbookId.value,
         orderbookCode            |-> orderbookCode.value,
         exchangeSymbol           |-> exchangeSymbol.value,
         group                    |-> group.value,
         roundLotSize             |-> roundLotSize.value,
         priceTickSizeTableId     |-> priceTickSizeTableId.value,
         priceDecimals            |-> priceDecimals.value,
         upperPriceLimit          |-> upperPriceLimit.value,
         lowerPriceLimit          |-> lowerPriceLimit.value,
         restrictionOfMarketOrder |-> restrictionOfMarketOrder.value,
         attentionFlag            |-> attentionFlag.value,
         terminationFlag          |-> terminationFlag.value ], terminationFlag.rest)

ZeroOrderbookDirectoryMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      orderbookId              |-> [i \in 1 .. 4 |-> 0],
      orderbookCode            |-> [i \in 1 .. 12 |-> 0],
      exchangeSymbol           |-> [i \in 1 .. 12 |-> 0],
      group                    |-> [i \in 1 .. 4 |-> 0],
      roundLotSize             |-> [i \in 1 .. 4 |-> 0],
      priceTickSizeTableId     |-> [i \in 1 .. 4 |-> 0],
      priceDecimals            |-> [i \in 1 .. 4 |-> 0],
      upperPriceLimit          |-> [i \in 1 .. 4 |-> 0],
      lowerPriceLimit          |-> [i \in 1 .. 4 |-> 0],
      restrictionOfMarketOrder |-> [i \in 1 .. 1 |-> 0],
      attentionFlag            |-> [i \in 1 .. 1 |-> 0],
      terminationFlag          |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookDirectoryMessage ==
    { ZeroOrderbookDirectoryMessage }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.orderbookCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.exchangeSymbol = one] : one \in Sample(12) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceTickSizeTableId = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.priceDecimals = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.upperPriceLimit = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.lowerPriceLimit = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.restrictionOfMarketOrder = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.attentionFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookDirectoryMessage EXCEPT !.terminationFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading State Message: 13 bytes                                         *)
(***************************************************************************)

TradingStateMessage ==
    [ nanoseconds  : Sample(4),
      orderbookId  : Sample(4),
      group        : Sample(4),
      tradingState : Sample(1) ]

EncodeTradingStateMessage(message) ==
    message.nanoseconds
        \o message.orderbookId
        \o message.group
        \o message.tradingState

DecodeTradingStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET group == ReadBytes(orderbookId.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET tradingState == ReadBytes(group.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         orderbookId  |-> orderbookId.value,
         group        |-> group.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroTradingStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      orderbookId  |-> [i \in 1 .. 4 |-> 0],
      group        |-> [i \in 1 .. 4 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading State Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStateMessage ==
    { ZeroTradingStateMessage }
        \cup { [ZeroTradingStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradingStateMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroTradingStateMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroTradingStateMessage EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Added Message: 29 bytes                                           *)
(***************************************************************************)

OrderAddedMessage ==
    [ nanoseconds      : Sample(4),
      orderNumber      : Sample(8),
      buySellIndicator : Sample(1),
      quantity         : Sample(4),
      orderbookId      : Sample(4),
      group            : Sample(4),
      price            : Sample(4) ]

EncodeOrderAddedMessage(message) ==
    message.nanoseconds
        \o message.orderNumber
        \o message.buySellIndicator
        \o message.quantity
        \o message.orderbookId
        \o message.group
        \o message.price

DecodeOrderAddedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(quantity.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET group == ReadBytes(orderbookId.rest, 4) IN IF ~group.ok THEN Fail ELSE
    LET price == ReadBytes(group.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderNumber      |-> orderNumber.value,
         buySellIndicator |-> buySellIndicator.value,
         quantity         |-> quantity.value,
         orderbookId      |-> orderbookId.value,
         group            |-> group.value,
         price            |-> price.value ], price.rest)

ZeroOrderAddedMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderNumber      |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity         |-> [i \in 1 .. 4 |-> 0],
      orderbookId      |-> [i \in 1 .. 4 |-> 0],
      group            |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 4 |-> 0] ]

(* Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedMessage ==
    { ZeroOrderAddedMessage }
        \cup { [ZeroOrderAddedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.group = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 29 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ nanoseconds      : Sample(4),
      orderNumber      : Sample(8),
      executedQuantity : Sample(4),
      matchNumber      : Sample(8),
      tradePrice       : Sample(4),
      occurredAsCross  : Sample(1) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.orderNumber
        \o message.executedQuantity
        \o message.matchNumber
        \o message.tradePrice
        \o message.occurredAsCross

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderNumber.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedQuantity.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(matchNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET occurredAsCross == ReadBytes(tradePrice.rest, 1) IN IF ~occurredAsCross.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderNumber      |-> orderNumber.value,
         executedQuantity |-> executedQuantity.value,
         matchNumber      |-> matchNumber.value,
         tradePrice       |-> tradePrice.value,
         occurredAsCross  |-> occurredAsCross.value ], occurredAsCross.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderNumber      |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      matchNumber      |-> [i \in 1 .. 8 |-> 0],
      tradePrice       |-> [i \in 1 .. 4 |-> 0],
      occurredAsCross  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.occurredAsCross = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Deleted Message: 12 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ nanoseconds : Sample(4),
      orderNumber : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.nanoseconds
        \o message.orderNumber

DecodeOrderDeletedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderNumber |-> orderNumber.value ], orderNumber.rest)

ZeroOrderDeletedMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replaced Message: 28 bytes                                        *)
(***************************************************************************)

OrderReplacedMessage ==
    [ nanoseconds         : Sample(4),
      originalOrderNumber : Sample(8),
      newOrderNumber      : Sample(8),
      quantity            : Sample(4),
      price               : Sample(4) ]

EncodeOrderReplacedMessage(message) ==
    message.nanoseconds
        \o message.originalOrderNumber
        \o message.newOrderNumber
        \o message.quantity
        \o message.price

DecodeOrderReplacedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET originalOrderNumber == ReadBytes(nanoseconds.rest, 8) IN IF ~originalOrderNumber.ok THEN Fail ELSE
    LET newOrderNumber == ReadBytes(originalOrderNumber.rest, 8) IN IF ~newOrderNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         originalOrderNumber |-> originalOrderNumber.value,
         newOrderNumber      |-> newOrderNumber.value,
         quantity            |-> quantity.value,
         price               |-> price.value ], price.rest)

ZeroOrderReplacedMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      originalOrderNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderNumber      |-> [i \in 1 .. 8 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.originalOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.newOrderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Book State Message: 28 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ nanoseconds : Sample(4),
      orderbookId : Sample(4),
      stateName   : Sample(20) ]

EncodeOrderBookStateMessage(message) ==
    message.nanoseconds
        \o message.orderbookId
        \o message.stateName

DecodeOrderBookStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderbookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderbookId |-> orderbookId.value,
         stateName   |-> stateName.value ], stateName.rest)

ZeroOrderBookStateMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderbookId |-> [i \in 1 .. 4 |-> 0],
      stateName   |-> [i \in 1 .. 20 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.stateName = one] : one \in Sample(20) }

(***************************************************************************)
(* Equilibrium Price Update Message: 12 bytes                              *)
(***************************************************************************)

EquilibriumPriceUpdateMessage ==
    [ nanoseconds      : Sample(4),
      orderbookId      : Sample(4),
      equilibriumPrice : Sample(4) ]

EncodeEquilibriumPriceUpdateMessage(message) ==
    message.nanoseconds
        \o message.orderbookId
        \o message.equilibriumPrice

DecodeEquilibriumPriceUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderbookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderbookId.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(orderbookId.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderbookId      |-> orderbookId.value,
         equilibriumPrice |-> equilibriumPrice.value ], equilibriumPrice.rest)

ZeroEquilibriumPriceUpdateMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderbookId      |-> [i \in 1 .. 4 |-> 0],
      equilibriumPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Equilibrium Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceUpdateMessage ==
    { ZeroEquilibriumPriceUpdateMessage }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.orderbookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
SystemEventMessageCode == 83  \* "S"
PriceTickSizeMessageCode == 76  \* "L"
OrderbookDirectoryMessageCode == 82  \* "R"
TradingStateMessageCode == 72  \* "H"
OrderAddedMessageCode == 65  \* "A"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderDeletedMessageCode == 68  \* "D"
OrderReplacedMessageCode == 85  \* "U"
OrderBookStateMessageCode == 79  \* "O"
EquilibriumPriceUpdateMessageCode == 90  \* "Z"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {PriceTickSizeMessageCode}, body : PriceTickSizeMessage ]
        \cup [ tag : {OrderbookDirectoryMessageCode}, body : OrderbookDirectoryMessage ]
        \cup [ tag : {TradingStateMessageCode}, body : TradingStateMessage ]
        \cup [ tag : {OrderAddedMessageCode}, body : OrderAddedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {EquilibriumPriceUpdateMessageCode}, body : EquilibriumPriceUpdateMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = PriceTickSizeMessageCode -> EncodePriceTickSizeMessage(message.body)
      [] message.tag = OrderbookDirectoryMessageCode -> EncodeOrderbookDirectoryMessage(message.body)
      [] message.tag = TradingStateMessageCode -> EncodeTradingStateMessage(message.body)
      [] message.tag = OrderAddedMessageCode -> EncodeOrderAddedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = EquilibriumPriceUpdateMessageCode -> EncodeEquilibriumPriceUpdateMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = PriceTickSizeMessageCode -> DecodePriceTickSizeMessage(bytes)
              [] tag = OrderbookDirectoryMessageCode -> DecodeOrderbookDirectoryMessage(bytes)
              [] tag = TradingStateMessageCode -> DecodeTradingStateMessage(bytes)
              [] tag = OrderAddedMessageCode -> DecodeOrderAddedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = EquilibriumPriceUpdateMessageCode -> DecodeEquilibriumPriceUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> PriceTickSizeMessageCode, body |-> one] : one \in CheckedPriceTickSizeMessage }
        \cup { [tag |-> OrderbookDirectoryMessageCode, body |-> one] : one \in CheckedOrderbookDirectoryMessage }
        \cup { [tag |-> TradingStateMessageCode, body |-> one] : one \in CheckedTradingStateMessage }
        \cup { [tag |-> OrderAddedMessageCode, body |-> one] : one \in CheckedOrderAddedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> EquilibriumPriceUpdateMessageCode, body |-> one] : one \in CheckedEquilibriumPriceUpdateMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
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

(* Every Price Tick Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceTickSizeMessage ==
    \A message \in CheckedPriceTickSizeMessage :
        LET read == DecodePriceTickSizeMessage(EncodePriceTickSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookDirectoryMessage ==
    \A message \in CheckedOrderbookDirectoryMessage :
        LET read == DecodeOrderbookDirectoryMessage(EncodeOrderbookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStateMessage ==
    \A message \in CheckedTradingStateMessage :
        LET read == DecodeTradingStateMessage(EncodeTradingStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Added Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedMessage ==
    \A message \in CheckedOrderAddedMessage :
        LET read == DecodeOrderAddedMessage(EncodeOrderAddedMessage(message))
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

(* Every Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeletedMessage ==
    \A message \in CheckedOrderDeletedMessage :
        LET read == DecodeOrderDeletedMessage(EncodeOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookStateMessage ==
    \A message \in CheckedOrderBookStateMessage :
        LET read == DecodeOrderBookStateMessage(EncodeOrderBookStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equilibrium Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceUpdateMessage ==
    \A message \in CheckedEquilibriumPriceUpdateMessage :
        LET read == DecodeEquilibriumPriceUpdateMessage(EncodeEquilibriumPriceUpdateMessage(message))
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

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
