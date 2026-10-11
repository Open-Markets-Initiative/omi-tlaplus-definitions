------------------- MODULE B3Derivatives_BinaryUmdf_v2_2 -------------------
(***************************************************************************)
(* Brasil, Bolsa, Balcão Binary Unified Market Data Feed v2.2              *)
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
(* Underlyings Group: 28 bytes                                             *)
(***************************************************************************)

UnderlyingsGroup ==
    [ underlyingSecurityId : Sample(8),
      underlyingSymbol     : Sample(20) ]

EncodeUnderlyingsGroup(message) ==
    message.underlyingSecurityId
        \o message.underlyingSymbol

DecodeUnderlyingsGroup(bytes) ==
    LET underlyingSecurityId == ReadBytes(bytes, 8) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(underlyingSecurityId.rest, 20) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ underlyingSecurityId |-> underlyingSecurityId.value,
         underlyingSymbol     |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroUnderlyingsGroup ==
    [ underlyingSecurityId |-> [i \in 1 .. 8 |-> 0],
      underlyingSymbol     |-> [i \in 1 .. 20 |-> 0] ]

(* Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingsGroup ==
    { ZeroUnderlyingsGroup }
        \cup { [ZeroUnderlyingsGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(20) }

(* A run of Underlyings Group, written one after another *)
RECURSIVE EncodeUnderlyingsGroupList(_)
EncodeUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingsGroup(Head(messages)) \o EncodeUnderlyingsGroupList(Tail(messages))

(* As many Underlyings Group as the field that counts them says *)
RECURSIVE ReadUnderlyingsGroupList(_, _)
ReadUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlyings Group of each kind, for the lists that carry them *)
OneUnderlyingsGroup == { ZeroUnderlyingsGroup }

(***************************************************************************)
(* Underlyings Groups                                                      *)
(***************************************************************************)

UnderlyingsGroups ==
    [ blockLength      : Sample(2),
      underlyingsGroup : SampleLists(OneUnderlyingsGroup) ]

EncodeUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.underlyingsGroup), 1)
        \o EncodeUnderlyingsGroupList(message.underlyingsGroup)

DecodeUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET underlyingsGroup == ReadUnderlyingsGroupList(numInGroup.rest, numInGroup.value) IN IF ~underlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength      |-> blockLength.value,
         underlyingsGroup |-> underlyingsGroup.value ], underlyingsGroup.rest)

ZeroUnderlyingsGroups ==
    [ blockLength      |-> [i \in 1 .. 2 |-> 0],
      underlyingsGroup |-> << >> ]

(* Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingsGroups ==
    { ZeroUnderlyingsGroups }
        \cup { [ZeroUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingsGroups EXCEPT !.underlyingsGroup = one] : one \in SampleLists(OneUnderlyingsGroup) }

(***************************************************************************)
(* Legs Group: 38 bytes                                                    *)
(***************************************************************************)

LegsGroup ==
    [ legSecurityId   : Sample(8),
      legRatioQty     : Sample(8),
      legSecurityType : Sample(1),
      legSide         : Sample(1),
      legSymbol       : Sample(20) ]

EncodeLegsGroup(message) ==
    message.legSecurityId
        \o message.legRatioQty
        \o message.legSecurityType
        \o message.legSide
        \o message.legSymbol

DecodeLegsGroup(bytes) ==
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

ZeroLegsGroup ==
    [ legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legRatioQty     |-> [i \in 1 .. 8 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legSymbol       |-> [i \in 1 .. 20 |-> 0] ]

(* Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroup ==
    { ZeroLegsGroup }
        \cup { [ZeroLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegsGroup EXCEPT !.legSymbol = one] : one \in Sample(20) }

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
(* Instr Attribs Group: 2 bytes                                            *)
(***************************************************************************)

InstrAttribsGroup ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(1) ]

EncodeInstrAttribsGroup(message) ==
    message.instrAttribType
        \o message.instrAttribValue

DecodeInstrAttribsGroup(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 1) IN IF ~instrAttribValue.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value ], instrAttribValue.rest)

ZeroInstrAttribsGroup ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 1 |-> 0] ]

(* Instr Attribs Group at zero, then each field in turn at the values it is checked at *)
CheckedInstrAttribsGroup ==
    { ZeroInstrAttribsGroup }
        \cup { [ZeroInstrAttribsGroup EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstrAttribsGroup EXCEPT !.instrAttribValue = one] : one \in Sample(1) }

(* A run of Instr Attribs Group, written one after another *)
RECURSIVE EncodeInstrAttribsGroupList(_)
EncodeInstrAttribsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrAttribsGroup(Head(messages)) \o EncodeInstrAttribsGroupList(Tail(messages))

(* As many Instr Attribs Group as the field that counts them says *)
RECURSIVE ReadInstrAttribsGroupList(_, _)
ReadInstrAttribsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrAttribsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrAttribsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instr Attribs Group of each kind, for the lists that carry them *)
OneInstrAttribsGroup == { ZeroInstrAttribsGroup }

(***************************************************************************)
(* Instr Attribs Groups                                                    *)
(***************************************************************************)

InstrAttribsGroups ==
    [ blockLength       : Sample(2),
      instrAttribsGroup : SampleLists(OneInstrAttribsGroup) ]

EncodeInstrAttribsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instrAttribsGroup), 1)
        \o EncodeInstrAttribsGroupList(message.instrAttribsGroup)

DecodeInstrAttribsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instrAttribsGroup == ReadInstrAttribsGroupList(numInGroup.rest, numInGroup.value) IN IF ~instrAttribsGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         instrAttribsGroup |-> instrAttribsGroup.value ], instrAttribsGroup.rest)

ZeroInstrAttribsGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      instrAttribsGroup |-> << >> ]

(* Instr Attribs Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstrAttribsGroups ==
    { ZeroInstrAttribsGroups }
        \cup { [ZeroInstrAttribsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstrAttribsGroups EXCEPT !.instrAttribsGroup = one] : one \in SampleLists(OneInstrAttribsGroup) }

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
(* Security Definition Message                                             *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityId                : Sample(8),
      securityExchange          : Sample(4),
      securityIdSource          : Sample(1),
      securityGroup             : Sample(3),
      symbol                    : Sample(20),
      securityUpdateAction      : Sample(1),
      securityType              : Sample(1),
      securitySubType           : Sample(2),
      totNoRelatedSym           : Sample(4),
      minPriceIncrement         : Sample(8),
      strikePrice               : Sample(8),
      contractMultiplier        : Sample(8),
      priceDivisor              : Sample(8),
      securityValidityTimestamp : Sample(8),
      noSharesIssued            : Sample(8),
      clearingHouseId           : Sample(8),
      minOrderQty               : Sample(8),
      maxOrderQty               : Sample(8),
      minLotSize                : Sample(8),
      minTradeVol               : Sample(8),
      corporateActionEventId    : Sample(4),
      issueDate                 : Sample(4),
      maturityDate              : Sample(4),
      countryOfIssue            : Sample(2),
      startDate                 : Sample(4),
      endDate                   : Sample(4),
      settlType                 : Sample(2),
      settlDate                 : Sample(4),
      datedDate                 : Sample(4),
      isinNumber                : Sample(12),
      asset                     : Sample(6),
      cfiCode                   : Sample(6),
      maturityMonthYear         : MaturityMonthYear,
      contractSettlMonth        : ContractSettlMonth,
      currency                  : Sample(3),
      strikeCurrency            : Sample(3),
      settlCurrency             : Sample(3),
      securityStrategyType      : Sample(3),
      lotType                   : Sample(1),
      tickSizeDenominator       : Sample(1),
      product                   : Sample(1),
      exerciseStyle             : Sample(1),
      putOrCall                 : Sample(1),
      priceTypeOptional         : Sample(1),
      marketSegmentId           : Sample(1),
      governanceIndicator       : Sample(1),
      securityMatchType         : Sample(1),
      lastFragment              : Sample(1),
      multiLegModel             : Sample(1),
      multiLegPriceMethod       : Sample(1),
      minCrossQty               : Sample(8),
      impliedMarketIndicator    : Sample(1),
      optPayoutType             : Sample(1),
      underlyingsGroups         : UnderlyingsGroups,
      legsGroups                : LegsGroups,
      instrAttribsGroups        : InstrAttribsGroups,
      securityDesc              : SecurityDesc ]

EncodeSecurityDefinitionMessage(message) ==
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
        \o message.priceTypeOptional
        \o message.marketSegmentId
        \o message.governanceIndicator
        \o message.securityMatchType
        \o message.lastFragment
        \o message.multiLegModel
        \o message.multiLegPriceMethod
        \o message.minCrossQty
        \o message.impliedMarketIndicator
        \o message.optPayoutType
        \o EncodeUnderlyingsGroups(message.underlyingsGroups)
        \o EncodeLegsGroups(message.legsGroups)
        \o EncodeInstrAttribsGroups(message.instrAttribsGroups)
        \o EncodeSecurityDesc(message.securityDesc)

DecodeSecurityDefinitionMessage(bytes) ==
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
    LET priceTypeOptional == ReadBytes(putOrCall.rest, 1) IN IF ~priceTypeOptional.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(priceTypeOptional.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET governanceIndicator == ReadBytes(marketSegmentId.rest, 1) IN IF ~governanceIndicator.ok THEN Fail ELSE
    LET securityMatchType == ReadBytes(governanceIndicator.rest, 1) IN IF ~securityMatchType.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(securityMatchType.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET multiLegModel == ReadBytes(lastFragment.rest, 1) IN IF ~multiLegModel.ok THEN Fail ELSE
    LET multiLegPriceMethod == ReadBytes(multiLegModel.rest, 1) IN IF ~multiLegPriceMethod.ok THEN Fail ELSE
    LET minCrossQty == ReadBytes(multiLegPriceMethod.rest, 8) IN IF ~minCrossQty.ok THEN Fail ELSE
    LET impliedMarketIndicator == ReadBytes(minCrossQty.rest, 1) IN IF ~impliedMarketIndicator.ok THEN Fail ELSE
    LET optPayoutType == ReadBytes(impliedMarketIndicator.rest, 1) IN IF ~optPayoutType.ok THEN Fail ELSE
    LET underlyingsGroups == DecodeUnderlyingsGroups(optPayoutType.rest) IN IF ~underlyingsGroups.ok THEN Fail ELSE
    LET legsGroups == DecodeLegsGroups(underlyingsGroups.rest) IN IF ~legsGroups.ok THEN Fail ELSE
    LET instrAttribsGroups == DecodeInstrAttribsGroups(legsGroups.rest) IN IF ~instrAttribsGroups.ok THEN Fail ELSE
    LET securityDesc == DecodeSecurityDesc(instrAttribsGroups.rest) IN IF ~securityDesc.ok THEN Fail ELSE
    Ok([ securityId                |-> securityId.value,
         securityExchange          |-> securityExchange.value,
         securityIdSource          |-> securityIdSource.value,
         securityGroup             |-> securityGroup.value,
         symbol                    |-> symbol.value,
         securityUpdateAction      |-> securityUpdateAction.value,
         securityType              |-> securityType.value,
         securitySubType           |-> securitySubType.value,
         totNoRelatedSym           |-> totNoRelatedSym.value,
         minPriceIncrement         |-> minPriceIncrement.value,
         strikePrice               |-> strikePrice.value,
         contractMultiplier        |-> contractMultiplier.value,
         priceDivisor              |-> priceDivisor.value,
         securityValidityTimestamp |-> securityValidityTimestamp.value,
         noSharesIssued            |-> noSharesIssued.value,
         clearingHouseId           |-> clearingHouseId.value,
         minOrderQty               |-> minOrderQty.value,
         maxOrderQty               |-> maxOrderQty.value,
         minLotSize                |-> minLotSize.value,
         minTradeVol               |-> minTradeVol.value,
         corporateActionEventId    |-> corporateActionEventId.value,
         issueDate                 |-> issueDate.value,
         maturityDate              |-> maturityDate.value,
         countryOfIssue            |-> countryOfIssue.value,
         startDate                 |-> startDate.value,
         endDate                   |-> endDate.value,
         settlType                 |-> settlType.value,
         settlDate                 |-> settlDate.value,
         datedDate                 |-> datedDate.value,
         isinNumber                |-> isinNumber.value,
         asset                     |-> asset.value,
         cfiCode                   |-> cfiCode.value,
         maturityMonthYear         |-> maturityMonthYear.value,
         contractSettlMonth        |-> contractSettlMonth.value,
         currency                  |-> currency.value,
         strikeCurrency            |-> strikeCurrency.value,
         settlCurrency             |-> settlCurrency.value,
         securityStrategyType      |-> securityStrategyType.value,
         lotType                   |-> lotType.value,
         tickSizeDenominator       |-> tickSizeDenominator.value,
         product                   |-> product.value,
         exerciseStyle             |-> exerciseStyle.value,
         putOrCall                 |-> putOrCall.value,
         priceTypeOptional         |-> priceTypeOptional.value,
         marketSegmentId           |-> marketSegmentId.value,
         governanceIndicator       |-> governanceIndicator.value,
         securityMatchType         |-> securityMatchType.value,
         lastFragment              |-> lastFragment.value,
         multiLegModel             |-> multiLegModel.value,
         multiLegPriceMethod       |-> multiLegPriceMethod.value,
         minCrossQty               |-> minCrossQty.value,
         impliedMarketIndicator    |-> impliedMarketIndicator.value,
         optPayoutType             |-> optPayoutType.value,
         underlyingsGroups         |-> underlyingsGroups.value,
         legsGroups                |-> legsGroups.value,
         instrAttribsGroups        |-> instrAttribsGroups.value,
         securityDesc              |-> securityDesc.value ], securityDesc.rest)

ZeroSecurityDefinitionMessage ==
    [ securityId                |-> [i \in 1 .. 8 |-> 0],
      securityExchange          |-> [i \in 1 .. 4 |-> 0],
      securityIdSource          |-> [i \in 1 .. 1 |-> 0],
      securityGroup             |-> [i \in 1 .. 3 |-> 0],
      symbol                    |-> [i \in 1 .. 20 |-> 0],
      securityUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      securityType              |-> [i \in 1 .. 1 |-> 0],
      securitySubType           |-> [i \in 1 .. 2 |-> 0],
      totNoRelatedSym           |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrement         |-> [i \in 1 .. 8 |-> 0],
      strikePrice               |-> [i \in 1 .. 8 |-> 0],
      contractMultiplier        |-> [i \in 1 .. 8 |-> 0],
      priceDivisor              |-> [i \in 1 .. 8 |-> 0],
      securityValidityTimestamp |-> [i \in 1 .. 8 |-> 0],
      noSharesIssued            |-> [i \in 1 .. 8 |-> 0],
      clearingHouseId           |-> [i \in 1 .. 8 |-> 0],
      minOrderQty               |-> [i \in 1 .. 8 |-> 0],
      maxOrderQty               |-> [i \in 1 .. 8 |-> 0],
      minLotSize                |-> [i \in 1 .. 8 |-> 0],
      minTradeVol               |-> [i \in 1 .. 8 |-> 0],
      corporateActionEventId    |-> [i \in 1 .. 4 |-> 0],
      issueDate                 |-> [i \in 1 .. 4 |-> 0],
      maturityDate              |-> [i \in 1 .. 4 |-> 0],
      countryOfIssue            |-> [i \in 1 .. 2 |-> 0],
      startDate                 |-> [i \in 1 .. 4 |-> 0],
      endDate                   |-> [i \in 1 .. 4 |-> 0],
      settlType                 |-> [i \in 1 .. 2 |-> 0],
      settlDate                 |-> [i \in 1 .. 4 |-> 0],
      datedDate                 |-> [i \in 1 .. 4 |-> 0],
      isinNumber                |-> [i \in 1 .. 12 |-> 0],
      asset                     |-> [i \in 1 .. 6 |-> 0],
      cfiCode                   |-> [i \in 1 .. 6 |-> 0],
      maturityMonthYear         |-> ZeroMaturityMonthYear,
      contractSettlMonth        |-> ZeroContractSettlMonth,
      currency                  |-> [i \in 1 .. 3 |-> 0],
      strikeCurrency            |-> [i \in 1 .. 3 |-> 0],
      settlCurrency             |-> [i \in 1 .. 3 |-> 0],
      securityStrategyType      |-> [i \in 1 .. 3 |-> 0],
      lotType                   |-> [i \in 1 .. 1 |-> 0],
      tickSizeDenominator       |-> [i \in 1 .. 1 |-> 0],
      product                   |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle             |-> [i \in 1 .. 1 |-> 0],
      putOrCall                 |-> [i \in 1 .. 1 |-> 0],
      priceTypeOptional         |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId           |-> [i \in 1 .. 1 |-> 0],
      governanceIndicator       |-> [i \in 1 .. 1 |-> 0],
      securityMatchType         |-> [i \in 1 .. 1 |-> 0],
      lastFragment              |-> [i \in 1 .. 1 |-> 0],
      multiLegModel             |-> [i \in 1 .. 1 |-> 0],
      multiLegPriceMethod       |-> [i \in 1 .. 1 |-> 0],
      minCrossQty               |-> [i \in 1 .. 8 |-> 0],
      impliedMarketIndicator    |-> [i \in 1 .. 1 |-> 0],
      optPayoutType             |-> [i \in 1 .. 1 |-> 0],
      underlyingsGroups         |-> ZeroUnderlyingsGroups,
      legsGroups                |-> ZeroLegsGroups,
      instrAttribsGroups        |-> ZeroInstrAttribsGroups,
      securityDesc              |-> ZeroSecurityDesc ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityIdSource = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityGroup = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.totNoRelatedSym = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minPriceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.priceDivisor = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityValidityTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.noSharesIssued = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.clearingHouseId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.maxOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minLotSize = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minTradeVol = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.corporateActionEventId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.issueDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.countryOfIssue = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.endDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.datedDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isinNumber = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.contractSettlMonth = one] : one \in CheckedContractSettlMonth }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityStrategyType = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tickSizeDenominator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.product = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.priceTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.governanceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityMatchType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.multiLegModel = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.multiLegPriceMethod = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minCrossQty = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.impliedMarketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.optPayoutType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingsGroups = one] : one \in CheckedUnderlyingsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.legsGroups = one] : one \in CheckedLegsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.instrAttribsGroups = one] : one \in CheckedInstrAttribsGroups }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDesc = one] : one \in CheckedSecurityDesc }

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
(* Price Band 22 Message: 48 bytes                                         *)
(***************************************************************************)

PriceBand22Message ==
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

EncodePriceBand22Message(message) ==
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

DecodePriceBand22Message(bytes) ==
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

ZeroPriceBand22Message ==
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

(* Price Band 22 Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceBand22Message ==
    { ZeroPriceBand22Message }
        \cup { [ZeroPriceBand22Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand22Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand22Message EXCEPT !.priceBandType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand22Message EXCEPT !.priceLimitType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand22Message EXCEPT !.priceBandMidpointPriceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceBand22Message EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand22Message EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand22Message EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand22Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriceBand22Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

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
(* Settlement Price 28 Message: 36 bytes                                   *)
(***************************************************************************)

SettlementPrice28Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      offset9Padding1     : Sample(1),
      tradeDate           : Sample(2),
      mdFuturePrice       : Sample(8),
      mdEntryTimestamp    : Sample(8),
      openCloseSettlFlag  : Sample(1),
      priceType           : Sample(1),
      settlPriceType      : Sample(1),
      rptSeq              : Sample(4),
      padding1            : Sample(1) ]

EncodeSettlementPrice28Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding1
        \o message.tradeDate
        \o message.mdFuturePrice
        \o message.mdEntryTimestamp
        \o message.openCloseSettlFlag
        \o message.priceType
        \o message.settlPriceType
        \o message.rptSeq
        \o message.padding1

DecodeSettlementPrice28Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding1 == ReadBytes(matchEventIndicator.rest, 1) IN IF ~offset9Padding1.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(offset9Padding1.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdFuturePrice == ReadBytes(tradeDate.rest, 8) IN IF ~mdFuturePrice.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdFuturePrice.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdEntryTimestamp.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET priceType == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(priceType.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(settlPriceType.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET padding1 == ReadBytes(rptSeq.rest, 1) IN IF ~padding1.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         offset9Padding1     |-> offset9Padding1.value,
         tradeDate           |-> tradeDate.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         openCloseSettlFlag  |-> openCloseSettlFlag.value,
         priceType           |-> priceType.value,
         settlPriceType      |-> settlPriceType.value,
         rptSeq              |-> rptSeq.value,
         padding1            |-> padding1.value ], padding1.rest)

ZeroSettlementPrice28Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      offset9Padding1     |-> [i \in 1 .. 1 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdFuturePrice       |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      openCloseSettlFlag  |-> [i \in 1 .. 1 |-> 0],
      priceType           |-> [i \in 1 .. 1 |-> 0],
      settlPriceType      |-> [i \in 1 .. 1 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      padding1            |-> [i \in 1 .. 1 |-> 0] ]

(* Settlement Price 28 Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementPrice28Message ==
    { ZeroSettlementPrice28Message }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.offset9Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.mdFuturePrice = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroSettlementPrice28Message EXCEPT !.padding1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Open Interest 29 Message: 32 bytes                                      *)
(***************************************************************************)

OpenInterest29Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      offset9Padding1     : Sample(1),
      tradeDate           : Sample(2),
      mdEntrySizeQuantity : Sample(8),
      mdEntryTimestamp    : Sample(8),
      rptSeq              : Sample(4) ]

EncodeOpenInterest29Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding1
        \o message.tradeDate
        \o message.mdEntrySizeQuantity
        \o message.mdEntryTimestamp
        \o message.rptSeq

DecodeOpenInterest29Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding1 == ReadBytes(matchEventIndicator.rest, 1) IN IF ~offset9Padding1.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(offset9Padding1.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(tradeDate.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET mdEntryTimestamp == ReadBytes(mdEntrySizeQuantity.rest, 8) IN IF ~mdEntryTimestamp.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(mdEntryTimestamp.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         offset9Padding1     |-> offset9Padding1.value,
         tradeDate           |-> tradeDate.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         mdEntryTimestamp    |-> mdEntryTimestamp.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroOpenInterest29Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      offset9Padding1     |-> [i \in 1 .. 1 |-> 0],
      tradeDate           |-> [i \in 1 .. 2 |-> 0],
      mdEntrySizeQuantity |-> [i \in 1 .. 8 |-> 0],
      mdEntryTimestamp    |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest 29 Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterest29Message ==
    { ZeroOpenInterest29Message }
        \cup { [ZeroOpenInterest29Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.offset9Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.mdEntryTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterest29Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Full Refresh Header 30 Message: 34 bytes                       *)
(***************************************************************************)

SnapshotFullRefreshHeader30Message ==
    [ securityId             : Sample(8),
      lastMsgSeqNumProcessed : Sample(4),
      totNumReports          : Sample(4),
      totNumBids             : Sample(4),
      totNumOffers           : Sample(4),
      totNumStats            : Sample(2),
      offset26Padding2       : Sample(2),
      lastRptSeq             : Sample(4),
      lastSequenceVersion    : Sample(2) ]

EncodeSnapshotFullRefreshHeader30Message(message) ==
    message.securityId
        \o message.lastMsgSeqNumProcessed
        \o message.totNumReports
        \o message.totNumBids
        \o message.totNumOffers
        \o message.totNumStats
        \o message.offset26Padding2
        \o message.lastRptSeq
        \o message.lastSequenceVersion

DecodeSnapshotFullRefreshHeader30Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastMsgSeqNumProcessed == ReadBytes(securityId.rest, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET totNumReports == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~totNumReports.ok THEN Fail ELSE
    LET totNumBids == ReadBytes(totNumReports.rest, 4) IN IF ~totNumBids.ok THEN Fail ELSE
    LET totNumOffers == ReadBytes(totNumBids.rest, 4) IN IF ~totNumOffers.ok THEN Fail ELSE
    LET totNumStats == ReadBytes(totNumOffers.rest, 2) IN IF ~totNumStats.ok THEN Fail ELSE
    LET offset26Padding2 == ReadBytes(totNumStats.rest, 2) IN IF ~offset26Padding2.ok THEN Fail ELSE
    LET lastRptSeq == ReadBytes(offset26Padding2.rest, 4) IN IF ~lastRptSeq.ok THEN Fail ELSE
    LET lastSequenceVersion == ReadBytes(lastRptSeq.rest, 2) IN IF ~lastSequenceVersion.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         lastMsgSeqNumProcessed |-> lastMsgSeqNumProcessed.value,
         totNumReports          |-> totNumReports.value,
         totNumBids             |-> totNumBids.value,
         totNumOffers           |-> totNumOffers.value,
         totNumStats            |-> totNumStats.value,
         offset26Padding2       |-> offset26Padding2.value,
         lastRptSeq             |-> lastRptSeq.value,
         lastSequenceVersion    |-> lastSequenceVersion.value ], lastSequenceVersion.rest)

ZeroSnapshotFullRefreshHeader30Message ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      lastMsgSeqNumProcessed |-> [i \in 1 .. 4 |-> 0],
      totNumReports          |-> [i \in 1 .. 4 |-> 0],
      totNumBids             |-> [i \in 1 .. 4 |-> 0],
      totNumOffers           |-> [i \in 1 .. 4 |-> 0],
      totNumStats            |-> [i \in 1 .. 2 |-> 0],
      offset26Padding2       |-> [i \in 1 .. 2 |-> 0],
      lastRptSeq             |-> [i \in 1 .. 4 |-> 0],
      lastSequenceVersion    |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroSnapshotFullRefreshHeader30Message EXCEPT !.lastSequenceVersion = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Mb O 50 Message: 72 bytes                                         *)
(***************************************************************************)

OrderMbO50Message ==
    [ securityId                     : Sample(8),
      matchEventIndicator            : Sample(1),
      mdUpdateAction                 : Sample(1),
      mdEntryType                    : Sample(1),
      offset11Padding1               : Sample(1),
      mdCorporateOffsetPriceOptional : Sample(8),
      mdEntrySizeQuantity            : Sample(8),
      offset28Padding4               : Sample(4),
      enteringFirm                   : Sample(4),
      mdInsertTimestamp              : Sample(8),
      secondaryOrderId               : Sample(8),
      rptSeq                         : Sample(4),
      transactTime                   : Sample(8),
      mdEntryPrevSize                : Sample(8) ]

EncodeOrderMbO50Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.mdEntryType
        \o message.offset11Padding1
        \o message.mdCorporateOffsetPriceOptional
        \o message.mdEntrySizeQuantity
        \o message.offset28Padding4
        \o message.enteringFirm
        \o message.mdInsertTimestamp
        \o message.secondaryOrderId
        \o message.rptSeq
        \o message.transactTime
        \o message.mdEntryPrevSize

DecodeOrderMbO50Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding1 == ReadBytes(mdEntryType.rest, 1) IN IF ~offset11Padding1.ok THEN Fail ELSE
    LET mdCorporateOffsetPriceOptional == ReadBytes(offset11Padding1.rest, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdCorporateOffsetPriceOptional.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET offset28Padding4 == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~offset28Padding4.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(offset28Padding4.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    LET mdInsertTimestamp == ReadBytes(enteringFirm.rest, 8) IN IF ~mdInsertTimestamp.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdInsertTimestamp.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(secondaryOrderId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rptSeq.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mdEntryPrevSize == ReadBytes(transactTime.rest, 8) IN IF ~mdEntryPrevSize.ok THEN Fail ELSE
    Ok([ securityId                     |-> securityId.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         mdUpdateAction                 |-> mdUpdateAction.value,
         mdEntryType                    |-> mdEntryType.value,
         offset11Padding1               |-> offset11Padding1.value,
         mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value,
         mdEntrySizeQuantity            |-> mdEntrySizeQuantity.value,
         offset28Padding4               |-> offset28Padding4.value,
         enteringFirm                   |-> enteringFirm.value,
         mdInsertTimestamp              |-> mdInsertTimestamp.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         rptSeq                         |-> rptSeq.value,
         transactTime                   |-> transactTime.value,
         mdEntryPrevSize                |-> mdEntryPrevSize.value ], mdEntryPrevSize.rest)

ZeroOrderMbO50Message ==
    [ securityId                     |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction                 |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                    |-> [i \in 1 .. 1 |-> 0],
      offset11Padding1               |-> [i \in 1 .. 1 |-> 0],
      mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity            |-> [i \in 1 .. 8 |-> 0],
      offset28Padding4               |-> [i \in 1 .. 4 |-> 0],
      enteringFirm                   |-> [i \in 1 .. 4 |-> 0],
      mdInsertTimestamp              |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      rptSeq                         |-> [i \in 1 .. 4 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      mdEntryPrevSize                |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroOrderMbO50Message EXCEPT !.offset28Padding4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.enteringFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdInsertTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderMbO50Message EXCEPT !.mdEntryPrevSize = one] : one \in Sample(8) }

(***************************************************************************)
(* Delete Order Mb O 51 Message: 52 bytes                                  *)
(***************************************************************************)

DeleteOrderMbO51Message ==
    [ securityId                     : Sample(8),
      matchEventIndicator            : Sample(1),
      offset9Padding1                : Sample(1),
      mdEntryType                    : Sample(1),
      offset11Padding5               : Sample(5),
      mdEntrySizeQuantity            : Sample(8),
      secondaryOrderId               : Sample(8),
      transactTime                   : Sample(8),
      rptSeq                         : Sample(4),
      mdCorporateOffsetPriceOptional : Sample(8) ]

EncodeDeleteOrderMbO51Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.offset9Padding1
        \o message.mdEntryType
        \o message.offset11Padding5
        \o message.mdEntrySizeQuantity
        \o message.secondaryOrderId
        \o message.transactTime
        \o message.rptSeq
        \o message.mdCorporateOffsetPriceOptional

DecodeDeleteOrderMbO51Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET offset9Padding1 == ReadBytes(matchEventIndicator.rest, 1) IN IF ~offset9Padding1.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(offset9Padding1.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding5 == ReadBytes(mdEntryType.rest, 5) IN IF ~offset11Padding5.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(offset11Padding5.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdEntrySizeQuantity.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(secondaryOrderId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdCorporateOffsetPriceOptional == ReadBytes(rptSeq.rest, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    Ok([ securityId                     |-> securityId.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         offset9Padding1                |-> offset9Padding1.value,
         mdEntryType                    |-> mdEntryType.value,
         offset11Padding5               |-> offset11Padding5.value,
         mdEntrySizeQuantity            |-> mdEntrySizeQuantity.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         transactTime                   |-> transactTime.value,
         rptSeq                         |-> rptSeq.value,
         mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value ], mdCorporateOffsetPriceOptional.rest)

ZeroDeleteOrderMbO51Message ==
    [ securityId                     |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      offset9Padding1                |-> [i \in 1 .. 1 |-> 0],
      mdEntryType                    |-> [i \in 1 .. 1 |-> 0],
      offset11Padding5               |-> [i \in 1 .. 5 |-> 0],
      mdEntrySizeQuantity            |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      transactTime                   |-> [i \in 1 .. 8 |-> 0],
      rptSeq                         |-> [i \in 1 .. 4 |-> 0],
      mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Mb O 51 Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMbO51Message ==
    { ZeroDeleteOrderMbO51Message }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.offset9Padding1 = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.offset11Padding5 = one] : one \in Sample(5) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMbO51Message EXCEPT !.mdCorporateOffsetPriceOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Mass Delete Orders Mb O 52 Message: 28 bytes                            *)
(***************************************************************************)

MassDeleteOrdersMbO52Message ==
    [ securityId          : Sample(8),
      matchEventIndicator : Sample(1),
      mdUpdateAction      : Sample(1),
      mdEntryType         : Sample(1),
      offset11Padding5    : Sample(5),
      transactTime        : Sample(8),
      rptSeq              : Sample(4) ]

EncodeMassDeleteOrdersMbO52Message(message) ==
    message.securityId
        \o message.matchEventIndicator
        \o message.mdUpdateAction
        \o message.mdEntryType
        \o message.offset11Padding5
        \o message.transactTime
        \o message.rptSeq

DecodeMassDeleteOrdersMbO52Message(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(matchEventIndicator.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET offset11Padding5 == ReadBytes(mdEntryType.rest, 5) IN IF ~offset11Padding5.ok THEN Fail ELSE
    LET transactTime == ReadBytes(offset11Padding5.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         mdUpdateAction      |-> mdUpdateAction.value,
         mdEntryType         |-> mdEntryType.value,
         offset11Padding5    |-> offset11Padding5.value,
         transactTime        |-> transactTime.value,
         rptSeq              |-> rptSeq.value ], rptSeq.rest)

ZeroMassDeleteOrdersMbO52Message ==
    [ securityId          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction      |-> [i \in 1 .. 1 |-> 0],
      mdEntryType         |-> [i \in 1 .. 1 |-> 0],
      offset11Padding5    |-> [i \in 1 .. 5 |-> 0],
      transactTime        |-> [i \in 1 .. 8 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Delete Orders Mb O 52 Message at zero, then each field in turn at the values it is checked at *)
CheckedMassDeleteOrdersMbO52Message ==
    { ZeroMassDeleteOrdersMbO52Message }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.offset11Padding5 = one] : one \in Sample(5) }
        \cup { [ZeroMassDeleteOrdersMbO52Message EXCEPT !.transactTime = one] : one \in Sample(8) }
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
      transactTime        : Sample(8),
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
        \o message.transactTime
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
    LET transactTime == ReadBytes(offset43Padding1.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
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
         transactTime        |-> transactTime.value,
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
      transactTime        |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroTrade53Message EXCEPT !.transactTime = one] : one \in Sample(8) }
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
      transactTime        : Sample(8),
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
        \o message.transactTime
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
    LET transactTime == ReadBytes(tradeDate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
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
         transactTime        |-> transactTime.value,
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
      transactTime        |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroForwardTrade54Message EXCEPT !.transactTime = one] : one \in Sample(8) }
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
      transactTime     : Sample(8) ]

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
        \o message.transactTime

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
    LET transactTime == ReadBytes(rptSeq.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
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
         transactTime     |-> transactTime.value ], transactTime.rest)

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
      transactTime     |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroExecutionSummary55Message EXCEPT !.transactTime = one] : one \in Sample(8) }

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
      transactTime        : Sample(8),
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
        \o message.transactTime
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
    LET transactTime == ReadBytes(offset34Padding2.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(transactTime.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ securityId          |-> securityId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         tradingSessionId    |-> tradingSessionId.value,
         offset10Padding2    |-> offset10Padding2.value,
         mdFuturePrice       |-> mdFuturePrice.value,
         mdEntrySizeQuantity |-> mdEntrySizeQuantity.value,
         tradeId             |-> tradeId.value,
         tradeDate           |-> tradeDate.value,
         offset34Padding2    |-> offset34Padding2.value,
         transactTime        |-> transactTime.value,
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
      transactTime        |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroTradeBust57Message EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBust57Message EXCEPT !.rptSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group: 42   *)
(* bytes                                                                   *)
(***************************************************************************)

SnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    [ mdCorporateOffsetPriceOptional : Sample(8),
      mdEntrySizeQuantity            : Sample(8),
      offset16Padding4               : Sample(4),
      enteringFirm                   : Sample(4),
      mdInsertTimestamp              : Sample(8),
      secondaryOrderId               : Sample(8),
      mdEntryType                    : Sample(1),
      matchEventIndicator            : Sample(1) ]

EncodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(message) ==
    message.mdCorporateOffsetPriceOptional
        \o message.mdEntrySizeQuantity
        \o message.offset16Padding4
        \o message.enteringFirm
        \o message.mdInsertTimestamp
        \o message.secondaryOrderId
        \o message.mdEntryType
        \o message.matchEventIndicator

DecodeSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup(bytes) ==
    LET mdCorporateOffsetPriceOptional == ReadBytes(bytes, 8) IN IF ~mdCorporateOffsetPriceOptional.ok THEN Fail ELSE
    LET mdEntrySizeQuantity == ReadBytes(mdCorporateOffsetPriceOptional.rest, 8) IN IF ~mdEntrySizeQuantity.ok THEN Fail ELSE
    LET offset16Padding4 == ReadBytes(mdEntrySizeQuantity.rest, 4) IN IF ~offset16Padding4.ok THEN Fail ELSE
    LET enteringFirm == ReadBytes(offset16Padding4.rest, 4) IN IF ~enteringFirm.ok THEN Fail ELSE
    LET mdInsertTimestamp == ReadBytes(enteringFirm.rest, 8) IN IF ~mdInsertTimestamp.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(mdInsertTimestamp.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(secondaryOrderId.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(mdEntryType.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    Ok([ mdCorporateOffsetPriceOptional |-> mdCorporateOffsetPriceOptional.value,
         mdEntrySizeQuantity            |-> mdEntrySizeQuantity.value,
         offset16Padding4               |-> offset16Padding4.value,
         enteringFirm                   |-> enteringFirm.value,
         mdInsertTimestamp              |-> mdInsertTimestamp.value,
         secondaryOrderId               |-> secondaryOrderId.value,
         mdEntryType                    |-> mdEntryType.value,
         matchEventIndicator            |-> matchEventIndicator.value ], matchEventIndicator.rest)

ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    [ mdCorporateOffsetPriceOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeQuantity            |-> [i \in 1 .. 8 |-> 0],
      offset16Padding4               |-> [i \in 1 .. 4 |-> 0],
      enteringFirm                   |-> [i \in 1 .. 4 |-> 0],
      mdInsertTimestamp              |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId               |-> [i \in 1 .. 8 |-> 0],
      mdEntryType                    |-> [i \in 1 .. 1 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Full Refresh Orders Mb O 71 Message no M D Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup ==
    { ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdCorporateOffsetPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdEntrySizeQuantity = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.offset16Padding4 = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.enteringFirm = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdInsertTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshOrdersMbO71MessageNoMDEntriesGroup EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }

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
EmptyBookMessageCode == 9  \* 0x09
ChannelReset11MessageCode == 11  \* 0x0b
SecurityStatus3MessageCode == 3  \* 0x03
SecurityGroupPhase10MessageCode == 10  \* 0x0a
SecurityDefinitionMessageCode == 12  \* 0x0c
News5MessageCode == 5  \* 0x05
OpeningPrice15MessageCode == 15  \* 0x0f
TheoreticalOpeningPrice16MessageCode == 16  \* 0x10
ClosingPrice17MessageCode == 17  \* 0x11
AuctionImbalance19MessageCode == 19  \* 0x13
QuantityBand21MessageCode == 21  \* 0x15
PriceBand22MessageCode == 22  \* 0x16
HighPrice24MessageCode == 24  \* 0x18
LowPrice25MessageCode == 25  \* 0x19
LastTradePrice27MessageCode == 27  \* 0x1b
SettlementPrice28MessageCode == 28  \* 0x1c
OpenInterest29MessageCode == 29  \* 0x1d
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
        \cup [ tag : {EmptyBookMessageCode}, body : EmptyBookMessage ]
        \cup [ tag : {ChannelReset11MessageCode}, body : ChannelReset11Message ]
        \cup [ tag : {SecurityStatus3MessageCode}, body : SecurityStatus3Message ]
        \cup [ tag : {SecurityGroupPhase10MessageCode}, body : SecurityGroupPhase10Message ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {News5MessageCode}, body : News5Message ]
        \cup [ tag : {OpeningPrice15MessageCode}, body : OpeningPrice15Message ]
        \cup [ tag : {TheoreticalOpeningPrice16MessageCode}, body : TheoreticalOpeningPrice16Message ]
        \cup [ tag : {ClosingPrice17MessageCode}, body : ClosingPrice17Message ]
        \cup [ tag : {AuctionImbalance19MessageCode}, body : AuctionImbalance19Message ]
        \cup [ tag : {QuantityBand21MessageCode}, body : QuantityBand21Message ]
        \cup [ tag : {PriceBand22MessageCode}, body : PriceBand22Message ]
        \cup [ tag : {HighPrice24MessageCode}, body : HighPrice24Message ]
        \cup [ tag : {LowPrice25MessageCode}, body : LowPrice25Message ]
        \cup [ tag : {LastTradePrice27MessageCode}, body : LastTradePrice27Message ]
        \cup [ tag : {SettlementPrice28MessageCode}, body : SettlementPrice28Message ]
        \cup [ tag : {OpenInterest29MessageCode}, body : OpenInterest29Message ]
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
      [] message.tag = EmptyBookMessageCode -> EncodeEmptyBookMessage(message.body)
      [] message.tag = ChannelReset11MessageCode -> EncodeChannelReset11Message(message.body)
      [] message.tag = SecurityStatus3MessageCode -> EncodeSecurityStatus3Message(message.body)
      [] message.tag = SecurityGroupPhase10MessageCode -> EncodeSecurityGroupPhase10Message(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = News5MessageCode -> EncodeNews5Message(message.body)
      [] message.tag = OpeningPrice15MessageCode -> EncodeOpeningPrice15Message(message.body)
      [] message.tag = TheoreticalOpeningPrice16MessageCode -> EncodeTheoreticalOpeningPrice16Message(message.body)
      [] message.tag = ClosingPrice17MessageCode -> EncodeClosingPrice17Message(message.body)
      [] message.tag = AuctionImbalance19MessageCode -> EncodeAuctionImbalance19Message(message.body)
      [] message.tag = QuantityBand21MessageCode -> EncodeQuantityBand21Message(message.body)
      [] message.tag = PriceBand22MessageCode -> EncodePriceBand22Message(message.body)
      [] message.tag = HighPrice24MessageCode -> EncodeHighPrice24Message(message.body)
      [] message.tag = LowPrice25MessageCode -> EncodeLowPrice25Message(message.body)
      [] message.tag = LastTradePrice27MessageCode -> EncodeLastTradePrice27Message(message.body)
      [] message.tag = SettlementPrice28MessageCode -> EncodeSettlementPrice28Message(message.body)
      [] message.tag = OpenInterest29MessageCode -> EncodeOpenInterest29Message(message.body)
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
              [] tag = EmptyBookMessageCode -> DecodeEmptyBookMessage(bytes)
              [] tag = ChannelReset11MessageCode -> DecodeChannelReset11Message(bytes)
              [] tag = SecurityStatus3MessageCode -> DecodeSecurityStatus3Message(bytes)
              [] tag = SecurityGroupPhase10MessageCode -> DecodeSecurityGroupPhase10Message(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = News5MessageCode -> DecodeNews5Message(bytes)
              [] tag = OpeningPrice15MessageCode -> DecodeOpeningPrice15Message(bytes)
              [] tag = TheoreticalOpeningPrice16MessageCode -> DecodeTheoreticalOpeningPrice16Message(bytes)
              [] tag = ClosingPrice17MessageCode -> DecodeClosingPrice17Message(bytes)
              [] tag = AuctionImbalance19MessageCode -> DecodeAuctionImbalance19Message(bytes)
              [] tag = QuantityBand21MessageCode -> DecodeQuantityBand21Message(bytes)
              [] tag = PriceBand22MessageCode -> DecodePriceBand22Message(bytes)
              [] tag = HighPrice24MessageCode -> DecodeHighPrice24Message(bytes)
              [] tag = LowPrice25MessageCode -> DecodeLowPrice25Message(bytes)
              [] tag = LastTradePrice27MessageCode -> DecodeLastTradePrice27Message(bytes)
              [] tag = SettlementPrice28MessageCode -> DecodeSettlementPrice28Message(bytes)
              [] tag = OpenInterest29MessageCode -> DecodeOpenInterest29Message(bytes)
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
        \cup { [tag |-> EmptyBookMessageCode, body |-> one] : one \in CheckedEmptyBookMessage }
        \cup { [tag |-> ChannelReset11MessageCode, body |-> one] : one \in CheckedChannelReset11Message }
        \cup { [tag |-> SecurityStatus3MessageCode, body |-> one] : one \in CheckedSecurityStatus3Message }
        \cup { [tag |-> SecurityGroupPhase10MessageCode, body |-> one] : one \in CheckedSecurityGroupPhase10Message }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> News5MessageCode, body |-> one] : one \in CheckedNews5Message }
        \cup { [tag |-> OpeningPrice15MessageCode, body |-> one] : one \in CheckedOpeningPrice15Message }
        \cup { [tag |-> TheoreticalOpeningPrice16MessageCode, body |-> one] : one \in CheckedTheoreticalOpeningPrice16Message }
        \cup { [tag |-> ClosingPrice17MessageCode, body |-> one] : one \in CheckedClosingPrice17Message }
        \cup { [tag |-> AuctionImbalance19MessageCode, body |-> one] : one \in CheckedAuctionImbalance19Message }
        \cup { [tag |-> QuantityBand21MessageCode, body |-> one] : one \in CheckedQuantityBand21Message }
        \cup { [tag |-> PriceBand22MessageCode, body |-> one] : one \in CheckedPriceBand22Message }
        \cup { [tag |-> HighPrice24MessageCode, body |-> one] : one \in CheckedHighPrice24Message }
        \cup { [tag |-> LowPrice25MessageCode, body |-> one] : one \in CheckedLowPrice25Message }
        \cup { [tag |-> LastTradePrice27MessageCode, body |-> one] : one \in CheckedLastTradePrice27Message }
        \cup { [tag |-> SettlementPrice28MessageCode, body |-> one] : one \in CheckedSettlementPrice28Message }
        \cup { [tag |-> OpenInterest29MessageCode, body |-> one] : one \in CheckedOpenInterest29Message }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> EmptyBookMessageCode, body |-> ZeroEmptyBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ChannelReset11MessageCode, body |-> ZeroChannelReset11Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatus3MessageCode, body |-> ZeroSecurityStatus3Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityGroupPhase10MessageCode, body |-> ZeroSecurityGroupPhase10Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> News5MessageCode, body |-> ZeroNews5Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpeningPrice15MessageCode, body |-> ZeroOpeningPrice15Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TheoreticalOpeningPrice16MessageCode, body |-> ZeroTheoreticalOpeningPrice16Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClosingPrice17MessageCode, body |-> ZeroClosingPrice17Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionImbalance19MessageCode, body |-> ZeroAuctionImbalance19Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuantityBand21MessageCode, body |-> ZeroQuantityBand21Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceBand22MessageCode, body |-> ZeroPriceBand22Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HighPrice24MessageCode, body |-> ZeroHighPrice24Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LowPrice25MessageCode, body |-> ZeroLowPrice25Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LastTradePrice27MessageCode, body |-> ZeroLastTradePrice27Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementPrice28MessageCode, body |-> ZeroSettlementPrice28Message]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenInterest29MessageCode, body |-> ZeroOpenInterest29Message]],
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

(* Every Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingsGroup ==
    \A message \in CheckedUnderlyingsGroup :
        LET read == DecodeUnderlyingsGroup(EncodeUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingsGroups ==
    \A message \in CheckedUnderlyingsGroups :
        LET read == DecodeUnderlyingsGroups(EncodeUnderlyingsGroups(message))
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

(* Every Instr Attribs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrAttribsGroup ==
    \A message \in CheckedInstrAttribsGroup :
        LET read == DecodeInstrAttribsGroup(EncodeInstrAttribsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instr Attribs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrAttribsGroups ==
    \A message \in CheckedInstrAttribsGroups :
        LET read == DecodeInstrAttribsGroups(EncodeInstrAttribsGroups(message))
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

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
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

(* Every Quantity Band 21 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuantityBand21Message ==
    \A message \in CheckedQuantityBand21Message :
        LET read == DecodeQuantityBand21Message(EncodeQuantityBand21Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Band 22 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceBand22Message ==
    \A message \in CheckedPriceBand22Message :
        LET read == DecodePriceBand22Message(EncodePriceBand22Message(message))
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

(* Every Settlement Price 28 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementPrice28Message ==
    \A message \in CheckedSettlementPrice28Message :
        LET read == DecodeSettlementPrice28Message(EncodeSettlementPrice28Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest 29 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterest29Message ==
    \A message \in CheckedOpenInterest29Message :
        LET read == DecodeOpenInterest29Message(EncodeOpenInterest29Message(message))
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
