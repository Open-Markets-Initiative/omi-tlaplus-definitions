--------------- MODULE C2Options_MulticastTop_Pitch_v1_2_64 ----------------
(***************************************************************************)
(* Chicago Board Options Exchange Multicast Top v1.2.64                    *)
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
(* Note: Bit Fields is a bit field set, checked as its 1 byte rather than  *)
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
(* Symbol Mapping Message: 36 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8) ]

EncodeSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying

DecodeSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value ], underlying.rest)

ZeroSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Side Update Expanded Short Message: 18 bytes                     *)
(***************************************************************************)

SingleSideUpdateExpandedShortMessage ==
    [ timeOffset            : Sample(4),
      symbol                : Sample(6),
      side                  : Sample(1),
      bitFields             : Sample(1),
      priceShort            : Sample(2),
      quantityShort         : Sample(2),
      customerQuantityShort : Sample(2) ]

EncodeSingleSideUpdateExpandedShortMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.side
        \o message.bitFields
        \o message.priceShort
        \o message.quantityShort
        \o message.customerQuantityShort

DecodeSingleSideUpdateExpandedShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET side == ReadBytes(symbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET bitFields == ReadBytes(side.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    LET priceShort == ReadBytes(bitFields.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(priceShort.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET customerQuantityShort == ReadBytes(quantityShort.rest, 2) IN IF ~customerQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         symbol                |-> symbol.value,
         side                  |-> side.value,
         bitFields             |-> bitFields.value,
         priceShort            |-> priceShort.value,
         quantityShort         |-> quantityShort.value,
         customerQuantityShort |-> customerQuantityShort.value ], customerQuantityShort.rest)

ZeroSingleSideUpdateExpandedShortMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 6 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      bitFields             |-> [i \in 1 .. 1 |-> 0],
      priceShort            |-> [i \in 1 .. 2 |-> 0],
      quantityShort         |-> [i \in 1 .. 2 |-> 0],
      customerQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Update Expanded Short Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateExpandedShortMessage ==
    { ZeroSingleSideUpdateExpandedShortMessage }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.bitFields = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideUpdateExpandedShortMessage EXCEPT !.customerQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Single Side Update Expanded Long Message: 28 bytes                      *)
(***************************************************************************)

SingleSideUpdateExpandedLongMessage ==
    [ timeOffset           : Sample(4),
      symbol               : Sample(6),
      side                 : Sample(1),
      bitFields            : Sample(1),
      priceLong            : Sample(8),
      quantityLong         : Sample(4),
      customerQuantityLong : Sample(4) ]

EncodeSingleSideUpdateExpandedLongMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.side
        \o message.bitFields
        \o message.priceLong
        \o message.quantityLong
        \o message.customerQuantityLong

DecodeSingleSideUpdateExpandedLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET side == ReadBytes(symbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET bitFields == ReadBytes(side.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    LET priceLong == ReadBytes(bitFields.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(priceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET customerQuantityLong == ReadBytes(quantityLong.rest, 4) IN IF ~customerQuantityLong.ok THEN Fail ELSE
    Ok([ timeOffset           |-> timeOffset.value,
         symbol               |-> symbol.value,
         side                 |-> side.value,
         bitFields            |-> bitFields.value,
         priceLong            |-> priceLong.value,
         quantityLong         |-> quantityLong.value,
         customerQuantityLong |-> customerQuantityLong.value ], customerQuantityLong.rest)

ZeroSingleSideUpdateExpandedLongMessage ==
    [ timeOffset           |-> [i \in 1 .. 4 |-> 0],
      symbol               |-> [i \in 1 .. 6 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      bitFields            |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 8 |-> 0],
      quantityLong         |-> [i \in 1 .. 4 |-> 0],
      customerQuantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Update Expanded Long Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideUpdateExpandedLongMessage ==
    { ZeroSingleSideUpdateExpandedLongMessage }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.bitFields = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideUpdateExpandedLongMessage EXCEPT !.customerQuantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Two Side Update Expanded Short Message: 23 bytes                        *)
(***************************************************************************)

TwoSideUpdateExpandedShortMessage ==
    [ timeOffset               : Sample(4),
      symbol                   : Sample(6),
      bitFields                : Sample(1),
      bidPriceShort            : Sample(2),
      bidQuantityShort         : Sample(2),
      bidCustomerQuantityShort : Sample(2),
      askPriceShort            : Sample(2),
      askQuantityShort         : Sample(2),
      askCustomerQuantityShort : Sample(2) ]

EncodeTwoSideUpdateExpandedShortMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.bitFields
        \o message.bidPriceShort
        \o message.bidQuantityShort
        \o message.bidCustomerQuantityShort
        \o message.askPriceShort
        \o message.askQuantityShort
        \o message.askCustomerQuantityShort

DecodeTwoSideUpdateExpandedShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET bitFields == ReadBytes(symbol.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(bitFields.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidQuantityShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidQuantityShort.ok THEN Fail ELSE
    LET bidCustomerQuantityShort == ReadBytes(bidQuantityShort.rest, 2) IN IF ~bidCustomerQuantityShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidCustomerQuantityShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askQuantityShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askQuantityShort.ok THEN Fail ELSE
    LET askCustomerQuantityShort == ReadBytes(askQuantityShort.rest, 2) IN IF ~askCustomerQuantityShort.ok THEN Fail ELSE
    Ok([ timeOffset               |-> timeOffset.value,
         symbol                   |-> symbol.value,
         bitFields                |-> bitFields.value,
         bidPriceShort            |-> bidPriceShort.value,
         bidQuantityShort         |-> bidQuantityShort.value,
         bidCustomerQuantityShort |-> bidCustomerQuantityShort.value,
         askPriceShort            |-> askPriceShort.value,
         askQuantityShort         |-> askQuantityShort.value,
         askCustomerQuantityShort |-> askCustomerQuantityShort.value ], askCustomerQuantityShort.rest)

ZeroTwoSideUpdateExpandedShortMessage ==
    [ timeOffset               |-> [i \in 1 .. 4 |-> 0],
      symbol                   |-> [i \in 1 .. 6 |-> 0],
      bitFields                |-> [i \in 1 .. 1 |-> 0],
      bidPriceShort            |-> [i \in 1 .. 2 |-> 0],
      bidQuantityShort         |-> [i \in 1 .. 2 |-> 0],
      bidCustomerQuantityShort |-> [i \in 1 .. 2 |-> 0],
      askPriceShort            |-> [i \in 1 .. 2 |-> 0],
      askQuantityShort         |-> [i \in 1 .. 2 |-> 0],
      askCustomerQuantityShort |-> [i \in 1 .. 2 |-> 0] ]

(* Two Side Update Expanded Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTwoSideUpdateExpandedShortMessage ==
    { ZeroTwoSideUpdateExpandedShortMessage }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.bitFields = one] : one \in Sample(1) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.bidQuantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.bidCustomerQuantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.askQuantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTwoSideUpdateExpandedShortMessage EXCEPT !.askCustomerQuantityShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Two Side Update Expanded Long Message: 43 bytes                         *)
(***************************************************************************)

TwoSideUpdateExpandedLongMessage ==
    [ timeOffset              : Sample(4),
      symbol                  : Sample(6),
      bitFields               : Sample(1),
      bidPriceLong            : Sample(8),
      bidQuantityLong         : Sample(4),
      bidCustomerQuantityLong : Sample(4),
      askPriceLong            : Sample(8),
      askQuantityLong         : Sample(4),
      askCustomerQuantityLong : Sample(4) ]

EncodeTwoSideUpdateExpandedLongMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.bitFields
        \o message.bidPriceLong
        \o message.bidQuantityLong
        \o message.bidCustomerQuantityLong
        \o message.askPriceLong
        \o message.askQuantityLong
        \o message.askCustomerQuantityLong

DecodeTwoSideUpdateExpandedLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET bitFields == ReadBytes(symbol.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(bitFields.rest, 8) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidQuantityLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidQuantityLong.ok THEN Fail ELSE
    LET bidCustomerQuantityLong == ReadBytes(bidQuantityLong.rest, 4) IN IF ~bidCustomerQuantityLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidCustomerQuantityLong.rest, 8) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askQuantityLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askQuantityLong.ok THEN Fail ELSE
    LET askCustomerQuantityLong == ReadBytes(askQuantityLong.rest, 4) IN IF ~askCustomerQuantityLong.ok THEN Fail ELSE
    Ok([ timeOffset              |-> timeOffset.value,
         symbol                  |-> symbol.value,
         bitFields               |-> bitFields.value,
         bidPriceLong            |-> bidPriceLong.value,
         bidQuantityLong         |-> bidQuantityLong.value,
         bidCustomerQuantityLong |-> bidCustomerQuantityLong.value,
         askPriceLong            |-> askPriceLong.value,
         askQuantityLong         |-> askQuantityLong.value,
         askCustomerQuantityLong |-> askCustomerQuantityLong.value ], askCustomerQuantityLong.rest)

ZeroTwoSideUpdateExpandedLongMessage ==
    [ timeOffset              |-> [i \in 1 .. 4 |-> 0],
      symbol                  |-> [i \in 1 .. 6 |-> 0],
      bitFields               |-> [i \in 1 .. 1 |-> 0],
      bidPriceLong            |-> [i \in 1 .. 8 |-> 0],
      bidQuantityLong         |-> [i \in 1 .. 4 |-> 0],
      bidCustomerQuantityLong |-> [i \in 1 .. 4 |-> 0],
      askPriceLong            |-> [i \in 1 .. 8 |-> 0],
      askQuantityLong         |-> [i \in 1 .. 4 |-> 0],
      askCustomerQuantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Two Side Update Expanded Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTwoSideUpdateExpandedLongMessage ==
    { ZeroTwoSideUpdateExpandedLongMessage }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.bitFields = one] : one \in Sample(1) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.bidPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.bidQuantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.bidCustomerQuantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.askPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.askQuantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTwoSideUpdateExpandedLongMessage EXCEPT !.askCustomerQuantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Top Trade Message: 35 bytes                                             *)
(***************************************************************************)

TopTradeMessage ==
    [ timeOffset     : Sample(4),
      symbol         : Sample(6),
      quantityLong   : Sample(4),
      priceLong      : Sample(8),
      executionId    : Sample(8),
      totalVolume    : Sample(4),
      tradeCondition : Sample(1) ]

EncodeTopTradeMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.quantityLong
        \o message.priceLong
        \o message.executionId
        \o message.totalVolume
        \o message.tradeCondition

DecodeTopTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(symbol.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET priceLong == ReadBytes(quantityLong.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(priceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(executionId.rest, 4) IN IF ~totalVolume.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(totalVolume.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset     |-> timeOffset.value,
         symbol         |-> symbol.value,
         quantityLong   |-> quantityLong.value,
         priceLong      |-> priceLong.value,
         executionId    |-> executionId.value,
         totalVolume    |-> totalVolume.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTopTradeMessage ==
    [ timeOffset     |-> [i \in 1 .. 4 |-> 0],
      symbol         |-> [i \in 1 .. 6 |-> 0],
      quantityLong   |-> [i \in 1 .. 4 |-> 0],
      priceLong      |-> [i \in 1 .. 8 |-> 0],
      executionId    |-> [i \in 1 .. 8 |-> 0],
      totalVolume    |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Top Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTopTradeMessage ==
    { ZeroTopTradeMessage }
        \cup { [ZeroTopTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTopTradeMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTopTradeMessage EXCEPT !.totalVolume = one] : one \in Sample(4) }
        \cup { [ZeroTopTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Auction Update Message: 62 bytes                                *)
(***************************************************************************)

OptionsAuctionUpdateMessage ==
    [ timeOffset                : Sample(4),
      expandedSymbol            : Sample(8),
      auctionType               : Sample(1),
      referencePrice            : Sample(8),
      buyContracts              : Sample(4),
      sellContracts             : Sample(4),
      indicativePrice           : Sample(8),
      auctionOnlyPrice          : Sample(8),
      openingCondition          : Sample(1),
      compositeMarketBidPrice   : Sample(8),
      compositeMarketOfferPrice : Sample(8) ]

EncodeOptionsAuctionUpdateMessage(message) ==
    message.timeOffset
        \o message.expandedSymbol
        \o message.auctionType
        \o message.referencePrice
        \o message.buyContracts
        \o message.sellContracts
        \o message.indicativePrice
        \o message.auctionOnlyPrice
        \o message.openingCondition
        \o message.compositeMarketBidPrice
        \o message.compositeMarketOfferPrice

DecodeOptionsAuctionUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET expandedSymbol == ReadBytes(timeOffset.rest, 8) IN IF ~expandedSymbol.ok THEN Fail ELSE
    LET auctionType == ReadBytes(expandedSymbol.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(auctionType.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET buyContracts == ReadBytes(referencePrice.rest, 4) IN IF ~buyContracts.ok THEN Fail ELSE
    LET sellContracts == ReadBytes(buyContracts.rest, 4) IN IF ~sellContracts.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(sellContracts.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET auctionOnlyPrice == ReadBytes(indicativePrice.rest, 8) IN IF ~auctionOnlyPrice.ok THEN Fail ELSE
    LET openingCondition == ReadBytes(auctionOnlyPrice.rest, 1) IN IF ~openingCondition.ok THEN Fail ELSE
    LET compositeMarketBidPrice == ReadBytes(openingCondition.rest, 8) IN IF ~compositeMarketBidPrice.ok THEN Fail ELSE
    LET compositeMarketOfferPrice == ReadBytes(compositeMarketBidPrice.rest, 8) IN IF ~compositeMarketOfferPrice.ok THEN Fail ELSE
    Ok([ timeOffset                |-> timeOffset.value,
         expandedSymbol            |-> expandedSymbol.value,
         auctionType               |-> auctionType.value,
         referencePrice            |-> referencePrice.value,
         buyContracts              |-> buyContracts.value,
         sellContracts             |-> sellContracts.value,
         indicativePrice           |-> indicativePrice.value,
         auctionOnlyPrice          |-> auctionOnlyPrice.value,
         openingCondition          |-> openingCondition.value,
         compositeMarketBidPrice   |-> compositeMarketBidPrice.value,
         compositeMarketOfferPrice |-> compositeMarketOfferPrice.value ], compositeMarketOfferPrice.rest)

ZeroOptionsAuctionUpdateMessage ==
    [ timeOffset                |-> [i \in 1 .. 4 |-> 0],
      expandedSymbol            |-> [i \in 1 .. 8 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      referencePrice            |-> [i \in 1 .. 8 |-> 0],
      buyContracts              |-> [i \in 1 .. 4 |-> 0],
      sellContracts             |-> [i \in 1 .. 4 |-> 0],
      indicativePrice           |-> [i \in 1 .. 8 |-> 0],
      auctionOnlyPrice          |-> [i \in 1 .. 8 |-> 0],
      openingCondition          |-> [i \in 1 .. 1 |-> 0],
      compositeMarketBidPrice   |-> [i \in 1 .. 8 |-> 0],
      compositeMarketOfferPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Options Auction Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsAuctionUpdateMessage ==
    { ZeroOptionsAuctionUpdateMessage }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.expandedSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.buyContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.sellContracts = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.auctionOnlyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.openingCondition = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionUpdateMessage EXCEPT !.compositeMarketOfferPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Summary Message: 25 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ timeOffset   : Sample(4),
      symbolId     : Sample(8),
      auctionType  : Sample(1),
      priceLong    : Sample(8),
      quantityLong : Sample(4) ]

EncodeAuctionSummaryMessage(message) ==
    message.timeOffset
        \o message.symbolId
        \o message.auctionType
        \o message.priceLong
        \o message.quantityLong

DecodeAuctionSummaryMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbolId == ReadBytes(timeOffset.rest, 8) IN IF ~symbolId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(auctionType.rest, 8) IN IF ~priceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(priceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ timeOffset   |-> timeOffset.value,
         symbolId     |-> symbolId.value,
         auctionType  |-> auctionType.value,
         priceLong    |-> priceLong.value,
         quantityLong |-> quantityLong.value ], quantityLong.rest)

ZeroAuctionSummaryMessage ==
    [ timeOffset   |-> [i \in 1 .. 4 |-> 0],
      symbolId     |-> [i \in 1 .. 8 |-> 0],
      auctionType  |-> [i \in 1 .. 1 |-> 0],
      priceLong    |-> [i \in 1 .. 8 |-> 0],
      quantityLong |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.priceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset       : Sample(4),
      symbol           : Sample(6),
      reserved2        : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      secondReserved1  : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.secondReserved1

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(symbol.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(gthTradingStatus.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbol           |-> symbol.value,
         reserved2        |-> reserved2.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         secondReserved1  |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbol           |-> [i \in 1 .. 6 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      secondReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Width Update Message: 17 bytes                                          *)
(***************************************************************************)

WidthUpdateMessage ==
    [ timeOffset : Sample(4),
      underlying : Sample(8),
      widthType  : Sample(1),
      multiplier : Sample(4) ]

EncodeWidthUpdateMessage(message) ==
    message.timeOffset
        \o message.underlying
        \o message.widthType
        \o message.multiplier

DecodeWidthUpdateMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET underlying == ReadBytes(timeOffset.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET widthType == ReadBytes(underlying.rest, 1) IN IF ~widthType.ok THEN Fail ELSE
    LET multiplier == ReadBytes(widthType.rest, 4) IN IF ~multiplier.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         underlying |-> underlying.value,
         widthType  |-> widthType.value,
         multiplier |-> multiplier.value ], multiplier.rest)

ZeroWidthUpdateMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      underlying |-> [i \in 1 .. 8 |-> 0],
      widthType  |-> [i \in 1 .. 1 |-> 0],
      multiplier |-> [i \in 1 .. 4 |-> 0] ]

(* Width Update Message at zero, then each field in turn at the values it is checked at *)
CheckedWidthUpdateMessage ==
    { ZeroWidthUpdateMessage }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.widthType = one] : one \in Sample(1) }
        \cup { [ZeroWidthUpdateMessage EXCEPT !.multiplier = one] : one \in Sample(4) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timestamp : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timestamp

DecodeEndOfSessionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 4) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value ], timestamp.rest)

ZeroEndOfSessionMessage ==
    [ timestamp |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timestamp = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeMessageCode == 32  \* 0x20
UnitClearMessageCode == 151  \* 0x97
SymbolMappingMessageCode == 46  \* 0x2e
SingleSideUpdateExpandedShortMessageCode == 212  \* 0xd4
SingleSideUpdateExpandedLongMessageCode == 213  \* 0xd5
TwoSideUpdateExpandedShortMessageCode == 214  \* 0xd6
TwoSideUpdateExpandedLongMessageCode == 215  \* 0xd7
TopTradeMessageCode == 184  \* 0xb8
OptionsAuctionUpdateMessageCode == 209  \* 0xd1
AuctionSummaryMessageCode == 150  \* 0x96
TradingStatusMessageCode == 49  \* 0x31
WidthUpdateMessageCode == 210  \* 0xd2
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {UnitClearMessageCode}, body : UnitClearMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {SingleSideUpdateExpandedShortMessageCode}, body : SingleSideUpdateExpandedShortMessage ]
        \cup [ tag : {SingleSideUpdateExpandedLongMessageCode}, body : SingleSideUpdateExpandedLongMessage ]
        \cup [ tag : {TwoSideUpdateExpandedShortMessageCode}, body : TwoSideUpdateExpandedShortMessage ]
        \cup [ tag : {TwoSideUpdateExpandedLongMessageCode}, body : TwoSideUpdateExpandedLongMessage ]
        \cup [ tag : {TopTradeMessageCode}, body : TopTradeMessage ]
        \cup [ tag : {OptionsAuctionUpdateMessageCode}, body : OptionsAuctionUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {WidthUpdateMessageCode}, body : WidthUpdateMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = UnitClearMessageCode -> EncodeUnitClearMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = SingleSideUpdateExpandedShortMessageCode -> EncodeSingleSideUpdateExpandedShortMessage(message.body)
      [] message.tag = SingleSideUpdateExpandedLongMessageCode -> EncodeSingleSideUpdateExpandedLongMessage(message.body)
      [] message.tag = TwoSideUpdateExpandedShortMessageCode -> EncodeTwoSideUpdateExpandedShortMessage(message.body)
      [] message.tag = TwoSideUpdateExpandedLongMessageCode -> EncodeTwoSideUpdateExpandedLongMessage(message.body)
      [] message.tag = TopTradeMessageCode -> EncodeTopTradeMessage(message.body)
      [] message.tag = OptionsAuctionUpdateMessageCode -> EncodeOptionsAuctionUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = WidthUpdateMessageCode -> EncodeWidthUpdateMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = UnitClearMessageCode -> DecodeUnitClearMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = SingleSideUpdateExpandedShortMessageCode -> DecodeSingleSideUpdateExpandedShortMessage(bytes)
              [] tag = SingleSideUpdateExpandedLongMessageCode -> DecodeSingleSideUpdateExpandedLongMessage(bytes)
              [] tag = TwoSideUpdateExpandedShortMessageCode -> DecodeTwoSideUpdateExpandedShortMessage(bytes)
              [] tag = TwoSideUpdateExpandedLongMessageCode -> DecodeTwoSideUpdateExpandedLongMessage(bytes)
              [] tag = TopTradeMessageCode -> DecodeTopTradeMessage(bytes)
              [] tag = OptionsAuctionUpdateMessageCode -> DecodeOptionsAuctionUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = WidthUpdateMessageCode -> DecodeWidthUpdateMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> UnitClearMessageCode, body |-> one] : one \in CheckedUnitClearMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> SingleSideUpdateExpandedShortMessageCode, body |-> one] : one \in CheckedSingleSideUpdateExpandedShortMessage }
        \cup { [tag |-> SingleSideUpdateExpandedLongMessageCode, body |-> one] : one \in CheckedSingleSideUpdateExpandedLongMessage }
        \cup { [tag |-> TwoSideUpdateExpandedShortMessageCode, body |-> one] : one \in CheckedTwoSideUpdateExpandedShortMessage }
        \cup { [tag |-> TwoSideUpdateExpandedLongMessageCode, body |-> one] : one \in CheckedTwoSideUpdateExpandedLongMessage }
        \cup { [tag |-> TopTradeMessageCode, body |-> one] : one \in CheckedTopTradeMessage }
        \cup { [tag |-> OptionsAuctionUpdateMessageCode, body |-> one] : one \in CheckedOptionsAuctionUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> WidthUpdateMessageCode, body |-> one] : one \in CheckedWidthUpdateMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideUpdateExpandedShortMessageCode, body |-> ZeroSingleSideUpdateExpandedShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SingleSideUpdateExpandedLongMessageCode, body |-> ZeroSingleSideUpdateExpandedLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TwoSideUpdateExpandedShortMessageCode, body |-> ZeroTwoSideUpdateExpandedShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TwoSideUpdateExpandedLongMessageCode, body |-> ZeroTwoSideUpdateExpandedLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopTradeMessageCode, body |-> ZeroTopTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionsAuctionUpdateMessageCode, body |-> ZeroOptionsAuctionUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WidthUpdateMessageCode, body |-> ZeroWidthUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]] }

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

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Update Expanded Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideUpdateExpandedShortMessage ==
    \A message \in CheckedSingleSideUpdateExpandedShortMessage :
        LET read == DecodeSingleSideUpdateExpandedShortMessage(EncodeSingleSideUpdateExpandedShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Update Expanded Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideUpdateExpandedLongMessage ==
    \A message \in CheckedSingleSideUpdateExpandedLongMessage :
        LET read == DecodeSingleSideUpdateExpandedLongMessage(EncodeSingleSideUpdateExpandedLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Side Update Expanded Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSideUpdateExpandedShortMessage ==
    \A message \in CheckedTwoSideUpdateExpandedShortMessage :
        LET read == DecodeTwoSideUpdateExpandedShortMessage(EncodeTwoSideUpdateExpandedShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Two Side Update Expanded Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwoSideUpdateExpandedLongMessage ==
    \A message \in CheckedTwoSideUpdateExpandedLongMessage :
        LET read == DecodeTwoSideUpdateExpandedLongMessage(EncodeTwoSideUpdateExpandedLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopTradeMessage ==
    \A message \in CheckedTopTradeMessage :
        LET read == DecodeTopTradeMessage(EncodeTopTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Auction Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsAuctionUpdateMessage ==
    \A message \in CheckedOptionsAuctionUpdateMessage :
        LET read == DecodeOptionsAuctionUpdateMessage(EncodeOptionsAuctionUpdateMessage(message))
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

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
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

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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
