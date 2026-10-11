----------------- MODULE PearlEquities_ExpressOrders_v2_7 ------------------
(***************************************************************************)
(* Miami International Holdings Express Orders v2.7                        *)
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
(* Note: New Order Instructions is a bit field set, checked as its 2 bytes *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Self Trade Protection is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Routing is a bit field set, checked as its 1 byte rather than bit *)
(* by bit.                                                                 *)
(*                                                                         *)
(* Note: Modify Order Instructions is a bit field set, checked as its 1    *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Order Execution Instructions is a bit field set, checked as its 2 *)
(* bytes rather than bit by bit.                                           *)
(*                                                                         *)
(* Note: Additional Liquidity Indicator is a bit field set, checked as its *)
(* 1 byte rather than bit by bit.                                          *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Esesm       *)
(* Packet Length states, which is what it is read from.                    *)
(*                                                                         *)
(* Note: Purge Instructions is a bit field set, checked as its 2 bytes     *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Esesm     *)
(* Packet Length states, which is what it is read from.                    *)
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
(* Symbol Update: 59 bytes                                                 *)
(***************************************************************************)

SymbolUpdate ==
    [ matchingEngineTime    : Sample(8),
      symbolId              : Sample(4),
      tickerSymbol          : Sample(11),
      reserved1             : Sample(1),
      testSecurityIndicator : Sample(1),
      future                : Sample(1),
      lotSize               : Sample(4),
      openingTime           : Sample(8),
      closingTime           : Sample(8),
      primaryMarketCode     : Sample(1),
      reserved12            : Sample(12) ]

EncodeSymbolUpdate(message) ==
    message.matchingEngineTime
        \o message.symbolId
        \o message.tickerSymbol
        \o message.reserved1
        \o message.testSecurityIndicator
        \o message.future
        \o message.lotSize
        \o message.openingTime
        \o message.closingTime
        \o message.primaryMarketCode
        \o message.reserved12

DecodeSymbolUpdate(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(matchingEngineTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tickerSymbol == ReadBytes(symbolId.rest, 11) IN IF ~tickerSymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tickerSymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET testSecurityIndicator == ReadBytes(reserved1.rest, 1) IN IF ~testSecurityIndicator.ok THEN Fail ELSE
    LET future == ReadBytes(testSecurityIndicator.rest, 1) IN IF ~future.ok THEN Fail ELSE
    LET lotSize == ReadBytes(future.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET openingTime == ReadBytes(lotSize.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET closingTime == ReadBytes(openingTime.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET primaryMarketCode == ReadBytes(closingTime.rest, 1) IN IF ~primaryMarketCode.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(primaryMarketCode.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         symbolId              |-> symbolId.value,
         tickerSymbol          |-> tickerSymbol.value,
         reserved1             |-> reserved1.value,
         testSecurityIndicator |-> testSecurityIndicator.value,
         future                |-> future.value,
         lotSize               |-> lotSize.value,
         openingTime           |-> openingTime.value,
         closingTime           |-> closingTime.value,
         primaryMarketCode     |-> primaryMarketCode.value,
         reserved12            |-> reserved12.value ], reserved12.rest)

ZeroSymbolUpdate ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      tickerSymbol          |-> [i \in 1 .. 11 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      testSecurityIndicator |-> [i \in 1 .. 1 |-> 0],
      future                |-> [i \in 1 .. 1 |-> 0],
      lotSize               |-> [i \in 1 .. 4 |-> 0],
      openingTime           |-> [i \in 1 .. 8 |-> 0],
      closingTime           |-> [i \in 1 .. 8 |-> 0],
      primaryMarketCode     |-> [i \in 1 .. 1 |-> 0],
      reserved12            |-> [i \in 1 .. 12 |-> 0] ]

(* Symbol Update at zero, then each field in turn at the values it is checked at *)
CheckedSymbolUpdate ==
    { ZeroSymbolUpdate }
        \cup { [ZeroSymbolUpdate EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdate EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdate EXCEPT !.tickerSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolUpdate EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdate EXCEPT !.testSecurityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdate EXCEPT !.future = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdate EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdate EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdate EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdate EXCEPT !.primaryMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdate EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* New Order Response Message: 76 bytes                                    *)
(***************************************************************************)

NewOrderResponseMessage ==
    [ matchingEngineTime : Sample(8),
      mpid               : Sample(4),
      clientOrderId      : Sample(20),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      price              : Sample(8),
      size               : Sample(4),
      orderStatus        : Sample(1),
      reserved19         : Sample(19) ]

EncodeNewOrderResponseMessage(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.price
        \o message.size
        \o message.orderStatus
        \o message.reserved19

DecodeNewOrderResponseMessage(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(size.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET reserved19 == ReadBytes(orderStatus.rest, 19) IN IF ~reserved19.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpid               |-> mpid.value,
         clientOrderId      |-> clientOrderId.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         price              |-> price.value,
         size               |-> size.value,
         orderStatus        |-> orderStatus.value,
         reserved19         |-> reserved19.value ], reserved19.rest)

ZeroNewOrderResponseMessage ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      orderStatus        |-> [i \in 1 .. 1 |-> 0],
      reserved19         |-> [i \in 1 .. 19 |-> 0] ]

(* New Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessage ==
    { ZeroNewOrderResponseMessage }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage EXCEPT !.reserved19 = one] : one \in Sample(19) }

(***************************************************************************)
(* Modify Order Response: 87 bytes                                         *)
(***************************************************************************)

ModifyOrderResponse ==
    [ matchingEngineTime    : Sample(8),
      mpid                  : Sample(4),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      symbolId              : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      price                 : Sample(8),
      modifyStatus          : Sample(1),
      reserved10            : Sample(10) ]

EncodeModifyOrderResponse(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.price
        \o message.modifyStatus
        \o message.reserved10

DecodeModifyOrderResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET price == ReadBytes(leavesQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET modifyStatus == ReadBytes(price.rest, 1) IN IF ~modifyStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(modifyStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpid                  |-> mpid.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         symbolId              |-> symbolId.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         price                 |-> price.value,
         modifyStatus          |-> modifyStatus.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroModifyOrderResponse ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      modifyStatus          |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse ==
    { ZeroModifyOrderResponse }
        \cup { [ZeroModifyOrderResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.modifyStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Response: 79 bytes                                         *)
(***************************************************************************)

CancelOrderResponse ==
    [ matchingEngineTime    : Sample(8),
      mpid                  : Sample(4),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      symbolId              : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      cancelStatus          : Sample(1),
      reserved10            : Sample(10) ]

EncodeCancelOrderResponse(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.cancelStatus
        \o message.reserved10

DecodeCancelOrderResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelStatus == ReadBytes(leavesQty.rest, 1) IN IF ~cancelStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(cancelStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpid                  |-> mpid.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         symbolId              |-> symbolId.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         cancelStatus          |-> cancelStatus.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderResponse ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cancelStatus          |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order Response at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponse ==
    { ZeroCancelOrderResponse }
        \cup { [ZeroCancelOrderResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.cancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order By Exchange Order Id Response Message: 59 bytes            *)
(***************************************************************************)

CancelOrderByExchangeOrderIdResponseMessage ==
    [ matchingEngineTime : Sample(8),
      mpid               : Sample(4),
      clientOrderId      : Sample(20),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      leavesQty          : Sample(4),
      cancelStatus       : Sample(1),
      reserved10         : Sample(10) ]

EncodeCancelOrderByExchangeOrderIdResponseMessage(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.cancelStatus
        \o message.reserved10

DecodeCancelOrderByExchangeOrderIdResponseMessage(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelStatus == ReadBytes(leavesQty.rest, 1) IN IF ~cancelStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(cancelStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpid               |-> mpid.value,
         clientOrderId      |-> clientOrderId.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         leavesQty          |-> leavesQty.value,
         cancelStatus       |-> cancelStatus.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderByExchangeOrderIdResponseMessage ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      leavesQty          |-> [i \in 1 .. 4 |-> 0],
      cancelStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order By Exchange Order Id Response Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderByExchangeOrderIdResponseMessage ==
    { ZeroCancelOrderByExchangeOrderIdResponseMessage }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.cancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* System State Notification: 26 bytes                                     *)
(***************************************************************************)

SystemStateNotification ==
    [ matchingEngineTime : Sample(8),
      meoVersion         : Sample(8),
      sessionId          : Sample(1),
      systemStatus       : Sample(1),
      reserved8          : Sample(8) ]

EncodeSystemStateNotification(message) ==
    message.matchingEngineTime
        \o message.meoVersion
        \o message.sessionId
        \o message.systemStatus
        \o message.reserved8

DecodeSystemStateNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET meoVersion == ReadBytes(matchingEngineTime.rest, 8) IN IF ~meoVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(meoVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(systemStatus.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         meoVersion         |-> meoVersion.value,
         sessionId          |-> sessionId.value,
         systemStatus       |-> systemStatus.value,
         reserved8          |-> reserved8.value ], reserved8.rest)

ZeroSystemStateNotification ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      meoVersion         |-> [i \in 1 .. 8 |-> 0],
      sessionId          |-> [i \in 1 .. 1 |-> 0],
      systemStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved8          |-> [i \in 1 .. 8 |-> 0] ]

(* System State Notification at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateNotification ==
    { ZeroSystemStateNotification }
        \cup { [ZeroSystemStateNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.meoVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateNotification EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotification EXCEPT !.systemStatus = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateNotification EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* New Order Notification: 137 bytes                                       *)
(***************************************************************************)

NewOrderNotification ==
    [ matchingEngineTime              : Sample(8),
      mpid                            : Sample(4),
      orderId                         : Sample(8),
      clientOrderId                   : Sample(20),
      symbolId                        : Sample(4),
      price                           : Sample(8),
      size                            : Sample(4),
      newOrderInstructions            : Sample(2),
      timeInForce                     : Sample(1),
      orderType                       : Sample(1),
      priceSlidingAndRepriceFrequency : Sample(1),
      selfTradeProtection             : Sample(1),
      selfTradeProtectionGroup        : Sample(1),
      routing                         : Sample(1),
      tradingCollarDollarValue        : Sample(8),
      capacity                        : Sample(1),
      account                         : Sample(16),
      clearingAccount                 : Sample(4),
      minQty                          : Sample(4),
      maxFloorQty                     : Sample(4),
      displayRangeQty                 : Sample(4),
      pegOffset                       : Sample(8),
      locateAccount                   : Sample(4),
      purgeGroup                      : Sample(1),
      originalOrderCapacity           : Sample(1),
      orderExpiryTime                 : Sample(8),
      reserved10                      : Sample(10) ]

EncodeNewOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.orderId
        \o message.clientOrderId
        \o message.symbolId
        \o message.price
        \o message.size
        \o message.newOrderInstructions
        \o message.timeInForce
        \o message.orderType
        \o message.priceSlidingAndRepriceFrequency
        \o message.selfTradeProtection
        \o message.selfTradeProtectionGroup
        \o message.routing
        \o message.tradingCollarDollarValue
        \o message.capacity
        \o message.account
        \o message.clearingAccount
        \o message.minQty
        \o message.maxFloorQty
        \o message.displayRangeQty
        \o message.pegOffset
        \o message.locateAccount
        \o message.purgeGroup
        \o message.originalOrderCapacity
        \o message.orderExpiryTime
        \o message.reserved10

DecodeNewOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET orderId == ReadBytes(mpid.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(orderId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET newOrderInstructions == ReadBytes(size.rest, 2) IN IF ~newOrderInstructions.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(newOrderInstructions.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderType == ReadBytes(timeInForce.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET priceSlidingAndRepriceFrequency == ReadBytes(orderType.rest, 1) IN IF ~priceSlidingAndRepriceFrequency.ok THEN Fail ELSE
    LET selfTradeProtection == ReadBytes(priceSlidingAndRepriceFrequency.rest, 1) IN IF ~selfTradeProtection.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(selfTradeProtection.rest, 1) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET routing == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~routing.ok THEN Fail ELSE
    LET tradingCollarDollarValue == ReadBytes(routing.rest, 8) IN IF ~tradingCollarDollarValue.ok THEN Fail ELSE
    LET capacity == ReadBytes(tradingCollarDollarValue.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(account.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET minQty == ReadBytes(clearingAccount.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloorQty == ReadBytes(minQty.rest, 4) IN IF ~maxFloorQty.ok THEN Fail ELSE
    LET displayRangeQty == ReadBytes(maxFloorQty.rest, 4) IN IF ~displayRangeQty.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(displayRangeQty.rest, 8) IN IF ~pegOffset.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(pegOffset.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(locateAccount.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET originalOrderCapacity == ReadBytes(purgeGroup.rest, 1) IN IF ~originalOrderCapacity.ok THEN Fail ELSE
    LET orderExpiryTime == ReadBytes(originalOrderCapacity.rest, 8) IN IF ~orderExpiryTime.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(orderExpiryTime.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime              |-> matchingEngineTime.value,
         mpid                            |-> mpid.value,
         orderId                         |-> orderId.value,
         clientOrderId                   |-> clientOrderId.value,
         symbolId                        |-> symbolId.value,
         price                           |-> price.value,
         size                            |-> size.value,
         newOrderInstructions            |-> newOrderInstructions.value,
         timeInForce                     |-> timeInForce.value,
         orderType                       |-> orderType.value,
         priceSlidingAndRepriceFrequency |-> priceSlidingAndRepriceFrequency.value,
         selfTradeProtection             |-> selfTradeProtection.value,
         selfTradeProtectionGroup        |-> selfTradeProtectionGroup.value,
         routing                         |-> routing.value,
         tradingCollarDollarValue        |-> tradingCollarDollarValue.value,
         capacity                        |-> capacity.value,
         account                         |-> account.value,
         clearingAccount                 |-> clearingAccount.value,
         minQty                          |-> minQty.value,
         maxFloorQty                     |-> maxFloorQty.value,
         displayRangeQty                 |-> displayRangeQty.value,
         pegOffset                       |-> pegOffset.value,
         locateAccount                   |-> locateAccount.value,
         purgeGroup                      |-> purgeGroup.value,
         originalOrderCapacity           |-> originalOrderCapacity.value,
         orderExpiryTime                 |-> orderExpiryTime.value,
         reserved10                      |-> reserved10.value ], reserved10.rest)

ZeroNewOrderNotification ==
    [ matchingEngineTime              |-> [i \in 1 .. 8 |-> 0],
      mpid                            |-> [i \in 1 .. 4 |-> 0],
      orderId                         |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                   |-> [i \in 1 .. 20 |-> 0],
      symbolId                        |-> [i \in 1 .. 4 |-> 0],
      price                           |-> [i \in 1 .. 8 |-> 0],
      size                            |-> [i \in 1 .. 4 |-> 0],
      newOrderInstructions            |-> [i \in 1 .. 2 |-> 0],
      timeInForce                     |-> [i \in 1 .. 1 |-> 0],
      orderType                       |-> [i \in 1 .. 1 |-> 0],
      priceSlidingAndRepriceFrequency |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtection             |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtectionGroup        |-> [i \in 1 .. 1 |-> 0],
      routing                         |-> [i \in 1 .. 1 |-> 0],
      tradingCollarDollarValue        |-> [i \in 1 .. 8 |-> 0],
      capacity                        |-> [i \in 1 .. 1 |-> 0],
      account                         |-> [i \in 1 .. 16 |-> 0],
      clearingAccount                 |-> [i \in 1 .. 4 |-> 0],
      minQty                          |-> [i \in 1 .. 4 |-> 0],
      maxFloorQty                     |-> [i \in 1 .. 4 |-> 0],
      displayRangeQty                 |-> [i \in 1 .. 4 |-> 0],
      pegOffset                       |-> [i \in 1 .. 8 |-> 0],
      locateAccount                   |-> [i \in 1 .. 4 |-> 0],
      purgeGroup                      |-> [i \in 1 .. 1 |-> 0],
      originalOrderCapacity           |-> [i \in 1 .. 1 |-> 0],
      orderExpiryTime                 |-> [i \in 1 .. 8 |-> 0],
      reserved10                      |-> [i \in 1 .. 10 |-> 0] ]

(* New Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderNotification ==
    { ZeroNewOrderNotification }
        \cup { [ZeroNewOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.newOrderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNotification EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.priceSlidingAndRepriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.selfTradeProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.routing = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.tradingCollarDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderNotification EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.maxFloorQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.displayRangeQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.pegOffset = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNotification EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.originalOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNotification EXCEPT !.orderExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNotification EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Modify Order Notification: 121 bytes                                    *)
(***************************************************************************)

ModifyOrderNotification ==
    [ matchingEngineTime      : Sample(8),
      mpid                    : Sample(4),
      clientOrderId           : Sample(20),
      originalClientOrderId   : Sample(20),
      symbolId                : Sample(4),
      orderId                 : Sample(8),
      price                   : Sample(8),
      size                    : Sample(4),
      leavesQty               : Sample(4),
      modifyOrderInstructions : Sample(1),
      minQty                  : Sample(4),
      maxFloorQty             : Sample(4),
      pendingModifyStatus     : Sample(1),
      pendingRejectReason     : Sample(1),
      locateAccount           : Sample(4),
      timeInForce             : Sample(1),
      orderExpiryTime         : Sample(8),
      reserved17              : Sample(17) ]

EncodeModifyOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.price
        \o message.size
        \o message.leavesQty
        \o message.modifyOrderInstructions
        \o message.minQty
        \o message.maxFloorQty
        \o message.pendingModifyStatus
        \o message.pendingRejectReason
        \o message.locateAccount
        \o message.timeInForce
        \o message.orderExpiryTime
        \o message.reserved17

DecodeModifyOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(size.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET modifyOrderInstructions == ReadBytes(leavesQty.rest, 1) IN IF ~modifyOrderInstructions.ok THEN Fail ELSE
    LET minQty == ReadBytes(modifyOrderInstructions.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloorQty == ReadBytes(minQty.rest, 4) IN IF ~maxFloorQty.ok THEN Fail ELSE
    LET pendingModifyStatus == ReadBytes(maxFloorQty.rest, 1) IN IF ~pendingModifyStatus.ok THEN Fail ELSE
    LET pendingRejectReason == ReadBytes(pendingModifyStatus.rest, 1) IN IF ~pendingRejectReason.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(pendingRejectReason.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(locateAccount.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderExpiryTime == ReadBytes(timeInForce.rest, 8) IN IF ~orderExpiryTime.ok THEN Fail ELSE
    LET reserved17 == ReadBytes(orderExpiryTime.rest, 17) IN IF ~reserved17.ok THEN Fail ELSE
    Ok([ matchingEngineTime      |-> matchingEngineTime.value,
         mpid                    |-> mpid.value,
         clientOrderId           |-> clientOrderId.value,
         originalClientOrderId   |-> originalClientOrderId.value,
         symbolId                |-> symbolId.value,
         orderId                 |-> orderId.value,
         price                   |-> price.value,
         size                    |-> size.value,
         leavesQty               |-> leavesQty.value,
         modifyOrderInstructions |-> modifyOrderInstructions.value,
         minQty                  |-> minQty.value,
         maxFloorQty             |-> maxFloorQty.value,
         pendingModifyStatus     |-> pendingModifyStatus.value,
         pendingRejectReason     |-> pendingRejectReason.value,
         locateAccount           |-> locateAccount.value,
         timeInForce             |-> timeInForce.value,
         orderExpiryTime         |-> orderExpiryTime.value,
         reserved17              |-> reserved17.value ], reserved17.rest)

ZeroModifyOrderNotification ==
    [ matchingEngineTime      |-> [i \in 1 .. 8 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      clientOrderId           |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId   |-> [i \in 1 .. 20 |-> 0],
      symbolId                |-> [i \in 1 .. 4 |-> 0],
      orderId                 |-> [i \in 1 .. 8 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      size                    |-> [i \in 1 .. 4 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      modifyOrderInstructions |-> [i \in 1 .. 1 |-> 0],
      minQty                  |-> [i \in 1 .. 4 |-> 0],
      maxFloorQty             |-> [i \in 1 .. 4 |-> 0],
      pendingModifyStatus     |-> [i \in 1 .. 1 |-> 0],
      pendingRejectReason     |-> [i \in 1 .. 1 |-> 0],
      locateAccount           |-> [i \in 1 .. 4 |-> 0],
      timeInForce             |-> [i \in 1 .. 1 |-> 0],
      orderExpiryTime         |-> [i \in 1 .. 8 |-> 0],
      reserved17              |-> [i \in 1 .. 17 |-> 0] ]

(* Modify Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderNotification ==
    { ZeroModifyOrderNotification }
        \cup { [ZeroModifyOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.modifyOrderInstructions = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.maxFloorQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.pendingModifyStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.pendingRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.orderExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNotification EXCEPT !.reserved17 = one] : one \in Sample(17) }

(***************************************************************************)
(* Cancel Reduce Size Order Notification: 71 bytes                         *)
(***************************************************************************)

CancelReduceSizeOrderNotification ==
    [ matchingEngineTime  : Sample(8),
      mpid                : Sample(4),
      clientOrderId       : Sample(20),
      symbolId            : Sample(4),
      orderId             : Sample(8),
      leavesQty           : Sample(4),
      cancelReason        : Sample(1),
      lastPrice           : Sample(8),
      lastSize            : Sample(4),
      pendingCancelStatus : Sample(1),
      pendingRejectReason : Sample(1),
      reserved8           : Sample(8) ]

EncodeCancelReduceSizeOrderNotification(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.cancelReason
        \o message.lastPrice
        \o message.lastSize
        \o message.pendingCancelStatus
        \o message.pendingRejectReason
        \o message.reserved8

DecodeCancelReduceSizeOrderNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(leavesQty.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(cancelReason.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET pendingCancelStatus == ReadBytes(lastSize.rest, 1) IN IF ~pendingCancelStatus.ok THEN Fail ELSE
    LET pendingRejectReason == ReadBytes(pendingCancelStatus.rest, 1) IN IF ~pendingRejectReason.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(pendingRejectReason.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ matchingEngineTime  |-> matchingEngineTime.value,
         mpid                |-> mpid.value,
         clientOrderId       |-> clientOrderId.value,
         symbolId            |-> symbolId.value,
         orderId             |-> orderId.value,
         leavesQty           |-> leavesQty.value,
         cancelReason        |-> cancelReason.value,
         lastPrice           |-> lastPrice.value,
         lastSize            |-> lastSize.value,
         pendingCancelStatus |-> pendingCancelStatus.value,
         pendingRejectReason |-> pendingRejectReason.value,
         reserved8           |-> reserved8.value ], reserved8.rest)

ZeroCancelReduceSizeOrderNotification ==
    [ matchingEngineTime  |-> [i \in 1 .. 8 |-> 0],
      mpid                |-> [i \in 1 .. 4 |-> 0],
      clientOrderId       |-> [i \in 1 .. 20 |-> 0],
      symbolId            |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      leavesQty           |-> [i \in 1 .. 4 |-> 0],
      cancelReason        |-> [i \in 1 .. 1 |-> 0],
      lastPrice           |-> [i \in 1 .. 8 |-> 0],
      lastSize            |-> [i \in 1 .. 4 |-> 0],
      pendingCancelStatus |-> [i \in 1 .. 1 |-> 0],
      pendingRejectReason |-> [i \in 1 .. 1 |-> 0],
      reserved8           |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Reduce Size Order Notification at zero, then each field in turn at the values it is checked at *)
CheckedCancelReduceSizeOrderNotification ==
    { ZeroCancelReduceSizeOrderNotification }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.pendingCancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.pendingRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroCancelReduceSizeOrderNotification EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Price Update Notification: 58 bytes                               *)
(***************************************************************************)

OrderPriceUpdateNotification ==
    [ matchingEngineTime : Sample(8),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      clientOrderId      : Sample(20),
      workingPrice       : Sample(8),
      nbboIndicator      : Sample(1),
      reserved9          : Sample(9) ]

EncodeOrderPriceUpdateNotification(message) ==
    message.matchingEngineTime
        \o message.symbolId
        \o message.orderId
        \o message.clientOrderId
        \o message.workingPrice
        \o message.nbboIndicator
        \o message.reserved9

DecodeOrderPriceUpdateNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(matchingEngineTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(orderId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET workingPrice == ReadBytes(clientOrderId.rest, 8) IN IF ~workingPrice.ok THEN Fail ELSE
    LET nbboIndicator == ReadBytes(workingPrice.rest, 1) IN IF ~nbboIndicator.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(nbboIndicator.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         clientOrderId      |-> clientOrderId.value,
         workingPrice       |-> workingPrice.value,
         nbboIndicator      |-> nbboIndicator.value,
         reserved9          |-> reserved9.value ], reserved9.rest)

ZeroOrderPriceUpdateNotification ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      workingPrice       |-> [i \in 1 .. 8 |-> 0],
      nbboIndicator      |-> [i \in 1 .. 1 |-> 0],
      reserved9          |-> [i \in 1 .. 9 |-> 0] ]

(* Order Price Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriceUpdateNotification ==
    { ZeroOrderPriceUpdateNotification }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.workingPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.nbboIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderPriceUpdateNotification EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Reserve Order Replenishment Notification: 42 bytes                      *)
(***************************************************************************)

ReserveOrderReplenishmentNotification ==
    [ matchingEngineTime : Sample(8),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      secondaryOrderId   : Sample(8),
      displayQty         : Sample(4),
      reserved10         : Sample(10) ]

EncodeReserveOrderReplenishmentNotification(message) ==
    message.matchingEngineTime
        \o message.symbolId
        \o message.orderId
        \o message.secondaryOrderId
        \o message.displayQty
        \o message.reserved10

DecodeReserveOrderReplenishmentNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(matchingEngineTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(orderId.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET displayQty == ReadBytes(secondaryOrderId.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(displayQty.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         secondaryOrderId   |-> secondaryOrderId.value,
         displayQty         |-> displayQty.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroReserveOrderReplenishmentNotification ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId   |-> [i \in 1 .. 8 |-> 0],
      displayQty         |-> [i \in 1 .. 4 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Reserve Order Replenishment Notification at zero, then each field in turn at the values it is checked at *)
CheckedReserveOrderReplenishmentNotification ==
    { ZeroReserveOrderReplenishmentNotification }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroReserveOrderReplenishmentNotification EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Execution Notification: 102 bytes                                       *)
(***************************************************************************)

ExecutionNotification ==
    [ matchingEngineTime           : Sample(8),
      mpid                         : Sample(4),
      symbolId                     : Sample(4),
      clientOrderId                : Sample(20),
      tradeId                      : Sample(8),
      executionId                  : Sample(8),
      correctionNumber             : Sample(1),
      tradeStatus                  : Sample(1),
      lastPrice                    : Sample(8),
      lastSize                     : Sample(4),
      orderExecutionInstructions   : Sample(2),
      executingTradingCenter       : Sample(1),
      secondaryOrderId             : Sample(8),
      liquidityIndicator           : Sample(3),
      locateAccount                : Sample(4),
      originalOrderCapacity        : Sample(1),
      additionalLiquidityIndicator : Sample(1),
      executingTradingCenterMpid   : Sample(4),
      reserved12                   : Sample(12) ]

EncodeExecutionNotification(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.symbolId
        \o message.clientOrderId
        \o message.tradeId
        \o message.executionId
        \o message.correctionNumber
        \o message.tradeStatus
        \o message.lastPrice
        \o message.lastSize
        \o message.orderExecutionInstructions
        \o message.executingTradingCenter
        \o message.secondaryOrderId
        \o message.liquidityIndicator
        \o message.locateAccount
        \o message.originalOrderCapacity
        \o message.additionalLiquidityIndicator
        \o message.executingTradingCenterMpid
        \o message.reserved12

DecodeExecutionNotification(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET symbolId == ReadBytes(mpid.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(symbolId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(clientOrderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(executionId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(correctionNumber.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET orderExecutionInstructions == ReadBytes(lastSize.rest, 2) IN IF ~orderExecutionInstructions.ok THEN Fail ELSE
    LET executingTradingCenter == ReadBytes(orderExecutionInstructions.rest, 1) IN IF ~executingTradingCenter.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(executingTradingCenter.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(secondaryOrderId.rest, 3) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(liquidityIndicator.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET originalOrderCapacity == ReadBytes(locateAccount.rest, 1) IN IF ~originalOrderCapacity.ok THEN Fail ELSE
    LET additionalLiquidityIndicator == ReadBytes(originalOrderCapacity.rest, 1) IN IF ~additionalLiquidityIndicator.ok THEN Fail ELSE
    LET executingTradingCenterMpid == ReadBytes(additionalLiquidityIndicator.rest, 4) IN IF ~executingTradingCenterMpid.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(executingTradingCenterMpid.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ matchingEngineTime           |-> matchingEngineTime.value,
         mpid                         |-> mpid.value,
         symbolId                     |-> symbolId.value,
         clientOrderId                |-> clientOrderId.value,
         tradeId                      |-> tradeId.value,
         executionId                  |-> executionId.value,
         correctionNumber             |-> correctionNumber.value,
         tradeStatus                  |-> tradeStatus.value,
         lastPrice                    |-> lastPrice.value,
         lastSize                     |-> lastSize.value,
         orderExecutionInstructions   |-> orderExecutionInstructions.value,
         executingTradingCenter       |-> executingTradingCenter.value,
         secondaryOrderId             |-> secondaryOrderId.value,
         liquidityIndicator           |-> liquidityIndicator.value,
         locateAccount                |-> locateAccount.value,
         originalOrderCapacity        |-> originalOrderCapacity.value,
         additionalLiquidityIndicator |-> additionalLiquidityIndicator.value,
         executingTradingCenterMpid   |-> executingTradingCenterMpid.value,
         reserved12                   |-> reserved12.value ], reserved12.rest)

ZeroExecutionNotification ==
    [ matchingEngineTime           |-> [i \in 1 .. 8 |-> 0],
      mpid                         |-> [i \in 1 .. 4 |-> 0],
      symbolId                     |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      tradeId                      |-> [i \in 1 .. 8 |-> 0],
      executionId                  |-> [i \in 1 .. 8 |-> 0],
      correctionNumber             |-> [i \in 1 .. 1 |-> 0],
      tradeStatus                  |-> [i \in 1 .. 1 |-> 0],
      lastPrice                    |-> [i \in 1 .. 8 |-> 0],
      lastSize                     |-> [i \in 1 .. 4 |-> 0],
      orderExecutionInstructions   |-> [i \in 1 .. 2 |-> 0],
      executingTradingCenter       |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId             |-> [i \in 1 .. 8 |-> 0],
      liquidityIndicator           |-> [i \in 1 .. 3 |-> 0],
      locateAccount                |-> [i \in 1 .. 4 |-> 0],
      originalOrderCapacity        |-> [i \in 1 .. 1 |-> 0],
      additionalLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      executingTradingCenterMpid   |-> [i \in 1 .. 4 |-> 0],
      reserved12                   |-> [i \in 1 .. 12 |-> 0] ]

(* Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotification ==
    { ZeroExecutionNotification }
        \cup { [ZeroExecutionNotification EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.orderExecutionInstructions = one] : one \in Sample(2) }
        \cup { [ZeroExecutionNotification EXCEPT !.executingTradingCenter = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification EXCEPT !.liquidityIndicator = one] : one \in Sample(3) }
        \cup { [ZeroExecutionNotification EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.originalOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.additionalLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification EXCEPT !.executingTradingCenterMpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SymbolUpdateCode == 21333  \* "SU"
NewOrderResponseMessageCode == 20050  \* "NR"
ModifyOrderResponseCode == 19794  \* "MR"
CancelOrderResponseCode == 17234  \* "CR"
CancelOrderByExchangeOrderIdResponseMessageCode == 17233  \* "CQ"
SystemStateNotificationCode == 21326  \* "SN"
NewOrderNotificationCode == 20273  \* "O1"
ModifyOrderNotificationCode == 19790  \* "MN"
CancelReduceSizeOrderNotificationCode == 22606  \* "XN"
OrderPriceUpdateNotificationCode == 20529  \* "P1"
ReserveOrderReplenishmentNotificationCode == 21057  \* "RA"
ExecutionNotificationCode == 17713  \* "E1"

SequencedMessage ==
    [ tag : {SymbolUpdateCode}, body : SymbolUpdate ]
        \cup [ tag : {NewOrderResponseMessageCode}, body : NewOrderResponseMessage ]
        \cup [ tag : {ModifyOrderResponseCode}, body : ModifyOrderResponse ]
        \cup [ tag : {CancelOrderResponseCode}, body : CancelOrderResponse ]
        \cup [ tag : {CancelOrderByExchangeOrderIdResponseMessageCode}, body : CancelOrderByExchangeOrderIdResponseMessage ]
        \cup [ tag : {SystemStateNotificationCode}, body : SystemStateNotification ]
        \cup [ tag : {NewOrderNotificationCode}, body : NewOrderNotification ]
        \cup [ tag : {ModifyOrderNotificationCode}, body : ModifyOrderNotification ]
        \cup [ tag : {CancelReduceSizeOrderNotificationCode}, body : CancelReduceSizeOrderNotification ]
        \cup [ tag : {OrderPriceUpdateNotificationCode}, body : OrderPriceUpdateNotification ]
        \cup [ tag : {ReserveOrderReplenishmentNotificationCode}, body : ReserveOrderReplenishmentNotification ]
        \cup [ tag : {ExecutionNotificationCode}, body : ExecutionNotification ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SymbolUpdateCode -> EncodeSymbolUpdate(message.body)
      [] message.tag = NewOrderResponseMessageCode -> EncodeNewOrderResponseMessage(message.body)
      [] message.tag = ModifyOrderResponseCode -> EncodeModifyOrderResponse(message.body)
      [] message.tag = CancelOrderResponseCode -> EncodeCancelOrderResponse(message.body)
      [] message.tag = CancelOrderByExchangeOrderIdResponseMessageCode -> EncodeCancelOrderByExchangeOrderIdResponseMessage(message.body)
      [] message.tag = SystemStateNotificationCode -> EncodeSystemStateNotification(message.body)
      [] message.tag = NewOrderNotificationCode -> EncodeNewOrderNotification(message.body)
      [] message.tag = ModifyOrderNotificationCode -> EncodeModifyOrderNotification(message.body)
      [] message.tag = CancelReduceSizeOrderNotificationCode -> EncodeCancelReduceSizeOrderNotification(message.body)
      [] message.tag = OrderPriceUpdateNotificationCode -> EncodeOrderPriceUpdateNotification(message.body)
      [] message.tag = ReserveOrderReplenishmentNotificationCode -> EncodeReserveOrderReplenishmentNotification(message.body)
      [] message.tag = ExecutionNotificationCode -> EncodeExecutionNotification(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SymbolUpdateCode -> DecodeSymbolUpdate(bytes)
              [] tag = NewOrderResponseMessageCode -> DecodeNewOrderResponseMessage(bytes)
              [] tag = ModifyOrderResponseCode -> DecodeModifyOrderResponse(bytes)
              [] tag = CancelOrderResponseCode -> DecodeCancelOrderResponse(bytes)
              [] tag = CancelOrderByExchangeOrderIdResponseMessageCode -> DecodeCancelOrderByExchangeOrderIdResponseMessage(bytes)
              [] tag = SystemStateNotificationCode -> DecodeSystemStateNotification(bytes)
              [] tag = NewOrderNotificationCode -> DecodeNewOrderNotification(bytes)
              [] tag = ModifyOrderNotificationCode -> DecodeModifyOrderNotification(bytes)
              [] tag = CancelReduceSizeOrderNotificationCode -> DecodeCancelReduceSizeOrderNotification(bytes)
              [] tag = OrderPriceUpdateNotificationCode -> DecodeOrderPriceUpdateNotification(bytes)
              [] tag = ReserveOrderReplenishmentNotificationCode -> DecodeReserveOrderReplenishmentNotification(bytes)
              [] tag = ExecutionNotificationCode -> DecodeExecutionNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SymbolUpdateCode, body |-> ZeroSymbolUpdate]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SymbolUpdateCode, body |-> one] : one \in CheckedSymbolUpdate }
        \cup { [tag |-> NewOrderResponseMessageCode, body |-> one] : one \in CheckedNewOrderResponseMessage }
        \cup { [tag |-> ModifyOrderResponseCode, body |-> one] : one \in CheckedModifyOrderResponse }
        \cup { [tag |-> CancelOrderResponseCode, body |-> one] : one \in CheckedCancelOrderResponse }
        \cup { [tag |-> CancelOrderByExchangeOrderIdResponseMessageCode, body |-> one] : one \in CheckedCancelOrderByExchangeOrderIdResponseMessage }
        \cup { [tag |-> SystemStateNotificationCode, body |-> one] : one \in CheckedSystemStateNotification }
        \cup { [tag |-> NewOrderNotificationCode, body |-> one] : one \in CheckedNewOrderNotification }
        \cup { [tag |-> ModifyOrderNotificationCode, body |-> one] : one \in CheckedModifyOrderNotification }
        \cup { [tag |-> CancelReduceSizeOrderNotificationCode, body |-> one] : one \in CheckedCancelReduceSizeOrderNotification }
        \cup { [tag |-> OrderPriceUpdateNotificationCode, body |-> one] : one \in CheckedOrderPriceUpdateNotification }
        \cup { [tag |-> ReserveOrderReplenishmentNotificationCode, body |-> one] : one \in CheckedReserveOrderReplenishmentNotification }
        \cup { [tag |-> ExecutionNotificationCode, body |-> one] : one \in CheckedExecutionNotification }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber   : Sample(8),
      matchingEngineId : Sample(1),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o message.matchingEngineId
        \o EncodeUIntBE(message.sequencedMessage.tag, 2)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET matchingEngineId == ReadBytes(sequenceNumber.rest, 1) IN IF ~matchingEngineId.ok THEN Fail ELSE
    LET sequencedMessageType == ReadUIntBE(matchingEngineId.rest, 2) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber   |-> sequenceNumber.value,
         matchingEngineId |-> matchingEngineId.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber   |-> [i \in 1 .. 8 |-> 0],
      matchingEngineId |-> [i \in 1 .. 1 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.matchingEngineId = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* New Order Request Message: 129 bytes                                    *)
(***************************************************************************)

NewOrderRequestMessage ==
    [ reserved8                       : Sample(8),
      mpid                            : Sample(4),
      clientOrderId                   : Sample(20),
      symbolId                        : Sample(4),
      price                           : Sample(8),
      size                            : Sample(4),
      newOrderInstructions            : Sample(2),
      timeInForce                     : Sample(1),
      orderType                       : Sample(1),
      priceSlidingAndRepriceFrequency : Sample(1),
      selfTradeProtection             : Sample(1),
      selfTradeProtectionGroup        : Sample(1),
      routing                         : Sample(1),
      tradingCollarDollarValue        : Sample(8),
      capacity                        : Sample(1),
      account                         : Sample(16),
      clearingAccount                 : Sample(4),
      minQty                          : Sample(4),
      maxFloorQty                     : Sample(4),
      displayRangeQty                 : Sample(4),
      pegOffset                       : Sample(8),
      locateAccount                   : Sample(4),
      purgeGroup                      : Sample(1),
      orderExpiryTime                 : Sample(8),
      reserved11                      : Sample(11) ]

EncodeNewOrderRequestMessage(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.price
        \o message.size
        \o message.newOrderInstructions
        \o message.timeInForce
        \o message.orderType
        \o message.priceSlidingAndRepriceFrequency
        \o message.selfTradeProtection
        \o message.selfTradeProtectionGroup
        \o message.routing
        \o message.tradingCollarDollarValue
        \o message.capacity
        \o message.account
        \o message.clearingAccount
        \o message.minQty
        \o message.maxFloorQty
        \o message.displayRangeQty
        \o message.pegOffset
        \o message.locateAccount
        \o message.purgeGroup
        \o message.orderExpiryTime
        \o message.reserved11

DecodeNewOrderRequestMessage(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET newOrderInstructions == ReadBytes(size.rest, 2) IN IF ~newOrderInstructions.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(newOrderInstructions.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderType == ReadBytes(timeInForce.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET priceSlidingAndRepriceFrequency == ReadBytes(orderType.rest, 1) IN IF ~priceSlidingAndRepriceFrequency.ok THEN Fail ELSE
    LET selfTradeProtection == ReadBytes(priceSlidingAndRepriceFrequency.rest, 1) IN IF ~selfTradeProtection.ok THEN Fail ELSE
    LET selfTradeProtectionGroup == ReadBytes(selfTradeProtection.rest, 1) IN IF ~selfTradeProtectionGroup.ok THEN Fail ELSE
    LET routing == ReadBytes(selfTradeProtectionGroup.rest, 1) IN IF ~routing.ok THEN Fail ELSE
    LET tradingCollarDollarValue == ReadBytes(routing.rest, 8) IN IF ~tradingCollarDollarValue.ok THEN Fail ELSE
    LET capacity == ReadBytes(tradingCollarDollarValue.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET account == ReadBytes(capacity.rest, 16) IN IF ~account.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(account.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET minQty == ReadBytes(clearingAccount.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloorQty == ReadBytes(minQty.rest, 4) IN IF ~maxFloorQty.ok THEN Fail ELSE
    LET displayRangeQty == ReadBytes(maxFloorQty.rest, 4) IN IF ~displayRangeQty.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(displayRangeQty.rest, 8) IN IF ~pegOffset.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(pegOffset.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(locateAccount.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET orderExpiryTime == ReadBytes(purgeGroup.rest, 8) IN IF ~orderExpiryTime.ok THEN Fail ELSE
    LET reserved11 == ReadBytes(orderExpiryTime.rest, 11) IN IF ~reserved11.ok THEN Fail ELSE
    Ok([ reserved8                       |-> reserved8.value,
         mpid                            |-> mpid.value,
         clientOrderId                   |-> clientOrderId.value,
         symbolId                        |-> symbolId.value,
         price                           |-> price.value,
         size                            |-> size.value,
         newOrderInstructions            |-> newOrderInstructions.value,
         timeInForce                     |-> timeInForce.value,
         orderType                       |-> orderType.value,
         priceSlidingAndRepriceFrequency |-> priceSlidingAndRepriceFrequency.value,
         selfTradeProtection             |-> selfTradeProtection.value,
         selfTradeProtectionGroup        |-> selfTradeProtectionGroup.value,
         routing                         |-> routing.value,
         tradingCollarDollarValue        |-> tradingCollarDollarValue.value,
         capacity                        |-> capacity.value,
         account                         |-> account.value,
         clearingAccount                 |-> clearingAccount.value,
         minQty                          |-> minQty.value,
         maxFloorQty                     |-> maxFloorQty.value,
         displayRangeQty                 |-> displayRangeQty.value,
         pegOffset                       |-> pegOffset.value,
         locateAccount                   |-> locateAccount.value,
         purgeGroup                      |-> purgeGroup.value,
         orderExpiryTime                 |-> orderExpiryTime.value,
         reserved11                      |-> reserved11.value ], reserved11.rest)

ZeroNewOrderRequestMessage ==
    [ reserved8                       |-> [i \in 1 .. 8 |-> 0],
      mpid                            |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                   |-> [i \in 1 .. 20 |-> 0],
      symbolId                        |-> [i \in 1 .. 4 |-> 0],
      price                           |-> [i \in 1 .. 8 |-> 0],
      size                            |-> [i \in 1 .. 4 |-> 0],
      newOrderInstructions            |-> [i \in 1 .. 2 |-> 0],
      timeInForce                     |-> [i \in 1 .. 1 |-> 0],
      orderType                       |-> [i \in 1 .. 1 |-> 0],
      priceSlidingAndRepriceFrequency |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtection             |-> [i \in 1 .. 1 |-> 0],
      selfTradeProtectionGroup        |-> [i \in 1 .. 1 |-> 0],
      routing                         |-> [i \in 1 .. 1 |-> 0],
      tradingCollarDollarValue        |-> [i \in 1 .. 8 |-> 0],
      capacity                        |-> [i \in 1 .. 1 |-> 0],
      account                         |-> [i \in 1 .. 16 |-> 0],
      clearingAccount                 |-> [i \in 1 .. 4 |-> 0],
      minQty                          |-> [i \in 1 .. 4 |-> 0],
      maxFloorQty                     |-> [i \in 1 .. 4 |-> 0],
      displayRangeQty                 |-> [i \in 1 .. 4 |-> 0],
      pegOffset                       |-> [i \in 1 .. 8 |-> 0],
      locateAccount                   |-> [i \in 1 .. 4 |-> 0],
      purgeGroup                      |-> [i \in 1 .. 1 |-> 0],
      orderExpiryTime                 |-> [i \in 1 .. 8 |-> 0],
      reserved11                      |-> [i \in 1 .. 11 |-> 0] ]

(* New Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderRequestMessage ==
    { ZeroNewOrderRequestMessage }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.newOrderInstructions = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.priceSlidingAndRepriceFrequency = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfTradeProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.selfTradeProtectionGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.routing = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.tradingCollarDollarValue = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.account = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.maxFloorQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.displayRangeQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.pegOffset = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.orderExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderRequestMessage EXCEPT !.reserved11 = one] : one \in Sample(11) }

(***************************************************************************)
(* New Order Response Message: 76 bytes                                    *)
(***************************************************************************)

NewOrderResponseMessage2 ==
    [ matchingEngineTime : Sample(8),
      mpid               : Sample(4),
      clientOrderId      : Sample(20),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      price              : Sample(8),
      size               : Sample(4),
      orderStatus        : Sample(1),
      reserved19         : Sample(19) ]

EncodeNewOrderResponseMessage2(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.price
        \o message.size
        \o message.orderStatus
        \o message.reserved19

DecodeNewOrderResponseMessage2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(size.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET reserved19 == ReadBytes(orderStatus.rest, 19) IN IF ~reserved19.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpid               |-> mpid.value,
         clientOrderId      |-> clientOrderId.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         price              |-> price.value,
         size               |-> size.value,
         orderStatus        |-> orderStatus.value,
         reserved19         |-> reserved19.value ], reserved19.rest)

ZeroNewOrderResponseMessage2 ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      orderStatus        |-> [i \in 1 .. 1 |-> 0],
      reserved19         |-> [i \in 1 .. 19 |-> 0] ]

(* New Order Response Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponseMessage2 ==
    { ZeroNewOrderResponseMessage2 }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponseMessage2 EXCEPT !.reserved19 = one] : one \in Sample(19) }

(***************************************************************************)
(* Modify Order Request Message: 109 bytes                                 *)
(***************************************************************************)

ModifyOrderRequestMessage ==
    [ reserved8               : Sample(8),
      mpid                    : Sample(4),
      clientOrderId           : Sample(20),
      originalClientOrderId   : Sample(20),
      symbolId                : Sample(4),
      price                   : Sample(8),
      size                    : Sample(4),
      modifyOrderInstructions : Sample(1),
      minQty                  : Sample(4),
      maxFloorQty             : Sample(4),
      locateAccount           : Sample(4),
      timeInForce             : Sample(1),
      orderExpiryTime         : Sample(8),
      reserved19              : Sample(19) ]

EncodeModifyOrderRequestMessage(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.price
        \o message.size
        \o message.modifyOrderInstructions
        \o message.minQty
        \o message.maxFloorQty
        \o message.locateAccount
        \o message.timeInForce
        \o message.orderExpiryTime
        \o message.reserved19

DecodeModifyOrderRequestMessage(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET modifyOrderInstructions == ReadBytes(size.rest, 1) IN IF ~modifyOrderInstructions.ok THEN Fail ELSE
    LET minQty == ReadBytes(modifyOrderInstructions.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET maxFloorQty == ReadBytes(minQty.rest, 4) IN IF ~maxFloorQty.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(maxFloorQty.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(locateAccount.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderExpiryTime == ReadBytes(timeInForce.rest, 8) IN IF ~orderExpiryTime.ok THEN Fail ELSE
    LET reserved19 == ReadBytes(orderExpiryTime.rest, 19) IN IF ~reserved19.ok THEN Fail ELSE
    Ok([ reserved8               |-> reserved8.value,
         mpid                    |-> mpid.value,
         clientOrderId           |-> clientOrderId.value,
         originalClientOrderId   |-> originalClientOrderId.value,
         symbolId                |-> symbolId.value,
         price                   |-> price.value,
         size                    |-> size.value,
         modifyOrderInstructions |-> modifyOrderInstructions.value,
         minQty                  |-> minQty.value,
         maxFloorQty             |-> maxFloorQty.value,
         locateAccount           |-> locateAccount.value,
         timeInForce             |-> timeInForce.value,
         orderExpiryTime         |-> orderExpiryTime.value,
         reserved19              |-> reserved19.value ], reserved19.rest)

ZeroModifyOrderRequestMessage ==
    [ reserved8               |-> [i \in 1 .. 8 |-> 0],
      mpid                    |-> [i \in 1 .. 4 |-> 0],
      clientOrderId           |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId   |-> [i \in 1 .. 20 |-> 0],
      symbolId                |-> [i \in 1 .. 4 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      size                    |-> [i \in 1 .. 4 |-> 0],
      modifyOrderInstructions |-> [i \in 1 .. 1 |-> 0],
      minQty                  |-> [i \in 1 .. 4 |-> 0],
      maxFloorQty             |-> [i \in 1 .. 4 |-> 0],
      locateAccount           |-> [i \in 1 .. 4 |-> 0],
      timeInForce             |-> [i \in 1 .. 1 |-> 0],
      orderExpiryTime         |-> [i \in 1 .. 8 |-> 0],
      reserved19              |-> [i \in 1 .. 19 |-> 0] ]

(* Modify Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderRequestMessage ==
    { ZeroModifyOrderRequestMessage }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.modifyOrderInstructions = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.maxFloorQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.orderExpiryTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderRequestMessage EXCEPT !.reserved19 = one] : one \in Sample(19) }

(***************************************************************************)
(* Modify Order Response: 87 bytes                                         *)
(***************************************************************************)

ModifyOrderResponse2 ==
    [ matchingEngineTime    : Sample(8),
      mpid                  : Sample(4),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      symbolId              : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      price                 : Sample(8),
      modifyStatus          : Sample(1),
      reserved10            : Sample(10) ]

EncodeModifyOrderResponse2(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.price
        \o message.modifyStatus
        \o message.reserved10

DecodeModifyOrderResponse2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET price == ReadBytes(leavesQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET modifyStatus == ReadBytes(price.rest, 1) IN IF ~modifyStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(modifyStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpid                  |-> mpid.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         symbolId              |-> symbolId.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         price                 |-> price.value,
         modifyStatus          |-> modifyStatus.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroModifyOrderResponse2 ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      modifyStatus          |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse2 ==
    { ZeroModifyOrderResponse2 }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.modifyStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Request: 66 bytes                                          *)
(***************************************************************************)

CancelOrderRequest ==
    [ reserved8             : Sample(8),
      mpid                  : Sample(4),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      symbolId              : Sample(4),
      reserved10            : Sample(10) ]

EncodeCancelOrderRequest(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.reserved10

DecodeCancelOrderRequest(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(symbolId.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ reserved8             |-> reserved8.value,
         mpid                  |-> mpid.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         symbolId              |-> symbolId.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderRequest ==
    [ reserved8             |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order Request at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRequest ==
    { ZeroCancelOrderRequest }
        \cup { [ZeroCancelOrderRequest EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderRequest EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderRequest EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderRequest EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order Response: 79 bytes                                         *)
(***************************************************************************)

CancelOrderResponse2 ==
    [ matchingEngineTime    : Sample(8),
      mpid                  : Sample(4),
      clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      symbolId              : Sample(4),
      orderId               : Sample(8),
      leavesQty             : Sample(4),
      cancelStatus          : Sample(1),
      reserved10            : Sample(10) ]

EncodeCancelOrderResponse2(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.originalClientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.cancelStatus
        \o message.reserved10

DecodeCancelOrderResponse2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(originalClientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelStatus == ReadBytes(leavesQty.rest, 1) IN IF ~cancelStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(cancelStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime    |-> matchingEngineTime.value,
         mpid                  |-> mpid.value,
         clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         symbolId              |-> symbolId.value,
         orderId               |-> orderId.value,
         leavesQty             |-> leavesQty.value,
         cancelStatus          |-> cancelStatus.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderResponse2 ==
    [ matchingEngineTime    |-> [i \in 1 .. 8 |-> 0],
      mpid                  |-> [i \in 1 .. 4 |-> 0],
      clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cancelStatus          |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order Response at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderResponse2 ==
    { ZeroCancelOrderResponse2 }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.cancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderResponse2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order By Exchange Order Id Request: 54 bytes                     *)
(***************************************************************************)

CancelOrderByExchangeOrderIdRequest ==
    [ reserved8     : Sample(8),
      mpid          : Sample(4),
      clientOrderId : Sample(20),
      orderId       : Sample(8),
      symbolId      : Sample(4),
      reserved10    : Sample(10) ]

EncodeCancelOrderByExchangeOrderIdRequest(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.orderId
        \o message.symbolId
        \o message.reserved10

DecodeCancelOrderByExchangeOrderIdRequest(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(orderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(symbolId.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ reserved8     |-> reserved8.value,
         mpid          |-> mpid.value,
         clientOrderId |-> clientOrderId.value,
         orderId       |-> orderId.value,
         symbolId      |-> symbolId.value,
         reserved10    |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderByExchangeOrderIdRequest ==
    [ reserved8     |-> [i \in 1 .. 8 |-> 0],
      mpid          |-> [i \in 1 .. 4 |-> 0],
      clientOrderId |-> [i \in 1 .. 20 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      symbolId      |-> [i \in 1 .. 4 |-> 0],
      reserved10    |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order By Exchange Order Id Request at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderByExchangeOrderIdRequest ==
    { ZeroCancelOrderByExchangeOrderIdRequest }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdRequest EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Cancel Order By Exchange Order Id Response Message: 59 bytes            *)
(***************************************************************************)

CancelOrderByExchangeOrderIdResponseMessage2 ==
    [ matchingEngineTime : Sample(8),
      mpid               : Sample(4),
      clientOrderId      : Sample(20),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      leavesQty          : Sample(4),
      cancelStatus       : Sample(1),
      reserved10         : Sample(10) ]

EncodeCancelOrderByExchangeOrderIdResponseMessage2(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.orderId
        \o message.leavesQty
        \o message.cancelStatus
        \o message.reserved10

DecodeCancelOrderByExchangeOrderIdResponseMessage2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cancelStatus == ReadBytes(leavesQty.rest, 1) IN IF ~cancelStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(cancelStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         mpid               |-> mpid.value,
         clientOrderId      |-> clientOrderId.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         leavesQty          |-> leavesQty.value,
         cancelStatus       |-> cancelStatus.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroCancelOrderByExchangeOrderIdResponseMessage2 ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      mpid               |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      leavesQty          |-> [i \in 1 .. 4 |-> 0],
      cancelStatus       |-> [i \in 1 .. 1 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Cancel Order By Exchange Order Id Response Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderByExchangeOrderIdResponseMessage2 ==
    { ZeroCancelOrderByExchangeOrderIdResponseMessage2 }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.cancelStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelOrderByExchangeOrderIdResponseMessage2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Mass Cancel Request: 44 bytes                                           *)
(***************************************************************************)

MassCancelRequest ==
    [ reserved8     : Sample(8),
      mpid          : Sample(4),
      clientOrderId : Sample(20),
      scope         : Sample(1),
      action        : Sample(1),
      purgeGroup    : Sample(1),
      reserved9     : Sample(9) ]

EncodeMassCancelRequest(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.scope
        \o message.action
        \o message.purgeGroup
        \o message.reserved9

DecodeMassCancelRequest(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET scope == ReadBytes(clientOrderId.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET action == ReadBytes(scope.rest, 1) IN IF ~action.ok THEN Fail ELSE
    LET purgeGroup == ReadBytes(action.rest, 1) IN IF ~purgeGroup.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(purgeGroup.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ reserved8     |-> reserved8.value,
         mpid          |-> mpid.value,
         clientOrderId |-> clientOrderId.value,
         scope         |-> scope.value,
         action        |-> action.value,
         purgeGroup    |-> purgeGroup.value,
         reserved9     |-> reserved9.value ], reserved9.rest)

ZeroMassCancelRequest ==
    [ reserved8     |-> [i \in 1 .. 8 |-> 0],
      mpid          |-> [i \in 1 .. 4 |-> 0],
      clientOrderId |-> [i \in 1 .. 20 |-> 0],
      scope         |-> [i \in 1 .. 1 |-> 0],
      action        |-> [i \in 1 .. 1 |-> 0],
      purgeGroup    |-> [i \in 1 .. 1 |-> 0],
      reserved9     |-> [i \in 1 .. 9 |-> 0] ]

(* Mass Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequest ==
    { ZeroMassCancelRequest }
        \cup { [ZeroMassCancelRequest EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelRequest EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.action = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.purgeGroup = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelRequest EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Matching Engine Status: 10 bytes                                        *)
(***************************************************************************)

MatchingEngineStatus ==
    [ loginStatus           : Sample(1),
      tradingSessionId      : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeMatchingEngineStatus(message) ==
    message.loginStatus
        \o message.tradingSessionId
        \o message.highestSequenceNumber

DecodeMatchingEngineStatus(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(loginStatus.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(tradingSessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         tradingSessionId      |-> tradingSessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroMatchingEngineStatus ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId      |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Matching Engine Status at zero, then each field in turn at the values it is checked at *)
CheckedMatchingEngineStatus ==
    { ZeroMatchingEngineStatus }
        \cup { [ZeroMatchingEngineStatus EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroMatchingEngineStatus EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroMatchingEngineStatus EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(* A run of Matching Engine Status, written one after another *)
RECURSIVE EncodeMatchingEngineStatusList(_)
EncodeMatchingEngineStatusList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMatchingEngineStatus(Head(messages)) \o EncodeMatchingEngineStatusList(Tail(messages))

(* As many Matching Engine Status as the field that counts them says *)
RECURSIVE ReadMatchingEngineStatusList(_, _)
ReadMatchingEngineStatusList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMatchingEngineStatus(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMatchingEngineStatusList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Matching Engine Status of each kind, for the lists that carry them *)
OneMatchingEngineStatus == { ZeroMatchingEngineStatus }

(***************************************************************************)
(* Mass Cancel Response                                                    *)
(***************************************************************************)

MassCancelResponse ==
    [ notificationTime     : Sample(8),
      mpid                 : Sample(4),
      clientOrderId        : Sample(20),
      matchingEngineStatus : SampleLists(OneMatchingEngineStatus),
      reserved10           : Sample(10) ]

EncodeMassCancelResponse(message) ==
    message.notificationTime
        \o message.mpid
        \o message.clientOrderId
        \o EncodeUIntLE(Len(message.matchingEngineStatus), 1)
        \o EncodeMatchingEngineStatusList(message.matchingEngineStatus)
        \o message.reserved10

DecodeMassCancelResponse(bytes) ==
    LET notificationTime == ReadBytes(bytes, 8) IN IF ~notificationTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(notificationTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET numberOfMatchingEngines == ReadUIntLE(clientOrderId.rest, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    LET matchingEngineStatus == ReadMatchingEngineStatusList(numberOfMatchingEngines.rest, numberOfMatchingEngines.value) IN IF ~matchingEngineStatus.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(matchingEngineStatus.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ notificationTime     |-> notificationTime.value,
         mpid                 |-> mpid.value,
         clientOrderId        |-> clientOrderId.value,
         matchingEngineStatus |-> matchingEngineStatus.value,
         reserved10           |-> reserved10.value ], reserved10.rest)

ZeroMassCancelResponse ==
    [ notificationTime     |-> [i \in 1 .. 8 |-> 0],
      mpid                 |-> [i \in 1 .. 4 |-> 0],
      clientOrderId        |-> [i \in 1 .. 20 |-> 0],
      matchingEngineStatus |-> << >>,
      reserved10           |-> [i \in 1 .. 10 |-> 0] ]

(* Mass Cancel Response at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponse ==
    { ZeroMassCancelResponse }
        \cup { [ZeroMassCancelResponse EXCEPT !.notificationTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroMassCancelResponse EXCEPT !.matchingEngineStatus = one] : one \in SampleLists(OneMatchingEngineStatus) }
        \cup { [ZeroMassCancelResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Aggressive Side Purge Request: 56 bytes                                 *)
(***************************************************************************)

AggressiveSidePurgeRequest ==
    [ reserved8         : Sample(8),
      mpid              : Sample(4),
      clientOrderId     : Sample(20),
      symbolId          : Sample(4),
      purgeInstructions : Sample(2),
      price             : Sample(8),
      reserved10        : Sample(10) ]

EncodeAggressiveSidePurgeRequest(message) ==
    message.reserved8
        \o message.mpid
        \o message.clientOrderId
        \o message.symbolId
        \o message.purgeInstructions
        \o message.price
        \o message.reserved10

DecodeAggressiveSidePurgeRequest(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET mpid == ReadBytes(reserved8.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolId == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET purgeInstructions == ReadBytes(symbolId.rest, 2) IN IF ~purgeInstructions.ok THEN Fail ELSE
    LET price == ReadBytes(purgeInstructions.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(price.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ reserved8         |-> reserved8.value,
         mpid              |-> mpid.value,
         clientOrderId     |-> clientOrderId.value,
         symbolId          |-> symbolId.value,
         purgeInstructions |-> purgeInstructions.value,
         price             |-> price.value,
         reserved10        |-> reserved10.value ], reserved10.rest)

ZeroAggressiveSidePurgeRequest ==
    [ reserved8         |-> [i \in 1 .. 8 |-> 0],
      mpid              |-> [i \in 1 .. 4 |-> 0],
      clientOrderId     |-> [i \in 1 .. 20 |-> 0],
      symbolId          |-> [i \in 1 .. 4 |-> 0],
      purgeInstructions |-> [i \in 1 .. 2 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      reserved10        |-> [i \in 1 .. 10 |-> 0] ]

(* Aggressive Side Purge Request at zero, then each field in turn at the values it is checked at *)
CheckedAggressiveSidePurgeRequest ==
    { ZeroAggressiveSidePurgeRequest }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.purgeInstructions = one] : one \in Sample(2) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAggressiveSidePurgeRequest EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Aggressive Side Purge Response: 49 bytes                                *)
(***************************************************************************)

AggressiveSidePurgeResponse ==
    [ matchingEngineTime         : Sample(8),
      mpid                       : Sample(4),
      clientOrderId              : Sample(20),
      symboldId                  : Sample(4),
      purgeStatus                : Sample(1),
      numberOfOrdersCancelled    : Sample(1),
      aspEligibleOrdersCancelled : Sample(1),
      reserved10                 : Sample(10) ]

EncodeAggressiveSidePurgeResponse(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.clientOrderId
        \o message.symboldId
        \o message.purgeStatus
        \o message.numberOfOrdersCancelled
        \o message.aspEligibleOrdersCancelled
        \o message.reserved10

DecodeAggressiveSidePurgeResponse(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mpid.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symboldId == ReadBytes(clientOrderId.rest, 4) IN IF ~symboldId.ok THEN Fail ELSE
    LET purgeStatus == ReadBytes(symboldId.rest, 1) IN IF ~purgeStatus.ok THEN Fail ELSE
    LET numberOfOrdersCancelled == ReadBytes(purgeStatus.rest, 1) IN IF ~numberOfOrdersCancelled.ok THEN Fail ELSE
    LET aspEligibleOrdersCancelled == ReadBytes(numberOfOrdersCancelled.rest, 1) IN IF ~aspEligibleOrdersCancelled.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(aspEligibleOrdersCancelled.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime         |-> matchingEngineTime.value,
         mpid                       |-> mpid.value,
         clientOrderId              |-> clientOrderId.value,
         symboldId                  |-> symboldId.value,
         purgeStatus                |-> purgeStatus.value,
         numberOfOrdersCancelled    |-> numberOfOrdersCancelled.value,
         aspEligibleOrdersCancelled |-> aspEligibleOrdersCancelled.value,
         reserved10                 |-> reserved10.value ], reserved10.rest)

ZeroAggressiveSidePurgeResponse ==
    [ matchingEngineTime         |-> [i \in 1 .. 8 |-> 0],
      mpid                       |-> [i \in 1 .. 4 |-> 0],
      clientOrderId              |-> [i \in 1 .. 20 |-> 0],
      symboldId                  |-> [i \in 1 .. 4 |-> 0],
      purgeStatus                |-> [i \in 1 .. 1 |-> 0],
      numberOfOrdersCancelled    |-> [i \in 1 .. 1 |-> 0],
      aspEligibleOrdersCancelled |-> [i \in 1 .. 1 |-> 0],
      reserved10                 |-> [i \in 1 .. 10 |-> 0] ]

(* Aggressive Side Purge Response at zero, then each field in turn at the values it is checked at *)
CheckedAggressiveSidePurgeResponse ==
    { ZeroAggressiveSidePurgeResponse }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.symboldId = one] : one \in Sample(4) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.purgeStatus = one] : one \in Sample(1) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.numberOfOrdersCancelled = one] : one \in Sample(1) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.aspEligibleOrdersCancelled = one] : one \in Sample(1) }
        \cup { [ZeroAggressiveSidePurgeResponse EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Reserve Order Replenishment Notification: 42 bytes                      *)
(***************************************************************************)

ReserveOrderReplenishmentNotification2 ==
    [ matchingEngineTime : Sample(8),
      symbolId           : Sample(4),
      orderId            : Sample(8),
      secondaryOrderId   : Sample(8),
      displayQty         : Sample(4),
      reserved10         : Sample(10) ]

EncodeReserveOrderReplenishmentNotification2(message) ==
    message.matchingEngineTime
        \o message.symbolId
        \o message.orderId
        \o message.secondaryOrderId
        \o message.displayQty
        \o message.reserved10

DecodeReserveOrderReplenishmentNotification2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(matchingEngineTime.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(orderId.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET displayQty == ReadBytes(secondaryOrderId.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(displayQty.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ matchingEngineTime |-> matchingEngineTime.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         secondaryOrderId   |-> secondaryOrderId.value,
         displayQty         |-> displayQty.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroReserveOrderReplenishmentNotification2 ==
    [ matchingEngineTime |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId   |-> [i \in 1 .. 8 |-> 0],
      displayQty         |-> [i \in 1 .. 4 |-> 0],
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Reserve Order Replenishment Notification at zero, then each field in turn at the values it is checked at *)
CheckedReserveOrderReplenishmentNotification2 ==
    { ZeroReserveOrderReplenishmentNotification2 }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroReserveOrderReplenishmentNotification2 EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Execution Notification: 102 bytes                                       *)
(***************************************************************************)

ExecutionNotification2 ==
    [ matchingEngineTime           : Sample(8),
      mpid                         : Sample(4),
      symbolId                     : Sample(4),
      clientOrderId                : Sample(20),
      tradeId                      : Sample(8),
      executionId                  : Sample(8),
      correctionNumber             : Sample(1),
      tradeStatus                  : Sample(1),
      lastPrice                    : Sample(8),
      lastSize                     : Sample(4),
      orderExecutionInstructions   : Sample(2),
      executingTradingCenter       : Sample(1),
      secondaryOrderId             : Sample(8),
      liquidityIndicator           : Sample(3),
      locateAccount                : Sample(4),
      originalOrderCapacity        : Sample(1),
      additionalLiquidityIndicator : Sample(1),
      executingTradingCenterMpid   : Sample(4),
      reserved12                   : Sample(12) ]

EncodeExecutionNotification2(message) ==
    message.matchingEngineTime
        \o message.mpid
        \o message.symbolId
        \o message.clientOrderId
        \o message.tradeId
        \o message.executionId
        \o message.correctionNumber
        \o message.tradeStatus
        \o message.lastPrice
        \o message.lastSize
        \o message.orderExecutionInstructions
        \o message.executingTradingCenter
        \o message.secondaryOrderId
        \o message.liquidityIndicator
        \o message.locateAccount
        \o message.originalOrderCapacity
        \o message.additionalLiquidityIndicator
        \o message.executingTradingCenterMpid
        \o message.reserved12

DecodeExecutionNotification2(bytes) ==
    LET matchingEngineTime == ReadBytes(bytes, 8) IN IF ~matchingEngineTime.ok THEN Fail ELSE
    LET mpid == ReadBytes(matchingEngineTime.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET symbolId == ReadBytes(mpid.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(symbolId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(clientOrderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET executionId == ReadBytes(tradeId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(executionId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(correctionNumber.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeStatus.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET lastSize == ReadBytes(lastPrice.rest, 4) IN IF ~lastSize.ok THEN Fail ELSE
    LET orderExecutionInstructions == ReadBytes(lastSize.rest, 2) IN IF ~orderExecutionInstructions.ok THEN Fail ELSE
    LET executingTradingCenter == ReadBytes(orderExecutionInstructions.rest, 1) IN IF ~executingTradingCenter.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(executingTradingCenter.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET liquidityIndicator == ReadBytes(secondaryOrderId.rest, 3) IN IF ~liquidityIndicator.ok THEN Fail ELSE
    LET locateAccount == ReadBytes(liquidityIndicator.rest, 4) IN IF ~locateAccount.ok THEN Fail ELSE
    LET originalOrderCapacity == ReadBytes(locateAccount.rest, 1) IN IF ~originalOrderCapacity.ok THEN Fail ELSE
    LET additionalLiquidityIndicator == ReadBytes(originalOrderCapacity.rest, 1) IN IF ~additionalLiquidityIndicator.ok THEN Fail ELSE
    LET executingTradingCenterMpid == ReadBytes(additionalLiquidityIndicator.rest, 4) IN IF ~executingTradingCenterMpid.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(executingTradingCenterMpid.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ matchingEngineTime           |-> matchingEngineTime.value,
         mpid                         |-> mpid.value,
         symbolId                     |-> symbolId.value,
         clientOrderId                |-> clientOrderId.value,
         tradeId                      |-> tradeId.value,
         executionId                  |-> executionId.value,
         correctionNumber             |-> correctionNumber.value,
         tradeStatus                  |-> tradeStatus.value,
         lastPrice                    |-> lastPrice.value,
         lastSize                     |-> lastSize.value,
         orderExecutionInstructions   |-> orderExecutionInstructions.value,
         executingTradingCenter       |-> executingTradingCenter.value,
         secondaryOrderId             |-> secondaryOrderId.value,
         liquidityIndicator           |-> liquidityIndicator.value,
         locateAccount                |-> locateAccount.value,
         originalOrderCapacity        |-> originalOrderCapacity.value,
         additionalLiquidityIndicator |-> additionalLiquidityIndicator.value,
         executingTradingCenterMpid   |-> executingTradingCenterMpid.value,
         reserved12                   |-> reserved12.value ], reserved12.rest)

ZeroExecutionNotification2 ==
    [ matchingEngineTime           |-> [i \in 1 .. 8 |-> 0],
      mpid                         |-> [i \in 1 .. 4 |-> 0],
      symbolId                     |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      tradeId                      |-> [i \in 1 .. 8 |-> 0],
      executionId                  |-> [i \in 1 .. 8 |-> 0],
      correctionNumber             |-> [i \in 1 .. 1 |-> 0],
      tradeStatus                  |-> [i \in 1 .. 1 |-> 0],
      lastPrice                    |-> [i \in 1 .. 8 |-> 0],
      lastSize                     |-> [i \in 1 .. 4 |-> 0],
      orderExecutionInstructions   |-> [i \in 1 .. 2 |-> 0],
      executingTradingCenter       |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId             |-> [i \in 1 .. 8 |-> 0],
      liquidityIndicator           |-> [i \in 1 .. 3 |-> 0],
      locateAccount                |-> [i \in 1 .. 4 |-> 0],
      originalOrderCapacity        |-> [i \in 1 .. 1 |-> 0],
      additionalLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      executingTradingCenterMpid   |-> [i \in 1 .. 4 |-> 0],
      reserved12                   |-> [i \in 1 .. 12 |-> 0] ]

(* Execution Notification at zero, then each field in turn at the values it is checked at *)
CheckedExecutionNotification2 ==
    { ZeroExecutionNotification2 }
        \cup { [ZeroExecutionNotification2 EXCEPT !.matchingEngineTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.tradeStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.lastSize = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.orderExecutionInstructions = one] : one \in Sample(2) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.executingTradingCenter = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.liquidityIndicator = one] : one \in Sample(3) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.locateAccount = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.originalOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.additionalLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.executingTradingCenterMpid = one] : one \in Sample(4) }
        \cup { [ZeroExecutionNotification2 EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

NewOrderRequestMessageCode == 20017  \* "N1"
NewOrderResponseMessageCode2 == 20050  \* "NR"
ModifyOrderRequestMessageCode == 19761  \* "M1"
ModifyOrderResponseCode2 == 19794  \* "MR"
CancelOrderRequestCode == 17231  \* "CO"
CancelOrderResponseCode2 == 17234  \* "CR"
CancelOrderByExchangeOrderIdRequestCode == 17240  \* "CX"
CancelOrderByExchangeOrderIdResponseMessageCode2 == 17233  \* "CQ"
MassCancelRequestCode == 22609  \* "XQ"
MassCancelResponseCode == 22610  \* "XR"
AggressiveSidePurgeRequestCode == 22611  \* "XS"
AggressiveSidePurgeResponseCode == 21330  \* "SR"
ReserveOrderReplenishmentNotificationCode2 == 21057  \* "RA"
ExecutionNotificationCode2 == 17713  \* "E1"

UnsequencedMessage ==
    [ tag : {NewOrderRequestMessageCode}, body : NewOrderRequestMessage ]
        \cup [ tag : {NewOrderResponseMessageCode2}, body : NewOrderResponseMessage2 ]
        \cup [ tag : {ModifyOrderRequestMessageCode}, body : ModifyOrderRequestMessage ]
        \cup [ tag : {ModifyOrderResponseCode2}, body : ModifyOrderResponse2 ]
        \cup [ tag : {CancelOrderRequestCode}, body : CancelOrderRequest ]
        \cup [ tag : {CancelOrderResponseCode2}, body : CancelOrderResponse2 ]
        \cup [ tag : {CancelOrderByExchangeOrderIdRequestCode}, body : CancelOrderByExchangeOrderIdRequest ]
        \cup [ tag : {CancelOrderByExchangeOrderIdResponseMessageCode2}, body : CancelOrderByExchangeOrderIdResponseMessage2 ]
        \cup [ tag : {MassCancelRequestCode}, body : MassCancelRequest ]
        \cup [ tag : {MassCancelResponseCode}, body : MassCancelResponse ]
        \cup [ tag : {AggressiveSidePurgeRequestCode}, body : AggressiveSidePurgeRequest ]
        \cup [ tag : {AggressiveSidePurgeResponseCode}, body : AggressiveSidePurgeResponse ]
        \cup [ tag : {ReserveOrderReplenishmentNotificationCode2}, body : ReserveOrderReplenishmentNotification2 ]
        \cup [ tag : {ExecutionNotificationCode2}, body : ExecutionNotification2 ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = NewOrderRequestMessageCode -> EncodeNewOrderRequestMessage(message.body)
      [] message.tag = NewOrderResponseMessageCode2 -> EncodeNewOrderResponseMessage2(message.body)
      [] message.tag = ModifyOrderRequestMessageCode -> EncodeModifyOrderRequestMessage(message.body)
      [] message.tag = ModifyOrderResponseCode2 -> EncodeModifyOrderResponse2(message.body)
      [] message.tag = CancelOrderRequestCode -> EncodeCancelOrderRequest(message.body)
      [] message.tag = CancelOrderResponseCode2 -> EncodeCancelOrderResponse2(message.body)
      [] message.tag = CancelOrderByExchangeOrderIdRequestCode -> EncodeCancelOrderByExchangeOrderIdRequest(message.body)
      [] message.tag = CancelOrderByExchangeOrderIdResponseMessageCode2 -> EncodeCancelOrderByExchangeOrderIdResponseMessage2(message.body)
      [] message.tag = MassCancelRequestCode -> EncodeMassCancelRequest(message.body)
      [] message.tag = MassCancelResponseCode -> EncodeMassCancelResponse(message.body)
      [] message.tag = AggressiveSidePurgeRequestCode -> EncodeAggressiveSidePurgeRequest(message.body)
      [] message.tag = AggressiveSidePurgeResponseCode -> EncodeAggressiveSidePurgeResponse(message.body)
      [] message.tag = ReserveOrderReplenishmentNotificationCode2 -> EncodeReserveOrderReplenishmentNotification2(message.body)
      [] message.tag = ExecutionNotificationCode2 -> EncodeExecutionNotification2(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderRequestMessageCode -> DecodeNewOrderRequestMessage(bytes)
              [] tag = NewOrderResponseMessageCode2 -> DecodeNewOrderResponseMessage2(bytes)
              [] tag = ModifyOrderRequestMessageCode -> DecodeModifyOrderRequestMessage(bytes)
              [] tag = ModifyOrderResponseCode2 -> DecodeModifyOrderResponse2(bytes)
              [] tag = CancelOrderRequestCode -> DecodeCancelOrderRequest(bytes)
              [] tag = CancelOrderResponseCode2 -> DecodeCancelOrderResponse2(bytes)
              [] tag = CancelOrderByExchangeOrderIdRequestCode -> DecodeCancelOrderByExchangeOrderIdRequest(bytes)
              [] tag = CancelOrderByExchangeOrderIdResponseMessageCode2 -> DecodeCancelOrderByExchangeOrderIdResponseMessage2(bytes)
              [] tag = MassCancelRequestCode -> DecodeMassCancelRequest(bytes)
              [] tag = MassCancelResponseCode -> DecodeMassCancelResponse(bytes)
              [] tag = AggressiveSidePurgeRequestCode -> DecodeAggressiveSidePurgeRequest(bytes)
              [] tag = AggressiveSidePurgeResponseCode -> DecodeAggressiveSidePurgeResponse(bytes)
              [] tag = ReserveOrderReplenishmentNotificationCode2 -> DecodeReserveOrderReplenishmentNotification2(bytes)
              [] tag = ExecutionNotificationCode2 -> DecodeExecutionNotification2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> NewOrderRequestMessageCode, body |-> ZeroNewOrderRequestMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> NewOrderRequestMessageCode, body |-> one] : one \in CheckedNewOrderRequestMessage }
        \cup { [tag |-> NewOrderResponseMessageCode2, body |-> one] : one \in CheckedNewOrderResponseMessage2 }
        \cup { [tag |-> ModifyOrderRequestMessageCode, body |-> one] : one \in CheckedModifyOrderRequestMessage }
        \cup { [tag |-> ModifyOrderResponseCode2, body |-> one] : one \in CheckedModifyOrderResponse2 }
        \cup { [tag |-> CancelOrderRequestCode, body |-> one] : one \in CheckedCancelOrderRequest }
        \cup { [tag |-> CancelOrderResponseCode2, body |-> one] : one \in CheckedCancelOrderResponse2 }
        \cup { [tag |-> CancelOrderByExchangeOrderIdRequestCode, body |-> one] : one \in CheckedCancelOrderByExchangeOrderIdRequest }
        \cup { [tag |-> CancelOrderByExchangeOrderIdResponseMessageCode2, body |-> one] : one \in CheckedCancelOrderByExchangeOrderIdResponseMessage2 }
        \cup { [tag |-> MassCancelRequestCode, body |-> one] : one \in CheckedMassCancelRequest }
        \cup { [tag |-> MassCancelResponseCode, body |-> one] : one \in CheckedMassCancelResponse }
        \cup { [tag |-> AggressiveSidePurgeRequestCode, body |-> one] : one \in CheckedAggressiveSidePurgeRequest }
        \cup { [tag |-> AggressiveSidePurgeResponseCode, body |-> one] : one \in CheckedAggressiveSidePurgeResponse }
        \cup { [tag |-> ReserveOrderReplenishmentNotificationCode2, body |-> one] : one \in CheckedReserveOrderReplenishmentNotification2 }
        \cup { [tag |-> ExecutionNotificationCode2, body |-> one] : one \in CheckedExecutionNotification2 }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 2)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 2) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Requested Matching Engine: 9 bytes                                      *)
(***************************************************************************)

RequestedMatchingEngine ==
    [ requestedTradingSessionId : Sample(1),
      requestedSequenceNumber   : Sample(8) ]

EncodeRequestedMatchingEngine(message) ==
    message.requestedTradingSessionId
        \o message.requestedSequenceNumber

DecodeRequestedMatchingEngine(bytes) ==
    LET requestedTradingSessionId == ReadBytes(bytes, 1) IN IF ~requestedTradingSessionId.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedTradingSessionId.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ requestedTradingSessionId |-> requestedTradingSessionId.value,
         requestedSequenceNumber   |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroRequestedMatchingEngine ==
    [ requestedTradingSessionId |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Requested Matching Engine at zero, then each field in turn at the values it is checked at *)
CheckedRequestedMatchingEngine ==
    { ZeroRequestedMatchingEngine }
        \cup { [ZeroRequestedMatchingEngine EXCEPT !.requestedTradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroRequestedMatchingEngine EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(* A run of Requested Matching Engine, written one after another *)
RECURSIVE EncodeRequestedMatchingEngineList(_)
EncodeRequestedMatchingEngineList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestedMatchingEngine(Head(messages)) \o EncodeRequestedMatchingEngineList(Tail(messages))

(* As many Requested Matching Engine as the field that counts them says *)
RECURSIVE ReadRequestedMatchingEngineList(_, _)
ReadRequestedMatchingEngineList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestedMatchingEngine(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestedMatchingEngineList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Requested Matching Engine of each kind, for the lists that carry them *)
OneRequestedMatchingEngine == { ZeroRequestedMatchingEngine }

(***************************************************************************)
(* Login Request                                                           *)
(***************************************************************************)

LoginRequest ==
    [ esesmVersion            : Sample(5),
      username                : Sample(5),
      computerId              : Sample(8),
      applicationProtocol     : Sample(8),
      requestedMatchingEngine : SampleLists(OneRequestedMatchingEngine) ]

EncodeLoginRequest(message) ==
    message.esesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o EncodeUIntLE(Len(message.requestedMatchingEngine), 1)
        \o EncodeRequestedMatchingEngineList(message.requestedMatchingEngine)

DecodeLoginRequest(bytes) ==
    LET esesmVersion == ReadBytes(bytes, 5) IN IF ~esesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(esesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET numberOfMatchingEngines == ReadUIntLE(applicationProtocol.rest, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    LET requestedMatchingEngine == ReadRequestedMatchingEngineList(numberOfMatchingEngines.rest, numberOfMatchingEngines.value) IN IF ~requestedMatchingEngine.ok THEN Fail ELSE
    Ok([ esesmVersion            |-> esesmVersion.value,
         username                |-> username.value,
         computerId              |-> computerId.value,
         applicationProtocol     |-> applicationProtocol.value,
         requestedMatchingEngine |-> requestedMatchingEngine.value ], requestedMatchingEngine.rest)

ZeroLoginRequest ==
    [ esesmVersion            |-> [i \in 1 .. 5 |-> 0],
      username                |-> [i \in 1 .. 5 |-> 0],
      computerId              |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol     |-> [i \in 1 .. 8 |-> 0],
      requestedMatchingEngine |-> << >> ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.esesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedMatchingEngine = one] : one \in SampleLists(OneRequestedMatchingEngine) }

(***************************************************************************)
(* Matching Engine Status: 10 bytes                                        *)
(***************************************************************************)

MatchingEngineStatus2 ==
    [ loginStatus           : Sample(1),
      tradingSessionId      : Sample(1),
      highestSequenceNumber : Sample(8) ]

EncodeMatchingEngineStatus2(message) ==
    message.loginStatus
        \o message.tradingSessionId
        \o message.highestSequenceNumber

DecodeMatchingEngineStatus2(bytes) ==
    LET loginStatus == ReadBytes(bytes, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(loginStatus.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(tradingSessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ loginStatus           |-> loginStatus.value,
         tradingSessionId      |-> tradingSessionId.value,
         highestSequenceNumber |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroMatchingEngineStatus2 ==
    [ loginStatus           |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId      |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Matching Engine Status at zero, then each field in turn at the values it is checked at *)
CheckedMatchingEngineStatus2 ==
    { ZeroMatchingEngineStatus2 }
        \cup { [ZeroMatchingEngineStatus2 EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroMatchingEngineStatus2 EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroMatchingEngineStatus2 EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(* A run of Matching Engine Status, written one after another *)
RECURSIVE EncodeMatchingEngineStatus2List(_)
EncodeMatchingEngineStatus2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMatchingEngineStatus2(Head(messages)) \o EncodeMatchingEngineStatus2List(Tail(messages))

(* As many Matching Engine Status as the field that counts them says *)
RECURSIVE ReadMatchingEngineStatus2List(_, _)
ReadMatchingEngineStatus2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMatchingEngineStatus2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMatchingEngineStatus2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Matching Engine Status of each kind, for the lists that carry them *)
OneMatchingEngineStatus2 == { ZeroMatchingEngineStatus2 }

(***************************************************************************)
(* Login Response                                                          *)
(***************************************************************************)

LoginResponse ==
    [ matchingEngineStatus : SampleLists(OneMatchingEngineStatus2) ]

EncodeLoginResponse(message) ==
    EncodeUIntLE(Len(message.matchingEngineStatus), 1)
        \o EncodeMatchingEngineStatus2List(message.matchingEngineStatus)

DecodeLoginResponse(bytes) ==
    LET numberOfMatchingEngines == ReadUIntLE(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    LET matchingEngineStatus == ReadMatchingEngineStatus2List(numberOfMatchingEngines.rest, numberOfMatchingEngines.value) IN IF ~matchingEngineStatus.ok THEN Fail ELSE
    Ok([ matchingEngineStatus |-> matchingEngineStatus.value ], matchingEngineStatus.rest)

ZeroLoginResponse ==
    [ matchingEngineStatus |-> << >> ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.matchingEngineStatus = one] : one \in SampleLists(OneMatchingEngineStatus2) }

(***************************************************************************)
(* Synchronization Complete: 1 bytes                                       *)
(***************************************************************************)

SynchronizationComplete ==
    [ numberOfMatchingEngines : Sample(1) ]

EncodeSynchronizationComplete(message) ==
    message.numberOfMatchingEngines

DecodeSynchronizationComplete(bytes) ==
    LET numberOfMatchingEngines == ReadBytes(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    Ok([ numberOfMatchingEngines |-> numberOfMatchingEngines.value ], numberOfMatchingEngines.rest)

ZeroSynchronizationComplete ==
    [ numberOfMatchingEngines |-> [i \in 1 .. 1 |-> 0] ]

(* Synchronization Complete at zero, then each field in turn at the values it is checked at *)
CheckedSynchronizationComplete ==
    { ZeroSynchronizationComplete }
        \cup { [ZeroSynchronizationComplete EXCEPT !.numberOfMatchingEngines = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.logoutReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Test Packet                                                             *)
(***************************************************************************)

TestPacket ==
    [ testText : SampleBytes ]

EncodeTestPacket(message) ==
    message.testText

DecodeTestPacket(bytes) ==
    LET testText == Ok(bytes, << >>) IN IF ~testText.ok THEN Fail ELSE
    Ok([ testText |-> testText.value ], testText.rest)

ZeroTestPacket ==
    [ testText |-> << >> ]

(* Test Packet at zero, then each field in turn at the values it is checked at *)
CheckedTestPacket ==
    { ZeroTestPacket }
        \cup { [ZeroTestPacket EXCEPT !.testText = one] : one \in SampleBytes }

(***************************************************************************)
(* Esesm Payload, selected by Esesm Packet Type                            *)
(***************************************************************************)

SequencedDataPacketCode == 115  \* "s"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 108  \* "l"
LoginResponseCode == 114  \* "r"
SynchronizationCompleteCode == 99  \* "c"
RetransmissionRequestCode == 97  \* "a"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
TradingSessionUpdateCode == 117  \* "u"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"
TestPacketCode == 84  \* "T"

EsesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : SynchronizationComplete ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {TradingSessionUpdateCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestPacketCode}, body : TestPacket ]

EncodeEsesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> EncodeSynchronizationComplete(message.body)
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = TradingSessionUpdateCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = TestPacketCode -> EncodeTestPacket(message.body)

DecodeEsesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> DecodeSynchronizationComplete(bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = TradingSessionUpdateCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = TestPacketCode -> DecodeTestPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEsesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Esesm Payload in turn, at the values the message it names is checked at *)
CheckedEsesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> one] : one \in CheckedSynchronizationComplete }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestPacketCode, body |-> one] : one \in CheckedTestPacket }

(***************************************************************************)
(* Esesm Tcp Packet, framed by Esesm Packet Length                         *)
(***************************************************************************)

EsesmTcpPacket ==
    [ esesmPayload : EsesmPayload ]

EncodeEsesmTcpPacketBody(message) ==
    EncodeUIntBE(message.esesmPayload.tag, 1)
        \o EncodeEsesmPayload(message.esesmPayload)

(* Esesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeEsesmTcpPacket(message) ==
    LET body == EncodeEsesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeEsesmTcpPacketBody(bytes) ==
    LET esesmPacketType == ReadUIntBE(bytes, 1) IN IF ~esesmPacketType.ok THEN Fail ELSE
    LET esesmPayload == DecodeEsesmPayload(esesmPacketType.value, esesmPacketType.rest) IN IF ~esesmPayload.ok THEN Fail ELSE
    Ok([ esesmPayload |-> esesmPayload.value ], esesmPayload.rest)

DecodeEsesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeEsesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroEsesmTcpPacket ==
    [ esesmPayload |-> ZeroEsesmPayload ]

(* Esesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedEsesmTcpPacket ==
    { ZeroEsesmTcpPacket }
        \cup { [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = one] : one \in CheckedEsesmPayload }

(* A run of Esesm Tcp Packet, written one after another *)
RECURSIVE EncodeEsesmTcpPacketList(_)
EncodeEsesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEsesmTcpPacket(Head(messages)) \o EncodeEsesmTcpPacketList(Tail(messages))

(* As many Esesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadEsesmTcpPacketAll(_)
ReadEsesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeEsesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEsesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Esesm Tcp Packet of each kind, for the lists that carry them *)
OneEsesmTcpPacket ==
    { [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> SynchronizationCompleteCode, body |-> ZeroSynchronizationComplete]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroEsesmTcpPacket EXCEPT !.esesmPayload = [tag |-> TestPacketCode, body |-> ZeroTestPacket]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ esesmTcpPacket : SampleLists(OneEsesmTcpPacket) ]

EncodePacket(message) ==
    EncodeEsesmTcpPacketList(message.esesmTcpPacket)

DecodePacket(bytes) ==
    LET esesmTcpPacket == ReadEsesmTcpPacketAll(bytes) IN IF ~esesmTcpPacket.ok THEN Fail ELSE
    Ok([ esesmTcpPacket |-> esesmTcpPacket.value ], esesmTcpPacket.rest)

ZeroPacket ==
    [ esesmTcpPacket |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.esesmTcpPacket = one] : one \in SampleLists(OneEsesmTcpPacket) }

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

(* Every Symbol Update decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolUpdate ==
    \A message \in CheckedSymbolUpdate :
        LET read == DecodeSymbolUpdate(EncodeSymbolUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessage ==
    \A message \in CheckedNewOrderResponseMessage :
        LET read == DecodeNewOrderResponseMessage(EncodeNewOrderResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderResponse ==
    \A message \in CheckedModifyOrderResponse :
        LET read == DecodeModifyOrderResponse(EncodeModifyOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponse ==
    \A message \in CheckedCancelOrderResponse :
        LET read == DecodeCancelOrderResponse(EncodeCancelOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order By Exchange Order Id Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderByExchangeOrderIdResponseMessage ==
    \A message \in CheckedCancelOrderByExchangeOrderIdResponseMessage :
        LET read == DecodeCancelOrderByExchangeOrderIdResponseMessage(EncodeCancelOrderByExchangeOrderIdResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateNotification ==
    \A message \in CheckedSystemStateNotification :
        LET read == DecodeSystemStateNotification(EncodeSystemStateNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderNotification ==
    \A message \in CheckedNewOrderNotification :
        LET read == DecodeNewOrderNotification(EncodeNewOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderNotification ==
    \A message \in CheckedModifyOrderNotification :
        LET read == DecodeModifyOrderNotification(EncodeModifyOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Reduce Size Order Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReduceSizeOrderNotification ==
    \A message \in CheckedCancelReduceSizeOrderNotification :
        LET read == DecodeCancelReduceSizeOrderNotification(EncodeCancelReduceSizeOrderNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Price Update Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriceUpdateNotification ==
    \A message \in CheckedOrderPriceUpdateNotification :
        LET read == DecodeOrderPriceUpdateNotification(EncodeOrderPriceUpdateNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reserve Order Replenishment Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripReserveOrderReplenishmentNotification ==
    \A message \in CheckedReserveOrderReplenishmentNotification :
        LET read == DecodeReserveOrderReplenishmentNotification(EncodeReserveOrderReplenishmentNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNotification ==
    \A message \in CheckedExecutionNotification :
        LET read == DecodeExecutionNotification(EncodeExecutionNotification(message))
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

(* Every New Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderRequestMessage ==
    \A message \in CheckedNewOrderRequestMessage :
        LET read == DecodeNewOrderRequestMessage(EncodeNewOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponseMessage2 ==
    \A message \in CheckedNewOrderResponseMessage2 :
        LET read == DecodeNewOrderResponseMessage2(EncodeNewOrderResponseMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderRequestMessage ==
    \A message \in CheckedModifyOrderRequestMessage :
        LET read == DecodeModifyOrderRequestMessage(EncodeModifyOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderResponse2 ==
    \A message \in CheckedModifyOrderResponse2 :
        LET read == DecodeModifyOrderResponse2(EncodeModifyOrderResponse2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRequest ==
    \A message \in CheckedCancelOrderRequest :
        LET read == DecodeCancelOrderRequest(EncodeCancelOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderResponse2 ==
    \A message \in CheckedCancelOrderResponse2 :
        LET read == DecodeCancelOrderResponse2(EncodeCancelOrderResponse2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order By Exchange Order Id Request decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderByExchangeOrderIdRequest ==
    \A message \in CheckedCancelOrderByExchangeOrderIdRequest :
        LET read == DecodeCancelOrderByExchangeOrderIdRequest(EncodeCancelOrderByExchangeOrderIdRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order By Exchange Order Id Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderByExchangeOrderIdResponseMessage2 ==
    \A message \in CheckedCancelOrderByExchangeOrderIdResponseMessage2 :
        LET read == DecodeCancelOrderByExchangeOrderIdResponseMessage2(EncodeCancelOrderByExchangeOrderIdResponseMessage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequest ==
    \A message \in CheckedMassCancelRequest :
        LET read == DecodeMassCancelRequest(EncodeMassCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Matching Engine Status decodes back to what was encoded, and leaves nothing over *)
RoundTripMatchingEngineStatus ==
    \A message \in CheckedMatchingEngineStatus :
        LET read == DecodeMatchingEngineStatus(EncodeMatchingEngineStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponse ==
    \A message \in CheckedMassCancelResponse :
        LET read == DecodeMassCancelResponse(EncodeMassCancelResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aggressive Side Purge Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAggressiveSidePurgeRequest ==
    \A message \in CheckedAggressiveSidePurgeRequest :
        LET read == DecodeAggressiveSidePurgeRequest(EncodeAggressiveSidePurgeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aggressive Side Purge Response decodes back to what was encoded, and leaves nothing over *)
RoundTripAggressiveSidePurgeResponse ==
    \A message \in CheckedAggressiveSidePurgeResponse :
        LET read == DecodeAggressiveSidePurgeResponse(EncodeAggressiveSidePurgeResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reserve Order Replenishment Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripReserveOrderReplenishmentNotification2 ==
    \A message \in CheckedReserveOrderReplenishmentNotification2 :
        LET read == DecodeReserveOrderReplenishmentNotification2(EncodeReserveOrderReplenishmentNotification2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionNotification2 ==
    \A message \in CheckedExecutionNotification2 :
        LET read == DecodeExecutionNotification2(EncodeExecutionNotification2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Requested Matching Engine decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestedMatchingEngine ==
    \A message \in CheckedRequestedMatchingEngine :
        LET read == DecodeRequestedMatchingEngine(EncodeRequestedMatchingEngine(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Matching Engine Status decodes back to what was encoded, and leaves nothing over *)
RoundTripMatchingEngineStatus2 ==
    \A message \in CheckedMatchingEngineStatus2 :
        LET read == DecodeMatchingEngineStatus2(EncodeMatchingEngineStatus2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Synchronization Complete decodes back to what was encoded, and leaves nothing over *)
RoundTripSynchronizationComplete ==
    \A message \in CheckedSynchronizationComplete :
        LET read == DecodeSynchronizationComplete(EncodeSynchronizationComplete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTestPacket ==
    \A message \in CheckedTestPacket :
        LET read == DecodeTestPacket(EncodeTestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Esesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripEsesmTcpPacket ==
    \A message \in CheckedEsesmTcpPacket :
        LET read == DecodeEsesmTcpPacket(EncodeEsesmTcpPacket(message))
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

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Esesm Payload is selected by the Esesm Packet Type it is written under *)
SelectsEsesmPayload ==
    \A message \in CheckedEsesmPayload :
        LET read == DecodeEsesmPayload(message.tag, EncodeEsesmPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Esesm Packet Length is written from the bytes it frames *)
FramesEsesmTcpPacket ==
    \A message \in CheckedEsesmTcpPacket :
        LET bytes == EncodeEsesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
