----------------- MODULE Spectra_OptInfoIncremental_v9_9_0 -----------------
(***************************************************************************)
(* Moscow Exchange SIMBA Spectra Options Instrument Incremental v9.9.0     *)
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
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 8 bytes off the reader the run *)
(* ends where the data does.                                               *)
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
(* Market Data Packet Header: 16 bytes                                     *)
(***************************************************************************)

MarketDataPacketHeader ==
    [ msgSeqNum   : Sample(4),
      msgSize     : Sample(2),
      msgFlags    : Sample(2),
      sendingTime : Sample(8) ]

EncodeMarketDataPacketHeader(message) ==
    message.msgSeqNum
        \o message.msgSize
        \o message.msgFlags
        \o message.sendingTime

DecodeMarketDataPacketHeader(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET msgSize == ReadBytes(msgSeqNum.rest, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgFlags == ReadBytes(msgSize.rest, 2) IN IF ~msgFlags.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(msgFlags.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         msgSize     |-> msgSize.value,
         msgFlags    |-> msgFlags.value,
         sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroMarketDataPacketHeader ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      msgSize     |-> [i \in 1 .. 2 |-> 0],
      msgFlags    |-> [i \in 1 .. 2 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Market Data Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataPacketHeader ==
    { ZeroMarketDataPacketHeader }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgSize = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.msgFlags = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Incremental Packet Header: 12 bytes                                     *)
(***************************************************************************)

IncrementalPacketHeader ==
    [ transactTime             : Sample(8),
      exchangeTradingSessionId : Sample(4) ]

EncodeIncrementalPacketHeader(message) ==
    message.transactTime
        \o message.exchangeTradingSessionId

DecodeIncrementalPacketHeader(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET exchangeTradingSessionId == ReadBytes(transactTime.rest, 4) IN IF ~exchangeTradingSessionId.ok THEN Fail ELSE
    Ok([ transactTime             |-> transactTime.value,
         exchangeTradingSessionId |-> exchangeTradingSessionId.value ], exchangeTradingSessionId.rest)

ZeroIncrementalPacketHeader ==
    [ transactTime             |-> [i \in 1 .. 8 |-> 0],
      exchangeTradingSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Incremental Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalPacketHeader ==
    { ZeroIncrementalPacketHeader }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalPacketHeader EXCEPT !.exchangeTradingSessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Status Message: 86 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityId            : Sample(4),
      symbol                : Sample(25),
      securityTradingStatus : Sample(1),
      highLimitPx           : Sample(8),
      lowLimitPx            : Sample(8),
      initialMarginOnBuy    : Sample(8),
      initialMarginOnSell   : Sample(8),
      initialMarginSyntetic : Sample(8),
      highLimitPxWeekend    : Sample(8),
      lowLimitPxWeekend     : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.securityId
        \o message.symbol
        \o message.securityTradingStatus
        \o message.highLimitPx
        \o message.lowLimitPx
        \o message.initialMarginOnBuy
        \o message.initialMarginOnSell
        \o message.initialMarginSyntetic
        \o message.highLimitPxWeekend
        \o message.lowLimitPxWeekend

DecodeSecurityStatusMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityId.rest, 25) IN IF ~symbol.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(symbol.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET highLimitPx == ReadBytes(securityTradingStatus.rest, 8) IN IF ~highLimitPx.ok THEN Fail ELSE
    LET lowLimitPx == ReadBytes(highLimitPx.rest, 8) IN IF ~lowLimitPx.ok THEN Fail ELSE
    LET initialMarginOnBuy == ReadBytes(lowLimitPx.rest, 8) IN IF ~initialMarginOnBuy.ok THEN Fail ELSE
    LET initialMarginOnSell == ReadBytes(initialMarginOnBuy.rest, 8) IN IF ~initialMarginOnSell.ok THEN Fail ELSE
    LET initialMarginSyntetic == ReadBytes(initialMarginOnSell.rest, 8) IN IF ~initialMarginSyntetic.ok THEN Fail ELSE
    LET highLimitPxWeekend == ReadBytes(initialMarginSyntetic.rest, 8) IN IF ~highLimitPxWeekend.ok THEN Fail ELSE
    LET lowLimitPxWeekend == ReadBytes(highLimitPxWeekend.rest, 8) IN IF ~lowLimitPxWeekend.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         symbol                |-> symbol.value,
         securityTradingStatus |-> securityTradingStatus.value,
         highLimitPx           |-> highLimitPx.value,
         lowLimitPx            |-> lowLimitPx.value,
         initialMarginOnBuy    |-> initialMarginOnBuy.value,
         initialMarginOnSell   |-> initialMarginOnSell.value,
         initialMarginSyntetic |-> initialMarginSyntetic.value,
         highLimitPxWeekend    |-> highLimitPxWeekend.value,
         lowLimitPxWeekend     |-> lowLimitPxWeekend.value ], lowLimitPxWeekend.rest)

ZeroSecurityStatusMessage ==
    [ securityId            |-> [i \in 1 .. 4 |-> 0],
      symbol                |-> [i \in 1 .. 25 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      highLimitPx           |-> [i \in 1 .. 8 |-> 0],
      lowLimitPx            |-> [i \in 1 .. 8 |-> 0],
      initialMarginOnBuy    |-> [i \in 1 .. 8 |-> 0],
      initialMarginOnSell   |-> [i \in 1 .. 8 |-> 0],
      initialMarginSyntetic |-> [i \in 1 .. 8 |-> 0],
      highLimitPxWeekend    |-> [i \in 1 .. 8 |-> 0],
      lowLimitPxWeekend     |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.symbol = one] : one \in Sample(25) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.highLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.lowLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.initialMarginOnBuy = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.initialMarginOnSell = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.initialMarginSyntetic = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.highLimitPxWeekend = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.lowLimitPxWeekend = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Definition Update Report Message: 28 bytes                     *)
(***************************************************************************)

SecurityDefinitionUpdateReportMessage ==
    [ securityId      : Sample(4),
      volatility      : Sample(8),
      theorPrice      : Sample(8),
      theorPriceLimit : Sample(8) ]

EncodeSecurityDefinitionUpdateReportMessage(message) ==
    message.securityId
        \o message.volatility
        \o message.theorPrice
        \o message.theorPriceLimit

DecodeSecurityDefinitionUpdateReportMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET volatility == ReadBytes(securityId.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET theorPrice == ReadBytes(volatility.rest, 8) IN IF ~theorPrice.ok THEN Fail ELSE
    LET theorPriceLimit == ReadBytes(theorPrice.rest, 8) IN IF ~theorPriceLimit.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         volatility      |-> volatility.value,
         theorPrice      |-> theorPrice.value,
         theorPriceLimit |-> theorPriceLimit.value ], theorPriceLimit.rest)

ZeroSecurityDefinitionUpdateReportMessage ==
    [ securityId      |-> [i \in 1 .. 4 |-> 0],
      volatility      |-> [i \in 1 .. 8 |-> 0],
      theorPrice      |-> [i \in 1 .. 8 |-> 0],
      theorPriceLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Update Report Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionUpdateReportMessage ==
    { ZeroSecurityDefinitionUpdateReportMessage }
        \cup { [ZeroSecurityDefinitionUpdateReportMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionUpdateReportMessage EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionUpdateReportMessage EXCEPT !.theorPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionUpdateReportMessage EXCEPT !.theorPriceLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Session Status Message: 48 bytes                                *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ tradSesOpenTime                           : Sample(8),
      tradSesCloseTime                          : Sample(8),
      tradingSessionId                          : Sample(1),
      exchangeTradingSessionIdInt32NullOptional : Sample(4),
      tradSesStatus                             : Sample(1),
      marketSegmentId                           : Sample(1),
      tradSesEvent                              : Sample(1),
      tradePeriodId                             : Sample(8),
      settlSessBegin                            : Sample(8),
      clrSessBegin                              : Sample(8) ]

EncodeTradingSessionStatusMessage(message) ==
    message.tradSesOpenTime
        \o message.tradSesCloseTime
        \o message.tradingSessionId
        \o message.exchangeTradingSessionIdInt32NullOptional
        \o message.tradSesStatus
        \o message.marketSegmentId
        \o message.tradSesEvent
        \o message.tradePeriodId
        \o message.settlSessBegin
        \o message.clrSessBegin

DecodeTradingSessionStatusMessage(bytes) ==
    LET tradSesOpenTime == ReadBytes(bytes, 8) IN IF ~tradSesOpenTime.ok THEN Fail ELSE
    LET tradSesCloseTime == ReadBytes(tradSesOpenTime.rest, 8) IN IF ~tradSesCloseTime.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(tradSesCloseTime.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET exchangeTradingSessionIdInt32NullOptional == ReadBytes(tradingSessionId.rest, 4) IN IF ~exchangeTradingSessionIdInt32NullOptional.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(exchangeTradingSessionIdInt32NullOptional.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tradSesStatus.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET tradePeriodId == ReadBytes(tradSesEvent.rest, 8) IN IF ~tradePeriodId.ok THEN Fail ELSE
    LET settlSessBegin == ReadBytes(tradePeriodId.rest, 8) IN IF ~settlSessBegin.ok THEN Fail ELSE
    LET clrSessBegin == ReadBytes(settlSessBegin.rest, 8) IN IF ~clrSessBegin.ok THEN Fail ELSE
    Ok([ tradSesOpenTime                           |-> tradSesOpenTime.value,
         tradSesCloseTime                          |-> tradSesCloseTime.value,
         tradingSessionId                          |-> tradingSessionId.value,
         exchangeTradingSessionIdInt32NullOptional |-> exchangeTradingSessionIdInt32NullOptional.value,
         tradSesStatus                             |-> tradSesStatus.value,
         marketSegmentId                           |-> marketSegmentId.value,
         tradSesEvent                              |-> tradSesEvent.value,
         tradePeriodId                             |-> tradePeriodId.value,
         settlSessBegin                            |-> settlSessBegin.value,
         clrSessBegin                              |-> clrSessBegin.value ], clrSessBegin.rest)

ZeroTradingSessionStatusMessage ==
    [ tradSesOpenTime                           |-> [i \in 1 .. 8 |-> 0],
      tradSesCloseTime                          |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId                          |-> [i \in 1 .. 1 |-> 0],
      exchangeTradingSessionIdInt32NullOptional |-> [i \in 1 .. 4 |-> 0],
      tradSesStatus                             |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId                           |-> [i \in 1 .. 1 |-> 0],
      tradSesEvent                              |-> [i \in 1 .. 1 |-> 0],
      tradePeriodId                             |-> [i \in 1 .. 8 |-> 0],
      settlSessBegin                            |-> [i \in 1 .. 8 |-> 0],
      clrSessBegin                              |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesOpenTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesCloseTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.exchangeTradingSessionIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradePeriodId = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.settlSessBegin = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.clrSessBegin = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Mass Status Message No Related Sym Group: 5 bytes              *)
(***************************************************************************)

SecurityMassStatusMessageNoRelatedSymGroup ==
    [ securityId            : Sample(4),
      securityTradingStatus : Sample(1) ]

EncodeSecurityMassStatusMessageNoRelatedSymGroup(message) ==
    message.securityId
        \o message.securityTradingStatus

DecodeSecurityMassStatusMessageNoRelatedSymGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         securityTradingStatus |-> securityTradingStatus.value ], securityTradingStatus.rest)

ZeroSecurityMassStatusMessageNoRelatedSymGroup ==
    [ securityId            |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Security Mass Status Message No Related Sym Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityMassStatusMessageNoRelatedSymGroup ==
    { ZeroSecurityMassStatusMessageNoRelatedSymGroup }
        \cup { [ZeroSecurityMassStatusMessageNoRelatedSymGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityMassStatusMessageNoRelatedSymGroup EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }

(* A run of Security Mass Status Message No Related Sym Group, written one after another *)
RECURSIVE EncodeSecurityMassStatusMessageNoRelatedSymGroupList(_)
EncodeSecurityMassStatusMessageNoRelatedSymGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityMassStatusMessageNoRelatedSymGroup(Head(messages)) \o EncodeSecurityMassStatusMessageNoRelatedSymGroupList(Tail(messages))

(* As many Security Mass Status Message No Related Sym Group as the field that counts them says *)
RECURSIVE ReadSecurityMassStatusMessageNoRelatedSymGroupList(_, _)
ReadSecurityMassStatusMessageNoRelatedSymGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityMassStatusMessageNoRelatedSymGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityMassStatusMessageNoRelatedSymGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Mass Status Message No Related Sym Group of each kind, for the lists that carry them *)
OneSecurityMassStatusMessageNoRelatedSymGroup == { ZeroSecurityMassStatusMessageNoRelatedSymGroup }

(***************************************************************************)
(* Security Mass Status Message No Related Sym Groups                      *)
(***************************************************************************)

SecurityMassStatusMessageNoRelatedSymGroups ==
    [ blockLength                                : Sample(2),
      securityMassStatusMessageNoRelatedSymGroup : SampleLists(OneSecurityMassStatusMessageNoRelatedSymGroup) ]

EncodeSecurityMassStatusMessageNoRelatedSymGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.securityMassStatusMessageNoRelatedSymGroup), 2)
        \o EncodeSecurityMassStatusMessageNoRelatedSymGroupList(message.securityMassStatusMessageNoRelatedSymGroup)

DecodeSecurityMassStatusMessageNoRelatedSymGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroupUint16 == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroupUint16.ok THEN Fail ELSE
    LET securityMassStatusMessageNoRelatedSymGroup == ReadSecurityMassStatusMessageNoRelatedSymGroupList(numInGroupUint16.rest, numInGroupUint16.value) IN IF ~securityMassStatusMessageNoRelatedSymGroup.ok THEN Fail ELSE
    Ok([ blockLength                                |-> blockLength.value,
         securityMassStatusMessageNoRelatedSymGroup |-> securityMassStatusMessageNoRelatedSymGroup.value ], securityMassStatusMessageNoRelatedSymGroup.rest)

ZeroSecurityMassStatusMessageNoRelatedSymGroups ==
    [ blockLength                                |-> [i \in 1 .. 2 |-> 0],
      securityMassStatusMessageNoRelatedSymGroup |-> << >> ]

(* Security Mass Status Message No Related Sym Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityMassStatusMessageNoRelatedSymGroups ==
    { ZeroSecurityMassStatusMessageNoRelatedSymGroups }
        \cup { [ZeroSecurityMassStatusMessageNoRelatedSymGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityMassStatusMessageNoRelatedSymGroups EXCEPT !.securityMassStatusMessageNoRelatedSymGroup = one] : one \in SampleLists(OneSecurityMassStatusMessageNoRelatedSymGroup) }

(***************************************************************************)
(* Security Mass Status Message                                            *)
(***************************************************************************)

SecurityMassStatusMessage ==
    [ securityMassStatusMessageNoRelatedSymGroups : SecurityMassStatusMessageNoRelatedSymGroups ]

EncodeSecurityMassStatusMessage(message) ==
    EncodeSecurityMassStatusMessageNoRelatedSymGroups(message.securityMassStatusMessageNoRelatedSymGroups)

DecodeSecurityMassStatusMessage(bytes) ==
    LET securityMassStatusMessageNoRelatedSymGroups == DecodeSecurityMassStatusMessageNoRelatedSymGroups(bytes) IN IF ~securityMassStatusMessageNoRelatedSymGroups.ok THEN Fail ELSE
    Ok([ securityMassStatusMessageNoRelatedSymGroups |-> securityMassStatusMessageNoRelatedSymGroups.value ], securityMassStatusMessageNoRelatedSymGroups.rest)

ZeroSecurityMassStatusMessage ==
    [ securityMassStatusMessageNoRelatedSymGroups |-> ZeroSecurityMassStatusMessageNoRelatedSymGroups ]

(* Security Mass Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityMassStatusMessage ==
    { ZeroSecurityMassStatusMessage }
        \cup { [ZeroSecurityMassStatusMessage EXCEPT !.securityMassStatusMessageNoRelatedSymGroups = one] : one \in CheckedSecurityMassStatusMessageNoRelatedSymGroups }

(***************************************************************************)
(* Security Group Status Message: 38 bytes                                 *)
(***************************************************************************)

SecurityGroupStatusMessage ==
    [ securityGroupId                 : Sample(8),
      haltType                        : Sample(1),
      tradeModeMask                   : Sample(4),
      groupMaskInt64NullOptional      : Sample(8),
      sectionIdInt32NullOptional      : Sample(4),
      baseContractIdInt32NullOptional : Sample(4),
      securityTradingStatus           : Sample(1),
      statusChangeTime                : Sample(8) ]

EncodeSecurityGroupStatusMessage(message) ==
    message.securityGroupId
        \o message.haltType
        \o message.tradeModeMask
        \o message.groupMaskInt64NullOptional
        \o message.sectionIdInt32NullOptional
        \o message.baseContractIdInt32NullOptional
        \o message.securityTradingStatus
        \o message.statusChangeTime

DecodeSecurityGroupStatusMessage(bytes) ==
    LET securityGroupId == ReadBytes(bytes, 8) IN IF ~securityGroupId.ok THEN Fail ELSE
    LET haltType == ReadBytes(securityGroupId.rest, 1) IN IF ~haltType.ok THEN Fail ELSE
    LET tradeModeMask == ReadBytes(haltType.rest, 4) IN IF ~tradeModeMask.ok THEN Fail ELSE
    LET groupMaskInt64NullOptional == ReadBytes(tradeModeMask.rest, 8) IN IF ~groupMaskInt64NullOptional.ok THEN Fail ELSE
    LET sectionIdInt32NullOptional == ReadBytes(groupMaskInt64NullOptional.rest, 4) IN IF ~sectionIdInt32NullOptional.ok THEN Fail ELSE
    LET baseContractIdInt32NullOptional == ReadBytes(sectionIdInt32NullOptional.rest, 4) IN IF ~baseContractIdInt32NullOptional.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(baseContractIdInt32NullOptional.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET statusChangeTime == ReadBytes(securityTradingStatus.rest, 8) IN IF ~statusChangeTime.ok THEN Fail ELSE
    Ok([ securityGroupId                 |-> securityGroupId.value,
         haltType                        |-> haltType.value,
         tradeModeMask                   |-> tradeModeMask.value,
         groupMaskInt64NullOptional      |-> groupMaskInt64NullOptional.value,
         sectionIdInt32NullOptional      |-> sectionIdInt32NullOptional.value,
         baseContractIdInt32NullOptional |-> baseContractIdInt32NullOptional.value,
         securityTradingStatus           |-> securityTradingStatus.value,
         statusChangeTime                |-> statusChangeTime.value ], statusChangeTime.rest)

ZeroSecurityGroupStatusMessage ==
    [ securityGroupId                 |-> [i \in 1 .. 8 |-> 0],
      haltType                        |-> [i \in 1 .. 1 |-> 0],
      tradeModeMask                   |-> [i \in 1 .. 4 |-> 0],
      groupMaskInt64NullOptional      |-> [i \in 1 .. 8 |-> 0],
      sectionIdInt32NullOptional      |-> [i \in 1 .. 4 |-> 0],
      baseContractIdInt32NullOptional |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus           |-> [i \in 1 .. 1 |-> 0],
      statusChangeTime                |-> [i \in 1 .. 8 |-> 0] ]

(* Security Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityGroupStatusMessage ==
    { ZeroSecurityGroupStatusMessage }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.securityGroupId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.haltType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.tradeModeMask = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.groupMaskInt64NullOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.sectionIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.baseContractIdInt32NullOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupStatusMessage EXCEPT !.statusChangeTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SequenceResetMessageCode == 2  \* 0x02
SecurityStatusMessageCode == 28  \* 0x1c
SecurityDefinitionUpdateReportMessageCode == 10  \* 0x0a
TradingSessionStatusMessageCode == 26  \* 0x1a
SecurityMassStatusMessageCode == 19  \* 0x13
SecurityGroupStatusMessageCode == 22  \* 0x16

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {SecurityDefinitionUpdateReportMessageCode}, body : SecurityDefinitionUpdateReportMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {SecurityMassStatusMessageCode}, body : SecurityMassStatusMessage ]
        \cup [ tag : {SecurityGroupStatusMessageCode}, body : SecurityGroupStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = SecurityDefinitionUpdateReportMessageCode -> EncodeSecurityDefinitionUpdateReportMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = SecurityMassStatusMessageCode -> EncodeSecurityMassStatusMessage(message.body)
      [] message.tag = SecurityGroupStatusMessageCode -> EncodeSecurityGroupStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = SecurityDefinitionUpdateReportMessageCode -> DecodeSecurityDefinitionUpdateReportMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = SecurityMassStatusMessageCode -> DecodeSecurityMassStatusMessage(bytes)
              [] tag = SecurityGroupStatusMessageCode -> DecodeSecurityGroupStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> SecurityDefinitionUpdateReportMessageCode, body |-> one] : one \in CheckedSecurityDefinitionUpdateReportMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> SecurityMassStatusMessageCode, body |-> one] : one \in CheckedSecurityMassStatusMessage }
        \cup { [tag |-> SecurityGroupStatusMessageCode, body |-> one] : one \in CheckedSecurityGroupStatusMessage }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessage(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionUpdateReportMessageCode, body |-> ZeroSecurityDefinitionUpdateReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityMassStatusMessageCode, body |-> ZeroSecurityMassStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityGroupStatusMessageCode, body |-> ZeroSecurityGroupStatusMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ marketDataPacketHeader  : MarketDataPacketHeader,
      incrementalPacketHeader : IncrementalPacketHeader,
      message                 : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeMarketDataPacketHeader(message.marketDataPacketHeader)
        \o EncodeIncrementalPacketHeader(message.incrementalPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET marketDataPacketHeader == DecodeMarketDataPacketHeader(bytes) IN IF ~marketDataPacketHeader.ok THEN Fail ELSE
    LET incrementalPacketHeader == DecodeIncrementalPacketHeader(marketDataPacketHeader.rest) IN IF ~incrementalPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(incrementalPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ marketDataPacketHeader  |-> marketDataPacketHeader.value,
         incrementalPacketHeader |-> incrementalPacketHeader.value,
         message                 |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ marketDataPacketHeader  |-> ZeroMarketDataPacketHeader,
      incrementalPacketHeader |-> ZeroIncrementalPacketHeader,
      message                 |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.marketDataPacketHeader = one] : one \in CheckedMarketDataPacketHeader }
        \cup { [ZeroUdpPacket EXCEPT !.incrementalPacketHeader = one] : one \in CheckedIncrementalPacketHeader }
        \cup { [ZeroUdpPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Market Data Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataPacketHeader ==
    \A message \in CheckedMarketDataPacketHeader :
        LET read == DecodeMarketDataPacketHeader(EncodeMarketDataPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalPacketHeader ==
    \A message \in CheckedIncrementalPacketHeader :
        LET read == DecodeIncrementalPacketHeader(EncodeIncrementalPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
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

(* Every Security Definition Update Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionUpdateReportMessage ==
    \A message \in CheckedSecurityDefinitionUpdateReportMessage :
        LET read == DecodeSecurityDefinitionUpdateReportMessage(EncodeSecurityDefinitionUpdateReportMessage(message))
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

(* Every Security Mass Status Message No Related Sym Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityMassStatusMessageNoRelatedSymGroup ==
    \A message \in CheckedSecurityMassStatusMessageNoRelatedSymGroup :
        LET read == DecodeSecurityMassStatusMessageNoRelatedSymGroup(EncodeSecurityMassStatusMessageNoRelatedSymGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Mass Status Message No Related Sym Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityMassStatusMessageNoRelatedSymGroups ==
    \A message \in CheckedSecurityMassStatusMessageNoRelatedSymGroups :
        LET read == DecodeSecurityMassStatusMessageNoRelatedSymGroups(EncodeSecurityMassStatusMessageNoRelatedSymGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Mass Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityMassStatusMessage ==
    \A message \in CheckedSecurityMassStatusMessage :
        LET read == DecodeSecurityMassStatusMessage(EncodeSecurityMassStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityGroupStatusMessage ==
    \A message \in CheckedSecurityGroupStatusMessage :
        LET read == DecodeSecurityGroupStatusMessage(EncodeSecurityGroupStatusMessage(message))
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

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
