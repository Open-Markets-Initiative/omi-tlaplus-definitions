------------------- MODULE B3Derivatives_BinaryUmdf_v1_6 -------------------
(***************************************************************************)
(* Brasil, Bolsa, Balcão Binary Unified Market Data Feed v1.6              *)
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
(* Note: Match Event Indicator is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Imbalance Condition is a bit field set, checked as its 2 bytes    *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Trade Condition is a bit field set, checked as its 2 bytes rather *)
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
(* Packet Header: 16 bytes                                                 *)
(***************************************************************************)

PacketHeader ==
    [ channelId       : Sample(1),
      packetReserved  : Sample(1),
      sequenceVersion : Sample(2),
      sequenceNumber  : Sample(4),
      sendingTime     : Sample(8) ]

EncodePacketHeader(message) ==
    message.channelId
        \o message.packetReserved
        \o message.sequenceVersion
        \o message.sequenceNumber
        \o message.sendingTime

DecodePacketHeader(bytes) ==
    LET channelId == ReadBytes(bytes, 1) IN IF ~channelId.ok THEN Fail ELSE
    LET packetReserved == ReadBytes(channelId.rest, 1) IN IF ~packetReserved.ok THEN Fail ELSE
    LET sequenceVersion == ReadBytes(packetReserved.rest, 2) IN IF ~sequenceVersion.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(sequenceVersion.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(sequenceNumber.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ channelId       |-> channelId.value,
         packetReserved  |-> packetReserved.value,
         sequenceVersion |-> sequenceVersion.value,
         sequenceNumber  |-> sequenceNumber.value,
         sendingTime     |-> sendingTime.value ], sendingTime.rest)

ZeroPacketHeader ==
    [ channelId       |-> [i \in 1 .. 1 |-> 0],
      packetReserved  |-> [i \in 1 .. 1 |-> 0],
      sequenceVersion |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0] ]

(* Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedPacketHeader ==
    { ZeroPacketHeader }
        \cup { [ZeroPacketHeader EXCEPT !.channelId = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.packetReserved = one] : one \in Sample(1) }
        \cup { [ZeroPacketHeader EXCEPT !.sequenceVersion = one] : one \in Sample(2) }
        \cup { [ZeroPacketHeader EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequence Message: 4 bytes                                               *)
(***************************************************************************)

SequenceMessage ==
    [ nextSeqNo : Sample(4) ]

EncodeSequenceMessage(message) ==
    message.nextSeqNo

DecodeSequenceMessage(bytes) ==
    LET nextSeqNo == ReadBytes(bytes, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ nextSeqNo |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSequenceMessage ==
    [ nextSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceMessage ==
    { ZeroSequenceMessage }
        \cup { [ZeroSequenceMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Status 3 Message: 36 bytes                                     *)
(***************************************************************************)

SecurityStatus3Message ==
    [ securityId            : Sample(8),
      matchEventIndicator   : Sample(1),
      tradingSessionId      : Sample(1),
      securityTradingStatus : Sample(1),
      securityTradingEvent  : Sample(1),
      tradeDate             : Sample(2),
      offset14Padding2      : Sample(2),
      tradSesOpenTime       : Sample(8),
      transactTime          : Sample(8),
      rptSeq                : Sample(4) ]

EncodeSecurityStatus3Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.securityTradingStatus
        \o message.securityTradingEvent
        \o message.tradeDate
        \o message.offset14Padding2
        \o message.tradSesOpenTime
        \o message.transactTime
        \o message.rptSeq

DecodeSecurityStatus3Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(tradingSessionId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(securityTradingStatus.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(securityTradingEvent.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET offset14Padding2 == ReadBytes(tradeDate.rest, 2) IN IF ~offset14Padding2.ok THEN Fail ELSE
    LET tradSesOpenTime == ReadBytes(offset14Padding2.rest, 8) IN IF ~tradSesOpenTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradSesOpenTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         matchEventIndicator   |-> matchEventIndicator.value,
         tradingSessionId      |-> tradingSessionId.value,
         securityTradingStatus |-> securityTradingStatus.value,
         securityTradingEvent  |-> securityTradingEvent.value,
         tradeDate             |-> tradeDate.value,
         offset14Padding2      |-> offset14Padding2.value,
         tradSesOpenTime       |-> tradSesOpenTime.value,
         transactTime          |-> transactTime.value,
         rptSeq                |-> rptSeq.value ], rptSeq.rest)

ZeroSecurityStatus3Message ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator   |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId      |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent  |-> [i \in 1 .. 1 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      offset14Padding2      |-> [i \in 1 .. 2 |-> 0],
      tradSesOpenTime       |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      rptSeq                |-> [i \in 1 .. 4 |-> 0] ]

(* Security Status 3 Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatus3Message ==
    { ZeroSecurityStatus3Message }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.offset14Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.tradSesOpenTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatus3Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Group Phase 10 Message: 32 bytes                               *)
(***************************************************************************)

SecurityGroupPhase10Message ==
    [ securityGroup        : Sample(3),
      offset3Padding5      : Sample(5),
      matchEventIndicator  : Sample(1),
      tradingSessionId     : Sample(1),
      tradingSessionSubId  : Sample(1),
      securityTradingEvent : Sample(1),
      tradeDate            : Sample(2),
      offset14Padding2     : Sample(2),
      tradSesOpenTime      : Sample(8),
      transactTime         : Sample(8) ]

EncodeSecurityGroupPhase10Message(message) ==
    message.securityGroup
        \o message.offset3Padding5
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.securityTradingEvent
        \o message.tradeDate
        \o message.offset14Padding2
        \o message.tradSesOpenTime
        \o message.transactTime

DecodeSecurityGroupPhase10Message(bytes) ==
    LET securityGroup == ReadBytes(bytes, 3) IN IF ~securityGroup.ok THEN Fail ELSE
    LET offset3Padding5 == ReadBytes(securityGroup.rest, 5) IN IF ~offset3Padding5.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(offset3Padding5.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(securityTradingEvent.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET offset14Padding2 == ReadBytes(tradeDate.rest, 2) IN IF ~offset14Padding2.ok THEN Fail ELSE
    LET tradSesOpenTime == ReadBytes(offset14Padding2.rest, 8) IN IF ~tradSesOpenTime.ok THEN Fail ELSE
    LET transactTime == ReadBytes(tradSesOpenTime.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ securityGroup        |-> securityGroup.value,
         offset3Padding5      |-> offset3Padding5.value,
         matchEventIndicator  |-> matchEventIndicator.value,
         tradingSessionId     |-> tradingSessionId.value,
         tradingSessionSubId  |-> tradingSessionSubId.value,
         securityTradingEvent |-> securityTradingEvent.value,
         tradeDate            |-> tradeDate.value,
         offset14Padding2     |-> offset14Padding2.value,
         tradSesOpenTime      |-> tradSesOpenTime.value,
         transactTime         |-> transactTime.value ], transactTime.rest)

ZeroSecurityGroupPhase10Message ==
    [ securityGroup        |-> [i \in 1 .. 3 |-> 0],
      offset3Padding5      |-> [i \in 1 .. 5 |-> 0],
      matchEventIndicator  |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId     |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId  |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent |-> [i \in 1 .. 1 |-> 0],
      tradeDate            |-> [i \in 1 .. 2 |-> 0],
      offset14Padding2     |-> [i \in 1 .. 2 |-> 0],
      tradSesOpenTime      |-> [i \in 1 .. 8 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Security Group Phase 10 Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityGroupPhase10Message ==
    { ZeroSecurityGroupPhase10Message }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.securityGroup = one] : one \in Sample(3) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.offset3Padding5 = one] : one \in Sample(5) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.offset14Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.tradSesOpenTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityGroupPhase10Message EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear ==
    { ZeroMaturityMonthYear }
        \cup { [ZeroMaturityMonthYear EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Settl Month: 5 bytes                                           *)
(***************************************************************************)

ContractSettlMonth ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeContractSettlMonth(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeContractSettlMonth(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroContractSettlMonth ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Settl Month at zero, then each field in turn at the values it is checked at *)
CheckedContractSettlMonth ==
    { ZeroContractSettlMonth }
        \cup { [ZeroContractSettlMonth EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroContractSettlMonth EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroContractSettlMonth EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroContractSettlMonth EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Deprecated Underlyings Group: 44 bytes                                  *)
(***************************************************************************)

DeprecatedUnderlyingsGroup ==
    [ underlyingSecurityId : Sample(8),
      indexPct             : Sample(8),
      indexTheoreticalQty  : Sample(8),
      underlyingSymbol     : Sample(20) ]

EncodeDeprecatedUnderlyingsGroup(message) ==
    message.underlyingSecurityId
        \o message.indexPct
        \o message.indexTheoreticalQty
        \o message.underlyingSymbol

DecodeDeprecatedUnderlyingsGroup(bytes) ==
    LET underlyingSecurityId == ReadBytes(bytes, 8) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET indexPct == ReadBytes(underlyingSecurityId.rest, 8) IN IF ~indexPct.ok THEN Fail ELSE
    LET indexTheoreticalQty == ReadBytes(indexPct.rest, 8) IN IF ~indexTheoreticalQty.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(indexTheoreticalQty.rest, 20) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ underlyingSecurityId |-> underlyingSecurityId.value,
         indexPct             |-> indexPct.value,
         indexTheoreticalQty  |-> indexTheoreticalQty.value,
         underlyingSymbol     |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroDeprecatedUnderlyingsGroup ==
    [ underlyingSecurityId |-> [i \in 1 .. 8 |-> 0],
      indexPct             |-> [i \in 1 .. 8 |-> 0],
      indexTheoreticalQty  |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol     |-> [i \in 1 .. 20 |-> 0] ]

(* Deprecated Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedUnderlyingsGroup ==
    { ZeroDeprecatedUnderlyingsGroup }
        \cup { [ZeroDeprecatedUnderlyingsGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedUnderlyingsGroup EXCEPT !.indexPct = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedUnderlyingsGroup EXCEPT !.indexTheoreticalQty = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(20) }

(* A run of Deprecated Underlyings Group, written one after another *)
RECURSIVE EncodeDeprecatedUnderlyingsGroupList(_)
EncodeDeprecatedUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDeprecatedUnderlyingsGroup(Head(messages)) \o EncodeDeprecatedUnderlyingsGroupList(Tail(messages))

(* As many Deprecated Underlyings Group as the field that counts them says *)
RECURSIVE ReadDeprecatedUnderlyingsGroupList(_, _)
ReadDeprecatedUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDeprecatedUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDeprecatedUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Deprecated Underlyings Group of each kind, for the lists that carry them *)
OneDeprecatedUnderlyingsGroup == { ZeroDeprecatedUnderlyingsGroup }

(***************************************************************************)
(* Deprecated Underlyings Groups                                           *)
(***************************************************************************)

DeprecatedUnderlyingsGroups ==
    [ blockLength                : Sample(2),
      deprecatedUnderlyingsGroup : SampleLists(OneDeprecatedUnderlyingsGroup) ]

EncodeDeprecatedUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.deprecatedUnderlyingsGroup), 1)
        \o EncodeDeprecatedUnderlyingsGroupList(message.deprecatedUnderlyingsGroup)

DecodeDeprecatedUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET deprecatedUnderlyingsGroup == ReadDeprecatedUnderlyingsGroupList(numInGroup.rest, numInGroup.value) IN IF ~deprecatedUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         deprecatedUnderlyingsGroup |-> deprecatedUnderlyingsGroup.value ], deprecatedUnderlyingsGroup.rest)

ZeroDeprecatedUnderlyingsGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      deprecatedUnderlyingsGroup |-> << >> ]

(* Deprecated Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedUnderlyingsGroups ==
    { ZeroDeprecatedUnderlyingsGroups }
        \cup { [ZeroDeprecatedUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedUnderlyingsGroups EXCEPT !.deprecatedUnderlyingsGroup = one] : one \in SampleLists(OneDeprecatedUnderlyingsGroup) }

(***************************************************************************)
(* Deprecated Legs Group: 38 bytes                                         *)
(***************************************************************************)

DeprecatedLegsGroup ==
    [ legSecurityId   : Sample(8),
      legRatioQty     : Sample(8),
      legSecurityType : Sample(1),
      legSide         : Sample(1),
      legSymbol       : Sample(20) ]

EncodeDeprecatedLegsGroup(message) ==
    message.legSecurityId
        \o message.legRatioQty
        \o message.legSecurityType
        \o message.legSide
        \o message.legSymbol

DecodeDeprecatedLegsGroup(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSecurityId.rest, 8) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatioQty.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityType.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legSide.rest, 20) IN IF ~legSymbol.ok THEN Fail ELSE
    Ok([ legSecurityId   |-> legSecurityId.value,
         legRatioQty     |-> legRatioQty.value,
         legSecurityType |-> legSecurityType.value,
         legSide         |-> legSide.value,
         legSymbol       |-> legSymbol.value ], legSymbol.rest)

ZeroDeprecatedLegsGroup ==
    [ legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legRatioQty     |-> [i \in 1 .. 8 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legSymbol       |-> [i \in 1 .. 20 |-> 0] ]

(* Deprecated Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedLegsGroup ==
    { ZeroDeprecatedLegsGroup }
        \cup { [ZeroDeprecatedLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(20) }

(* A run of Deprecated Legs Group, written one after another *)
RECURSIVE EncodeDeprecatedLegsGroupList(_)
EncodeDeprecatedLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDeprecatedLegsGroup(Head(messages)) \o EncodeDeprecatedLegsGroupList(Tail(messages))

(* As many Deprecated Legs Group as the field that counts them says *)
RECURSIVE ReadDeprecatedLegsGroupList(_, _)
ReadDeprecatedLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDeprecatedLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDeprecatedLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Deprecated Legs Group of each kind, for the lists that carry them *)
OneDeprecatedLegsGroup == { ZeroDeprecatedLegsGroup }

(***************************************************************************)
(* Deprecated Legs Groups                                                  *)
(***************************************************************************)

DeprecatedLegsGroups ==
    [ blockLength         : Sample(2),
      deprecatedLegsGroup : SampleLists(OneDeprecatedLegsGroup) ]

EncodeDeprecatedLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.deprecatedLegsGroup), 1)
        \o EncodeDeprecatedLegsGroupList(message.deprecatedLegsGroup)

DecodeDeprecatedLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET deprecatedLegsGroup == ReadDeprecatedLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~deprecatedLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength         |-> blockLength.value,
         deprecatedLegsGroup |-> deprecatedLegsGroup.value ], deprecatedLegsGroup.rest)

ZeroDeprecatedLegsGroups ==
    [ blockLength         |-> [i \in 1 .. 2 |-> 0],
      deprecatedLegsGroup |-> << >> ]

(* Deprecated Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedLegsGroups ==
    { ZeroDeprecatedLegsGroups }
        \cup { [ZeroDeprecatedLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedLegsGroups EXCEPT !.deprecatedLegsGroup = one] : one \in SampleLists(OneDeprecatedLegsGroup) }

(***************************************************************************)
(* Deprecated Instr Attribs Group: 2 bytes                                 *)
(***************************************************************************)

DeprecatedInstrAttribsGroup ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(1) ]

EncodeDeprecatedInstrAttribsGroup(message) ==
    message.instrAttribType
        \o message.instrAttribValue

DecodeDeprecatedInstrAttribsGroup(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 1) IN IF ~instrAttribValue.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value ], instrAttribValue.rest)

ZeroDeprecatedInstrAttribsGroup ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 1 |-> 0] ]

(* Deprecated Instr Attribs Group at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedInstrAttribsGroup ==
    { ZeroDeprecatedInstrAttribsGroup }
        \cup { [ZeroDeprecatedInstrAttribsGroup EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedInstrAttribsGroup EXCEPT !.instrAttribValue = one] : one \in Sample(1) }

(* A run of Deprecated Instr Attribs Group, written one after another *)
RECURSIVE EncodeDeprecatedInstrAttribsGroupList(_)
EncodeDeprecatedInstrAttribsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDeprecatedInstrAttribsGroup(Head(messages)) \o EncodeDeprecatedInstrAttribsGroupList(Tail(messages))

(* As many Deprecated Instr Attribs Group as the field that counts them says *)
RECURSIVE ReadDeprecatedInstrAttribsGroupList(_, _)
ReadDeprecatedInstrAttribsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDeprecatedInstrAttribsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDeprecatedInstrAttribsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Deprecated Instr Attribs Group of each kind, for the lists that carry them *)
OneDeprecatedInstrAttribsGroup == { ZeroDeprecatedInstrAttribsGroup }

(***************************************************************************)
(* Deprecated Instr Attribs Groups                                         *)
(***************************************************************************)

DeprecatedInstrAttribsGroups ==
    [ blockLength                 : Sample(2),
      deprecatedInstrAttribsGroup : SampleLists(OneDeprecatedInstrAttribsGroup) ]

EncodeDeprecatedInstrAttribsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.deprecatedInstrAttribsGroup), 1)
        \o EncodeDeprecatedInstrAttribsGroupList(message.deprecatedInstrAttribsGroup)

DecodeDeprecatedInstrAttribsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET deprecatedInstrAttribsGroup == ReadDeprecatedInstrAttribsGroupList(numInGroup.rest, numInGroup.value) IN IF ~deprecatedInstrAttribsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         deprecatedInstrAttribsGroup |-> deprecatedInstrAttribsGroup.value ], deprecatedInstrAttribsGroup.rest)

ZeroDeprecatedInstrAttribsGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      deprecatedInstrAttribsGroup |-> << >> ]

(* Deprecated Instr Attribs Groups at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedInstrAttribsGroups ==
    { ZeroDeprecatedInstrAttribsGroups }
        \cup { [ZeroDeprecatedInstrAttribsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedInstrAttribsGroups EXCEPT !.deprecatedInstrAttribsGroup = one] : one \in SampleLists(OneDeprecatedInstrAttribsGroup) }

(***************************************************************************)
(* Security Desc                                                           *)
(***************************************************************************)

SecurityDesc ==
    [ securityDescData : SampleBytes ]

EncodeSecurityDesc(message) ==
    EncodeUIntBE(Len(message.securityDescData), 1)
        \o message.securityDescData

DecodeSecurityDesc(bytes) ==
    LET securityDescLength == ReadUIntBE(bytes, 1) IN IF ~securityDescLength.ok THEN Fail ELSE
    LET securityDescData == ReadBytes(securityDescLength.rest, securityDescLength.value) IN IF ~securityDescData.ok THEN Fail ELSE
    Ok([ securityDescData |-> securityDescData.value ], securityDescData.rest)

ZeroSecurityDesc ==
    [ securityDescData |-> << >> ]

(* Security Desc at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDesc ==
    { ZeroSecurityDesc }
        \cup { [ZeroSecurityDesc EXCEPT !.securityDescData = one] : one \in SampleBytes }

(***************************************************************************)
(* Deprecated Security Definition Message                                  *)
(***************************************************************************)

DeprecatedSecurityDefinitionMessage ==
    [ securityId                   : Sample(8),
      securityExchange             : Sample(4),
      securityIdSource             : Sample(1),
      securityGroup                : Sample(3),
      symbol                       : Sample(20),
      securityUpdateAction         : Sample(1),
      securityType                 : Sample(1),
      securitySubType              : Sample(2),
      totNoRelatedSym              : Sample(4),
      minPriceIncrement            : Sample(8),
      strikePrice                  : Sample(8),
      contractMultiplier           : Sample(8),
      priceDivisor                 : Sample(8),
      securityValidityTimestamp    : Sample(8),
      noSharesIssued               : Sample(8),
      clearingHouseId              : Sample(8),
      minOrderQty                  : Sample(8),
      maxOrderQty                  : Sample(8),
      minLotSize                   : Sample(8),
      minTradeVol                  : Sample(8),
      corporateActionEventId       : Sample(4),
      issueDate                    : Sample(4),
      maturityDate                 : Sample(4),
      countryOfIssue               : Sample(2),
      startDate                    : Sample(4),
      endDate                      : Sample(4),
      settlType                    : Sample(2),
      settlDate                    : Sample(4),
      datedDate                    : Sample(4),
      isinNumber                   : Sample(12),
      asset                        : Sample(6),
      cfiCode                      : Sample(6),
      maturityMonthYear            : MaturityMonthYear,
      contractSettlMonth           : ContractSettlMonth,
      currency                     : Sample(3),
      strikeCurrency               : Sample(3),
      settlCurrency                : Sample(3),
      securityStrategyType         : Sample(3),
      lotType                      : Sample(1),
      tickSizeDenominator          : Sample(1),
      product                      : Sample(1),
      exerciseStyle                : Sample(1),
      putOrCall                    : Sample(1),
      priceType                    : Sample(1),
      marketSegmentId              : Sample(1),
      governanceIndicator          : Sample(1),
      securityMatchType            : Sample(1),
      lastFragment                 : Sample(1),
      multiLegModel                : Sample(1),
      multiLegPriceMethod          : Sample(1),
      minCrossQty                  : Sample(8),
      deprecatedUnderlyingsGroups  : DeprecatedUnderlyingsGroups,
      deprecatedLegsGroups         : DeprecatedLegsGroups,
      deprecatedInstrAttribsGroups : DeprecatedInstrAttribsGroups,
      securityDesc                 : SecurityDesc ]

EncodeDeprecatedSecurityDefinitionMessage(message) ==
    message.securityId
        \o message.securityExchange
        \o message.securityIdSource
        \o message.securityGroup
        \o message.symbol
        \o message.securityUpdateAction
        \o message.securityType
        \o message.securitySubType
        \o message.totNoRelatedSym
        \o message.minPriceIncrement
        \o message.strikePrice
        \o message.contractMultiplier
        \o message.priceDivisor
        \o message.securityValidityTimestamp
        \o message.noSharesIssued
        \o message.clearingHouseId
        \o message.minOrderQty
        \o message.maxOrderQty
        \o message.minLotSize
        \o message.minTradeVol
        \o message.corporateActionEventId
        \o message.issueDate
        \o message.maturityDate
        \o message.countryOfIssue
        \o message.startDate
        \o message.endDate
        \o message.settlType
        \o message.settlDate
        \o message.datedDate
        \o message.isinNumber
        \o message.asset
        \o message.cfiCode
        \o EncodeMaturityMonthYear(message.maturityMonthYear)
        \o EncodeContractSettlMonth(message.contractSettlMonth)
        \o message.currency
        \o message.strikeCurrency
        \o message.settlCurrency
        \o message.securityStrategyType
        \o message.lotType
        \o message.tickSizeDenominator
        \o message.product
        \o message.exerciseStyle
        \o message.putOrCall
        \o message.priceType
        \o message.marketSegmentId
        \o message.governanceIndicator
        \o message.securityMatchType
        \o message.lastFragment
        \o message.multiLegModel
        \o message.multiLegPriceMethod
        \o message.minCrossQty
        \o EncodeDeprecatedUnderlyingsGroups(message.deprecatedUnderlyingsGroups)
        \o EncodeDeprecatedLegsGroups(message.deprecatedLegsGroups)
        \o EncodeDeprecatedInstrAttribsGroups(message.deprecatedInstrAttribsGroups)
        \o EncodeSecurityDesc(message.securityDesc)

DecodeDeprecatedSecurityDefinitionMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityId.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityExchange.rest, 1) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityIdSource.rest, 3) IN IF ~securityGroup.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityGroup.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(symbol.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityUpdateAction.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(securityType.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET totNoRelatedSym == ReadBytes(securitySubType.rest, 4) IN IF ~totNoRelatedSym.ok THEN Fail ELSE
    LET minPriceIncrement == ReadBytes(totNoRelatedSym.rest, 8) IN IF ~minPriceIncrement.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(minPriceIncrement.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(strikePrice.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET priceDivisor == ReadBytes(contractMultiplier.rest, 8) IN IF ~priceDivisor.ok THEN Fail ELSE
    LET securityValidityTimestamp == ReadBytes(priceDivisor.rest, 8) IN IF ~securityValidityTimestamp.ok THEN Fail ELSE
    LET noSharesIssued == ReadBytes(securityValidityTimestamp.rest, 8) IN IF ~noSharesIssued.ok THEN Fail ELSE
    LET clearingHouseId == ReadBytes(noSharesIssued.rest, 8) IN IF ~clearingHouseId.ok THEN Fail ELSE
    LET minOrderQty == ReadBytes(clearingHouseId.rest, 8) IN IF ~minOrderQty.ok THEN Fail ELSE
    LET maxOrderQty == ReadBytes(minOrderQty.rest, 8) IN IF ~maxOrderQty.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(maxOrderQty.rest, 8) IN IF ~minLotSize.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(minLotSize.rest, 8) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET corporateActionEventId == ReadBytes(minTradeVol.rest, 4) IN IF ~corporateActionEventId.ok THEN Fail ELSE
    LET issueDate == ReadBytes(corporateActionEventId.rest, 4) IN IF ~issueDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(issueDate.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET countryOfIssue == ReadBytes(maturityDate.rest, 2) IN IF ~countryOfIssue.ok THEN Fail ELSE
    LET startDate == ReadBytes(countryOfIssue.rest, 4) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 4) IN IF ~endDate.ok THEN Fail ELSE
    LET settlType == ReadBytes(endDate.rest, 2) IN IF ~settlType.ok THEN Fail ELSE
    LET settlDate == ReadBytes(settlType.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET datedDate == ReadBytes(settlDate.rest, 4) IN IF ~datedDate.ok THEN Fail ELSE
    LET isinNumber == ReadBytes(datedDate.rest, 12) IN IF ~isinNumber.ok THEN Fail ELSE
    LET asset == ReadBytes(isinNumber.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(asset.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear(cfiCode.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET contractSettlMonth == DecodeContractSettlMonth(maturityMonthYear.rest) IN IF ~contractSettlMonth.ok THEN Fail ELSE
    LET currency == ReadBytes(contractSettlMonth.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET strikeCurrency == ReadBytes(currency.rest, 3) IN IF ~strikeCurrency.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(strikeCurrency.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET securityStrategyType == ReadBytes(settlCurrency.rest, 3) IN IF ~securityStrategyType.ok THEN Fail ELSE
    LET lotType == ReadBytes(securityStrategyType.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET tickSizeDenominator == ReadBytes(lotType.rest, 1) IN IF ~tickSizeDenominator.ok THEN Fail ELSE
    LET product == ReadBytes(tickSizeDenominator.rest, 1) IN IF ~product.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(product.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(exerciseStyle.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET priceType == ReadBytes(putOrCall.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(priceType.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET governanceIndicator == ReadBytes(marketSegmentId.rest, 1) IN IF ~governanceIndicator.ok THEN Fail ELSE
    LET securityMatchType == ReadBytes(governanceIndicator.rest, 1) IN IF ~securityMatchType.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(securityMatchType.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET multiLegModel == ReadBytes(lastFragment.rest, 1) IN IF ~multiLegModel.ok THEN Fail ELSE
    LET multiLegPriceMethod == ReadBytes(multiLegModel.rest, 1) IN IF ~multiLegPriceMethod.ok THEN Fail ELSE
    LET minCrossQty == ReadBytes(multiLegPriceMethod.rest, 8) IN IF ~minCrossQty.ok THEN Fail ELSE
    LET deprecatedUnderlyingsGroups == DecodeDeprecatedUnderlyingsGroups(minCrossQty.rest) IN IF ~deprecatedUnderlyingsGroups.ok THEN Fail ELSE
    LET deprecatedLegsGroups == DecodeDeprecatedLegsGroups(deprecatedUnderlyingsGroups.rest) IN IF ~deprecatedLegsGroups.ok THEN Fail ELSE
    LET deprecatedInstrAttribsGroups == DecodeDeprecatedInstrAttribsGroups(deprecatedLegsGroups.rest) IN IF ~deprecatedInstrAttribsGroups.ok THEN Fail ELSE
    LET securityDesc == DecodeSecurityDesc(deprecatedInstrAttribsGroups.rest) IN IF ~securityDesc.ok THEN Fail ELSE
    Ok([ securityId                   |-> securityId.value,
         securityExchange             |-> securityExchange.value,
         securityIdSource             |-> securityIdSource.value,
         securityGroup                |-> securityGroup.value,
         symbol                       |-> symbol.value,
         securityUpdateAction         |-> securityUpdateAction.value,
         securityType                 |-> securityType.value,
         securitySubType              |-> securitySubType.value,
         totNoRelatedSym              |-> totNoRelatedSym.value,
         minPriceIncrement            |-> minPriceIncrement.value,
         strikePrice                  |-> strikePrice.value,
         contractMultiplier           |-> contractMultiplier.value,
         priceDivisor                 |-> priceDivisor.value,
         securityValidityTimestamp    |-> securityValidityTimestamp.value,
         noSharesIssued               |-> noSharesIssued.value,
         clearingHouseId              |-> clearingHouseId.value,
         minOrderQty                  |-> minOrderQty.value,
         maxOrderQty                  |-> maxOrderQty.value,
         minLotSize                   |-> minLotSize.value,
         minTradeVol                  |-> minTradeVol.value,
         corporateActionEventId       |-> corporateActionEventId.value,
         issueDate                    |-> issueDate.value,
         maturityDate                 |-> maturityDate.value,
         countryOfIssue               |-> countryOfIssue.value,
         startDate                    |-> startDate.value,
         endDate                      |-> endDate.value,
         settlType                    |-> settlType.value,
         settlDate                    |-> settlDate.value,
         datedDate                    |-> datedDate.value,
         isinNumber                   |-> isinNumber.value,
         asset                        |-> asset.value,
         cfiCode                      |-> cfiCode.value,
         maturityMonthYear            |-> maturityMonthYear.value,
         contractSettlMonth           |-> contractSettlMonth.value,
         currency                     |-> currency.value,
         strikeCurrency               |-> strikeCurrency.value,
         settlCurrency                |-> settlCurrency.value,
         securityStrategyType         |-> securityStrategyType.value,
         lotType                      |-> lotType.value,
         tickSizeDenominator          |-> tickSizeDenominator.value,
         product                      |-> product.value,
         exerciseStyle                |-> exerciseStyle.value,
         putOrCall                    |-> putOrCall.value,
         priceType                    |-> priceType.value,
         marketSegmentId              |-> marketSegmentId.value,
         governanceIndicator          |-> governanceIndicator.value,
         securityMatchType            |-> securityMatchType.value,
         lastFragment                 |-> lastFragment.value,
         multiLegModel                |-> multiLegModel.value,
         multiLegPriceMethod          |-> multiLegPriceMethod.value,
         minCrossQty                  |-> minCrossQty.value,
         deprecatedUnderlyingsGroups  |-> deprecatedUnderlyingsGroups.value,
         deprecatedLegsGroups         |-> deprecatedLegsGroups.value,
         deprecatedInstrAttribsGroups |-> deprecatedInstrAttribsGroups.value,
         securityDesc                 |-> securityDesc.value ], securityDesc.rest)

ZeroDeprecatedSecurityDefinitionMessage ==
    [ securityId                   |-> [i \in 1 .. 8 |-> 0],
      securityExchange             |-> [i \in 1 .. 4 |-> 0],
      securityIdSource             |-> [i \in 1 .. 1 |-> 0],
      securityGroup                |-> [i \in 1 .. 3 |-> 0],
      symbol                       |-> [i \in 1 .. 20 |-> 0],
      securityUpdateAction         |-> [i \in 1 .. 1 |-> 0],
      securityType                 |-> [i \in 1 .. 1 |-> 0],
      securitySubType              |-> [i \in 1 .. 2 |-> 0],
      totNoRelatedSym              |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrement            |-> [i \in 1 .. 8 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      contractMultiplier           |-> [i \in 1 .. 8 |-> 0],
      priceDivisor                 |-> [i \in 1 .. 8 |-> 0],
      securityValidityTimestamp    |-> [i \in 1 .. 8 |-> 0],
      noSharesIssued               |-> [i \in 1 .. 8 |-> 0],
      clearingHouseId              |-> [i \in 1 .. 8 |-> 0],
      minOrderQty                  |-> [i \in 1 .. 8 |-> 0],
      maxOrderQty                  |-> [i \in 1 .. 8 |-> 0],
      minLotSize                   |-> [i \in 1 .. 8 |-> 0],
      minTradeVol                  |-> [i \in 1 .. 8 |-> 0],
      corporateActionEventId       |-> [i \in 1 .. 4 |-> 0],
      issueDate                    |-> [i \in 1 .. 4 |-> 0],
      maturityDate                 |-> [i \in 1 .. 4 |-> 0],
      countryOfIssue               |-> [i \in 1 .. 2 |-> 0],
      startDate                    |-> [i \in 1 .. 4 |-> 0],
      endDate                      |-> [i \in 1 .. 4 |-> 0],
      settlType                    |-> [i \in 1 .. 2 |-> 0],
      settlDate                    |-> [i \in 1 .. 4 |-> 0],
      datedDate                    |-> [i \in 1 .. 4 |-> 0],
      isinNumber                   |-> [i \in 1 .. 12 |-> 0],
      asset                        |-> [i \in 1 .. 6 |-> 0],
      cfiCode                      |-> [i \in 1 .. 6 |-> 0],
      maturityMonthYear            |-> ZeroMaturityMonthYear,
      contractSettlMonth           |-> ZeroContractSettlMonth,
      currency                     |-> [i \in 1 .. 3 |-> 0],
      strikeCurrency               |-> [i \in 1 .. 3 |-> 0],
      settlCurrency                |-> [i \in 1 .. 3 |-> 0],
      securityStrategyType         |-> [i \in 1 .. 3 |-> 0],
      lotType                      |-> [i \in 1 .. 1 |-> 0],
      tickSizeDenominator          |-> [i \in 1 .. 1 |-> 0],
      product                      |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle                |-> [i \in 1 .. 1 |-> 0],
      putOrCall                    |-> [i \in 1 .. 1 |-> 0],
      priceType                    |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 1 |-> 0],
      governanceIndicator          |-> [i \in 1 .. 1 |-> 0],
      securityMatchType            |-> [i \in 1 .. 1 |-> 0],
      lastFragment                 |-> [i \in 1 .. 1 |-> 0],
      multiLegModel                |-> [i \in 1 .. 1 |-> 0],
      multiLegPriceMethod          |-> [i \in 1 .. 1 |-> 0],
      minCrossQty                  |-> [i \in 1 .. 8 |-> 0],
      deprecatedUnderlyingsGroups  |-> ZeroDeprecatedUnderlyingsGroups,
      deprecatedLegsGroups         |-> ZeroDeprecatedLegsGroups,
      deprecatedInstrAttribsGroups |-> ZeroDeprecatedInstrAttribsGroups,
      securityDesc                 |-> ZeroSecurityDesc ]

(* Deprecated Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedDeprecatedSecurityDefinitionMessage ==
    { ZeroDeprecatedSecurityDefinitionMessage }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityIdSource = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityGroup = one] : one \in Sample(3) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.totNoRelatedSym = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.minPriceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.priceDivisor = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityValidityTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.noSharesIssued = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.clearingHouseId = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.maxOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.minLotSize = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.minTradeVol = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.corporateActionEventId = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.issueDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.countryOfIssue = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.endDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.settlType = one] : one \in Sample(2) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.datedDate = one] : one \in Sample(4) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.isinNumber = one] : one \in Sample(12) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.contractSettlMonth = one] : one \in CheckedContractSettlMonth }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityStrategyType = one] : one \in Sample(3) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.tickSizeDenominator = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.product = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.governanceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityMatchType = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.multiLegModel = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.multiLegPriceMethod = one] : one \in Sample(1) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.minCrossQty = one] : one \in Sample(8) }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.deprecatedUnderlyingsGroups = one] : one \in CheckedDeprecatedUnderlyingsGroups }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.deprecatedLegsGroups = one] : one \in CheckedDeprecatedLegsGroups }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.deprecatedInstrAttribsGroups = one] : one \in CheckedDeprecatedInstrAttribsGroups }
        \cup { [ZeroDeprecatedSecurityDefinitionMessage EXCEPT !.securityDesc = one] : one \in CheckedSecurityDesc }

(***************************************************************************)
(* Headline                                                                *)
(***************************************************************************)

Headline ==
    [ headlineData : SampleBytes ]

EncodeHeadline(message) ==
    EncodeUIntLE(Len(message.headlineData), 2)
        \o message.headlineData

DecodeHeadline(bytes) ==
    LET headlineLength == ReadUIntLE(bytes, 2) IN IF ~headlineLength.ok THEN Fail ELSE
    LET headlineData == ReadBytes(headlineLength.rest, headlineLength.value) IN IF ~headlineData.ok THEN Fail ELSE
    Ok([ headlineData |-> headlineData.value ], headlineData.rest)

ZeroHeadline ==
    [ headlineData |-> << >> ]

(* Headline at zero, then each field in turn at the values it is checked at *)
CheckedHeadline ==
    { ZeroHeadline }
        \cup { [ZeroHeadline EXCEPT !.headlineData = one] : one \in SampleBytes }

(***************************************************************************)
(* Text                                                                    *)
(***************************************************************************)

Text ==
    [ textData : SampleBytes ]

EncodeText(message) ==
    EncodeUIntLE(Len(message.textData), 2)
        \o message.textData

DecodeText(bytes) ==
    LET textLength == ReadUIntLE(bytes, 2) IN IF ~textLength.ok THEN Fail ELSE
    LET textData == ReadBytes(textLength.rest, textLength.value) IN IF ~textData.ok THEN Fail ELSE
    Ok([ textData |-> textData.value ], textData.rest)

ZeroText ==
    [ textData |-> << >> ]

(* Text at zero, then each field in turn at the values it is checked at *)
CheckedText ==
    { ZeroText }
        \cup { [ZeroText EXCEPT !.textData = one] : one \in SampleBytes }

(***************************************************************************)
(* Url Link                                                                *)
(***************************************************************************)

UrlLink ==
    [ urlLinkData : SampleBytes ]

EncodeUrlLink(message) ==
    EncodeUIntLE(Len(message.urlLinkData), 2)
        \o message.urlLinkData

DecodeUrlLink(bytes) ==
    LET urlLinkLength == ReadUIntLE(bytes, 2) IN IF ~urlLinkLength.ok THEN Fail ELSE
    LET urlLinkData == ReadBytes(urlLinkLength.rest, urlLinkLength.value) IN IF ~urlLinkData.ok THEN Fail ELSE
    Ok([ urlLinkData |-> urlLinkData.value ], urlLinkData.rest)

ZeroUrlLink ==
    [ urlLinkData |-> << >> ]

(* Url Link at zero, then each field in turn at the values it is checked at *)
CheckedUrlLink ==
    { ZeroUrlLink }
        \cup { [ZeroUrlLink EXCEPT !.urlLinkData = one] : one \in SampleBytes }

(***************************************************************************)
(* News 5 Message                                                          *)
(***************************************************************************)

News5Message ==
    [ securityIdOptional  : Sample(8),
      matchEventIndicator : Sample(1),
      newsSource          : Sample(1),
      languageCode        : Sample(2),
      partCount           : Sample(2),
      partNumber          : Sample(2),
      newsId              : Sample(8),
      origTime            : Sample(8),
      totalTextLength     : Sample(4),
      headline            : Headline,
      text                : Text,
      urlLink             : UrlLink ]

EncodeNews5Message(message) ==
    message.securityIdOptional
        \o message.matchEventIndicator
        \o message.newsSource
        \o message.languageCode
        \o message.partCount
        \o message.partNumber
        \o message.newsId
        \o message.origTime
        \o message.totalTextLength
        \o EncodeHeadline(message.headline)
        \o EncodeText(message.text)
        \o EncodeUrlLink(message.urlLink)

DecodeNews5Message(bytes) ==
    LET securityIdOptional == ReadBytes(bytes, 8) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityIdOptional.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET newsSource == ReadBytes(matchEventIndicator.rest, 1) IN IF ~newsSource.ok THEN Fail ELSE
    LET languageCode == ReadBytes(newsSource.rest, 2) IN IF ~languageCode.ok THEN Fail ELSE
    LET partCount == ReadBytes(languageCode.rest, 2) IN IF ~partCount.ok THEN Fail ELSE
    LET partNumber == ReadBytes(partCount.rest, 2) IN IF ~partNumber.ok THEN Fail ELSE
    LET newsId == ReadBytes(partNumber.rest, 8) IN IF ~newsId.ok THEN Fail ELSE
    LET origTime == ReadBytes(newsId.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET totalTextLength == ReadBytes(origTime.rest, 4) IN IF ~totalTextLength.ok THEN Fail ELSE
    LET headline == DecodeHeadline(totalTextLength.rest) IN IF ~headline.ok THEN Fail ELSE
    LET text == DecodeText(headline.rest) IN IF ~text.ok THEN Fail ELSE
    LET urlLink == DecodeUrlLink(text.rest) IN IF ~urlLink.ok THEN Fail ELSE
    Ok([ securityIdOptional  |-> securityIdOptional.value,
         matchEventIndicator |-> matchEventIndicator.value,
         newsSource          |-> newsSource.value,
         languageCode        |-> languageCode.value,
         partCount           |-> partCount.value,
         partNumber          |-> partNumber.value,
         newsId              |-> newsId.value,
         origTime            |-> origTime.value,
         totalTextLength     |-> totalTextLength.value,
         headline            |-> headline.value,
         text                |-> text.value,
         urlLink             |-> urlLink.value ], urlLink.rest)

ZeroNews5Message ==
    [ securityIdOptional  |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      newsSource          |-> [i \in 1 .. 1 |-> 0],
      languageCode        |-> [i \in 1 .. 2 |-> 0],
      partCount           |-> [i \in 1 .. 2 |-> 0],
      partNumber          |-> [i \in 1 .. 2 |-> 0],
      newsId              |-> [i \in 1 .. 8 |-> 0],
      origTime            |-> [i \in 1 .. 8 |-> 0],
      totalTextLength     |-> [i \in 1 .. 4 |-> 0],
      headline            |-> ZeroHeadline,
      text                |-> ZeroText,
      urlLink             |-> ZeroUrlLink ]

(* News 5 Message at zero, then each field in turn at the values it is checked at *)
CheckedNews5Message ==
    { ZeroNews5Message }
        \cup { [ZeroNews5Message EXCEPT !.securityIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroNews5Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNews5Message EXCEPT !.newsSource = one] : one \in Sample(1) }
        \cup { [ZeroNews5Message EXCEPT !.languageCode = one] : one \in Sample(2) }
        \cup { [ZeroNews5Message EXCEPT !.partCount = one] : one \in Sample(2) }
        \cup { [ZeroNews5Message EXCEPT !.partNumber = one] : one \in Sample(2) }
        \cup { [ZeroNews5Message EXCEPT !.newsId = one] : one \in Sample(8) }
        \cup { [ZeroNews5Message EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroNews5Message EXCEPT !.totalTextLength = one] : one \in Sample(4) }
        \cup { [ZeroNews5Message EXCEPT !.headline = one] : one \in CheckedHeadline }
        \cup { [ZeroNews5Message EXCEPT !.text = one] : one \in CheckedText }
        \cup { [ZeroNews5Message EXCEPT !.urlLink = one] : one \in CheckedUrlLink }

(***************************************************************************)
(* Empty Book Message: 20 bytes                                            *)
(***************************************************************************)

EmptyBookMessage ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      offset9Padding3     : Sample(3),
      mdEntryTimestamp    : Sample(8) ]

EncodeEmptyBookMessage(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding3
        \o message.mdEntryTimestamp

DecodeEmptyBookMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding3 == ReadBytes(matchEventIndicator.rest, 3) IN IF ~offset9Padding3.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(offset9Padding3.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         offset9Padding3     |-> offset9Padding3.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value ], mdEntryTimestamp.rest)

ZeroEmptyBookMessage ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      offset9Padding3     |-> [i \in 1 .. 3 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0] ]

(* Empty Book Message at zero, then each field in turn at the values it is checked at *)
CheckedEmptyBookMessage ==
    { ZeroEmptyBookMessage }
        \cup { [ZeroEmptyBookMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroEmptyBookMessage EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEmptyBookMessage EXCEPT !.offset9Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroEmptyBookMessage EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Channel Reset 11 Message: 12 bytes                                      *)
(***************************************************************************)

ChannelReset11Message ==
    [ matchEventIndicator : Sample(1),
      offset1Padding3     : Sample(3),
      mdEntryTimestamp    : Sample(8) ]

EncodeChannelReset11Message(message) ==
    message.matchEventIndicator
        \o message.offset1Padding3
        \o message.mdEntryTimestamp

DecodeChannelReset11Message(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset1Padding3 == ReadBytes(matchEventIndicator.rest, 3) IN IF ~offset1Padding3.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(offset1Padding3.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    Ok([ matchEventIndicator |-> matchEventIndicator.value,
         offset1Padding3     |-> offset1Padding3.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value ], mdEntryTimestamp.rest)

ZeroChannelReset11Message ==
    [ matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      offset1Padding3     |-> [i \in 1 .. 3 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0] ]

(* Channel Reset 11 Message at zero, then each field in turn at the values it is checked at *)
CheckedChannelReset11Message ==
    { ZeroChannelReset11Message }
        \cup { [ZeroChannelReset11Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroChannelReset11Message EXCEPT !.offset1Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroChannelReset11Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Opening Price 15 Message: 44 bytes                                      *)
(***************************************************************************)

OpeningPrice15Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      mdUpdateAction      : Sample(1),
      openCloseSettlFlag  : Sample(1),
      offset11Padding1    : Sample(1),
      mdFuturePrice       : Sample(8),
      netChgPrevDay       : Sample(8),
      tradeDate           : Sample(2),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4),
      padding2            : Sample(2) ]

EncodeOpeningPrice15Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.openCloseSettlFlag
        \o message.offset11Padding1
        \o message.mdFuturePrice
        \o message.netChgPrevDay
        \o message.tradeDate
        \o message.mdEntryTimestamp
        \o message.rptSeq
        \o message.padding2

DecodeOpeningPrice15Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdUpdateAction.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(offset11Padding1.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET netChgPrevDay == ReadBytes(mdFuturePrice.rest, 8) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(netChgPrevDay.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(tradeDate.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET padding2 == ReadBytes(rptSeq.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         openCloseSettlFlag  |-> openCloseSettlFlag.value,
         offset11Padding1    |-> offset11Padding1.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         netChgPrevDay       |-> netChgPrevDay.value,
         tradeDate           |-> tradeDate.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value,
         padding2            |-> padding2.value ], padding2.rest)

ZeroOpeningPrice15Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      openCloseSettlFlag  |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1    |-> [i \in 1 .. 1 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDay       |-> [i \in 1 .. 8 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      padding2            |-> [i \in 1 .. 2 |-> 0] ]

(* Opening Price 15 Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningPrice15Message ==
    { ZeroOpeningPrice15Message }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.offset11Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.netChgPrevDay = one] : one \in Sample(8) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOpeningPrice15Message EXCEPT !.padding2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Theoretical Opening Price 16 Message: 40 bytes                          *)
(***************************************************************************)

TheoreticalOpeningPrice16Message ==
    [ securityId                     : Sample(8),
      matchEventIndicator            : Sample(1),
      mdUpdateAction                 : Sample(1),
      tradeDate                      : Sample(2),
      mdCorporateOffsetPriceOptional : Sample(8),
      mdEntrySizeQuantityOptional    : Sample(8),
      mdEntryTimestamp               : Sample(8),
      rptSeq                         : Sample(4) ]

EncodeTheoreticalOpeningPrice16Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.tradeDate
        \o message.mdCorporateOffsetPriceOptional
        \o message.mdEntrySizeQuantityOptional
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeTheoreticalOpeningPrice16Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdUpdateAction.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdCorporateOffsetPriceOptional == ReadBytes(tradeDate.rest, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    LET mdEntrySizeQuantityOptional == ReadBytes(mdCorporateOffsetPriceOptional.rest, 8) IN IF ~mdEntrySizeQuantityOptional.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdEntrySizeQuantityOptional.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId                     |-> securityId.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         mdUpdateAction                 |-> mdUpdateAction.value,
         tradeDate                      |-> tradeDate.value,
         mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value,
         mdEntrySizeQuantityOptional    |-> mdEntrySizeQuantityOptional.value,
         mdEntryTimestamp               |-> mdEntryTimestamp.value,
         rptSeq                         |-> rptSeq.value ], rptSeq.rest)

ZeroTheoreticalOpeningPrice16Message ==
    [ securityId                     |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction                 |-> [i \in 1 .. 1 |-> 0],
      tradeDate                      |-> [i \in 1 .. 2 |-> 0],
      mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantityOptional    |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp               |-> [i \in 1 .. 8 |-> 0],
      rptSeq                         |-> [i \in 1 .. 4 |-> 0] ]

(* Theoretical Opening Price 16 Message at zero, then each field in turn at the values it is checked at *)
CheckedTheoreticalOpeningPrice16Message ==
    { ZeroTheoreticalOpeningPrice16Message }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.mdCorporateOffsetPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.mdEntrySizeQuantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTheoreticalOpeningPrice16Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Closing Price 17 Message: 36 bytes                                      *)
(***************************************************************************)

ClosingPrice17Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      openCloseSettlFlag  : Sample(1),
      offset10Padding2    : Sample(2),
      mdCorporatePrice    : Sample(8),
      lastTradeDate       : Sample(2),
      tradeDate           : Sample(2),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeClosingPrice17Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.openCloseSettlFlag
        \o message.offset10Padding2
        \o message.mdCorporatePrice
        \o message.lastTradeDate
        \o message.tradeDate
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeClosingPrice17Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(matchEventIndicator.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET offset10Padding2 == ReadBytes(openCloseSettlFlag.rest, 2) IN IF ~offset10Padding2.ok THEN Fail ELSE
    LET mdCorporatePrice == ReadBytes(offset10Padding2.rest, 8) IN IF ~mdCorporatePrice.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(mdCorporatePrice.rest, 2) IN IF ~lastTradeDate.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(lastTradeDate.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(tradeDate.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         openCloseSettlFlag  |-> openCloseSettlFlag.value,
         offset10Padding2    |-> offset10Padding2.value,
         mdCorporatePrice    |-> mdCorporatePrice.value,
         lastTradeDate       |-> lastTradeDate.value,
         tradeDate           |-> tradeDate.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroClosingPrice17Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      openCloseSettlFlag  |-> [i \in 1 .. 1 |-> 0],
      offset10Padding2    |-> [i \in 1 .. 2 |-> 0],
      mdCorporatePrice    |-> [i \in 1 .. 8 |-> 0],
      lastTradeDate       |-> [i \in 1 .. 2 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Closing Price 17 Message at zero, then each field in turn at the values it is checked at *)
CheckedClosingPrice17Message ==
    { ZeroClosingPrice17Message }
        \cup { [ZeroClosingPrice17Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.offset10Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.mdCorporatePrice = one] : one \in Sample(8) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.lastTradeDate = one] : one \in Sample(2) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClosingPrice17Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Auction Imbalance 19 Message: 32 bytes                                  *)
(***************************************************************************)

AuctionImbalance19Message ==
    [ securityId                  : Sample(8),
      matchEventIndicator         : Sample(1),
      mdUpdateAction              : Sample(1),
      imbalanceCondition          : Sample(2),
      mdEntrySizeQuantityOptional : Sample(8),
      mdEntryTimestamp            : Sample(8),
      rptSeq                      : Sample(4) ]

EncodeAuctionImbalance19Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.imbalanceCondition
        \o message.mdEntrySizeQuantityOptional
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeAuctionImbalance19Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET imbalanceCondition == ReadBytes(mdUpdateAction.rest, 2) IN IF ~imbalanceCondition.ok THEN Fail ELSE
    LET mdEntrySizeQuantityOptional == ReadBytes(imbalanceCondition.rest, 8) IN IF ~mdEntrySizeQuantityOptional.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdEntrySizeQuantityOptional.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId                  |-> securityId.value,
         matchEventIndicator         |-> matchEventIndicator.value,
         mdUpdateAction              |-> mdUpdateAction.value,
         imbalanceCondition          |-> imbalanceCondition.value,
         mdEntrySizeQuantityOptional |-> mdEntrySizeQuantityOptional.value,
         mdEntryTimestamp            |-> mdEntryTimestamp.value,
         rptSeq                      |-> rptSeq.value ], rptSeq.rest)

ZeroAuctionImbalance19Message ==
    [ securityId                  |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction              |-> [i \in 1 .. 1 |-> 0],
      imbalanceCondition          |-> [i \in 1 .. 2 |-> 0],
      mdEntrySizeQuantityOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp            |-> [i \in 1 .. 8 |-> 0],
      rptSeq                      |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Imbalance 19 Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionImbalance19Message ==
    { ZeroAuctionImbalance19Message }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.imbalanceCondition = one] : one \in Sample(2) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.mdEntrySizeQuantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionImbalance19Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Band 20 Message: 48 bytes                                         *)
(***************************************************************************)

PriceBand20Message ==
    [ securityId                 : Sample(8),
      matchEventIndicator        : Sample(1),
      priceBandType              : Sample(1),
      priceLimitType             : Sample(1),
      priceBandMidpointPriceType : Sample(1),
      lowLimitPrice              : Sample(8),
      highLimitPrice             : Sample(8),
      tradingReferencePrice      : Sample(8),
      mdEntryTimestamp           : Sample(8),
      rptSeq                     : Sample(4) ]

EncodePriceBand20Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.priceBandType
        \o message.priceLimitType
        \o message.priceBandMidpointPriceType
        \o message.lowLimitPrice
        \o message.highLimitPrice
        \o message.tradingReferencePrice
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodePriceBand20Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET priceBandType == ReadBytes(matchEventIndicator.rest, 1) IN IF ~priceBandType.ok THEN Fail ELSE
    LET priceLimitType == ReadBytes(priceBandType.rest, 1) IN IF ~priceLimitType.ok THEN Fail ELSE
    LET priceBandMidpointPriceType == ReadBytes(priceLimitType.rest, 1) IN IF ~priceBandMidpointPriceType.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(priceBandMidpointPriceType.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(lowLimitPrice.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(tradingReferencePrice.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId                 |-> securityId.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         priceBandType              |-> priceBandType.value,
         priceLimitType             |-> priceLimitType.value,
         priceBandMidpointPriceType |-> priceBandMidpointPriceType.value,
         lowLimitPrice              |-> lowLimitPrice.value,
         highLimitPrice             |-> highLimitPrice.value,
         tradingReferencePrice      |-> tradingReferencePrice.value,
         mdEntryTimestamp           |-> mdEntryTimestamp.value,
         rptSeq                     |-> rptSeq.value ], rptSeq.rest)

ZeroPriceBand20Message ==
    [ securityId                 |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      priceBandType              |-> [i \in 1 .. 1 |-> 0],
      priceLimitType             |-> [i \in 1 .. 1 |-> 0],
      priceBandMidpointPriceType |-> [i \in 1 .. 1 |-> 0],
      lowLimitPrice              |-> [i \in 1 .. 8 |-> 0],
      highLimitPrice             |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice      |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp           |-> [i \in 1 .. 8 |-> 0],
      rptSeq                     |-> [i \in 1 .. 4 |-> 0] ]

(* Price Band 20 Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceBand20Message ==
    { ZeroPriceBand20Message }
        \cup { [ZeroPriceBand20Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand20Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand20Message EXCEPT !.priceBandType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand20Message EXCEPT !.priceLimitType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand20Message EXCEPT !.priceBandMidpointPriceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand20Message EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand20Message EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand20Message EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand20Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand20Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Quantity Band 21 Message: 40 bytes                                      *)
(***************************************************************************)

QuantityBand21Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      offset9Padding3     : Sample(3),
      avgDailyTradedQty   : Sample(8),
      maxTradeVol         : Sample(8),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeQuantityBand21Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding3
        \o message.avgDailyTradedQty
        \o message.maxTradeVol
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeQuantityBand21Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding3 == ReadBytes(matchEventIndicator.rest, 3) IN IF ~offset9Padding3.ok THEN Fail ELSE
    LET avgDailyTradedQty == ReadBytes(offset9Padding3.rest, 8) IN IF ~avgDailyTradedQty.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(avgDailyTradedQty.rest, 8) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(maxTradeVol.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         offset9Padding3     |-> offset9Padding3.value,
         avgDailyTradedQty   |-> avgDailyTradedQty.value,
         maxTradeVol         |-> maxTradeVol.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroQuantityBand21Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      offset9Padding3     |-> [i \in 1 .. 3 |-> 0],
      avgDailyTradedQty   |-> [i \in 1 .. 8 |-> 0],
      maxTradeVol         |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Quantity Band 21 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuantityBand21Message ==
    { ZeroQuantityBand21Message }
        \cup { [ZeroQuantityBand21Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.offset9Padding3 = one] : one \in Sample(3) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.avgDailyTradedQty = one] : one \in Sample(8) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.maxTradeVol = one] : one \in Sample(8) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuantityBand21Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* High Price 24 Message: 32 bytes                                         *)
(***************************************************************************)

HighPrice24Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      mdUpdateAction      : Sample(1),
      tradeDate           : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeHighPrice24Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.tradeDate
        \o message.mdFuturePrice
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeHighPrice24Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdUpdateAction.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeDate.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         tradeDate           |-> tradeDate.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroHighPrice24Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* High Price 24 Message at zero, then each field in turn at the values it is checked at *)
CheckedHighPrice24Message ==
    { ZeroHighPrice24Message }
        \cup { [ZeroHighPrice24Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroHighPrice24Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroHighPrice24Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroHighPrice24Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroHighPrice24Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroHighPrice24Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroHighPrice24Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Low Price 25 Message: 32 bytes                                          *)
(***************************************************************************)

LowPrice25Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      mdUpdateAction      : Sample(1),
      tradeDate           : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeLowPrice25Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.tradeDate
        \o message.mdFuturePrice
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeLowPrice25Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdUpdateAction.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeDate.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         tradeDate           |-> tradeDate.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroLowPrice25Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Low Price 25 Message at zero, then each field in turn at the values it is checked at *)
CheckedLowPrice25Message ==
    { ZeroLowPrice25Message }
        \cup { [ZeroLowPrice25Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroLowPrice25Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLowPrice25Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroLowPrice25Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroLowPrice25Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroLowPrice25Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLowPrice25Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Last Trade Price 27 Message: 68 bytes                                   *)
(***************************************************************************)

LastTradePrice27Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      tradingSessionId    : Sample(1),
      tradeCondition      : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntrySizeQuantity : Sample(8),
      tradeId             : Sample(4),
      mdEntryBuyer        : Sample(4),
      mdEntrySeller       : Sample(4),
      tradeDate           : Sample(2),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4),
      sellerDays          : Sample(2),
      mdEntryInterestRate : Sample(8),
      trdSubType          : Sample(1),
      padding3            : Sample(3) ]

EncodeLastTradePrice27Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.tradeCondition
        \o message.mdFuturePrice
        \o message.mdEntrySizeQuantity
        \o message.tradeId
        \o message.mdEntryBuyer
        \o message.mdEntrySeller
        \o message.tradeDate
        \o message.mdEntryTimestamp
        \o message.rptSeq
        \o message.sellerDays
        \o message.mdEntryInterestRate
        \o message.trdSubType
        \o message.padding3

DecodeLastTradePrice27Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradingSessionId.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeCondition.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET mdEntryBuyer == ReadBytes(tradeId.rest, 4) IN IF ~mdEntryBuyer.ok THEN Fail ELSE
    LET mdEntrySeller == ReadBytes(mdEntryBuyer.rest, 4) IN IF ~mdEntrySeller.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdEntrySeller.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(tradeDate.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET sellerDays == ReadBytes(rptSeq.rest, 2) IN IF ~sellerDays.ok THEN Fail ELSE
    LET mdEntryInterestRate == ReadBytes(sellerDays.rest, 8) IN IF ~mdEntryInterestRate.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(mdEntryInterestRate.rest, 1) IN IF ~trdSubType.ok THEN Fail ELSE
    LET padding3 == ReadBytes(trdSubType.rest, 3) IN IF ~padding3.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradeCondition      |-> tradeCondition.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         tradeId             |-> tradeId.value,
         mdEntryBuyer        |-> mdEntryBuyer.value,
         mdEntrySeller       |-> mdEntrySeller.value,
         tradeDate           |-> tradeDate.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value,
         sellerDays          |-> sellerDays.value,
         mdEntryInterestRate |-> mdEntryInterestRate.value,
         trdSubType          |-> trdSubType.value,
         padding3            |-> padding3.value ], padding3.rest)

ZeroLastTradePrice27Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradeCondition      |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 4 |-> 0],
      mdEntryBuyer        |-> [i \in 1 .. 4 |-> 0],
      mdEntrySeller       |-> [i \in 1 .. 4 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      sellerDays          |-> [i \in 1 .. 2 |-> 0],
      mdEntryInterestRate |-> [i \in 1 .. 8 |-> 0],
      trdSubType          |-> [i \in 1 .. 1 |-> 0],
      padding3            |-> [i \in 1 .. 3 |-> 0] ]

(* Last Trade Price 27 Message at zero, then each field in turn at the values it is checked at *)
CheckedLastTradePrice27Message ==
    { ZeroLastTradePrice27Message }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdEntryBuyer = one] : one \in Sample(4) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdEntrySeller = one] : one \in Sample(4) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.sellerDays = one] : one \in Sample(2) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.mdEntryInterestRate = one] : one \in Sample(8) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.trdSubType = one] : one \in Sample(1) }
        \cup { [ZeroLastTradePrice27Message EXCEPT !.padding3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Snapshot Full Refresh Header 30 Message: 32 bytes                       *)
(***************************************************************************)

SnapshotFullRefreshHeader30Message ==
    [ securityId             : Sample(8),
      lastMsgSeqNumProcessed : Sample(4),
      totNumReports          : Sample(4),
      totNumBids             : Sample(4),
      totNumOffers           : Sample(4),
      totNumStats            : Sample(2),
      offset26Padding2       : Sample(2),
      lastRptSeq             : Sample(4) ]

EncodeSnapshotFullRefreshHeader30Message(message) ==
    message.securityId
        \o message.lastMsgSeqNumProcessed
        \o message.totNumReports
        \o message.totNumBids
        \o message.totNumOffers
        \o message.totNumStats
        \o message.offset26Padding2
        \o message.lastRptSeq

DecodeSnapshotFullRefreshHeader30Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastMsgSeqNumProcessed == ReadBytes(securityId.rest, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET totNumReports == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~totNumReports.ok THEN Fail ELSE
    LET totNumBids == ReadBytes(totNumReports.rest, 4) IN IF ~totNumBids.ok THEN Fail ELSE
    LET totNumOffers == ReadBytes(totNumBids.rest, 4) IN IF ~totNumOffers.ok THEN Fail ELSE
    LET totNumStats == ReadBytes(totNumOffers.rest, 2) IN IF ~totNumStats.ok THEN Fail ELSE
    LET offset26Padding2 == ReadBytes(totNumStats.rest, 2) IN IF ~offset26Padding2.ok THEN Fail ELSE
    LET lastRptSeq == ReadBytes(offset26Padding2.rest, 4) IN IF ~lastRptSeq.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         totNumReports          |-> totNumReports.value,
         totNumBids             |-> totNumBids.value,
         totNumOffers           |-> totNumOffers.value,
         totNumStats            |-> totNumStats.value,
         offset26Padding2       |-> offset26Padding2.value,
         lastRptSeq             |-> lastRptSeq.value ], lastRptSeq.rest)

ZeroSnapshotFullRefreshHeader30Message ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      totNumReports          |-> [i \in 1 .. 4 |-> 0],
      totNumBids             |-> [i \in 1 .. 4 |-> 0],
      totNumOffers           |-> [i \in 1 .. 4 |-> 0],
      totNumStats            |-> [i \in 1 .. 2 |-> 0],
      offset26Padding2       |-> [i \in 1 .. 2 |-> 0],
      lastRptSeq             |-> [i \in 1 .. 4 |-> 0] ]

(* Snapshot Full Refresh Header 30 Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshHeader30Message ==
    { ZeroSnapshotFullRefreshHeader30Message }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.totNumReports = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.totNumBids = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.totNumOffers = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.totNumStats = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.offset26Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.lastRptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mb O 50 Message: 64 bytes                                         *)
(***************************************************************************)

OrderMbO50Message ==
    [ securityId                     : Sample(8),
      matchEventIndicator            : Sample(1),
      mdUpdateAction                 : Sample(1),
      mdEntryType                    : Sample(1),
      offset11Padding1               : Sample(1),
      mdCorporateOffsetPriceOptional : Sample(8),
      mdEntrySizeQuantity            : Sample(8),
      mdEntryPositionNo              : Sample(4),
      enteringFirm                   : Sample(4),
      mdInsertTimestamp              : Sample(8),
      secondaryOrderId               : Sample(8),
      rptSeq                         : Sample(4),
      mdEntryTimestamp               : Sample(8) ]

EncodeOrderMbO50Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.mdEntryType
        \o message.offset11Padding1
        \o message.mdCorporateOffsetPriceOptional
        \o message.mdEntrySizeQuantity
        \o message.mdEntryPositionNo
        \o message.enteringFirm
        \o message.mdInsertTimestamp
        \o message.secondaryOrderId
        \o message.rptSeq
        \o message.mdEntryTimestamp

DecodeOrderMbO50Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(mdEntryType.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET mdCorporateOffsetPriceOptional == ReadBytes(offset11Padding1.rest, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdCorporateOffsetPriceOptional.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(mdEntryPositionNo.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    LET mdInsertTimestamp == ReadBytes(enteringFirm.rest, 8) IN IF ~mdInsertTimestamp.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdInsertTimestamp.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(secondaryOrderId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    Ok([ securityId                     |-> securityId.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         mdUpdateAction                 |-> mdUpdateAction.value,
         mdEntryType                    |-> mdEntryType.value,
         offset11Padding1               |-> offset11Padding1.value,
         mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value,
         mdEntrySizeQuantity            |-> mdEntrySizeQuantity.value,
         mdEntryPositionNo              |-> mdEntryPositionNo.value,
         enteringFirm                   |-> enteringFirm.value,
         mdInsertTimestamp              |-> mdInsertTimestamp.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         rptSeq                         |-> rptSeq.value,
         mdEntryTimestamp               |-> mdEntryTimestamp.value ], mdEntryTimestamp.rest)

ZeroOrderMbO50Message ==
    [ securityId                     |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction                 |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                    |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1               |-> [i \in 1 .. 1 |-> 0],
      mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity            |-> [i \in 1 .. 8 |-> 0],
      mdEntryPositionNo              |-> [i \in 1 .. 4 |-> 0],
      enteringFirm                   |-> [i \in 1 .. 4 |-> 0],
      mdInsertTimestamp              |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      rptSeq                         |-> [i \in 1 .. 4 |-> 0],
      mdEntryTimestamp               |-> [i \in 1 .. 8 |-> 0] ]

(* Order Mb O 50 Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMbO50Message ==
    { ZeroOrderMbO50Message }
        \cup { [ZeroOrderMbO50Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.offset11Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdCorporateOffsetPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.enteringFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdInsertTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Delete Order Mb O 51 Message: 44 bytes                                  *)
(***************************************************************************)

DeleteOrderMbO51Message ==
    [ securityId                  : Sample(8),
      matchEventIndicator         : Sample(1),
      offset9Padding1             : Sample(1),
      mdEntryType                 : Sample(1),
      offset11Padding1            : Sample(1),
      mdEntryPositionNo           : Sample(4),
      mdEntrySizeQuantityOptional : Sample(8),
      secondaryOrderId            : Sample(8),
      mdEntryTimestamp            : Sample(8),
      rptSeq                      : Sample(4) ]

EncodeDeleteOrderMbO51Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding1
        \o message.mdEntryType
        \o message.offset11Padding1
        \o message.mdEntryPositionNo
        \o message.mdEntrySizeQuantityOptional
        \o message.secondaryOrderId
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeDeleteOrderMbO51Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding1 == ReadBytes(matchEventIndicator.rest, 1) IN IF ~offset9Padding1.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(offset9Padding1.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(mdEntryType.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(offset11Padding1.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET mdEntrySizeQuantityOptional == ReadBytes(mdEntryPositionNo.rest, 8) IN IF ~mdEntrySizeQuantityOptional.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdEntrySizeQuantityOptional.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(secondaryOrderId.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId                  |-> securityId.value,
         matchEventIndicator         |-> matchEventIndicator.value,
         offset9Padding1             |-> offset9Padding1.value,
         mdEntryType                 |-> mdEntryType.value,
         offset11Padding1            |-> offset11Padding1.value,
         mdEntryPositionNo           |-> mdEntryPositionNo.value,
         mdEntrySizeQuantityOptional |-> mdEntrySizeQuantityOptional.value,
         secondaryOrderId            |-> secondaryOrderId.value,
         mdEntryTimestamp            |-> mdEntryTimestamp.value,
         rptSeq                      |-> rptSeq.value ], rptSeq.rest)

ZeroDeleteOrderMbO51Message ==
    [ securityId                  |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      offset9Padding1             |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                 |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1            |-> [i \in 1 .. 1 |-> 0],
      mdEntryPositionNo           |-> [i \in 1 .. 4 |-> 0],
      mdEntrySizeQuantityOptional |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId            |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp            |-> [i \in 1 .. 8 |-> 0],
      rptSeq                      |-> [i \in 1 .. 4 |-> 0] ]

(* Delete Order Mb O 51 Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMbO51Message ==
    { ZeroDeleteOrderMbO51Message }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.offset9Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.offset11Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntrySizeQuantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Mass Delete Orders Mb O 52 Message: 28 bytes                            *)
(***************************************************************************)

MassDeleteOrdersMbO52Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      mdUpdateAction      : Sample(1),
      mdEntryType         : Sample(1),
      offset11Padding1    : Sample(1),
      mdEntryPositionNo   : Sample(4),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeMassDeleteOrdersMbO52Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.mdEntryType
        \o message.offset11Padding1
        \o message.mdEntryPositionNo
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeMassDeleteOrdersMbO52Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(mdEntryType.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(offset11Padding1.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdEntryPositionNo.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         mdEntryType         |-> mdEntryType.value,
         offset11Padding1    |-> offset11Padding1.value,
         mdEntryPositionNo   |-> mdEntryPositionNo.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroMassDeleteOrdersMbO52Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType         |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1    |-> [i \in 1 .. 1 |-> 0],
      mdEntryPositionNo   |-> [i \in 1 .. 4 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Delete Orders Mb O 52 Message at zero, then each field in turn at the values it is checked at *)
CheckedMassDeleteOrdersMbO52Message ==
    { ZeroMassDeleteOrdersMbO52Message }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.offset11Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade 53 Message: 56 bytes                                              *)
(***************************************************************************)

Trade53Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      tradingSessionId    : Sample(1),
      tradeCondition      : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntrySizeQuantity : Sample(8),
      tradeId             : Sample(4),
      mdEntryBuyer        : Sample(4),
      mdEntrySeller       : Sample(4),
      tradeDate           : Sample(2),
      trdSubType          : Sample(1),
      offset43Padding1    : Sample(1),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeTrade53Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.tradeCondition
        \o message.mdFuturePrice
        \o message.mdEntrySizeQuantity
        \o message.tradeId
        \o message.mdEntryBuyer
        \o message.mdEntrySeller
        \o message.tradeDate
        \o message.trdSubType
        \o message.offset43Padding1
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeTrade53Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradingSessionId.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeCondition.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET mdEntryBuyer == ReadBytes(tradeId.rest, 4) IN IF ~mdEntryBuyer.ok THEN Fail ELSE
    LET mdEntrySeller == ReadBytes(mdEntryBuyer.rest, 4) IN IF ~mdEntrySeller.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdEntrySeller.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(tradeDate.rest, 1) IN IF ~trdSubType.ok THEN Fail ELSE
    LET offset43Padding1 == ReadBytes(trdSubType.rest, 1) IN IF ~offset43Padding1.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(offset43Padding1.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradeCondition      |-> tradeCondition.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         tradeId             |-> tradeId.value,
         mdEntryBuyer        |-> mdEntryBuyer.value,
         mdEntrySeller       |-> mdEntrySeller.value,
         tradeDate           |-> tradeDate.value,
         trdSubType          |-> trdSubType.value,
         offset43Padding1    |-> offset43Padding1.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroTrade53Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradeCondition      |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 4 |-> 0],
      mdEntryBuyer        |-> [i \in 1 .. 4 |-> 0],
      mdEntrySeller       |-> [i \in 1 .. 4 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      trdSubType          |-> [i \in 1 .. 1 |-> 0],
      offset43Padding1    |-> [i \in 1 .. 1 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Trade 53 Message at zero, then each field in turn at the values it is checked at *)
CheckedTrade53Message ==
    { ZeroTrade53Message }
        \cup { [ZeroTrade53Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTrade53Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade53Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTrade53Message EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroTrade53Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroTrade53Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTrade53Message EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrade53Message EXCEPT !.mdEntryBuyer = one] : one \in Sample(4) }
        \cup { [ZeroTrade53Message EXCEPT !.mdEntrySeller = one] : one \in Sample(4) }
        \cup { [ZeroTrade53Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTrade53Message EXCEPT !.trdSubType = one] : one \in Sample(1) }
        \cup { [ZeroTrade53Message EXCEPT !.offset43Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroTrade53Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTrade53Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Forward Trade 54 Message: 68 bytes                                      *)
(***************************************************************************)

ForwardTrade54Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      tradingSessionId    : Sample(1),
      tradeCondition      : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntrySizeQuantity : Sample(8),
      tradeId             : Sample(4),
      mdEntryBuyer        : Sample(4),
      mdEntrySeller       : Sample(4),
      tradeDate           : Sample(2),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4),
      sellerDays          : Sample(2),
      mdEntryInterestRate : Sample(8),
      trdSubType          : Sample(1),
      padding3            : Sample(3) ]

EncodeForwardTrade54Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.tradeCondition
        \o message.mdFuturePrice
        \o message.mdEntrySizeQuantity
        \o message.tradeId
        \o message.mdEntryBuyer
        \o message.mdEntrySeller
        \o message.tradeDate
        \o message.mdEntryTimestamp
        \o message.rptSeq
        \o message.sellerDays
        \o message.mdEntryInterestRate
        \o message.trdSubType
        \o message.padding3

DecodeForwardTrade54Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradingSessionId.rest, 2) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeCondition.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET mdEntryBuyer == ReadBytes(tradeId.rest, 4) IN IF ~mdEntryBuyer.ok THEN Fail ELSE
    LET mdEntrySeller == ReadBytes(mdEntryBuyer.rest, 4) IN IF ~mdEntrySeller.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(mdEntrySeller.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(tradeDate.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET sellerDays == ReadBytes(rptSeq.rest, 2) IN IF ~sellerDays.ok THEN Fail ELSE
    LET mdEntryInterestRate == ReadBytes(sellerDays.rest, 8) IN IF ~mdEntryInterestRate.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(mdEntryInterestRate.rest, 1) IN IF ~trdSubType.ok THEN Fail ELSE
    LET padding3 == ReadBytes(trdSubType.rest, 3) IN IF ~padding3.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradeCondition      |-> tradeCondition.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         tradeId             |-> tradeId.value,
         mdEntryBuyer        |-> mdEntryBuyer.value,
         mdEntrySeller       |-> mdEntrySeller.value,
         tradeDate           |-> tradeDate.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value,
         sellerDays          |-> sellerDays.value,
         mdEntryInterestRate |-> mdEntryInterestRate.value,
         trdSubType          |-> trdSubType.value,
         padding3            |-> padding3.value ], padding3.rest)

ZeroForwardTrade54Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradeCondition      |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 4 |-> 0],
      mdEntryBuyer        |-> [i \in 1 .. 4 |-> 0],
      mdEntrySeller       |-> [i \in 1 .. 4 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      sellerDays          |-> [i \in 1 .. 2 |-> 0],
      mdEntryInterestRate |-> [i \in 1 .. 8 |-> 0],
      trdSubType          |-> [i \in 1 .. 1 |-> 0],
      padding3            |-> [i \in 1 .. 3 |-> 0] ]

(* Forward Trade 54 Message at zero, then each field in turn at the values it is checked at *)
CheckedForwardTrade54Message ==
    { ZeroForwardTrade54Message }
        \cup { [ZeroForwardTrade54Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.tradeCondition = one] : one \in Sample(2) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdEntryBuyer = one] : one \in Sample(4) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdEntrySeller = one] : one \in Sample(4) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.sellerDays = one] : one \in Sample(2) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.mdEntryInterestRate = one] : one \in Sample(8) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.trdSubType = one] : one \in Sample(1) }
        \cup { [ZeroForwardTrade54Message EXCEPT !.padding3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Execution Summary 55 Message: 64 bytes                                  *)
(***************************************************************************)

ExecutionSummary55Message ==
    [ securityId       : Sample(8),
      offset8Padding2  : Sample(2),
      aggressorSide    : Sample(1),
      offset11Padding1 : Sample(1),
      lastPx           : Sample(8),
      fillQty          : Sample(8),
      tradedHiddenQty  : Sample(8),
      cxlQty           : Sample(8),
      aggressorTime    : Sample(8),
      rptSeq           : Sample(4),
      mdEntryTimestamp : Sample(8) ]

EncodeExecutionSummary55Message(message) ==
    message.securityId
        \o message.offset8Padding2
        \o message.aggressorSide
        \o message.offset11Padding1
        \o message.lastPx
        \o message.fillQty
        \o message.tradedHiddenQty
        \o message.cxlQty
        \o message.aggressorTime
        \o message.rptSeq
        \o message.mdEntryTimestamp

DecodeExecutionSummary55Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET offset8Padding2 == ReadBytes(securityId.rest, 2) IN IF ~offset8Padding2.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(offset8Padding2.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(aggressorSide.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET lastPx == ReadBytes(offset11Padding1.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(lastPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET tradedHiddenQty == ReadBytes(fillQty.rest, 8) IN IF ~tradedHiddenQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(tradedHiddenQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET aggressorTime == ReadBytes(cxlQty.rest, 8) IN IF ~aggressorTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(aggressorTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(rptSeq.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    Ok([ securityId       |-> securityId.value,
         offset8Padding2  |-> offset8Padding2.value,
         aggressorSide    |-> aggressorSide.value,
         offset11Padding1 |-> offset11Padding1.value,
         lastPx           |-> lastPx.value,
         fillQty          |-> fillQty.value,
         tradedHiddenQty  |-> tradedHiddenQty.value,
         cxlQty           |-> cxlQty.value,
         aggressorTime    |-> aggressorTime.value,
         rptSeq           |-> rptSeq.value,
         mdEntryTimestamp |-> mdEntryTimestamp.value ], mdEntryTimestamp.rest)

ZeroExecutionSummary55Message ==
    [ securityId       |-> [i \in 1 .. 8 |-> 0],
      offset8Padding2  |-> [i \in 1 .. 2 |-> 0],
      aggressorSide    |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1 |-> [i \in 1 .. 1 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 8 |-> 0],
      tradedHiddenQty  |-> [i \in 1 .. 8 |-> 0],
      cxlQty           |-> [i \in 1 .. 8 |-> 0],
      aggressorTime    |-> [i \in 1 .. 8 |-> 0],
      rptSeq           |-> [i \in 1 .. 4 |-> 0],
      mdEntryTimestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Summary 55 Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionSummary55Message ==
    { ZeroExecutionSummary55Message }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.offset8Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.offset11Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.tradedHiddenQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.aggressorTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroExecutionSummary55Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Statistics 56 Message: 52 bytes                               *)
(***************************************************************************)

ExecutionStatistics56Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      tradingSessionId    : Sample(1),
      tradeDate           : Sample(2),
      tradeVolume         : Sample(8),
      vwapPx              : Sample(8),
      netChgPrevDay       : Sample(8),
      numberOfTrades      : Sample(4),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeExecutionStatistics56Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.tradeDate
        \o message.tradeVolume
        \o message.vwapPx
        \o message.netChgPrevDay
        \o message.numberOfTrades
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeExecutionStatistics56Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradingSessionId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(tradeDate.rest, 8) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET vwapPx == ReadBytes(tradeVolume.rest, 8) IN IF ~vwapPx.ok THEN Fail ELSE
    LET netChgPrevDay == ReadBytes(vwapPx.rest, 8) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET numberOfTrades == ReadBytes(netChgPrevDay.rest, 4) IN IF ~numberOfTrades.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(numberOfTrades.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradeDate           |-> tradeDate.value,
         tradeVolume         |-> tradeVolume.value,
         vwapPx              |-> vwapPx.value,
         netChgPrevDay       |-> netChgPrevDay.value,
         numberOfTrades      |-> numberOfTrades.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroExecutionStatistics56Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      tradeVolume         |-> [i \in 1 .. 8 |-> 0],
      vwapPx              |-> [i \in 1 .. 8 |-> 0],
      netChgPrevDay       |-> [i \in 1 .. 8 |-> 0],
      numberOfTrades      |-> [i \in 1 .. 4 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Execution Statistics 56 Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionStatistics56Message ==
    { ZeroExecutionStatistics56Message }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.tradeVolume = one] : one \in Sample(8) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.vwapPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.netChgPrevDay = one] : one \in Sample(8) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.numberOfTrades = one] : one \in Sample(4) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutionStatistics56Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Bust 57 Message: 48 bytes                                         *)
(***************************************************************************)

TradeBust57Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      tradingSessionId    : Sample(1),
      offset10Padding2    : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntrySizeQuantity : Sample(8),
      tradeId             : Sample(4),
      tradeDate           : Sample(2),
      offset34Padding2    : Sample(2),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeTradeBust57Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.tradingSessionId
        \o message.offset10Padding2
        \o message.mdFuturePrice
        \o message.mdEntrySizeQuantity
        \o message.tradeId
        \o message.tradeDate
        \o message.offset34Padding2
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeTradeBust57Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(matchEventIndicator.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET offset10Padding2 == ReadBytes(tradingSessionId.rest, 2) IN IF ~offset10Padding2.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(offset10Padding2.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeId.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET offset34Padding2 == ReadBytes(tradeDate.rest, 2) IN IF ~offset34Padding2.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(offset34Padding2.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         offset10Padding2    |-> offset10Padding2.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         tradeId             |-> tradeId.value,
         tradeDate           |-> tradeDate.value,
         offset34Padding2    |-> offset34Padding2.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroTradeBust57Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 1 |-> 0],
      offset10Padding2    |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity |-> [i \in 1 .. 8 |-> 0],
      tradeId             |-> [i \in 1 .. 4 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      offset34Padding2    |-> [i \in 1 .. 2 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust 57 Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBust57Message ==
    { ZeroTradeBust57Message }
        \cup { [ZeroTradeBust57Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBust57Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeBust57Message EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeBust57Message EXCEPT !.offset10Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBust57Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBust57Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeBust57Message EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBust57Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeBust57Message EXCEPT !.offset34Padding2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBust57Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBust57Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group: 41   *)
(* bytes                                                                   *)
(***************************************************************************)

SnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    [ mdCorporateOffsetPriceOptional : Sample(8),
      mdEntrySizeQuantity            : Sample(8),
      mdEntryPositionNo              : Sample(4),
      enteringFirm                   : Sample(4),
      mdInsertTimestamp              : Sample(8),
      secondaryOrderId               : Sample(8),
      mdEntryType                    : Sample(1) ]

EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(message) ==
    message.mdCorporateOffsetPriceOptional
        \o message.mdEntrySizeQuantity
        \o message.mdEntryPositionNo
        \o message.enteringFirm
        \o message.mdInsertTimestamp
        \o message.secondaryOrderId
        \o message.mdEntryType

DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(bytes) ==
    LET mdCorporateOffsetPriceOptional == ReadBytes(bytes, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdCorporateOffsetPriceOptional.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET mdEntryPositionNo == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~mdEntryPositionNo.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(mdEntryPositionNo.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    LET mdInsertTimestamp == ReadBytes(enteringFirm.rest, 8) IN IF ~mdInsertTimestamp.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdInsertTimestamp.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(secondaryOrderId.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value,
         mdEntrySizeQuantity            |-> mdEntrySizeQuantity.value,
         mdEntryPositionNo              |-> mdEntryPositionNo.value,
         enteringFirm                   |-> enteringFirm.value,
         mdInsertTimestamp              |-> mdInsertTimestamp.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         mdEntryType                    |-> mdEntryType.value ], mdEntryType.rest)

ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    [ mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity            |-> [i \in 1 .. 8 |-> 0],
      mdEntryPositionNo              |-> [i \in 1 .. 4 |-> 0],
      enteringFirm                   |-> [i \in 1 .. 4 |-> 0],
      mdInsertTimestamp              |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      mdEntryType                    |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    { ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdCorporateOffsetPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdEntryPositionNo = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.enteringFirm = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdInsertTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(* A run of Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group, written one after another *)
RECURSIVE EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(_)
EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(Head(messages)) \o EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(Tail(messages))

(* As many Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group as the field that counts them says *)
RECURSIVE ReadSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(_, _)
ReadSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group of each kind, for the lists that carry them *)
OneSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup == { ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup }

(***************************************************************************)
(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Groups      *)
(***************************************************************************)

SnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ==
    [ blockLength                                           : Sample(2),
      snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup : SampleLists(OneSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup) ]

EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup), 1)
        \o EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(message.snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup)

DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup == ReadSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength                                           |-> blockLength.value,
         snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup |-> snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup.value ], snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup.rest)

ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ==
    [ blockLength                                           |-> [i \in 1 .. 2 |-> 0],
      snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup |-> << >> ]

(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ==
    { ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups EXCEPT !.snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup = one] : one \in SampleLists(OneSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup) }

(***************************************************************************)
(* Snapshot Full Refresh Orders Mb O 71 Message                            *)
(***************************************************************************)

SnapshotFullRefreshOrdersMbO71Message ==
    [ securityId                                             : Sample(8),
      snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups : SnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ]

EncodeSnapshotFullRefreshOrdersMbO71Message(message) ==
    message.securityId
        \o EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(message.snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups)

DecodeSnapshotFullRefreshOrdersMbO71Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups == DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(securityId.rest) IN IF ~snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups.ok THEN Fail ELSE
    Ok([ securityId                                             |-> securityId.value,
         snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups |-> snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups.value ], snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups.rest)

ZeroSnapshotFullRefreshOrdersMbO71Message ==
    [ securityId                                             |-> [i \in 1 .. 8 |-> 0],
      snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups |-> ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ]

(* Snapshot Full Refresh Orders Mb O 71 Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrdersMbO71Message ==
    { ZeroSnapshotFullRefreshOrdersMbO71Message }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71Message EXCEPT !.snapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups = one] : one \in CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

SequenceResetMessageCode == 1  \* 0x01
SequenceMessageCode == 2  \* 0x02
SecurityStatus3MessageCode == 3  \* 0x03
SecurityGroupPhase10MessageCode == 10  \* 0x0a
DeprecatedSecurityDefinitionMessageCode == 4  \* 0x04
News5MessageCode == 5  \* 0x05
EmptyBookMessageCode == 9  \* 0x09
ChannelReset11MessageCode == 11  \* 0x0b
OpeningPrice15MessageCode == 15  \* 0x0f
TheoreticalOpeningPrice16MessageCode == 16  \* 0x10
ClosingPrice17MessageCode == 17  \* 0x11
AuctionImbalance19MessageCode == 19  \* 0x13
PriceBand20MessageCode == 20  \* 0x14
QuantityBand21MessageCode == 21  \* 0x15
HighPrice24MessageCode == 24  \* 0x18
LowPrice25MessageCode == 25  \* 0x19
LastTradePrice27MessageCode == 27  \* 0x1b
SnapshotFullRefreshHeader30MessageCode == 30  \* 0x1e
OrderMbO50MessageCode == 50  \* 0x32
DeleteOrderMbO51MessageCode == 51  \* 0x33
MassDeleteOrdersMbO52MessageCode == 52  \* 0x34
Trade53MessageCode == 53  \* 0x35
ForwardTrade54MessageCode == 54  \* 0x36
ExecutionSummary55MessageCode == 55  \* 0x37
ExecutionStatistics56MessageCode == 56  \* 0x38
TradeBust57MessageCode == 57  \* 0x39
SnapshotFullRefreshOrdersMbO71MessageCode == 71  \* 0x47

Payload ==
    [ tag : {SequenceResetMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceMessageCode}, body : SequenceMessage ]
        \cup [ tag : {SecurityStatus3MessageCode}, body : SecurityStatus3Message ]
        \cup [ tag : {SecurityGroupPhase10MessageCode}, body : SecurityGroupPhase10Message ]
        \cup [ tag : {DeprecatedSecurityDefinitionMessageCode}, body : DeprecatedSecurityDefinitionMessage ]
        \cup [ tag : {News5MessageCode}, body : News5Message ]
        \cup [ tag : {EmptyBookMessageCode}, body : EmptyBookMessage ]
        \cup [ tag : {ChannelReset11MessageCode}, body : ChannelReset11Message ]
        \cup [ tag : {OpeningPrice15MessageCode}, body : OpeningPrice15Message ]
        \cup [ tag : {TheoreticalOpeningPrice16MessageCode}, body : TheoreticalOpeningPrice16Message ]
        \cup [ tag : {ClosingPrice17MessageCode}, body : ClosingPrice17Message ]
        \cup [ tag : {AuctionImbalance19MessageCode}, body : AuctionImbalance19Message ]
        \cup [ tag : {PriceBand20MessageCode}, body : PriceBand20Message ]
        \cup [ tag : {QuantityBand21MessageCode}, body : QuantityBand21Message ]
        \cup [ tag : {HighPrice24MessageCode}, body : HighPrice24Message ]
        \cup [ tag : {LowPrice25MessageCode}, body : LowPrice25Message ]
        \cup [ tag : {LastTradePrice27MessageCode}, body : LastTradePrice27Message ]
        \cup [ tag : {SnapshotFullRefreshHeader30MessageCode}, body : SnapshotFullRefreshHeader30Message ]
        \cup [ tag : {OrderMbO50MessageCode}, body : OrderMbO50Message ]
        \cup [ tag : {DeleteOrderMbO51MessageCode}, body : DeleteOrderMbO51Message ]
        \cup [ tag : {MassDeleteOrdersMbO52MessageCode}, body : MassDeleteOrdersMbO52Message ]
        \cup [ tag : {Trade53MessageCode}, body : Trade53Message ]
        \cup [ tag : {ForwardTrade54MessageCode}, body : ForwardTrade54Message ]
        \cup [ tag : {ExecutionSummary55MessageCode}, body : ExecutionSummary55Message ]
        \cup [ tag : {ExecutionStatistics56MessageCode}, body : ExecutionStatistics56Message ]
        \cup [ tag : {TradeBust57MessageCode}, body : TradeBust57Message ]
        \cup [ tag : {SnapshotFullRefreshOrdersMbO71MessageCode}, body : SnapshotFullRefreshOrdersMbO71Message ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> << >>
      [] message.tag = SequenceMessageCode -> EncodeSequenceMessage(message.body)
      [] message.tag = SecurityStatus3MessageCode -> EncodeSecurityStatus3Message(message.body)
      [] message.tag = SecurityGroupPhase10MessageCode -> EncodeSecurityGroupPhase10Message(message.body)
      [] message.tag = DeprecatedSecurityDefinitionMessageCode -> EncodeDeprecatedSecurityDefinitionMessage(message.body)
      [] message.tag = News5MessageCode -> EncodeNews5Message(message.body)
      [] message.tag = EmptyBookMessageCode -> EncodeEmptyBookMessage(message.body)
      [] message.tag = ChannelReset11MessageCode -> EncodeChannelReset11Message(message.body)
      [] message.tag = OpeningPrice15MessageCode -> EncodeOpeningPrice15Message(message.body)
      [] message.tag = TheoreticalOpeningPrice16MessageCode -> EncodeTheoreticalOpeningPrice16Message(message.body)
      [] message.tag = ClosingPrice17MessageCode -> EncodeClosingPrice17Message(message.body)
      [] message.tag = AuctionImbalance19MessageCode -> EncodeAuctionImbalance19Message(message.body)
      [] message.tag = PriceBand20MessageCode -> EncodePriceBand20Message(message.body)
      [] message.tag = QuantityBand21MessageCode -> EncodeQuantityBand21Message(message.body)
      [] message.tag = HighPrice24MessageCode -> EncodeHighPrice24Message(message.body)
      [] message.tag = LowPrice25MessageCode -> EncodeLowPrice25Message(message.body)
      [] message.tag = LastTradePrice27MessageCode -> EncodeLastTradePrice27Message(message.body)
      [] message.tag = SnapshotFullRefreshHeader30MessageCode -> EncodeSnapshotFullRefreshHeader30Message(message.body)
      [] message.tag = OrderMbO50MessageCode -> EncodeOrderMbO50Message(message.body)
      [] message.tag = DeleteOrderMbO51MessageCode -> EncodeDeleteOrderMbO51Message(message.body)
      [] message.tag = MassDeleteOrdersMbO52MessageCode -> EncodeMassDeleteOrdersMbO52Message(message.body)
      [] message.tag = Trade53MessageCode -> EncodeTrade53Message(message.body)
      [] message.tag = ForwardTrade54MessageCode -> EncodeForwardTrade54Message(message.body)
      [] message.tag = ExecutionSummary55MessageCode -> EncodeExecutionSummary55Message(message.body)
      [] message.tag = ExecutionStatistics56MessageCode -> EncodeExecutionStatistics56Message(message.body)
      [] message.tag = TradeBust57MessageCode -> EncodeTradeBust57Message(message.body)
      [] message.tag = SnapshotFullRefreshOrdersMbO71MessageCode -> EncodeSnapshotFullRefreshOrdersMbO71Message(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceMessageCode -> DecodeSequenceMessage(bytes)
              [] tag = SecurityStatus3MessageCode -> DecodeSecurityStatus3Message(bytes)
              [] tag = SecurityGroupPhase10MessageCode -> DecodeSecurityGroupPhase10Message(bytes)
              [] tag = DeprecatedSecurityDefinitionMessageCode -> DecodeDeprecatedSecurityDefinitionMessage(bytes)
              [] tag = News5MessageCode -> DecodeNews5Message(bytes)
              [] tag = EmptyBookMessageCode -> DecodeEmptyBookMessage(bytes)
              [] tag = ChannelReset11MessageCode -> DecodeChannelReset11Message(bytes)
              [] tag = OpeningPrice15MessageCode -> DecodeOpeningPrice15Message(bytes)
              [] tag = TheoreticalOpeningPrice16MessageCode -> DecodeTheoreticalOpeningPrice16Message(bytes)
              [] tag = ClosingPrice17MessageCode -> DecodeClosingPrice17Message(bytes)
              [] tag = AuctionImbalance19MessageCode -> DecodeAuctionImbalance19Message(bytes)
              [] tag = PriceBand20MessageCode -> DecodePriceBand20Message(bytes)
              [] tag = QuantityBand21MessageCode -> DecodeQuantityBand21Message(bytes)
              [] tag = HighPrice24MessageCode -> DecodeHighPrice24Message(bytes)
              [] tag = LowPrice25MessageCode -> DecodeLowPrice25Message(bytes)
              [] tag = LastTradePrice27MessageCode -> DecodeLastTradePrice27Message(bytes)
              [] tag = SnapshotFullRefreshHeader30MessageCode -> DecodeSnapshotFullRefreshHeader30Message(bytes)
              [] tag = OrderMbO50MessageCode -> DecodeOrderMbO50Message(bytes)
              [] tag = DeleteOrderMbO51MessageCode -> DecodeDeleteOrderMbO51Message(bytes)
              [] tag = MassDeleteOrdersMbO52MessageCode -> DecodeMassDeleteOrdersMbO52Message(bytes)
              [] tag = Trade53MessageCode -> DecodeTrade53Message(bytes)
              [] tag = ForwardTrade54MessageCode -> DecodeForwardTrade54Message(bytes)
              [] tag = ExecutionSummary55MessageCode -> DecodeExecutionSummary55Message(bytes)
              [] tag = ExecutionStatistics56MessageCode -> DecodeExecutionStatistics56Message(bytes)
              [] tag = TradeBust57MessageCode -> DecodeTradeBust57Message(bytes)
              [] tag = SnapshotFullRefreshOrdersMbO71MessageCode -> DecodeSnapshotFullRefreshOrdersMbO71Message(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceMessageCode, body |-> one] : one \in CheckedSequenceMessage }
        \cup { [tag |-> SecurityStatus3MessageCode, body |-> one] : one \in CheckedSecurityStatus3Message }
        \cup { [tag |-> SecurityGroupPhase10MessageCode, body |-> one] : one \in CheckedSecurityGroupPhase10Message }
        \cup { [tag |-> DeprecatedSecurityDefinitionMessageCode, body |-> one] : one \in CheckedDeprecatedSecurityDefinitionMessage }
        \cup { [tag |-> News5MessageCode, body |-> one] : one \in CheckedNews5Message }
        \cup { [tag |-> EmptyBookMessageCode, body |-> one] : one \in CheckedEmptyBookMessage }
        \cup { [tag |-> ChannelReset11MessageCode, body |-> one] : one \in CheckedChannelReset11Message }
        \cup { [tag |-> OpeningPrice15MessageCode, body |-> one] : one \in CheckedOpeningPrice15Message }
        \cup { [tag |-> TheoreticalOpeningPrice16MessageCode, body |-> one] : one \in CheckedTheoreticalOpeningPrice16Message }
        \cup { [tag |-> ClosingPrice17MessageCode, body |-> one] : one \in CheckedClosingPrice17Message }
        \cup { [tag |-> AuctionImbalance19MessageCode, body |-> one] : one \in CheckedAuctionImbalance19Message }
        \cup { [tag |-> PriceBand20MessageCode, body |-> one] : one \in CheckedPriceBand20Message }
        \cup { [tag |-> QuantityBand21MessageCode, body |-> one] : one \in CheckedQuantityBand21Message }
        \cup { [tag |-> HighPrice24MessageCode, body |-> one] : one \in CheckedHighPrice24Message }
        \cup { [tag |-> LowPrice25MessageCode, body |-> one] : one \in CheckedLowPrice25Message }
        \cup { [tag |-> LastTradePrice27MessageCode, body |-> one] : one \in CheckedLastTradePrice27Message }
        \cup { [tag |-> SnapshotFullRefreshHeader30MessageCode, body |-> one] : one \in CheckedSnapshotFullRefreshHeader30Message }
        \cup { [tag |-> OrderMbO50MessageCode, body |-> one] : one \in CheckedOrderMbO50Message }
        \cup { [tag |-> DeleteOrderMbO51MessageCode, body |-> one] : one \in CheckedDeleteOrderMbO51Message }
        \cup { [tag |-> MassDeleteOrdersMbO52MessageCode, body |-> one] : one \in CheckedMassDeleteOrdersMbO52Message }
        \cup { [tag |-> Trade53MessageCode, body |-> one] : one \in CheckedTrade53Message }
        \cup { [tag |-> ForwardTrade54MessageCode, body |-> one] : one \in CheckedForwardTrade54Message }
        \cup { [tag |-> ExecutionSummary55MessageCode, body |-> one] : one \in CheckedExecutionSummary55Message }
        \cup { [tag |-> ExecutionStatistics56MessageCode, body |-> one] : one \in CheckedExecutionStatistics56Message }
        \cup { [tag |-> TradeBust57MessageCode, body |-> one] : one \in CheckedTradeBust57Message }
        \cup { [tag |-> SnapshotFullRefreshOrdersMbO71MessageCode, body |-> one] : one \in CheckedSnapshotFullRefreshOrdersMbO71Message }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ encodingType : Sample(2),
      blockLength  : Sample(2),
      schemaId     : Sample(2),
      version      : Sample(2),
      payload      : Payload ]

EncodeMessageBody(message) ==
    message.encodingType
        \o message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET blockLength == ReadBytes(encodingType.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ encodingType |-> encodingType.value,
         blockLength  |-> blockLength.value,
         schemaId     |-> schemaId.value,
         version      |-> version.value,
         payload      |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ encodingType |-> [i \in 1 .. 2 |-> 0],
      blockLength  |-> [i \in 1 .. 2 |-> 0],
      schemaId     |-> [i \in 1 .. 2 |-> 0],
      version      |-> [i \in 1 .. 2 |-> 0],
      payload      |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.encodingType = one] : one \in Sample(2) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceMessageCode, body |-> ZeroSequenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatus3MessageCode, body |-> ZeroSecurityStatus3Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityGroupPhase10MessageCode, body |-> ZeroSecurityGroupPhase10Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeprecatedSecurityDefinitionMessageCode, body |-> ZeroDeprecatedSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> News5MessageCode, body |-> ZeroNews5Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EmptyBookMessageCode, body |-> ZeroEmptyBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ChannelReset11MessageCode, body |-> ZeroChannelReset11Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpeningPrice15MessageCode, body |-> ZeroOpeningPrice15Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TheoreticalOpeningPrice16MessageCode, body |-> ZeroTheoreticalOpeningPrice16Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClosingPrice17MessageCode, body |-> ZeroClosingPrice17Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionImbalance19MessageCode, body |-> ZeroAuctionImbalance19Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceBand20MessageCode, body |-> ZeroPriceBand20Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuantityBand21MessageCode, body |-> ZeroQuantityBand21Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HighPrice24MessageCode, body |-> ZeroHighPrice24Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LowPrice25MessageCode, body |-> ZeroLowPrice25Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LastTradePrice27MessageCode, body |-> ZeroLastTradePrice27Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotFullRefreshHeader30MessageCode, body |-> ZeroSnapshotFullRefreshHeader30Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMbO50MessageCode, body |-> ZeroOrderMbO50Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeleteOrderMbO51MessageCode, body |-> ZeroDeleteOrderMbO51Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassDeleteOrdersMbO52MessageCode, body |-> ZeroMassDeleteOrdersMbO52Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> Trade53MessageCode, body |-> ZeroTrade53Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ForwardTrade54MessageCode, body |-> ZeroForwardTrade54Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionSummary55MessageCode, body |-> ZeroExecutionSummary55Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionStatistics56MessageCode, body |-> ZeroExecutionStatistics56Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBust57MessageCode, body |-> ZeroTradeBust57Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotFullRefreshOrdersMbO71MessageCode, body |-> ZeroSnapshotFullRefreshOrdersMbO71Message]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetHeader : PacketHeader,
      message      : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodePacketHeader(message.packetHeader)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET packetHeader == DecodePacketHeader(bytes) IN IF ~packetHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(packetHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ packetHeader |-> packetHeader.value,
         message      |-> message.value ], message.rest)

ZeroPacket ==
    [ packetHeader |-> ZeroPacketHeader,
      message      |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetHeader = one] : one \in CheckedPacketHeader }
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

(* Every Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripPacketHeader ==
    \A message \in CheckedPacketHeader :
        LET read == DecodePacketHeader(EncodePacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceMessage ==
    \A message \in CheckedSequenceMessage :
        LET read == DecodeSequenceMessage(EncodeSequenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status 3 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatus3Message ==
    \A message \in CheckedSecurityStatus3Message :
        LET read == DecodeSecurityStatus3Message(EncodeSecurityStatus3Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Group Phase 10 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityGroupPhase10Message ==
    \A message \in CheckedSecurityGroupPhase10Message :
        LET read == DecodeSecurityGroupPhase10Message(EncodeSecurityGroupPhase10Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear ==
    \A message \in CheckedMaturityMonthYear :
        LET read == DecodeMaturityMonthYear(EncodeMaturityMonthYear(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Settl Month decodes back to what was encoded, and leaves nothing over *)
RoundTripContractSettlMonth ==
    \A message \in CheckedContractSettlMonth :
        LET read == DecodeContractSettlMonth(EncodeContractSettlMonth(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedUnderlyingsGroup ==
    \A message \in CheckedDeprecatedUnderlyingsGroup :
        LET read == DecodeDeprecatedUnderlyingsGroup(EncodeDeprecatedUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedUnderlyingsGroups ==
    \A message \in CheckedDeprecatedUnderlyingsGroups :
        LET read == DecodeDeprecatedUnderlyingsGroups(EncodeDeprecatedUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedLegsGroup ==
    \A message \in CheckedDeprecatedLegsGroup :
        LET read == DecodeDeprecatedLegsGroup(EncodeDeprecatedLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedLegsGroups ==
    \A message \in CheckedDeprecatedLegsGroups :
        LET read == DecodeDeprecatedLegsGroups(EncodeDeprecatedLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Instr Attribs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedInstrAttribsGroup ==
    \A message \in CheckedDeprecatedInstrAttribsGroup :
        LET read == DecodeDeprecatedInstrAttribsGroup(EncodeDeprecatedInstrAttribsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Instr Attribs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedInstrAttribsGroups ==
    \A message \in CheckedDeprecatedInstrAttribsGroups :
        LET read == DecodeDeprecatedInstrAttribsGroups(EncodeDeprecatedInstrAttribsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDesc ==
    \A message \in CheckedSecurityDesc :
        LET read == DecodeSecurityDesc(EncodeSecurityDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deprecated Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeprecatedSecurityDefinitionMessage ==
    \A message \in CheckedDeprecatedSecurityDefinitionMessage :
        LET read == DecodeDeprecatedSecurityDefinitionMessage(EncodeDeprecatedSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Headline decodes back to what was encoded, and leaves nothing over *)
RoundTripHeadline ==
    \A message \in CheckedHeadline :
        LET read == DecodeHeadline(EncodeHeadline(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Text decodes back to what was encoded, and leaves nothing over *)
RoundTripText ==
    \A message \in CheckedText :
        LET read == DecodeText(EncodeText(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Url Link decodes back to what was encoded, and leaves nothing over *)
RoundTripUrlLink ==
    \A message \in CheckedUrlLink :
        LET read == DecodeUrlLink(EncodeUrlLink(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News 5 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNews5Message ==
    \A message \in CheckedNews5Message :
        LET read == DecodeNews5Message(EncodeNews5Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Empty Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEmptyBookMessage ==
    \A message \in CheckedEmptyBookMessage :
        LET read == DecodeEmptyBookMessage(EncodeEmptyBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Reset 11 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelReset11Message ==
    \A message \in CheckedChannelReset11Message :
        LET read == DecodeChannelReset11Message(EncodeChannelReset11Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Price 15 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningPrice15Message ==
    \A message \in CheckedOpeningPrice15Message :
        LET read == DecodeOpeningPrice15Message(EncodeOpeningPrice15Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Theoretical Opening Price 16 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTheoreticalOpeningPrice16Message ==
    \A message \in CheckedTheoreticalOpeningPrice16Message :
        LET read == DecodeTheoreticalOpeningPrice16Message(EncodeTheoreticalOpeningPrice16Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Closing Price 17 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClosingPrice17Message ==
    \A message \in CheckedClosingPrice17Message :
        LET read == DecodeClosingPrice17Message(EncodeClosingPrice17Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Imbalance 19 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionImbalance19Message ==
    \A message \in CheckedAuctionImbalance19Message :
        LET read == DecodeAuctionImbalance19Message(EncodeAuctionImbalance19Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Band 20 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceBand20Message ==
    \A message \in CheckedPriceBand20Message :
        LET read == DecodePriceBand20Message(EncodePriceBand20Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quantity Band 21 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantityBand21Message ==
    \A message \in CheckedQuantityBand21Message :
        LET read == DecodeQuantityBand21Message(EncodeQuantityBand21Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every High Price 24 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHighPrice24Message ==
    \A message \in CheckedHighPrice24Message :
        LET read == DecodeHighPrice24Message(EncodeHighPrice24Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Low Price 25 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLowPrice25Message ==
    \A message \in CheckedLowPrice25Message :
        LET read == DecodeLowPrice25Message(EncodeLowPrice25Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Trade Price 27 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastTradePrice27Message ==
    \A message \in CheckedLastTradePrice27Message :
        LET read == DecodeLastTradePrice27Message(EncodeLastTradePrice27Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Header 30 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshHeader30Message ==
    \A message \in CheckedSnapshotFullRefreshHeader30Message :
        LET read == DecodeSnapshotFullRefreshHeader30Message(EncodeSnapshotFullRefreshHeader30Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mb O 50 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMbO50Message ==
    \A message \in CheckedOrderMbO50Message :
        LET read == DecodeOrderMbO50Message(EncodeOrderMbO50Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Mb O 51 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMbO51Message ==
    \A message \in CheckedDeleteOrderMbO51Message :
        LET read == DecodeDeleteOrderMbO51Message(EncodeDeleteOrderMbO51Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Delete Orders Mb O 52 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassDeleteOrdersMbO52Message ==
    \A message \in CheckedMassDeleteOrdersMbO52Message :
        LET read == DecodeMassDeleteOrdersMbO52Message(EncodeMassDeleteOrdersMbO52Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade 53 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTrade53Message ==
    \A message \in CheckedTrade53Message :
        LET read == DecodeTrade53Message(EncodeTrade53Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Forward Trade 54 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripForwardTrade54Message ==
    \A message \in CheckedForwardTrade54Message :
        LET read == DecodeForwardTrade54Message(EncodeForwardTrade54Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Summary 55 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionSummary55Message ==
    \A message \in CheckedExecutionSummary55Message :
        LET read == DecodeExecutionSummary55Message(EncodeExecutionSummary55Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Statistics 56 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionStatistics56Message ==
    \A message \in CheckedExecutionStatistics56Message :
        LET read == DecodeExecutionStatistics56Message(EncodeExecutionStatistics56Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust 57 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBust57Message ==
    \A message \in CheckedTradeBust57Message :
        LET read == DecodeTradeBust57Message(EncodeTradeBust57Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    \A message \in CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup :
        LET read == DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups ==
    \A message \in CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups :
        LET read == DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Orders Mb O 71 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrdersMbO71Message ==
    \A message \in CheckedSnapshotFullRefreshOrdersMbO71Message :
        LET read == DecodeSnapshotFullRefreshOrdersMbO71Message(EncodeSnapshotFullRefreshOrdersMbO71Message(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
