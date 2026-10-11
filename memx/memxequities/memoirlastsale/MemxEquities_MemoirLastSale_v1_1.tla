----------------- MODULE MemxEquities_MemoirLastSale_v1_1 ------------------
(***************************************************************************)
(* The Members Exchange Member Order Information Record Last Sale v1.1     *)
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
(* Instrument Directory Message: 35 bytes                                  *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp    : Sample(8),
      securityId   : Sample(2),
      symbol       : Sample(6),
      symbolSfx    : Sample(6),
      roundLot     : Sample(4),
      isTestSymbol : Sample(1),
      mpv          : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.symbol
        \o message.symbolSfx
        \o message.roundLot
        \o message.isTestSymbol
        \o message.mpv

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET roundLot == ReadBytes(symbolSfx.rest, 4) IN IF ~roundLot.ok THEN Fail ELSE
    LET isTestSymbol == ReadBytes(roundLot.rest, 1) IN IF ~isTestSymbol.ok THEN Fail ELSE
    LET mpv == ReadBytes(isTestSymbol.rest, 8) IN IF ~mpv.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         securityId   |-> securityId.value,
         symbol       |-> symbol.value,
         symbolSfx    |-> symbolSfx.value,
         roundLot     |-> roundLot.value,
         isTestSymbol |-> isTestSymbol.value,
         mpv          |-> mpv.value ], mpv.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 2 |-> 0],
      symbol       |-> [i \in 1 .. 6 |-> 0],
      symbolSfx    |-> [i \in 1 .. 6 |-> 0],
      roundLot     |-> [i \in 1 .. 4 |-> 0],
      isTestSymbol |-> [i \in 1 .. 1 |-> 0],
      mpv          |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.roundLot = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isTestSymbol = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(8) }

(***************************************************************************)
(* Reg Sho Restriction Message: 11 bytes                                   *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ timestamp            : Sample(8),
      securityId           : Sample(2),
      shortSaleRestriction : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.shortSaleRestriction

DecodeRegShoRestrictionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(securityId.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         securityId           |-> securityId.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroRegShoRestrictionMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      securityId           |-> [i \in 1 .. 2 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Trading Status Message: 12 bytes                               *)
(***************************************************************************)

SecurityTradingStatusMessage ==
    [ timestamp                   : Sample(8),
      securityId                  : Sample(2),
      securityTradingStatus       : Sample(1),
      securityTradingStatusReason : Sample(1) ]

EncodeSecurityTradingStatusMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.securityTradingStatus
        \o message.securityTradingStatusReason

DecodeSecurityTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET securityTradingStatusReason == ReadBytes(securityTradingStatus.rest, 1) IN IF ~securityTradingStatusReason.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         securityId                  |-> securityId.value,
         securityTradingStatus       |-> securityTradingStatus.value,
         securityTradingStatusReason |-> securityTradingStatusReason.value ], securityTradingStatusReason.rest)

ZeroSecurityTradingStatusMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 2 |-> 0],
      securityTradingStatus       |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatusReason |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingStatusMessage ==
    { ZeroSecurityTradingStatusMessage }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatusReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Session Status Message: 9 bytes                                 *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ timestamp      : Sample(8),
      tradingSession : Sample(1) ]

EncodeTradingSessionStatusMessage(message) ==
    message.timestamp
        \o message.tradingSession

DecodeTradingSessionStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(timestamp.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         tradingSession |-> tradingSession.value ], tradingSession.rest)

ZeroTradingSessionStatusMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      tradingSession |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message: 34 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ timestamp      : Sample(8),
      securityId     : Sample(2),
      tradeId        : Sample(8),
      tradeQty       : Sample(4),
      tradePrice     : Sample(8),
      saleCondition1 : Sample(1),
      saleCondition2 : Sample(1),
      saleCondition3 : Sample(1),
      saleCondition4 : Sample(1) ]

EncodeTradeReportMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.tradeQty
        \o message.tradePrice
        \o message.saleCondition1
        \o message.saleCondition2
        \o message.saleCondition3
        \o message.saleCondition4

DecodeTradeReportMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeQty == ReadBytes(tradeId.rest, 4) IN IF ~tradeQty.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeQty.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET saleCondition1 == ReadBytes(tradePrice.rest, 1) IN IF ~saleCondition1.ok THEN Fail ELSE
    LET saleCondition2 == ReadBytes(saleCondition1.rest, 1) IN IF ~saleCondition2.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(saleCondition2.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         securityId     |-> securityId.value,
         tradeId        |-> tradeId.value,
         tradeQty       |-> tradeQty.value,
         tradePrice     |-> tradePrice.value,
         saleCondition1 |-> saleCondition1.value,
         saleCondition2 |-> saleCondition2.value,
         saleCondition3 |-> saleCondition3.value,
         saleCondition4 |-> saleCondition4.value ], saleCondition4.rest)

ZeroTradeReportMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 2 |-> 0],
      tradeId        |-> [i \in 1 .. 8 |-> 0],
      tradeQty       |-> [i \in 1 .. 4 |-> 0],
      tradePrice     |-> [i \in 1 .. 8 |-> 0],
      saleCondition1 |-> [i \in 1 .. 1 |-> 0],
      saleCondition2 |-> [i \in 1 .. 1 |-> 0],
      saleCondition3 |-> [i \in 1 .. 1 |-> 0],
      saleCondition4 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleCondition4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 34 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ timestamp      : Sample(8),
      securityId     : Sample(2),
      tradeId        : Sample(8),
      tradeQty       : Sample(4),
      lastPrice      : Sample(8),
      saleCondition1 : Sample(1),
      saleCondition2 : Sample(1),
      saleCondition3 : Sample(1),
      saleCondition4 : Sample(1) ]

EncodeTradeCancelMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.tradeQty
        \o message.lastPrice
        \o message.saleCondition1
        \o message.saleCondition2
        \o message.saleCondition3
        \o message.saleCondition4

DecodeTradeCancelMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeQty == ReadBytes(tradeId.rest, 4) IN IF ~tradeQty.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(tradeQty.rest, 8) IN IF ~lastPrice.ok THEN Fail ELSE
    LET saleCondition1 == ReadBytes(lastPrice.rest, 1) IN IF ~saleCondition1.ok THEN Fail ELSE
    LET saleCondition2 == ReadBytes(saleCondition1.rest, 1) IN IF ~saleCondition2.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(saleCondition2.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         securityId     |-> securityId.value,
         tradeId        |-> tradeId.value,
         tradeQty       |-> tradeQty.value,
         lastPrice      |-> lastPrice.value,
         saleCondition1 |-> saleCondition1.value,
         saleCondition2 |-> saleCondition2.value,
         saleCondition3 |-> saleCondition3.value,
         saleCondition4 |-> saleCondition4.value ], saleCondition4.rest)

ZeroTradeCancelMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      securityId     |-> [i \in 1 .. 2 |-> 0],
      tradeId        |-> [i \in 1 .. 8 |-> 0],
      tradeQty       |-> [i \in 1 .. 4 |-> 0],
      lastPrice      |-> [i \in 1 .. 8 |-> 0],
      saleCondition1 |-> [i \in 1 .. 1 |-> 0],
      saleCondition2 |-> [i \in 1 .. 1 |-> 0],
      saleCondition3 |-> [i \in 1 .. 1 |-> 0],
      saleCondition4 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.lastPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.saleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.saleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.saleCondition4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correct Message: 50 bytes                                         *)
(***************************************************************************)

TradeCorrectMessage ==
    [ timestamp               : Sample(8),
      securityId              : Sample(2),
      tradeId                 : Sample(8),
      originalTradeQty        : Sample(4),
      originalTradePrice      : Sample(8),
      originalSaleCondition1  : Sample(1),
      originalSaleCondition2  : Sample(1),
      originalSaleCondition3  : Sample(1),
      originalSaleCondition4  : Sample(1),
      correctedTradeQty       : Sample(4),
      correctedTradePrice     : Sample(8),
      correctedSaleCondition1 : Sample(1),
      correctedSaleCondition2 : Sample(1),
      correctedSaleCondition3 : Sample(1),
      correctedSaleCondition4 : Sample(1) ]

EncodeTradeCorrectMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.originalTradeQty
        \o message.originalTradePrice
        \o message.originalSaleCondition1
        \o message.originalSaleCondition2
        \o message.originalSaleCondition3
        \o message.originalSaleCondition4
        \o message.correctedTradeQty
        \o message.correctedTradePrice
        \o message.correctedSaleCondition1
        \o message.correctedSaleCondition2
        \o message.correctedSaleCondition3
        \o message.correctedSaleCondition4

DecodeTradeCorrectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalTradeQty == ReadBytes(tradeId.rest, 4) IN IF ~originalTradeQty.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeQty.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalSaleCondition1 == ReadBytes(originalTradePrice.rest, 1) IN IF ~originalSaleCondition1.ok THEN Fail ELSE
    LET originalSaleCondition2 == ReadBytes(originalSaleCondition1.rest, 1) IN IF ~originalSaleCondition2.ok THEN Fail ELSE
    LET originalSaleCondition3 == ReadBytes(originalSaleCondition2.rest, 1) IN IF ~originalSaleCondition3.ok THEN Fail ELSE
    LET originalSaleCondition4 == ReadBytes(originalSaleCondition3.rest, 1) IN IF ~originalSaleCondition4.ok THEN Fail ELSE
    LET correctedTradeQty == ReadBytes(originalSaleCondition4.rest, 4) IN IF ~correctedTradeQty.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeQty.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedSaleCondition1 == ReadBytes(correctedTradePrice.rest, 1) IN IF ~correctedSaleCondition1.ok THEN Fail ELSE
    LET correctedSaleCondition2 == ReadBytes(correctedSaleCondition1.rest, 1) IN IF ~correctedSaleCondition2.ok THEN Fail ELSE
    LET correctedSaleCondition3 == ReadBytes(correctedSaleCondition2.rest, 1) IN IF ~correctedSaleCondition3.ok THEN Fail ELSE
    LET correctedSaleCondition4 == ReadBytes(correctedSaleCondition3.rest, 1) IN IF ~correctedSaleCondition4.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         securityId              |-> securityId.value,
         tradeId                 |-> tradeId.value,
         originalTradeQty        |-> originalTradeQty.value,
         originalTradePrice      |-> originalTradePrice.value,
         originalSaleCondition1  |-> originalSaleCondition1.value,
         originalSaleCondition2  |-> originalSaleCondition2.value,
         originalSaleCondition3  |-> originalSaleCondition3.value,
         originalSaleCondition4  |-> originalSaleCondition4.value,
         correctedTradeQty       |-> correctedTradeQty.value,
         correctedTradePrice     |-> correctedTradePrice.value,
         correctedSaleCondition1 |-> correctedSaleCondition1.value,
         correctedSaleCondition2 |-> correctedSaleCondition2.value,
         correctedSaleCondition3 |-> correctedSaleCondition3.value,
         correctedSaleCondition4 |-> correctedSaleCondition4.value ], correctedSaleCondition4.rest)

ZeroTradeCorrectMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      securityId              |-> [i \in 1 .. 2 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      originalTradeQty        |-> [i \in 1 .. 4 |-> 0],
      originalTradePrice      |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition1  |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition2  |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition3  |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition4  |-> [i \in 1 .. 1 |-> 0],
      correctedTradeQty       |-> [i \in 1 .. 4 |-> 0],
      correctedTradePrice     |-> [i \in 1 .. 8 |-> 0],
      correctedSaleCondition1 |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition2 |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition3 |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition4 |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectMessage ==
    { ZeroTradeCorrectMessage }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalTradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalSaleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalSaleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalSaleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.originalSaleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedTradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedSaleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedSaleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedSaleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.correctedSaleCondition4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentDirectoryMessageCode == 1  \* 0x01
RegShoRestrictionMessageCode == 2  \* 0x02
SecurityTradingStatusMessageCode == 3  \* 0x03
TradingSessionStatusMessageCode == 5  \* 0x05
TradeReportMessageCode == 10  \* 0x0a
TradeCancelMessageCode == 11  \* 0x0b
TradeCorrectMessageCode == 12  \* 0x0c

Payload ==
    [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {SecurityTradingStatusMessageCode}, body : SecurityTradingStatusMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {TradeCorrectMessageCode}, body : TradeCorrectMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = SecurityTradingStatusMessageCode -> EncodeSecurityTradingStatusMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = TradeCorrectMessageCode -> EncodeTradeCorrectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = SecurityTradingStatusMessageCode -> DecodeSecurityTradingStatusMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = TradeCorrectMessageCode -> DecodeTradeCorrectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> SecurityTradingStatusMessageCode, body |-> one] : one \in CheckedSecurityTradingStatusMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> TradeCorrectMessageCode, body |-> one] : one \in CheckedTradeCorrectMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(1),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 1 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ sbeMessage : SbeMessage ]

EncodeMessageBody(message) ==
    EncodeSbeMessage(message.sbeMessage)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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
OneMessage == { ZeroMessage }

(***************************************************************************)
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ message : SampleLists(OneMessage) ]

EncodeSequencedMessage(message) ==
    EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodeSequencedMessage(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroSequencedMessage ==
    [ message |-> << >> ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Sequenced Messages, selected by Message Type                            *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
SessionShutdownCode == 1  \* 0x01
SequencedMessageCode == 2  \* 0x02

SequencedMessages ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SessionShutdownCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedMessageCode}, body : SequencedMessage ]

EncodeSequencedMessages(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = SessionShutdownCode -> << >>
      [] message.tag = SequencedMessageCode -> EncodeSequencedMessage(message.body)

DecodeSequencedMessages(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = SessionShutdownCode -> Ok([empty |-> 0], bytes)
              [] tag = SequencedMessageCode -> DecodeSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessages == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Sequenced Messages in turn, at the values the message it names is checked at *)
CheckedSequencedMessages ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SessionShutdownCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedMessageCode, body |-> one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ headerLength      : Sample(1),
      sessionId         : Sample(8),
      sequenceNumber    : Sample(8),
      sequencedMessages : SequencedMessages ]

EncodePacket(message) ==
    EncodeUIntBE(message.sequencedMessages.tag, 1)
        \o message.headerLength
        \o message.sessionId
        \o message.sequenceNumber
        \o EncodeSequencedMessages(message.sequencedMessages)

DecodePacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET headerLength == ReadBytes(messageType.rest, 1) IN IF ~headerLength.ok THEN Fail ELSE
    LET sessionId == ReadBytes(headerLength.rest, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessages == DecodeSequencedMessages(messageType.value, sequenceNumber.rest) IN IF ~sequencedMessages.ok THEN Fail ELSE
    Ok([ headerLength      |-> headerLength.value,
         sessionId         |-> sessionId.value,
         sequenceNumber    |-> sequenceNumber.value,
         sequencedMessages |-> sequencedMessages.value ], sequencedMessages.rest)

ZeroPacket ==
    [ headerLength      |-> [i \in 1 .. 1 |-> 0],
      sessionId         |-> [i \in 1 .. 8 |-> 0],
      sequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      sequencedMessages |-> ZeroSequencedMessages ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.headerLength = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequencedMessages = one] : one \in CheckedSequencedMessages }

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

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoRestrictionMessage ==
    \A message \in CheckedRegShoRestrictionMessage :
        LET read == DecodeRegShoRestrictionMessage(EncodeRegShoRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingStatusMessage ==
    \A message \in CheckedSecurityTradingStatusMessage :
        LET read == DecodeSecurityTradingStatusMessage(EncodeSecurityTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
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

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correct Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectMessage ==
    \A message \in CheckedTradeCorrectMessage :
        LET read == DecodeTradeCorrectMessage(EncodeTradeCorrectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
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

(* Every Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(EncodeSequencedMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sequenced Messages is selected by the Message Type it is written under *)
SelectsSequencedMessages ==
    \A message \in CheckedSequencedMessages :
        LET read == DecodeSequencedMessages(message.tag, EncodeSequencedMessages(message))
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
