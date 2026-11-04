---------------- MODULE AquisStockExchange_RealTime_v1_2_3 -----------------
(***************************************************************************)
(* Aquis Exchange Real Time Market Data Feed v1.2.3                        *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Binary Mmt is a bit field set, checked as its 4 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Market Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
(* Order Add Message: 27 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ securityId : Sample(2),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      timestamp  : Sample(8) ]

EncodeOrderAddMessage(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp

DecodeOrderAddMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroOrderAddMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Message: 14 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ securityId : Sample(2),
      orderRef   : Sample(4),
      timestamp  : Sample(8) ]

EncodeOrderCancelMessage(message) ==
    message.securityId
        \o message.orderRef
        \o message.timestamp

DecodeOrderCancelMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderRef == ReadBytes(securityId.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroOrderCancelMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Message: 26 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ securityId        : Sample(2),
      remainingQuantity : Sample(4),
      price             : Sample(8),
      orderRef          : Sample(4),
      timestamp         : Sample(8) ]

EncodeOrderModifyMessage(message) ==
    message.securityId
        \o message.remainingQuantity
        \o message.price
        \o message.orderRef
        \o message.timestamp

DecodeOrderModifyMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(securityId.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET price == ReadBytes(remainingQuantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId        |-> securityId.value,
         remainingQuantity |-> remainingQuantity.value,
         price             |-> price.value,
         orderRef          |-> orderRef.value,
         timestamp         |-> timestamp.value ], timestamp.rest)

ZeroOrderModifyMessage ==
    [ securityId        |-> [i \in 1 .. 2 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      orderRef          |-> [i \in 1 .. 4 |-> 0],
      timestamp         |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Add Replace Message: 36 bytes                                     *)
(***************************************************************************)

QuoteAddReplaceMessage ==
    [ traderId      : Sample(2),
      securityId    : Sample(2),
      bidQuantity   : Sample(4),
      bidPrice      : Sample(8),
      offerQuantity : Sample(4),
      offerPrice    : Sample(8),
      timestamp     : Sample(8) ]

EncodeQuoteAddReplaceMessage(message) ==
    message.traderId
        \o message.securityId
        \o message.bidQuantity
        \o message.bidPrice
        \o message.offerQuantity
        \o message.offerPrice
        \o message.timestamp

DecodeQuoteAddReplaceMessage(bytes) ==
    LET traderId == ReadBytes(bytes, 2) IN IF ~traderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(traderId.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(securityId.rest, 4) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidQuantity.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerQuantity == ReadBytes(bidPrice.rest, 4) IN IF ~offerQuantity.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(offerQuantity.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET timestamp == ReadBytes(offerPrice.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ traderId      |-> traderId.value,
         securityId    |-> securityId.value,
         bidQuantity   |-> bidQuantity.value,
         bidPrice      |-> bidPrice.value,
         offerQuantity |-> offerQuantity.value,
         offerPrice    |-> offerPrice.value,
         timestamp     |-> timestamp.value ], timestamp.rest)

ZeroQuoteAddReplaceMessage ==
    [ traderId      |-> [i \in 1 .. 2 |-> 0],
      securityId    |-> [i \in 1 .. 2 |-> 0],
      bidQuantity   |-> [i \in 1 .. 4 |-> 0],
      bidPrice      |-> [i \in 1 .. 8 |-> 0],
      offerQuantity |-> [i \in 1 .. 4 |-> 0],
      offerPrice    |-> [i \in 1 .. 8 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Add Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAddReplaceMessage ==
    { ZeroQuoteAddReplaceMessage }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.traderId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.bidQuantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.offerQuantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAddReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Cancel Message: 12 bytes                                          *)
(***************************************************************************)

QuoteCancelMessage ==
    [ traderId   : Sample(2),
      securityId : Sample(2),
      timestamp  : Sample(8) ]

EncodeQuoteCancelMessage(message) ==
    message.traderId
        \o message.securityId
        \o message.timestamp

DecodeQuoteCancelMessage(bytes) ==
    LET traderId == ReadBytes(bytes, 2) IN IF ~traderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(traderId.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(securityId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ traderId   |-> traderId.value,
         securityId |-> securityId.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroQuoteCancelMessage ==
    [ traderId   |-> [i \in 1 .. 2 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelMessage ==
    { ZeroQuoteCancelMessage }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.traderId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 35 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ securityId     : Sample(2),
      tradeType      : Sample(1),
      tradedQuantity : Sample(4),
      executionPrice : Sample(8),
      orderRef       : Sample(4),
      tradeRef       : Sample(4),
      timestamp      : Sample(8),
      binaryMmt      : Sample(4) ]

EncodeTradeMessage(message) ==
    message.securityId
        \o message.tradeType
        \o message.tradedQuantity
        \o message.executionPrice
        \o message.orderRef
        \o message.tradeRef
        \o message.timestamp
        \o message.binaryMmt

DecodeTradeMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(tradeType.rest, 4) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradedQuantity.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET orderRef == ReadBytes(executionPrice.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(orderRef.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    Ok([ securityId     |-> securityId.value,
         tradeType      |-> tradeType.value,
         tradedQuantity |-> tradedQuantity.value,
         executionPrice |-> executionPrice.value,
         orderRef       |-> orderRef.value,
         tradeRef       |-> tradeRef.value,
         timestamp      |-> timestamp.value,
         binaryMmt      |-> binaryMmt.value ], binaryMmt.rest)

ZeroTradeMessage ==
    [ securityId     |-> [i \in 1 .. 2 |-> 0],
      tradeType      |-> [i \in 1 .. 1 |-> 0],
      tradedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionPrice |-> [i \in 1 .. 8 |-> 0],
      orderRef       |-> [i \in 1 .. 4 |-> 0],
      tradeRef       |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      binaryMmt      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Report Message: 39 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ securityId        : Sample(2),
      tradeType         : Sample(1),
      tradedQuantity    : Sample(4),
      executionPrice    : Sample(8),
      tradeRef          : Sample(4),
      receivedTimestamp : Sample(8),
      binaryMmt         : Sample(4),
      transactTime      : Sample(8) ]

EncodeTradeReportMessage(message) ==
    message.securityId
        \o message.tradeType
        \o message.tradedQuantity
        \o message.executionPrice
        \o message.tradeRef
        \o message.receivedTimestamp
        \o message.binaryMmt
        \o message.transactTime

DecodeTradeReportMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(tradeType.rest, 4) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradedQuantity.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(executionPrice.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET receivedTimestamp == ReadBytes(tradeRef.rest, 8) IN IF ~receivedTimestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(receivedTimestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    LET transactTime == ReadBytes(binaryMmt.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityId        |-> securityId.value,
         tradeType         |-> tradeType.value,
         tradedQuantity    |-> tradedQuantity.value,
         executionPrice    |-> executionPrice.value,
         tradeRef          |-> tradeRef.value,
         receivedTimestamp |-> receivedTimestamp.value,
         binaryMmt         |-> binaryMmt.value,
         transactTime      |-> transactTime.value ], transactTime.rest)

ZeroTradeReportMessage ==
    [ securityId        |-> [i \in 1 .. 2 |-> 0],
      tradeType         |-> [i \in 1 .. 1 |-> 0],
      tradedQuantity    |-> [i \in 1 .. 4 |-> 0],
      executionPrice    |-> [i \in 1 .. 8 |-> 0],
      tradeRef          |-> [i \in 1 .. 4 |-> 0],
      receivedTimestamp |-> [i \in 1 .. 8 |-> 0],
      binaryMmt         |-> [i \in 1 .. 4 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.receivedTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Report Modify Message: 51 bytes                                   *)
(***************************************************************************)

TradeReportModifyMessage ==
    [ securityId        : Sample(2),
      tradeType         : Sample(1),
      tradedQuantity    : Sample(4),
      executionPrice    : Sample(8),
      tradeRef          : Sample(4),
      receivedTimestamp : Sample(8),
      binaryMmt         : Sample(4),
      transactTime      : Sample(8),
      origTradeRef      : Sample(4),
      origTimestamp     : Sample(8) ]

EncodeTradeReportModifyMessage(message) ==
    message.securityId
        \o message.tradeType
        \o message.tradedQuantity
        \o message.executionPrice
        \o message.tradeRef
        \o message.receivedTimestamp
        \o message.binaryMmt
        \o message.transactTime
        \o message.origTradeRef
        \o message.origTimestamp

DecodeTradeReportModifyMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(tradeType.rest, 4) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradedQuantity.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(executionPrice.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET receivedTimestamp == ReadBytes(tradeRef.rest, 8) IN IF ~receivedTimestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(receivedTimestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    LET transactTime == ReadBytes(binaryMmt.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET origTradeRef == ReadBytes(transactTime.rest, 4) IN IF ~origTradeRef.ok THEN Fail ELSE
    LET origTimestamp == ReadBytes(origTradeRef.rest, 8) IN IF ~origTimestamp.ok THEN Fail ELSE
    Ok([ securityId        |-> securityId.value,
         tradeType         |-> tradeType.value,
         tradedQuantity    |-> tradedQuantity.value,
         executionPrice    |-> executionPrice.value,
         tradeRef          |-> tradeRef.value,
         receivedTimestamp |-> receivedTimestamp.value,
         binaryMmt         |-> binaryMmt.value,
         transactTime      |-> transactTime.value,
         origTradeRef      |-> origTradeRef.value,
         origTimestamp     |-> origTimestamp.value ], origTimestamp.rest)

ZeroTradeReportModifyMessage ==
    [ securityId        |-> [i \in 1 .. 2 |-> 0],
      tradeType         |-> [i \in 1 .. 1 |-> 0],
      tradedQuantity    |-> [i \in 1 .. 4 |-> 0],
      executionPrice    |-> [i \in 1 .. 8 |-> 0],
      tradeRef          |-> [i \in 1 .. 4 |-> 0],
      receivedTimestamp |-> [i \in 1 .. 8 |-> 0],
      binaryMmt         |-> [i \in 1 .. 4 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      origTradeRef      |-> [i \in 1 .. 4 |-> 0],
      origTimestamp     |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportModifyMessage ==
    { ZeroTradeReportModifyMessage }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.tradedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.receivedTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.origTradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportModifyMessage EXCEPT !.origTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Report Cancel Message: 59 bytes                                   *)
(***************************************************************************)

TradeReportCancelMessage ==
    [ origSecurityId    : Sample(2),
      origTradeType     : Sample(1),
      origQuantity      : Sample(4),
      origPrice         : Sample(8),
      tradeRef          : Sample(4),
      receivedTimestamp : Sample(8),
      binaryMmt         : Sample(4),
      transactTime      : Sample(8),
      origTradeRef      : Sample(4),
      origTimestamp     : Sample(8),
      origTransactTime  : Sample(8) ]

EncodeTradeReportCancelMessage(message) ==
    message.origSecurityId
        \o message.origTradeType
        \o message.origQuantity
        \o message.origPrice
        \o message.tradeRef
        \o message.receivedTimestamp
        \o message.binaryMmt
        \o message.transactTime
        \o message.origTradeRef
        \o message.origTimestamp
        \o message.origTransactTime

DecodeTradeReportCancelMessage(bytes) ==
    LET origSecurityId == ReadBytes(bytes, 2) IN IF ~origSecurityId.ok THEN Fail ELSE
    LET origTradeType == ReadBytes(origSecurityId.rest, 1) IN IF ~origTradeType.ok THEN Fail ELSE
    LET origQuantity == ReadBytes(origTradeType.rest, 4) IN IF ~origQuantity.ok THEN Fail ELSE
    LET origPrice == ReadBytes(origQuantity.rest, 8) IN IF ~origPrice.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(origPrice.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET receivedTimestamp == ReadBytes(tradeRef.rest, 8) IN IF ~receivedTimestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(receivedTimestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    LET transactTime == ReadBytes(binaryMmt.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET origTradeRef == ReadBytes(transactTime.rest, 4) IN IF ~origTradeRef.ok THEN Fail ELSE
    LET origTimestamp == ReadBytes(origTradeRef.rest, 8) IN IF ~origTimestamp.ok THEN Fail ELSE
    LET origTransactTime == ReadBytes(origTimestamp.rest, 8) IN IF ~origTransactTime.ok THEN Fail ELSE
    Ok([ origSecurityId    |-> origSecurityId.value,
         origTradeType     |-> origTradeType.value,
         origQuantity      |-> origQuantity.value,
         origPrice         |-> origPrice.value,
         tradeRef          |-> tradeRef.value,
         receivedTimestamp |-> receivedTimestamp.value,
         binaryMmt         |-> binaryMmt.value,
         transactTime      |-> transactTime.value,
         origTradeRef      |-> origTradeRef.value,
         origTimestamp     |-> origTimestamp.value,
         origTransactTime  |-> origTransactTime.value ], origTransactTime.rest)

ZeroTradeReportCancelMessage ==
    [ origSecurityId    |-> [i \in 1 .. 2 |-> 0],
      origTradeType     |-> [i \in 1 .. 1 |-> 0],
      origQuantity      |-> [i \in 1 .. 4 |-> 0],
      origPrice         |-> [i \in 1 .. 8 |-> 0],
      tradeRef          |-> [i \in 1 .. 4 |-> 0],
      receivedTimestamp |-> [i \in 1 .. 8 |-> 0],
      binaryMmt         |-> [i \in 1 .. 4 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      origTradeRef      |-> [i \in 1 .. 4 |-> 0],
      origTimestamp     |-> [i \in 1 .. 8 |-> 0],
      origTransactTime  |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportCancelMessage ==
    { ZeroTradeReportCancelMessage }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origSecurityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.receivedTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origTradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportCancelMessage EXCEPT !.origTransactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Bust Message: 30 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ securityId     : Sample(2),
      tradedQuantity : Sample(4),
      executionPrice : Sample(8),
      tradeRef       : Sample(4),
      timestamp      : Sample(8),
      binaryMmt      : Sample(4) ]

EncodeTradeBustMessage(message) ==
    message.securityId
        \o message.tradedQuantity
        \o message.executionPrice
        \o message.tradeRef
        \o message.timestamp
        \o message.binaryMmt

DecodeTradeBustMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(securityId.rest, 4) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(tradedQuantity.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(executionPrice.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    Ok([ securityId     |-> securityId.value,
         tradedQuantity |-> tradedQuantity.value,
         executionPrice |-> executionPrice.value,
         tradeRef       |-> tradeRef.value,
         timestamp      |-> timestamp.value,
         binaryMmt      |-> binaryMmt.value ], binaryMmt.rest)

ZeroTradeBustMessage ==
    [ securityId     |-> [i \in 1 .. 2 |-> 0],
      tradedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionPrice |-> [i \in 1 .. 8 |-> 0],
      tradeRef       |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      binaryMmt      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Statistics Message: 19 bytes                                   *)
(***************************************************************************)

SecurityStatisticsMessage ==
    [ securityId      : Sample(2),
      statisticsPrice : Sample(8),
      priceType       : Sample(1),
      timestamp       : Sample(8) ]

EncodeSecurityStatisticsMessage(message) ==
    message.securityId
        \o message.statisticsPrice
        \o message.priceType
        \o message.timestamp

DecodeSecurityStatisticsMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET statisticsPrice == ReadBytes(securityId.rest, 8) IN IF ~statisticsPrice.ok THEN Fail ELSE
    LET priceType == ReadBytes(statisticsPrice.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(priceType.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         statisticsPrice |-> statisticsPrice.value,
         priceType       |-> priceType.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroSecurityStatisticsMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      statisticsPrice |-> [i \in 1 .. 8 |-> 0],
      priceType       |-> [i \in 1 .. 1 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Security Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatisticsMessage ==
    { ZeroSecurityStatisticsMessage }
        \cup { [ZeroSecurityStatisticsMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatisticsMessage EXCEPT !.statisticsPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatisticsMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatisticsMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trader Definition Message: 18 bytes                                     *)
(***************************************************************************)

TraderDefinitionMessage ==
    [ traderId : Sample(2),
      senderId : Sample(16) ]

EncodeTraderDefinitionMessage(message) ==
    message.traderId
        \o message.senderId

DecodeTraderDefinitionMessage(bytes) ==
    LET traderId == ReadBytes(bytes, 2) IN IF ~traderId.ok THEN Fail ELSE
    LET senderId == ReadBytes(traderId.rest, 16) IN IF ~senderId.ok THEN Fail ELSE
    Ok([ traderId |-> traderId.value,
         senderId |-> senderId.value ], senderId.rest)

ZeroTraderDefinitionMessage ==
    [ traderId |-> [i \in 1 .. 2 |-> 0],
      senderId |-> [i \in 1 .. 16 |-> 0] ]

(* Trader Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedTraderDefinitionMessage ==
    { ZeroTraderDefinitionMessage }
        \cup { [ZeroTraderDefinitionMessage EXCEPT !.traderId = one] : one \in Sample(2) }
        \cup { [ZeroTraderDefinitionMessage EXCEPT !.senderId = one] : one \in Sample(16) }

(***************************************************************************)
(* Tick Table Data Message: 27 bytes                                       *)
(***************************************************************************)

TickTableDataMessage ==
    [ tickTableId : Sample(1),
      name        : Sample(10),
      threshold   : Sample(8),
      tickSize    : Sample(8) ]

EncodeTickTableDataMessage(message) ==
    message.tickTableId
        \o message.name
        \o message.threshold
        \o message.tickSize

DecodeTickTableDataMessage(bytes) ==
    LET tickTableId == ReadBytes(bytes, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET name == ReadBytes(tickTableId.rest, 10) IN IF ~name.ok THEN Fail ELSE
    LET threshold == ReadBytes(name.rest, 8) IN IF ~threshold.ok THEN Fail ELSE
    LET tickSize == ReadBytes(threshold.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    Ok([ tickTableId |-> tickTableId.value,
         name        |-> name.value,
         threshold   |-> threshold.value,
         tickSize    |-> tickSize.value ], tickSize.rest)

ZeroTickTableDataMessage ==
    [ tickTableId |-> [i \in 1 .. 1 |-> 0],
      name        |-> [i \in 1 .. 10 |-> 0],
      threshold   |-> [i \in 1 .. 8 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0] ]

(* Tick Table Data Message at zero, then each field in turn at the values it is checked at *)
CheckedTickTableDataMessage ==
    { ZeroTickTableDataMessage }
        \cup { [ZeroTickTableDataMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.name = one] : one \in Sample(10) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.threshold = one] : one \in Sample(8) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.tickSize = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Definition Message: 28 bytes                                   *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityId  : Sample(2),
      umtf        : Sample(6),
      isin        : Sample(12),
      currency    : Sample(3),
      mic         : Sample(4),
      tickTableId : Sample(1) ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    Ok([ securityId  |-> securityId.value,
         umtf        |-> umtf.value,
         isin        |-> isin.value,
         currency    |-> currency.value,
         mic         |-> mic.value,
         tickTableId |-> tickTableId.value ], tickTableId.rest)

ZeroSecurityDefinitionMessage ==
    [ securityId  |-> [i \in 1 .. 2 |-> 0],
      umtf        |-> [i \in 1 .. 6 |-> 0],
      isin        |-> [i \in 1 .. 12 |-> 0],
      currency    |-> [i \in 1 .. 3 |-> 0],
      mic         |-> [i \in 1 .. 4 |-> 0],
      tickTableId |-> [i \in 1 .. 1 |-> 0] ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Status Message: 12 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityId    : Sample(2),
      tradingStatus : Sample(1),
      marketFlags   : Sample(1),
      timestamp     : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.securityId
        \o message.tradingStatus
        \o message.marketFlags
        \o message.timestamp

DecodeSecurityStatusMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(securityId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~marketFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(marketFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId    |-> securityId.value,
         tradingStatus |-> tradingStatus.value,
         marketFlags   |-> marketFlags.value,
         timestamp     |-> timestamp.value ], timestamp.rest)

ZeroSecurityStatusMessage ==
    [ securityId    |-> [i \in 1 .. 2 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketFlags   |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Aod Update Message: 22 bytes                                            *)
(***************************************************************************)

AodUpdateMessage ==
    [ securityId      : Sample(2),
      indicativePrice : Sample(8),
      matchVol        : Sample(4),
      timestamp       : Sample(8) ]

EncodeAodUpdateMessage(message) ==
    message.securityId
        \o message.indicativePrice
        \o message.matchVol
        \o message.timestamp

DecodeAodUpdateMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(securityId.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET matchVol == ReadBytes(indicativePrice.rest, 4) IN IF ~matchVol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(matchVol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         indicativePrice |-> indicativePrice.value,
         matchVol        |-> matchVol.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroAodUpdateMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      matchVol        |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Aod Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAodUpdateMessage ==
    { ZeroAodUpdateMessage }
        \cup { [ZeroAodUpdateMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.matchVol = one] : one \in Sample(4) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
OrderAddMessageCode == 2  \* 0x02
OrderCancelMessageCode == 3  \* 0x03
OrderModifyMessageCode == 4  \* 0x04
QuoteAddReplaceMessageCode == 20  \* 0x14
QuoteCancelMessageCode == 21  \* 0x15
TradeMessageCode == 5  \* 0x05
TradeReportMessageCode == 25  \* 0x19
TradeReportModifyMessageCode == 26  \* 0x1a
TradeReportCancelMessageCode == 27  \* 0x1b
TradeBustMessageCode == 6  \* 0x06
SecurityStatisticsMessageCode == 22  \* 0x16
TraderDefinitionMessageCode == 23  \* 0x17
TickTableDataMessageCode == 7  \* 0x07
SecurityDefinitionMessageCode == 8  \* 0x08
SecurityStatusMessageCode == 9  \* 0x09
AodUpdateMessageCode == 17  \* 0x11

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {QuoteAddReplaceMessageCode}, body : QuoteAddReplaceMessage ]
        \cup [ tag : {QuoteCancelMessageCode}, body : QuoteCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeReportModifyMessageCode}, body : TradeReportModifyMessage ]
        \cup [ tag : {TradeReportCancelMessageCode}, body : TradeReportCancelMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {SecurityStatisticsMessageCode}, body : SecurityStatisticsMessage ]
        \cup [ tag : {TraderDefinitionMessageCode}, body : TraderDefinitionMessage ]
        \cup [ tag : {TickTableDataMessageCode}, body : TickTableDataMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {AodUpdateMessageCode}, body : AodUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = QuoteAddReplaceMessageCode -> EncodeQuoteAddReplaceMessage(message.body)
      [] message.tag = QuoteCancelMessageCode -> EncodeQuoteCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeReportModifyMessageCode -> EncodeTradeReportModifyMessage(message.body)
      [] message.tag = TradeReportCancelMessageCode -> EncodeTradeReportCancelMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = SecurityStatisticsMessageCode -> EncodeSecurityStatisticsMessage(message.body)
      [] message.tag = TraderDefinitionMessageCode -> EncodeTraderDefinitionMessage(message.body)
      [] message.tag = TickTableDataMessageCode -> EncodeTickTableDataMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = AodUpdateMessageCode -> EncodeAodUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = QuoteAddReplaceMessageCode -> DecodeQuoteAddReplaceMessage(bytes)
              [] tag = QuoteCancelMessageCode -> DecodeQuoteCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeReportModifyMessageCode -> DecodeTradeReportModifyMessage(bytes)
              [] tag = TradeReportCancelMessageCode -> DecodeTradeReportCancelMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = SecurityStatisticsMessageCode -> DecodeSecurityStatisticsMessage(bytes)
              [] tag = TraderDefinitionMessageCode -> DecodeTraderDefinitionMessage(bytes)
              [] tag = TickTableDataMessageCode -> DecodeTickTableDataMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = AodUpdateMessageCode -> DecodeAodUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> QuoteAddReplaceMessageCode, body |-> one] : one \in CheckedQuoteAddReplaceMessage }
        \cup { [tag |-> QuoteCancelMessageCode, body |-> one] : one \in CheckedQuoteCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeReportModifyMessageCode, body |-> one] : one \in CheckedTradeReportModifyMessage }
        \cup { [tag |-> TradeReportCancelMessageCode, body |-> one] : one \in CheckedTradeReportCancelMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> SecurityStatisticsMessageCode, body |-> one] : one \in CheckedSecurityStatisticsMessage }
        \cup { [tag |-> TraderDefinitionMessageCode, body |-> one] : one \in CheckedTraderDefinitionMessage }
        \cup { [tag |-> TickTableDataMessageCode, body |-> one] : one \in CheckedTickTableDataMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> AodUpdateMessageCode, body |-> one] : one \in CheckedAodUpdateMessage }

(***************************************************************************)
(* Message, framed by Msg Length                                           *)
(***************************************************************************)

Message ==
    [ seqNo   : Sample(4),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.seqNo
        \o EncodePayload(message.payload)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(message.payload.tag, 1) \o EncodeUIntBE(Len(body) + 2, 1) \o body

DecodeMessage(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntBE(msgType.rest, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET seqNo == ReadBytes(framed, 4) IN IF ~seqNo.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, seqNo.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ seqNo   |-> seqNo.value,
         payload |-> payload.value ], beyond)

ZeroMessage ==
    [ seqNo   |-> [i \in 1 .. 4 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.seqNo = one] : one \in Sample(4) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteAddReplaceMessageCode, body |-> ZeroQuoteAddReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteCancelMessageCode, body |-> ZeroQuoteCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportModifyMessageCode, body |-> ZeroTradeReportModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportCancelMessageCode, body |-> ZeroTradeReportCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatisticsMessageCode, body |-> ZeroSecurityStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TraderDefinitionMessageCode, body |-> ZeroTraderDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickTableDataMessageCode, body |-> ZeroTickTableDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AodUpdateMessageCode, body |-> ZeroAodUpdateMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeUIntBE(Len(message.message), 1)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
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

(* Every Order Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyMessage ==
    \A message \in CheckedOrderModifyMessage :
        LET read == DecodeOrderModifyMessage(EncodeOrderModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Add Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAddReplaceMessage ==
    \A message \in CheckedQuoteAddReplaceMessage :
        LET read == DecodeQuoteAddReplaceMessage(EncodeQuoteAddReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelMessage ==
    \A message \in CheckedQuoteCancelMessage :
        LET read == DecodeQuoteCancelMessage(EncodeQuoteCancelMessage(message))
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

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportModifyMessage ==
    \A message \in CheckedTradeReportModifyMessage :
        LET read == DecodeTradeReportModifyMessage(EncodeTradeReportModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Report Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportCancelMessage ==
    \A message \in CheckedTradeReportCancelMessage :
        LET read == DecodeTradeReportCancelMessage(EncodeTradeReportCancelMessage(message))
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

(* Every Security Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatisticsMessage ==
    \A message \in CheckedSecurityStatisticsMessage :
        LET read == DecodeSecurityStatisticsMessage(EncodeSecurityStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trader Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTraderDefinitionMessage ==
    \A message \in CheckedTraderDefinitionMessage :
        LET read == DecodeTraderDefinitionMessage(EncodeTraderDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Table Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickTableDataMessage ==
    \A message \in CheckedTickTableDataMessage :
        LET read == DecodeTickTableDataMessage(EncodeTickTableDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusMessage ==
    \A message \in CheckedSecurityStatusMessage :
        LET read == DecodeSecurityStatusMessage(EncodeSecurityStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aod Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAodUpdateMessage ==
    \A message \in CheckedAodUpdateMessage :
        LET read == DecodeAodUpdateMessage(EncodeAodUpdateMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 2, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
