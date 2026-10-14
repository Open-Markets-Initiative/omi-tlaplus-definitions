------------- MODULE DxeDerivatives_MulticastDepthOfBook_v1_11 -------------
(***************************************************************************)
(* Chicago Board Options Exchange Europe Derivatives Multicast Depth Of    *)
(* Book v1.11                                                              *)
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
(* Note: Summary Flags is a bit field set, checked as its 1 byte rather    *)
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
(* Time Message: 4 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroTimeMessage ==
    [ time |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }

(***************************************************************************)
(* Unit Clear Message: 4 bytes                                             *)
(***************************************************************************)

UnitClearMessage ==
    [ timeOffset : Sample(4) ]

EncodeUnitClearMessage(message) ==
    message.timeOffset

DecodeUnitClearMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroUnitClearMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Unit Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedUnitClearMessage ==
    { ZeroUnitClearMessage }
        \cup { [ZeroUnitClearMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Long Message: 33 bytes                                        *)
(***************************************************************************)

AddOrderLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantity      : Sample(4),
      symbolLong    : Sample(8),
      price         : Sample(8) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantity
        \o message.symbolLong
        \o message.price

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(sideIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(quantity.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantity      |-> quantity.value,
         symbolLong    |-> symbolLong.value,
         price         |-> price.value ], price.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      symbolLong    |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Short Message: 23 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityShort : Sample(2),
      symbolShort   : Sample(6),
      priceShort    : Sample(2) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolShort
        \o message.priceShort

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityShort.rest, 6) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityShort |-> quantityShort.value,
         symbolShort   |-> symbolShort.value,
         priceShort    |-> priceShort.value ], priceShort.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      symbolShort   |-> [i \in 1 .. 6 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.symbolShort = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Flags: 4 bytes                                                *)
(***************************************************************************)

ExecutionFlags ==
    [ marketMechanism  : Sample(1),
      tradingMode      : Sample(1),
      exCumDividend    : Sample(1),
      algorithmicTrade : Sample(1) ]

EncodeExecutionFlags(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.exCumDividend
        \o message.algorithmicTrade

DecodeExecutionFlags(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(tradingMode.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    LET algorithmicTrade == ReadBytes(exCumDividend.rest, 1) IN IF ~algorithmicTrade.ok THEN Fail ELSE
    Ok([ marketMechanism  |-> marketMechanism.value,
         tradingMode      |-> tradingMode.value,
         exCumDividend    |-> exCumDividend.value,
         algorithmicTrade |-> algorithmicTrade.value ], algorithmicTrade.rest)

ZeroExecutionFlags ==
    [ marketMechanism  |-> [i \in 1 .. 1 |-> 0],
      tradingMode      |-> [i \in 1 .. 1 |-> 0],
      exCumDividend    |-> [i \in 1 .. 1 |-> 0],
      algorithmicTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Flags at zero, then each field in turn at the values it is checked at *)
CheckedExecutionFlags ==
    { ZeroExecutionFlags }
        \cup { [ZeroExecutionFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags EXCEPT !.exCumDividend = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags EXCEPT !.algorithmicTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 28 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      executedQuantity : Sample(4),
      executionId      : Sample(8),
      executionFlags   : ExecutionFlags ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.executionId
        \o EncodeExecutionFlags(message.executionFlags)

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET executionFlags == DecodeExecutionFlags(executionId.rest) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         executedQuantity |-> executedQuantity.value,
         executionId      |-> executionId.value,
         executionFlags   |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      executedQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      executionFlags   |-> ZeroExecutionFlags ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionFlags = one] : one \in CheckedExecutionFlags }

(***************************************************************************)
(* Execution Flags: 4 bytes                                                *)
(***************************************************************************)

ExecutionFlags2 ==
    [ marketMechanism  : Sample(1),
      tradingMode      : Sample(1),
      exCumDividend    : Sample(1),
      algorithmicTrade : Sample(1) ]

EncodeExecutionFlags2(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.exCumDividend
        \o message.algorithmicTrade

DecodeExecutionFlags2(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(tradingMode.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    LET algorithmicTrade == ReadBytes(exCumDividend.rest, 1) IN IF ~algorithmicTrade.ok THEN Fail ELSE
    Ok([ marketMechanism  |-> marketMechanism.value,
         tradingMode      |-> tradingMode.value,
         exCumDividend    |-> exCumDividend.value,
         algorithmicTrade |-> algorithmicTrade.value ], algorithmicTrade.rest)

ZeroExecutionFlags2 ==
    [ marketMechanism  |-> [i \in 1 .. 1 |-> 0],
      tradingMode      |-> [i \in 1 .. 1 |-> 0],
      exCumDividend    |-> [i \in 1 .. 1 |-> 0],
      algorithmicTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Flags at zero, then each field in turn at the values it is checked at *)
CheckedExecutionFlags2 ==
    { ZeroExecutionFlags2 }
        \cup { [ZeroExecutionFlags2 EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags2 EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags2 EXCEPT !.exCumDividend = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags2 EXCEPT !.algorithmicTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed At Price Size Message: 40 bytes                          *)
(***************************************************************************)

OrderExecutedAtPriceSizeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      executedQuantity  : Sample(4),
      remainingQuantity : Sample(4),
      executionId       : Sample(8),
      price             : Sample(8),
      executionFlags    : ExecutionFlags2 ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedQuantity
        \o message.remainingQuantity
        \o message.executionId
        \o message.price
        \o EncodeExecutionFlags2(message.executionFlags)

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(orderId.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET remainingQuantity == ReadBytes(executedQuantity.rest, 4) IN IF ~remainingQuantity.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingQuantity.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionFlags == DecodeExecutionFlags2(price.rest) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         executedQuantity  |-> executedQuantity.value,
         remainingQuantity |-> remainingQuantity.value,
         executionId       |-> executionId.value,
         price             |-> price.value,
         executionFlags    |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      executedQuantity  |-> [i \in 1 .. 4 |-> 0],
      remainingQuantity |-> [i \in 1 .. 4 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      executionFlags    |-> ZeroExecutionFlags2 ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionFlags = one] : one \in CheckedExecutionFlags2 }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset            : Sample(4),
      orderId               : Sample(8),
      canceledContractsLong : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledContractsLong

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledContractsLong == ReadBytes(orderId.rest, 4) IN IF ~canceledContractsLong.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         orderId               |-> orderId.value,
         canceledContractsLong |-> canceledContractsLong.value ], canceledContractsLong.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      canceledContractsLong |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.canceledContractsLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Reduce Size Short Message: 14 bytes                                     *)
(***************************************************************************)

ReduceSizeShortMessage ==
    [ timeOffset             : Sample(4),
      orderId                : Sample(8),
      canceledContractsShort : Sample(2) ]

EncodeReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.canceledContractsShort

DecodeReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET canceledContractsShort == ReadBytes(orderId.rest, 2) IN IF ~canceledContractsShort.ok THEN Fail ELSE
    Ok([ timeOffset             |-> timeOffset.value,
         orderId                |-> orderId.value,
         canceledContractsShort |-> canceledContractsShort.value ], canceledContractsShort.rest)

ZeroReduceSizeShortMessage ==
    [ timeOffset             |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      canceledContractsShort |-> [i \in 1 .. 2 |-> 0] ]

(* Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeShortMessage ==
    { ZeroReduceSizeShortMessage }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.canceledContractsShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Long Message: 22 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      contractsShort : Sample(2),
      price          : Sample(8) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.contractsShort
        \o message.price

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(orderId.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET price == ReadBytes(contractsShort.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         contractsShort |-> contractsShort.value,
         price          |-> price.value ], price.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      contractsShort |-> [i \in 1 .. 2 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Short Message: 16 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      contractsShort : Sample(2),
      priceShort     : Sample(2) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.contractsShort
        \o message.priceShort

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(orderId.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(contractsShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         contractsShort |-> contractsShort.value,
         priceShort     |-> priceShort.value ], priceShort.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      contractsShort |-> [i \in 1 .. 2 |-> 0],
      priceShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Delete Order Message: 12 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.timeOffset
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Flags: 5 bytes                                                    *)
(***************************************************************************)

TradeFlags ==
    [ marketMechanism                  : Sample(1),
      tradingMode                      : Sample(1),
      transactionCategory              : Sample(1),
      benchmarkReferencePriceIndicator : Sample(1),
      algorithmicTrade                 : Sample(1) ]

EncodeTradeFlags(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.benchmarkReferencePriceIndicator
        \o message.algorithmicTrade

DecodeTradeFlags(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET benchmarkReferencePriceIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~benchmarkReferencePriceIndicator.ok THEN Fail ELSE
    LET algorithmicTrade == ReadBytes(benchmarkReferencePriceIndicator.rest, 1) IN IF ~algorithmicTrade.ok THEN Fail ELSE
    Ok([ marketMechanism                  |-> marketMechanism.value,
         tradingMode                      |-> tradingMode.value,
         transactionCategory              |-> transactionCategory.value,
         benchmarkReferencePriceIndicator |-> benchmarkReferencePriceIndicator.value,
         algorithmicTrade                 |-> algorithmicTrade.value ], algorithmicTrade.rest)

ZeroTradeFlags ==
    [ marketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      tradingMode                      |-> [i \in 1 .. 1 |-> 0],
      transactionCategory              |-> [i \in 1 .. 1 |-> 0],
      benchmarkReferencePriceIndicator |-> [i \in 1 .. 1 |-> 0],
      algorithmicTrade                 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedTradeFlags ==
    { ZeroTradeFlags }
        \cup { [ZeroTradeFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.benchmarkReferencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.algorithmicTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Long Message: 44 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      contractsShort : Sample(2),
      symbolLong     : Sample(8),
      price          : Sample(8),
      executionId    : Sample(8),
      tradeFlags     : TradeFlags ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.contractsShort
        \o message.symbolLong
        \o message.price
        \o message.executionId
        \o EncodeTradeFlags(message.tradeFlags)

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(sideIndicator.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(contractsShort.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executionId == ReadBytes(price.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == DecodeTradeFlags(executionId.rest) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         contractsShort |-> contractsShort.value,
         symbolLong     |-> symbolLong.value,
         price          |-> price.value,
         executionId    |-> executionId.value,
         tradeFlags     |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeLongMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      contractsShort |-> [i \in 1 .. 2 |-> 0],
      symbolLong     |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeFlags     |-> ZeroTradeFlags ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeLongMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeFlags = one] : one \in CheckedTradeFlags }

(***************************************************************************)
(* Trade Flags: 5 bytes                                                    *)
(***************************************************************************)

TradeFlags2 ==
    [ marketMechanism                  : Sample(1),
      tradingMode                      : Sample(1),
      transactionCategory              : Sample(1),
      benchmarkReferencePriceIndicator : Sample(1),
      algorithmicTrade                 : Sample(1) ]

EncodeTradeFlags2(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.benchmarkReferencePriceIndicator
        \o message.algorithmicTrade

DecodeTradeFlags2(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET benchmarkReferencePriceIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~benchmarkReferencePriceIndicator.ok THEN Fail ELSE
    LET algorithmicTrade == ReadBytes(benchmarkReferencePriceIndicator.rest, 1) IN IF ~algorithmicTrade.ok THEN Fail ELSE
    Ok([ marketMechanism                  |-> marketMechanism.value,
         tradingMode                      |-> tradingMode.value,
         transactionCategory              |-> transactionCategory.value,
         benchmarkReferencePriceIndicator |-> benchmarkReferencePriceIndicator.value,
         algorithmicTrade                 |-> algorithmicTrade.value ], algorithmicTrade.rest)

ZeroTradeFlags2 ==
    [ marketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      tradingMode                      |-> [i \in 1 .. 1 |-> 0],
      transactionCategory              |-> [i \in 1 .. 1 |-> 0],
      benchmarkReferencePriceIndicator |-> [i \in 1 .. 1 |-> 0],
      algorithmicTrade                 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedTradeFlags2 ==
    { ZeroTradeFlags2 }
        \cup { [ZeroTradeFlags2 EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.benchmarkReferencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.algorithmicTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 36 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      sideIndicator  : Sample(1),
      contractsShort : Sample(2),
      symbol         : Sample(6),
      priceShort     : Sample(2),
      executionId    : Sample(8),
      tradeFlags     : TradeFlags2 ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.contractsShort
        \o message.symbol
        \o message.priceShort
        \o message.executionId
        \o EncodeTradeFlags2(message.tradeFlags)

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(sideIndicator.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET symbol == ReadBytes(contractsShort.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbol.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == DecodeTradeFlags2(executionId.rest) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         sideIndicator  |-> sideIndicator.value,
         contractsShort |-> contractsShort.value,
         symbol         |-> symbol.value,
         priceShort     |-> priceShort.value,
         executionId    |-> executionId.value,
         tradeFlags     |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeShortMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      sideIndicator  |-> [i \in 1 .. 1 |-> 0],
      contractsShort |-> [i \in 1 .. 2 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      priceShort     |-> [i \in 1 .. 2 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      tradeFlags     |-> ZeroTradeFlags2 ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeFlags = one] : one \in CheckedTradeFlags2 }

(***************************************************************************)
(* Extended Trade Flags: 14 bytes                                          *)
(***************************************************************************)

ExtendedTradeFlags ==
    [ marketMechanism                  : Sample(1),
      tradingMode                      : Sample(1),
      transactionCategory              : Sample(1),
      negotiatedTrade                  : Sample(1),
      crossingTrade                    : Sample(1),
      modificationIndicator            : Sample(1),
      benchmarkReferencePriceIndicator : Sample(1),
      specialDividend                  : Sample(1),
      offBookAutomatedIndicator        : Sample(1),
      priceFormationDiscoveryProcess   : Sample(1),
      algorithmicIndicator             : Sample(1),
      publicationModeDeferralReason    : Sample(1),
      deferralOrEnrichmentType         : Sample(1),
      duplicativeIndicator             : Sample(1) ]

EncodeExtendedTradeFlags(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.negotiatedTrade
        \o message.crossingTrade
        \o message.modificationIndicator
        \o message.benchmarkReferencePriceIndicator
        \o message.specialDividend
        \o message.offBookAutomatedIndicator
        \o message.priceFormationDiscoveryProcess
        \o message.algorithmicIndicator
        \o message.publicationModeDeferralReason
        \o message.deferralOrEnrichmentType
        \o message.duplicativeIndicator

DecodeExtendedTradeFlags(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET negotiatedTrade == ReadBytes(transactionCategory.rest, 1) IN IF ~negotiatedTrade.ok THEN Fail ELSE
    LET crossingTrade == ReadBytes(negotiatedTrade.rest, 1) IN IF ~crossingTrade.ok THEN Fail ELSE
    LET modificationIndicator == ReadBytes(crossingTrade.rest, 1) IN IF ~modificationIndicator.ok THEN Fail ELSE
    LET benchmarkReferencePriceIndicator == ReadBytes(modificationIndicator.rest, 1) IN IF ~benchmarkReferencePriceIndicator.ok THEN Fail ELSE
    LET specialDividend == ReadBytes(benchmarkReferencePriceIndicator.rest, 1) IN IF ~specialDividend.ok THEN Fail ELSE
    LET offBookAutomatedIndicator == ReadBytes(specialDividend.rest, 1) IN IF ~offBookAutomatedIndicator.ok THEN Fail ELSE
    LET priceFormationDiscoveryProcess == ReadBytes(offBookAutomatedIndicator.rest, 1) IN IF ~priceFormationDiscoveryProcess.ok THEN Fail ELSE
    LET algorithmicIndicator == ReadBytes(priceFormationDiscoveryProcess.rest, 1) IN IF ~algorithmicIndicator.ok THEN Fail ELSE
    LET publicationModeDeferralReason == ReadBytes(algorithmicIndicator.rest, 1) IN IF ~publicationModeDeferralReason.ok THEN Fail ELSE
    LET deferralOrEnrichmentType == ReadBytes(publicationModeDeferralReason.rest, 1) IN IF ~deferralOrEnrichmentType.ok THEN Fail ELSE
    LET duplicativeIndicator == ReadBytes(deferralOrEnrichmentType.rest, 1) IN IF ~duplicativeIndicator.ok THEN Fail ELSE
    Ok([ marketMechanism                  |-> marketMechanism.value,
         tradingMode                      |-> tradingMode.value,
         transactionCategory              |-> transactionCategory.value,
         negotiatedTrade                  |-> negotiatedTrade.value,
         crossingTrade                    |-> crossingTrade.value,
         modificationIndicator            |-> modificationIndicator.value,
         benchmarkReferencePriceIndicator |-> benchmarkReferencePriceIndicator.value,
         specialDividend                  |-> specialDividend.value,
         offBookAutomatedIndicator        |-> offBookAutomatedIndicator.value,
         priceFormationDiscoveryProcess   |-> priceFormationDiscoveryProcess.value,
         algorithmicIndicator             |-> algorithmicIndicator.value,
         publicationModeDeferralReason    |-> publicationModeDeferralReason.value,
         deferralOrEnrichmentType         |-> deferralOrEnrichmentType.value,
         duplicativeIndicator             |-> duplicativeIndicator.value ], duplicativeIndicator.rest)

ZeroExtendedTradeFlags ==
    [ marketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      tradingMode                      |-> [i \in 1 .. 1 |-> 0],
      transactionCategory              |-> [i \in 1 .. 1 |-> 0],
      negotiatedTrade                  |-> [i \in 1 .. 1 |-> 0],
      crossingTrade                    |-> [i \in 1 .. 1 |-> 0],
      modificationIndicator            |-> [i \in 1 .. 1 |-> 0],
      benchmarkReferencePriceIndicator |-> [i \in 1 .. 1 |-> 0],
      specialDividend                  |-> [i \in 1 .. 1 |-> 0],
      offBookAutomatedIndicator        |-> [i \in 1 .. 1 |-> 0],
      priceFormationDiscoveryProcess   |-> [i \in 1 .. 1 |-> 0],
      algorithmicIndicator             |-> [i \in 1 .. 1 |-> 0],
      publicationModeDeferralReason    |-> [i \in 1 .. 1 |-> 0],
      deferralOrEnrichmentType         |-> [i \in 1 .. 1 |-> 0],
      duplicativeIndicator             |-> [i \in 1 .. 1 |-> 0] ]

(* Extended Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedExtendedTradeFlags ==
    { ZeroExtendedTradeFlags }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.negotiatedTrade = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.crossingTrade = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.modificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.benchmarkReferencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.specialDividend = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.offBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.priceFormationDiscoveryProcess = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.algorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.publicationModeDeferralReason = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.deferralOrEnrichmentType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.duplicativeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Extended Message: 66 bytes                                        *)
(***************************************************************************)

TradeExtendedMessage ==
    [ timeOffset         : Sample(4),
      contractsLong      : Sample(8),
      symbolLong         : Sample(8),
      price              : Sample(8),
      tradeId            : Sample(8),
      tradeTimestamp     : Sample(8),
      executionVenue     : Sample(4),
      currency           : Sample(3),
      cboeTradeFlags     : Sample(1),
      extendedTradeFlags : ExtendedTradeFlags ]

EncodeTradeExtendedMessage(message) ==
    message.timeOffset
        \o message.contractsLong
        \o message.symbolLong
        \o message.price
        \o message.tradeId
        \o message.tradeTimestamp
        \o message.executionVenue
        \o message.currency
        \o message.cboeTradeFlags
        \o EncodeExtendedTradeFlags(message.extendedTradeFlags)

DecodeTradeExtendedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET contractsLong == ReadBytes(timeOffset.rest, 8) IN IF ~contractsLong.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(contractsLong.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET price == ReadBytes(symbolLong.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(tradeId.rest, 8) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(tradeTimestamp.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET currency == ReadBytes(executionVenue.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET cboeTradeFlags == ReadBytes(currency.rest, 1) IN IF ~cboeTradeFlags.ok THEN Fail ELSE
    LET extendedTradeFlags == DecodeExtendedTradeFlags(cboeTradeFlags.rest) IN IF ~extendedTradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         contractsLong      |-> contractsLong.value,
         symbolLong         |-> symbolLong.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value,
         tradeTimestamp     |-> tradeTimestamp.value,
         executionVenue     |-> executionVenue.value,
         currency           |-> currency.value,
         cboeTradeFlags     |-> cboeTradeFlags.value,
         extendedTradeFlags |-> extendedTradeFlags.value ], extendedTradeFlags.rest)

ZeroTradeExtendedMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      contractsLong      |-> [i \in 1 .. 8 |-> 0],
      symbolLong         |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0],
      tradeTimestamp     |-> [i \in 1 .. 8 |-> 0],
      executionVenue     |-> [i \in 1 .. 4 |-> 0],
      currency           |-> [i \in 1 .. 3 |-> 0],
      cboeTradeFlags     |-> [i \in 1 .. 1 |-> 0],
      extendedTradeFlags |-> ZeroExtendedTradeFlags ]

(* Trade Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExtendedMessage ==
    { ZeroTradeExtendedMessage }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.contractsLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.cboeTradeFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.extendedTradeFlags = one] : one \in CheckedExtendedTradeFlags }

(***************************************************************************)
(* End Of Session: 4 bytes                                                 *)
(***************************************************************************)

EndOfSession ==
    [ timeOffset : Sample(4) ]

EncodeEndOfSession(message) ==
    message.timeOffset

DecodeEndOfSession(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEndOfSession ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSession ==
    { ZeroEndOfSession }
        \cup { [ZeroEndOfSession EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Transaction Begin Message: 4 bytes                                      *)
(***************************************************************************)

TransactionBeginMessage ==
    [ timeOffset : Sample(4) ]

EncodeTransactionBeginMessage(message) ==
    message.timeOffset

DecodeTransactionBeginMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroTransactionBeginMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Transaction Begin Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionBeginMessage ==
    { ZeroTransactionBeginMessage }
        \cup { [ZeroTransactionBeginMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Transaction End Message: 4 bytes                                        *)
(***************************************************************************)

TransactionEndMessage ==
    [ timeOffset : Sample(4) ]

EncodeTransactionEndMessage(message) ==
    message.timeOffset

DecodeTransactionEndMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroTransactionEndMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Transaction End Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionEndMessage ==
    { ZeroTransactionEndMessage }
        \cup { [ZeroTransactionEndMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset : Sample(4),
      symbolLong : Sample(8),
      status     : Sample(1),
      reserved3  : Sample(3) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.status
        \o message.reserved3

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET status == ReadBytes(symbolLong.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(status.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         symbolLong |-> symbolLong.value,
         status     |-> status.value,
         reserved3  |-> reserved3.value ], reserved3.rest)

ZeroTradingStatusMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      symbolLong |-> [i \in 1 .. 8 |-> 0],
      status     |-> [i \in 1 .. 1 |-> 0],
      reserved3  |-> [i \in 1 .. 3 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Fast Status Message: 11 bytes                                           *)
(***************************************************************************)

FastStatusMessage ==
    [ timeOffset       : Sample(4),
      productCodeShort : Sample(6),
      isFast           : Sample(1) ]

EncodeFastStatusMessage(message) ==
    message.timeOffset
        \o message.productCodeShort
        \o message.isFast

DecodeFastStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET productCodeShort == ReadBytes(timeOffset.rest, 6) IN IF ~productCodeShort.ok THEN Fail ELSE
    LET isFast == ReadBytes(productCodeShort.rest, 1) IN IF ~isFast.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         productCodeShort |-> productCodeShort.value,
         isFast           |-> isFast.value ], isFast.rest)

ZeroFastStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      productCodeShort |-> [i \in 1 .. 6 |-> 0],
      isFast           |-> [i \in 1 .. 1 |-> 0] ]

(* Fast Status Message at zero, then each field in turn at the values it is checked at *)
CheckedFastStatusMessage ==
    { ZeroFastStatusMessage }
        \cup { [ZeroFastStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFastStatusMessage EXCEPT !.productCodeShort = one] : one \in Sample(6) }
        \cup { [ZeroFastStatusMessage EXCEPT !.isFast = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 23 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset         : Sample(4),
      symbolLong         : Sample(8),
      auctionOpeningType : Sample(1),
      price              : Sample(8),
      contractsShort     : Sample(2) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.auctionOpeningType
        \o message.price
        \o message.contractsShort

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionOpeningType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionOpeningType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionOpeningType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(price.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         symbolLong         |-> symbolLong.value,
         auctionOpeningType |-> auctionOpeningType.value,
         price              |-> price.value,
         contractsShort     |-> contractsShort.value ], contractsShort.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      symbolLong         |-> [i \in 1 .. 8 |-> 0],
      auctionOpeningType |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      contractsShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionOpeningType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Opening Auction Update Message: 62 bytes                                *)
(***************************************************************************)

OpeningAuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      symbolLong                : Sample(8),
      auctionType               : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeOpeningAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.symbolLong
        \o message.auctionType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeOpeningAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolLong == ReadBytes(timeOffset.rest, 8) IN IF ~symbolLong.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolLong.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         symbolLong                |-> symbolLong.value,
         auctionType               |-> auctionType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroOpeningAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      symbolLong                |-> [i \in 1 .. 8 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Opening Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningAuctionUpdateMessage ==
    { ZeroOpeningAuctionUpdateMessage }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.symbolLong = one] : one \in Sample(8) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroOpeningAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Notification Message: 39 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      symbol            : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      side              : Sample(1),
      price             : Sample(8),
      contractsShort    : Sample(2),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.auctionId
        \o message.auctionType
        \o message.side
        \o message.price
        \o message.contractsShort
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(symbol.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET side == ReadBytes(auctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(price.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(contractsShort.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         symbol            |-> symbol.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         side              |-> side.value,
         price             |-> price.value,
         contractsShort    |-> contractsShort.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value ], auctionEndOffset.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      symbol            |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      contractsShort    |-> [i \in 1 .. 2 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Cancel Message: 12 bytes                                        *)
(***************************************************************************)

AuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCancelMessage ==
    { ZeroAuctionCancelMessage }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Flags: 4 bytes                                                *)
(***************************************************************************)

ExecutionFlags3 ==
    [ marketMechanism  : Sample(1),
      tradingMode      : Sample(1),
      exCumDividend    : Sample(1),
      algorithmicTrade : Sample(1) ]

EncodeExecutionFlags3(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.exCumDividend
        \o message.algorithmicTrade

DecodeExecutionFlags3(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(tradingMode.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    LET algorithmicTrade == ReadBytes(exCumDividend.rest, 1) IN IF ~algorithmicTrade.ok THEN Fail ELSE
    Ok([ marketMechanism  |-> marketMechanism.value,
         tradingMode      |-> tradingMode.value,
         exCumDividend    |-> exCumDividend.value,
         algorithmicTrade |-> algorithmicTrade.value ], algorithmicTrade.rest)

ZeroExecutionFlags3 ==
    [ marketMechanism  |-> [i \in 1 .. 1 |-> 0],
      tradingMode      |-> [i \in 1 .. 1 |-> 0],
      exCumDividend    |-> [i \in 1 .. 1 |-> 0],
      algorithmicTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Flags at zero, then each field in turn at the values it is checked at *)
CheckedExecutionFlags3 ==
    { ZeroExecutionFlags3 }
        \cup { [ZeroExecutionFlags3 EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags3 EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags3 EXCEPT !.exCumDividend = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags3 EXCEPT !.algorithmicTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Trade Message: 34 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timeOffset     : Sample(4),
      auctionId      : Sample(8),
      executionId    : Sample(8),
      price          : Sample(8),
      contractsShort : Sample(2),
      executionFlags : ExecutionFlags3 ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.price
        \o message.contractsShort
        \o EncodeExecutionFlags3(message.executionFlags)

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET price == ReadBytes(executionId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contractsShort == ReadBytes(price.rest, 2) IN IF ~contractsShort.ok THEN Fail ELSE
    LET executionFlags == DecodeExecutionFlags3(contractsShort.rest) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         auctionId      |-> auctionId.value,
         executionId    |-> executionId.value,
         price          |-> price.value,
         contractsShort |-> contractsShort.value,
         executionFlags |-> executionFlags.value ], executionFlags.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      auctionId      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      contractsShort |-> [i \in 1 .. 2 |-> 0],
      executionFlags |-> ZeroExecutionFlags3 ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.contractsShort = one] : one \in Sample(2) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionFlags = one] : one \in CheckedExecutionFlags3 }

(***************************************************************************)
(* Price Level Group: 12 bytes                                             *)
(***************************************************************************)

PriceLevelGroup ==
    [ priceLevel : Sample(8),
      volume     : Sample(4) ]

EncodePriceLevelGroup(message) ==
    message.priceLevel
        \o message.volume

DecodePriceLevelGroup(bytes) ==
    LET priceLevel == ReadBytes(bytes, 8) IN IF ~priceLevel.ok THEN Fail ELSE
    LET volume == ReadBytes(priceLevel.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ priceLevel |-> priceLevel.value,
         volume     |-> volume.value ], volume.rest)

ZeroPriceLevelGroup ==
    [ priceLevel |-> [i \in 1 .. 8 |-> 0],
      volume     |-> [i \in 1 .. 4 |-> 0] ]

(* Price Level Group at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevelGroup ==
    { ZeroPriceLevelGroup }
        \cup { [ZeroPriceLevelGroup EXCEPT !.priceLevel = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevelGroup EXCEPT !.volume = one] : one \in Sample(4) }

(* A run of Price Level Group, written one after another *)
RECURSIVE EncodePriceLevelGroupList(_)
EncodePriceLevelGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePriceLevelGroup(Head(messages)) \o EncodePriceLevelGroupList(Tail(messages))

(* As many Price Level Group as the field that counts them says *)
RECURSIVE ReadPriceLevelGroupList(_, _)
ReadPriceLevelGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePriceLevelGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPriceLevelGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Price Level Group of each kind, for the lists that carry them *)
OnePriceLevelGroup == { ZeroPriceLevelGroup }

(***************************************************************************)
(* Auction Liquidity Message                                               *)
(***************************************************************************)

AuctionLiquidityMessage ==
    [ timeOffset      : Sample(4),
      auctionId       : Sample(8),
      priceLevelGroup : SampleLists(OnePriceLevelGroup) ]

EncodeAuctionLiquidityMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o EncodeUIntLE(Len(message.priceLevelGroup), 1)
        \o EncodePriceLevelGroupList(message.priceLevelGroup)

DecodeAuctionLiquidityMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET priceLevelCount == ReadUIntLE(auctionId.rest, 1) IN IF ~priceLevelCount.ok THEN Fail ELSE
    LET priceLevelGroup == ReadPriceLevelGroupList(priceLevelCount.rest, priceLevelCount.value) IN IF ~priceLevelGroup.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         auctionId       |-> auctionId.value,
         priceLevelGroup |-> priceLevelGroup.value ], priceLevelGroup.rest)

ZeroAuctionLiquidityMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 8 |-> 0],
      priceLevelGroup |-> << >> ]

(* Auction Liquidity Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionLiquidityMessage ==
    { ZeroAuctionLiquidityMessage }
        \cup { [ZeroAuctionLiquidityMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionLiquidityMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionLiquidityMessage EXCEPT !.priceLevelGroup = one] : one \in SampleLists(OnePriceLevelGroup) }

(***************************************************************************)
(* Width Update Message: 17 bytes                                          *)
(***************************************************************************)

WidthUpdateMessage ==
    [ timeOffset      : Sample(4),
      productCodeLong : Sample(8),
      widthType       : Sample(1),
      multiplier      : Sample(4) ]

EncodeWidthUpdateMessage(message) ==
    message.timeOffset
        \o message.productCodeLong
        \o message.widthType
        \o message.multiplier

DecodeWidthUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET productCodeLong == ReadBytes(timeOffset.rest, 8) IN IF ~productCodeLong.ok THEN Fail ELSE
    LET widthType == ReadBytes(productCodeLong.rest, 1) IN IF ~widthType.ok THEN Fail ELSE
    LET multiplier == ReadBytes(widthType.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         productCodeLong |-> productCodeLong.value,
         widthType       |-> widthType.value,
         multiplier      |-> multiplier.value ], multiplier.rest)

ZeroWidthUpdateMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      productCodeLong |-> [i \in 1 .. 8 |-> 0],
      widthType       |-> [i \in 1 .. 1 |-> 0],
      multiplier      |-> [i \in 1 .. 4 |-> 0] ]

(* Width Update Message at zero, then each field in turn at the values it is checked at *)
CheckedWidthUpdateMessage ==
    { ZeroWidthUpdateMessage }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.productCodeLong = one] : one \in Sample(8) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.widthType = one] : one \in Sample(1) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.multiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* Futures Instrument Definition Message: 33 bytes                         *)
(***************************************************************************)

FuturesInstrumentDefinitionMessage ==
    [ timeOffset      : Sample(4),
      symbol          : Sample(6),
      productCodeLong : Sample(8),
      expirationDate  : Sample(4),
      contractSize    : Sample(2),
      listingState    : Sample(1),
      priceIncrement  : Sample(8) ]

EncodeFuturesInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.productCodeLong
        \o message.expirationDate
        \o message.contractSize
        \o message.listingState
        \o message.priceIncrement

DecodeFuturesInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET productCodeLong == ReadBytes(symbol.rest, 8) IN IF ~productCodeLong.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(productCodeLong.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET contractSize == ReadBytes(expirationDate.rest, 2) IN IF ~contractSize.ok THEN Fail ELSE
    LET listingState == ReadBytes(contractSize.rest, 1) IN IF ~listingState.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(listingState.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbol          |-> symbol.value,
         productCodeLong |-> productCodeLong.value,
         expirationDate  |-> expirationDate.value,
         contractSize    |-> contractSize.value,
         listingState    |-> listingState.value,
         priceIncrement  |-> priceIncrement.value ], priceIncrement.rest)

ZeroFuturesInstrumentDefinitionMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      productCodeLong |-> [i \in 1 .. 8 |-> 0],
      expirationDate  |-> [i \in 1 .. 4 |-> 0],
      contractSize    |-> [i \in 1 .. 2 |-> 0],
      listingState    |-> [i \in 1 .. 1 |-> 0],
      priceIncrement  |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesInstrumentDefinitionMessage ==
    { ZeroFuturesInstrumentDefinitionMessage }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.productCodeLong = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.listingState = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentDefinitionMessage EXCEPT !.priceIncrement = one] : one \in Sample(8) }

(***************************************************************************)
(* Options Instrument Definition Message: 42 bytes                         *)
(***************************************************************************)

OptionsInstrumentDefinitionMessage ==
    [ timeOffset      : Sample(4),
      symbol          : Sample(6),
      productCodeLong : Sample(8),
      callPut         : Sample(1),
      expirationDate  : Sample(4),
      strikePrice     : Sample(8),
      contractSize    : Sample(2),
      listingState    : Sample(1),
      priceIncrement  : Sample(8) ]

EncodeOptionsInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.productCodeLong
        \o message.callPut
        \o message.expirationDate
        \o message.strikePrice
        \o message.contractSize
        \o message.listingState
        \o message.priceIncrement

DecodeOptionsInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET productCodeLong == ReadBytes(symbol.rest, 8) IN IF ~productCodeLong.ok THEN Fail ELSE
    LET callPut == ReadBytes(productCodeLong.rest, 1) IN IF ~callPut.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(callPut.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET contractSize == ReadBytes(strikePrice.rest, 2) IN IF ~contractSize.ok THEN Fail ELSE
    LET listingState == ReadBytes(contractSize.rest, 1) IN IF ~listingState.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(listingState.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbol          |-> symbol.value,
         productCodeLong |-> productCodeLong.value,
         callPut         |-> callPut.value,
         expirationDate  |-> expirationDate.value,
         strikePrice     |-> strikePrice.value,
         contractSize    |-> contractSize.value,
         listingState    |-> listingState.value,
         priceIncrement  |-> priceIncrement.value ], priceIncrement.rest)

ZeroOptionsInstrumentDefinitionMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      productCodeLong |-> [i \in 1 .. 8 |-> 0],
      callPut         |-> [i \in 1 .. 1 |-> 0],
      expirationDate  |-> [i \in 1 .. 4 |-> 0],
      strikePrice     |-> [i \in 1 .. 8 |-> 0],
      contractSize    |-> [i \in 1 .. 2 |-> 0],
      listingState    |-> [i \in 1 .. 1 |-> 0],
      priceIncrement  |-> [i \in 1 .. 8 |-> 0] ]

(* Options Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsInstrumentDefinitionMessage ==
    { ZeroOptionsInstrumentDefinitionMessage }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.productCodeLong = one] : one \in Sample(8) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.callPut = one] : one \in Sample(1) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(2) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.listingState = one] : one \in Sample(1) }
        \cup { [ZeroOptionsInstrumentDefinitionMessage EXCEPT !.priceIncrement = one] : one \in Sample(8) }

(***************************************************************************)
(* Leg Group: 10 bytes                                                     *)
(***************************************************************************)

LegGroup ==
    [ legSymbol : Sample(6),
      legRatio  : Sample(4) ]

EncodeLegGroup(message) ==
    message.legSymbol
        \o message.legRatio

DecodeLegGroup(bytes) ==
    LET legSymbol == ReadBytes(bytes, 6) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbol |-> legSymbol.value,
         legRatio  |-> legRatio.value ], legRatio.rest)

ZeroLegGroup ==
    [ legSymbol |-> [i \in 1 .. 6 |-> 0],
      legRatio  |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Group at zero, then each field in turn at the values it is checked at *)
CheckedLegGroup ==
    { ZeroLegGroup }
        \cup { [ZeroLegGroup EXCEPT !.legSymbol = one] : one \in Sample(6) }
        \cup { [ZeroLegGroup EXCEPT !.legRatio = one] : one \in Sample(4) }

(* A run of Leg Group, written one after another *)
RECURSIVE EncodeLegGroupList(_)
EncodeLegGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegGroup(Head(messages)) \o EncodeLegGroupList(Tail(messages))

(* As many Leg Group as the field that counts them says *)
RECURSIVE ReadLegGroupList(_, _)
ReadLegGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Group of each kind, for the lists that carry them *)
OneLegGroup == { ZeroLegGroup }

(***************************************************************************)
(* Complex Instrument Definition Message                                   *)
(***************************************************************************)

ComplexInstrumentDefinitionMessage ==
    [ timeOffset          : Sample(4),
      complexInstrumentId : Sample(6),
      referencePrice      : Sample(8),
      legGroup            : SampleLists(OneLegGroup) ]

EncodeComplexInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.referencePrice
        \o EncodeUIntLE(Len(message.legGroup), 1)
        \o EncodeLegGroupList(message.legGroup)

DecodeComplexInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(complexInstrumentId.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET legCount == ReadUIntLE(referencePrice.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET legGroup == ReadLegGroupList(legCount.rest, legCount.value) IN IF ~legGroup.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         complexInstrumentId |-> complexInstrumentId.value,
         referencePrice      |-> referencePrice.value,
         legGroup            |-> legGroup.value ], legGroup.rest)

ZeroComplexInstrumentDefinitionMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      referencePrice      |-> [i \in 1 .. 8 |-> 0],
      legGroup            |-> << >> ]

(* Complex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDefinitionMessage ==
    { ZeroComplexInstrumentDefinitionMessage }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDefinitionMessage EXCEPT !.legGroup = one] : one \in SampleLists(OneLegGroup) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Settlement Message: 23 bytes                                            *)
(***************************************************************************)

SettlementMessage ==
    [ timeOffset      : Sample(4),
      symbol          : Sample(6),
      tradeDate       : Sample(4),
      settlementPrice : Sample(8),
      issue           : Sample(1) ]

EncodeSettlementMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.tradeDate
        \o message.settlementPrice
        \o message.issue

DecodeSettlementMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(symbol.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(tradeDate.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET issue == ReadBytes(settlementPrice.rest, 1) IN IF ~issue.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         symbol          |-> symbol.value,
         tradeDate       |-> tradeDate.value,
         settlementPrice |-> settlementPrice.value,
         issue           |-> issue.value ], issue.rest)

ZeroSettlementMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 6 |-> 0],
      tradeDate       |-> [i \in 1 .. 4 |-> 0],
      settlementPrice |-> [i \in 1 .. 8 |-> 0],
      issue           |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementMessage ==
    { ZeroSettlementMessage }
        \cup { [ZeroSettlementMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSettlementMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroSettlementMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroSettlementMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSettlementMessage EXCEPT !.issue = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Day Summary Message: 63 bytes                                    *)
(***************************************************************************)

EndOfDaySummaryMessage ==
    [ timeOffset   : Sample(4),
      symbol       : Sample(6),
      tradeDate    : Sample(4),
      openInterest : Sample(4),
      highPrice    : Sample(8),
      lowPrice     : Sample(8),
      openPrice    : Sample(8),
      closePrice   : Sample(8),
      totalVolume  : Sample(4),
      blockVolume  : Sample(4),
      ecrpVolume   : Sample(4),
      summaryFlags : Sample(1) ]

EncodeEndOfDaySummaryMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.tradeDate
        \o message.openInterest
        \o message.highPrice
        \o message.lowPrice
        \o message.openPrice
        \o message.closePrice
        \o message.totalVolume
        \o message.blockVolume
        \o message.ecrpVolume
        \o message.summaryFlags

DecodeEndOfDaySummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(symbol.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET openInterest == ReadBytes(tradeDate.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openInterest.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET openPrice == ReadBytes(lowPrice.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(openPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(closePrice.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET blockVolume == ReadBytes(totalVolume.rest, 4) IN IF ~blockVolume.ok THEN Fail ELSE
    LET ecrpVolume == ReadBytes(blockVolume.rest, 4) IN IF ~ecrpVolume.ok THEN Fail ELSE
    LET summaryFlags == ReadBytes(ecrpVolume.rest, 1) IN IF ~summaryFlags.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         symbol       |-> symbol.value,
         tradeDate    |-> tradeDate.value,
         openInterest |-> openInterest.value,
         highPrice    |-> highPrice.value,
         lowPrice     |-> lowPrice.value,
         openPrice    |-> openPrice.value,
         closePrice   |-> closePrice.value,
         totalVolume  |-> totalVolume.value,
         blockVolume  |-> blockVolume.value,
         ecrpVolume   |-> ecrpVolume.value,
         summaryFlags |-> summaryFlags.value ], summaryFlags.rest)

ZeroEndOfDaySummaryMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      symbol       |-> [i \in 1 .. 6 |-> 0],
      tradeDate    |-> [i \in 1 .. 4 |-> 0],
      openInterest |-> [i \in 1 .. 4 |-> 0],
      highPrice    |-> [i \in 1 .. 8 |-> 0],
      lowPrice     |-> [i \in 1 .. 8 |-> 0],
      openPrice    |-> [i \in 1 .. 8 |-> 0],
      closePrice   |-> [i \in 1 .. 8 |-> 0],
      totalVolume  |-> [i \in 1 .. 4 |-> 0],
      blockVolume  |-> [i \in 1 .. 4 |-> 0],
      ecrpVolume   |-> [i \in 1 .. 4 |-> 0],
      summaryFlags |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Day Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDaySummaryMessage ==
    { ZeroEndOfDaySummaryMessage }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.blockVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.ecrpVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfDaySummaryMessage EXCEPT !.summaryFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
AddOrderLongMessageCode == 64  \* 0x40
AddOrderShortMessageCode == 34  \* 0x22
OrderExecutedMessageCode == 35  \* 0x23
OrderExecutedAtPriceSizeMessageCode == 36  \* 0x24
ReduceSizeLongMessageCode == 37  \* 0x25
ReduceSizeShortMessageCode == 38  \* 0x26
ModifyOrderLongMessageCode == 39  \* 0x27
ModifyOrderShortMessageCode == 40  \* 0x28
DeleteOrderMessageCode == 41  \* 0x29
TradeLongMessageCode == 65  \* 0x41
TradeShortMessageCode == 43  \* 0x2b
TradeExtendedMessageCode == 50  \* 0x32
EndOfSessionCode == 45  \* 0x2d
TransactionBeginMessageCode == 188  \* 0xbc
TransactionEndMessageCode == 189  \* 0xbd
TradingStatusMessageCode == 49  \* 0x31
FastStatusMessageCode == 226  \* 0xe2
AuctionSummaryMessageCode == 150  \* 0x96
OpeningAuctionUpdateMessageCode == 209  \* 0xd1
AuctionNotificationMessageCode == 173  \* 0xad
AuctionCancelMessageCode == 174  \* 0xae
AuctionTradeMessageCode == 223  \* 0xdf
AuctionLiquidityMessageCode == 222  \* 0xde
WidthUpdateMessageCode == 210  \* 0xd2
FuturesInstrumentDefinitionMessageCode == 218  \* 0xda
OptionsInstrumentDefinitionMessageCode == 219  \* 0xdb
ComplexInstrumentDefinitionMessageCode == 220  \* 0xdc
TradeBreakMessageCode == 44  \* 0x2c
SettlementMessageCode == 185  \* 0xb9
EndOfDaySummaryMessageCode == 186  \* 0xba

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedAtPriceSizeMessageCode}, body : OrderExecutedAtPriceSizeMessage ]
        \cup [ tag : {ReduceSizeLongMessageCode}, body : ReduceSizeLongMessage ]
        \cup [ tag : {ReduceSizeShortMessageCode}, body : ReduceSizeShortMessage ]
        \cup [ tag : {ModifyOrderLongMessageCode}, body : ModifyOrderLongMessage ]
        \cup [ tag : {ModifyOrderShortMessageCode}, body : ModifyOrderShortMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {TradeExtendedMessageCode}, body : TradeExtendedMessage ]
        \cup [ tag : {EndOfSessionCode}, body : EndOfSession ]
        \cup [ tag : {TransactionBeginMessageCode}, body : TransactionBeginMessage ]
        \cup [ tag : {TransactionEndMessageCode}, body : TransactionEndMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {FastStatusMessageCode}, body : FastStatusMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {OpeningAuctionUpdateMessageCode}, body : OpeningAuctionUpdateMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {AuctionCancelMessageCode}, body : AuctionCancelMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {AuctionLiquidityMessageCode}, body : AuctionLiquidityMessage ]
        \cup [ tag : {WidthUpdateMessageCode}, body : WidthUpdateMessage ]
        \cup [ tag : {FuturesInstrumentDefinitionMessageCode}, body : FuturesInstrumentDefinitionMessage ]
        \cup [ tag : {OptionsInstrumentDefinitionMessageCode}, body : OptionsInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexInstrumentDefinitionMessageCode}, body : ComplexInstrumentDefinitionMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {SettlementMessageCode}, body : SettlementMessage ]
        \cup [ tag : {EndOfDaySummaryMessageCode}, body : EndOfDaySummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedAtPriceSizeMessageCode -> EncodeOrderExecutedAtPriceSizeMessage(message.body)
      [] message.tag = ReduceSizeLongMessageCode -> EncodeReduceSizeLongMessage(message.body)
      [] message.tag = ReduceSizeShortMessageCode -> EncodeReduceSizeShortMessage(message.body)
      [] message.tag = ModifyOrderLongMessageCode -> EncodeModifyOrderLongMessage(message.body)
      [] message.tag = ModifyOrderShortMessageCode -> EncodeModifyOrderShortMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = TradeExtendedMessageCode -> EncodeTradeExtendedMessage(message.body)
      [] message.tag = EndOfSessionCode -> EncodeEndOfSession(message.body)
      [] message.tag = TransactionBeginMessageCode -> EncodeTransactionBeginMessage(message.body)
      [] message.tag = TransactionEndMessageCode -> EncodeTransactionEndMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = FastStatusMessageCode -> EncodeFastStatusMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = OpeningAuctionUpdateMessageCode -> EncodeOpeningAuctionUpdateMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = AuctionCancelMessageCode -> EncodeAuctionCancelMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = AuctionLiquidityMessageCode -> EncodeAuctionLiquidityMessage(message.body)
      [] message.tag = WidthUpdateMessageCode -> EncodeWidthUpdateMessage(message.body)
      [] message.tag = FuturesInstrumentDefinitionMessageCode -> EncodeFuturesInstrumentDefinitionMessage(message.body)
      [] message.tag = OptionsInstrumentDefinitionMessageCode -> EncodeOptionsInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexInstrumentDefinitionMessageCode -> EncodeComplexInstrumentDefinitionMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = SettlementMessageCode -> EncodeSettlementMessage(message.body)
      [] message.tag = EndOfDaySummaryMessageCode -> EncodeEndOfDaySummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedAtPriceSizeMessageCode -> DecodeOrderExecutedAtPriceSizeMessage(bytes)
              [] tag = ReduceSizeLongMessageCode -> DecodeReduceSizeLongMessage(bytes)
              [] tag = ReduceSizeShortMessageCode -> DecodeReduceSizeShortMessage(bytes)
              [] tag = ModifyOrderLongMessageCode -> DecodeModifyOrderLongMessage(bytes)
              [] tag = ModifyOrderShortMessageCode -> DecodeModifyOrderShortMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = TradeExtendedMessageCode -> DecodeTradeExtendedMessage(bytes)
              [] tag = EndOfSessionCode -> DecodeEndOfSession(bytes)
              [] tag = TransactionBeginMessageCode -> DecodeTransactionBeginMessage(bytes)
              [] tag = TransactionEndMessageCode -> DecodeTransactionEndMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = FastStatusMessageCode -> DecodeFastStatusMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = OpeningAuctionUpdateMessageCode -> DecodeOpeningAuctionUpdateMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = AuctionCancelMessageCode -> DecodeAuctionCancelMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = AuctionLiquidityMessageCode -> DecodeAuctionLiquidityMessage(bytes)
              [] tag = WidthUpdateMessageCode -> DecodeWidthUpdateMessage(bytes)
              [] tag = FuturesInstrumentDefinitionMessageCode -> DecodeFuturesInstrumentDefinitionMessage(bytes)
              [] tag = OptionsInstrumentDefinitionMessageCode -> DecodeOptionsInstrumentDefinitionMessage(bytes)
              [] tag = ComplexInstrumentDefinitionMessageCode -> DecodeComplexInstrumentDefinitionMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = SettlementMessageCode -> DecodeSettlementMessage(bytes)
              [] tag = EndOfDaySummaryMessageCode -> DecodeEndOfDaySummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> one] : one \in CheckedOrderExecutedAtPriceSizeMessage }
        \cup { [tag |-> ReduceSizeLongMessageCode, body |-> one] : one \in CheckedReduceSizeLongMessage }
        \cup { [tag |-> ReduceSizeShortMessageCode, body |-> one] : one \in CheckedReduceSizeShortMessage }
        \cup { [tag |-> ModifyOrderLongMessageCode, body |-> one] : one \in CheckedModifyOrderLongMessage }
        \cup { [tag |-> ModifyOrderShortMessageCode, body |-> one] : one \in CheckedModifyOrderShortMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> TradeExtendedMessageCode, body |-> one] : one \in CheckedTradeExtendedMessage }
        \cup { [tag |-> EndOfSessionCode, body |-> one] : one \in CheckedEndOfSession }
        \cup { [tag |-> TransactionBeginMessageCode, body |-> one] : one \in CheckedTransactionBeginMessage }
        \cup { [tag |-> TransactionEndMessageCode, body |-> one] : one \in CheckedTransactionEndMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> FastStatusMessageCode, body |-> one] : one \in CheckedFastStatusMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> OpeningAuctionUpdateMessageCode, body |-> one] : one \in CheckedOpeningAuctionUpdateMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> AuctionCancelMessageCode, body |-> one] : one \in CheckedAuctionCancelMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> AuctionLiquidityMessageCode, body |-> one] : one \in CheckedAuctionLiquidityMessage }
        \cup { [tag |-> WidthUpdateMessageCode, body |-> one] : one \in CheckedWidthUpdateMessage }
        \cup { [tag |-> FuturesInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedFuturesInstrumentDefinitionMessage }
        \cup { [tag |-> OptionsInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedOptionsInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedComplexInstrumentDefinitionMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> SettlementMessageCode, body |-> one] : one \in CheckedSettlementMessage }
        \cup { [tag |-> EndOfDaySummaryMessageCode, body |-> one] : one \in CheckedEndOfDaySummaryMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UnitClearMessageCode, body |-> ZeroUnitClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderLongMessageCode, body |-> ZeroAddOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderShortMessageCode, body |-> ZeroAddOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedAtPriceSizeMessageCode, body |-> ZeroOrderExecutedAtPriceSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeLongMessageCode, body |-> ZeroReduceSizeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReduceSizeShortMessageCode, body |-> ZeroReduceSizeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderLongMessageCode, body |-> ZeroModifyOrderLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ModifyOrderShortMessageCode, body |-> ZeroModifyOrderShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeLongMessageCode, body |-> ZeroTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeShortMessageCode, body |-> ZeroTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeExtendedMessageCode, body |-> ZeroTradeExtendedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> ZeroEndOfSession]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionBeginMessageCode, body |-> ZeroTransactionBeginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TransactionEndMessageCode, body |-> ZeroTransactionEndMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FastStatusMessageCode, body |-> ZeroFastStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpeningAuctionUpdateMessageCode, body |-> ZeroOpeningAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionCancelMessageCode, body |-> ZeroAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionLiquidityMessageCode, body |-> ZeroAuctionLiquidityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WidthUpdateMessageCode, body |-> ZeroWidthUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FuturesInstrumentDefinitionMessageCode, body |-> ZeroFuturesInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsInstrumentDefinitionMessageCode, body |-> ZeroOptionsInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexInstrumentDefinitionMessageCode, body |-> ZeroComplexInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementMessageCode, body |-> ZeroSettlementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDaySummaryMessageCode, body |-> ZeroEndOfDaySummaryMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
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

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unit Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnitClearMessage ==
    \A message \in CheckedUnitClearMessage :
        LET read == DecodeUnitClearMessage(EncodeUnitClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongMessage ==
    \A message \in CheckedAddOrderLongMessage :
        LET read == DecodeAddOrderLongMessage(EncodeAddOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortMessage ==
    \A message \in CheckedAddOrderShortMessage :
        LET read == DecodeAddOrderShortMessage(EncodeAddOrderShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionFlags ==
    \A message \in CheckedExecutionFlags :
        LET read == DecodeExecutionFlags(EncodeExecutionFlags(message))
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

(* Every Execution Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionFlags2 ==
    \A message \in CheckedExecutionFlags2 :
        LET read == DecodeExecutionFlags2(EncodeExecutionFlags2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed At Price Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedAtPriceSizeMessage ==
    \A message \in CheckedOrderExecutedAtPriceSizeMessage :
        LET read == DecodeOrderExecutedAtPriceSizeMessage(EncodeOrderExecutedAtPriceSizeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeLongMessage ==
    \A message \in CheckedReduceSizeLongMessage :
        LET read == DecodeReduceSizeLongMessage(EncodeReduceSizeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reduce Size Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReduceSizeShortMessage ==
    \A message \in CheckedReduceSizeShortMessage :
        LET read == DecodeReduceSizeShortMessage(EncodeReduceSizeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderLongMessage ==
    \A message \in CheckedModifyOrderLongMessage :
        LET read == DecodeModifyOrderLongMessage(EncodeModifyOrderLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderShortMessage ==
    \A message \in CheckedModifyOrderShortMessage :
        LET read == DecodeModifyOrderShortMessage(EncodeModifyOrderShortMessage(message))
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

(* Every Trade Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeFlags ==
    \A message \in CheckedTradeFlags :
        LET read == DecodeTradeFlags(EncodeTradeFlags(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLongMessage ==
    \A message \in CheckedTradeLongMessage :
        LET read == DecodeTradeLongMessage(EncodeTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeFlags2 ==
    \A message \in CheckedTradeFlags2 :
        LET read == DecodeTradeFlags2(EncodeTradeFlags2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeShortMessage ==
    \A message \in CheckedTradeShortMessage :
        LET read == DecodeTradeShortMessage(EncodeTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Trade Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedTradeFlags ==
    \A message \in CheckedExtendedTradeFlags :
        LET read == DecodeExtendedTradeFlags(EncodeExtendedTradeFlags(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeExtendedMessage ==
    \A message \in CheckedTradeExtendedMessage :
        LET read == DecodeTradeExtendedMessage(EncodeTradeExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSession ==
    \A message \in CheckedEndOfSession :
        LET read == DecodeEndOfSession(EncodeEndOfSession(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Begin Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionBeginMessage ==
    \A message \in CheckedTransactionBeginMessage :
        LET read == DecodeTransactionBeginMessage(EncodeTransactionBeginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionEndMessage ==
    \A message \in CheckedTransactionEndMessage :
        LET read == DecodeTransactionEndMessage(EncodeTransactionEndMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fast Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFastStatusMessage ==
    \A message \in CheckedFastStatusMessage :
        LET read == DecodeFastStatusMessage(EncodeFastStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningAuctionUpdateMessage ==
    \A message \in CheckedOpeningAuctionUpdateMessage :
        LET read == DecodeOpeningAuctionUpdateMessage(EncodeOpeningAuctionUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCancelMessage ==
    \A message \in CheckedAuctionCancelMessage :
        LET read == DecodeAuctionCancelMessage(EncodeAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Flags decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionFlags3 ==
    \A message \in CheckedExecutionFlags3 :
        LET read == DecodeExecutionFlags3(EncodeExecutionFlags3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevelGroup ==
    \A message \in CheckedPriceLevelGroup :
        LET read == DecodePriceLevelGroup(EncodePriceLevelGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Liquidity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionLiquidityMessage ==
    \A message \in CheckedAuctionLiquidityMessage :
        LET read == DecodeAuctionLiquidityMessage(EncodeAuctionLiquidityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Width Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWidthUpdateMessage ==
    \A message \in CheckedWidthUpdateMessage :
        LET read == DecodeWidthUpdateMessage(EncodeWidthUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesInstrumentDefinitionMessage ==
    \A message \in CheckedFuturesInstrumentDefinitionMessage :
        LET read == DecodeFuturesInstrumentDefinitionMessage(EncodeFuturesInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsInstrumentDefinitionMessage ==
    \A message \in CheckedOptionsInstrumentDefinitionMessage :
        LET read == DecodeOptionsInstrumentDefinitionMessage(EncodeOptionsInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLegGroup ==
    \A message \in CheckedLegGroup :
        LET read == DecodeLegGroup(EncodeLegGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDefinitionMessage ==
    \A message \in CheckedComplexInstrumentDefinitionMessage :
        LET read == DecodeComplexInstrumentDefinitionMessage(EncodeComplexInstrumentDefinitionMessage(message))
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

(* Every Settlement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementMessage ==
    \A message \in CheckedSettlementMessage :
        LET read == DecodeSettlementMessage(EncodeSettlementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDaySummaryMessage ==
    \A message \in CheckedEndOfDaySummaryMessage :
        LET read == DecodeEndOfDaySummaryMessage(EncodeEndOfDaySummaryMessage(message))
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
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
