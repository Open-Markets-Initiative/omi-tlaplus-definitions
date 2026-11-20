---------------------- MODULE TxseEquities_Feed_v1_0 -----------------------
(***************************************************************************)
(* Texas Stock Exchange FEED Full-Depth Market Data v1.0                   *)
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
(* Note: A field marked present by fields read before it is read only when *)
(* they say it is there, and the records checked hold it exactly where     *)
(* they do: one holding it anywhere else is no message the protocol sends. *)
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

(* A field there only when what was read before it says so: read when it is, and held *)
(* as a sequence of the one value it read, or of none when it is not there. *)
ReadWhen(holds, read, bytes) ==
    IF ~holds
    THEN Ok(<< >>, bytes)
    ELSE IF ~read.ok THEN Fail ELSE Ok(<<read.value>>, read.rest)

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
(* Trading Session Status Message                                          *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ tradingSessionStatusPresenceBits          : 0 .. 255,
      transactTime                              : Sample(8),
      marketHoursState                          : Sample(1),
      sessionTradingState                       : Sample(1),
      tradingSessionStatusOperationalHaltReason : { << >> } \cup { <<held>> : held \in Sample(1) },
      tradingSessionStatusRegulatoryHaltReason  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeTradingSessionStatusMessage(message) ==
    EncodeUIntLE(message.tradingSessionStatusPresenceBits, 1)
        \o message.transactTime
        \o message.marketHoursState
        \o message.sessionTradingState
        \o (IF message.tradingSessionStatusOperationalHaltReason = << >> THEN << >> ELSE message.tradingSessionStatusOperationalHaltReason[1])
        \o (IF message.tradingSessionStatusRegulatoryHaltReason = << >> THEN << >> ELSE message.tradingSessionStatusRegulatoryHaltReason[1])

DecodeTradingSessionStatusMessage(bytes) ==
    LET tradingSessionStatusPresenceBits == ReadUIntLE(bytes, 1) IN IF ~tradingSessionStatusPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradingSessionStatusPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketHoursState == ReadBytes(transactTime.rest, 1) IN IF ~marketHoursState.ok THEN Fail ELSE
    LET sessionTradingState == ReadBytes(marketHoursState.rest, 1) IN IF ~sessionTradingState.ok THEN Fail ELSE
    LET tradingSessionStatusOperationalHaltReason == ReadWhen(tradingSessionStatusPresenceBits.value % 2 = 1, ReadBytes(sessionTradingState.rest, 1), sessionTradingState.rest) IN IF ~tradingSessionStatusOperationalHaltReason.ok THEN Fail ELSE
    LET tradingSessionStatusRegulatoryHaltReason == ReadWhen((tradingSessionStatusPresenceBits.value \div 2) % 2 = 1, ReadBytes(tradingSessionStatusOperationalHaltReason.rest, 1), tradingSessionStatusOperationalHaltReason.rest) IN IF ~tradingSessionStatusRegulatoryHaltReason.ok THEN Fail ELSE
    Ok([ tradingSessionStatusPresenceBits          |-> tradingSessionStatusPresenceBits.value,
         transactTime                              |-> transactTime.value,
         marketHoursState                          |-> marketHoursState.value,
         sessionTradingState                       |-> sessionTradingState.value,
         tradingSessionStatusOperationalHaltReason |-> tradingSessionStatusOperationalHaltReason.value,
         tradingSessionStatusRegulatoryHaltReason  |-> tradingSessionStatusRegulatoryHaltReason.value ], tradingSessionStatusRegulatoryHaltReason.rest)

(* Trading Session Status Message with each field marked present by fields before it there exactly where they say *)
SettleTradingSessionStatusMessage(message) ==
    LET settled1 == [message EXCEPT !.tradingSessionStatusOperationalHaltReason = IF message.tradingSessionStatusPresenceBits % 2 = 1 THEN (IF message.tradingSessionStatusOperationalHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.tradingSessionStatusOperationalHaltReason) ELSE << >>]
        settled2 == [settled1 EXCEPT !.tradingSessionStatusRegulatoryHaltReason = IF (settled1.tradingSessionStatusPresenceBits \div 2) % 2 = 1 THEN (IF settled1.tradingSessionStatusRegulatoryHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.tradingSessionStatusRegulatoryHaltReason) ELSE << >>]
    IN  settled2

ZeroTradingSessionStatusMessage ==
    SettleTradingSessionStatusMessage([ tradingSessionStatusPresenceBits          |-> 0,
                                        transactTime                              |-> [i \in 1 .. 8 |-> 0],
                                        marketHoursState                          |-> [i \in 1 .. 1 |-> 0],
                                        sessionTradingState                       |-> [i \in 1 .. 1 |-> 0],
                                        tradingSessionStatusOperationalHaltReason |-> << >>,
                                        tradingSessionStatusRegulatoryHaltReason  |-> << >> ])

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.marketHoursState = one]) : one \in Sample(1) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.sessionTradingState = one]) : one \in Sample(1) }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = 1, !.tradingSessionStatusOperationalHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleTradingSessionStatusMessage([ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionStatusPresenceBits = 2, !.tradingSessionStatusRegulatoryHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Define Symbol Message: 33 bytes                                         *)
(***************************************************************************)

DefineSymbolMessage ==
    [ transactTime          : Sample(8),
      symbolId              : Sample(2),
      symbol                : Sample(8),
      suffix                : Sample(8),
      matchingEngineId      : Sample(1),
      defineSymbolBitFields : Sample(1),
      lotSize               : Sample(4),
      listingMarket         : Sample(1) ]

EncodeDefineSymbolMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.symbol
        \o message.suffix
        \o message.matchingEngineId
        \o message.defineSymbolBitFields
        \o message.lotSize
        \o message.listingMarket

DecodeDefineSymbolMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbol == ReadBytes(symbolId.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET suffix == ReadBytes(symbol.rest, 8) IN IF ~suffix.ok THEN Fail ELSE
    LET matchingEngineId == ReadBytes(suffix.rest, 1) IN IF ~matchingEngineId.ok THEN Fail ELSE
    LET defineSymbolBitFields == ReadBytes(matchingEngineId.rest, 1) IN IF ~defineSymbolBitFields.ok THEN Fail ELSE
    LET lotSize == ReadBytes(defineSymbolBitFields.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET listingMarket == ReadBytes(lotSize.rest, 1) IN IF ~listingMarket.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         symbolId              |-> symbolId.value,
         symbol                |-> symbol.value,
         suffix                |-> suffix.value,
         matchingEngineId      |-> matchingEngineId.value,
         defineSymbolBitFields |-> defineSymbolBitFields.value,
         lotSize               |-> lotSize.value,
         listingMarket         |-> listingMarket.value ], listingMarket.rest)

ZeroDefineSymbolMessage ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      symbolId              |-> [i \in 1 .. 2 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0],
      suffix                |-> [i \in 1 .. 8 |-> 0],
      matchingEngineId      |-> [i \in 1 .. 1 |-> 0],
      defineSymbolBitFields |-> [i \in 1 .. 1 |-> 0],
      lotSize               |-> [i \in 1 .. 4 |-> 0],
      listingMarket         |-> [i \in 1 .. 1 |-> 0] ]

(* Define Symbol Message at zero, then each field in turn at the values it is checked at *)
CheckedDefineSymbolMessage ==
    { ZeroDefineSymbolMessage }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.suffix = one] : one \in Sample(8) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.matchingEngineId = one] : one \in Sample(1) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.defineSymbolBitFields = one] : one \in Sample(1) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroDefineSymbolMessage EXCEPT !.listingMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Status Message                                                   *)
(***************************************************************************)

SymbolStatusMessage ==
    [ symbolStatusPresenceBits          : 0 .. 255,
      transactTime                      : Sample(8),
      symbolId                          : Sample(2),
      symbolTradingState                : Sample(1),
      shortSaleRestrictionState         : Sample(1),
      symbolStatusOperationalHaltReason : { << >> } \cup { <<held>> : held \in Sample(1) },
      symbolStatusRegulatoryHaltReason  : { << >> } \cup { <<held>> : held \in Sample(1) } ]

EncodeSymbolStatusMessage(message) ==
    EncodeUIntLE(message.symbolStatusPresenceBits, 1)
        \o message.transactTime
        \o message.symbolId
        \o message.symbolTradingState
        \o message.shortSaleRestrictionState
        \o (IF message.symbolStatusOperationalHaltReason = << >> THEN << >> ELSE message.symbolStatusOperationalHaltReason[1])
        \o (IF message.symbolStatusRegulatoryHaltReason = << >> THEN << >> ELSE message.symbolStatusRegulatoryHaltReason[1])

DecodeSymbolStatusMessage(bytes) ==
    LET symbolStatusPresenceBits == ReadUIntLE(bytes, 1) IN IF ~symbolStatusPresenceBits.ok THEN Fail ELSE
    LET transactTime == ReadBytes(symbolStatusPresenceBits.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET symbolTradingState == ReadBytes(symbolId.rest, 1) IN IF ~symbolTradingState.ok THEN Fail ELSE
    LET shortSaleRestrictionState == ReadBytes(symbolTradingState.rest, 1) IN IF ~shortSaleRestrictionState.ok THEN Fail ELSE
    LET symbolStatusOperationalHaltReason == ReadWhen(symbolStatusPresenceBits.value % 2 = 1, ReadBytes(shortSaleRestrictionState.rest, 1), shortSaleRestrictionState.rest) IN IF ~symbolStatusOperationalHaltReason.ok THEN Fail ELSE
    LET symbolStatusRegulatoryHaltReason == ReadWhen((symbolStatusPresenceBits.value \div 2) % 2 = 1, ReadBytes(symbolStatusOperationalHaltReason.rest, 1), symbolStatusOperationalHaltReason.rest) IN IF ~symbolStatusRegulatoryHaltReason.ok THEN Fail ELSE
    Ok([ symbolStatusPresenceBits          |-> symbolStatusPresenceBits.value,
         transactTime                      |-> transactTime.value,
         symbolId                          |-> symbolId.value,
         symbolTradingState                |-> symbolTradingState.value,
         shortSaleRestrictionState         |-> shortSaleRestrictionState.value,
         symbolStatusOperationalHaltReason |-> symbolStatusOperationalHaltReason.value,
         symbolStatusRegulatoryHaltReason  |-> symbolStatusRegulatoryHaltReason.value ], symbolStatusRegulatoryHaltReason.rest)

(* Symbol Status Message with each field marked present by fields before it there exactly where they say *)
SettleSymbolStatusMessage(message) ==
    LET settled1 == [message EXCEPT !.symbolStatusOperationalHaltReason = IF message.symbolStatusPresenceBits % 2 = 1 THEN (IF message.symbolStatusOperationalHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE message.symbolStatusOperationalHaltReason) ELSE << >>]
        settled2 == [settled1 EXCEPT !.symbolStatusRegulatoryHaltReason = IF (settled1.symbolStatusPresenceBits \div 2) % 2 = 1 THEN (IF settled1.symbolStatusRegulatoryHaltReason = << >> THEN <<[i \in 1 .. 1 |-> 0]>> ELSE settled1.symbolStatusRegulatoryHaltReason) ELSE << >>]
    IN  settled2

ZeroSymbolStatusMessage ==
    SettleSymbolStatusMessage([ symbolStatusPresenceBits          |-> 0,
                                transactTime                      |-> [i \in 1 .. 8 |-> 0],
                                symbolId                          |-> [i \in 1 .. 2 |-> 0],
                                symbolTradingState                |-> [i \in 1 .. 1 |-> 0],
                                shortSaleRestrictionState         |-> [i \in 1 .. 1 |-> 0],
                                symbolStatusOperationalHaltReason |-> << >>,
                                symbolStatusRegulatoryHaltReason  |-> << >> ])

(* Symbol Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolStatusMessage ==
    { ZeroSymbolStatusMessage }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = one]) : one \in {0, 1, 255} }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.transactTime = one]) : one \in Sample(8) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolId = one]) : one \in Sample(2) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolTradingState = one]) : one \in Sample(1) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.shortSaleRestrictionState = one]) : one \in Sample(1) }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = 1, !.symbolStatusOperationalHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }
        \cup { SettleSymbolStatusMessage([ZeroSymbolStatusMessage EXCEPT !.symbolStatusPresenceBits = 2, !.symbolStatusRegulatoryHaltReason = one]) : one \in { <<held>> : held \in Sample(1) } }

(***************************************************************************)
(* Add Order Message: 31 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ transactTime   : Sample(8),
      symbolId       : Sample(2),
      orderId        : Sample(8),
      orderBitFields : Sample(1),
      price          : Sample(8),
      qty            : Sample(4) ]

EncodeAddOrderMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.orderId
        \o message.orderBitFields
        \o message.price
        \o message.qty

DecodeAddOrderMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBitFields == ReadBytes(orderId.rest, 1) IN IF ~orderBitFields.ok THEN Fail ELSE
    LET price == ReadBytes(orderBitFields.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    Ok([ transactTime   |-> transactTime.value,
         symbolId       |-> symbolId.value,
         orderId        |-> orderId.value,
         orderBitFields |-> orderBitFields.value,
         price          |-> price.value,
         qty            |-> qty.value ], qty.rest)

ZeroAddOrderMessage ==
    [ transactTime   |-> [i \in 1 .. 8 |-> 0],
      symbolId       |-> [i \in 1 .. 2 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      orderBitFields |-> [i \in 1 .. 1 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      qty            |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderBitFields = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.qty = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Message: 18 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      orderId      : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         orderId      |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Execute Order Message: 30 bytes                                         *)
(***************************************************************************)

ExecuteOrderMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      orderId      : Sample(8),
      qty          : Sample(4),
      execId       : Sample(8) ]

EncodeExecuteOrderMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.orderId
        \o message.qty
        \o message.execId

DecodeExecuteOrderMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET qty == ReadBytes(orderId.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    LET execId == ReadBytes(qty.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         orderId      |-> orderId.value,
         qty          |-> qty.value,
         execId       |-> execId.value ], execId.rest)

ZeroExecuteOrderMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      qty          |-> [i \in 1 .. 4 |-> 0],
      execId       |-> [i \in 1 .. 8 |-> 0] ]

(* Execute Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecuteOrderMessage ==
    { ZeroExecuteOrderMessage }
        \cup { [ZeroExecuteOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroExecuteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderMessage EXCEPT !.qty = one] : one \in Sample(4) }
        \cup { [ZeroExecuteOrderMessage EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Execute Order With Price Message: 39 bytes                              *)
(***************************************************************************)

ExecuteOrderWithPriceMessage ==
    [ transactTime       : Sample(8),
      symbolId           : Sample(2),
      orderId            : Sample(8),
      qty                : Sample(4),
      execId             : Sample(8),
      execPrice          : Sample(8),
      executionBitFields : Sample(1) ]

EncodeExecuteOrderWithPriceMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.orderId
        \o message.qty
        \o message.execId
        \o message.execPrice
        \o message.executionBitFields

DecodeExecuteOrderWithPriceMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET qty == ReadBytes(orderId.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    LET execId == ReadBytes(qty.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET execPrice == ReadBytes(execId.rest, 8) IN IF ~execPrice.ok THEN Fail ELSE
    LET executionBitFields == ReadBytes(execPrice.rest, 1) IN IF ~executionBitFields.ok THEN Fail ELSE
    Ok([ transactTime       |-> transactTime.value,
         symbolId           |-> symbolId.value,
         orderId            |-> orderId.value,
         qty                |-> qty.value,
         execId             |-> execId.value,
         execPrice          |-> execPrice.value,
         executionBitFields |-> executionBitFields.value ], executionBitFields.rest)

ZeroExecuteOrderWithPriceMessage ==
    [ transactTime       |-> [i \in 1 .. 8 |-> 0],
      symbolId           |-> [i \in 1 .. 2 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      qty                |-> [i \in 1 .. 4 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      execPrice          |-> [i \in 1 .. 8 |-> 0],
      executionBitFields |-> [i \in 1 .. 1 |-> 0] ]

(* Execute Order With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedExecuteOrderWithPriceMessage ==
    { ZeroExecuteOrderWithPriceMessage }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.qty = one] : one \in Sample(4) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.execPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecuteOrderWithPriceMessage EXCEPT !.executionBitFields = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Size Down Message: 22 bytes                                      *)
(***************************************************************************)

ModifySizeDownMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      orderId      : Sample(8),
      qty          : Sample(4) ]

EncodeModifySizeDownMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.orderId
        \o message.qty

DecodeModifySizeDownMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbolId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET qty == ReadBytes(orderId.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         orderId      |-> orderId.value,
         qty          |-> qty.value ], qty.rest)

ZeroModifySizeDownMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      qty          |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Size Down Message at zero, then each field in turn at the values it is checked at *)
CheckedModifySizeDownMessage ==
    { ZeroModifySizeDownMessage }
        \cup { [ZeroModifySizeDownMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroModifySizeDownMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroModifySizeDownMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifySizeDownMessage EXCEPT !.qty = one] : one \in Sample(4) }

(***************************************************************************)
(* Replace Order Message: 38 bytes                                         *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      oldOrderId   : Sample(8),
      newOrderId   : Sample(8),
      price        : Sample(8),
      qty          : Sample(4) ]

EncodeReplaceOrderMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.oldOrderId
        \o message.newOrderId
        \o message.price
        \o message.qty

DecodeReplaceOrderMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET oldOrderId == ReadBytes(symbolId.rest, 8) IN IF ~oldOrderId.ok THEN Fail ELSE
    LET newOrderId == ReadBytes(oldOrderId.rest, 8) IN IF ~newOrderId.ok THEN Fail ELSE
    LET price == ReadBytes(newOrderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         oldOrderId   |-> oldOrderId.value,
         newOrderId   |-> newOrderId.value,
         price        |-> price.value,
         qty          |-> qty.value ], qty.rest)

ZeroReplaceOrderMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      oldOrderId   |-> [i \in 1 .. 8 |-> 0],
      newOrderId   |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      qty          |-> [i \in 1 .. 4 |-> 0] ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.oldOrderId = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.newOrderId = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.qty = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 30 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      price        : Sample(8),
      qty          : Sample(4),
      execId       : Sample(8) ]

EncodeTradeMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.price
        \o message.qty
        \o message.execId

DecodeTradeMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET price == ReadBytes(symbolId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 4) IN IF ~qty.ok THEN Fail ELSE
    LET execId == ReadBytes(qty.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         price        |-> price.value,
         qty          |-> qty.value,
         execId       |-> execId.value ], execId.rest)

ZeroTradeMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      qty          |-> [i \in 1 .. 4 |-> 0],
      execId       |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.qty = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Break Trade Message: 18 bytes                                           *)
(***************************************************************************)

BreakTradeMessage ==
    [ transactTime : Sample(8),
      symbolId     : Sample(2),
      execId       : Sample(8) ]

EncodeBreakTradeMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.execId

DecodeBreakTradeMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET execId == ReadBytes(symbolId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ transactTime |-> transactTime.value,
         symbolId     |-> symbolId.value,
         execId       |-> execId.value ], execId.rest)

ZeroBreakTradeMessage ==
    [ transactTime |-> [i \in 1 .. 8 |-> 0],
      symbolId     |-> [i \in 1 .. 2 |-> 0],
      execId       |-> [i \in 1 .. 8 |-> 0] ]

(* Break Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBreakTradeMessage ==
    { ZeroBreakTradeMessage }
        \cup { [ZeroBreakTradeMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBreakTradeMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroBreakTradeMessage EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Preamble Message: 32 bytes                                      *)
(***************************************************************************)

AuctionPreambleMessage ==
    [ transactTime      : Sample(8),
      symbolId          : Sample(2),
      auctionType       : Sample(1),
      auctionStart      : Sample(8),
      matchedShares     : Sample(4),
      excessAuctionSide : Sample(1),
      reserved8         : Sample(8) ]

EncodeAuctionPreambleMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.auctionType
        \o message.auctionStart
        \o message.matchedShares
        \o message.excessAuctionSide
        \o message.reserved8

DecodeAuctionPreambleMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionStart == ReadBytes(auctionType.rest, 8) IN IF ~auctionStart.ok THEN Fail ELSE
    LET matchedShares == ReadBytes(auctionStart.rest, 4) IN IF ~matchedShares.ok THEN Fail ELSE
    LET excessAuctionSide == ReadBytes(matchedShares.rest, 1) IN IF ~excessAuctionSide.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(excessAuctionSide.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ transactTime      |-> transactTime.value,
         symbolId          |-> symbolId.value,
         auctionType       |-> auctionType.value,
         auctionStart      |-> auctionStart.value,
         matchedShares     |-> matchedShares.value,
         excessAuctionSide |-> excessAuctionSide.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroAuctionPreambleMessage ==
    [ transactTime      |-> [i \in 1 .. 8 |-> 0],
      symbolId          |-> [i \in 1 .. 2 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      auctionStart      |-> [i \in 1 .. 8 |-> 0],
      matchedShares     |-> [i \in 1 .. 4 |-> 0],
      excessAuctionSide |-> [i \in 1 .. 1 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Preamble Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionPreambleMessage ==
    { ZeroAuctionPreambleMessage }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.auctionStart = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.matchedShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.excessAuctionSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionPreambleMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Band Window Message: 60 bytes                                   *)
(***************************************************************************)

AuctionBandWindowMessage ==
    [ transactTime           : Sample(8),
      symbolId               : Sample(2),
      auctionType            : Sample(1),
      auctionStart           : Sample(8),
      extensionCycleCount    : Sample(1),
      lowerParticipationBand : Sample(8),
      buySharesAtLower       : Sample(4),
      sellSharesAtLower      : Sample(4),
      upperParticipationBand : Sample(8),
      buySharesAtUpper       : Sample(4),
      sellSharesAtUpper      : Sample(4),
      reserved8              : Sample(8) ]

EncodeAuctionBandWindowMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.auctionType
        \o message.auctionStart
        \o message.extensionCycleCount
        \o message.lowerParticipationBand
        \o message.buySharesAtLower
        \o message.sellSharesAtLower
        \o message.upperParticipationBand
        \o message.buySharesAtUpper
        \o message.sellSharesAtUpper
        \o message.reserved8

DecodeAuctionBandWindowMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionStart == ReadBytes(auctionType.rest, 8) IN IF ~auctionStart.ok THEN Fail ELSE
    LET extensionCycleCount == ReadBytes(auctionStart.rest, 1) IN IF ~extensionCycleCount.ok THEN Fail ELSE
    LET lowerParticipationBand == ReadBytes(extensionCycleCount.rest, 8) IN IF ~lowerParticipationBand.ok THEN Fail ELSE
    LET buySharesAtLower == ReadBytes(lowerParticipationBand.rest, 4) IN IF ~buySharesAtLower.ok THEN Fail ELSE
    LET sellSharesAtLower == ReadBytes(buySharesAtLower.rest, 4) IN IF ~sellSharesAtLower.ok THEN Fail ELSE
    LET upperParticipationBand == ReadBytes(sellSharesAtLower.rest, 8) IN IF ~upperParticipationBand.ok THEN Fail ELSE
    LET buySharesAtUpper == ReadBytes(upperParticipationBand.rest, 4) IN IF ~buySharesAtUpper.ok THEN Fail ELSE
    LET sellSharesAtUpper == ReadBytes(buySharesAtUpper.rest, 4) IN IF ~sellSharesAtUpper.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(sellSharesAtUpper.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ transactTime           |-> transactTime.value,
         symbolId               |-> symbolId.value,
         auctionType            |-> auctionType.value,
         auctionStart           |-> auctionStart.value,
         extensionCycleCount    |-> extensionCycleCount.value,
         lowerParticipationBand |-> lowerParticipationBand.value,
         buySharesAtLower       |-> buySharesAtLower.value,
         sellSharesAtLower      |-> sellSharesAtLower.value,
         upperParticipationBand |-> upperParticipationBand.value,
         buySharesAtUpper       |-> buySharesAtUpper.value,
         sellSharesAtUpper      |-> sellSharesAtUpper.value,
         reserved8              |-> reserved8.value ], reserved8.rest)

ZeroAuctionBandWindowMessage ==
    [ transactTime           |-> [i \in 1 .. 8 |-> 0],
      symbolId               |-> [i \in 1 .. 2 |-> 0],
      auctionType            |-> [i \in 1 .. 1 |-> 0],
      auctionStart           |-> [i \in 1 .. 8 |-> 0],
      extensionCycleCount    |-> [i \in 1 .. 1 |-> 0],
      lowerParticipationBand |-> [i \in 1 .. 8 |-> 0],
      buySharesAtLower       |-> [i \in 1 .. 4 |-> 0],
      sellSharesAtLower      |-> [i \in 1 .. 4 |-> 0],
      upperParticipationBand |-> [i \in 1 .. 8 |-> 0],
      buySharesAtUpper       |-> [i \in 1 .. 4 |-> 0],
      sellSharesAtUpper      |-> [i \in 1 .. 4 |-> 0],
      reserved8              |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Band Window Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionBandWindowMessage ==
    { ZeroAuctionBandWindowMessage }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.auctionStart = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.extensionCycleCount = one] : one \in Sample(1) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.lowerParticipationBand = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.buySharesAtLower = one] : one \in Sample(4) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.sellSharesAtLower = one] : one \in Sample(4) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.upperParticipationBand = one] : one \in Sample(8) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.buySharesAtUpper = one] : one \in Sample(4) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.sellSharesAtUpper = one] : one \in Sample(4) }
        \cup { [ZeroAuctionBandWindowMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Print Message: 31 bytes                                         *)
(***************************************************************************)

AuctionPrintMessage ==
    [ transactTime  : Sample(8),
      symbolId      : Sample(2),
      auctionType   : Sample(1),
      auctionPrice  : Sample(8),
      matchedShares : Sample(4),
      execId        : Sample(8) ]

EncodeAuctionPrintMessage(message) ==
    message.transactTime
        \o message.symbolId
        \o message.auctionType
        \o message.auctionPrice
        \o message.matchedShares
        \o message.execId

DecodeAuctionPrintMessage(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET symbolId == ReadBytes(transactTime.rest, 2) IN IF ~symbolId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(symbolId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionPrice == ReadBytes(auctionType.rest, 8) IN IF ~auctionPrice.ok THEN Fail ELSE
    LET matchedShares == ReadBytes(auctionPrice.rest, 4) IN IF ~matchedShares.ok THEN Fail ELSE
    LET execId == ReadBytes(matchedShares.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ transactTime  |-> transactTime.value,
         symbolId      |-> symbolId.value,
         auctionType   |-> auctionType.value,
         auctionPrice  |-> auctionPrice.value,
         matchedShares |-> matchedShares.value,
         execId        |-> execId.value ], execId.rest)

ZeroAuctionPrintMessage ==
    [ transactTime  |-> [i \in 1 .. 8 |-> 0],
      symbolId      |-> [i \in 1 .. 2 |-> 0],
      auctionType   |-> [i \in 1 .. 1 |-> 0],
      auctionPrice  |-> [i \in 1 .. 8 |-> 0],
      matchedShares |-> [i \in 1 .. 4 |-> 0],
      execId        |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Print Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionPrintMessage ==
    { ZeroAuctionPrintMessage }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.symbolId = one] : one \in Sample(2) }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.auctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.matchedShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionPrintMessage EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TradingSessionStatusMessageCode == 105  \* 0x69
DefineSymbolMessageCode == 115  \* 0x73
SymbolStatusMessageCode == 121  \* 0x79
AddOrderMessageCode == 97  \* 0x61
DeleteOrderMessageCode == 100  \* 0x64
ExecuteOrderMessageCode == 101  \* 0x65
ExecuteOrderWithPriceMessageCode == 112  \* 0x70
ModifySizeDownMessageCode == 109  \* 0x6d
ReplaceOrderMessageCode == 114  \* 0x72
TradeMessageCode == 116  \* 0x74
BreakTradeMessageCode == 98  \* 0x62
AuctionPreambleMessageCode == 117  \* 0x75
AuctionBandWindowMessageCode == 118  \* 0x76
AuctionPrintMessageCode == 110  \* 0x6e

Payload ==
    [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {DefineSymbolMessageCode}, body : DefineSymbolMessage ]
        \cup [ tag : {SymbolStatusMessageCode}, body : SymbolStatusMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {ExecuteOrderMessageCode}, body : ExecuteOrderMessage ]
        \cup [ tag : {ExecuteOrderWithPriceMessageCode}, body : ExecuteOrderWithPriceMessage ]
        \cup [ tag : {ModifySizeDownMessageCode}, body : ModifySizeDownMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BreakTradeMessageCode}, body : BreakTradeMessage ]
        \cup [ tag : {AuctionPreambleMessageCode}, body : AuctionPreambleMessage ]
        \cup [ tag : {AuctionBandWindowMessageCode}, body : AuctionBandWindowMessage ]
        \cup [ tag : {AuctionPrintMessageCode}, body : AuctionPrintMessage ]

EncodePayload(message) ==
    CASE message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = DefineSymbolMessageCode -> EncodeDefineSymbolMessage(message.body)
      [] message.tag = SymbolStatusMessageCode -> EncodeSymbolStatusMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = ExecuteOrderMessageCode -> EncodeExecuteOrderMessage(message.body)
      [] message.tag = ExecuteOrderWithPriceMessageCode -> EncodeExecuteOrderWithPriceMessage(message.body)
      [] message.tag = ModifySizeDownMessageCode -> EncodeModifySizeDownMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BreakTradeMessageCode -> EncodeBreakTradeMessage(message.body)
      [] message.tag = AuctionPreambleMessageCode -> EncodeAuctionPreambleMessage(message.body)
      [] message.tag = AuctionBandWindowMessageCode -> EncodeAuctionBandWindowMessage(message.body)
      [] message.tag = AuctionPrintMessageCode -> EncodeAuctionPrintMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = DefineSymbolMessageCode -> DecodeDefineSymbolMessage(bytes)
              [] tag = SymbolStatusMessageCode -> DecodeSymbolStatusMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = ExecuteOrderMessageCode -> DecodeExecuteOrderMessage(bytes)
              [] tag = ExecuteOrderWithPriceMessageCode -> DecodeExecuteOrderWithPriceMessage(bytes)
              [] tag = ModifySizeDownMessageCode -> DecodeModifySizeDownMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BreakTradeMessageCode -> DecodeBreakTradeMessage(bytes)
              [] tag = AuctionPreambleMessageCode -> DecodeAuctionPreambleMessage(bytes)
              [] tag = AuctionBandWindowMessageCode -> DecodeAuctionBandWindowMessage(bytes)
              [] tag = AuctionPrintMessageCode -> DecodeAuctionPrintMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> DefineSymbolMessageCode, body |-> one] : one \in CheckedDefineSymbolMessage }
        \cup { [tag |-> SymbolStatusMessageCode, body |-> one] : one \in CheckedSymbolStatusMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> ExecuteOrderMessageCode, body |-> one] : one \in CheckedExecuteOrderMessage }
        \cup { [tag |-> ExecuteOrderWithPriceMessageCode, body |-> one] : one \in CheckedExecuteOrderWithPriceMessage }
        \cup { [tag |-> ModifySizeDownMessageCode, body |-> one] : one \in CheckedModifySizeDownMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BreakTradeMessageCode, body |-> one] : one \in CheckedBreakTradeMessage }
        \cup { [tag |-> AuctionPreambleMessageCode, body |-> one] : one \in CheckedAuctionPreambleMessage }
        \cup { [tag |-> AuctionBandWindowMessageCode, body |-> one] : one \in CheckedAuctionBandWindowMessage }
        \cup { [tag |-> AuctionPrintMessageCode, body |-> one] : one \in CheckedAuctionPrintMessage }

(***************************************************************************)
(* Udp Sequenced Message, framed by Message Length                         *)
(***************************************************************************)

UdpSequencedMessage ==
    [ streamId : Sample(1),
      payload  : Payload ]

EncodeUdpSequencedMessageBody(message) ==
    message.streamId
        \o EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeUdpSequencedMessage(message) ==
    LET body == EncodeUdpSequencedMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeUdpSequencedMessageBody(bytes) ==
    LET streamId == ReadBytes(bytes, 1) IN IF ~streamId.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(streamId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ streamId |-> streamId.value,
         payload  |-> payload.value ], payload.rest)

DecodeUdpSequencedMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeUdpSequencedMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroUdpSequencedMessage ==
    [ streamId |-> [i \in 1 .. 1 |-> 0],
      payload  |-> ZeroPayload ]

(* Udp Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedUdpSequencedMessage ==
    { ZeroUdpSequencedMessage }
        \cup { [ZeroUdpSequencedMessage EXCEPT !.streamId = one] : one \in Sample(1) }
        \cup { [ZeroUdpSequencedMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Udp Sequenced Message, written one after another *)
RECURSIVE EncodeUdpSequencedMessageList(_)
EncodeUdpSequencedMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUdpSequencedMessage(Head(messages)) \o EncodeUdpSequencedMessageList(Tail(messages))

(* As many Udp Sequenced Message as the field that counts them says *)
RECURSIVE ReadUdpSequencedMessageList(_, _)
ReadUdpSequencedMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUdpSequencedMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUdpSequencedMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Udp Sequenced Message of each kind, for the lists that carry them *)
OneUdpSequencedMessage ==
    { [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> DefineSymbolMessageCode, body |-> ZeroDefineSymbolMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> SymbolStatusMessageCode, body |-> ZeroSymbolStatusMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> ExecuteOrderMessageCode, body |-> ZeroExecuteOrderMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> ExecuteOrderWithPriceMessageCode, body |-> ZeroExecuteOrderWithPriceMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> ModifySizeDownMessageCode, body |-> ZeroModifySizeDownMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> ReplaceOrderMessageCode, body |-> ZeroReplaceOrderMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> BreakTradeMessageCode, body |-> ZeroBreakTradeMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> AuctionPreambleMessageCode, body |-> ZeroAuctionPreambleMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> AuctionBandWindowMessageCode, body |-> ZeroAuctionBandWindowMessage]],
      [ZeroUdpSequencedMessage EXCEPT !.payload = [tag |-> AuctionPrintMessageCode, body |-> ZeroAuctionPrintMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session             : Sample(8),
      sequence            : Sample(8),
      packetType          : Sample(1),
      udpSequencedMessage : SampleLists(OneUdpSequencedMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequence
        \o EncodeUIntLE(Len(message.udpSequencedMessage), 2)
        \o message.packetType
        \o EncodeUdpSequencedMessageList(message.udpSequencedMessage)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 8) IN IF ~session.ok THEN Fail ELSE
    LET sequence == ReadBytes(session.rest, 8) IN IF ~sequence.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(sequence.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET packetType == ReadBytes(messageCount.rest, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET udpSequencedMessage == ReadUdpSequencedMessageList(packetType.rest, messageCount.value) IN IF ~udpSequencedMessage.ok THEN Fail ELSE
    Ok([ session             |-> session.value,
         sequence            |-> sequence.value,
         packetType          |-> packetType.value,
         udpSequencedMessage |-> udpSequencedMessage.value ], udpSequencedMessage.rest)

ZeroPacket ==
    [ session             |-> [i \in 1 .. 8 |-> 0],
      sequence            |-> [i \in 1 .. 8 |-> 0],
      packetType          |-> [i \in 1 .. 1 |-> 0],
      udpSequencedMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.udpSequencedMessage = one] : one \in SampleLists(OneUdpSequencedMessage) }

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

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Define Symbol Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDefineSymbolMessage ==
    \A message \in CheckedDefineSymbolMessage :
        LET read == DecodeDefineSymbolMessage(EncodeDefineSymbolMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolStatusMessage ==
    \A message \in CheckedSymbolStatusMessage :
        LET read == DecodeSymbolStatusMessage(EncodeSymbolStatusMessage(message))
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

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execute Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecuteOrderMessage ==
    \A message \in CheckedExecuteOrderMessage :
        LET read == DecodeExecuteOrderMessage(EncodeExecuteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execute Order With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecuteOrderWithPriceMessage ==
    \A message \in CheckedExecuteOrderWithPriceMessage :
        LET read == DecodeExecuteOrderWithPriceMessage(EncodeExecuteOrderWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Size Down Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifySizeDownMessage ==
    \A message \in CheckedModifySizeDownMessage :
        LET read == DecodeModifySizeDownMessage(EncodeModifySizeDownMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderMessage ==
    \A message \in CheckedReplaceOrderMessage :
        LET read == DecodeReplaceOrderMessage(EncodeReplaceOrderMessage(message))
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

(* Every Break Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBreakTradeMessage ==
    \A message \in CheckedBreakTradeMessage :
        LET read == DecodeBreakTradeMessage(EncodeBreakTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Preamble Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionPreambleMessage ==
    \A message \in CheckedAuctionPreambleMessage :
        LET read == DecodeAuctionPreambleMessage(EncodeAuctionPreambleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Band Window Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionBandWindowMessage ==
    \A message \in CheckedAuctionBandWindowMessage :
        LET read == DecodeAuctionBandWindowMessage(EncodeAuctionBandWindowMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Print Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionPrintMessage ==
    \A message \in CheckedAuctionPrintMessage :
        LET read == DecodeAuctionPrintMessage(EncodeAuctionPrintMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpSequencedMessage ==
    \A message \in CheckedUdpSequencedMessage :
        LET read == DecodeUdpSequencedMessage(EncodeUdpSequencedMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesUdpSequencedMessage ==
    \A message \in CheckedUdpSequencedMessage :
        LET bytes == EncodeUdpSequencedMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
