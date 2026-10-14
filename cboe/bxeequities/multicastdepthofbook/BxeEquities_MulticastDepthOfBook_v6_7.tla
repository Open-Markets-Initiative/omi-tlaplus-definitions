--------------- MODULE BxeEquities_MulticastDepthOfBook_v6_7 ---------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Depth Of Book v6.7             *)
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
(* Note: Add Flags is a bit field set, checked as its 1 byte rather than   *)
(* bit by bit.                                                             *)
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
      quantityLong  : Sample(4),
      symbolShort   : Sample(8),
      priceLong     : Sample(8) ]

EncodeAddOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolShort
        \o message.priceLong

DecodeAddOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityLong.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbolShort   |-> symbolShort.value,
         priceLong     |-> priceLong.value ], priceLong.rest)

ZeroAddOrderLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongMessage ==
    { ZeroAddOrderLongMessage }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order Short Message: 23 bytes                                       *)
(***************************************************************************)

AddOrderShortMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      quantityShort       : Sample(2),
      symbolAlphanumeric6 : Sample(6),
      priceShort          : Sample(2) ]

EncodeAddOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.symbolAlphanumeric6
        \o message.priceShort

DecodeAddOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET symbolAlphanumeric6 == ReadBytes(quantityShort.rest, 6) IN IF ~symbolAlphanumeric6.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolAlphanumeric6.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         quantityShort       |-> quantityShort.value,
         symbolAlphanumeric6 |-> symbolAlphanumeric6.value,
         priceShort          |-> priceShort.value ], priceShort.rest)

ZeroAddOrderShortMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      quantityShort       |-> [i \in 1 .. 2 |-> 0],
      symbolAlphanumeric6 |-> [i \in 1 .. 6 |-> 0],
      priceShort          |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortMessage ==
    { ZeroAddOrderShortMessage }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.symbolAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Expanded Message: 38 bytes                                    *)
(***************************************************************************)

AddOrderExpandedMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      quantityLong  : Sample(4),
      symbolShort   : Sample(8),
      priceLong     : Sample(8),
      addFlags      : Sample(1),
      participantId : Sample(4) ]

EncodeAddOrderExpandedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.symbolShort
        \o message.priceLong
        \o message.addFlags
        \o message.participantId

DecodeAddOrderExpandedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(quantityLong.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET addFlags == ReadBytes(priceLong.rest, 1) IN IF ~addFlags.ok THEN Fail ELSE
    LET participantId == ReadBytes(addFlags.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         quantityLong  |-> quantityLong.value,
         symbolShort   |-> symbolShort.value,
         priceLong     |-> priceLong.value,
         addFlags      |-> addFlags.value,
         participantId |-> participantId.value ], participantId.rest)

ZeroAddOrderExpandedMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      quantityLong  |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      addFlags      |-> [i \in 1 .. 1 |-> 0],
      participantId |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Expanded Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderExpandedMessage ==
    { ZeroAddOrderExpandedMessage }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.addFlags = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderExpandedMessage EXCEPT !.participantId = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Flags: 3 bytes                                                *)
(***************************************************************************)

ExecutionFlags ==
    [ marketMechanism : Sample(1),
      tradingMode     : Sample(1),
      exCumDividend   : Sample(1) ]

EncodeExecutionFlags(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.exCumDividend

DecodeExecutionFlags(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(tradingMode.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    Ok([ marketMechanism |-> marketMechanism.value,
         tradingMode     |-> tradingMode.value,
         exCumDividend   |-> exCumDividend.value ], exCumDividend.rest)

ZeroExecutionFlags ==
    [ marketMechanism |-> [i \in 1 .. 1 |-> 0],
      tradingMode     |-> [i \in 1 .. 1 |-> 0],
      exCumDividend   |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Flags at zero, then each field in turn at the values it is checked at *)
CheckedExecutionFlags ==
    { ZeroExecutionFlags }
        \cup { [ZeroExecutionFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags EXCEPT !.exCumDividend = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 27 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timeOffset     : Sample(4),
      orderId        : Sample(8),
      executedShares : Sample(4),
      executionId    : Sample(8),
      executionFlags : ExecutionFlags ]

EncodeOrderExecutedMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedShares
        \o message.executionId
        \o EncodeExecutionFlags(message.executionFlags)

DecodeOrderExecutedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderId.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET executionId == ReadBytes(executedShares.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET executionFlags == DecodeExecutionFlags(executionId.rest) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         orderId        |-> orderId.value,
         executedShares |-> executedShares.value,
         executionId    |-> executionId.value,
         executionFlags |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      executedShares |-> [i \in 1 .. 4 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      executionFlags |-> ZeroExecutionFlags ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executionFlags = one] : one \in CheckedExecutionFlags }

(***************************************************************************)
(* Execution Flags: 3 bytes                                                *)
(***************************************************************************)

ExecutionFlags2 ==
    [ marketMechanism : Sample(1),
      tradingMode     : Sample(1),
      exCumDividend   : Sample(1) ]

EncodeExecutionFlags2(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.exCumDividend

DecodeExecutionFlags2(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(tradingMode.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    Ok([ marketMechanism |-> marketMechanism.value,
         tradingMode     |-> tradingMode.value,
         exCumDividend   |-> exCumDividend.value ], exCumDividend.rest)

ZeroExecutionFlags2 ==
    [ marketMechanism |-> [i \in 1 .. 1 |-> 0],
      tradingMode     |-> [i \in 1 .. 1 |-> 0],
      exCumDividend   |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Flags at zero, then each field in turn at the values it is checked at *)
CheckedExecutionFlags2 ==
    { ZeroExecutionFlags2 }
        \cup { [ZeroExecutionFlags2 EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags2 EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionFlags2 EXCEPT !.exCumDividend = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed At Price Size Message: 39 bytes                          *)
(***************************************************************************)

OrderExecutedAtPriceSizeMessage ==
    [ timeOffset      : Sample(4),
      orderId         : Sample(8),
      executedShares  : Sample(4),
      remainingShares : Sample(4),
      executionId     : Sample(8),
      priceLong       : Sample(8),
      executionFlags  : ExecutionFlags2 ]

EncodeOrderExecutedAtPriceSizeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.executedShares
        \o message.remainingShares
        \o message.executionId
        \o message.priceLong
        \o EncodeExecutionFlags2(message.executionFlags)

DecodeOrderExecutedAtPriceSizeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderId.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET remainingShares == ReadBytes(executedShares.rest, 4) IN IF ~remainingShares.ok THEN Fail ELSE
    LET executionId == ReadBytes(remainingShares.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(executionId.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionFlags == DecodeExecutionFlags2(priceLong.rest) IN IF ~executionFlags.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         orderId         |-> orderId.value,
         executedShares  |-> executedShares.value,
         remainingShares |-> remainingShares.value,
         executionId     |-> executionId.value,
         priceLong       |-> priceLong.value,
         executionFlags  |-> executionFlags.value ], executionFlags.rest)

ZeroOrderExecutedAtPriceSizeMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      executedShares  |-> [i \in 1 .. 4 |-> 0],
      remainingShares |-> [i \in 1 .. 4 |-> 0],
      executionId     |-> [i \in 1 .. 8 |-> 0],
      priceLong       |-> [i \in 1 .. 8 |-> 0],
      executionFlags  |-> ZeroExecutionFlags2 ]

(* Order Executed At Price Size Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAtPriceSizeMessage ==
    { ZeroOrderExecutedAtPriceSizeMessage }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.remainingShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedAtPriceSizeMessage EXCEPT !.executionFlags = one] : one \in CheckedExecutionFlags2 }

(***************************************************************************)
(* Reduce Size Long Message: 16 bytes                                      *)
(***************************************************************************)

ReduceSizeLongMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      cancelledSharesLong : Sample(4) ]

EncodeReduceSizeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.cancelledSharesLong

DecodeReduceSizeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledSharesLong == ReadBytes(orderId.rest, 4) IN IF ~cancelledSharesLong.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         cancelledSharesLong |-> cancelledSharesLong.value ], cancelledSharesLong.rest)

ZeroReduceSizeLongMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      cancelledSharesLong |-> [i \in 1 .. 4 |-> 0] ]

(* Reduce Size Long Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeLongMessage ==
    { ZeroReduceSizeLongMessage }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeLongMessage EXCEPT !.cancelledSharesLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Reduce Size Short Message: 14 bytes                                     *)
(***************************************************************************)

ReduceSizeShortMessage ==
    [ timeOffset           : Sample(4),
      orderId              : Sample(8),
      cancelledSharesShort : Sample(2) ]

EncodeReduceSizeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.cancelledSharesShort

DecodeReduceSizeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelledSharesShort == ReadBytes(orderId.rest, 2) IN IF ~cancelledSharesShort.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         orderId              |-> orderId.value,
         cancelledSharesShort |-> cancelledSharesShort.value ], cancelledSharesShort.rest)

ZeroReduceSizeShortMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      cancelledSharesShort |-> [i \in 1 .. 2 |-> 0] ]

(* Reduce Size Short Message at zero, then each field in turn at the values it is checked at *)
CheckedReduceSizeShortMessage ==
    { ZeroReduceSizeShortMessage }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroReduceSizeShortMessage EXCEPT !.cancelledSharesShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Modify Order Long Message: 24 bytes                                     *)
(***************************************************************************)

ModifyOrderLongMessage ==
    [ timeOffset : Sample(4),
      orderId    : Sample(8),
      sharesLong : Sample(4),
      priceLong  : Sample(8) ]

EncodeModifyOrderLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sharesLong
        \o message.priceLong

DecodeModifyOrderLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(orderId.rest, 4) IN IF ~sharesLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(sharesLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         orderId    |-> orderId.value,
         sharesLong |-> sharesLong.value,
         priceLong  |-> priceLong.value ], priceLong.rest)

ZeroModifyOrderLongMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0],
      sharesLong |-> [i \in 1 .. 4 |-> 0],
      priceLong  |-> [i \in 1 .. 8 |-> 0] ]

(* Modify Order Long Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderLongMessage ==
    { ZeroModifyOrderLongMessage }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.sharesLong = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }

(***************************************************************************)
(* Modify Order Short Message: 16 bytes                                    *)
(***************************************************************************)

ModifyOrderShortMessage ==
    [ timeOffset  : Sample(4),
      orderId     : Sample(8),
      sharesShort : Sample(2),
      priceShort  : Sample(2) ]

EncodeModifyOrderShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sharesShort
        \o message.priceShort

DecodeModifyOrderShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(orderId.rest, 2) IN IF ~sharesShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(sharesShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         orderId     |-> orderId.value,
         sharesShort |-> sharesShort.value,
         priceShort  |-> priceShort.value ], priceShort.rest)

ZeroModifyOrderShortMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      sharesShort |-> [i \in 1 .. 2 |-> 0],
      priceShort  |-> [i \in 1 .. 2 |-> 0] ]

(* Modify Order Short Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderShortMessage ==
    { ZeroModifyOrderShortMessage }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderShortMessage EXCEPT !.sharesShort = one] : one \in Sample(2) }
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
(* Trade Flags: 4 bytes                                                    *)
(***************************************************************************)

TradeFlags ==
    [ marketMechanism     : Sample(1),
      tradingMode         : Sample(1),
      transactionCategory : Sample(1),
      exCumDividend       : Sample(1) ]

EncodeTradeFlags(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.exCumDividend

DecodeTradeFlags(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(transactionCategory.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    Ok([ marketMechanism     |-> marketMechanism.value,
         tradingMode         |-> tradingMode.value,
         transactionCategory |-> transactionCategory.value,
         exCumDividend       |-> exCumDividend.value ], exCumDividend.rest)

ZeroTradeFlags ==
    [ marketMechanism     |-> [i \in 1 .. 1 |-> 0],
      tradingMode         |-> [i \in 1 .. 1 |-> 0],
      transactionCategory |-> [i \in 1 .. 1 |-> 0],
      exCumDividend       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedTradeFlags ==
    { ZeroTradeFlags }
        \cup { [ZeroTradeFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags EXCEPT !.exCumDividend = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Long Message: 45 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset    : Sample(4),
      orderId       : Sample(8),
      sideIndicator : Sample(1),
      sharesLong    : Sample(4),
      symbolShort   : Sample(8),
      priceLong     : Sample(8),
      executionId   : Sample(8),
      tradeFlags    : TradeFlags ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.sharesLong
        \o message.symbolShort
        \o message.priceLong
        \o message.executionId
        \o EncodeTradeFlags(message.tradeFlags)

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(sideIndicator.rest, 4) IN IF ~sharesLong.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(sharesLong.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == DecodeTradeFlags(executionId.rest) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset    |-> timeOffset.value,
         orderId       |-> orderId.value,
         sideIndicator |-> sideIndicator.value,
         sharesLong    |-> sharesLong.value,
         symbolShort   |-> symbolShort.value,
         priceLong     |-> priceLong.value,
         executionId   |-> executionId.value,
         tradeFlags    |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeLongMessage ==
    [ timeOffset    |-> [i \in 1 .. 4 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      sideIndicator |-> [i \in 1 .. 1 |-> 0],
      sharesLong    |-> [i \in 1 .. 4 |-> 0],
      symbolShort   |-> [i \in 1 .. 8 |-> 0],
      priceLong     |-> [i \in 1 .. 8 |-> 0],
      executionId   |-> [i \in 1 .. 8 |-> 0],
      tradeFlags    |-> ZeroTradeFlags ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sharesLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeFlags = one] : one \in CheckedTradeFlags }

(***************************************************************************)
(* Trade Flags: 4 bytes                                                    *)
(***************************************************************************)

TradeFlags2 ==
    [ marketMechanism     : Sample(1),
      tradingMode         : Sample(1),
      transactionCategory : Sample(1),
      exCumDividend       : Sample(1) ]

EncodeTradeFlags2(message) ==
    message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.exCumDividend

DecodeTradeFlags2(bytes) ==
    LET marketMechanism == ReadBytes(bytes, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(transactionCategory.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    Ok([ marketMechanism     |-> marketMechanism.value,
         tradingMode         |-> tradingMode.value,
         transactionCategory |-> transactionCategory.value,
         exCumDividend       |-> exCumDividend.value ], exCumDividend.rest)

ZeroTradeFlags2 ==
    [ marketMechanism     |-> [i \in 1 .. 1 |-> 0],
      tradingMode         |-> [i \in 1 .. 1 |-> 0],
      transactionCategory |-> [i \in 1 .. 1 |-> 0],
      exCumDividend       |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedTradeFlags2 ==
    { ZeroTradeFlags2 }
        \cup { [ZeroTradeFlags2 EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeFlags2 EXCEPT !.exCumDividend = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 35 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset          : Sample(4),
      orderId             : Sample(8),
      sideIndicator       : Sample(1),
      sharesShort         : Sample(2),
      symbolAlphanumeric6 : Sample(6),
      priceShort          : Sample(2),
      executionId         : Sample(8),
      tradeFlags          : TradeFlags2 ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.sharesShort
        \o message.symbolAlphanumeric6
        \o message.priceShort
        \o message.executionId
        \o EncodeTradeFlags2(message.tradeFlags)

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET sharesShort == ReadBytes(sideIndicator.rest, 2) IN IF ~sharesShort.ok THEN Fail ELSE
    LET symbolAlphanumeric6 == ReadBytes(sharesShort.rest, 6) IN IF ~symbolAlphanumeric6.ok THEN Fail ELSE
    LET priceShort == ReadBytes(symbolAlphanumeric6.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeFlags == DecodeTradeFlags2(executionId.rest) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         orderId             |-> orderId.value,
         sideIndicator       |-> sideIndicator.value,
         sharesShort         |-> sharesShort.value,
         symbolAlphanumeric6 |-> symbolAlphanumeric6.value,
         priceShort          |-> priceShort.value,
         executionId         |-> executionId.value,
         tradeFlags          |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeShortMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      orderId             |-> [i \in 1 .. 8 |-> 0],
      sideIndicator       |-> [i \in 1 .. 1 |-> 0],
      sharesShort         |-> [i \in 1 .. 2 |-> 0],
      symbolAlphanumeric6 |-> [i \in 1 .. 6 |-> 0],
      priceShort          |-> [i \in 1 .. 2 |-> 0],
      executionId         |-> [i \in 1 .. 8 |-> 0],
      tradeFlags          |-> ZeroTradeFlags2 ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sharesShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.symbolAlphanumeric6 = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeFlags = one] : one \in CheckedTradeFlags2 }

(***************************************************************************)
(* Extended Trade Flags: 11 bytes                                          *)
(***************************************************************************)

ExtendedTradeFlags ==
    [ batsTradeTimingIndicator  : Sample(1),
      marketMechanism           : Sample(1),
      tradingMode               : Sample(1),
      transactionCategory       : Sample(1),
      negotiatedTrade           : Sample(1),
      crossingTrade             : Sample(1),
      modificationIndicator     : Sample(1),
      benchmarkIndicator        : Sample(1),
      exCumDividend             : Sample(1),
      publicationMode           : Sample(1),
      offBookAutomatedIndicator : Sample(1) ]

EncodeExtendedTradeFlags(message) ==
    message.batsTradeTimingIndicator
        \o message.marketMechanism
        \o message.tradingMode
        \o message.transactionCategory
        \o message.negotiatedTrade
        \o message.crossingTrade
        \o message.modificationIndicator
        \o message.benchmarkIndicator
        \o message.exCumDividend
        \o message.publicationMode
        \o message.offBookAutomatedIndicator

DecodeExtendedTradeFlags(bytes) ==
    LET batsTradeTimingIndicator == ReadBytes(bytes, 1) IN IF ~batsTradeTimingIndicator.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(batsTradeTimingIndicator.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(marketMechanism.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET negotiatedTrade == ReadBytes(transactionCategory.rest, 1) IN IF ~negotiatedTrade.ok THEN Fail ELSE
    LET crossingTrade == ReadBytes(negotiatedTrade.rest, 1) IN IF ~crossingTrade.ok THEN Fail ELSE
    LET modificationIndicator == ReadBytes(crossingTrade.rest, 1) IN IF ~modificationIndicator.ok THEN Fail ELSE
    LET benchmarkIndicator == ReadBytes(modificationIndicator.rest, 1) IN IF ~benchmarkIndicator.ok THEN Fail ELSE
    LET exCumDividend == ReadBytes(benchmarkIndicator.rest, 1) IN IF ~exCumDividend.ok THEN Fail ELSE
    LET publicationMode == ReadBytes(exCumDividend.rest, 1) IN IF ~publicationMode.ok THEN Fail ELSE
    LET offBookAutomatedIndicator == ReadBytes(publicationMode.rest, 1) IN IF ~offBookAutomatedIndicator.ok THEN Fail ELSE
    Ok([ batsTradeTimingIndicator  |-> batsTradeTimingIndicator.value,
         marketMechanism           |-> marketMechanism.value,
         tradingMode               |-> tradingMode.value,
         transactionCategory       |-> transactionCategory.value,
         negotiatedTrade           |-> negotiatedTrade.value,
         crossingTrade             |-> crossingTrade.value,
         modificationIndicator     |-> modificationIndicator.value,
         benchmarkIndicator        |-> benchmarkIndicator.value,
         exCumDividend             |-> exCumDividend.value,
         publicationMode           |-> publicationMode.value,
         offBookAutomatedIndicator |-> offBookAutomatedIndicator.value ], offBookAutomatedIndicator.rest)

ZeroExtendedTradeFlags ==
    [ batsTradeTimingIndicator  |-> [i \in 1 .. 1 |-> 0],
      marketMechanism           |-> [i \in 1 .. 1 |-> 0],
      tradingMode               |-> [i \in 1 .. 1 |-> 0],
      transactionCategory       |-> [i \in 1 .. 1 |-> 0],
      negotiatedTrade           |-> [i \in 1 .. 1 |-> 0],
      crossingTrade             |-> [i \in 1 .. 1 |-> 0],
      modificationIndicator     |-> [i \in 1 .. 1 |-> 0],
      benchmarkIndicator        |-> [i \in 1 .. 1 |-> 0],
      exCumDividend             |-> [i \in 1 .. 1 |-> 0],
      publicationMode           |-> [i \in 1 .. 1 |-> 0],
      offBookAutomatedIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Extended Trade Flags at zero, then each field in turn at the values it is checked at *)
CheckedExtendedTradeFlags ==
    { ZeroExtendedTradeFlags }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.batsTradeTimingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.negotiatedTrade = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.crossingTrade = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.modificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.benchmarkIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.exCumDividend = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.publicationMode = one] : one \in Sample(1) }
        \cup { [ZeroExtendedTradeFlags EXCEPT !.offBookAutomatedIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Extended Message: 62 bytes                                        *)
(***************************************************************************)

TradeExtendedMessage ==
    [ timeOffset         : Sample(4),
      sharesExtended     : Sample(8),
      symbolShort        : Sample(8),
      priceLong          : Sample(8),
      tradeId            : Sample(8),
      tradeTimestamp     : Sample(8),
      executionVenue     : Sample(4),
      currency           : Sample(3),
      extendedTradeFlags : ExtendedTradeFlags ]

EncodeTradeExtendedMessage(message) ==
    message.timeOffset
        \o message.sharesExtended
        \o message.symbolShort
        \o message.priceLong
        \o message.tradeId
        \o message.tradeTimestamp
        \o message.executionVenue
        \o message.currency
        \o EncodeExtendedTradeFlags(message.extendedTradeFlags)

DecodeTradeExtendedMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET sharesExtended == ReadBytes(timeOffset.rest, 8) IN IF ~sharesExtended.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(sharesExtended.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET tradeId == ReadBytes(priceLong.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeTimestamp == ReadBytes(tradeId.rest, 8) IN IF ~tradeTimestamp.ok THEN Fail ELSE
    LET executionVenue == ReadBytes(tradeTimestamp.rest, 4) IN IF ~executionVenue.ok THEN Fail ELSE
    LET currency == ReadBytes(executionVenue.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET extendedTradeFlags == DecodeExtendedTradeFlags(currency.rest) IN IF ~extendedTradeFlags.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         sharesExtended     |-> sharesExtended.value,
         symbolShort        |-> symbolShort.value,
         priceLong          |-> priceLong.value,
         tradeId            |-> tradeId.value,
         tradeTimestamp     |-> tradeTimestamp.value,
         executionVenue     |-> executionVenue.value,
         currency           |-> currency.value,
         extendedTradeFlags |-> extendedTradeFlags.value ], extendedTradeFlags.rest)

ZeroTradeExtendedMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      sharesExtended     |-> [i \in 1 .. 8 |-> 0],
      symbolShort        |-> [i \in 1 .. 8 |-> 0],
      priceLong          |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0],
      tradeTimestamp     |-> [i \in 1 .. 8 |-> 0],
      executionVenue     |-> [i \in 1 .. 4 |-> 0],
      currency           |-> [i \in 1 .. 3 |-> 0],
      extendedTradeFlags |-> ZeroExtendedTradeFlags ]

(* Trade Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeExtendedMessage ==
    { ZeroTradeExtendedMessage }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.sharesExtended = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.tradeTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.executionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeExtendedMessage EXCEPT !.extendedTradeFlags = one] : one \in CheckedExtendedTradeFlags }

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
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timeOffset : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timeOffset

DecodeEndOfSessionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEndOfSessionMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset  : Sample(4),
      symbolShort : Sample(8),
      status      : Sample(1),
      reserved3   : Sample(3) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbolShort
        \o message.status
        \o message.reserved3

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timeOffset.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET status == ReadBytes(symbolShort.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(status.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         symbolShort |-> symbolShort.value,
         status      |-> status.value,
         reserved3   |-> reserved3.value ], reserved3.rest)

ZeroTradingStatusMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      symbolShort |-> [i \in 1 .. 8 |-> 0],
      status      |-> [i \in 1 .. 1 |-> 0],
      reserved3   |-> [i \in 1 .. 3 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Statistics Message: 22 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ timeOffset         : Sample(4),
      symbolShort        : Sample(8),
      priceLong          : Sample(8),
      statisticType      : Sample(1),
      priceDetermination : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.timeOffset
        \o message.symbolShort
        \o message.priceLong
        \o message.statisticType
        \o message.priceDetermination

DecodeStatisticsMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timeOffset.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET priceLong == ReadBytes(symbolShort.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET statisticType == ReadBytes(priceLong.rest, 1) IN IF ~statisticType.ok THEN Fail ELSE
    LET priceDetermination == ReadBytes(statisticType.rest, 1) IN IF ~priceDetermination.ok THEN Fail ELSE
    Ok([ timeOffset         |-> timeOffset.value,
         symbolShort        |-> symbolShort.value,
         priceLong          |-> priceLong.value,
         statisticType      |-> statisticType.value,
         priceDetermination |-> priceDetermination.value ], priceDetermination.rest)

ZeroStatisticsMessage ==
    [ timeOffset         |-> [i \in 1 .. 4 |-> 0],
      symbolShort        |-> [i \in 1 .. 8 |-> 0],
      priceLong          |-> [i \in 1 .. 8 |-> 0],
      statisticType      |-> [i \in 1 .. 1 |-> 0],
      priceDetermination |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticType = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.priceDetermination = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update Message: 35 bytes                                        *)
(***************************************************************************)

AuctionUpdateMessage ==
    [ timeOffset       : Sample(4),
      symbolShort      : Sample(8),
      auctionType      : Sample(1),
      referencePrice   : Sample(8),
      indicativePrice  : Sample(8),
      indicativeShares : Sample(4),
      outsideTolerance : Sample(1),
      includesPrimary  : Sample(1) ]

EncodeAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.symbolShort
        \o message.auctionType
        \o message.referencePrice
        \o message.indicativePrice
        \o message.indicativeShares
        \o message.outsideTolerance
        \o message.includesPrimary

DecodeAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timeOffset.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolShort.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(referencePrice.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET indicativeShares == ReadBytes(indicativePrice.rest, 4) IN IF ~indicativeShares.ok THEN Fail ELSE
    LET outsideTolerance == ReadBytes(indicativeShares.rest, 1) IN IF ~outsideTolerance.ok THEN Fail ELSE
    LET includesPrimary == ReadBytes(outsideTolerance.rest, 1) IN IF ~includesPrimary.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbolShort      |-> symbolShort.value,
         auctionType      |-> auctionType.value,
         referencePrice   |-> referencePrice.value,
         indicativePrice  |-> indicativePrice.value,
         indicativeShares |-> indicativeShares.value,
         outsideTolerance |-> outsideTolerance.value,
         includesPrimary  |-> includesPrimary.value ], includesPrimary.rest)

ZeroAuctionUpdateMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbolShort      |-> [i \in 1 .. 8 |-> 0],
      auctionType      |-> [i \in 1 .. 1 |-> 0],
      referencePrice   |-> [i \in 1 .. 8 |-> 0],
      indicativePrice  |-> [i \in 1 .. 8 |-> 0],
      indicativeShares |-> [i \in 1 .. 4 |-> 0],
      outsideTolerance |-> [i \in 1 .. 1 |-> 0],
      includesPrimary  |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdateMessage ==
    { ZeroAuctionUpdateMessage }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.indicativeShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.outsideTolerance = one] : one \in Sample(1) }
        \cup { [ZeroAuctionUpdateMessage EXCEPT !.includesPrimary = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset  : Sample(4),
      symbolShort : Sample(8),
      auctionType : Sample(1),
      priceLong   : Sample(8),
      sharesLong  : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.symbolShort
        \o message.auctionType
        \o message.priceLong
        \o message.sharesLong

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolShort == ReadBytes(timeOffset.rest, 8) IN IF ~symbolShort.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolShort.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(auctionType.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET sharesLong == ReadBytes(priceLong.rest, 4) IN IF ~sharesLong.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         symbolShort |-> symbolShort.value,
         auctionType |-> auctionType.value,
         priceLong   |-> priceLong.value,
         sharesLong  |-> sharesLong.value ], sharesLong.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      symbolShort |-> [i \in 1 .. 8 |-> 0],
      auctionType |-> [i \in 1 .. 1 |-> 0],
      priceLong   |-> [i \in 1 .. 8 |-> 0],
      sharesLong  |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolShort = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sharesLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
AddOrderLongMessageCode == 64  \* 0x40
AddOrderShortMessageCode == 34  \* 0x22
AddOrderExpandedMessageCode == 47  \* 0x2f
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
TradeBreakMessageCode == 44  \* 0x2c
EndOfSessionMessageCode == 45  \* 0x2d
TradingStatusMessageCode == 49  \* 0x31
StatisticsMessageCode == 52  \* 0x34
AuctionUpdateMessageCode == 172  \* 0xac
AuctionSummaryMessageCode == 150  \* 0x96

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {AddOrderLongMessageCode}, body : AddOrderLongMessage ]
        \cup [ tag : {AddOrderShortMessageCode}, body : AddOrderShortMessage ]
        \cup [ tag : {AddOrderExpandedMessageCode}, body : AddOrderExpandedMessage ]
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
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {AuctionUpdateMessageCode}, body : AuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = AddOrderLongMessageCode -> EncodeAddOrderLongMessage(message.body)
      [] message.tag = AddOrderShortMessageCode -> EncodeAddOrderShortMessage(message.body)
      [] message.tag = AddOrderExpandedMessageCode -> EncodeAddOrderExpandedMessage(message.body)
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
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = AuctionUpdateMessageCode -> EncodeAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = AddOrderLongMessageCode -> DecodeAddOrderLongMessage(bytes)
              [] tag = AddOrderShortMessageCode -> DecodeAddOrderShortMessage(bytes)
              [] tag = AddOrderExpandedMessageCode -> DecodeAddOrderExpandedMessage(bytes)
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
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = AuctionUpdateMessageCode -> DecodeAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> AddOrderLongMessageCode, body |-> one] : one \in CheckedAddOrderLongMessage }
        \cup { [tag |-> AddOrderShortMessageCode, body |-> one] : one \in CheckedAddOrderShortMessage }
        \cup { [tag |-> AddOrderExpandedMessageCode, body |-> one] : one \in CheckedAddOrderExpandedMessage }
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
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> AuctionUpdateMessageCode, body |-> one] : one \in CheckedAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderExpandedMessageCode, body |-> ZeroAddOrderExpandedMessage]],
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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateMessageCode, body |-> ZeroAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]] }

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

(* Every Add Order Expanded Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderExpandedMessage ==
    \A message \in CheckedAddOrderExpandedMessage :
        LET read == DecodeAddOrderExpandedMessage(EncodeAddOrderExpandedMessage(message))
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

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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

(* Every Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsMessage ==
    \A message \in CheckedStatisticsMessage :
        LET read == DecodeStatisticsMessage(EncodeStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdateMessage ==
    \A message \in CheckedAuctionUpdateMessage :
        LET read == DecodeAuctionUpdateMessage(EncodeAuctionUpdateMessage(message))
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
