-------------- MODULE CoinbaseDerivatives_MarketDataApi_v1_7 ---------------
(***************************************************************************)
(* Coinbase Market Data Api v1.7                                           *)
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
(* Note: Packet Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Definition Flags is a bit field set, checked as its 2 bytes       *)
(* rather than bit by bit.                                                 *)
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
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader ==
    { ZeroInstrHeader }
        \cup { [ZeroInstrHeader EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry ==
    { ZeroLogicalExpiry }
        \cup { [ZeroLogicalExpiry EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Outright Instrument Definition Message: 174 bytes                       *)
(***************************************************************************)

OutrightInstrumentDefinitionMessage ==
    [ instrHeader                  : InstrHeader,
      symbol                       : Sample(24),
      productCode                  : Sample(8),
      description                  : Sample(32),
      tickSize                     : Sample(8),
      cfiCode                      : Sample(8),
      currency                     : Sample(8),
      firstTradingSessionDate      : Sample(2),
      lastTradingSessionDate       : Sample(2),
      oldContractSize              : Sample(4),
      priorSettlementPriceOptional : Sample(8),
      settlementPrice              : Sample(8),
      limitDownPrice               : Sample(8),
      limitUpPrice                 : Sample(8),
      productId                    : Sample(4),
      productGroup                 : Sample(1),
      tradingStatus                : Sample(1),
      definitionFlags              : Sample(2),
      contractSize                 : Sample(8),
      logicalExpiry                : LogicalExpiry ]

EncodeOutrightInstrumentDefinitionMessage(message) ==
    EncodeInstrHeader(message.instrHeader)
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.tickSize
        \o message.cfiCode
        \o message.currency
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.oldContractSize
        \o message.priorSettlementPriceOptional
        \o message.settlementPrice
        \o message.limitDownPrice
        \o message.limitUpPrice
        \o message.productId
        \o message.productGroup
        \o message.tradingStatus
        \o message.definitionFlags
        \o message.contractSize
        \o EncodeLogicalExpiry(message.logicalExpiry)

DecodeOutrightInstrumentDefinitionMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrHeader.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET tickSize == ReadBytes(description.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(tickSize.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 8) IN IF ~currency.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(currency.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET oldContractSize == ReadBytes(lastTradingSessionDate.rest, 4) IN IF ~oldContractSize.ok THEN Fail ELSE
    LET priorSettlementPriceOptional == ReadBytes(oldContractSize.rest, 8) IN IF ~priorSettlementPriceOptional.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(priorSettlementPriceOptional.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(settlementPrice.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    LET productId == ReadBytes(limitUpPrice.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET productGroup == ReadBytes(productId.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET definitionFlags == ReadBytes(tradingStatus.rest, 2) IN IF ~definitionFlags.ok THEN Fail ELSE
    LET contractSize == ReadBytes(definitionFlags.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry(contractSize.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ instrHeader                  |-> instrHeader.value,
         symbol                       |-> symbol.value,
         productCode                  |-> productCode.value,
         description                  |-> description.value,
         tickSize                     |-> tickSize.value,
         cfiCode                      |-> cfiCode.value,
         currency                     |-> currency.value,
         firstTradingSessionDate      |-> firstTradingSessionDate.value,
         lastTradingSessionDate       |-> lastTradingSessionDate.value,
         oldContractSize              |-> oldContractSize.value,
         priorSettlementPriceOptional |-> priorSettlementPriceOptional.value,
         settlementPrice              |-> settlementPrice.value,
         limitDownPrice               |-> limitDownPrice.value,
         limitUpPrice                 |-> limitUpPrice.value,
         productId                    |-> productId.value,
         productGroup                 |-> productGroup.value,
         tradingStatus                |-> tradingStatus.value,
         definitionFlags              |-> definitionFlags.value,
         contractSize                 |-> contractSize.value,
         logicalExpiry                |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroOutrightInstrumentDefinitionMessage ==
    [ instrHeader                  |-> ZeroInstrHeader,
      symbol                       |-> [i \in 1 .. 24 |-> 0],
      productCode                  |-> [i \in 1 .. 8 |-> 0],
      description                  |-> [i \in 1 .. 32 |-> 0],
      tickSize                     |-> [i \in 1 .. 8 |-> 0],
      cfiCode                      |-> [i \in 1 .. 8 |-> 0],
      currency                     |-> [i \in 1 .. 8 |-> 0],
      firstTradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate       |-> [i \in 1 .. 2 |-> 0],
      oldContractSize              |-> [i \in 1 .. 4 |-> 0],
      priorSettlementPriceOptional |-> [i \in 1 .. 8 |-> 0],
      settlementPrice              |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice               |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice                 |-> [i \in 1 .. 8 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      productGroup                 |-> [i \in 1 .. 1 |-> 0],
      tradingStatus                |-> [i \in 1 .. 1 |-> 0],
      definitionFlags              |-> [i \in 1 .. 2 |-> 0],
      contractSize                 |-> [i \in 1 .. 8 |-> 0],
      logicalExpiry                |-> ZeroLogicalExpiry ]

(* Outright Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedOutrightInstrumentDefinitionMessage ==
    { ZeroOutrightInstrumentDefinitionMessage }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.currency = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.oldContractSize = one] : one \in Sample(4) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.priorSettlementPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.definitionFlags = one] : one \in Sample(2) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroOutrightInstrumentDefinitionMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader2 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader2(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader2(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader2 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader2 ==
    { ZeroInstrHeader2 }
        \cup { [ZeroInstrHeader2 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader2 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader2 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader2 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader2 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader2 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader2 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry2 ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry2(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry2 ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry2 ==
    { ZeroLogicalExpiry2 }
        \cup { [ZeroLogicalExpiry2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry2 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry2 EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry2 EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Spread Instrument Definition Message: 175 bytes                         *)
(***************************************************************************)

SpreadInstrumentDefinitionMessage ==
    [ instrHeader                  : InstrHeader2,
      symbol                       : Sample(24),
      productCode                  : Sample(8),
      description                  : Sample(32),
      tickSize                     : Sample(8),
      cfiCode                      : Sample(8),
      currency                     : Sample(8),
      firstTradingSessionDate      : Sample(2),
      lastTradingSessionDate       : Sample(2),
      oldContractSize              : Sample(4),
      priorSettlementPriceOptional : Sample(8),
      settlementPrice              : Sample(8),
      limitDownPrice               : Sample(8),
      limitUpPrice                 : Sample(8),
      productId                    : Sample(4),
      productGroup                 : Sample(1),
      tradingStatus                : Sample(1),
      leg1InstrumentId             : Sample(4),
      leg2InstrumentId             : Sample(4),
      spreadBuyConvention          : Sample(1),
      definitionFlags              : Sample(2),
      logicalExpiry                : LogicalExpiry2 ]

EncodeSpreadInstrumentDefinitionMessage(message) ==
    EncodeInstrHeader2(message.instrHeader)
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.tickSize
        \o message.cfiCode
        \o message.currency
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.oldContractSize
        \o message.priorSettlementPriceOptional
        \o message.settlementPrice
        \o message.limitDownPrice
        \o message.limitUpPrice
        \o message.productId
        \o message.productGroup
        \o message.tradingStatus
        \o message.leg1InstrumentId
        \o message.leg2InstrumentId
        \o message.spreadBuyConvention
        \o message.definitionFlags
        \o EncodeLogicalExpiry2(message.logicalExpiry)

DecodeSpreadInstrumentDefinitionMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader2(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrHeader.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET tickSize == ReadBytes(description.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(tickSize.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 8) IN IF ~currency.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(currency.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET oldContractSize == ReadBytes(lastTradingSessionDate.rest, 4) IN IF ~oldContractSize.ok THEN Fail ELSE
    LET priorSettlementPriceOptional == ReadBytes(oldContractSize.rest, 8) IN IF ~priorSettlementPriceOptional.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(priorSettlementPriceOptional.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(settlementPrice.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    LET productId == ReadBytes(limitUpPrice.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET productGroup == ReadBytes(productId.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET leg1InstrumentId == ReadBytes(tradingStatus.rest, 4) IN IF ~leg1InstrumentId.ok THEN Fail ELSE
    LET leg2InstrumentId == ReadBytes(leg1InstrumentId.rest, 4) IN IF ~leg2InstrumentId.ok THEN Fail ELSE
    LET spreadBuyConvention == ReadBytes(leg2InstrumentId.rest, 1) IN IF ~spreadBuyConvention.ok THEN Fail ELSE
    LET definitionFlags == ReadBytes(spreadBuyConvention.rest, 2) IN IF ~definitionFlags.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry2(definitionFlags.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ instrHeader                  |-> instrHeader.value,
         symbol                       |-> symbol.value,
         productCode                  |-> productCode.value,
         description                  |-> description.value,
         tickSize                     |-> tickSize.value,
         cfiCode                      |-> cfiCode.value,
         currency                     |-> currency.value,
         firstTradingSessionDate      |-> firstTradingSessionDate.value,
         lastTradingSessionDate       |-> lastTradingSessionDate.value,
         oldContractSize              |-> oldContractSize.value,
         priorSettlementPriceOptional |-> priorSettlementPriceOptional.value,
         settlementPrice              |-> settlementPrice.value,
         limitDownPrice               |-> limitDownPrice.value,
         limitUpPrice                 |-> limitUpPrice.value,
         productId                    |-> productId.value,
         productGroup                 |-> productGroup.value,
         tradingStatus                |-> tradingStatus.value,
         leg1InstrumentId             |-> leg1InstrumentId.value,
         leg2InstrumentId             |-> leg2InstrumentId.value,
         spreadBuyConvention          |-> spreadBuyConvention.value,
         definitionFlags              |-> definitionFlags.value,
         logicalExpiry                |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroSpreadInstrumentDefinitionMessage ==
    [ instrHeader                  |-> ZeroInstrHeader2,
      symbol                       |-> [i \in 1 .. 24 |-> 0],
      productCode                  |-> [i \in 1 .. 8 |-> 0],
      description                  |-> [i \in 1 .. 32 |-> 0],
      tickSize                     |-> [i \in 1 .. 8 |-> 0],
      cfiCode                      |-> [i \in 1 .. 8 |-> 0],
      currency                     |-> [i \in 1 .. 8 |-> 0],
      firstTradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate       |-> [i \in 1 .. 2 |-> 0],
      oldContractSize              |-> [i \in 1 .. 4 |-> 0],
      priorSettlementPriceOptional |-> [i \in 1 .. 8 |-> 0],
      settlementPrice              |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice               |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice                 |-> [i \in 1 .. 8 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      productGroup                 |-> [i \in 1 .. 1 |-> 0],
      tradingStatus                |-> [i \in 1 .. 1 |-> 0],
      leg1InstrumentId             |-> [i \in 1 .. 4 |-> 0],
      leg2InstrumentId             |-> [i \in 1 .. 4 |-> 0],
      spreadBuyConvention          |-> [i \in 1 .. 1 |-> 0],
      definitionFlags              |-> [i \in 1 .. 2 |-> 0],
      logicalExpiry                |-> ZeroLogicalExpiry2 ]

(* Spread Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadInstrumentDefinitionMessage ==
    { ZeroSpreadInstrumentDefinitionMessage }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader2 }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.currency = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.oldContractSize = one] : one \in Sample(4) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.priorSettlementPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.leg1InstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.leg2InstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.spreadBuyConvention = one] : one \in Sample(1) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.definitionFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpreadInstrumentDefinitionMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry2 }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader3 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader3(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader3(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader3 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader3 ==
    { ZeroInstrHeader3 }
        \cup { [ZeroInstrHeader3 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader3 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader3 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader3 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader3 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader3 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader3 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry3 ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry3(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry3 ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry3 ==
    { ZeroLogicalExpiry3 }
        \cup { [ZeroLogicalExpiry3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry3 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry3 EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry3 EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Instrument Definition Message: 167 bytes                         *)
(***************************************************************************)

OptionInstrumentDefinitionMessage ==
    [ instrHeader             : InstrHeader3,
      symbol                  : Sample(24),
      productCode             : Sample(8),
      description             : Sample(32),
      smallTick               : Sample(8),
      cfiCode                 : Sample(8),
      largeTick               : Sample(8),
      largeTickThreshold      : Sample(8),
      strikePrice             : Sample(8),
      firstTradingSessionDate : Sample(2),
      lastTradingSessionDate  : Sample(2),
      priorSettlementPrice    : Sample(8),
      settlementPrice         : Sample(8),
      productId               : Sample(4),
      underlyingInstrumentId  : Sample(4),
      productGroup            : Sample(1),
      tradingStatus           : Sample(1),
      definitionFlags         : Sample(2),
      optionExpiryType        : Sample(1),
      logicalExpiry           : LogicalExpiry3 ]

EncodeOptionInstrumentDefinitionMessage(message) ==
    EncodeInstrHeader3(message.instrHeader)
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.smallTick
        \o message.cfiCode
        \o message.largeTick
        \o message.largeTickThreshold
        \o message.strikePrice
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.priorSettlementPrice
        \o message.settlementPrice
        \o message.productId
        \o message.underlyingInstrumentId
        \o message.productGroup
        \o message.tradingStatus
        \o message.definitionFlags
        \o message.optionExpiryType
        \o EncodeLogicalExpiry3(message.logicalExpiry)

DecodeOptionInstrumentDefinitionMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader3(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrHeader.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET smallTick == ReadBytes(description.rest, 8) IN IF ~smallTick.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(smallTick.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET largeTick == ReadBytes(cfiCode.rest, 8) IN IF ~largeTick.ok THEN Fail ELSE
    LET largeTickThreshold == ReadBytes(largeTick.rest, 8) IN IF ~largeTickThreshold.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(largeTickThreshold.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(strikePrice.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET priorSettlementPrice == ReadBytes(lastTradingSessionDate.rest, 8) IN IF ~priorSettlementPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(priorSettlementPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET productId == ReadBytes(settlementPrice.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(productId.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET productGroup == ReadBytes(underlyingInstrumentId.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET definitionFlags == ReadBytes(tradingStatus.rest, 2) IN IF ~definitionFlags.ok THEN Fail ELSE
    LET optionExpiryType == ReadBytes(definitionFlags.rest, 1) IN IF ~optionExpiryType.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry3(optionExpiryType.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ instrHeader             |-> instrHeader.value,
         symbol                  |-> symbol.value,
         productCode             |-> productCode.value,
         description             |-> description.value,
         smallTick               |-> smallTick.value,
         cfiCode                 |-> cfiCode.value,
         largeTick               |-> largeTick.value,
         largeTickThreshold      |-> largeTickThreshold.value,
         strikePrice             |-> strikePrice.value,
         firstTradingSessionDate |-> firstTradingSessionDate.value,
         lastTradingSessionDate  |-> lastTradingSessionDate.value,
         priorSettlementPrice    |-> priorSettlementPrice.value,
         settlementPrice         |-> settlementPrice.value,
         productId               |-> productId.value,
         underlyingInstrumentId  |-> underlyingInstrumentId.value,
         productGroup            |-> productGroup.value,
         tradingStatus           |-> tradingStatus.value,
         definitionFlags         |-> definitionFlags.value,
         optionExpiryType        |-> optionExpiryType.value,
         logicalExpiry           |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroOptionInstrumentDefinitionMessage ==
    [ instrHeader             |-> ZeroInstrHeader3,
      symbol                  |-> [i \in 1 .. 24 |-> 0],
      productCode             |-> [i \in 1 .. 8 |-> 0],
      description             |-> [i \in 1 .. 32 |-> 0],
      smallTick               |-> [i \in 1 .. 8 |-> 0],
      cfiCode                 |-> [i \in 1 .. 8 |-> 0],
      largeTick               |-> [i \in 1 .. 8 |-> 0],
      largeTickThreshold      |-> [i \in 1 .. 8 |-> 0],
      strikePrice             |-> [i \in 1 .. 8 |-> 0],
      firstTradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate  |-> [i \in 1 .. 2 |-> 0],
      priorSettlementPrice    |-> [i \in 1 .. 8 |-> 0],
      settlementPrice         |-> [i \in 1 .. 8 |-> 0],
      productId               |-> [i \in 1 .. 4 |-> 0],
      underlyingInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      productGroup            |-> [i \in 1 .. 1 |-> 0],
      tradingStatus           |-> [i \in 1 .. 1 |-> 0],
      definitionFlags         |-> [i \in 1 .. 2 |-> 0],
      optionExpiryType        |-> [i \in 1 .. 1 |-> 0],
      logicalExpiry           |-> ZeroLogicalExpiry3 ]

(* Option Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInstrumentDefinitionMessage ==
    { ZeroOptionInstrumentDefinitionMessage }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader3 }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.smallTick = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.largeTick = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.largeTickThreshold = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.priorSettlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.definitionFlags = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.optionExpiryType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentDefinitionMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry3 }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader4 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader4(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader4(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader4 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader4 ==
    { ZeroInstrHeader4 }
        \cup { [ZeroInstrHeader4 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader4 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader4 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader4 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader4 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader4 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader4 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Status Update Message: 39 bytes                                 *)
(***************************************************************************)

TradingStatusUpdateMessage ==
    [ instrHeader    : InstrHeader4,
      limitDownPrice : Sample(8),
      limitUpPrice   : Sample(8),
      tradingStatus  : Sample(1) ]

EncodeTradingStatusUpdateMessage(message) ==
    EncodeInstrHeader4(message.instrHeader)
        \o message.limitDownPrice
        \o message.limitUpPrice
        \o message.tradingStatus

DecodeTradingStatusUpdateMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader4(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(instrHeader.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(limitUpPrice.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ instrHeader    |-> instrHeader.value,
         limitDownPrice |-> limitDownPrice.value,
         limitUpPrice   |-> limitUpPrice.value,
         tradingStatus  |-> tradingStatus.value ], tradingStatus.rest)

ZeroTradingStatusUpdateMessage ==
    [ instrHeader    |-> ZeroInstrHeader4,
      limitDownPrice |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice   |-> [i \in 1 .. 8 |-> 0],
      tradingStatus  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Update Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusUpdateMessage ==
    { ZeroTradingStatusUpdateMessage }
        \cup { [ZeroTradingStatusUpdateMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader4 }
        \cup { [ZeroTradingStatusUpdateMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusUpdateMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusUpdateMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader5 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader5(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader5(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader5 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader5 ==
    { ZeroInstrHeader5 }
        \cup { [ZeroInstrHeader5 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader5 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader5 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader5 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader5 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader5 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader5 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Put Message: 42 bytes                                             *)
(***************************************************************************)

OrderPutMessage ==
    [ instrHeader : InstrHeader5,
      orderId     : Sample(8),
      price       : Sample(8),
      quantity    : Sample(4) ]

EncodeOrderPutMessage(message) ==
    EncodeInstrHeader5(message.instrHeader)
        \o message.orderId
        \o message.price
        \o message.quantity

DecodeOrderPutMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader5(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrHeader.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         orderId     |-> orderId.value,
         price       |-> price.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroOrderPutMessage ==
    [ instrHeader |-> ZeroInstrHeader5,
      orderId     |-> [i \in 1 .. 8 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      quantity    |-> [i \in 1 .. 4 |-> 0] ]

(* Order Put Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPutMessage ==
    { ZeroOrderPutMessage }
        \cup { [ZeroOrderPutMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader5 }
        \cup { [ZeroOrderPutMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderPutMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderPutMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader6 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader6(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader6(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader6 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader6 ==
    { ZeroInstrHeader6 }
        \cup { [ZeroInstrHeader6 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader6 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader6 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader6 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader6 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader6 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader6 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete Message: 30 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ instrHeader : InstrHeader6,
      orderId     : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    EncodeInstrHeader6(message.instrHeader)
        \o message.orderId

DecodeOrderDeleteMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader6(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrHeader.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         orderId     |-> orderId.value ], orderId.rest)

ZeroOrderDeleteMessage ==
    [ instrHeader |-> ZeroInstrHeader6,
      orderId     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader6 }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader7 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader7(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader7(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader7 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader7 ==
    { ZeroInstrHeader7 }
        \cup { [ZeroInstrHeader7 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader7 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader7 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader7 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader7 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader7 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader7 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Implied Order Update Message: 46 bytes                                  *)
(***************************************************************************)

ImpliedOrderUpdateMessage ==
    [ instrHeader : InstrHeader7,
      bestPrice   : Sample(8),
      nextPrice   : Sample(8),
      bestQty     : Sample(4),
      nextQty     : Sample(4) ]

EncodeImpliedOrderUpdateMessage(message) ==
    EncodeInstrHeader7(message.instrHeader)
        \o message.bestPrice
        \o message.nextPrice
        \o message.bestQty
        \o message.nextQty

DecodeImpliedOrderUpdateMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader7(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET bestPrice == ReadBytes(instrHeader.rest, 8) IN IF ~bestPrice.ok THEN Fail ELSE
    LET nextPrice == ReadBytes(bestPrice.rest, 8) IN IF ~nextPrice.ok THEN Fail ELSE
    LET bestQty == ReadBytes(nextPrice.rest, 4) IN IF ~bestQty.ok THEN Fail ELSE
    LET nextQty == ReadBytes(bestQty.rest, 4) IN IF ~nextQty.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         bestPrice   |-> bestPrice.value,
         nextPrice   |-> nextPrice.value,
         bestQty     |-> bestQty.value,
         nextQty     |-> nextQty.value ], nextQty.rest)

ZeroImpliedOrderUpdateMessage ==
    [ instrHeader |-> ZeroInstrHeader7,
      bestPrice   |-> [i \in 1 .. 8 |-> 0],
      nextPrice   |-> [i \in 1 .. 8 |-> 0],
      bestQty     |-> [i \in 1 .. 4 |-> 0],
      nextQty     |-> [i \in 1 .. 4 |-> 0] ]

(* Implied Order Update Message at zero, then each field in turn at the values it is checked at *)
CheckedImpliedOrderUpdateMessage ==
    { ZeroImpliedOrderUpdateMessage }
        \cup { [ZeroImpliedOrderUpdateMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader7 }
        \cup { [ZeroImpliedOrderUpdateMessage EXCEPT !.bestPrice = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderUpdateMessage EXCEPT !.nextPrice = one] : one \in Sample(8) }
        \cup { [ZeroImpliedOrderUpdateMessage EXCEPT !.bestQty = one] : one \in Sample(4) }
        \cup { [ZeroImpliedOrderUpdateMessage EXCEPT !.nextQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader8 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader8(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader8(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader8 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader8 ==
    { ZeroInstrHeader8 }
        \cup { [ZeroInstrHeader8 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader8 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader8 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader8 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader8 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader8 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader8 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Summary Message: 58 bytes                                         *)
(***************************************************************************)

TradeSummaryMessage ==
    [ instrHeader          : InstrHeader8,
      aggressorOrderId     : Sample(8),
      aggressorReceiveTime : Sample(8),
      vwapPrice            : Sample(8),
      deepestPrice         : Sample(8),
      quantity             : Sample(4) ]

EncodeTradeSummaryMessage(message) ==
    EncodeInstrHeader8(message.instrHeader)
        \o message.aggressorOrderId
        \o message.aggressorReceiveTime
        \o message.vwapPrice
        \o message.deepestPrice
        \o message.quantity

DecodeTradeSummaryMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader8(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET aggressorOrderId == ReadBytes(instrHeader.rest, 8) IN IF ~aggressorOrderId.ok THEN Fail ELSE
    LET aggressorReceiveTime == ReadBytes(aggressorOrderId.rest, 8) IN IF ~aggressorReceiveTime.ok THEN Fail ELSE
    LET vwapPrice == ReadBytes(aggressorReceiveTime.rest, 8) IN IF ~vwapPrice.ok THEN Fail ELSE
    LET deepestPrice == ReadBytes(vwapPrice.rest, 8) IN IF ~deepestPrice.ok THEN Fail ELSE
    LET quantity == ReadBytes(deepestPrice.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ instrHeader          |-> instrHeader.value,
         aggressorOrderId     |-> aggressorOrderId.value,
         aggressorReceiveTime |-> aggressorReceiveTime.value,
         vwapPrice            |-> vwapPrice.value,
         deepestPrice         |-> deepestPrice.value,
         quantity             |-> quantity.value ], quantity.rest)

ZeroTradeSummaryMessage ==
    [ instrHeader          |-> ZeroInstrHeader8,
      aggressorOrderId     |-> [i \in 1 .. 8 |-> 0],
      aggressorReceiveTime |-> [i \in 1 .. 8 |-> 0],
      vwapPrice            |-> [i \in 1 .. 8 |-> 0],
      deepestPrice         |-> [i \in 1 .. 8 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryMessage ==
    { ZeroTradeSummaryMessage }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader8 }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.aggressorOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.aggressorReceiveTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.vwapPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.deepestPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader9 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader9(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader9(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader9 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader9 ==
    { ZeroInstrHeader9 }
        \cup { [ZeroInstrHeader9 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader9 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader9 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader9 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader9 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader9 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader9 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 58 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ instrHeader : InstrHeader9,
      matchId     : Sample(8),
      buyOrderId  : Sample(8),
      sellOrderId : Sample(8),
      price       : Sample(8),
      quantity    : Sample(4) ]

EncodeTradeMessage(message) ==
    EncodeInstrHeader9(message.instrHeader)
        \o message.matchId
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.price
        \o message.quantity

DecodeTradeMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader9(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET matchId == ReadBytes(instrHeader.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(matchId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET price == ReadBytes(sellOrderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         matchId     |-> matchId.value,
         buyOrderId  |-> buyOrderId.value,
         sellOrderId |-> sellOrderId.value,
         price       |-> price.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroTradeMessage ==
    [ instrHeader |-> ZeroInstrHeader9,
      matchId     |-> [i \in 1 .. 8 |-> 0],
      buyOrderId  |-> [i \in 1 .. 8 |-> 0],
      sellOrderId |-> [i \in 1 .. 8 |-> 0],
      price       |-> [i \in 1 .. 8 |-> 0],
      quantity    |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader9 }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader10 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader10(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader10(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader10 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader10 ==
    { ZeroInstrHeader10 }
        \cup { [ZeroInstrHeader10 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader10 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader10 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader10 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader10 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader10 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader10 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Amend Message: 62 bytes                                           *)
(***************************************************************************)

TradeAmendMessage ==
    [ instrHeader : InstrHeader10,
      matchId     : Sample(8),
      buyOrderId  : Sample(8),
      sellOrderId : Sample(8),
      oldPrice    : Sample(8),
      newPrice    : Sample(8) ]

EncodeTradeAmendMessage(message) ==
    EncodeInstrHeader10(message.instrHeader)
        \o message.matchId
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.oldPrice
        \o message.newPrice

DecodeTradeAmendMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader10(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET matchId == ReadBytes(instrHeader.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(matchId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET oldPrice == ReadBytes(sellOrderId.rest, 8) IN IF ~oldPrice.ok THEN Fail ELSE
    LET newPrice == ReadBytes(oldPrice.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         matchId     |-> matchId.value,
         buyOrderId  |-> buyOrderId.value,
         sellOrderId |-> sellOrderId.value,
         oldPrice    |-> oldPrice.value,
         newPrice    |-> newPrice.value ], newPrice.rest)

ZeroTradeAmendMessage ==
    [ instrHeader |-> ZeroInstrHeader10,
      matchId     |-> [i \in 1 .. 8 |-> 0],
      buyOrderId  |-> [i \in 1 .. 8 |-> 0],
      sellOrderId |-> [i \in 1 .. 8 |-> 0],
      oldPrice    |-> [i \in 1 .. 8 |-> 0],
      newPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Amend Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeAmendMessage ==
    { ZeroTradeAmendMessage }
        \cup { [ZeroTradeAmendMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader10 }
        \cup { [ZeroTradeAmendMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.oldPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeAmendMessage EXCEPT !.newPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader11 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader11(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader11(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader11 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader11 ==
    { ZeroInstrHeader11 }
        \cup { [ZeroInstrHeader11 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader11 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader11 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader11 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader11 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader11 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader11 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Spread Trade Amend Message: 94 bytes                                    *)
(***************************************************************************)

SpreadTradeAmendMessage ==
    [ instrHeader  : InstrHeader11,
      matchId      : Sample(8),
      buyOrderId   : Sample(8),
      sellOrderId  : Sample(8),
      oldPrice     : Sample(8),
      newPrice     : Sample(8),
      oldLeg1Price : Sample(8),
      newLeg1Price : Sample(8),
      oldLeg2Price : Sample(8),
      newLeg2Price : Sample(8) ]

EncodeSpreadTradeAmendMessage(message) ==
    EncodeInstrHeader11(message.instrHeader)
        \o message.matchId
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.oldPrice
        \o message.newPrice
        \o message.oldLeg1Price
        \o message.newLeg1Price
        \o message.oldLeg2Price
        \o message.newLeg2Price

DecodeSpreadTradeAmendMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader11(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET matchId == ReadBytes(instrHeader.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(matchId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET oldPrice == ReadBytes(sellOrderId.rest, 8) IN IF ~oldPrice.ok THEN Fail ELSE
    LET newPrice == ReadBytes(oldPrice.rest, 8) IN IF ~newPrice.ok THEN Fail ELSE
    LET oldLeg1Price == ReadBytes(newPrice.rest, 8) IN IF ~oldLeg1Price.ok THEN Fail ELSE
    LET newLeg1Price == ReadBytes(oldLeg1Price.rest, 8) IN IF ~newLeg1Price.ok THEN Fail ELSE
    LET oldLeg2Price == ReadBytes(newLeg1Price.rest, 8) IN IF ~oldLeg2Price.ok THEN Fail ELSE
    LET newLeg2Price == ReadBytes(oldLeg2Price.rest, 8) IN IF ~newLeg2Price.ok THEN Fail ELSE
    Ok([ instrHeader  |-> instrHeader.value,
         matchId      |-> matchId.value,
         buyOrderId   |-> buyOrderId.value,
         sellOrderId  |-> sellOrderId.value,
         oldPrice     |-> oldPrice.value,
         newPrice     |-> newPrice.value,
         oldLeg1Price |-> oldLeg1Price.value,
         newLeg1Price |-> newLeg1Price.value,
         oldLeg2Price |-> oldLeg2Price.value,
         newLeg2Price |-> newLeg2Price.value ], newLeg2Price.rest)

ZeroSpreadTradeAmendMessage ==
    [ instrHeader  |-> ZeroInstrHeader11,
      matchId      |-> [i \in 1 .. 8 |-> 0],
      buyOrderId   |-> [i \in 1 .. 8 |-> 0],
      sellOrderId  |-> [i \in 1 .. 8 |-> 0],
      oldPrice     |-> [i \in 1 .. 8 |-> 0],
      newPrice     |-> [i \in 1 .. 8 |-> 0],
      oldLeg1Price |-> [i \in 1 .. 8 |-> 0],
      newLeg1Price |-> [i \in 1 .. 8 |-> 0],
      oldLeg2Price |-> [i \in 1 .. 8 |-> 0],
      newLeg2Price |-> [i \in 1 .. 8 |-> 0] ]

(* Spread Trade Amend Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadTradeAmendMessage ==
    { ZeroSpreadTradeAmendMessage }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader11 }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.oldPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.newPrice = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.oldLeg1Price = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.newLeg1Price = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.oldLeg2Price = one] : one \in Sample(8) }
        \cup { [ZeroSpreadTradeAmendMessage EXCEPT !.newLeg2Price = one] : one \in Sample(8) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader12 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader12(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader12(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader12 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader12 ==
    { ZeroInstrHeader12 }
        \cup { [ZeroInstrHeader12 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader12 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader12 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader12 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader12 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader12 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader12 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Bust Message: 46 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ instrHeader : InstrHeader12,
      matchId     : Sample(8),
      buyOrderId  : Sample(8),
      sellOrderId : Sample(8) ]

EncodeTradeBustMessage(message) ==
    EncodeInstrHeader12(message.instrHeader)
        \o message.matchId
        \o message.buyOrderId
        \o message.sellOrderId

DecodeTradeBustMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader12(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET matchId == ReadBytes(instrHeader.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(matchId.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         matchId     |-> matchId.value,
         buyOrderId  |-> buyOrderId.value,
         sellOrderId |-> sellOrderId.value ], sellOrderId.rest)

ZeroTradeBustMessage ==
    [ instrHeader |-> ZeroInstrHeader12,
      matchId     |-> [i \in 1 .. 8 |-> 0],
      buyOrderId  |-> [i \in 1 .. 8 |-> 0],
      sellOrderId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader12 }
        \cup { [ZeroTradeBustMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.sellOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader13 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader13(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader13(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader13 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader13 ==
    { ZeroInstrHeader13 }
        \cup { [ZeroInstrHeader13 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader13 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader13 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader13 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader13 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader13 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader13 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Market Stat Message: 31 bytes                                           *)
(***************************************************************************)

MarketStatMessage ==
    [ instrHeader : InstrHeader13,
      price       : Sample(8),
      statType    : Sample(1) ]

EncodeMarketStatMessage(message) ==
    EncodeInstrHeader13(message.instrHeader)
        \o message.price
        \o message.statType

DecodeMarketStatMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader13(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET price == ReadBytes(instrHeader.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET statType == ReadBytes(price.rest, 1) IN IF ~statType.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         price       |-> price.value,
         statType    |-> statType.value ], statType.rest)

ZeroMarketStatMessage ==
    [ instrHeader |-> ZeroInstrHeader13,
      price       |-> [i \in 1 .. 8 |-> 0],
      statType    |-> [i \in 1 .. 1 |-> 0] ]

(* Market Stat Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStatMessage ==
    { ZeroMarketStatMessage }
        \cup { [ZeroMarketStatMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader13 }
        \cup { [ZeroMarketStatMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMarketStatMessage EXCEPT !.statType = one] : one \in Sample(1) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader14 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader14(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader14(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader14 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader14 ==
    { ZeroInstrHeader14 }
        \cup { [ZeroInstrHeader14 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader14 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader14 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader14 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader14 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader14 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader14 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Session Volume Message: 34 bytes                                  *)
(***************************************************************************)

TradeSessionVolumeMessage ==
    [ instrHeader : InstrHeader14,
      vwapPrice   : Sample(8),
      tradeVolume : Sample(4) ]

EncodeTradeSessionVolumeMessage(message) ==
    EncodeInstrHeader14(message.instrHeader)
        \o message.vwapPrice
        \o message.tradeVolume

DecodeTradeSessionVolumeMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader14(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET vwapPrice == ReadBytes(instrHeader.rest, 8) IN IF ~vwapPrice.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(vwapPrice.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         vwapPrice   |-> vwapPrice.value,
         tradeVolume |-> tradeVolume.value ], tradeVolume.rest)

ZeroTradeSessionVolumeMessage ==
    [ instrHeader |-> ZeroInstrHeader14,
      vwapPrice   |-> [i \in 1 .. 8 |-> 0],
      tradeVolume |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Session Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSessionVolumeMessage ==
    { ZeroTradeSessionVolumeMessage }
        \cup { [ZeroTradeSessionVolumeMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader14 }
        \cup { [ZeroTradeSessionVolumeMessage EXCEPT !.vwapPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSessionVolumeMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Instr Header: 22 bytes                                                  *)
(***************************************************************************)

InstrHeader15 ==
    [ instrumentFlags    : Sample(1),
      instrumentSide     : Sample(1),
      instrumentId       : Sample(4),
      instrSeqNum        : Sample(4),
      tradingSessionDate : Sample(2),
      reserved           : Sample(2),
      transactTime       : Sample(8) ]

EncodeInstrHeader15(message) ==
    message.instrumentFlags
        \o message.instrumentSide
        \o message.instrumentId
        \o message.instrSeqNum
        \o message.tradingSessionDate
        \o message.reserved
        \o message.transactTime

DecodeInstrHeader15(bytes) ==
    LET instrumentFlags == ReadBytes(bytes, 1) IN IF ~instrumentFlags.ok THEN Fail ELSE
    LET instrumentSide == ReadBytes(instrumentFlags.rest, 1) IN IF ~instrumentSide.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentSide.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrSeqNum == ReadBytes(instrumentId.rest, 4) IN IF ~instrSeqNum.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(instrSeqNum.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingSessionDate.rest, 2) IN IF ~reserved.ok THEN Fail ELSE
    LET transactTime == ReadBytes(reserved.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentFlags    |-> instrumentFlags.value,
         instrumentSide     |-> instrumentSide.value,
         instrumentId       |-> instrumentId.value,
         instrSeqNum        |-> instrSeqNum.value,
         tradingSessionDate |-> tradingSessionDate.value,
         reserved           |-> reserved.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroInstrHeader15 ==
    [ instrumentFlags    |-> [i \in 1 .. 1 |-> 0],
      instrumentSide     |-> [i \in 1 .. 1 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      instrSeqNum        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      reserved           |-> [i \in 1 .. 2 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Instr Header at zero, then each field in turn at the values it is checked at *)
CheckedInstrHeader15 ==
    { ZeroInstrHeader15 }
        \cup { [ZeroInstrHeader15 EXCEPT !.instrumentFlags = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader15 EXCEPT !.instrumentSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrHeader15 EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader15 EXCEPT !.instrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrHeader15 EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader15 EXCEPT !.reserved = one] : one \in Sample(2) }
        \cup { [ZeroInstrHeader15 EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Open Interest Message: 26 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ instrHeader : InstrHeader15,
      quantity    : Sample(4) ]

EncodeOpenInterestMessage(message) ==
    EncodeInstrHeader15(message.instrHeader)
        \o message.quantity

DecodeOpenInterestMessage(bytes) ==
    LET instrHeader == DecodeInstrHeader15(bytes) IN IF ~instrHeader.ok THEN Fail ELSE
    LET quantity == ReadBytes(instrHeader.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ instrHeader |-> instrHeader.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroOpenInterestMessage ==
    [ instrHeader |-> ZeroInstrHeader15,
      quantity    |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.instrHeader = one] : one \in CheckedInstrHeader15 }
        \cup { [ZeroOpenInterestMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry4 ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry4(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry4(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry4 ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry4 ==
    { ZeroLogicalExpiry4 }
        \cup { [ZeroLogicalExpiry4 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry4 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry4 EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry4 EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Start Of Outright Instrument Snapshot Message: 130 bytes                *)
(***************************************************************************)

StartOfOutrightInstrumentSnapshotMessage ==
    [ snapshotSeqNum          : Sample(2),
      lastInstrSeqNum         : Sample(4),
      symbol                  : Sample(24),
      productCode             : Sample(8),
      description             : Sample(32),
      tickSize                : Sample(8),
      cfiCode                 : Sample(8),
      currency                : Sample(8),
      productId               : Sample(4),
      oldContractSize         : Sample(4),
      orderCount              : Sample(4),
      firstTradingSessionDate : Sample(2),
      lastTradingSessionDate  : Sample(2),
      tradingSessionDate      : Sample(2),
      productGroup            : Sample(1),
      tradingStatus           : Sample(1),
      contractSize            : Sample(8),
      logicalExpiry           : LogicalExpiry4 ]

EncodeStartOfOutrightInstrumentSnapshotMessage(message) ==
    message.snapshotSeqNum
        \o message.lastInstrSeqNum
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.tickSize
        \o message.cfiCode
        \o message.currency
        \o message.productId
        \o message.oldContractSize
        \o message.orderCount
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.tradingSessionDate
        \o message.productGroup
        \o message.tradingStatus
        \o message.contractSize
        \o EncodeLogicalExpiry4(message.logicalExpiry)

DecodeStartOfOutrightInstrumentSnapshotMessage(bytes) ==
    LET snapshotSeqNum == ReadBytes(bytes, 2) IN IF ~snapshotSeqNum.ok THEN Fail ELSE
    LET lastInstrSeqNum == ReadBytes(snapshotSeqNum.rest, 4) IN IF ~lastInstrSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastInstrSeqNum.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET tickSize == ReadBytes(description.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(tickSize.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 8) IN IF ~currency.ok THEN Fail ELSE
    LET productId == ReadBytes(currency.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET oldContractSize == ReadBytes(productId.rest, 4) IN IF ~oldContractSize.ok THEN Fail ELSE
    LET orderCount == ReadBytes(oldContractSize.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(orderCount.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET productGroup == ReadBytes(tradingSessionDate.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET contractSize == ReadBytes(tradingStatus.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry4(contractSize.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ snapshotSeqNum          |-> snapshotSeqNum.value,
         lastInstrSeqNum         |-> lastInstrSeqNum.value,
         symbol                  |-> symbol.value,
         productCode             |-> productCode.value,
         description             |-> description.value,
         tickSize                |-> tickSize.value,
         cfiCode                 |-> cfiCode.value,
         currency                |-> currency.value,
         productId               |-> productId.value,
         oldContractSize         |-> oldContractSize.value,
         orderCount              |-> orderCount.value,
         firstTradingSessionDate |-> firstTradingSessionDate.value,
         lastTradingSessionDate  |-> lastTradingSessionDate.value,
         tradingSessionDate      |-> tradingSessionDate.value,
         productGroup            |-> productGroup.value,
         tradingStatus           |-> tradingStatus.value,
         contractSize            |-> contractSize.value,
         logicalExpiry           |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroStartOfOutrightInstrumentSnapshotMessage ==
    [ snapshotSeqNum          |-> [i \in 1 .. 2 |-> 0],
      lastInstrSeqNum         |-> [i \in 1 .. 4 |-> 0],
      symbol                  |-> [i \in 1 .. 24 |-> 0],
      productCode             |-> [i \in 1 .. 8 |-> 0],
      description             |-> [i \in 1 .. 32 |-> 0],
      tickSize                |-> [i \in 1 .. 8 |-> 0],
      cfiCode                 |-> [i \in 1 .. 8 |-> 0],
      currency                |-> [i \in 1 .. 8 |-> 0],
      productId               |-> [i \in 1 .. 4 |-> 0],
      oldContractSize         |-> [i \in 1 .. 4 |-> 0],
      orderCount              |-> [i \in 1 .. 4 |-> 0],
      firstTradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate  |-> [i \in 1 .. 2 |-> 0],
      tradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      productGroup            |-> [i \in 1 .. 1 |-> 0],
      tradingStatus           |-> [i \in 1 .. 1 |-> 0],
      contractSize            |-> [i \in 1 .. 8 |-> 0],
      logicalExpiry           |-> ZeroLogicalExpiry4 ]

(* Start Of Outright Instrument Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfOutrightInstrumentSnapshotMessage ==
    { ZeroStartOfOutrightInstrumentSnapshotMessage }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.snapshotSeqNum = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.lastInstrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.currency = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.oldContractSize = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOutrightInstrumentSnapshotMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry4 }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry5 ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry5(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry5(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry5 ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry5 ==
    { ZeroLogicalExpiry5 }
        \cup { [ZeroLogicalExpiry5 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry5 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry5 EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry5 EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Start Of Spread Instrument Snapshot Message: 131 bytes                  *)
(***************************************************************************)

StartOfSpreadInstrumentSnapshotMessage ==
    [ snapshotSeqNum          : Sample(2),
      lastInstrSeqNum         : Sample(4),
      symbol                  : Sample(24),
      productCode             : Sample(8),
      description             : Sample(32),
      tickSize                : Sample(8),
      cfiCode                 : Sample(8),
      currency                : Sample(8),
      productId               : Sample(4),
      oldContractSize         : Sample(4),
      orderCount              : Sample(4),
      firstTradingSessionDate : Sample(2),
      lastTradingSessionDate  : Sample(2),
      tradingSessionDate      : Sample(2),
      productGroup            : Sample(1),
      tradingStatus           : Sample(1),
      leg1InstrumentId        : Sample(4),
      leg2InstrumentId        : Sample(4),
      spreadBuyConvention     : Sample(1),
      logicalExpiry           : LogicalExpiry5 ]

EncodeStartOfSpreadInstrumentSnapshotMessage(message) ==
    message.snapshotSeqNum
        \o message.lastInstrSeqNum
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.tickSize
        \o message.cfiCode
        \o message.currency
        \o message.productId
        \o message.oldContractSize
        \o message.orderCount
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.tradingSessionDate
        \o message.productGroup
        \o message.tradingStatus
        \o message.leg1InstrumentId
        \o message.leg2InstrumentId
        \o message.spreadBuyConvention
        \o EncodeLogicalExpiry5(message.logicalExpiry)

DecodeStartOfSpreadInstrumentSnapshotMessage(bytes) ==
    LET snapshotSeqNum == ReadBytes(bytes, 2) IN IF ~snapshotSeqNum.ok THEN Fail ELSE
    LET lastInstrSeqNum == ReadBytes(snapshotSeqNum.rest, 4) IN IF ~lastInstrSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastInstrSeqNum.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET tickSize == ReadBytes(description.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(tickSize.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 8) IN IF ~currency.ok THEN Fail ELSE
    LET productId == ReadBytes(currency.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET oldContractSize == ReadBytes(productId.rest, 4) IN IF ~oldContractSize.ok THEN Fail ELSE
    LET orderCount == ReadBytes(oldContractSize.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(orderCount.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET productGroup == ReadBytes(tradingSessionDate.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET leg1InstrumentId == ReadBytes(tradingStatus.rest, 4) IN IF ~leg1InstrumentId.ok THEN Fail ELSE
    LET leg2InstrumentId == ReadBytes(leg1InstrumentId.rest, 4) IN IF ~leg2InstrumentId.ok THEN Fail ELSE
    LET spreadBuyConvention == ReadBytes(leg2InstrumentId.rest, 1) IN IF ~spreadBuyConvention.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry5(spreadBuyConvention.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ snapshotSeqNum          |-> snapshotSeqNum.value,
         lastInstrSeqNum         |-> lastInstrSeqNum.value,
         symbol                  |-> symbol.value,
         productCode             |-> productCode.value,
         description             |-> description.value,
         tickSize                |-> tickSize.value,
         cfiCode                 |-> cfiCode.value,
         currency                |-> currency.value,
         productId               |-> productId.value,
         oldContractSize         |-> oldContractSize.value,
         orderCount              |-> orderCount.value,
         firstTradingSessionDate |-> firstTradingSessionDate.value,
         lastTradingSessionDate  |-> lastTradingSessionDate.value,
         tradingSessionDate      |-> tradingSessionDate.value,
         productGroup            |-> productGroup.value,
         tradingStatus           |-> tradingStatus.value,
         leg1InstrumentId        |-> leg1InstrumentId.value,
         leg2InstrumentId        |-> leg2InstrumentId.value,
         spreadBuyConvention     |-> spreadBuyConvention.value,
         logicalExpiry           |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroStartOfSpreadInstrumentSnapshotMessage ==
    [ snapshotSeqNum          |-> [i \in 1 .. 2 |-> 0],
      lastInstrSeqNum         |-> [i \in 1 .. 4 |-> 0],
      symbol                  |-> [i \in 1 .. 24 |-> 0],
      productCode             |-> [i \in 1 .. 8 |-> 0],
      description             |-> [i \in 1 .. 32 |-> 0],
      tickSize                |-> [i \in 1 .. 8 |-> 0],
      cfiCode                 |-> [i \in 1 .. 8 |-> 0],
      currency                |-> [i \in 1 .. 8 |-> 0],
      productId               |-> [i \in 1 .. 4 |-> 0],
      oldContractSize         |-> [i \in 1 .. 4 |-> 0],
      orderCount              |-> [i \in 1 .. 4 |-> 0],
      firstTradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate  |-> [i \in 1 .. 2 |-> 0],
      tradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      productGroup            |-> [i \in 1 .. 1 |-> 0],
      tradingStatus           |-> [i \in 1 .. 1 |-> 0],
      leg1InstrumentId        |-> [i \in 1 .. 4 |-> 0],
      leg2InstrumentId        |-> [i \in 1 .. 4 |-> 0],
      spreadBuyConvention     |-> [i \in 1 .. 1 |-> 0],
      logicalExpiry           |-> ZeroLogicalExpiry5 ]

(* Start Of Spread Instrument Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfSpreadInstrumentSnapshotMessage ==
    { ZeroStartOfSpreadInstrumentSnapshotMessage }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.snapshotSeqNum = one] : one \in Sample(2) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.lastInstrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.currency = one] : one \in Sample(8) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.oldContractSize = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.leg1InstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.leg2InstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.spreadBuyConvention = one] : one \in Sample(1) }
        \cup { [ZeroStartOfSpreadInstrumentSnapshotMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry5 }

(***************************************************************************)
(* Logical Expiry: 8 bytes                                                 *)
(***************************************************************************)

LogicalExpiry6 ==
    [ year        : Sample(2),
      month       : Sample(2),
      weekOfMonth : Sample(2),
      dayOfMonth  : Sample(2) ]

EncodeLogicalExpiry6(message) ==
    message.year
        \o message.month
        \o message.weekOfMonth
        \o message.dayOfMonth

DecodeLogicalExpiry6(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET weekOfMonth == ReadBytes(month.rest, 2) IN IF ~weekOfMonth.ok THEN Fail ELSE
    LET dayOfMonth == ReadBytes(weekOfMonth.rest, 2) IN IF ~dayOfMonth.ok THEN Fail ELSE
    Ok([ year        |-> year.value,
         month       |-> month.value,
         weekOfMonth |-> weekOfMonth.value,
         dayOfMonth  |-> dayOfMonth.value ], dayOfMonth.rest)

ZeroLogicalExpiry6 ==
    [ year        |-> [i \in 1 .. 2 |-> 0],
      month       |-> [i \in 1 .. 2 |-> 0],
      weekOfMonth |-> [i \in 1 .. 2 |-> 0],
      dayOfMonth  |-> [i \in 1 .. 2 |-> 0] ]

(* Logical Expiry at zero, then each field in turn at the values it is checked at *)
CheckedLogicalExpiry6 ==
    { ZeroLogicalExpiry6 }
        \cup { [ZeroLogicalExpiry6 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry6 EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry6 EXCEPT !.weekOfMonth = one] : one \in Sample(2) }
        \cup { [ZeroLogicalExpiry6 EXCEPT !.dayOfMonth = one] : one \in Sample(2) }

(***************************************************************************)
(* Start Of Option Instrument Snapshot Message: 141 bytes                  *)
(***************************************************************************)

StartOfOptionInstrumentSnapshotMessage ==
    [ snapshotSeqNum          : Sample(2),
      lastInstrSeqNum         : Sample(4),
      symbol                  : Sample(24),
      productCode             : Sample(8),
      description             : Sample(32),
      smallTick               : Sample(8),
      cfiCode                 : Sample(8),
      largeTick               : Sample(8),
      largeTickThreshold      : Sample(8),
      strikePrice             : Sample(8),
      productId               : Sample(4),
      underlyingInstrumentId  : Sample(4),
      orderCount              : Sample(4),
      firstTradingSessionDate : Sample(2),
      lastTradingSessionDate  : Sample(2),
      tradingSessionDate      : Sample(2),
      productGroup            : Sample(1),
      tradingStatus           : Sample(1),
      definitionFlags         : Sample(2),
      optionExpiryType        : Sample(1),
      logicalExpiry           : LogicalExpiry6 ]

EncodeStartOfOptionInstrumentSnapshotMessage(message) ==
    message.snapshotSeqNum
        \o message.lastInstrSeqNum
        \o message.symbol
        \o message.productCode
        \o message.description
        \o message.smallTick
        \o message.cfiCode
        \o message.largeTick
        \o message.largeTickThreshold
        \o message.strikePrice
        \o message.productId
        \o message.underlyingInstrumentId
        \o message.orderCount
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.tradingSessionDate
        \o message.productGroup
        \o message.tradingStatus
        \o message.definitionFlags
        \o message.optionExpiryType
        \o EncodeLogicalExpiry6(message.logicalExpiry)

DecodeStartOfOptionInstrumentSnapshotMessage(bytes) ==
    LET snapshotSeqNum == ReadBytes(bytes, 2) IN IF ~snapshotSeqNum.ok THEN Fail ELSE
    LET lastInstrSeqNum == ReadBytes(snapshotSeqNum.rest, 4) IN IF ~lastInstrSeqNum.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastInstrSeqNum.rest, 24) IN IF ~symbol.ok THEN Fail ELSE
    LET productCode == ReadBytes(symbol.rest, 8) IN IF ~productCode.ok THEN Fail ELSE
    LET description == ReadBytes(productCode.rest, 32) IN IF ~description.ok THEN Fail ELSE
    LET smallTick == ReadBytes(description.rest, 8) IN IF ~smallTick.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(smallTick.rest, 8) IN IF ~cfiCode.ok THEN Fail ELSE
    LET largeTick == ReadBytes(cfiCode.rest, 8) IN IF ~largeTick.ok THEN Fail ELSE
    LET largeTickThreshold == ReadBytes(largeTick.rest, 8) IN IF ~largeTickThreshold.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(largeTickThreshold.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET productId == ReadBytes(strikePrice.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(productId.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET orderCount == ReadBytes(underlyingInstrumentId.rest, 4) IN IF ~orderCount.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(orderCount.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET productGroup == ReadBytes(tradingSessionDate.rest, 1) IN IF ~productGroup.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(productGroup.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET definitionFlags == ReadBytes(tradingStatus.rest, 2) IN IF ~definitionFlags.ok THEN Fail ELSE
    LET optionExpiryType == ReadBytes(definitionFlags.rest, 1) IN IF ~optionExpiryType.ok THEN Fail ELSE
    LET logicalExpiry == DecodeLogicalExpiry6(optionExpiryType.rest) IN IF ~logicalExpiry.ok THEN Fail ELSE
    Ok([ snapshotSeqNum          |-> snapshotSeqNum.value,
         lastInstrSeqNum         |-> lastInstrSeqNum.value,
         symbol                  |-> symbol.value,
         productCode             |-> productCode.value,
         description             |-> description.value,
         smallTick               |-> smallTick.value,
         cfiCode                 |-> cfiCode.value,
         largeTick               |-> largeTick.value,
         largeTickThreshold      |-> largeTickThreshold.value,
         strikePrice             |-> strikePrice.value,
         productId               |-> productId.value,
         underlyingInstrumentId  |-> underlyingInstrumentId.value,
         orderCount              |-> orderCount.value,
         firstTradingSessionDate |-> firstTradingSessionDate.value,
         lastTradingSessionDate  |-> lastTradingSessionDate.value,
         tradingSessionDate      |-> tradingSessionDate.value,
         productGroup            |-> productGroup.value,
         tradingStatus           |-> tradingStatus.value,
         definitionFlags         |-> definitionFlags.value,
         optionExpiryType        |-> optionExpiryType.value,
         logicalExpiry           |-> logicalExpiry.value ], logicalExpiry.rest)

ZeroStartOfOptionInstrumentSnapshotMessage ==
    [ snapshotSeqNum          |-> [i \in 1 .. 2 |-> 0],
      lastInstrSeqNum         |-> [i \in 1 .. 4 |-> 0],
      symbol                  |-> [i \in 1 .. 24 |-> 0],
      productCode             |-> [i \in 1 .. 8 |-> 0],
      description             |-> [i \in 1 .. 32 |-> 0],
      smallTick               |-> [i \in 1 .. 8 |-> 0],
      cfiCode                 |-> [i \in 1 .. 8 |-> 0],
      largeTick               |-> [i \in 1 .. 8 |-> 0],
      largeTickThreshold      |-> [i \in 1 .. 8 |-> 0],
      strikePrice             |-> [i \in 1 .. 8 |-> 0],
      productId               |-> [i \in 1 .. 4 |-> 0],
      underlyingInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      orderCount              |-> [i \in 1 .. 4 |-> 0],
      firstTradingSessionDate |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate  |-> [i \in 1 .. 2 |-> 0],
      tradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      productGroup            |-> [i \in 1 .. 1 |-> 0],
      tradingStatus           |-> [i \in 1 .. 1 |-> 0],
      definitionFlags         |-> [i \in 1 .. 2 |-> 0],
      optionExpiryType        |-> [i \in 1 .. 1 |-> 0],
      logicalExpiry           |-> ZeroLogicalExpiry6 ]

(* Start Of Option Instrument Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfOptionInstrumentSnapshotMessage ==
    { ZeroStartOfOptionInstrumentSnapshotMessage }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.snapshotSeqNum = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.lastInstrSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.symbol = one] : one \in Sample(24) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.productCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.description = one] : one \in Sample(32) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.smallTick = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.cfiCode = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.largeTick = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.largeTickThreshold = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.orderCount = one] : one \in Sample(4) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.productGroup = one] : one \in Sample(1) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.definitionFlags = one] : one \in Sample(2) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.optionExpiryType = one] : one \in Sample(1) }
        \cup { [ZeroStartOfOptionInstrumentSnapshotMessage EXCEPT !.logicalExpiry = one] : one \in CheckedLogicalExpiry6 }

(***************************************************************************)
(* Order Snapshot Message: 30 bytes                                        *)
(***************************************************************************)

OrderSnapshotMessage ==
    [ snapshotSeqNum : Sample(2),
      quantity       : Sample(4),
      transactTime   : Sample(8),
      orderId        : Sample(8),
      price          : Sample(8) ]

EncodeOrderSnapshotMessage(message) ==
    message.snapshotSeqNum
        \o message.quantity
        \o message.transactTime
        \o message.orderId
        \o message.price

DecodeOrderSnapshotMessage(bytes) ==
    LET snapshotSeqNum == ReadBytes(bytes, 2) IN IF ~snapshotSeqNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(snapshotSeqNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET transactTime == ReadBytes(quantity.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ snapshotSeqNum |-> snapshotSeqNum.value,
         quantity       |-> quantity.value,
         transactTime   |-> transactTime.value,
         orderId        |-> orderId.value,
         price          |-> price.value ], price.rest)

ZeroOrderSnapshotMessage ==
    [ snapshotSeqNum |-> [i \in 1 .. 2 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      transactTime   |-> [i \in 1 .. 8 |-> 0],
      orderId        |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0] ]

(* Order Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderSnapshotMessage ==
    { ZeroOrderSnapshotMessage }
        \cup { [ZeroOrderSnapshotMessage EXCEPT !.snapshotSeqNum = one] : one \in Sample(2) }
        \cup { [ZeroOrderSnapshotMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderSnapshotMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderSnapshotMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderSnapshotMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Snapshot Message: 160 bytes                                      *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ snapshotSeqNum               : Sample(2),
      tradeVolume                  : Sample(4),
      indicativeOpenPrice          : Sample(8),
      dayOpenPrice                 : Sample(8),
      closePrice                   : Sample(8),
      lowPrice                     : Sample(8),
      highPrice                    : Sample(8),
      vwapPriceOptional            : Sample(8),
      settlementPrice              : Sample(8),
      lastTradePrice               : Sample(8),
      lastTradeTime                : Sample(8),
      bestBidImpliedPrice          : Sample(8),
      bestAskImpliedPrice          : Sample(8),
      nextBidImpliedPrice          : Sample(8),
      nextAskImpliedPrice          : Sample(8),
      limitDownPrice               : Sample(8),
      limitUpPrice                 : Sample(8),
      lastTradeQty                 : Sample(4),
      openInterest                 : Sample(4),
      bestBidImpliedQty            : Sample(4),
      bestAskImpliedQty            : Sample(4),
      nextBidImpliedQty            : Sample(4),
      nextAskImpliedQty            : Sample(4),
      priorSettlementPriceOptional : Sample(8),
      definitionFlags              : Sample(2) ]

EncodeEndOfSnapshotMessage(message) ==
    message.snapshotSeqNum
        \o message.tradeVolume
        \o message.indicativeOpenPrice
        \o message.dayOpenPrice
        \o message.closePrice
        \o message.lowPrice
        \o message.highPrice
        \o message.vwapPriceOptional
        \o message.settlementPrice
        \o message.lastTradePrice
        \o message.lastTradeTime
        \o message.bestBidImpliedPrice
        \o message.bestAskImpliedPrice
        \o message.nextBidImpliedPrice
        \o message.nextAskImpliedPrice
        \o message.limitDownPrice
        \o message.limitUpPrice
        \o message.lastTradeQty
        \o message.openInterest
        \o message.bestBidImpliedQty
        \o message.bestAskImpliedQty
        \o message.nextBidImpliedQty
        \o message.nextAskImpliedQty
        \o message.priorSettlementPriceOptional
        \o message.definitionFlags

DecodeEndOfSnapshotMessage(bytes) ==
    LET snapshotSeqNum == ReadBytes(bytes, 2) IN IF ~snapshotSeqNum.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(snapshotSeqNum.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET indicativeOpenPrice == ReadBytes(tradeVolume.rest, 8) IN IF ~indicativeOpenPrice.ok THEN Fail ELSE
    LET dayOpenPrice == ReadBytes(indicativeOpenPrice.rest, 8) IN IF ~dayOpenPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(dayOpenPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(closePrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(lowPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET vwapPriceOptional == ReadBytes(highPrice.rest, 8) IN IF ~vwapPriceOptional.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(vwapPriceOptional.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(settlementPrice.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeTime == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeTime.ok THEN Fail ELSE
    LET bestBidImpliedPrice == ReadBytes(lastTradeTime.rest, 8) IN IF ~bestBidImpliedPrice.ok THEN Fail ELSE
    LET bestAskImpliedPrice == ReadBytes(bestBidImpliedPrice.rest, 8) IN IF ~bestAskImpliedPrice.ok THEN Fail ELSE
    LET nextBidImpliedPrice == ReadBytes(bestAskImpliedPrice.rest, 8) IN IF ~nextBidImpliedPrice.ok THEN Fail ELSE
    LET nextAskImpliedPrice == ReadBytes(nextBidImpliedPrice.rest, 8) IN IF ~nextAskImpliedPrice.ok THEN Fail ELSE
    LET limitDownPrice == ReadBytes(nextAskImpliedPrice.rest, 8) IN IF ~limitDownPrice.ok THEN Fail ELSE
    LET limitUpPrice == ReadBytes(limitDownPrice.rest, 8) IN IF ~limitUpPrice.ok THEN Fail ELSE
    LET lastTradeQty == ReadBytes(limitUpPrice.rest, 4) IN IF ~lastTradeQty.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastTradeQty.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET bestBidImpliedQty == ReadBytes(openInterest.rest, 4) IN IF ~bestBidImpliedQty.ok THEN Fail ELSE
    LET bestAskImpliedQty == ReadBytes(bestBidImpliedQty.rest, 4) IN IF ~bestAskImpliedQty.ok THEN Fail ELSE
    LET nextBidImpliedQty == ReadBytes(bestAskImpliedQty.rest, 4) IN IF ~nextBidImpliedQty.ok THEN Fail ELSE
    LET nextAskImpliedQty == ReadBytes(nextBidImpliedQty.rest, 4) IN IF ~nextAskImpliedQty.ok THEN Fail ELSE
    LET priorSettlementPriceOptional == ReadBytes(nextAskImpliedQty.rest, 8) IN IF ~priorSettlementPriceOptional.ok THEN Fail ELSE
    LET definitionFlags == ReadBytes(priorSettlementPriceOptional.rest, 2) IN IF ~definitionFlags.ok THEN Fail ELSE
    Ok([ snapshotSeqNum               |-> snapshotSeqNum.value,
         tradeVolume                  |-> tradeVolume.value,
         indicativeOpenPrice          |-> indicativeOpenPrice.value,
         dayOpenPrice                 |-> dayOpenPrice.value,
         closePrice                   |-> closePrice.value,
         lowPrice                     |-> lowPrice.value,
         highPrice                    |-> highPrice.value,
         vwapPriceOptional            |-> vwapPriceOptional.value,
         settlementPrice              |-> settlementPrice.value,
         lastTradePrice               |-> lastTradePrice.value,
         lastTradeTime                |-> lastTradeTime.value,
         bestBidImpliedPrice          |-> bestBidImpliedPrice.value,
         bestAskImpliedPrice          |-> bestAskImpliedPrice.value,
         nextBidImpliedPrice          |-> nextBidImpliedPrice.value,
         nextAskImpliedPrice          |-> nextAskImpliedPrice.value,
         limitDownPrice               |-> limitDownPrice.value,
         limitUpPrice                 |-> limitUpPrice.value,
         lastTradeQty                 |-> lastTradeQty.value,
         openInterest                 |-> openInterest.value,
         bestBidImpliedQty            |-> bestBidImpliedQty.value,
         bestAskImpliedQty            |-> bestAskImpliedQty.value,
         nextBidImpliedQty            |-> nextBidImpliedQty.value,
         nextAskImpliedQty            |-> nextAskImpliedQty.value,
         priorSettlementPriceOptional |-> priorSettlementPriceOptional.value,
         definitionFlags              |-> definitionFlags.value ], definitionFlags.rest)

ZeroEndOfSnapshotMessage ==
    [ snapshotSeqNum               |-> [i \in 1 .. 2 |-> 0],
      tradeVolume                  |-> [i \in 1 .. 4 |-> 0],
      indicativeOpenPrice          |-> [i \in 1 .. 8 |-> 0],
      dayOpenPrice                 |-> [i \in 1 .. 8 |-> 0],
      closePrice                   |-> [i \in 1 .. 8 |-> 0],
      lowPrice                     |-> [i \in 1 .. 8 |-> 0],
      highPrice                    |-> [i \in 1 .. 8 |-> 0],
      vwapPriceOptional            |-> [i \in 1 .. 8 |-> 0],
      settlementPrice              |-> [i \in 1 .. 8 |-> 0],
      lastTradePrice               |-> [i \in 1 .. 8 |-> 0],
      lastTradeTime                |-> [i \in 1 .. 8 |-> 0],
      bestBidImpliedPrice          |-> [i \in 1 .. 8 |-> 0],
      bestAskImpliedPrice          |-> [i \in 1 .. 8 |-> 0],
      nextBidImpliedPrice          |-> [i \in 1 .. 8 |-> 0],
      nextAskImpliedPrice          |-> [i \in 1 .. 8 |-> 0],
      limitDownPrice               |-> [i \in 1 .. 8 |-> 0],
      limitUpPrice                 |-> [i \in 1 .. 8 |-> 0],
      lastTradeQty                 |-> [i \in 1 .. 4 |-> 0],
      openInterest                 |-> [i \in 1 .. 4 |-> 0],
      bestBidImpliedQty            |-> [i \in 1 .. 4 |-> 0],
      bestAskImpliedQty            |-> [i \in 1 .. 4 |-> 0],
      nextBidImpliedQty            |-> [i \in 1 .. 4 |-> 0],
      nextAskImpliedQty            |-> [i \in 1 .. 4 |-> 0],
      priorSettlementPriceOptional |-> [i \in 1 .. 8 |-> 0],
      definitionFlags              |-> [i \in 1 .. 2 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.snapshotSeqNum = one] : one \in Sample(2) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.indicativeOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.dayOpenPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.vwapPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.lastTradeTime = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.bestBidImpliedPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.bestAskImpliedPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.nextBidImpliedPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.nextAskImpliedPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.limitDownPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.limitUpPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.lastTradeQty = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.bestBidImpliedQty = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.bestAskImpliedQty = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.nextBidImpliedQty = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.nextAskImpliedQty = one] : one \in Sample(4) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.priorSettlementPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.definitionFlags = one] : one \in Sample(2) }

(***************************************************************************)
(* End Of Cycle Message: 4 bytes                                           *)
(***************************************************************************)

EndOfCycleMessage ==
    [ activeInstrumentCount : Sample(4) ]

EncodeEndOfCycleMessage(message) ==
    message.activeInstrumentCount

DecodeEndOfCycleMessage(bytes) ==
    LET activeInstrumentCount == ReadBytes(bytes, 4) IN IF ~activeInstrumentCount.ok THEN Fail ELSE
    Ok([ activeInstrumentCount |-> activeInstrumentCount.value ], activeInstrumentCount.rest)

ZeroEndOfCycleMessage ==
    [ activeInstrumentCount |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Cycle Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfCycleMessage ==
    { ZeroEndOfCycleMessage }
        \cup { [ZeroEndOfCycleMessage EXCEPT !.activeInstrumentCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request Message: 9 bytes                                     *)
(***************************************************************************)

RetransmitRequestMessage ==
    [ beginSeqNum  : Sample(8),
      messageCount : Sample(1) ]

EncodeRetransmitRequestMessage(message) ==
    message.beginSeqNum
        \o message.messageCount

DecodeRetransmitRequestMessage(bytes) ==
    LET beginSeqNum == ReadBytes(bytes, 8) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET messageCount == ReadBytes(beginSeqNum.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    Ok([ beginSeqNum  |-> beginSeqNum.value,
         messageCount |-> messageCount.value ], messageCount.rest)

ZeroRetransmitRequestMessage ==
    [ beginSeqNum  |-> [i \in 1 .. 8 |-> 0],
      messageCount |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequestMessage ==
    { ZeroRetransmitRequestMessage }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.messageCount = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmit Reject Message: 49 bytes                                     *)
(***************************************************************************)

RetransmitRejectMessage ==
    [ retryDelayNanos : Sample(8),
      details         : Sample(40),
      reason          : Sample(1) ]

EncodeRetransmitRejectMessage(message) ==
    message.retryDelayNanos
        \o message.details
        \o message.reason

DecodeRetransmitRejectMessage(bytes) ==
    LET retryDelayNanos == ReadBytes(bytes, 8) IN IF ~retryDelayNanos.ok THEN Fail ELSE
    LET details == ReadBytes(retryDelayNanos.rest, 40) IN IF ~details.ok THEN Fail ELSE
    LET reason == ReadBytes(details.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ retryDelayNanos |-> retryDelayNanos.value,
         details         |-> details.value,
         reason          |-> reason.value ], reason.rest)

ZeroRetransmitRejectMessage ==
    [ retryDelayNanos |-> [i \in 1 .. 8 |-> 0],
      details         |-> [i \in 1 .. 40 |-> 0],
      reason          |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRejectMessage ==
    { ZeroRetransmitRejectMessage }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.retryDelayNanos = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.details = one] : one \in Sample(40) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

OutrightInstrumentDefinitionMessageCode == 10  \* 0x0a
SpreadInstrumentDefinitionMessageCode == 11  \* 0x0b
OptionInstrumentDefinitionMessageCode == 12  \* 0x0c
TradingStatusUpdateMessageCode == 17  \* 0x11
OrderPutMessageCode == 20  \* 0x14
OrderDeleteMessageCode == 21  \* 0x15
ImpliedOrderUpdateMessageCode == 22  \* 0x16
TradeSummaryMessageCode == 33  \* 0x21
TradeMessageCode == 30  \* 0x1e
TradeAmendMessageCode == 31  \* 0x1f
SpreadTradeAmendMessageCode == 34  \* 0x22
TradeBustMessageCode == 32  \* 0x20
MarketStatMessageCode == 40  \* 0x28
TradeSessionVolumeMessageCode == 41  \* 0x29
OpenInterestMessageCode == 42  \* 0x2a
StartOfOutrightInstrumentSnapshotMessageCode == 110  \* 0x6e
StartOfSpreadInstrumentSnapshotMessageCode == 111  \* 0x6f
StartOfOptionInstrumentSnapshotMessageCode == 112  \* 0x70
OrderSnapshotMessageCode == 120  \* 0x78
EndOfSnapshotMessageCode == 122  \* 0x7a
EndOfCycleMessageCode == 124  \* 0x7c
RetransmitRequestMessageCode == 200  \* 0xc8
RetransmitRejectMessageCode == 202  \* 0xca

Payload ==
    [ tag : {OutrightInstrumentDefinitionMessageCode}, body : OutrightInstrumentDefinitionMessage ]
        \cup [ tag : {SpreadInstrumentDefinitionMessageCode}, body : SpreadInstrumentDefinitionMessage ]
        \cup [ tag : {OptionInstrumentDefinitionMessageCode}, body : OptionInstrumentDefinitionMessage ]
        \cup [ tag : {TradingStatusUpdateMessageCode}, body : TradingStatusUpdateMessage ]
        \cup [ tag : {OrderPutMessageCode}, body : OrderPutMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {ImpliedOrderUpdateMessageCode}, body : ImpliedOrderUpdateMessage ]
        \cup [ tag : {TradeSummaryMessageCode}, body : TradeSummaryMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeAmendMessageCode}, body : TradeAmendMessage ]
        \cup [ tag : {SpreadTradeAmendMessageCode}, body : SpreadTradeAmendMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {MarketStatMessageCode}, body : MarketStatMessage ]
        \cup [ tag : {TradeSessionVolumeMessageCode}, body : TradeSessionVolumeMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {StartOfOutrightInstrumentSnapshotMessageCode}, body : StartOfOutrightInstrumentSnapshotMessage ]
        \cup [ tag : {StartOfSpreadInstrumentSnapshotMessageCode}, body : StartOfSpreadInstrumentSnapshotMessage ]
        \cup [ tag : {StartOfOptionInstrumentSnapshotMessageCode}, body : StartOfOptionInstrumentSnapshotMessage ]
        \cup [ tag : {OrderSnapshotMessageCode}, body : OrderSnapshotMessage ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]
        \cup [ tag : {EndOfCycleMessageCode}, body : EndOfCycleMessage ]
        \cup [ tag : {RetransmitRequestMessageCode}, body : RetransmitRequestMessage ]
        \cup [ tag : {RetransmitRejectMessageCode}, body : RetransmitRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = OutrightInstrumentDefinitionMessageCode -> EncodeOutrightInstrumentDefinitionMessage(message.body)
      [] message.tag = SpreadInstrumentDefinitionMessageCode -> EncodeSpreadInstrumentDefinitionMessage(message.body)
      [] message.tag = OptionInstrumentDefinitionMessageCode -> EncodeOptionInstrumentDefinitionMessage(message.body)
      [] message.tag = TradingStatusUpdateMessageCode -> EncodeTradingStatusUpdateMessage(message.body)
      [] message.tag = OrderPutMessageCode -> EncodeOrderPutMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = ImpliedOrderUpdateMessageCode -> EncodeImpliedOrderUpdateMessage(message.body)
      [] message.tag = TradeSummaryMessageCode -> EncodeTradeSummaryMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeAmendMessageCode -> EncodeTradeAmendMessage(message.body)
      [] message.tag = SpreadTradeAmendMessageCode -> EncodeSpreadTradeAmendMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = MarketStatMessageCode -> EncodeMarketStatMessage(message.body)
      [] message.tag = TradeSessionVolumeMessageCode -> EncodeTradeSessionVolumeMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = StartOfOutrightInstrumentSnapshotMessageCode -> EncodeStartOfOutrightInstrumentSnapshotMessage(message.body)
      [] message.tag = StartOfSpreadInstrumentSnapshotMessageCode -> EncodeStartOfSpreadInstrumentSnapshotMessage(message.body)
      [] message.tag = StartOfOptionInstrumentSnapshotMessageCode -> EncodeStartOfOptionInstrumentSnapshotMessage(message.body)
      [] message.tag = OrderSnapshotMessageCode -> EncodeOrderSnapshotMessage(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)
      [] message.tag = EndOfCycleMessageCode -> EncodeEndOfCycleMessage(message.body)
      [] message.tag = RetransmitRequestMessageCode -> EncodeRetransmitRequestMessage(message.body)
      [] message.tag = RetransmitRejectMessageCode -> EncodeRetransmitRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OutrightInstrumentDefinitionMessageCode -> DecodeOutrightInstrumentDefinitionMessage(bytes)
              [] tag = SpreadInstrumentDefinitionMessageCode -> DecodeSpreadInstrumentDefinitionMessage(bytes)
              [] tag = OptionInstrumentDefinitionMessageCode -> DecodeOptionInstrumentDefinitionMessage(bytes)
              [] tag = TradingStatusUpdateMessageCode -> DecodeTradingStatusUpdateMessage(bytes)
              [] tag = OrderPutMessageCode -> DecodeOrderPutMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = ImpliedOrderUpdateMessageCode -> DecodeImpliedOrderUpdateMessage(bytes)
              [] tag = TradeSummaryMessageCode -> DecodeTradeSummaryMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeAmendMessageCode -> DecodeTradeAmendMessage(bytes)
              [] tag = SpreadTradeAmendMessageCode -> DecodeSpreadTradeAmendMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = MarketStatMessageCode -> DecodeMarketStatMessage(bytes)
              [] tag = TradeSessionVolumeMessageCode -> DecodeTradeSessionVolumeMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = StartOfOutrightInstrumentSnapshotMessageCode -> DecodeStartOfOutrightInstrumentSnapshotMessage(bytes)
              [] tag = StartOfSpreadInstrumentSnapshotMessageCode -> DecodeStartOfSpreadInstrumentSnapshotMessage(bytes)
              [] tag = StartOfOptionInstrumentSnapshotMessageCode -> DecodeStartOfOptionInstrumentSnapshotMessage(bytes)
              [] tag = OrderSnapshotMessageCode -> DecodeOrderSnapshotMessage(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] tag = EndOfCycleMessageCode -> DecodeEndOfCycleMessage(bytes)
              [] tag = RetransmitRequestMessageCode -> DecodeRetransmitRequestMessage(bytes)
              [] tag = RetransmitRejectMessageCode -> DecodeRetransmitRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OutrightInstrumentDefinitionMessageCode, body |-> ZeroOutrightInstrumentDefinitionMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OutrightInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedOutrightInstrumentDefinitionMessage }
        \cup { [tag |-> SpreadInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedSpreadInstrumentDefinitionMessage }
        \cup { [tag |-> OptionInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedOptionInstrumentDefinitionMessage }
        \cup { [tag |-> TradingStatusUpdateMessageCode, body |-> one] : one \in CheckedTradingStatusUpdateMessage }
        \cup { [tag |-> OrderPutMessageCode, body |-> one] : one \in CheckedOrderPutMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> ImpliedOrderUpdateMessageCode, body |-> one] : one \in CheckedImpliedOrderUpdateMessage }
        \cup { [tag |-> TradeSummaryMessageCode, body |-> one] : one \in CheckedTradeSummaryMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeAmendMessageCode, body |-> one] : one \in CheckedTradeAmendMessage }
        \cup { [tag |-> SpreadTradeAmendMessageCode, body |-> one] : one \in CheckedSpreadTradeAmendMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> MarketStatMessageCode, body |-> one] : one \in CheckedMarketStatMessage }
        \cup { [tag |-> TradeSessionVolumeMessageCode, body |-> one] : one \in CheckedTradeSessionVolumeMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> StartOfOutrightInstrumentSnapshotMessageCode, body |-> one] : one \in CheckedStartOfOutrightInstrumentSnapshotMessage }
        \cup { [tag |-> StartOfSpreadInstrumentSnapshotMessageCode, body |-> one] : one \in CheckedStartOfSpreadInstrumentSnapshotMessage }
        \cup { [tag |-> StartOfOptionInstrumentSnapshotMessageCode, body |-> one] : one \in CheckedStartOfOptionInstrumentSnapshotMessage }
        \cup { [tag |-> OrderSnapshotMessageCode, body |-> one] : one \in CheckedOrderSnapshotMessage }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }
        \cup { [tag |-> EndOfCycleMessageCode, body |-> one] : one \in CheckedEndOfCycleMessage }
        \cup { [tag |-> RetransmitRequestMessageCode, body |-> one] : one \in CheckedRetransmitRequestMessage }
        \cup { [tag |-> RetransmitRejectMessageCode, body |-> one] : one \in CheckedRetransmitRejectMessage }

(***************************************************************************)
(* Sbe Message, framed by Frame Length                                     *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload,
      padding     : SampleBytes ]

EncodeSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)
        \o message.padding

(* Frame Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    LET padding == Ok(payload.rest, << >>) IN IF ~padding.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value,
         padding     |-> padding.value ], padding.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload,
      padding     |-> << >> ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroSbeMessage EXCEPT !.padding = one] : one \in SampleBytes }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the field that counts them says *)
RECURSIVE ReadSbeMessageList(_, _)
ReadSbeMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> OutrightInstrumentDefinitionMessageCode, body |-> ZeroOutrightInstrumentDefinitionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SpreadInstrumentDefinitionMessageCode, body |-> ZeroSpreadInstrumentDefinitionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OptionInstrumentDefinitionMessageCode, body |-> ZeroOptionInstrumentDefinitionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradingStatusUpdateMessageCode, body |-> ZeroTradingStatusUpdateMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderPutMessageCode, body |-> ZeroOrderPutMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ImpliedOrderUpdateMessageCode, body |-> ZeroImpliedOrderUpdateMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeSummaryMessageCode, body |-> ZeroTradeSummaryMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeAmendMessageCode, body |-> ZeroTradeAmendMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SpreadTradeAmendMessageCode, body |-> ZeroSpreadTradeAmendMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> MarketStatMessageCode, body |-> ZeroMarketStatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeSessionVolumeMessageCode, body |-> ZeroTradeSessionVolumeMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> StartOfOutrightInstrumentSnapshotMessageCode, body |-> ZeroStartOfOutrightInstrumentSnapshotMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> StartOfSpreadInstrumentSnapshotMessageCode, body |-> ZeroStartOfSpreadInstrumentSnapshotMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> StartOfOptionInstrumentSnapshotMessageCode, body |-> ZeroStartOfOptionInstrumentSnapshotMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderSnapshotMessageCode, body |-> ZeroOrderSnapshotMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> EndOfSnapshotMessageCode, body |-> ZeroEndOfSnapshotMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> EndOfCycleMessageCode, body |-> ZeroEndOfCycleMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RetransmitRequestMessageCode, body |-> ZeroRetransmitRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RetransmitRejectMessageCode, body |-> ZeroRetransmitRejectMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sendingTime          : Sample(8),
      seqNum               : Sample(8),
      channelId            : Sample(2),
      packetFlags          : Sample(1),
      snapshotInstrumentId : Sample(4),
      sbeMessage           : SampleLists(OneSbeMessage) ]

EncodePacket(message) ==
    message.sendingTime
        \o message.seqNum
        \o message.channelId
        \o message.packetFlags
        \o EncodeUIntBE(Len(message.sbeMessage), 1)
        \o message.snapshotInstrumentId
        \o EncodeSbeMessageList(message.sbeMessage)

DecodePacket(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET seqNum == ReadBytes(sendingTime.rest, 8) IN IF ~seqNum.ok THEN Fail ELSE
    LET channelId == ReadBytes(seqNum.rest, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET packetFlags == ReadBytes(channelId.rest, 1) IN IF ~packetFlags.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(packetFlags.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET snapshotInstrumentId == ReadBytes(messageCount.rest, 4) IN IF ~snapshotInstrumentId.ok THEN Fail ELSE
    LET sbeMessage == ReadSbeMessageList(snapshotInstrumentId.rest, messageCount.value) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         seqNum               |-> seqNum.value,
         channelId            |-> channelId.value,
         packetFlags          |-> packetFlags.value,
         snapshotInstrumentId |-> snapshotInstrumentId.value,
         sbeMessage           |-> sbeMessage.value ], sbeMessage.rest)

ZeroPacket ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      seqNum               |-> [i \in 1 .. 8 |-> 0],
      channelId            |-> [i \in 1 .. 2 |-> 0],
      packetFlags          |-> [i \in 1 .. 1 |-> 0],
      snapshotInstrumentId |-> [i \in 1 .. 4 |-> 0],
      sbeMessage           |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetFlags = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.snapshotInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader ==
    \A message \in CheckedInstrHeader :
        LET read == DecodeInstrHeader(EncodeInstrHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry ==
    \A message \in CheckedLogicalExpiry :
        LET read == DecodeLogicalExpiry(EncodeLogicalExpiry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Outright Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOutrightInstrumentDefinitionMessage ==
    \A message \in CheckedOutrightInstrumentDefinitionMessage :
        LET read == DecodeOutrightInstrumentDefinitionMessage(EncodeOutrightInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader2 ==
    \A message \in CheckedInstrHeader2 :
        LET read == DecodeInstrHeader2(EncodeInstrHeader2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry2 ==
    \A message \in CheckedLogicalExpiry2 :
        LET read == DecodeLogicalExpiry2(EncodeLogicalExpiry2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadInstrumentDefinitionMessage ==
    \A message \in CheckedSpreadInstrumentDefinitionMessage :
        LET read == DecodeSpreadInstrumentDefinitionMessage(EncodeSpreadInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader3 ==
    \A message \in CheckedInstrHeader3 :
        LET read == DecodeInstrHeader3(EncodeInstrHeader3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry3 ==
    \A message \in CheckedLogicalExpiry3 :
        LET read == DecodeLogicalExpiry3(EncodeLogicalExpiry3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionInstrumentDefinitionMessage ==
    \A message \in CheckedOptionInstrumentDefinitionMessage :
        LET read == DecodeOptionInstrumentDefinitionMessage(EncodeOptionInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader4 ==
    \A message \in CheckedInstrHeader4 :
        LET read == DecodeInstrHeader4(EncodeInstrHeader4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusUpdateMessage ==
    \A message \in CheckedTradingStatusUpdateMessage :
        LET read == DecodeTradingStatusUpdateMessage(EncodeTradingStatusUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader5 ==
    \A message \in CheckedInstrHeader5 :
        LET read == DecodeInstrHeader5(EncodeInstrHeader5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Put Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPutMessage ==
    \A message \in CheckedOrderPutMessage :
        LET read == DecodeOrderPutMessage(EncodeOrderPutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader6 ==
    \A message \in CheckedInstrHeader6 :
        LET read == DecodeInstrHeader6(EncodeInstrHeader6(message))
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

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader7 ==
    \A message \in CheckedInstrHeader7 :
        LET read == DecodeInstrHeader7(EncodeInstrHeader7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Implied Order Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripImpliedOrderUpdateMessage ==
    \A message \in CheckedImpliedOrderUpdateMessage :
        LET read == DecodeImpliedOrderUpdateMessage(EncodeImpliedOrderUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader8 ==
    \A message \in CheckedInstrHeader8 :
        LET read == DecodeInstrHeader8(EncodeInstrHeader8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSummaryMessage ==
    \A message \in CheckedTradeSummaryMessage :
        LET read == DecodeTradeSummaryMessage(EncodeTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader9 ==
    \A message \in CheckedInstrHeader9 :
        LET read == DecodeInstrHeader9(EncodeInstrHeader9(message))
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

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader10 ==
    \A message \in CheckedInstrHeader10 :
        LET read == DecodeInstrHeader10(EncodeInstrHeader10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Amend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeAmendMessage ==
    \A message \in CheckedTradeAmendMessage :
        LET read == DecodeTradeAmendMessage(EncodeTradeAmendMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader11 ==
    \A message \in CheckedInstrHeader11 :
        LET read == DecodeInstrHeader11(EncodeInstrHeader11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Trade Amend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadTradeAmendMessage ==
    \A message \in CheckedSpreadTradeAmendMessage :
        LET read == DecodeSpreadTradeAmendMessage(EncodeSpreadTradeAmendMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader12 ==
    \A message \in CheckedInstrHeader12 :
        LET read == DecodeInstrHeader12(EncodeInstrHeader12(message))
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

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader13 ==
    \A message \in CheckedInstrHeader13 :
        LET read == DecodeInstrHeader13(EncodeInstrHeader13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Stat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStatMessage ==
    \A message \in CheckedMarketStatMessage :
        LET read == DecodeMarketStatMessage(EncodeMarketStatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader14 ==
    \A message \in CheckedInstrHeader14 :
        LET read == DecodeInstrHeader14(EncodeInstrHeader14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Session Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSessionVolumeMessage ==
    \A message \in CheckedTradeSessionVolumeMessage :
        LET read == DecodeTradeSessionVolumeMessage(EncodeTradeSessionVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Header decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrHeader15 ==
    \A message \in CheckedInstrHeader15 :
        LET read == DecodeInstrHeader15(EncodeInstrHeader15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestMessage ==
    \A message \in CheckedOpenInterestMessage :
        LET read == DecodeOpenInterestMessage(EncodeOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry4 ==
    \A message \in CheckedLogicalExpiry4 :
        LET read == DecodeLogicalExpiry4(EncodeLogicalExpiry4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Outright Instrument Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfOutrightInstrumentSnapshotMessage ==
    \A message \in CheckedStartOfOutrightInstrumentSnapshotMessage :
        LET read == DecodeStartOfOutrightInstrumentSnapshotMessage(EncodeStartOfOutrightInstrumentSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry5 ==
    \A message \in CheckedLogicalExpiry5 :
        LET read == DecodeLogicalExpiry5(EncodeLogicalExpiry5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Spread Instrument Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfSpreadInstrumentSnapshotMessage ==
    \A message \in CheckedStartOfSpreadInstrumentSnapshotMessage :
        LET read == DecodeStartOfSpreadInstrumentSnapshotMessage(EncodeStartOfSpreadInstrumentSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logical Expiry decodes back to what was encoded, and leaves nothing over *)
RoundTripLogicalExpiry6 ==
    \A message \in CheckedLogicalExpiry6 :
        LET read == DecodeLogicalExpiry6(EncodeLogicalExpiry6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Of Option Instrument Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartOfOptionInstrumentSnapshotMessage ==
    \A message \in CheckedStartOfOptionInstrumentSnapshotMessage :
        LET read == DecodeStartOfOptionInstrumentSnapshotMessage(EncodeStartOfOptionInstrumentSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderSnapshotMessage ==
    \A message \in CheckedOrderSnapshotMessage :
        LET read == DecodeOrderSnapshotMessage(EncodeOrderSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Cycle Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfCycleMessage ==
    \A message \in CheckedEndOfCycleMessage :
        LET read == DecodeEndOfCycleMessage(EncodeEndOfCycleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequestMessage ==
    \A message \in CheckedRetransmitRequestMessage :
        LET read == DecodeRetransmitRequestMessage(EncodeRetransmitRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRejectMessage ==
    \A message \in CheckedRetransmitRejectMessage :
        LET read == DecodeRetransmitRejectMessage(EncodeRetransmitRejectMessage(message))
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

(* Frame Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
