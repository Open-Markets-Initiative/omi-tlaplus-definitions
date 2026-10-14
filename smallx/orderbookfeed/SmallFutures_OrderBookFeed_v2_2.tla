------------------ MODULE SmallFutures_OrderBookFeed_v2_2 ------------------
(***************************************************************************)
(* The Small Exchange Order Book Feed v2.2                                 *)
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
(* Note: Incremental Message Instructions is a bit field set, checked as   *)
(* its 2 bytes rather than bit by bit.                                     *)
(*                                                                         *)
(* Note: Trade Conditions is a bit field set, checked as its 2 bytes       *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Order Attributes is a bit field set, checked as its 2 bytes       *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Snapshot Message Instructions is a bit field set, checked as its  *)
(* 2 bytes rather than bit by bit.                                         *)
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
(* Instrument Trading Status Incremental Message: 25 bytes                 *)
(***************************************************************************)

InstrumentTradingStatusIncrementalMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2) ]

EncodeInstrumentTradingStatusIncrementalMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions

DecodeInstrumentTradingStatusIncrementalMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value ], incrementalMessageInstructions.rest)

ZeroInstrumentTradingStatusIncrementalMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Trading Status Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentTradingStatusIncrementalMessage ==
    { ZeroInstrumentTradingStatusIncrementalMessage }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentTradingStatusIncrementalMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }

(***************************************************************************)
(* Incremental Trade Group: 43 bytes                                       *)
(***************************************************************************)

IncrementalTradeGroup ==
    [ tradeId         : Sample(8),
      price           : Sample(8),
      size            : Sample(8),
      aggressorSide   : Sample(1),
      buyOrderId      : Sample(8),
      sellOrderId     : Sample(8),
      tradeConditions : Sample(2) ]

EncodeIncrementalTradeGroup(message) ==
    message.tradeId
        \o message.price
        \o message.size
        \o message.aggressorSide
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.tradeConditions

DecodeIncrementalTradeGroup(bytes) ==
    LET tradeId == ReadBytes(bytes, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(size.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(aggressorSide.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET tradeConditions == ReadBytes(sellOrderId.rest, 2) IN IF ~tradeConditions.ok THEN Fail ELSE
    Ok([ tradeId         |-> tradeId.value,
         price           |-> price.value,
         size            |-> size.value,
         aggressorSide   |-> aggressorSide.value,
         buyOrderId      |-> buyOrderId.value,
         sellOrderId     |-> sellOrderId.value,
         tradeConditions |-> tradeConditions.value ], tradeConditions.rest)

ZeroIncrementalTradeGroup ==
    [ tradeId         |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      size            |-> [i \in 1 .. 8 |-> 0],
      aggressorSide   |-> [i \in 1 .. 1 |-> 0],
      buyOrderId      |-> [i \in 1 .. 8 |-> 0],
      sellOrderId     |-> [i \in 1 .. 8 |-> 0],
      tradeConditions |-> [i \in 1 .. 2 |-> 0] ]

(* Incremental Trade Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalTradeGroup ==
    { ZeroIncrementalTradeGroup }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalTradeGroup EXCEPT !.tradeConditions = one] : one \in Sample(2) }

(* A run of Incremental Trade Group, written one after another *)
RECURSIVE EncodeIncrementalTradeGroupList(_)
EncodeIncrementalTradeGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalTradeGroup(Head(messages)) \o EncodeIncrementalTradeGroupList(Tail(messages))

(* As many Incremental Trade Group as the field that counts them says *)
RECURSIVE ReadIncrementalTradeGroupList(_, _)
ReadIncrementalTradeGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalTradeGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalTradeGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Trade Group of each kind, for the lists that carry them *)
OneIncrementalTradeGroup == { ZeroIncrementalTradeGroup }

(***************************************************************************)
(* Incremental Trade Groups                                                *)
(***************************************************************************)

IncrementalTradeGroups ==
    [ blockLength           : Sample(2),
      incrementalTradeGroup : SampleLists(OneIncrementalTradeGroup) ]

EncodeIncrementalTradeGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalTradeGroup), 1)
        \o EncodeIncrementalTradeGroupList(message.incrementalTradeGroup)

DecodeIncrementalTradeGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalTradeGroup == ReadIncrementalTradeGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalTradeGroup.ok THEN Fail ELSE
    Ok([ blockLength           |-> blockLength.value,
         incrementalTradeGroup |-> incrementalTradeGroup.value ], incrementalTradeGroup.rest)

ZeroIncrementalTradeGroups ==
    [ blockLength           |-> [i \in 1 .. 2 |-> 0],
      incrementalTradeGroup |-> << >> ]

(* Incremental Trade Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalTradeGroups ==
    { ZeroIncrementalTradeGroups }
        \cup { [ZeroIncrementalTradeGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalTradeGroups EXCEPT !.incrementalTradeGroup = one] : one \in SampleLists(OneIncrementalTradeGroup) }

(***************************************************************************)
(* Trades Incremental Message                                              *)
(***************************************************************************)

TradesIncrementalMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      lastTradePrice                 : Sample(8),
      lastTradeSize                  : Sample(8),
      lastTradeTimeTimestampOptional : Sample(8),
      totalVolumeQuantity            : Sample(8),
      incrementalTradeGroups         : IncrementalTradeGroups ]

EncodeTradesIncrementalMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.lastTradePrice
        \o message.lastTradeSize
        \o message.lastTradeTimeTimestampOptional
        \o message.totalVolumeQuantity
        \o EncodeIncrementalTradeGroups(message.incrementalTradeGroups)

DecodeTradesIncrementalMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(incrementalMessageInstructions.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET lastTradeTimeTimestampOptional == ReadBytes(lastTradeSize.rest, 8) IN IF ~lastTradeTimeTimestampOptional.ok THEN Fail ELSE
    LET totalVolumeQuantity == ReadBytes(lastTradeTimeTimestampOptional.rest, 8) IN IF ~totalVolumeQuantity.ok THEN Fail ELSE
    LET incrementalTradeGroups == DecodeIncrementalTradeGroups(totalVolumeQuantity.rest) IN IF ~incrementalTradeGroups.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         lastTradePrice                 |-> lastTradePrice.value,
         lastTradeSize                  |-> lastTradeSize.value,
         lastTradeTimeTimestampOptional |-> lastTradeTimeTimestampOptional.value,
         totalVolumeQuantity            |-> totalVolumeQuantity.value,
         incrementalTradeGroups         |-> incrementalTradeGroups.value ], incrementalTradeGroups.rest)

ZeroTradesIncrementalMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      lastTradePrice                 |-> [i \in 1 .. 8 |-> 0],
      lastTradeSize                  |-> [i \in 1 .. 8 |-> 0],
      lastTradeTimeTimestampOptional |-> [i \in 1 .. 8 |-> 0],
      totalVolumeQuantity            |-> [i \in 1 .. 8 |-> 0],
      incrementalTradeGroups         |-> ZeroIncrementalTradeGroups ]

(* Trades Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedTradesIncrementalMessage ==
    { ZeroTradesIncrementalMessage }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.lastTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.lastTradeTimeTimestampOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.totalVolumeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradesIncrementalMessage EXCEPT !.incrementalTradeGroups = one] : one \in CheckedIncrementalTradeGroups }

(***************************************************************************)
(* Trade Correct Group: 52 bytes                                           *)
(***************************************************************************)

TradeCorrectGroup ==
    [ tradeUpdateAction : Sample(1),
      tradeId           : Sample(8),
      time              : Sample(8),
      price             : Sample(8),
      size              : Sample(8),
      aggressorSide     : Sample(1),
      buyOrderId        : Sample(8),
      sellOrderId       : Sample(8),
      tradeConditions   : Sample(2) ]

EncodeTradeCorrectGroup(message) ==
    message.tradeUpdateAction
        \o message.tradeId
        \o message.time
        \o message.price
        \o message.size
        \o message.aggressorSide
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.tradeConditions

DecodeTradeCorrectGroup(bytes) ==
    LET tradeUpdateAction == ReadBytes(bytes, 1) IN IF ~tradeUpdateAction.ok THEN Fail ELSE
    LET tradeId == ReadBytes(tradeUpdateAction.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET time == ReadBytes(tradeId.rest, 8) IN IF ~time.ok THEN Fail ELSE
    LET price == ReadBytes(time.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(size.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(aggressorSide.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET tradeConditions == ReadBytes(sellOrderId.rest, 2) IN IF ~tradeConditions.ok THEN Fail ELSE
    Ok([ tradeUpdateAction |-> tradeUpdateAction.value,
         tradeId           |-> tradeId.value,
         time              |-> time.value,
         price             |-> price.value,
         size              |-> size.value,
         aggressorSide     |-> aggressorSide.value,
         buyOrderId        |-> buyOrderId.value,
         sellOrderId       |-> sellOrderId.value,
         tradeConditions   |-> tradeConditions.value ], tradeConditions.rest)

ZeroTradeCorrectGroup ==
    [ tradeUpdateAction |-> [i \in 1 .. 1 |-> 0],
      tradeId           |-> [i \in 1 .. 8 |-> 0],
      time              |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      size              |-> [i \in 1 .. 8 |-> 0],
      aggressorSide     |-> [i \in 1 .. 1 |-> 0],
      buyOrderId        |-> [i \in 1 .. 8 |-> 0],
      sellOrderId       |-> [i \in 1 .. 8 |-> 0],
      tradeConditions   |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Correct Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectGroup ==
    { ZeroTradeCorrectGroup }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.tradeUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectGroup EXCEPT !.tradeConditions = one] : one \in Sample(2) }

(* A run of Trade Correct Group, written one after another *)
RECURSIVE EncodeTradeCorrectGroupList(_)
EncodeTradeCorrectGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeCorrectGroup(Head(messages)) \o EncodeTradeCorrectGroupList(Tail(messages))

(* As many Trade Correct Group as the field that counts them says *)
RECURSIVE ReadTradeCorrectGroupList(_, _)
ReadTradeCorrectGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeCorrectGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeCorrectGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Correct Group of each kind, for the lists that carry them *)
OneTradeCorrectGroup == { ZeroTradeCorrectGroup }

(***************************************************************************)
(* Trade Correct Groups                                                    *)
(***************************************************************************)

TradeCorrectGroups ==
    [ blockLength       : Sample(2),
      tradeCorrectGroup : SampleLists(OneTradeCorrectGroup) ]

EncodeTradeCorrectGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeCorrectGroup), 1)
        \o EncodeTradeCorrectGroupList(message.tradeCorrectGroup)

DecodeTradeCorrectGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeCorrectGroup == ReadTradeCorrectGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeCorrectGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         tradeCorrectGroup |-> tradeCorrectGroup.value ], tradeCorrectGroup.rest)

ZeroTradeCorrectGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      tradeCorrectGroup |-> << >> ]

(* Trade Correct Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectGroups ==
    { ZeroTradeCorrectGroups }
        \cup { [ZeroTradeCorrectGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectGroups EXCEPT !.tradeCorrectGroup = one] : one \in SampleLists(OneTradeCorrectGroup) }

(***************************************************************************)
(* Trade Correct Message                                                   *)
(***************************************************************************)

TradeCorrectMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      lastTradePrice                 : Sample(8),
      lastTradeSize                  : Sample(8),
      lastTradeTimeTimestampOptional : Sample(8),
      totalVolumeQuantity            : Sample(8),
      tradeCorrectGroups             : TradeCorrectGroups ]

EncodeTradeCorrectMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.lastTradePrice
        \o message.lastTradeSize
        \o message.lastTradeTimeTimestampOptional
        \o message.totalVolumeQuantity
        \o EncodeTradeCorrectGroups(message.tradeCorrectGroups)

DecodeTradeCorrectMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(incrementalMessageInstructions.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET lastTradeTimeTimestampOptional == ReadBytes(lastTradeSize.rest, 8) IN IF ~lastTradeTimeTimestampOptional.ok THEN Fail ELSE
    LET totalVolumeQuantity == ReadBytes(lastTradeTimeTimestampOptional.rest, 8) IN IF ~totalVolumeQuantity.ok THEN Fail ELSE
    LET tradeCorrectGroups == DecodeTradeCorrectGroups(totalVolumeQuantity.rest) IN IF ~tradeCorrectGroups.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         lastTradePrice                 |-> lastTradePrice.value,
         lastTradeSize                  |-> lastTradeSize.value,
         lastTradeTimeTimestampOptional |-> lastTradeTimeTimestampOptional.value,
         totalVolumeQuantity            |-> totalVolumeQuantity.value,
         tradeCorrectGroups             |-> tradeCorrectGroups.value ], tradeCorrectGroups.rest)

ZeroTradeCorrectMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      lastTradePrice                 |-> [i \in 1 .. 8 |-> 0],
      lastTradeSize                  |-> [i \in 1 .. 8 |-> 0],
      lastTradeTimeTimestampOptional |-> [i \in 1 .. 8 |-> 0],
      totalVolumeQuantity            |-> [i \in 1 .. 8 |-> 0],
      tradeCorrectGroups             |-> ZeroTradeCorrectGroups ]

(* Trade Correct Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectMessage ==
    { ZeroTradeCorrectMessage }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.lastTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.lastTradeTimeTimestampOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.totalVolumeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectMessage EXCEPT !.tradeCorrectGroups = one] : one \in CheckedTradeCorrectGroups }

(***************************************************************************)
(* Trade Bust Group: 51 bytes                                              *)
(***************************************************************************)

TradeBustGroup ==
    [ tradeId         : Sample(8),
      time            : Sample(8),
      price           : Sample(8),
      size            : Sample(8),
      aggressorSide   : Sample(1),
      buyOrderId      : Sample(8),
      sellOrderId     : Sample(8),
      tradeConditions : Sample(2) ]

EncodeTradeBustGroup(message) ==
    message.tradeId
        \o message.time
        \o message.price
        \o message.size
        \o message.aggressorSide
        \o message.buyOrderId
        \o message.sellOrderId
        \o message.tradeConditions

DecodeTradeBustGroup(bytes) ==
    LET tradeId == ReadBytes(bytes, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET time == ReadBytes(tradeId.rest, 8) IN IF ~time.ok THEN Fail ELSE
    LET price == ReadBytes(time.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(size.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET buyOrderId == ReadBytes(aggressorSide.rest, 8) IN IF ~buyOrderId.ok THEN Fail ELSE
    LET sellOrderId == ReadBytes(buyOrderId.rest, 8) IN IF ~sellOrderId.ok THEN Fail ELSE
    LET tradeConditions == ReadBytes(sellOrderId.rest, 2) IN IF ~tradeConditions.ok THEN Fail ELSE
    Ok([ tradeId         |-> tradeId.value,
         time            |-> time.value,
         price           |-> price.value,
         size            |-> size.value,
         aggressorSide   |-> aggressorSide.value,
         buyOrderId      |-> buyOrderId.value,
         sellOrderId     |-> sellOrderId.value,
         tradeConditions |-> tradeConditions.value ], tradeConditions.rest)

ZeroTradeBustGroup ==
    [ tradeId         |-> [i \in 1 .. 8 |-> 0],
      time            |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      size            |-> [i \in 1 .. 8 |-> 0],
      aggressorSide   |-> [i \in 1 .. 1 |-> 0],
      buyOrderId      |-> [i \in 1 .. 8 |-> 0],
      sellOrderId     |-> [i \in 1 .. 8 |-> 0],
      tradeConditions |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Bust Group at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustGroup ==
    { ZeroTradeBustGroup }
        \cup { [ZeroTradeBustGroup EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustGroup EXCEPT !.buyOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.sellOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustGroup EXCEPT !.tradeConditions = one] : one \in Sample(2) }

(* A run of Trade Bust Group, written one after another *)
RECURSIVE EncodeTradeBustGroupList(_)
EncodeTradeBustGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeBustGroup(Head(messages)) \o EncodeTradeBustGroupList(Tail(messages))

(* As many Trade Bust Group as the field that counts them says *)
RECURSIVE ReadTradeBustGroupList(_, _)
ReadTradeBustGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeBustGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeBustGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Bust Group of each kind, for the lists that carry them *)
OneTradeBustGroup == { ZeroTradeBustGroup }

(***************************************************************************)
(* Trade Bust Groups                                                       *)
(***************************************************************************)

TradeBustGroups ==
    [ blockLength    : Sample(2),
      tradeBustGroup : SampleLists(OneTradeBustGroup) ]

EncodeTradeBustGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.tradeBustGroup), 1)
        \o EncodeTradeBustGroupList(message.tradeBustGroup)

DecodeTradeBustGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET tradeBustGroup == ReadTradeBustGroupList(numInGroup.rest, numInGroup.value) IN IF ~tradeBustGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         tradeBustGroup |-> tradeBustGroup.value ], tradeBustGroup.rest)

ZeroTradeBustGroups ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      tradeBustGroup |-> << >> ]

(* Trade Bust Groups at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustGroups ==
    { ZeroTradeBustGroups }
        \cup { [ZeroTradeBustGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustGroups EXCEPT !.tradeBustGroup = one] : one \in SampleLists(OneTradeBustGroup) }

(***************************************************************************)
(* Trade Bust Message                                                      *)
(***************************************************************************)

TradeBustMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      lastTradePrice                 : Sample(8),
      lastTradeSize                  : Sample(8),
      lastTradeTimeTimestampOptional : Sample(8),
      totalVolumeQuantity            : Sample(8),
      tradeBustGroups                : TradeBustGroups ]

EncodeTradeBustMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.lastTradePrice
        \o message.lastTradeSize
        \o message.lastTradeTimeTimestampOptional
        \o message.totalVolumeQuantity
        \o EncodeTradeBustGroups(message.tradeBustGroups)

DecodeTradeBustMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(incrementalMessageInstructions.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET lastTradeTimeTimestampOptional == ReadBytes(lastTradeSize.rest, 8) IN IF ~lastTradeTimeTimestampOptional.ok THEN Fail ELSE
    LET totalVolumeQuantity == ReadBytes(lastTradeTimeTimestampOptional.rest, 8) IN IF ~totalVolumeQuantity.ok THEN Fail ELSE
    LET tradeBustGroups == DecodeTradeBustGroups(totalVolumeQuantity.rest) IN IF ~tradeBustGroups.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         lastTradePrice                 |-> lastTradePrice.value,
         lastTradeSize                  |-> lastTradeSize.value,
         lastTradeTimeTimestampOptional |-> lastTradeTimeTimestampOptional.value,
         totalVolumeQuantity            |-> totalVolumeQuantity.value,
         tradeBustGroups                |-> tradeBustGroups.value ], tradeBustGroups.rest)

ZeroTradeBustMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      lastTradePrice                 |-> [i \in 1 .. 8 |-> 0],
      lastTradeSize                  |-> [i \in 1 .. 8 |-> 0],
      lastTradeTimeTimestampOptional |-> [i \in 1 .. 8 |-> 0],
      totalVolumeQuantity            |-> [i \in 1 .. 8 |-> 0],
      tradeBustGroups                |-> ZeroTradeBustGroups ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.lastTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.lastTradeTimeTimestampOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.totalVolumeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeBustGroups = one] : one \in CheckedTradeBustGroups }

(***************************************************************************)
(* Incremetal Orders Group: 44 bytes                                       *)
(***************************************************************************)

IncremetalOrdersGroup ==
    [ orderUpdateAction     : Sample(1),
      orderId               : Sample(8),
      tradeIdOptional       : Sample(8),
      side                  : Sample(1),
      priceOptional         : Sample(8),
      size                  : Sample(8),
      orderPriorityOptional : Sample(8),
      orderAttributes       : Sample(2) ]

EncodeIncremetalOrdersGroup(message) ==
    message.orderUpdateAction
        \o message.orderId
        \o message.tradeIdOptional
        \o message.side
        \o message.priceOptional
        \o message.size
        \o message.orderPriorityOptional
        \o message.orderAttributes

DecodeIncremetalOrdersGroup(bytes) ==
    LET orderUpdateAction == ReadBytes(bytes, 1) IN IF ~orderUpdateAction.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderUpdateAction.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeIdOptional == ReadBytes(orderId.rest, 8) IN IF ~tradeIdOptional.ok THEN Fail ELSE
    LET side == ReadBytes(tradeIdOptional.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(side.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET size == ReadBytes(priceOptional.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET orderPriorityOptional == ReadBytes(size.rest, 8) IN IF ~orderPriorityOptional.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(orderPriorityOptional.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    Ok([ orderUpdateAction     |-> orderUpdateAction.value,
         orderId               |-> orderId.value,
         tradeIdOptional       |-> tradeIdOptional.value,
         side                  |-> side.value,
         priceOptional         |-> priceOptional.value,
         size                  |-> size.value,
         orderPriorityOptional |-> orderPriorityOptional.value,
         orderAttributes       |-> orderAttributes.value ], orderAttributes.rest)

ZeroIncremetalOrdersGroup ==
    [ orderUpdateAction     |-> [i \in 1 .. 1 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      tradeIdOptional       |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      priceOptional         |-> [i \in 1 .. 8 |-> 0],
      size                  |-> [i \in 1 .. 8 |-> 0],
      orderPriorityOptional |-> [i \in 1 .. 8 |-> 0],
      orderAttributes       |-> [i \in 1 .. 2 |-> 0] ]

(* Incremetal Orders Group at zero, then each field in turn at the values it is checked at *)
CheckedIncremetalOrdersGroup ==
    { ZeroIncremetalOrdersGroup }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.orderUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.tradeIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.orderPriorityOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncremetalOrdersGroup EXCEPT !.orderAttributes = one] : one \in Sample(2) }

(* A run of Incremetal Orders Group, written one after another *)
RECURSIVE EncodeIncremetalOrdersGroupList(_)
EncodeIncremetalOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncremetalOrdersGroup(Head(messages)) \o EncodeIncremetalOrdersGroupList(Tail(messages))

(* As many Incremetal Orders Group as the field that counts them says *)
RECURSIVE ReadIncremetalOrdersGroupList(_, _)
ReadIncremetalOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncremetalOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncremetalOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremetal Orders Group of each kind, for the lists that carry them *)
OneIncremetalOrdersGroup == { ZeroIncremetalOrdersGroup }

(***************************************************************************)
(* Incremetal Orders Groups                                                *)
(***************************************************************************)

IncremetalOrdersGroups ==
    [ blockLength           : Sample(2),
      incremetalOrdersGroup : SampleLists(OneIncremetalOrdersGroup) ]

EncodeIncremetalOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incremetalOrdersGroup), 1)
        \o EncodeIncremetalOrdersGroupList(message.incremetalOrdersGroup)

DecodeIncremetalOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incremetalOrdersGroup == ReadIncremetalOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~incremetalOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength           |-> blockLength.value,
         incremetalOrdersGroup |-> incremetalOrdersGroup.value ], incremetalOrdersGroup.rest)

ZeroIncremetalOrdersGroups ==
    [ blockLength           |-> [i \in 1 .. 2 |-> 0],
      incremetalOrdersGroup |-> << >> ]

(* Incremetal Orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncremetalOrdersGroups ==
    { ZeroIncremetalOrdersGroups }
        \cup { [ZeroIncremetalOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncremetalOrdersGroups EXCEPT !.incremetalOrdersGroup = one] : one \in SampleLists(OneIncremetalOrdersGroup) }

(***************************************************************************)
(* Order Book Incremental Message                                          *)
(***************************************************************************)

OrderBookIncrementalMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      incremetalOrdersGroups         : IncremetalOrdersGroups ]

EncodeOrderBookIncrementalMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o EncodeIncremetalOrdersGroups(message.incremetalOrdersGroups)

DecodeOrderBookIncrementalMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET incremetalOrdersGroups == DecodeIncremetalOrdersGroups(incrementalMessageInstructions.rest) IN IF ~incremetalOrdersGroups.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         incremetalOrdersGroups         |-> incremetalOrdersGroups.value ], incremetalOrdersGroups.rest)

ZeroOrderBookIncrementalMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      incremetalOrdersGroups         |-> ZeroIncremetalOrdersGroups ]

(* Order Book Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookIncrementalMessage ==
    { ZeroOrderBookIncrementalMessage }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookIncrementalMessage EXCEPT !.incremetalOrdersGroups = one] : one \in CheckedIncremetalOrdersGroups }

(***************************************************************************)
(* Market Summary Incremental Message: 75 bytes                            *)
(***************************************************************************)

MarketSummaryIncrementalMessage ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      openPrice                      : Sample(8),
      openPriceType                  : Sample(1),
      highPrice                      : Sample(8),
      lowPrice                       : Sample(8),
      closePrice                     : Sample(8),
      openInterest                   : Sample(8),
      settlementPrice                : Sample(8),
      settlementPriceType            : Sample(1) ]

EncodeMarketSummaryIncrementalMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.openPrice
        \o message.openPriceType
        \o message.highPrice
        \o message.lowPrice
        \o message.closePrice
        \o message.openInterest
        \o message.settlementPrice
        \o message.settlementPriceType

DecodeMarketSummaryIncrementalMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET openPrice == ReadBytes(incrementalMessageInstructions.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceType == ReadBytes(openPrice.rest, 1) IN IF ~openPriceType.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceType.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(lowPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET openInterest == ReadBytes(closePrice.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(openInterest.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceType == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceType.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         openPrice                      |-> openPrice.value,
         openPriceType                  |-> openPriceType.value,
         highPrice                      |-> highPrice.value,
         lowPrice                       |-> lowPrice.value,
         closePrice                     |-> closePrice.value,
         openInterest                   |-> openInterest.value,
         settlementPrice                |-> settlementPrice.value,
         settlementPriceType            |-> settlementPriceType.value ], settlementPriceType.rest)

ZeroMarketSummaryIncrementalMessage ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      openPrice                      |-> [i \in 1 .. 8 |-> 0],
      openPriceType                  |-> [i \in 1 .. 1 |-> 0],
      highPrice                      |-> [i \in 1 .. 8 |-> 0],
      lowPrice                       |-> [i \in 1 .. 8 |-> 0],
      closePrice                     |-> [i \in 1 .. 8 |-> 0],
      openInterest                   |-> [i \in 1 .. 8 |-> 0],
      settlementPrice                |-> [i \in 1 .. 8 |-> 0],
      settlementPriceType            |-> [i \in 1 .. 1 |-> 0] ]

(* Market Summary Incremental Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSummaryIncrementalMessage ==
    { ZeroMarketSummaryIncrementalMessage }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.openPriceType = one] : one \in Sample(1) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummaryIncrementalMessage EXCEPT !.settlementPriceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Snaphot Orders Group: 43 bytes                                          *)
(***************************************************************************)

SnaphotOrdersGroup ==
    [ orderId         : Sample(8),
      side            : Sample(1),
      price           : Sample(8),
      size            : Sample(8),
      orderPriority   : Sample(8),
      orderAttributes : Sample(2),
      time            : Sample(8) ]

EncodeSnaphotOrdersGroup(message) ==
    message.orderId
        \o message.side
        \o message.price
        \o message.size
        \o message.orderPriority
        \o message.orderAttributes
        \o message.time

DecodeSnaphotOrdersGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 8) IN IF ~size.ok THEN Fail ELSE
    LET orderPriority == ReadBytes(size.rest, 8) IN IF ~orderPriority.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(orderPriority.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET time == ReadBytes(orderAttributes.rest, 8) IN IF ~time.ok THEN Fail ELSE
    Ok([ orderId         |-> orderId.value,
         side            |-> side.value,
         price           |-> price.value,
         size            |-> size.value,
         orderPriority   |-> orderPriority.value,
         orderAttributes |-> orderAttributes.value,
         time            |-> time.value ], time.rest)

ZeroSnaphotOrdersGroup ==
    [ orderId         |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      size            |-> [i \in 1 .. 8 |-> 0],
      orderPriority   |-> [i \in 1 .. 8 |-> 0],
      orderAttributes |-> [i \in 1 .. 2 |-> 0],
      time            |-> [i \in 1 .. 8 |-> 0] ]

(* Snaphot Orders Group at zero, then each field in turn at the values it is checked at *)
CheckedSnaphotOrdersGroup ==
    { ZeroSnaphotOrdersGroup }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.size = one] : one \in Sample(8) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.orderPriority = one] : one \in Sample(8) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroSnaphotOrdersGroup EXCEPT !.time = one] : one \in Sample(8) }

(* A run of Snaphot Orders Group, written one after another *)
RECURSIVE EncodeSnaphotOrdersGroupList(_)
EncodeSnaphotOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnaphotOrdersGroup(Head(messages)) \o EncodeSnaphotOrdersGroupList(Tail(messages))

(* As many Snaphot Orders Group as the field that counts them says *)
RECURSIVE ReadSnaphotOrdersGroupList(_, _)
ReadSnaphotOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnaphotOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnaphotOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snaphot Orders Group of each kind, for the lists that carry them *)
OneSnaphotOrdersGroup == { ZeroSnaphotOrdersGroup }

(***************************************************************************)
(* Snaphot Orders Groups                                                   *)
(***************************************************************************)

SnaphotOrdersGroups ==
    [ blockLength        : Sample(2),
      snaphotOrdersGroup : SampleLists(OneSnaphotOrdersGroup) ]

EncodeSnaphotOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snaphotOrdersGroup), 1)
        \o EncodeSnaphotOrdersGroupList(message.snaphotOrdersGroup)

DecodeSnaphotOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snaphotOrdersGroup == ReadSnaphotOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~snaphotOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength        |-> blockLength.value,
         snaphotOrdersGroup |-> snaphotOrdersGroup.value ], snaphotOrdersGroup.rest)

ZeroSnaphotOrdersGroups ==
    [ blockLength        |-> [i \in 1 .. 2 |-> 0],
      snaphotOrdersGroup |-> << >> ]

(* Snaphot Orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnaphotOrdersGroups ==
    { ZeroSnaphotOrdersGroups }
        \cup { [ZeroSnaphotOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnaphotOrdersGroups EXCEPT !.snaphotOrdersGroup = one] : one \in SampleLists(OneSnaphotOrdersGroup) }

(***************************************************************************)
(* Order Book Snapshot Message                                             *)
(***************************************************************************)

OrderBookSnapshotMessage ==
    [ instrumentId                : Sample(4),
      instrumentMessageNo         : Sample(8),
      transactTime                : Sample(8),
      tradingSessionDate          : Sample(2),
      instrumentTradingStatus     : Sample(1),
      snapshotMessageInstructions : Sample(2),
      snapshotInstrumentsCount    : Sample(4),
      lastIncrementalMessageSeq   : Sample(8),
      snaphotOrdersGroups         : SnaphotOrdersGroups ]

EncodeOrderBookSnapshotMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.snapshotMessageInstructions
        \o message.snapshotInstrumentsCount
        \o message.lastIncrementalMessageSeq
        \o EncodeSnaphotOrdersGroups(message.snaphotOrdersGroups)

DecodeOrderBookSnapshotMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET snapshotMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~snapshotMessageInstructions.ok THEN Fail ELSE
    LET snapshotInstrumentsCount == ReadBytes(snapshotMessageInstructions.rest, 4) IN IF ~snapshotInstrumentsCount.ok THEN Fail ELSE
    LET lastIncrementalMessageSeq == ReadBytes(snapshotInstrumentsCount.rest, 8) IN IF ~lastIncrementalMessageSeq.ok THEN Fail ELSE
    LET snaphotOrdersGroups == DecodeSnaphotOrdersGroups(lastIncrementalMessageSeq.rest) IN IF ~snaphotOrdersGroups.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         instrumentMessageNo         |-> instrumentMessageNo.value,
         transactTime                |-> transactTime.value,
         tradingSessionDate          |-> tradingSessionDate.value,
         instrumentTradingStatus     |-> instrumentTradingStatus.value,
         snapshotMessageInstructions |-> snapshotMessageInstructions.value,
         snapshotInstrumentsCount    |-> snapshotInstrumentsCount.value,
         lastIncrementalMessageSeq   |-> lastIncrementalMessageSeq.value,
         snaphotOrdersGroups         |-> snaphotOrdersGroups.value ], snaphotOrdersGroups.rest)

ZeroOrderBookSnapshotMessage ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo         |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate          |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      snapshotMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      snapshotInstrumentsCount    |-> [i \in 1 .. 4 |-> 0],
      lastIncrementalMessageSeq   |-> [i \in 1 .. 8 |-> 0],
      snaphotOrdersGroups         |-> ZeroSnaphotOrdersGroups ]

(* Order Book Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookSnapshotMessage ==
    { ZeroOrderBookSnapshotMessage }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.snapshotMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.snapshotInstrumentsCount = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.lastIncrementalMessageSeq = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookSnapshotMessage EXCEPT !.snaphotOrdersGroups = one] : one \in CheckedSnaphotOrdersGroups }

(***************************************************************************)
(* Market Summary Snapshot Message: 119 bytes                              *)
(***************************************************************************)

MarketSummarySnapshotMessage ==
    [ instrumentId                : Sample(4),
      instrumentMessageNo         : Sample(8),
      transactTime                : Sample(8),
      tradingSessionDate          : Sample(2),
      instrumentTradingStatus     : Sample(1),
      snapshotMessageInstructions : Sample(2),
      snapshotInstrumentsCount    : Sample(4),
      lastIncrementalMessageSeq   : Sample(8),
      lastTradePrice              : Sample(8),
      lastTradeSize               : Sample(8),
      lastTradeTimeTimestamp      : Sample(8),
      totalVolumeQuantityOptional : Sample(8),
      openPrice                   : Sample(8),
      openPriceType               : Sample(1),
      highPrice                   : Sample(8),
      lowPrice                    : Sample(8),
      closePrice                  : Sample(8),
      openInterest                : Sample(8),
      settlementPrice             : Sample(8),
      settlementPriceType         : Sample(1) ]

EncodeMarketSummarySnapshotMessage(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.snapshotMessageInstructions
        \o message.snapshotInstrumentsCount
        \o message.lastIncrementalMessageSeq
        \o message.lastTradePrice
        \o message.lastTradeSize
        \o message.lastTradeTimeTimestamp
        \o message.totalVolumeQuantityOptional
        \o message.openPrice
        \o message.openPriceType
        \o message.highPrice
        \o message.lowPrice
        \o message.closePrice
        \o message.openInterest
        \o message.settlementPrice
        \o message.settlementPriceType

DecodeMarketSummarySnapshotMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET snapshotMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~snapshotMessageInstructions.ok THEN Fail ELSE
    LET snapshotInstrumentsCount == ReadBytes(snapshotMessageInstructions.rest, 4) IN IF ~snapshotInstrumentsCount.ok THEN Fail ELSE
    LET lastIncrementalMessageSeq == ReadBytes(snapshotInstrumentsCount.rest, 8) IN IF ~lastIncrementalMessageSeq.ok THEN Fail ELSE
    LET lastTradePrice == ReadBytes(lastIncrementalMessageSeq.rest, 8) IN IF ~lastTradePrice.ok THEN Fail ELSE
    LET lastTradeSize == ReadBytes(lastTradePrice.rest, 8) IN IF ~lastTradeSize.ok THEN Fail ELSE
    LET lastTradeTimeTimestamp == ReadBytes(lastTradeSize.rest, 8) IN IF ~lastTradeTimeTimestamp.ok THEN Fail ELSE
    LET totalVolumeQuantityOptional == ReadBytes(lastTradeTimeTimestamp.rest, 8) IN IF ~totalVolumeQuantityOptional.ok THEN Fail ELSE
    LET openPrice == ReadBytes(totalVolumeQuantityOptional.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET openPriceType == ReadBytes(openPrice.rest, 1) IN IF ~openPriceType.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPriceType.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(lowPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    LET openInterest == ReadBytes(closePrice.rest, 8) IN IF ~openInterest.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(openInterest.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementPriceType == ReadBytes(settlementPrice.rest, 1) IN IF ~settlementPriceType.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         instrumentMessageNo         |-> instrumentMessageNo.value,
         transactTime                |-> transactTime.value,
         tradingSessionDate          |-> tradingSessionDate.value,
         instrumentTradingStatus     |-> instrumentTradingStatus.value,
         snapshotMessageInstructions |-> snapshotMessageInstructions.value,
         snapshotInstrumentsCount    |-> snapshotInstrumentsCount.value,
         lastIncrementalMessageSeq   |-> lastIncrementalMessageSeq.value,
         lastTradePrice              |-> lastTradePrice.value,
         lastTradeSize               |-> lastTradeSize.value,
         lastTradeTimeTimestamp      |-> lastTradeTimeTimestamp.value,
         totalVolumeQuantityOptional |-> totalVolumeQuantityOptional.value,
         openPrice                   |-> openPrice.value,
         openPriceType               |-> openPriceType.value,
         highPrice                   |-> highPrice.value,
         lowPrice                    |-> lowPrice.value,
         closePrice                  |-> closePrice.value,
         openInterest                |-> openInterest.value,
         settlementPrice             |-> settlementPrice.value,
         settlementPriceType         |-> settlementPriceType.value ], settlementPriceType.rest)

ZeroMarketSummarySnapshotMessage ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo         |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate          |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      snapshotMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      snapshotInstrumentsCount    |-> [i \in 1 .. 4 |-> 0],
      lastIncrementalMessageSeq   |-> [i \in 1 .. 8 |-> 0],
      lastTradePrice              |-> [i \in 1 .. 8 |-> 0],
      lastTradeSize               |-> [i \in 1 .. 8 |-> 0],
      lastTradeTimeTimestamp      |-> [i \in 1 .. 8 |-> 0],
      totalVolumeQuantityOptional |-> [i \in 1 .. 8 |-> 0],
      openPrice                   |-> [i \in 1 .. 8 |-> 0],
      openPriceType               |-> [i \in 1 .. 1 |-> 0],
      highPrice                   |-> [i \in 1 .. 8 |-> 0],
      lowPrice                    |-> [i \in 1 .. 8 |-> 0],
      closePrice                  |-> [i \in 1 .. 8 |-> 0],
      openInterest                |-> [i \in 1 .. 8 |-> 0],
      settlementPrice             |-> [i \in 1 .. 8 |-> 0],
      settlementPriceType         |-> [i \in 1 .. 1 |-> 0] ]

(* Market Summary Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketSummarySnapshotMessage ==
    { ZeroMarketSummarySnapshotMessage }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.snapshotMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.snapshotInstrumentsCount = one] : one \in Sample(4) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.lastIncrementalMessageSeq = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.lastTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.lastTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.lastTradeTimeTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.totalVolumeQuantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.openPriceType = one] : one \in Sample(1) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.closePrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.openInterest = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroMarketSummarySnapshotMessage EXCEPT !.settlementPriceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Value Snapshot Message: 80 bytes                                  *)
(***************************************************************************)

IndexValueSnapshotMessage ==
    [ instrumentId                : Sample(4),
      transactTime                : Sample(8),
      snapshotMessageInstructions : Sample(2),
      indexCount                  : Sample(4),
      indexSymbol                 : Sample(20),
      value                       : Sample(8),
      sessionDate                 : Sample(2),
      openPrice                   : Sample(8),
      highPrice                   : Sample(8),
      lowPrice                    : Sample(8),
      closePrice                  : Sample(8) ]

EncodeIndexValueSnapshotMessage(message) ==
    message.instrumentId
        \o message.transactTime
        \o message.snapshotMessageInstructions
        \o message.indexCount
        \o message.indexSymbol
        \o message.value
        \o message.sessionDate
        \o message.openPrice
        \o message.highPrice
        \o message.lowPrice
        \o message.closePrice

DecodeIndexValueSnapshotMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET snapshotMessageInstructions == ReadBytes(transactTime.rest, 2) IN IF ~snapshotMessageInstructions.ok THEN Fail ELSE
    LET indexCount == ReadBytes(snapshotMessageInstructions.rest, 4) IN IF ~indexCount.ok THEN Fail ELSE
    LET indexSymbol == ReadBytes(indexCount.rest, 20) IN IF ~indexSymbol.ok THEN Fail ELSE
    LET value == ReadBytes(indexSymbol.rest, 8) IN IF ~value.ok THEN Fail ELSE
    LET sessionDate == ReadBytes(value.rest, 2) IN IF ~sessionDate.ok THEN Fail ELSE
    LET openPrice == ReadBytes(sessionDate.rest, 8) IN IF ~openPrice.ok THEN Fail ELSE
    LET highPrice == ReadBytes(openPrice.rest, 8) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 8) IN IF ~lowPrice.ok THEN Fail ELSE
    LET closePrice == ReadBytes(lowPrice.rest, 8) IN IF ~closePrice.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         transactTime                |-> transactTime.value,
         snapshotMessageInstructions |-> snapshotMessageInstructions.value,
         indexCount                  |-> indexCount.value,
         indexSymbol                 |-> indexSymbol.value,
         value                       |-> value.value,
         sessionDate                 |-> sessionDate.value,
         openPrice                   |-> openPrice.value,
         highPrice                   |-> highPrice.value,
         lowPrice                    |-> lowPrice.value,
         closePrice                  |-> closePrice.value ], closePrice.rest)

ZeroIndexValueSnapshotMessage ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      snapshotMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      indexCount                  |-> [i \in 1 .. 4 |-> 0],
      indexSymbol                 |-> [i \in 1 .. 20 |-> 0],
      value                       |-> [i \in 1 .. 8 |-> 0],
      sessionDate                 |-> [i \in 1 .. 2 |-> 0],
      openPrice                   |-> [i \in 1 .. 8 |-> 0],
      highPrice                   |-> [i \in 1 .. 8 |-> 0],
      lowPrice                    |-> [i \in 1 .. 8 |-> 0],
      closePrice                  |-> [i \in 1 .. 8 |-> 0] ]

(* Index Value Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueSnapshotMessage ==
    { ZeroIndexValueSnapshotMessage }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.snapshotMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.indexCount = one] : one \in Sample(4) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.indexSymbol = one] : one \in Sample(20) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.value = one] : one \in Sample(8) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.sessionDate = one] : one \in Sample(2) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.openPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.highPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.lowPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndexValueSnapshotMessage EXCEPT !.closePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Instrument Definition Incremental V 2 Message: 262 bytes         *)
(***************************************************************************)

SingleInstrumentDefinitionIncrementalV2Message ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      instrumentUpdateAction         : Sample(1),
      symbol                         : Sample(25),
      product                        : Sample(8),
      description                    : Sample(120),
      instrumentType                 : Sample(1),
      maturityDate                   : Sample(2),
      firstTradingSessionDate        : Sample(2),
      lastTradingSessionDate         : Sample(2),
      expirationDate                 : Sample(2),
      cfiCode                        : Sample(6),
      currency                       : Sample(3),
      priceIncrement                 : Sample(8),
      priceMultiplier                : Sample(8),
      underlyingSymbol               : Sample(25),
      underlyingInstrumentId         : Sample(4),
      putOrCall                      : Sample(1),
      strikePrice                    : Sample(8),
      sharesPerContract              : Sample(8),
      expirationStyle                : Sample(1),
      exerciseStyle                  : Sample(1),
      delivery                       : Sample(1) ]

EncodeSingleInstrumentDefinitionIncrementalV2Message(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.instrumentUpdateAction
        \o message.symbol
        \o message.product
        \o message.description
        \o message.instrumentType
        \o message.maturityDate
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.expirationDate
        \o message.cfiCode
        \o message.currency
        \o message.priceIncrement
        \o message.priceMultiplier
        \o message.underlyingSymbol
        \o message.underlyingInstrumentId
        \o message.putOrCall
        \o message.strikePrice
        \o message.sharesPerContract
        \o message.expirationStyle
        \o message.exerciseStyle
        \o message.delivery

DecodeSingleInstrumentDefinitionIncrementalV2Message(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET instrumentUpdateAction == ReadBytes(incrementalMessageInstructions.rest, 1) IN IF ~instrumentUpdateAction.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentUpdateAction.rest, 25) IN IF ~symbol.ok THEN Fail ELSE
    LET product == ReadBytes(symbol.rest, 8) IN IF ~product.ok THEN Fail ELSE
    LET description == ReadBytes(product.rest, 120) IN IF ~description.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(description.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(instrumentType.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(maturityDate.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~expirationDate.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(expirationDate.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(currency.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(priceIncrement.rest, 8) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(priceMultiplier.rest, 25) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(underlyingSymbol.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(underlyingInstrumentId.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET sharesPerContract == ReadBytes(strikePrice.rest, 8) IN IF ~sharesPerContract.ok THEN Fail ELSE
    LET expirationStyle == ReadBytes(sharesPerContract.rest, 1) IN IF ~expirationStyle.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(expirationStyle.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET delivery == ReadBytes(exerciseStyle.rest, 1) IN IF ~delivery.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         instrumentUpdateAction         |-> instrumentUpdateAction.value,
         symbol                         |-> symbol.value,
         product                        |-> product.value,
         description                    |-> description.value,
         instrumentType                 |-> instrumentType.value,
         maturityDate                   |-> maturityDate.value,
         firstTradingSessionDate        |-> firstTradingSessionDate.value,
         lastTradingSessionDate         |-> lastTradingSessionDate.value,
         expirationDate                 |-> expirationDate.value,
         cfiCode                        |-> cfiCode.value,
         currency                       |-> currency.value,
         priceIncrement                 |-> priceIncrement.value,
         priceMultiplier                |-> priceMultiplier.value,
         underlyingSymbol               |-> underlyingSymbol.value,
         underlyingInstrumentId         |-> underlyingInstrumentId.value,
         putOrCall                      |-> putOrCall.value,
         strikePrice                    |-> strikePrice.value,
         sharesPerContract              |-> sharesPerContract.value,
         expirationStyle                |-> expirationStyle.value,
         exerciseStyle                  |-> exerciseStyle.value,
         delivery                       |-> delivery.value ], delivery.rest)

ZeroSingleInstrumentDefinitionIncrementalV2Message ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      instrumentUpdateAction         |-> [i \in 1 .. 1 |-> 0],
      symbol                         |-> [i \in 1 .. 25 |-> 0],
      product                        |-> [i \in 1 .. 8 |-> 0],
      description                    |-> [i \in 1 .. 120 |-> 0],
      instrumentType                 |-> [i \in 1 .. 1 |-> 0],
      maturityDate                   |-> [i \in 1 .. 2 |-> 0],
      firstTradingSessionDate        |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate         |-> [i \in 1 .. 2 |-> 0],
      expirationDate                 |-> [i \in 1 .. 2 |-> 0],
      cfiCode                        |-> [i \in 1 .. 6 |-> 0],
      currency                       |-> [i \in 1 .. 3 |-> 0],
      priceIncrement                 |-> [i \in 1 .. 8 |-> 0],
      priceMultiplier                |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol               |-> [i \in 1 .. 25 |-> 0],
      underlyingInstrumentId         |-> [i \in 1 .. 4 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0],
      strikePrice                    |-> [i \in 1 .. 8 |-> 0],
      sharesPerContract              |-> [i \in 1 .. 8 |-> 0],
      expirationStyle                |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle                  |-> [i \in 1 .. 1 |-> 0],
      delivery                       |-> [i \in 1 .. 1 |-> 0] ]

(* Single Instrument Definition Incremental V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleInstrumentDefinitionIncrementalV2Message ==
    { ZeroSingleInstrumentDefinitionIncrementalV2Message }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.instrumentUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.symbol = one] : one \in Sample(25) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.product = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.description = one] : one \in Sample(120) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.expirationDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.priceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.priceMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.underlyingSymbol = one] : one \in Sample(25) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.sharesPerContract = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.expirationStyle = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionIncrementalV2Message EXCEPT !.delivery = one] : one \in Sample(1) }

(***************************************************************************)
(* Legs Group: 46 bytes                                                    *)
(***************************************************************************)

LegsGroup ==
    [ legInstrumentId  : Sample(4),
      legSymbol        : Sample(25),
      legProduct       : Sample(8),
      legRatioQuantity : Sample(8),
      legSide          : Sample(1) ]

EncodeLegsGroup(message) ==
    message.legInstrumentId
        \o message.legSymbol
        \o message.legProduct
        \o message.legRatioQuantity
        \o message.legSide

DecodeLegsGroup(bytes) ==
    LET legInstrumentId == ReadBytes(bytes, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legInstrumentId.rest, 25) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legProduct == ReadBytes(legSymbol.rest, 8) IN IF ~legProduct.ok THEN Fail ELSE
    LET legRatioQuantity == ReadBytes(legProduct.rest, 8) IN IF ~legRatioQuantity.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQuantity.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legInstrumentId  |-> legInstrumentId.value,
         legSymbol        |-> legSymbol.value,
         legProduct       |-> legProduct.value,
         legRatioQuantity |-> legRatioQuantity.value,
         legSide          |-> legSide.value ], legSide.rest)

ZeroLegsGroup ==
    [ legInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      legSymbol        |-> [i \in 1 .. 25 |-> 0],
      legProduct       |-> [i \in 1 .. 8 |-> 0],
      legRatioQuantity |-> [i \in 1 .. 8 |-> 0],
      legSide          |-> [i \in 1 .. 1 |-> 0] ]

(* Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroup ==
    { ZeroLegsGroup }
        \cup { [ZeroLegsGroup EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(25) }
        \cup { [ZeroLegsGroup EXCEPT !.legProduct = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legRatioQuantity = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Legs Group, written one after another *)
RECURSIVE EncodeLegsGroupList(_)
EncodeLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegsGroup(Head(messages)) \o EncodeLegsGroupList(Tail(messages))

(* As many Legs Group as the field that counts them says *)
RECURSIVE ReadLegsGroupList(_, _)
ReadLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Legs Group of each kind, for the lists that carry them *)
OneLegsGroup == { ZeroLegsGroup }

(***************************************************************************)
(* Legs Groups                                                             *)
(***************************************************************************)

LegsGroups ==
    [ blockLength : Sample(2),
      legsGroup   : SampleLists(OneLegsGroup) ]

EncodeLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.legsGroup), 1)
        \o EncodeLegsGroupList(message.legsGroup)

DecodeLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET legsGroup == ReadLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~legsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         legsGroup   |-> legsGroup.value ], legsGroup.rest)

ZeroLegsGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      legsGroup   |-> << >> ]

(* Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroups ==
    { ZeroLegsGroups }
        \cup { [ZeroLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLegsGroups EXCEPT !.legsGroup = one] : one \in SampleLists(OneLegsGroup) }

(***************************************************************************)
(* Multileg Definition Incremental V 2 Message                             *)
(***************************************************************************)

MultilegDefinitionIncrementalV2Message ==
    [ instrumentId                   : Sample(4),
      instrumentMessageNo            : Sample(8),
      transactTime                   : Sample(8),
      tradingSessionDate             : Sample(2),
      instrumentTradingStatus        : Sample(1),
      incrementalMessageInstructions : Sample(2),
      instrumentUpdateAction         : Sample(1),
      spreadSymbol                   : Sample(120),
      description                    : Sample(120),
      instrumentType                 : Sample(1),
      maturityDate                   : Sample(2),
      firstTradingSessionDate        : Sample(2),
      lastTradingSessionDate         : Sample(2),
      expirationDate                 : Sample(2),
      cfiCode                        : Sample(6),
      currency                       : Sample(3),
      priceIncrement                 : Sample(8),
      priceMultiplier                : Sample(8),
      strategyType                   : Sample(1),
      legsGroups                     : LegsGroups ]

EncodeMultilegDefinitionIncrementalV2Message(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.incrementalMessageInstructions
        \o message.instrumentUpdateAction
        \o message.spreadSymbol
        \o message.description
        \o message.instrumentType
        \o message.maturityDate
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.expirationDate
        \o message.cfiCode
        \o message.currency
        \o message.priceIncrement
        \o message.priceMultiplier
        \o message.strategyType
        \o EncodeLegsGroups(message.legsGroups)

DecodeMultilegDefinitionIncrementalV2Message(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET incrementalMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~incrementalMessageInstructions.ok THEN Fail ELSE
    LET instrumentUpdateAction == ReadBytes(incrementalMessageInstructions.rest, 1) IN IF ~instrumentUpdateAction.ok THEN Fail ELSE
    LET spreadSymbol == ReadBytes(instrumentUpdateAction.rest, 120) IN IF ~spreadSymbol.ok THEN Fail ELSE
    LET description == ReadBytes(spreadSymbol.rest, 120) IN IF ~description.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(description.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(instrumentType.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(maturityDate.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~expirationDate.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(expirationDate.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(currency.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(priceIncrement.rest, 8) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET strategyType == ReadBytes(priceMultiplier.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET legsGroups == DecodeLegsGroups(strategyType.rest) IN IF ~legsGroups.ok THEN Fail ELSE
    Ok([ instrumentId                   |-> instrumentId.value,
         instrumentMessageNo            |-> instrumentMessageNo.value,
         transactTime                   |-> transactTime.value,
         tradingSessionDate             |-> tradingSessionDate.value,
         instrumentTradingStatus        |-> instrumentTradingStatus.value,
         incrementalMessageInstructions |-> incrementalMessageInstructions.value,
         instrumentUpdateAction         |-> instrumentUpdateAction.value,
         spreadSymbol                   |-> spreadSymbol.value,
         description                    |-> description.value,
         instrumentType                 |-> instrumentType.value,
         maturityDate                   |-> maturityDate.value,
         firstTradingSessionDate        |-> firstTradingSessionDate.value,
         lastTradingSessionDate         |-> lastTradingSessionDate.value,
         expirationDate                 |-> expirationDate.value,
         cfiCode                        |-> cfiCode.value,
         currency                       |-> currency.value,
         priceIncrement                 |-> priceIncrement.value,
         priceMultiplier                |-> priceMultiplier.value,
         strategyType                   |-> strategyType.value,
         legsGroups                     |-> legsGroups.value ], legsGroups.rest)

ZeroMultilegDefinitionIncrementalV2Message ==
    [ instrumentId                   |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo            |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate             |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      incrementalMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      instrumentUpdateAction         |-> [i \in 1 .. 1 |-> 0],
      spreadSymbol                   |-> [i \in 1 .. 120 |-> 0],
      description                    |-> [i \in 1 .. 120 |-> 0],
      instrumentType                 |-> [i \in 1 .. 1 |-> 0],
      maturityDate                   |-> [i \in 1 .. 2 |-> 0],
      firstTradingSessionDate        |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate         |-> [i \in 1 .. 2 |-> 0],
      expirationDate                 |-> [i \in 1 .. 2 |-> 0],
      cfiCode                        |-> [i \in 1 .. 6 |-> 0],
      currency                       |-> [i \in 1 .. 3 |-> 0],
      priceIncrement                 |-> [i \in 1 .. 8 |-> 0],
      priceMultiplier                |-> [i \in 1 .. 8 |-> 0],
      strategyType                   |-> [i \in 1 .. 1 |-> 0],
      legsGroups                     |-> ZeroLegsGroups ]

(* Multileg Definition Incremental V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedMultilegDefinitionIncrementalV2Message ==
    { ZeroMultilegDefinitionIncrementalV2Message }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.incrementalMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.instrumentUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.spreadSymbol = one] : one \in Sample(120) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.description = one] : one \in Sample(120) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.expirationDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.priceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.priceMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionIncrementalV2Message EXCEPT !.legsGroups = one] : one \in CheckedLegsGroups }

(***************************************************************************)
(* Single Instrument Definition Snapshot V 2 Message: 273 bytes            *)
(***************************************************************************)

SingleInstrumentDefinitionSnapshotV2Message ==
    [ instrumentId                : Sample(4),
      instrumentMessageNo         : Sample(8),
      transactTime                : Sample(8),
      tradingSessionDate          : Sample(2),
      instrumentTradingStatus     : Sample(1),
      snapshotMessageInstructions : Sample(2),
      snapshotInstrumentsCount    : Sample(4),
      lastIncrementalMessageSeq   : Sample(8),
      symbol                      : Sample(25),
      product                     : Sample(8),
      description                 : Sample(120),
      instrumentType              : Sample(1),
      maturityDate                : Sample(2),
      firstTradingSessionDate     : Sample(2),
      lastTradingSessionDate      : Sample(2),
      expirationDate              : Sample(2),
      cfiCode                     : Sample(6),
      currency                    : Sample(3),
      priceIncrement              : Sample(8),
      priceMultiplier             : Sample(8),
      underlyingSymbol            : Sample(25),
      underlyingInstrumentId      : Sample(4),
      putOrCall                   : Sample(1),
      strikePrice                 : Sample(8),
      sharesPerContract           : Sample(8),
      expirationStyle             : Sample(1),
      exerciseStyle               : Sample(1),
      delivery                    : Sample(1) ]

EncodeSingleInstrumentDefinitionSnapshotV2Message(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.snapshotMessageInstructions
        \o message.snapshotInstrumentsCount
        \o message.lastIncrementalMessageSeq
        \o message.symbol
        \o message.product
        \o message.description
        \o message.instrumentType
        \o message.maturityDate
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.expirationDate
        \o message.cfiCode
        \o message.currency
        \o message.priceIncrement
        \o message.priceMultiplier
        \o message.underlyingSymbol
        \o message.underlyingInstrumentId
        \o message.putOrCall
        \o message.strikePrice
        \o message.sharesPerContract
        \o message.expirationStyle
        \o message.exerciseStyle
        \o message.delivery

DecodeSingleInstrumentDefinitionSnapshotV2Message(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET snapshotMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~snapshotMessageInstructions.ok THEN Fail ELSE
    LET snapshotInstrumentsCount == ReadBytes(snapshotMessageInstructions.rest, 4) IN IF ~snapshotInstrumentsCount.ok THEN Fail ELSE
    LET lastIncrementalMessageSeq == ReadBytes(snapshotInstrumentsCount.rest, 8) IN IF ~lastIncrementalMessageSeq.ok THEN Fail ELSE
    LET symbol == ReadBytes(lastIncrementalMessageSeq.rest, 25) IN IF ~symbol.ok THEN Fail ELSE
    LET product == ReadBytes(symbol.rest, 8) IN IF ~product.ok THEN Fail ELSE
    LET description == ReadBytes(product.rest, 120) IN IF ~description.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(description.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(instrumentType.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(maturityDate.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~expirationDate.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(expirationDate.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(currency.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(priceIncrement.rest, 8) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(priceMultiplier.rest, 25) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(underlyingSymbol.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(underlyingInstrumentId.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(putOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET sharesPerContract == ReadBytes(strikePrice.rest, 8) IN IF ~sharesPerContract.ok THEN Fail ELSE
    LET expirationStyle == ReadBytes(sharesPerContract.rest, 1) IN IF ~expirationStyle.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(expirationStyle.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET delivery == ReadBytes(exerciseStyle.rest, 1) IN IF ~delivery.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         instrumentMessageNo         |-> instrumentMessageNo.value,
         transactTime                |-> transactTime.value,
         tradingSessionDate          |-> tradingSessionDate.value,
         instrumentTradingStatus     |-> instrumentTradingStatus.value,
         snapshotMessageInstructions |-> snapshotMessageInstructions.value,
         snapshotInstrumentsCount    |-> snapshotInstrumentsCount.value,
         lastIncrementalMessageSeq   |-> lastIncrementalMessageSeq.value,
         symbol                      |-> symbol.value,
         product                     |-> product.value,
         description                 |-> description.value,
         instrumentType              |-> instrumentType.value,
         maturityDate                |-> maturityDate.value,
         firstTradingSessionDate     |-> firstTradingSessionDate.value,
         lastTradingSessionDate      |-> lastTradingSessionDate.value,
         expirationDate              |-> expirationDate.value,
         cfiCode                     |-> cfiCode.value,
         currency                    |-> currency.value,
         priceIncrement              |-> priceIncrement.value,
         priceMultiplier             |-> priceMultiplier.value,
         underlyingSymbol            |-> underlyingSymbol.value,
         underlyingInstrumentId      |-> underlyingInstrumentId.value,
         putOrCall                   |-> putOrCall.value,
         strikePrice                 |-> strikePrice.value,
         sharesPerContract           |-> sharesPerContract.value,
         expirationStyle             |-> expirationStyle.value,
         exerciseStyle               |-> exerciseStyle.value,
         delivery                    |-> delivery.value ], delivery.rest)

ZeroSingleInstrumentDefinitionSnapshotV2Message ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo         |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate          |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      snapshotMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      snapshotInstrumentsCount    |-> [i \in 1 .. 4 |-> 0],
      lastIncrementalMessageSeq   |-> [i \in 1 .. 8 |-> 0],
      symbol                      |-> [i \in 1 .. 25 |-> 0],
      product                     |-> [i \in 1 .. 8 |-> 0],
      description                 |-> [i \in 1 .. 120 |-> 0],
      instrumentType              |-> [i \in 1 .. 1 |-> 0],
      maturityDate                |-> [i \in 1 .. 2 |-> 0],
      firstTradingSessionDate     |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      expirationDate              |-> [i \in 1 .. 2 |-> 0],
      cfiCode                     |-> [i \in 1 .. 6 |-> 0],
      currency                    |-> [i \in 1 .. 3 |-> 0],
      priceIncrement              |-> [i \in 1 .. 8 |-> 0],
      priceMultiplier             |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol            |-> [i \in 1 .. 25 |-> 0],
      underlyingInstrumentId      |-> [i \in 1 .. 4 |-> 0],
      putOrCall                   |-> [i \in 1 .. 1 |-> 0],
      strikePrice                 |-> [i \in 1 .. 8 |-> 0],
      sharesPerContract           |-> [i \in 1 .. 8 |-> 0],
      expirationStyle             |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle               |-> [i \in 1 .. 1 |-> 0],
      delivery                    |-> [i \in 1 .. 1 |-> 0] ]

(* Single Instrument Definition Snapshot V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleInstrumentDefinitionSnapshotV2Message ==
    { ZeroSingleInstrumentDefinitionSnapshotV2Message }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.snapshotMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.snapshotInstrumentsCount = one] : one \in Sample(4) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.lastIncrementalMessageSeq = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.symbol = one] : one \in Sample(25) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.product = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.description = one] : one \in Sample(120) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.expirationDate = one] : one \in Sample(2) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.priceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.priceMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.underlyingSymbol = one] : one \in Sample(25) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.sharesPerContract = one] : one \in Sample(8) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.expirationStyle = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSingleInstrumentDefinitionSnapshotV2Message EXCEPT !.delivery = one] : one \in Sample(1) }

(***************************************************************************)
(* Legs Group: 46 bytes                                                    *)
(***************************************************************************)

LegsGroup2 ==
    [ legInstrumentId  : Sample(4),
      legSymbol        : Sample(25),
      legProduct       : Sample(8),
      legRatioQuantity : Sample(8),
      legSide          : Sample(1) ]

EncodeLegsGroup2(message) ==
    message.legInstrumentId
        \o message.legSymbol
        \o message.legProduct
        \o message.legRatioQuantity
        \o message.legSide

DecodeLegsGroup2(bytes) ==
    LET legInstrumentId == ReadBytes(bytes, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legInstrumentId.rest, 25) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legProduct == ReadBytes(legSymbol.rest, 8) IN IF ~legProduct.ok THEN Fail ELSE
    LET legRatioQuantity == ReadBytes(legProduct.rest, 8) IN IF ~legRatioQuantity.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQuantity.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legInstrumentId  |-> legInstrumentId.value,
         legSymbol        |-> legSymbol.value,
         legProduct       |-> legProduct.value,
         legRatioQuantity |-> legRatioQuantity.value,
         legSide          |-> legSide.value ], legSide.rest)

ZeroLegsGroup2 ==
    [ legInstrumentId  |-> [i \in 1 .. 4 |-> 0],
      legSymbol        |-> [i \in 1 .. 25 |-> 0],
      legProduct       |-> [i \in 1 .. 8 |-> 0],
      legRatioQuantity |-> [i \in 1 .. 8 |-> 0],
      legSide          |-> [i \in 1 .. 1 |-> 0] ]

(* Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroup2 ==
    { ZeroLegsGroup2 }
        \cup { [ZeroLegsGroup2 EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLegsGroup2 EXCEPT !.legSymbol = one] : one \in Sample(25) }
        \cup { [ZeroLegsGroup2 EXCEPT !.legProduct = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup2 EXCEPT !.legRatioQuantity = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup2 EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Legs Group, written one after another *)
RECURSIVE EncodeLegsGroup2List(_)
EncodeLegsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegsGroup2(Head(messages)) \o EncodeLegsGroup2List(Tail(messages))

(* As many Legs Group as the field that counts them says *)
RECURSIVE ReadLegsGroup2List(_, _)
ReadLegsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Legs Group of each kind, for the lists that carry them *)
OneLegsGroup2 == { ZeroLegsGroup2 }

(***************************************************************************)
(* Legs Groups                                                             *)
(***************************************************************************)

LegsGroups2 ==
    [ blockLength : Sample(2),
      legsGroup   : SampleLists(OneLegsGroup2) ]

EncodeLegsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.legsGroup), 1)
        \o EncodeLegsGroup2List(message.legsGroup)

DecodeLegsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET legsGroup == ReadLegsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~legsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         legsGroup   |-> legsGroup.value ], legsGroup.rest)

ZeroLegsGroups2 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      legsGroup   |-> << >> ]

(* Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroups2 ==
    { ZeroLegsGroups2 }
        \cup { [ZeroLegsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLegsGroups2 EXCEPT !.legsGroup = one] : one \in SampleLists(OneLegsGroup2) }

(***************************************************************************)
(* Multileg Definition Snapshot V 2 Message                                *)
(***************************************************************************)

MultilegDefinitionSnapshotV2Message ==
    [ instrumentId                : Sample(4),
      instrumentMessageNo         : Sample(8),
      transactTime                : Sample(8),
      tradingSessionDate          : Sample(2),
      instrumentTradingStatus     : Sample(1),
      snapshotMessageInstructions : Sample(2),
      snapshotInstrumentsCount    : Sample(4),
      lastIncrementalMessageSeq   : Sample(8),
      spreadSymbol                : Sample(120),
      description                 : Sample(120),
      instrumentType              : Sample(1),
      maturityDate                : Sample(2),
      firstTradingSessionDate     : Sample(2),
      lastTradingSessionDate      : Sample(2),
      expirationDate              : Sample(2),
      cfiCode                     : Sample(6),
      currency                    : Sample(3),
      priceIncrement              : Sample(8),
      priceMultiplier             : Sample(8),
      strategyType                : Sample(1),
      legsGroups                  : LegsGroups2 ]

EncodeMultilegDefinitionSnapshotV2Message(message) ==
    message.instrumentId
        \o message.instrumentMessageNo
        \o message.transactTime
        \o message.tradingSessionDate
        \o message.instrumentTradingStatus
        \o message.snapshotMessageInstructions
        \o message.snapshotInstrumentsCount
        \o message.lastIncrementalMessageSeq
        \o message.spreadSymbol
        \o message.description
        \o message.instrumentType
        \o message.maturityDate
        \o message.firstTradingSessionDate
        \o message.lastTradingSessionDate
        \o message.expirationDate
        \o message.cfiCode
        \o message.currency
        \o message.priceIncrement
        \o message.priceMultiplier
        \o message.strategyType
        \o EncodeLegsGroups2(message.legsGroups)

DecodeMultilegDefinitionSnapshotV2Message(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET instrumentMessageNo == ReadBytes(instrumentId.rest, 8) IN IF ~instrumentMessageNo.ok THEN Fail ELSE
    LET transactTime == ReadBytes(instrumentMessageNo.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradingSessionDate == ReadBytes(transactTime.rest, 2) IN IF ~tradingSessionDate.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(tradingSessionDate.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET snapshotMessageInstructions == ReadBytes(instrumentTradingStatus.rest, 2) IN IF ~snapshotMessageInstructions.ok THEN Fail ELSE
    LET snapshotInstrumentsCount == ReadBytes(snapshotMessageInstructions.rest, 4) IN IF ~snapshotInstrumentsCount.ok THEN Fail ELSE
    LET lastIncrementalMessageSeq == ReadBytes(snapshotInstrumentsCount.rest, 8) IN IF ~lastIncrementalMessageSeq.ok THEN Fail ELSE
    LET spreadSymbol == ReadBytes(lastIncrementalMessageSeq.rest, 120) IN IF ~spreadSymbol.ok THEN Fail ELSE
    LET description == ReadBytes(spreadSymbol.rest, 120) IN IF ~description.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(description.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(instrumentType.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET firstTradingSessionDate == ReadBytes(maturityDate.rest, 2) IN IF ~firstTradingSessionDate.ok THEN Fail ELSE
    LET lastTradingSessionDate == ReadBytes(firstTradingSessionDate.rest, 2) IN IF ~lastTradingSessionDate.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(lastTradingSessionDate.rest, 2) IN IF ~expirationDate.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(expirationDate.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET priceIncrement == ReadBytes(currency.rest, 8) IN IF ~priceIncrement.ok THEN Fail ELSE
    LET priceMultiplier == ReadBytes(priceIncrement.rest, 8) IN IF ~priceMultiplier.ok THEN Fail ELSE
    LET strategyType == ReadBytes(priceMultiplier.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET legsGroups == DecodeLegsGroups2(strategyType.rest) IN IF ~legsGroups.ok THEN Fail ELSE
    Ok([ instrumentId                |-> instrumentId.value,
         instrumentMessageNo         |-> instrumentMessageNo.value,
         transactTime                |-> transactTime.value,
         tradingSessionDate          |-> tradingSessionDate.value,
         instrumentTradingStatus     |-> instrumentTradingStatus.value,
         snapshotMessageInstructions |-> snapshotMessageInstructions.value,
         snapshotInstrumentsCount    |-> snapshotInstrumentsCount.value,
         lastIncrementalMessageSeq   |-> lastIncrementalMessageSeq.value,
         spreadSymbol                |-> spreadSymbol.value,
         description                 |-> description.value,
         instrumentType              |-> instrumentType.value,
         maturityDate                |-> maturityDate.value,
         firstTradingSessionDate     |-> firstTradingSessionDate.value,
         lastTradingSessionDate      |-> lastTradingSessionDate.value,
         expirationDate              |-> expirationDate.value,
         cfiCode                     |-> cfiCode.value,
         currency                    |-> currency.value,
         priceIncrement              |-> priceIncrement.value,
         priceMultiplier             |-> priceMultiplier.value,
         strategyType                |-> strategyType.value,
         legsGroups                  |-> legsGroups.value ], legsGroups.rest)

ZeroMultilegDefinitionSnapshotV2Message ==
    [ instrumentId                |-> [i \in 1 .. 4 |-> 0],
      instrumentMessageNo         |-> [i \in 1 .. 8 |-> 0],
      transactTime                |-> [i \in 1 .. 8 |-> 0],
      tradingSessionDate          |-> [i \in 1 .. 2 |-> 0],
      instrumentTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      snapshotMessageInstructions |-> [i \in 1 .. 2 |-> 0],
      snapshotInstrumentsCount    |-> [i \in 1 .. 4 |-> 0],
      lastIncrementalMessageSeq   |-> [i \in 1 .. 8 |-> 0],
      spreadSymbol                |-> [i \in 1 .. 120 |-> 0],
      description                 |-> [i \in 1 .. 120 |-> 0],
      instrumentType              |-> [i \in 1 .. 1 |-> 0],
      maturityDate                |-> [i \in 1 .. 2 |-> 0],
      firstTradingSessionDate     |-> [i \in 1 .. 2 |-> 0],
      lastTradingSessionDate      |-> [i \in 1 .. 2 |-> 0],
      expirationDate              |-> [i \in 1 .. 2 |-> 0],
      cfiCode                     |-> [i \in 1 .. 6 |-> 0],
      currency                    |-> [i \in 1 .. 3 |-> 0],
      priceIncrement              |-> [i \in 1 .. 8 |-> 0],
      priceMultiplier             |-> [i \in 1 .. 8 |-> 0],
      strategyType                |-> [i \in 1 .. 1 |-> 0],
      legsGroups                  |-> ZeroLegsGroups2 ]

(* Multileg Definition Snapshot V 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedMultilegDefinitionSnapshotV2Message ==
    { ZeroMultilegDefinitionSnapshotV2Message }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.instrumentMessageNo = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.tradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.snapshotMessageInstructions = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.snapshotInstrumentsCount = one] : one \in Sample(4) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.lastIncrementalMessageSeq = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.spreadSymbol = one] : one \in Sample(120) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.description = one] : one \in Sample(120) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.firstTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.lastTradingSessionDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.expirationDate = one] : one \in Sample(2) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.priceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.priceMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroMultilegDefinitionSnapshotV2Message EXCEPT !.legsGroups = one] : one \in CheckedLegsGroups2 }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentTradingStatusIncrementalMessageCode == 3  \* 0x03
TradesIncrementalMessageCode == 4  \* 0x04
TradeCorrectMessageCode == 5  \* 0x05
TradeBustMessageCode == 6  \* 0x06
OrderBookIncrementalMessageCode == 7  \* 0x07
MarketSummaryIncrementalMessageCode == 8  \* 0x08
OrderBookSnapshotMessageCode == 11  \* 0x0b
MarketSummarySnapshotMessageCode == 12  \* 0x0c
IndexValueSnapshotMessageCode == 13  \* 0x0d
SingleInstrumentDefinitionIncrementalV2MessageCode == 14  \* 0x0e
MultilegDefinitionIncrementalV2MessageCode == 15  \* 0x0f
SingleInstrumentDefinitionSnapshotV2MessageCode == 16  \* 0x10
MultilegDefinitionSnapshotV2MessageCode == 17  \* 0x11

Payload ==
    [ tag : {InstrumentTradingStatusIncrementalMessageCode}, body : InstrumentTradingStatusIncrementalMessage ]
        \cup [ tag : {TradesIncrementalMessageCode}, body : TradesIncrementalMessage ]
        \cup [ tag : {TradeCorrectMessageCode}, body : TradeCorrectMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {OrderBookIncrementalMessageCode}, body : OrderBookIncrementalMessage ]
        \cup [ tag : {MarketSummaryIncrementalMessageCode}, body : MarketSummaryIncrementalMessage ]
        \cup [ tag : {OrderBookSnapshotMessageCode}, body : OrderBookSnapshotMessage ]
        \cup [ tag : {MarketSummarySnapshotMessageCode}, body : MarketSummarySnapshotMessage ]
        \cup [ tag : {IndexValueSnapshotMessageCode}, body : IndexValueSnapshotMessage ]
        \cup [ tag : {SingleInstrumentDefinitionIncrementalV2MessageCode}, body : SingleInstrumentDefinitionIncrementalV2Message ]
        \cup [ tag : {MultilegDefinitionIncrementalV2MessageCode}, body : MultilegDefinitionIncrementalV2Message ]
        \cup [ tag : {SingleInstrumentDefinitionSnapshotV2MessageCode}, body : SingleInstrumentDefinitionSnapshotV2Message ]
        \cup [ tag : {MultilegDefinitionSnapshotV2MessageCode}, body : MultilegDefinitionSnapshotV2Message ]

EncodePayload(message) ==
    CASE message.tag = InstrumentTradingStatusIncrementalMessageCode -> EncodeInstrumentTradingStatusIncrementalMessage(message.body)
      [] message.tag = TradesIncrementalMessageCode -> EncodeTradesIncrementalMessage(message.body)
      [] message.tag = TradeCorrectMessageCode -> EncodeTradeCorrectMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = OrderBookIncrementalMessageCode -> EncodeOrderBookIncrementalMessage(message.body)
      [] message.tag = MarketSummaryIncrementalMessageCode -> EncodeMarketSummaryIncrementalMessage(message.body)
      [] message.tag = OrderBookSnapshotMessageCode -> EncodeOrderBookSnapshotMessage(message.body)
      [] message.tag = MarketSummarySnapshotMessageCode -> EncodeMarketSummarySnapshotMessage(message.body)
      [] message.tag = IndexValueSnapshotMessageCode -> EncodeIndexValueSnapshotMessage(message.body)
      [] message.tag = SingleInstrumentDefinitionIncrementalV2MessageCode -> EncodeSingleInstrumentDefinitionIncrementalV2Message(message.body)
      [] message.tag = MultilegDefinitionIncrementalV2MessageCode -> EncodeMultilegDefinitionIncrementalV2Message(message.body)
      [] message.tag = SingleInstrumentDefinitionSnapshotV2MessageCode -> EncodeSingleInstrumentDefinitionSnapshotV2Message(message.body)
      [] message.tag = MultilegDefinitionSnapshotV2MessageCode -> EncodeMultilegDefinitionSnapshotV2Message(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentTradingStatusIncrementalMessageCode -> DecodeInstrumentTradingStatusIncrementalMessage(bytes)
              [] tag = TradesIncrementalMessageCode -> DecodeTradesIncrementalMessage(bytes)
              [] tag = TradeCorrectMessageCode -> DecodeTradeCorrectMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = OrderBookIncrementalMessageCode -> DecodeOrderBookIncrementalMessage(bytes)
              [] tag = MarketSummaryIncrementalMessageCode -> DecodeMarketSummaryIncrementalMessage(bytes)
              [] tag = OrderBookSnapshotMessageCode -> DecodeOrderBookSnapshotMessage(bytes)
              [] tag = MarketSummarySnapshotMessageCode -> DecodeMarketSummarySnapshotMessage(bytes)
              [] tag = IndexValueSnapshotMessageCode -> DecodeIndexValueSnapshotMessage(bytes)
              [] tag = SingleInstrumentDefinitionIncrementalV2MessageCode -> DecodeSingleInstrumentDefinitionIncrementalV2Message(bytes)
              [] tag = MultilegDefinitionIncrementalV2MessageCode -> DecodeMultilegDefinitionIncrementalV2Message(bytes)
              [] tag = SingleInstrumentDefinitionSnapshotV2MessageCode -> DecodeSingleInstrumentDefinitionSnapshotV2Message(bytes)
              [] tag = MultilegDefinitionSnapshotV2MessageCode -> DecodeMultilegDefinitionSnapshotV2Message(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentTradingStatusIncrementalMessageCode, body |-> ZeroInstrumentTradingStatusIncrementalMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentTradingStatusIncrementalMessageCode, body |-> one] : one \in CheckedInstrumentTradingStatusIncrementalMessage }
        \cup { [tag |-> TradesIncrementalMessageCode, body |-> one] : one \in CheckedTradesIncrementalMessage }
        \cup { [tag |-> TradeCorrectMessageCode, body |-> one] : one \in CheckedTradeCorrectMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> OrderBookIncrementalMessageCode, body |-> one] : one \in CheckedOrderBookIncrementalMessage }
        \cup { [tag |-> MarketSummaryIncrementalMessageCode, body |-> one] : one \in CheckedMarketSummaryIncrementalMessage }
        \cup { [tag |-> OrderBookSnapshotMessageCode, body |-> one] : one \in CheckedOrderBookSnapshotMessage }
        \cup { [tag |-> MarketSummarySnapshotMessageCode, body |-> one] : one \in CheckedMarketSummarySnapshotMessage }
        \cup { [tag |-> IndexValueSnapshotMessageCode, body |-> one] : one \in CheckedIndexValueSnapshotMessage }
        \cup { [tag |-> SingleInstrumentDefinitionIncrementalV2MessageCode, body |-> one] : one \in CheckedSingleInstrumentDefinitionIncrementalV2Message }
        \cup { [tag |-> MultilegDefinitionIncrementalV2MessageCode, body |-> one] : one \in CheckedMultilegDefinitionIncrementalV2Message }
        \cup { [tag |-> SingleInstrumentDefinitionSnapshotV2MessageCode, body |-> one] : one \in CheckedSingleInstrumentDefinitionSnapshotV2Message }
        \cup { [tag |-> MultilegDefinitionSnapshotV2MessageCode, body |-> one] : one \in CheckedMultilegDefinitionSnapshotV2Message }

(***************************************************************************)
(* Sbe Frame, framed by Frame Length                                       *)
(***************************************************************************)

SbeFrame ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeFrameBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Frame Length counts the bytes it frames, so it is written from them *)
EncodeSbeFrame(message) ==
    LET body == EncodeSbeFrameBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeSbeFrameBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeSbeFrame(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeFrameBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeFrame ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Frame at zero, then each field in turn at the values it is checked at *)
CheckedSbeFrame ==
    { ZeroSbeFrame }
        \cup { [ZeroSbeFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeFrame EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Sbe Frame, written one after another *)
RECURSIVE EncodeSbeFrameList(_)
EncodeSbeFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeFrame(Head(messages)) \o EncodeSbeFrameList(Tail(messages))

(* As many Sbe Frame as the field that counts them says *)
RECURSIVE ReadSbeFrameList(_, _)
ReadSbeFrameList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSbeFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeFrameList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Frame of each kind, for the lists that carry them *)
OneSbeFrame ==
    { [ZeroSbeFrame EXCEPT !.payload = [tag |-> InstrumentTradingStatusIncrementalMessageCode, body |-> ZeroInstrumentTradingStatusIncrementalMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> TradesIncrementalMessageCode, body |-> ZeroTradesIncrementalMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> TradeCorrectMessageCode, body |-> ZeroTradeCorrectMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> OrderBookIncrementalMessageCode, body |-> ZeroOrderBookIncrementalMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> MarketSummaryIncrementalMessageCode, body |-> ZeroMarketSummaryIncrementalMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> OrderBookSnapshotMessageCode, body |-> ZeroOrderBookSnapshotMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> MarketSummarySnapshotMessageCode, body |-> ZeroMarketSummarySnapshotMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> IndexValueSnapshotMessageCode, body |-> ZeroIndexValueSnapshotMessage]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> SingleInstrumentDefinitionIncrementalV2MessageCode, body |-> ZeroSingleInstrumentDefinitionIncrementalV2Message]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> MultilegDefinitionIncrementalV2MessageCode, body |-> ZeroMultilegDefinitionIncrementalV2Message]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> SingleInstrumentDefinitionSnapshotV2MessageCode, body |-> ZeroSingleInstrumentDefinitionSnapshotV2Message]],
      [ZeroSbeFrame EXCEPT !.payload = [tag |-> MultilegDefinitionSnapshotV2MessageCode, body |-> ZeroMultilegDefinitionSnapshotV2Message]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ channelId       : Sample(1),
      incarnation     : Sample(2),
      source          : Sample(1),
      packetFlags     : Sample(1),
      messageSequence : Sample(4),
      sbeFrame        : SampleLists(OneSbeFrame) ]

EncodePacket(message) ==
    message.channelId
        \o message.incarnation
        \o message.source
        \o message.packetFlags
        \o message.messageSequence
        \o EncodeUIntBE(Len(message.sbeFrame), 1)
        \o EncodeSbeFrameList(message.sbeFrame)

DecodePacket(bytes) ==
    LET channelId == ReadBytes(bytes, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET incarnation == ReadBytes(channelId.rest, 2) IN IF ~incarnation.ok THEN Fail ELSE
    LET source == ReadBytes(incarnation.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET packetFlags == ReadBytes(source.rest, 1) IN IF ~packetFlags.ok THEN Fail ELSE
    LET messageSequence == ReadBytes(packetFlags.rest, 4) IN IF ~messageSequence.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(messageSequence.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET sbeFrame == ReadSbeFrameList(messageCount.rest, messageCount.value) IN IF ~sbeFrame.ok THEN Fail ELSE
    Ok([ channelId       |-> channelId.value,
         incarnation     |-> incarnation.value,
         source          |-> source.value,
         packetFlags     |-> packetFlags.value,
         messageSequence |-> messageSequence.value,
         sbeFrame        |-> sbeFrame.value ], sbeFrame.rest)

ZeroPacket ==
    [ channelId       |-> [i \in 1 .. 1 |-> 0],
      incarnation     |-> [i \in 1 .. 2 |-> 0],
      source          |-> [i \in 1 .. 1 |-> 0],
      packetFlags     |-> [i \in 1 .. 1 |-> 0],
      messageSequence |-> [i \in 1 .. 4 |-> 0],
      sbeFrame        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.incarnation = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.packetFlags = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageSequence = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sbeFrame = one] : one \in SampleLists(OneSbeFrame) }

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

(* Every Instrument Trading Status Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentTradingStatusIncrementalMessage ==
    \A message \in CheckedInstrumentTradingStatusIncrementalMessage :
        LET read == DecodeInstrumentTradingStatusIncrementalMessage(EncodeInstrumentTradingStatusIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Trade Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalTradeGroup ==
    \A message \in CheckedIncrementalTradeGroup :
        LET read == DecodeIncrementalTradeGroup(EncodeIncrementalTradeGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Trade Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalTradeGroups ==
    \A message \in CheckedIncrementalTradeGroups :
        LET read == DecodeIncrementalTradeGroups(EncodeIncrementalTradeGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trades Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradesIncrementalMessage ==
    \A message \in CheckedTradesIncrementalMessage :
        LET read == DecodeTradesIncrementalMessage(EncodeTradesIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correct Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectGroup ==
    \A message \in CheckedTradeCorrectGroup :
        LET read == DecodeTradeCorrectGroup(EncodeTradeCorrectGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correct Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectGroups ==
    \A message \in CheckedTradeCorrectGroups :
        LET read == DecodeTradeCorrectGroups(EncodeTradeCorrectGroups(message))
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

(* Every Trade Bust Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustGroup ==
    \A message \in CheckedTradeBustGroup :
        LET read == DecodeTradeBustGroup(EncodeTradeBustGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustGroups ==
    \A message \in CheckedTradeBustGroups :
        LET read == DecodeTradeBustGroups(EncodeTradeBustGroups(message))
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

(* Every Incremetal Orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncremetalOrdersGroup ==
    \A message \in CheckedIncremetalOrdersGroup :
        LET read == DecodeIncremetalOrdersGroup(EncodeIncremetalOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremetal Orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncremetalOrdersGroups ==
    \A message \in CheckedIncremetalOrdersGroups :
        LET read == DecodeIncremetalOrdersGroups(EncodeIncremetalOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookIncrementalMessage ==
    \A message \in CheckedOrderBookIncrementalMessage :
        LET read == DecodeOrderBookIncrementalMessage(EncodeOrderBookIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Summary Incremental Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSummaryIncrementalMessage ==
    \A message \in CheckedMarketSummaryIncrementalMessage :
        LET read == DecodeMarketSummaryIncrementalMessage(EncodeMarketSummaryIncrementalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snaphot Orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnaphotOrdersGroup ==
    \A message \in CheckedSnaphotOrdersGroup :
        LET read == DecodeSnaphotOrdersGroup(EncodeSnaphotOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snaphot Orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnaphotOrdersGroups ==
    \A message \in CheckedSnaphotOrdersGroups :
        LET read == DecodeSnaphotOrdersGroups(EncodeSnaphotOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookSnapshotMessage ==
    \A message \in CheckedOrderBookSnapshotMessage :
        LET read == DecodeOrderBookSnapshotMessage(EncodeOrderBookSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Summary Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketSummarySnapshotMessage ==
    \A message \in CheckedMarketSummarySnapshotMessage :
        LET read == DecodeMarketSummarySnapshotMessage(EncodeMarketSummarySnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueSnapshotMessage ==
    \A message \in CheckedIndexValueSnapshotMessage :
        LET read == DecodeIndexValueSnapshotMessage(EncodeIndexValueSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Instrument Definition Incremental V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleInstrumentDefinitionIncrementalV2Message ==
    \A message \in CheckedSingleInstrumentDefinitionIncrementalV2Message :
        LET read == DecodeSingleInstrumentDefinitionIncrementalV2Message(EncodeSingleInstrumentDefinitionIncrementalV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroup ==
    \A message \in CheckedLegsGroup :
        LET read == DecodeLegsGroup(EncodeLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroups ==
    \A message \in CheckedLegsGroups :
        LET read == DecodeLegsGroups(EncodeLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multileg Definition Incremental V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMultilegDefinitionIncrementalV2Message ==
    \A message \in CheckedMultilegDefinitionIncrementalV2Message :
        LET read == DecodeMultilegDefinitionIncrementalV2Message(EncodeMultilegDefinitionIncrementalV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Instrument Definition Snapshot V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleInstrumentDefinitionSnapshotV2Message ==
    \A message \in CheckedSingleInstrumentDefinitionSnapshotV2Message :
        LET read == DecodeSingleInstrumentDefinitionSnapshotV2Message(EncodeSingleInstrumentDefinitionSnapshotV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroup2 ==
    \A message \in CheckedLegsGroup2 :
        LET read == DecodeLegsGroup2(EncodeLegsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLegsGroups2 ==
    \A message \in CheckedLegsGroups2 :
        LET read == DecodeLegsGroups2(EncodeLegsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multileg Definition Snapshot V 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMultilegDefinitionSnapshotV2Message ==
    \A message \in CheckedMultilegDefinitionSnapshotV2Message :
        LET read == DecodeMultilegDefinitionSnapshotV2Message(EncodeMultilegDefinitionSnapshotV2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeFrame ==
    \A message \in CheckedSbeFrame :
        LET read == DecodeSbeFrame(EncodeSbeFrame(message))
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
FramesSbeFrame ==
    \A message \in CheckedSbeFrame :
        LET bytes == EncodeSbeFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
