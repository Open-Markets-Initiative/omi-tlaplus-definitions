---------------- MODULE PearlEquities_DepthOfMarket_v1_3_a -----------------
(***************************************************************************)
(* Miami International Holdings Depth Of Market v1.3.a                     *)
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
(* Note: Modify Order Flags is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Order Execution Flags is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Application Message fills what is left of the frame Mach Packet   *)
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
(* System Time Message: 4 bytes                                            *)
(***************************************************************************)

SystemTimeMessage ==
    [ seconds : Sample(4) ]

EncodeSystemTimeMessage(message) ==
    message.seconds

DecodeSystemTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSystemTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* System Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimeMessage ==
    { ZeroSystemTimeMessage }
        \cup { [ZeroSystemTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Update Message: 41 bytes                                         *)
(***************************************************************************)

SymbolUpdateMessage ==
    [ nanoseconds           : Sample(4),
      symbolId              : Sample(4),
      tickerSymbol          : Sample(11),
      reserved1             : Sample(1),
      testSecurityIndicator : Sample(1),
      spare                 : Sample(1),
      lotSize               : Sample(2),
      openingTime           : Sample(8),
      closingTime           : Sample(8),
      primaryMarketCode     : Sample(1) ]

EncodeSymbolUpdateMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tickerSymbol
        \o message.reserved1
        \o message.testSecurityIndicator
        \o message.spare
        \o message.lotSize
        \o message.openingTime
        \o message.closingTime
        \o message.primaryMarketCode

DecodeSymbolUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tickerSymbol == ReadBytes(symbolId.rest, 11) IN IF ~tickerSymbol.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tickerSymbol.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET testSecurityIndicator == ReadBytes(reserved1.rest, 1) IN IF ~testSecurityIndicator.ok THEN Fail ELSE
    LET spare == ReadBytes(testSecurityIndicator.rest, 1) IN IF ~spare.ok THEN Fail ELSE
    LET lotSize == ReadBytes(spare.rest, 2) IN IF ~lotSize.ok THEN Fail ELSE
    LET openingTime == ReadBytes(lotSize.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET closingTime == ReadBytes(openingTime.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET primaryMarketCode == ReadBytes(closingTime.rest, 1) IN IF ~primaryMarketCode.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         symbolId              |-> symbolId.value,
         tickerSymbol          |-> tickerSymbol.value,
         reserved1             |-> reserved1.value,
         testSecurityIndicator |-> testSecurityIndicator.value,
         spare                 |-> spare.value,
         lotSize               |-> lotSize.value,
         openingTime           |-> openingTime.value,
         closingTime           |-> closingTime.value,
         primaryMarketCode     |-> primaryMarketCode.value ], primaryMarketCode.rest)

ZeroSymbolUpdateMessage ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      symbolId              |-> [i \in 1 .. 4 |-> 0],
      tickerSymbol          |-> [i \in 1 .. 11 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      testSecurityIndicator |-> [i \in 1 .. 1 |-> 0],
      spare                 |-> [i \in 1 .. 1 |-> 0],
      lotSize               |-> [i \in 1 .. 2 |-> 0],
      openingTime           |-> [i \in 1 .. 8 |-> 0],
      closingTime           |-> [i \in 1 .. 8 |-> 0],
      primaryMarketCode     |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolUpdateMessage ==
    { ZeroSymbolUpdateMessage }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.tickerSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.testSecurityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.spare = one] : one \in Sample(1) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.lotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSymbolUpdateMessage EXCEPT !.primaryMarketCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System State Message: 14 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      doMVersion   : Sample(8),
      sessionId    : Sample(1),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.doMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET doMVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~doMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(doMVersion.rest, 1) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         doMVersion   |-> doMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      doMVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 1 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.doMVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(1) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Trading Status Notification Message: 11 bytes                  *)
(***************************************************************************)

SecurityTradingStatusNotificationMessage ==
    [ nanoseconds          : Sample(4),
      symbolId             : Sample(4),
      tradingStatus        : Sample(1),
      marketState          : Sample(1),
      shortSaleRestriction : Sample(1) ]

EncodeSecurityTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradingStatus
        \o message.marketState
        \o message.shortSaleRestriction

DecodeSecurityTradingStatusNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(symbolId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketState == ReadBytes(tradingStatus.rest, 1) IN IF ~marketState.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(marketState.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         symbolId             |-> symbolId.value,
         tradingStatus        |-> tradingStatus.value,
         marketState          |-> marketState.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroSecurityTradingStatusNotificationMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      symbolId             |-> [i \in 1 .. 4 |-> 0],
      tradingStatus        |-> [i \in 1 .. 1 |-> 0],
      marketState          |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingStatusNotificationMessage ==
    { ZeroSecurityTradingStatusNotificationMessage }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.marketState = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusNotificationMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Clear Message: 8 bytes                                           *)
(***************************************************************************)

SymbolClearMessage ==
    [ nanoseconds : Sample(4),
      symbolId    : Sample(4) ]

EncodeSymbolClearMessage(message) ==
    message.nanoseconds
        \o message.symbolId

DecodeSymbolClearMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         symbolId    |-> symbolId.value ], symbolId.rest)

ZeroSymbolClearMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      symbolId    |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolClearMessage ==
    { ZeroSymbolClearMessage }
        \cup { [ZeroSymbolClearMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSymbolClearMessage EXCEPT !.symbolId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Message: 33 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ nanoseconds    : Sample(4),
      symbolId       : Sample(4),
      orderId        : Sample(8),
      orderSide      : Sample(1),
      price          : Sample(8),
      size           : Sample(4),
      attributableId : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.orderId
        \o message.orderSide
        \o message.price
        \o message.size
        \o message.attributableId

DecodeAddOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(orderId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET price == ReadBytes(orderSide.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET attributableId == ReadBytes(size.rest, 4) IN IF ~attributableId.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         symbolId       |-> symbolId.value,
         orderId        |-> orderId.value,
         orderSide      |-> orderSide.value,
         price          |-> price.value,
         size           |-> size.value,
         attributableId |-> attributableId.value ], attributableId.rest)

ZeroAddOrderMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      symbolId       |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderSide      |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      size           |-> [i \in 1 .. 4 |-> 0],
      attributableId |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.attributableId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Message: 29 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ nanoseconds      : Sample(4),
      symbolId         : Sample(4),
      orderId          : Sample(8),
      price            : Sample(8),
      size             : Sample(4),
      modifyOrderFlags : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.orderId
        \o message.price
        \o message.size
        \o message.modifyOrderFlags

DecodeModifyOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET modifyOrderFlags == ReadBytes(size.rest, 1) IN IF ~modifyOrderFlags.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         symbolId         |-> symbolId.value,
         orderId          |-> orderId.value,
         price            |-> price.value,
         size             |-> size.value,
         modifyOrderFlags |-> modifyOrderFlags.value ], modifyOrderFlags.rest)

ZeroModifyOrderMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      symbolId         |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      modifyOrderFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.modifyOrderFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 16 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ nanoseconds : Sample(4),
      symbolId    : Sample(4),
      orderId     : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         symbolId    |-> symbolId.value,
         orderId     |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      symbolId    |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Execution Message: 37 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ nanoseconds         : Sample(4),
      symbolId            : Sample(4),
      orderId             : Sample(8),
      tradeId             : Sample(8),
      price               : Sample(8),
      size                : Sample(4),
      orderExecutionFlags : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.orderId
        \o message.tradeId
        \o message.price
        \o message.size
        \o message.orderExecutionFlags

DecodeOrderExecutionMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET orderExecutionFlags == ReadBytes(size.rest, 1) IN IF ~orderExecutionFlags.ok THEN Fail ELSE
    Ok([ nanoseconds         |-> nanoseconds.value,
         symbolId            |-> symbolId.value,
         orderId             |-> orderId.value,
         tradeId             |-> tradeId.value,
         price               |-> price.value,
         size                |-> size.value,
         orderExecutionFlags |-> orderExecutionFlags.value ], orderExecutionFlags.rest)

ZeroOrderExecutionMessage ==
    [ nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      symbolId            |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 8 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      size                |-> [i \in 1 .. 4 |-> 0],
      orderExecutionFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.orderExecutionFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 30 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanoseconds      : Sample(4),
      symbolId         : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4),
      tradeFlags       : Sample(1) ]

EncodeTradeMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size
        \o message.tradeFlags

DecodeTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(size.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         symbolId         |-> symbolId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value,
         tradeFlags       |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      symbolId         |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      tradeFlags       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 29 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ nanoseconds      : Sample(4),
      symbolId         : Sample(4),
      tradeId          : Sample(8),
      correctionNumber : Sample(1),
      price            : Sample(8),
      size             : Sample(4) ]

EncodeTradeCancelMessage(message) ==
    message.nanoseconds
        \o message.symbolId
        \o message.tradeId
        \o message.correctionNumber
        \o message.price
        \o message.size

DecodeTradeCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET symbolId == ReadBytes(nanoseconds.rest, 4) IN IF ~symbolId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbolId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET price == ReadBytes(correctionNumber.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         symbolId         |-> symbolId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         price            |-> price.value,
         size             |-> size.value ], size.rest)

ZeroTradeCancelMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      symbolId         |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.symbolId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.size = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* 0x31
SymbolUpdateMessageCode == 1  \* 0x01
SystemStateMessageCode == 83  \* 0x53
SecurityTradingStatusNotificationMessageCode == 4  \* 0x04
SymbolClearMessageCode == 5  \* 0x05
AddOrderMessageCode == 20  \* 0x14
ModifyOrderMessageCode == 21  \* 0x15
DeleteOrderMessageCode == 23  \* 0x17
OrderExecutionMessageCode == 24  \* 0x18
TradeMessageCode == 10  \* 0x0a
TradeCancelMessageCode == 11  \* 0x0b

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SymbolUpdateMessageCode}, body : SymbolUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SecurityTradingStatusNotificationMessageCode}, body : SecurityTradingStatusNotificationMessage ]
        \cup [ tag : {SymbolClearMessageCode}, body : SymbolClearMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SymbolUpdateMessageCode -> EncodeSymbolUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SecurityTradingStatusNotificationMessageCode -> EncodeSecurityTradingStatusNotificationMessage(message.body)
      [] message.tag = SymbolClearMessageCode -> EncodeSymbolClearMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SymbolUpdateMessageCode -> DecodeSymbolUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SecurityTradingStatusNotificationMessageCode -> DecodeSecurityTradingStatusNotificationMessage(bytes)
              [] tag = SymbolClearMessageCode -> DecodeSymbolClearMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SymbolUpdateMessageCode, body |-> one] : one \in CheckedSymbolUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> SecurityTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedSecurityTradingStatusNotificationMessage }
        \cup { [tag |-> SymbolClearMessageCode, body |-> one] : one \in CheckedSymbolClearMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Payload, selected by Mach Packet Type                                   *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02
ApplicationMessageCode == 3  \* 0x03

Payload ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* Mach Message, framed by Mach Packet Length                              *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Mach Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET machPacketType == ReadUIntLE(framed, 1) IN IF ~machPacketType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(machPacketType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(machPacketType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodePacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodePacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroPacket ==
    [ machMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every System Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimeMessage ==
    \A message \in CheckedSystemTimeMessage :
        LET read == DecodeSystemTimeMessage(EncodeSystemTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolUpdateMessage ==
    \A message \in CheckedSymbolUpdateMessage :
        LET read == DecodeSymbolUpdateMessage(EncodeSymbolUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingStatusNotificationMessage ==
    \A message \in CheckedSecurityTradingStatusNotificationMessage :
        LET read == DecodeSecurityTradingStatusNotificationMessage(EncodeSecurityTradingStatusNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolClearMessage ==
    \A message \in CheckedSymbolClearMessage :
        LET read == DecodeSymbolClearMessage(EncodeSymbolClearMessage(message))
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

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
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

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
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

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Mach Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Mach Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
