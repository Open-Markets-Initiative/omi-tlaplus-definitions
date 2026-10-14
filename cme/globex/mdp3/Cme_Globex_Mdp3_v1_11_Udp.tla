--------------------- MODULE Cme_Globex_Mdp3_v1_11_Udp ---------------------
(***************************************************************************)
(* CME Group Market Data Platform 3 v1.11                                  *)
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
(* Note: Settl Price Type is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Inst Attrib Value is a bit field set, checked as its 4 bytes      *)
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
(* Binary Packet Header: 12 bytes                                          *)
(***************************************************************************)

BinaryPacketHeader ==
    [ packetSequenceNumber : Sample(4),
      sendingTime          : Sample(8) ]

EncodeBinaryPacketHeader(message) ==
    message.packetSequenceNumber
        \o message.sendingTime

DecodeBinaryPacketHeader(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(packetSequenceNumber.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         sendingTime          |-> sendingTime.value ], sendingTime.rest)

ZeroBinaryPacketHeader ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendingTime          |-> [i \in 1 .. 8 |-> 0] ]

(* Binary Packet Header at zero, then each field in turn at the values it is checked at *)
CheckedBinaryPacketHeader ==
    { ZeroBinaryPacketHeader }
        \cup { [ZeroBinaryPacketHeader EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBinaryPacketHeader EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Channel Reset Group: 2 bytes                                            *)
(***************************************************************************)

ChannelResetGroup ==
    [ applId : Sample(2) ]

EncodeChannelResetGroup(message) ==
    message.applId

DecodeChannelResetGroup(bytes) ==
    LET applId == ReadBytes(bytes, 2) IN IF ~applId.ok THEN Fail ELSE
    Ok([ applId |-> applId.value ], applId.rest)

ZeroChannelResetGroup ==
    [ applId |-> [i \in 1 .. 2 |-> 0] ]

(* Channel Reset Group at zero, then each field in turn at the values it is checked at *)
CheckedChannelResetGroup ==
    { ZeroChannelResetGroup }
        \cup { [ZeroChannelResetGroup EXCEPT !.applId = one] : one \in Sample(2) }

(* A run of Channel Reset Group, written one after another *)
RECURSIVE EncodeChannelResetGroupList(_)
EncodeChannelResetGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeChannelResetGroup(Head(messages)) \o EncodeChannelResetGroupList(Tail(messages))

(* As many Channel Reset Group as the field that counts them says *)
RECURSIVE ReadChannelResetGroupList(_, _)
ReadChannelResetGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeChannelResetGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadChannelResetGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Channel Reset Group of each kind, for the lists that carry them *)
OneChannelResetGroup == { ZeroChannelResetGroup }

(***************************************************************************)
(* Channel Reset Groups                                                    *)
(***************************************************************************)

ChannelResetGroups ==
    [ blockLength       : Sample(2),
      channelResetGroup : SampleLists(OneChannelResetGroup) ]

EncodeChannelResetGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.channelResetGroup), 1)
        \o EncodeChannelResetGroupList(message.channelResetGroup)

DecodeChannelResetGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET channelResetGroup == ReadChannelResetGroupList(numInGroup.rest, numInGroup.value) IN IF ~channelResetGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         channelResetGroup |-> channelResetGroup.value ], channelResetGroup.rest)

ZeroChannelResetGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      channelResetGroup |-> << >> ]

(* Channel Reset Groups at zero, then each field in turn at the values it is checked at *)
CheckedChannelResetGroups ==
    { ZeroChannelResetGroups }
        \cup { [ZeroChannelResetGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroChannelResetGroups EXCEPT !.channelResetGroup = one] : one \in SampleLists(OneChannelResetGroup) }

(***************************************************************************)
(* Channel Reset                                                           *)
(***************************************************************************)

ChannelReset ==
    [ transactTime        : Sample(8),
      matchEventIndicator : Sample(1),
      channelResetGroups  : ChannelResetGroups ]

EncodeChannelReset(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o EncodeChannelResetGroups(message.channelResetGroups)

DecodeChannelReset(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET channelResetGroups == DecodeChannelResetGroups(matchEventIndicator.rest) IN IF ~channelResetGroups.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         matchEventIndicator |-> matchEventIndicator.value,
         channelResetGroups  |-> channelResetGroups.value ], channelResetGroups.rest)

ZeroChannelReset ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      channelResetGroups  |-> ZeroChannelResetGroups ]

(* Channel Reset at zero, then each field in turn at the values it is checked at *)
CheckedChannelReset ==
    { ZeroChannelReset }
        \cup { [ZeroChannelReset EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroChannelReset EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroChannelReset EXCEPT !.channelResetGroups = one] : one \in CheckedChannelResetGroups }

(***************************************************************************)
(* Admin Login: 1 bytes                                                    *)
(***************************************************************************)

AdminLogin ==
    [ heartBtInt : Sample(1) ]

EncodeAdminLogin(message) ==
    message.heartBtInt

DecodeAdminLogin(bytes) ==
    LET heartBtInt == ReadBytes(bytes, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    Ok([ heartBtInt |-> heartBtInt.value ], heartBtInt.rest)

ZeroAdminLogin ==
    [ heartBtInt |-> [i \in 1 .. 1 |-> 0] ]

(* Admin Login at zero, then each field in turn at the values it is checked at *)
CheckedAdminLogin ==
    { ZeroAdminLogin }
        \cup { [ZeroAdminLogin EXCEPT !.heartBtInt = one] : one \in Sample(1) }

(***************************************************************************)
(* Admin Logout: 180 bytes                                                 *)
(***************************************************************************)

AdminLogout ==
    [ logoutText : Sample(180) ]

EncodeAdminLogout(message) ==
    message.logoutText

DecodeAdminLogout(bytes) ==
    LET logoutText == ReadBytes(bytes, 180) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutText |-> logoutText.value ], logoutText.rest)

ZeroAdminLogout ==
    [ logoutText |-> [i \in 1 .. 180 |-> 0] ]

(* Admin Logout at zero, then each field in turn at the values it is checked at *)
CheckedAdminLogout ==
    { ZeroAdminLogout }
        \cup { [ZeroAdminLogout EXCEPT !.logoutText = one] : one \in Sample(180) }

(***************************************************************************)
(* Security Status: 30 bytes                                               *)
(***************************************************************************)

SecurityStatus ==
    [ transactTime          : Sample(8),
      securityGroup         : Sample(6),
      asset                 : Sample(6),
      securityIdOptional    : Sample(4),
      tradeDate             : Sample(2),
      matchEventIndicator   : Sample(1),
      securityTradingStatus : Sample(1),
      haltReason            : Sample(1),
      securityTradingEvent  : Sample(1) ]

EncodeSecurityStatus(message) ==
    message.transactTime
        \o message.securityGroup
        \o message.asset
        \o message.securityIdOptional
        \o message.tradeDate
        \o message.matchEventIndicator
        \o message.securityTradingStatus
        \o message.haltReason
        \o message.securityTradingEvent

DecodeSecurityStatus(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(transactTime.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(asset.rest, 4) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(securityIdOptional.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(tradeDate.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(matchEventIndicator.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(securityTradingStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(haltReason.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    Ok([ transactTime          |-> transactTime.value,
         securityGroup         |-> securityGroup.value,
         asset                 |-> asset.value,
         securityIdOptional    |-> securityIdOptional.value,
         tradeDate             |-> tradeDate.value,
         matchEventIndicator   |-> matchEventIndicator.value,
         securityTradingStatus |-> securityTradingStatus.value,
         haltReason            |-> haltReason.value,
         securityTradingEvent  |-> securityTradingEvent.value ], securityTradingEvent.rest)

ZeroSecurityStatus ==
    [ transactTime          |-> [i \in 1 .. 8 |-> 0],
      securityGroup         |-> [i \in 1 .. 6 |-> 0],
      asset                 |-> [i \in 1 .. 6 |-> 0],
      securityIdOptional    |-> [i \in 1 .. 4 |-> 0],
      tradeDate             |-> [i \in 1 .. 2 |-> 0],
      matchEventIndicator   |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      haltReason            |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Status at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatus ==
    { ZeroSecurityStatus }
        \cup { [ZeroSecurityStatus EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatus EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroSecurityStatus EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroSecurityStatus EXCEPT !.securityIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatus EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatus EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatus EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }

(***************************************************************************)
(* Incremental Refresh Volume Group: 16 bytes                              *)
(***************************************************************************)

IncrementalRefreshVolumeGroup ==
    [ mdEntrySizeShort : Sample(4),
      securityId       : Sample(4),
      rptSeq           : Sample(4),
      mdUpdateAction   : Sample(1),
      padding3         : Sample(3) ]

EncodeIncrementalRefreshVolumeGroup(message) ==
    message.mdEntrySizeShort
        \o message.securityId
        \o message.rptSeq
        \o message.mdUpdateAction
        \o message.padding3

DecodeIncrementalRefreshVolumeGroup(bytes) ==
    LET mdEntrySizeShort == ReadBytes(bytes, 4) IN IF ~mdEntrySizeShort.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntrySizeShort.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(rptSeq.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET padding3 == ReadBytes(mdUpdateAction.rest, 3) IN IF ~padding3.ok THEN Fail ELSE
    Ok([ mdEntrySizeShort |-> mdEntrySizeShort.value,
         securityId       |-> securityId.value,
         rptSeq           |-> rptSeq.value,
         mdUpdateAction   |-> mdUpdateAction.value,
         padding3         |-> padding3.value ], padding3.rest)

ZeroIncrementalRefreshVolumeGroup ==
    [ mdEntrySizeShort |-> [i \in 1 .. 4 |-> 0],
      securityId       |-> [i \in 1 .. 4 |-> 0],
      rptSeq           |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction   |-> [i \in 1 .. 1 |-> 0],
      padding3         |-> [i \in 1 .. 3 |-> 0] ]

(* Incremental Refresh Volume Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshVolumeGroup ==
    { ZeroIncrementalRefreshVolumeGroup }
        \cup { [ZeroIncrementalRefreshVolumeGroup EXCEPT !.mdEntrySizeShort = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVolumeGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVolumeGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshVolumeGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshVolumeGroup EXCEPT !.padding3 = one] : one \in Sample(3) }

(* A run of Incremental Refresh Volume Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshVolumeGroupList(_)
EncodeIncrementalRefreshVolumeGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshVolumeGroup(Head(messages)) \o EncodeIncrementalRefreshVolumeGroupList(Tail(messages))

(* As many Incremental Refresh Volume Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshVolumeGroupList(_, _)
ReadIncrementalRefreshVolumeGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshVolumeGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshVolumeGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Volume Group of each kind, for the lists that carry them *)
OneIncrementalRefreshVolumeGroup == { ZeroIncrementalRefreshVolumeGroup }

(***************************************************************************)
(* Incremental Refresh Volume Groups                                       *)
(***************************************************************************)

IncrementalRefreshVolumeGroups ==
    [ blockLength                   : Sample(2),
      incrementalRefreshVolumeGroup : SampleLists(OneIncrementalRefreshVolumeGroup) ]

EncodeIncrementalRefreshVolumeGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshVolumeGroup), 1)
        \o EncodeIncrementalRefreshVolumeGroupList(message.incrementalRefreshVolumeGroup)

DecodeIncrementalRefreshVolumeGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshVolumeGroup == ReadIncrementalRefreshVolumeGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshVolumeGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         incrementalRefreshVolumeGroup |-> incrementalRefreshVolumeGroup.value ], incrementalRefreshVolumeGroup.rest)

ZeroIncrementalRefreshVolumeGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshVolumeGroup |-> << >> ]

(* Incremental Refresh Volume Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshVolumeGroups ==
    { ZeroIncrementalRefreshVolumeGroups }
        \cup { [ZeroIncrementalRefreshVolumeGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshVolumeGroups EXCEPT !.incrementalRefreshVolumeGroup = one] : one \in SampleLists(OneIncrementalRefreshVolumeGroup) }

(***************************************************************************)
(* Md Incremental Refresh Volume                                           *)
(***************************************************************************)

MdIncrementalRefreshVolume ==
    [ transactTime                   : Sample(8),
      matchEventIndicator            : Sample(1),
      padding2                       : Sample(2),
      incrementalRefreshVolumeGroups : IncrementalRefreshVolumeGroups ]

EncodeMdIncrementalRefreshVolume(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshVolumeGroups(message.incrementalRefreshVolumeGroups)

DecodeMdIncrementalRefreshVolume(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshVolumeGroups == DecodeIncrementalRefreshVolumeGroups(padding2.rest) IN IF ~incrementalRefreshVolumeGroups.ok THEN Fail ELSE
    Ok([ transactTime                   |-> transactTime.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         padding2                       |-> padding2.value,
         incrementalRefreshVolumeGroups |-> incrementalRefreshVolumeGroups.value ], incrementalRefreshVolumeGroups.rest)

ZeroMdIncrementalRefreshVolume ==
    [ transactTime                   |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      padding2                       |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshVolumeGroups |-> ZeroIncrementalRefreshVolumeGroups ]

(* Md Incremental Refresh Volume at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshVolume ==
    { ZeroMdIncrementalRefreshVolume }
        \cup { [ZeroMdIncrementalRefreshVolume EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshVolume EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshVolume EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshVolume EXCEPT !.incrementalRefreshVolumeGroups = one] : one \in CheckedIncrementalRefreshVolumeGroups }

(***************************************************************************)
(* Related Sym Group: 32 bytes                                             *)
(***************************************************************************)

RelatedSymGroup ==
    [ symbol       : Sample(20),
      securityId   : Sample(4),
      orderQty     : Sample(4),
      quoteType    : Sample(1),
      sideOptional : Sample(1),
      padding2     : Sample(2) ]

EncodeRelatedSymGroup(message) ==
    message.symbol
        \o message.securityId
        \o message.orderQty
        \o message.quoteType
        \o message.sideOptional
        \o message.padding2

DecodeRelatedSymGroup(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET quoteType == ReadBytes(orderQty.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(quoteType.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET padding2 == ReadBytes(sideOptional.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    Ok([ symbol       |-> symbol.value,
         securityId   |-> securityId.value,
         orderQty     |-> orderQty.value,
         quoteType    |-> quoteType.value,
         sideOptional |-> sideOptional.value,
         padding2     |-> padding2.value ], padding2.rest)

ZeroRelatedSymGroup ==
    [ symbol       |-> [i \in 1 .. 20 |-> 0],
      securityId   |-> [i \in 1 .. 4 |-> 0],
      orderQty     |-> [i \in 1 .. 4 |-> 0],
      quoteType    |-> [i \in 1 .. 1 |-> 0],
      sideOptional |-> [i \in 1 .. 1 |-> 0],
      padding2     |-> [i \in 1 .. 2 |-> 0] ]

(* Related Sym Group at zero, then each field in turn at the values it is checked at *)
CheckedRelatedSymGroup ==
    { ZeroRelatedSymGroup }
        \cup { [ZeroRelatedSymGroup EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.padding2 = one] : one \in Sample(2) }

(* A run of Related Sym Group, written one after another *)
RECURSIVE EncodeRelatedSymGroupList(_)
EncodeRelatedSymGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRelatedSymGroup(Head(messages)) \o EncodeRelatedSymGroupList(Tail(messages))

(* As many Related Sym Group as the field that counts them says *)
RECURSIVE ReadRelatedSymGroupList(_, _)
ReadRelatedSymGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRelatedSymGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRelatedSymGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Related Sym Group of each kind, for the lists that carry them *)
OneRelatedSymGroup == { ZeroRelatedSymGroup }

(***************************************************************************)
(* Related Sym Groups                                                      *)
(***************************************************************************)

RelatedSymGroups ==
    [ blockLength     : Sample(2),
      relatedSymGroup : SampleLists(OneRelatedSymGroup) ]

EncodeRelatedSymGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.relatedSymGroup), 1)
        \o EncodeRelatedSymGroupList(message.relatedSymGroup)

DecodeRelatedSymGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET relatedSymGroup == ReadRelatedSymGroupList(numInGroup.rest, numInGroup.value) IN IF ~relatedSymGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         relatedSymGroup |-> relatedSymGroup.value ], relatedSymGroup.rest)

ZeroRelatedSymGroups ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      relatedSymGroup |-> << >> ]

(* Related Sym Groups at zero, then each field in turn at the values it is checked at *)
CheckedRelatedSymGroups ==
    { ZeroRelatedSymGroups }
        \cup { [ZeroRelatedSymGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRelatedSymGroups EXCEPT !.relatedSymGroup = one] : one \in SampleLists(OneRelatedSymGroup) }

(***************************************************************************)
(* Quote Request                                                           *)
(***************************************************************************)

QuoteRequest ==
    [ transactTime        : Sample(8),
      quoteReqId          : Sample(23),
      matchEventIndicator : Sample(1),
      padding3            : Sample(3),
      relatedSymGroups    : RelatedSymGroups ]

EncodeQuoteRequest(message) ==
    message.transactTime
        \o message.quoteReqId
        \o message.matchEventIndicator
        \o message.padding3
        \o EncodeRelatedSymGroups(message.relatedSymGroups)

DecodeQuoteRequest(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(transactTime.rest, 23) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(quoteReqId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding3 == ReadBytes(matchEventIndicator.rest, 3) IN IF ~padding3.ok THEN Fail ELSE
    LET relatedSymGroups == DecodeRelatedSymGroups(padding3.rest) IN IF ~relatedSymGroups.ok THEN Fail ELSE
    Ok([ transactTime        |-> transactTime.value,
         quoteReqId          |-> quoteReqId.value,
         matchEventIndicator |-> matchEventIndicator.value,
         padding3            |-> padding3.value,
         relatedSymGroups    |-> relatedSymGroups.value ], relatedSymGroups.rest)

ZeroQuoteRequest ==
    [ transactTime        |-> [i \in 1 .. 8 |-> 0],
      quoteReqId          |-> [i \in 1 .. 23 |-> 0],
      matchEventIndicator |-> [i \in 1 .. 1 |-> 0],
      padding3            |-> [i \in 1 .. 3 |-> 0],
      relatedSymGroups    |-> ZeroRelatedSymGroups ]

(* Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequest ==
    { ZeroQuoteRequest }
        \cup { [ZeroQuoteRequest EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequest EXCEPT !.quoteReqId = one] : one \in Sample(23) }
        \cup { [ZeroQuoteRequest EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequest EXCEPT !.padding3 = one] : one \in Sample(3) }
        \cup { [ZeroQuoteRequest EXCEPT !.relatedSymGroups = one] : one \in CheckedRelatedSymGroups }

(***************************************************************************)
(* Incremental Refresh Book Group: 32 bytes                                *)
(***************************************************************************)

IncrementalRefreshBookGroup ==
    [ mdEntryPxOptionalEx      : Sample(8),
      mdEntrySizeShortOptional : Sample(4),
      securityId               : Sample(4),
      rptSeq                   : Sample(4),
      numberOfOrdersOptional   : Sample(4),
      mdPriceLevel             : Sample(1),
      mdUpdateAction           : Sample(1),
      mdEntryTypeBook          : Sample(1),
      tradeableSize            : Sample(4),
      padding1                 : Sample(1) ]

EncodeIncrementalRefreshBookGroup(message) ==
    message.mdEntryPxOptionalEx
        \o message.mdEntrySizeShortOptional
        \o message.securityId
        \o message.rptSeq
        \o message.numberOfOrdersOptional
        \o message.mdPriceLevel
        \o message.mdUpdateAction
        \o message.mdEntryTypeBook
        \o message.tradeableSize
        \o message.padding1

DecodeIncrementalRefreshBookGroup(bytes) ==
    LET mdEntryPxOptionalEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET mdEntrySizeShortOptional == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~mdEntrySizeShortOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntrySizeShortOptional.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET numberOfOrdersOptional == ReadBytes(rptSeq.rest, 4) IN IF ~numberOfOrdersOptional.ok THEN Fail ELSE
    LET mdPriceLevel == ReadBytes(numberOfOrdersOptional.rest, 1) IN IF ~mdPriceLevel.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(mdPriceLevel.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryTypeBook == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryTypeBook.ok THEN Fail ELSE
    LET tradeableSize == ReadBytes(mdEntryTypeBook.rest, 4) IN IF ~tradeableSize.ok THEN Fail ELSE
    LET padding1 == ReadBytes(tradeableSize.rest, 1) IN IF ~padding1.ok THEN Fail ELSE
    Ok([ mdEntryPxOptionalEx      |-> mdEntryPxOptionalEx.value,
         mdEntrySizeShortOptional |-> mdEntrySizeShortOptional.value,
         securityId               |-> securityId.value,
         rptSeq                   |-> rptSeq.value,
         numberOfOrdersOptional   |-> numberOfOrdersOptional.value,
         mdPriceLevel             |-> mdPriceLevel.value,
         mdUpdateAction           |-> mdUpdateAction.value,
         mdEntryTypeBook          |-> mdEntryTypeBook.value,
         tradeableSize            |-> tradeableSize.value,
         padding1                 |-> padding1.value ], padding1.rest)

ZeroIncrementalRefreshBookGroup ==
    [ mdEntryPxOptionalEx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeShortOptional |-> [i \in 1 .. 4 |-> 0],
      securityId               |-> [i \in 1 .. 4 |-> 0],
      rptSeq                   |-> [i \in 1 .. 4 |-> 0],
      numberOfOrdersOptional   |-> [i \in 1 .. 4 |-> 0],
      mdPriceLevel             |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction           |-> [i \in 1 .. 1 |-> 0],
      mdEntryTypeBook          |-> [i \in 1 .. 1 |-> 0],
      tradeableSize            |-> [i \in 1 .. 4 |-> 0],
      padding1                 |-> [i \in 1 .. 1 |-> 0] ]

(* Incremental Refresh Book Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBookGroup ==
    { ZeroIncrementalRefreshBookGroup }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.mdEntrySizeShortOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.numberOfOrdersOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.mdPriceLevel = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.mdEntryTypeBook = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.tradeableSize = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookGroup EXCEPT !.padding1 = one] : one \in Sample(1) }

(* A run of Incremental Refresh Book Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshBookGroupList(_)
EncodeIncrementalRefreshBookGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshBookGroup(Head(messages)) \o EncodeIncrementalRefreshBookGroupList(Tail(messages))

(* As many Incremental Refresh Book Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshBookGroupList(_, _)
ReadIncrementalRefreshBookGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshBookGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshBookGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Book Group of each kind, for the lists that carry them *)
OneIncrementalRefreshBookGroup == { ZeroIncrementalRefreshBookGroup }

(***************************************************************************)
(* Incremental Refresh Book Groups                                         *)
(***************************************************************************)

IncrementalRefreshBookGroups ==
    [ blockLength                 : Sample(2),
      incrementalRefreshBookGroup : SampleLists(OneIncrementalRefreshBookGroup) ]

EncodeIncrementalRefreshBookGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshBookGroup), 1)
        \o EncodeIncrementalRefreshBookGroupList(message.incrementalRefreshBookGroup)

DecodeIncrementalRefreshBookGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshBookGroup == ReadIncrementalRefreshBookGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshBookGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         incrementalRefreshBookGroup |-> incrementalRefreshBookGroup.value ], incrementalRefreshBookGroup.rest)

ZeroIncrementalRefreshBookGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshBookGroup |-> << >> ]

(* Incremental Refresh Book Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBookGroups ==
    { ZeroIncrementalRefreshBookGroups }
        \cup { [ZeroIncrementalRefreshBookGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshBookGroups EXCEPT !.incrementalRefreshBookGroup = one] : one \in SampleLists(OneIncrementalRefreshBookGroup) }

(***************************************************************************)
(* Incremental Refresh Book Order Id Group: 24 bytes                       *)
(***************************************************************************)

IncrementalRefreshBookOrderIdGroup ==
    [ orderId                 : Sample(8),
      mdOrderPriorityOptional : Sample(8),
      mdDisplayQtyOptional    : Sample(4),
      referenceId             : Sample(1),
      orderUpdateAction       : Sample(1),
      padding2                : Sample(2) ]

EncodeIncrementalRefreshBookOrderIdGroup(message) ==
    message.orderId
        \o message.mdOrderPriorityOptional
        \o message.mdDisplayQtyOptional
        \o message.referenceId
        \o message.orderUpdateAction
        \o message.padding2

DecodeIncrementalRefreshBookOrderIdGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET mdOrderPriorityOptional == ReadBytes(orderId.rest, 8) IN IF ~mdOrderPriorityOptional.ok THEN Fail ELSE
    LET mdDisplayQtyOptional == ReadBytes(mdOrderPriorityOptional.rest, 4) IN IF ~mdDisplayQtyOptional.ok THEN Fail ELSE
    LET referenceId == ReadBytes(mdDisplayQtyOptional.rest, 1) IN IF ~referenceId.ok THEN Fail ELSE
    LET orderUpdateAction == ReadBytes(referenceId.rest, 1) IN IF ~orderUpdateAction.ok THEN Fail ELSE
    LET padding2 == ReadBytes(orderUpdateAction.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    Ok([ orderId                 |-> orderId.value,
         mdOrderPriorityOptional |-> mdOrderPriorityOptional.value,
         mdDisplayQtyOptional    |-> mdDisplayQtyOptional.value,
         referenceId             |-> referenceId.value,
         orderUpdateAction       |-> orderUpdateAction.value,
         padding2                |-> padding2.value ], padding2.rest)

ZeroIncrementalRefreshBookOrderIdGroup ==
    [ orderId                 |-> [i \in 1 .. 8 |-> 0],
      mdOrderPriorityOptional |-> [i \in 1 .. 8 |-> 0],
      mdDisplayQtyOptional    |-> [i \in 1 .. 4 |-> 0],
      referenceId             |-> [i \in 1 .. 1 |-> 0],
      orderUpdateAction       |-> [i \in 1 .. 1 |-> 0],
      padding2                |-> [i \in 1 .. 2 |-> 0] ]

(* Incremental Refresh Book Order Id Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBookOrderIdGroup ==
    { ZeroIncrementalRefreshBookOrderIdGroup }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.mdOrderPriorityOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.mdDisplayQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.referenceId = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.orderUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroup EXCEPT !.padding2 = one] : one \in Sample(2) }

(* A run of Incremental Refresh Book Order Id Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshBookOrderIdGroupList(_)
EncodeIncrementalRefreshBookOrderIdGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshBookOrderIdGroup(Head(messages)) \o EncodeIncrementalRefreshBookOrderIdGroupList(Tail(messages))

(* As many Incremental Refresh Book Order Id Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshBookOrderIdGroupList(_, _)
ReadIncrementalRefreshBookOrderIdGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshBookOrderIdGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshBookOrderIdGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Book Order Id Group of each kind, for the lists that carry them *)
OneIncrementalRefreshBookOrderIdGroup == { ZeroIncrementalRefreshBookOrderIdGroup }

(***************************************************************************)
(* Incremental Refresh Book Order Id Groups                                *)
(***************************************************************************)

IncrementalRefreshBookOrderIdGroups ==
    [ blockLength                        : Sample(2),
      padding5                           : Sample(5),
      incrementalRefreshBookOrderIdGroup : SampleLists(OneIncrementalRefreshBookOrderIdGroup) ]

EncodeIncrementalRefreshBookOrderIdGroups(message) ==
    message.blockLength
        \o message.padding5
        \o EncodeUIntBE(Len(message.incrementalRefreshBookOrderIdGroup), 1)
        \o EncodeIncrementalRefreshBookOrderIdGroupList(message.incrementalRefreshBookOrderIdGroup)

DecodeIncrementalRefreshBookOrderIdGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET padding5 == ReadBytes(blockLength.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(padding5.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshBookOrderIdGroup == ReadIncrementalRefreshBookOrderIdGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshBookOrderIdGroup.ok THEN Fail ELSE
    Ok([ blockLength                        |-> blockLength.value,
         padding5                           |-> padding5.value,
         incrementalRefreshBookOrderIdGroup |-> incrementalRefreshBookOrderIdGroup.value ], incrementalRefreshBookOrderIdGroup.rest)

ZeroIncrementalRefreshBookOrderIdGroups ==
    [ blockLength                        |-> [i \in 1 .. 2 |-> 0],
      padding5                           |-> [i \in 1 .. 5 |-> 0],
      incrementalRefreshBookOrderIdGroup |-> << >> ]

(* Incremental Refresh Book Order Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshBookOrderIdGroups ==
    { ZeroIncrementalRefreshBookOrderIdGroups }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroups EXCEPT !.padding5 = one] : one \in Sample(5) }
        \cup { [ZeroIncrementalRefreshBookOrderIdGroups EXCEPT !.incrementalRefreshBookOrderIdGroup = one] : one \in SampleLists(OneIncrementalRefreshBookOrderIdGroup) }

(***************************************************************************)
(* Md Incremental Refresh Book                                             *)
(***************************************************************************)

MdIncrementalRefreshBook ==
    [ transactTime                        : Sample(8),
      matchEventIndicator                 : Sample(1),
      padding2                            : Sample(2),
      incrementalRefreshBookGroups        : IncrementalRefreshBookGroups,
      incrementalRefreshBookOrderIdGroups : IncrementalRefreshBookOrderIdGroups ]

EncodeMdIncrementalRefreshBook(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshBookGroups(message.incrementalRefreshBookGroups)
        \o EncodeIncrementalRefreshBookOrderIdGroups(message.incrementalRefreshBookOrderIdGroups)

DecodeMdIncrementalRefreshBook(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshBookGroups == DecodeIncrementalRefreshBookGroups(padding2.rest) IN IF ~incrementalRefreshBookGroups.ok THEN Fail ELSE
    LET incrementalRefreshBookOrderIdGroups == DecodeIncrementalRefreshBookOrderIdGroups(incrementalRefreshBookGroups.rest) IN IF ~incrementalRefreshBookOrderIdGroups.ok THEN Fail ELSE
    Ok([ transactTime                        |-> transactTime.value,
         matchEventIndicator                 |-> matchEventIndicator.value,
         padding2                            |-> padding2.value,
         incrementalRefreshBookGroups        |-> incrementalRefreshBookGroups.value,
         incrementalRefreshBookOrderIdGroups |-> incrementalRefreshBookOrderIdGroups.value ], incrementalRefreshBookOrderIdGroups.rest)

ZeroMdIncrementalRefreshBook ==
    [ transactTime                        |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator                 |-> [i \in 1 .. 1 |-> 0],
      padding2                            |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshBookGroups        |-> ZeroIncrementalRefreshBookGroups,
      incrementalRefreshBookOrderIdGroups |-> ZeroIncrementalRefreshBookOrderIdGroups ]

(* Md Incremental Refresh Book at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshBook ==
    { ZeroMdIncrementalRefreshBook }
        \cup { [ZeroMdIncrementalRefreshBook EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshBook EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshBook EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshBook EXCEPT !.incrementalRefreshBookGroups = one] : one \in CheckedIncrementalRefreshBookGroups }
        \cup { [ZeroMdIncrementalRefreshBook EXCEPT !.incrementalRefreshBookOrderIdGroups = one] : one \in CheckedIncrementalRefreshBookOrderIdGroups }

(***************************************************************************)
(* Incremental Refresh Order Book Group: 40 bytes                          *)
(***************************************************************************)

IncrementalRefreshOrderBookGroup ==
    [ orderIdOptional         : Sample(8),
      mdOrderPriorityOptional : Sample(8),
      mdEntryPxOptionalEx     : Sample(8),
      mdDisplayQtyOptional    : Sample(4),
      securityId              : Sample(4),
      mdUpdateAction          : Sample(1),
      mdEntryTypeBook         : Sample(1),
      padding6                : Sample(6) ]

EncodeIncrementalRefreshOrderBookGroup(message) ==
    message.orderIdOptional
        \o message.mdOrderPriorityOptional
        \o message.mdEntryPxOptionalEx
        \o message.mdDisplayQtyOptional
        \o message.securityId
        \o message.mdUpdateAction
        \o message.mdEntryTypeBook
        \o message.padding6

DecodeIncrementalRefreshOrderBookGroup(bytes) ==
    LET orderIdOptional == ReadBytes(bytes, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET mdOrderPriorityOptional == ReadBytes(orderIdOptional.rest, 8) IN IF ~mdOrderPriorityOptional.ok THEN Fail ELSE
    LET mdEntryPxOptionalEx == ReadBytes(mdOrderPriorityOptional.rest, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET mdDisplayQtyOptional == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~mdDisplayQtyOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdDisplayQtyOptional.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(securityId.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryTypeBook == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryTypeBook.ok THEN Fail ELSE
    LET padding6 == ReadBytes(mdEntryTypeBook.rest, 6) IN IF ~padding6.ok THEN Fail ELSE
    Ok([ orderIdOptional         |-> orderIdOptional.value,
         mdOrderPriorityOptional |-> mdOrderPriorityOptional.value,
         mdEntryPxOptionalEx     |-> mdEntryPxOptionalEx.value,
         mdDisplayQtyOptional    |-> mdDisplayQtyOptional.value,
         securityId              |-> securityId.value,
         mdUpdateAction          |-> mdUpdateAction.value,
         mdEntryTypeBook         |-> mdEntryTypeBook.value,
         padding6                |-> padding6.value ], padding6.rest)

ZeroIncrementalRefreshOrderBookGroup ==
    [ orderIdOptional         |-> [i \in 1 .. 8 |-> 0],
      mdOrderPriorityOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxOptionalEx     |-> [i \in 1 .. 8 |-> 0],
      mdDisplayQtyOptional    |-> [i \in 1 .. 4 |-> 0],
      securityId              |-> [i \in 1 .. 4 |-> 0],
      mdUpdateAction          |-> [i \in 1 .. 1 |-> 0],
      mdEntryTypeBook         |-> [i \in 1 .. 1 |-> 0],
      padding6                |-> [i \in 1 .. 6 |-> 0] ]

(* Incremental Refresh Order Book Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshOrderBookGroup ==
    { ZeroIncrementalRefreshOrderBookGroup }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.mdOrderPriorityOptional = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.mdDisplayQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.mdEntryTypeBook = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshOrderBookGroup EXCEPT !.padding6 = one] : one \in Sample(6) }

(* A run of Incremental Refresh Order Book Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshOrderBookGroupList(_)
EncodeIncrementalRefreshOrderBookGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshOrderBookGroup(Head(messages)) \o EncodeIncrementalRefreshOrderBookGroupList(Tail(messages))

(* As many Incremental Refresh Order Book Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshOrderBookGroupList(_, _)
ReadIncrementalRefreshOrderBookGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshOrderBookGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshOrderBookGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Order Book Group of each kind, for the lists that carry them *)
OneIncrementalRefreshOrderBookGroup == { ZeroIncrementalRefreshOrderBookGroup }

(***************************************************************************)
(* Incremental Refresh Order Book Groups                                   *)
(***************************************************************************)

IncrementalRefreshOrderBookGroups ==
    [ blockLength                      : Sample(2),
      incrementalRefreshOrderBookGroup : SampleLists(OneIncrementalRefreshOrderBookGroup) ]

EncodeIncrementalRefreshOrderBookGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshOrderBookGroup), 1)
        \o EncodeIncrementalRefreshOrderBookGroupList(message.incrementalRefreshOrderBookGroup)

DecodeIncrementalRefreshOrderBookGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshOrderBookGroup == ReadIncrementalRefreshOrderBookGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshOrderBookGroup.ok THEN Fail ELSE
    Ok([ blockLength                      |-> blockLength.value,
         incrementalRefreshOrderBookGroup |-> incrementalRefreshOrderBookGroup.value ], incrementalRefreshOrderBookGroup.rest)

ZeroIncrementalRefreshOrderBookGroups ==
    [ blockLength                      |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshOrderBookGroup |-> << >> ]

(* Incremental Refresh Order Book Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshOrderBookGroups ==
    { ZeroIncrementalRefreshOrderBookGroups }
        \cup { [ZeroIncrementalRefreshOrderBookGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshOrderBookGroups EXCEPT !.incrementalRefreshOrderBookGroup = one] : one \in SampleLists(OneIncrementalRefreshOrderBookGroup) }

(***************************************************************************)
(* Md Incremental Refresh Order Book                                       *)
(***************************************************************************)

MdIncrementalRefreshOrderBook ==
    [ transactTime                      : Sample(8),
      matchEventIndicator               : Sample(1),
      padding2                          : Sample(2),
      incrementalRefreshOrderBookGroups : IncrementalRefreshOrderBookGroups ]

EncodeMdIncrementalRefreshOrderBook(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshOrderBookGroups(message.incrementalRefreshOrderBookGroups)

DecodeMdIncrementalRefreshOrderBook(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshOrderBookGroups == DecodeIncrementalRefreshOrderBookGroups(padding2.rest) IN IF ~incrementalRefreshOrderBookGroups.ok THEN Fail ELSE
    Ok([ transactTime                      |-> transactTime.value,
         matchEventIndicator               |-> matchEventIndicator.value,
         padding2                          |-> padding2.value,
         incrementalRefreshOrderBookGroups |-> incrementalRefreshOrderBookGroups.value ], incrementalRefreshOrderBookGroups.rest)

ZeroMdIncrementalRefreshOrderBook ==
    [ transactTime                      |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator               |-> [i \in 1 .. 1 |-> 0],
      padding2                          |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshOrderBookGroups |-> ZeroIncrementalRefreshOrderBookGroups ]

(* Md Incremental Refresh Order Book at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshOrderBook ==
    { ZeroMdIncrementalRefreshOrderBook }
        \cup { [ZeroMdIncrementalRefreshOrderBook EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshOrderBook EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshOrderBook EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshOrderBook EXCEPT !.incrementalRefreshOrderBookGroups = one] : one \in CheckedIncrementalRefreshOrderBookGroups }

(***************************************************************************)
(* Incremental Refresh Trade Summary Group: 32 bytes                       *)
(***************************************************************************)

IncrementalRefreshTradeSummaryGroup ==
    [ mdEntryPxEx      : Sample(8),
      mdEntrySizeShort : Sample(4),
      securityId       : Sample(4),
      rptSeq           : Sample(4),
      numberOfOrders   : Sample(4),
      aggressorSide    : Sample(1),
      mdUpdateAction   : Sample(1),
      mdTradeEntryId   : Sample(4),
      padding2         : Sample(2) ]

EncodeIncrementalRefreshTradeSummaryGroup(message) ==
    message.mdEntryPxEx
        \o message.mdEntrySizeShort
        \o message.securityId
        \o message.rptSeq
        \o message.numberOfOrders
        \o message.aggressorSide
        \o message.mdUpdateAction
        \o message.mdTradeEntryId
        \o message.padding2

DecodeIncrementalRefreshTradeSummaryGroup(bytes) ==
    LET mdEntryPxEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxEx.ok THEN Fail ELSE
    LET mdEntrySizeShort == ReadBytes(mdEntryPxEx.rest, 4) IN IF ~mdEntrySizeShort.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntrySizeShort.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(rptSeq.rest, 4) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET aggressorSide == ReadBytes(numberOfOrders.rest, 1) IN IF ~aggressorSide.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(aggressorSide.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdTradeEntryId == ReadBytes(mdUpdateAction.rest, 4) IN IF ~mdTradeEntryId.ok THEN Fail ELSE
    LET padding2 == ReadBytes(mdTradeEntryId.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    Ok([ mdEntryPxEx      |-> mdEntryPxEx.value,
         mdEntrySizeShort |-> mdEntrySizeShort.value,
         securityId       |-> securityId.value,
         rptSeq           |-> rptSeq.value,
         numberOfOrders   |-> numberOfOrders.value,
         aggressorSide    |-> aggressorSide.value,
         mdUpdateAction   |-> mdUpdateAction.value,
         mdTradeEntryId   |-> mdTradeEntryId.value,
         padding2         |-> padding2.value ], padding2.rest)

ZeroIncrementalRefreshTradeSummaryGroup ==
    [ mdEntryPxEx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeShort |-> [i \in 1 .. 4 |-> 0],
      securityId       |-> [i \in 1 .. 4 |-> 0],
      rptSeq           |-> [i \in 1 .. 4 |-> 0],
      numberOfOrders   |-> [i \in 1 .. 4 |-> 0],
      aggressorSide    |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction   |-> [i \in 1 .. 1 |-> 0],
      mdTradeEntryId   |-> [i \in 1 .. 4 |-> 0],
      padding2         |-> [i \in 1 .. 2 |-> 0] ]

(* Incremental Refresh Trade Summary Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTradeSummaryGroup ==
    { ZeroIncrementalRefreshTradeSummaryGroup }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.mdEntryPxEx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.mdEntrySizeShort = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.numberOfOrders = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.aggressorSide = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.mdTradeEntryId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroup EXCEPT !.padding2 = one] : one \in Sample(2) }

(* A run of Incremental Refresh Trade Summary Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshTradeSummaryGroupList(_)
EncodeIncrementalRefreshTradeSummaryGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshTradeSummaryGroup(Head(messages)) \o EncodeIncrementalRefreshTradeSummaryGroupList(Tail(messages))

(* As many Incremental Refresh Trade Summary Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshTradeSummaryGroupList(_, _)
ReadIncrementalRefreshTradeSummaryGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshTradeSummaryGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshTradeSummaryGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Trade Summary Group of each kind, for the lists that carry them *)
OneIncrementalRefreshTradeSummaryGroup == { ZeroIncrementalRefreshTradeSummaryGroup }

(***************************************************************************)
(* Incremental Refresh Trade Summary Groups                                *)
(***************************************************************************)

IncrementalRefreshTradeSummaryGroups ==
    [ blockLength                         : Sample(2),
      incrementalRefreshTradeSummaryGroup : SampleLists(OneIncrementalRefreshTradeSummaryGroup) ]

EncodeIncrementalRefreshTradeSummaryGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshTradeSummaryGroup), 1)
        \o EncodeIncrementalRefreshTradeSummaryGroupList(message.incrementalRefreshTradeSummaryGroup)

DecodeIncrementalRefreshTradeSummaryGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshTradeSummaryGroup == ReadIncrementalRefreshTradeSummaryGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshTradeSummaryGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         incrementalRefreshTradeSummaryGroup |-> incrementalRefreshTradeSummaryGroup.value ], incrementalRefreshTradeSummaryGroup.rest)

ZeroIncrementalRefreshTradeSummaryGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshTradeSummaryGroup |-> << >> ]

(* Incremental Refresh Trade Summary Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTradeSummaryGroups ==
    { ZeroIncrementalRefreshTradeSummaryGroups }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshTradeSummaryGroups EXCEPT !.incrementalRefreshTradeSummaryGroup = one] : one \in SampleLists(OneIncrementalRefreshTradeSummaryGroup) }

(***************************************************************************)
(* Incremental Refresh Trade Summary Order Id Group: 16 bytes              *)
(***************************************************************************)

IncrementalRefreshTradeSummaryOrderIdGroup ==
    [ orderId  : Sample(8),
      lastQty  : Sample(4),
      padding4 : Sample(4) ]

EncodeIncrementalRefreshTradeSummaryOrderIdGroup(message) ==
    message.orderId
        \o message.lastQty
        \o message.padding4

DecodeIncrementalRefreshTradeSummaryOrderIdGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(orderId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET padding4 == ReadBytes(lastQty.rest, 4) IN IF ~padding4.ok THEN Fail ELSE
    Ok([ orderId  |-> orderId.value,
         lastQty  |-> lastQty.value,
         padding4 |-> padding4.value ], padding4.rest)

ZeroIncrementalRefreshTradeSummaryOrderIdGroup ==
    [ orderId  |-> [i \in 1 .. 8 |-> 0],
      lastQty  |-> [i \in 1 .. 4 |-> 0],
      padding4 |-> [i \in 1 .. 4 |-> 0] ]

(* Incremental Refresh Trade Summary Order Id Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTradeSummaryOrderIdGroup ==
    { ZeroIncrementalRefreshTradeSummaryOrderIdGroup }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroup EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroup EXCEPT !.padding4 = one] : one \in Sample(4) }

(* A run of Incremental Refresh Trade Summary Order Id Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshTradeSummaryOrderIdGroupList(_)
EncodeIncrementalRefreshTradeSummaryOrderIdGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshTradeSummaryOrderIdGroup(Head(messages)) \o EncodeIncrementalRefreshTradeSummaryOrderIdGroupList(Tail(messages))

(* As many Incremental Refresh Trade Summary Order Id Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshTradeSummaryOrderIdGroupList(_, _)
ReadIncrementalRefreshTradeSummaryOrderIdGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshTradeSummaryOrderIdGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshTradeSummaryOrderIdGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Trade Summary Order Id Group of each kind, for the lists that carry them *)
OneIncrementalRefreshTradeSummaryOrderIdGroup == { ZeroIncrementalRefreshTradeSummaryOrderIdGroup }

(***************************************************************************)
(* Incremental Refresh Trade Summary Order Id Groups                       *)
(***************************************************************************)

IncrementalRefreshTradeSummaryOrderIdGroups ==
    [ blockLength                                : Sample(2),
      padding5                                   : Sample(5),
      incrementalRefreshTradeSummaryOrderIdGroup : SampleLists(OneIncrementalRefreshTradeSummaryOrderIdGroup) ]

EncodeIncrementalRefreshTradeSummaryOrderIdGroups(message) ==
    message.blockLength
        \o message.padding5
        \o EncodeUIntBE(Len(message.incrementalRefreshTradeSummaryOrderIdGroup), 1)
        \o EncodeIncrementalRefreshTradeSummaryOrderIdGroupList(message.incrementalRefreshTradeSummaryOrderIdGroup)

DecodeIncrementalRefreshTradeSummaryOrderIdGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET padding5 == ReadBytes(blockLength.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(padding5.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshTradeSummaryOrderIdGroup == ReadIncrementalRefreshTradeSummaryOrderIdGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshTradeSummaryOrderIdGroup.ok THEN Fail ELSE
    Ok([ blockLength                                |-> blockLength.value,
         padding5                                   |-> padding5.value,
         incrementalRefreshTradeSummaryOrderIdGroup |-> incrementalRefreshTradeSummaryOrderIdGroup.value ], incrementalRefreshTradeSummaryOrderIdGroup.rest)

ZeroIncrementalRefreshTradeSummaryOrderIdGroups ==
    [ blockLength                                |-> [i \in 1 .. 2 |-> 0],
      padding5                                   |-> [i \in 1 .. 5 |-> 0],
      incrementalRefreshTradeSummaryOrderIdGroup |-> << >> ]

(* Incremental Refresh Trade Summary Order Id Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshTradeSummaryOrderIdGroups ==
    { ZeroIncrementalRefreshTradeSummaryOrderIdGroups }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroups EXCEPT !.padding5 = one] : one \in Sample(5) }
        \cup { [ZeroIncrementalRefreshTradeSummaryOrderIdGroups EXCEPT !.incrementalRefreshTradeSummaryOrderIdGroup = one] : one \in SampleLists(OneIncrementalRefreshTradeSummaryOrderIdGroup) }

(***************************************************************************)
(* Md Incremental Refresh Trade Summary                                    *)
(***************************************************************************)

MdIncrementalRefreshTradeSummary ==
    [ transactTime                                : Sample(8),
      matchEventIndicator                         : Sample(1),
      padding2                                    : Sample(2),
      incrementalRefreshTradeSummaryGroups        : IncrementalRefreshTradeSummaryGroups,
      incrementalRefreshTradeSummaryOrderIdGroups : IncrementalRefreshTradeSummaryOrderIdGroups ]

EncodeMdIncrementalRefreshTradeSummary(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshTradeSummaryGroups(message.incrementalRefreshTradeSummaryGroups)
        \o EncodeIncrementalRefreshTradeSummaryOrderIdGroups(message.incrementalRefreshTradeSummaryOrderIdGroups)

DecodeMdIncrementalRefreshTradeSummary(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshTradeSummaryGroups == DecodeIncrementalRefreshTradeSummaryGroups(padding2.rest) IN IF ~incrementalRefreshTradeSummaryGroups.ok THEN Fail ELSE
    LET incrementalRefreshTradeSummaryOrderIdGroups == DecodeIncrementalRefreshTradeSummaryOrderIdGroups(incrementalRefreshTradeSummaryGroups.rest) IN IF ~incrementalRefreshTradeSummaryOrderIdGroups.ok THEN Fail ELSE
    Ok([ transactTime                                |-> transactTime.value,
         matchEventIndicator                         |-> matchEventIndicator.value,
         padding2                                    |-> padding2.value,
         incrementalRefreshTradeSummaryGroups        |-> incrementalRefreshTradeSummaryGroups.value,
         incrementalRefreshTradeSummaryOrderIdGroups |-> incrementalRefreshTradeSummaryOrderIdGroups.value ], incrementalRefreshTradeSummaryOrderIdGroups.rest)

ZeroMdIncrementalRefreshTradeSummary ==
    [ transactTime                                |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator                         |-> [i \in 1 .. 1 |-> 0],
      padding2                                    |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshTradeSummaryGroups        |-> ZeroIncrementalRefreshTradeSummaryGroups,
      incrementalRefreshTradeSummaryOrderIdGroups |-> ZeroIncrementalRefreshTradeSummaryOrderIdGroups ]

(* Md Incremental Refresh Trade Summary at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshTradeSummary ==
    { ZeroMdIncrementalRefreshTradeSummary }
        \cup { [ZeroMdIncrementalRefreshTradeSummary EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshTradeSummary EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshTradeSummary EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshTradeSummary EXCEPT !.incrementalRefreshTradeSummaryGroups = one] : one \in CheckedIncrementalRefreshTradeSummaryGroups }
        \cup { [ZeroMdIncrementalRefreshTradeSummary EXCEPT !.incrementalRefreshTradeSummaryOrderIdGroups = one] : one \in CheckedIncrementalRefreshTradeSummaryOrderIdGroups }

(***************************************************************************)
(* Incremental Refresh Daily Statistics Group: 32 bytes                    *)
(***************************************************************************)

IncrementalRefreshDailyStatisticsGroup ==
    [ mdEntryPxOptionalEx        : Sample(8),
      mdEntrySizeShortOptional   : Sample(4),
      securityId                 : Sample(4),
      rptSeq                     : Sample(4),
      tradingReferenceDate       : Sample(2),
      settlPriceType             : Sample(1),
      mdUpdateAction             : Sample(1),
      mdEntryTypeDailyStatistics : Sample(1),
      padding7                   : Sample(7) ]

EncodeIncrementalRefreshDailyStatisticsGroup(message) ==
    message.mdEntryPxOptionalEx
        \o message.mdEntrySizeShortOptional
        \o message.securityId
        \o message.rptSeq
        \o message.tradingReferenceDate
        \o message.settlPriceType
        \o message.mdUpdateAction
        \o message.mdEntryTypeDailyStatistics
        \o message.padding7

DecodeIncrementalRefreshDailyStatisticsGroup(bytes) ==
    LET mdEntryPxOptionalEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET mdEntrySizeShortOptional == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~mdEntrySizeShortOptional.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntrySizeShortOptional.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(rptSeq.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(tradingReferenceDate.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(settlPriceType.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryTypeDailyStatistics == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryTypeDailyStatistics.ok THEN Fail ELSE
    LET padding7 == ReadBytes(mdEntryTypeDailyStatistics.rest, 7) IN IF ~padding7.ok THEN Fail ELSE
    Ok([ mdEntryPxOptionalEx        |-> mdEntryPxOptionalEx.value,
         mdEntrySizeShortOptional   |-> mdEntrySizeShortOptional.value,
         securityId                 |-> securityId.value,
         rptSeq                     |-> rptSeq.value,
         tradingReferenceDate       |-> tradingReferenceDate.value,
         settlPriceType             |-> settlPriceType.value,
         mdUpdateAction             |-> mdUpdateAction.value,
         mdEntryTypeDailyStatistics |-> mdEntryTypeDailyStatistics.value,
         padding7                   |-> padding7.value ], padding7.rest)

ZeroIncrementalRefreshDailyStatisticsGroup ==
    [ mdEntryPxOptionalEx        |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeShortOptional   |-> [i \in 1 .. 4 |-> 0],
      securityId                 |-> [i \in 1 .. 4 |-> 0],
      rptSeq                     |-> [i \in 1 .. 4 |-> 0],
      tradingReferenceDate       |-> [i \in 1 .. 2 |-> 0],
      settlPriceType             |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction             |-> [i \in 1 .. 1 |-> 0],
      mdEntryTypeDailyStatistics |-> [i \in 1 .. 1 |-> 0],
      padding7                   |-> [i \in 1 .. 7 |-> 0] ]

(* Incremental Refresh Daily Statistics Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshDailyStatisticsGroup ==
    { ZeroIncrementalRefreshDailyStatisticsGroup }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.mdEntrySizeShortOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.mdEntryTypeDailyStatistics = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroup EXCEPT !.padding7 = one] : one \in Sample(7) }

(* A run of Incremental Refresh Daily Statistics Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshDailyStatisticsGroupList(_)
EncodeIncrementalRefreshDailyStatisticsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshDailyStatisticsGroup(Head(messages)) \o EncodeIncrementalRefreshDailyStatisticsGroupList(Tail(messages))

(* As many Incremental Refresh Daily Statistics Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshDailyStatisticsGroupList(_, _)
ReadIncrementalRefreshDailyStatisticsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshDailyStatisticsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshDailyStatisticsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Daily Statistics Group of each kind, for the lists that carry them *)
OneIncrementalRefreshDailyStatisticsGroup == { ZeroIncrementalRefreshDailyStatisticsGroup }

(***************************************************************************)
(* Incremental Refresh Daily Statistics Groups                             *)
(***************************************************************************)

IncrementalRefreshDailyStatisticsGroups ==
    [ blockLength                            : Sample(2),
      incrementalRefreshDailyStatisticsGroup : SampleLists(OneIncrementalRefreshDailyStatisticsGroup) ]

EncodeIncrementalRefreshDailyStatisticsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshDailyStatisticsGroup), 1)
        \o EncodeIncrementalRefreshDailyStatisticsGroupList(message.incrementalRefreshDailyStatisticsGroup)

DecodeIncrementalRefreshDailyStatisticsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshDailyStatisticsGroup == ReadIncrementalRefreshDailyStatisticsGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshDailyStatisticsGroup.ok THEN Fail ELSE
    Ok([ blockLength                            |-> blockLength.value,
         incrementalRefreshDailyStatisticsGroup |-> incrementalRefreshDailyStatisticsGroup.value ], incrementalRefreshDailyStatisticsGroup.rest)

ZeroIncrementalRefreshDailyStatisticsGroups ==
    [ blockLength                            |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshDailyStatisticsGroup |-> << >> ]

(* Incremental Refresh Daily Statistics Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshDailyStatisticsGroups ==
    { ZeroIncrementalRefreshDailyStatisticsGroups }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshDailyStatisticsGroups EXCEPT !.incrementalRefreshDailyStatisticsGroup = one] : one \in SampleLists(OneIncrementalRefreshDailyStatisticsGroup) }

(***************************************************************************)
(* Md Incremental Refresh Daily Statistics                                 *)
(***************************************************************************)

MdIncrementalRefreshDailyStatistics ==
    [ transactTime                            : Sample(8),
      matchEventIndicator                     : Sample(1),
      padding2                                : Sample(2),
      incrementalRefreshDailyStatisticsGroups : IncrementalRefreshDailyStatisticsGroups ]

EncodeMdIncrementalRefreshDailyStatistics(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshDailyStatisticsGroups(message.incrementalRefreshDailyStatisticsGroups)

DecodeMdIncrementalRefreshDailyStatistics(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshDailyStatisticsGroups == DecodeIncrementalRefreshDailyStatisticsGroups(padding2.rest) IN IF ~incrementalRefreshDailyStatisticsGroups.ok THEN Fail ELSE
    Ok([ transactTime                            |-> transactTime.value,
         matchEventIndicator                     |-> matchEventIndicator.value,
         padding2                                |-> padding2.value,
         incrementalRefreshDailyStatisticsGroups |-> incrementalRefreshDailyStatisticsGroups.value ], incrementalRefreshDailyStatisticsGroups.rest)

ZeroMdIncrementalRefreshDailyStatistics ==
    [ transactTime                            |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator                     |-> [i \in 1 .. 1 |-> 0],
      padding2                                |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshDailyStatisticsGroups |-> ZeroIncrementalRefreshDailyStatisticsGroups ]

(* Md Incremental Refresh Daily Statistics at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshDailyStatistics ==
    { ZeroMdIncrementalRefreshDailyStatistics }
        \cup { [ZeroMdIncrementalRefreshDailyStatistics EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshDailyStatistics EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshDailyStatistics EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshDailyStatistics EXCEPT !.incrementalRefreshDailyStatisticsGroups = one] : one \in CheckedIncrementalRefreshDailyStatisticsGroups }

(***************************************************************************)
(* Incremental Refresh Limits Banding Group: 32 bytes                      *)
(***************************************************************************)

IncrementalRefreshLimitsBandingGroup ==
    [ highLimitPrice    : Sample(8),
      lowLimitPrice     : Sample(8),
      maxPriceVariation : Sample(8),
      securityId        : Sample(4),
      rptSeq            : Sample(4) ]

EncodeIncrementalRefreshLimitsBandingGroup(message) ==
    message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o message.securityId
        \o message.rptSeq

DecodeIncrementalRefreshLimitsBandingGroup(bytes) ==
    LET highLimitPrice == ReadBytes(bytes, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET securityId == ReadBytes(maxPriceVariation.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    Ok([ highLimitPrice    |-> highLimitPrice.value,
         lowLimitPrice     |-> lowLimitPrice.value,
         maxPriceVariation |-> maxPriceVariation.value,
         securityId        |-> securityId.value,
         rptSeq            |-> rptSeq.value ], rptSeq.rest)

ZeroIncrementalRefreshLimitsBandingGroup ==
    [ highLimitPrice    |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice     |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation |-> [i \in 1 .. 8 |-> 0],
      securityId        |-> [i \in 1 .. 4 |-> 0],
      rptSeq            |-> [i \in 1 .. 4 |-> 0] ]

(* Incremental Refresh Limits Banding Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshLimitsBandingGroup ==
    { ZeroIncrementalRefreshLimitsBandingGroup }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroup EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroup EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroup EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }

(* A run of Incremental Refresh Limits Banding Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshLimitsBandingGroupList(_)
EncodeIncrementalRefreshLimitsBandingGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshLimitsBandingGroup(Head(messages)) \o EncodeIncrementalRefreshLimitsBandingGroupList(Tail(messages))

(* As many Incremental Refresh Limits Banding Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshLimitsBandingGroupList(_, _)
ReadIncrementalRefreshLimitsBandingGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshLimitsBandingGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshLimitsBandingGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Limits Banding Group of each kind, for the lists that carry them *)
OneIncrementalRefreshLimitsBandingGroup == { ZeroIncrementalRefreshLimitsBandingGroup }

(***************************************************************************)
(* Incremental Refresh Limits Banding Groups                               *)
(***************************************************************************)

IncrementalRefreshLimitsBandingGroups ==
    [ blockLength                          : Sample(2),
      incrementalRefreshLimitsBandingGroup : SampleLists(OneIncrementalRefreshLimitsBandingGroup) ]

EncodeIncrementalRefreshLimitsBandingGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshLimitsBandingGroup), 1)
        \o EncodeIncrementalRefreshLimitsBandingGroupList(message.incrementalRefreshLimitsBandingGroup)

DecodeIncrementalRefreshLimitsBandingGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshLimitsBandingGroup == ReadIncrementalRefreshLimitsBandingGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshLimitsBandingGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         incrementalRefreshLimitsBandingGroup |-> incrementalRefreshLimitsBandingGroup.value ], incrementalRefreshLimitsBandingGroup.rest)

ZeroIncrementalRefreshLimitsBandingGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshLimitsBandingGroup |-> << >> ]

(* Incremental Refresh Limits Banding Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshLimitsBandingGroups ==
    { ZeroIncrementalRefreshLimitsBandingGroups }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshLimitsBandingGroups EXCEPT !.incrementalRefreshLimitsBandingGroup = one] : one \in SampleLists(OneIncrementalRefreshLimitsBandingGroup) }

(***************************************************************************)
(* Md Incremental Refresh Limits Banding                                   *)
(***************************************************************************)

MdIncrementalRefreshLimitsBanding ==
    [ transactTime                          : Sample(8),
      matchEventIndicator                   : Sample(1),
      padding2                              : Sample(2),
      incrementalRefreshLimitsBandingGroups : IncrementalRefreshLimitsBandingGroups ]

EncodeMdIncrementalRefreshLimitsBanding(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshLimitsBandingGroups(message.incrementalRefreshLimitsBandingGroups)

DecodeMdIncrementalRefreshLimitsBanding(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshLimitsBandingGroups == DecodeIncrementalRefreshLimitsBandingGroups(padding2.rest) IN IF ~incrementalRefreshLimitsBandingGroups.ok THEN Fail ELSE
    Ok([ transactTime                          |-> transactTime.value,
         matchEventIndicator                   |-> matchEventIndicator.value,
         padding2                              |-> padding2.value,
         incrementalRefreshLimitsBandingGroups |-> incrementalRefreshLimitsBandingGroups.value ], incrementalRefreshLimitsBandingGroups.rest)

ZeroMdIncrementalRefreshLimitsBanding ==
    [ transactTime                          |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator                   |-> [i \in 1 .. 1 |-> 0],
      padding2                              |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshLimitsBandingGroups |-> ZeroIncrementalRefreshLimitsBandingGroups ]

(* Md Incremental Refresh Limits Banding at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshLimitsBanding ==
    { ZeroMdIncrementalRefreshLimitsBanding }
        \cup { [ZeroMdIncrementalRefreshLimitsBanding EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshLimitsBanding EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshLimitsBanding EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshLimitsBanding EXCEPT !.incrementalRefreshLimitsBandingGroups = one] : one \in CheckedIncrementalRefreshLimitsBandingGroups }

(***************************************************************************)
(* Incremental Refresh Session Statistics Group: 24 bytes                  *)
(***************************************************************************)

IncrementalRefreshSessionStatisticsGroup ==
    [ mdEntryPxEx              : Sample(8),
      securityId               : Sample(4),
      rptSeq                   : Sample(4),
      openCloseSettlFlag       : Sample(1),
      mdUpdateAction           : Sample(1),
      mdEntryTypeStatistics    : Sample(1),
      mdEntrySizeShortOptional : Sample(4),
      padding1                 : Sample(1) ]

EncodeIncrementalRefreshSessionStatisticsGroup(message) ==
    message.mdEntryPxEx
        \o message.securityId
        \o message.rptSeq
        \o message.openCloseSettlFlag
        \o message.mdUpdateAction
        \o message.mdEntryTypeStatistics
        \o message.mdEntrySizeShortOptional
        \o message.padding1

DecodeIncrementalRefreshSessionStatisticsGroup(bytes) ==
    LET mdEntryPxEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxEx.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntryPxEx.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(rptSeq.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET mdUpdateAction == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~mdUpdateAction.ok THEN Fail ELSE
    LET mdEntryTypeStatistics == ReadBytes(mdUpdateAction.rest, 1) IN IF ~mdEntryTypeStatistics.ok THEN Fail ELSE
    LET mdEntrySizeShortOptional == ReadBytes(mdEntryTypeStatistics.rest, 4) IN IF ~mdEntrySizeShortOptional.ok THEN Fail ELSE
    LET padding1 == ReadBytes(mdEntrySizeShortOptional.rest, 1) IN IF ~padding1.ok THEN Fail ELSE
    Ok([ mdEntryPxEx              |-> mdEntryPxEx.value,
         securityId               |-> securityId.value,
         rptSeq                   |-> rptSeq.value,
         openCloseSettlFlag       |-> openCloseSettlFlag.value,
         mdUpdateAction           |-> mdUpdateAction.value,
         mdEntryTypeStatistics    |-> mdEntryTypeStatistics.value,
         mdEntrySizeShortOptional |-> mdEntrySizeShortOptional.value,
         padding1                 |-> padding1.value ], padding1.rest)

ZeroIncrementalRefreshSessionStatisticsGroup ==
    [ mdEntryPxEx              |-> [i \in 1 .. 8 |-> 0],
      securityId               |-> [i \in 1 .. 4 |-> 0],
      rptSeq                   |-> [i \in 1 .. 4 |-> 0],
      openCloseSettlFlag       |-> [i \in 1 .. 1 |-> 0],
      mdUpdateAction           |-> [i \in 1 .. 1 |-> 0],
      mdEntryTypeStatistics    |-> [i \in 1 .. 1 |-> 0],
      mdEntrySizeShortOptional |-> [i \in 1 .. 4 |-> 0],
      padding1                 |-> [i \in 1 .. 1 |-> 0] ]

(* Incremental Refresh Session Statistics Group at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSessionStatisticsGroup ==
    { ZeroIncrementalRefreshSessionStatisticsGroup }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.mdEntryPxEx = one] : one \in Sample(8) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.mdUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.mdEntryTypeStatistics = one] : one \in Sample(1) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.mdEntrySizeShortOptional = one] : one \in Sample(4) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroup EXCEPT !.padding1 = one] : one \in Sample(1) }

(* A run of Incremental Refresh Session Statistics Group, written one after another *)
RECURSIVE EncodeIncrementalRefreshSessionStatisticsGroupList(_)
EncodeIncrementalRefreshSessionStatisticsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIncrementalRefreshSessionStatisticsGroup(Head(messages)) \o EncodeIncrementalRefreshSessionStatisticsGroupList(Tail(messages))

(* As many Incremental Refresh Session Statistics Group as the field that counts them says *)
RECURSIVE ReadIncrementalRefreshSessionStatisticsGroupList(_, _)
ReadIncrementalRefreshSessionStatisticsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIncrementalRefreshSessionStatisticsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIncrementalRefreshSessionStatisticsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Incremental Refresh Session Statistics Group of each kind, for the lists that carry them *)
OneIncrementalRefreshSessionStatisticsGroup == { ZeroIncrementalRefreshSessionStatisticsGroup }

(***************************************************************************)
(* Incremental Refresh Session Statistics Groups                           *)
(***************************************************************************)

IncrementalRefreshSessionStatisticsGroups ==
    [ blockLength                              : Sample(2),
      incrementalRefreshSessionStatisticsGroup : SampleLists(OneIncrementalRefreshSessionStatisticsGroup) ]

EncodeIncrementalRefreshSessionStatisticsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.incrementalRefreshSessionStatisticsGroup), 1)
        \o EncodeIncrementalRefreshSessionStatisticsGroupList(message.incrementalRefreshSessionStatisticsGroup)

DecodeIncrementalRefreshSessionStatisticsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET incrementalRefreshSessionStatisticsGroup == ReadIncrementalRefreshSessionStatisticsGroupList(numInGroup.rest, numInGroup.value) IN IF ~incrementalRefreshSessionStatisticsGroup.ok THEN Fail ELSE
    Ok([ blockLength                              |-> blockLength.value,
         incrementalRefreshSessionStatisticsGroup |-> incrementalRefreshSessionStatisticsGroup.value ], incrementalRefreshSessionStatisticsGroup.rest)

ZeroIncrementalRefreshSessionStatisticsGroups ==
    [ blockLength                              |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshSessionStatisticsGroup |-> << >> ]

(* Incremental Refresh Session Statistics Groups at zero, then each field in turn at the values it is checked at *)
CheckedIncrementalRefreshSessionStatisticsGroups ==
    { ZeroIncrementalRefreshSessionStatisticsGroups }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroIncrementalRefreshSessionStatisticsGroups EXCEPT !.incrementalRefreshSessionStatisticsGroup = one] : one \in SampleLists(OneIncrementalRefreshSessionStatisticsGroup) }

(***************************************************************************)
(* Md Incremental Refresh Session Statistics                               *)
(***************************************************************************)

MdIncrementalRefreshSessionStatistics ==
    [ transactTime                              : Sample(8),
      matchEventIndicator                       : Sample(1),
      padding2                                  : Sample(2),
      incrementalRefreshSessionStatisticsGroups : IncrementalRefreshSessionStatisticsGroups ]

EncodeMdIncrementalRefreshSessionStatistics(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeIncrementalRefreshSessionStatisticsGroups(message.incrementalRefreshSessionStatisticsGroups)

DecodeMdIncrementalRefreshSessionStatistics(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET incrementalRefreshSessionStatisticsGroups == DecodeIncrementalRefreshSessionStatisticsGroups(padding2.rest) IN IF ~incrementalRefreshSessionStatisticsGroups.ok THEN Fail ELSE
    Ok([ transactTime                              |-> transactTime.value,
         matchEventIndicator                       |-> matchEventIndicator.value,
         padding2                                  |-> padding2.value,
         incrementalRefreshSessionStatisticsGroups |-> incrementalRefreshSessionStatisticsGroups.value ], incrementalRefreshSessionStatisticsGroups.rest)

ZeroMdIncrementalRefreshSessionStatistics ==
    [ transactTime                              |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator                       |-> [i \in 1 .. 1 |-> 0],
      padding2                                  |-> [i \in 1 .. 2 |-> 0],
      incrementalRefreshSessionStatisticsGroups |-> ZeroIncrementalRefreshSessionStatisticsGroups ]

(* Md Incremental Refresh Session Statistics at zero, then each field in turn at the values it is checked at *)
CheckedMdIncrementalRefreshSessionStatistics ==
    { ZeroMdIncrementalRefreshSessionStatistics }
        \cup { [ZeroMdIncrementalRefreshSessionStatistics EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdIncrementalRefreshSessionStatistics EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdIncrementalRefreshSessionStatistics EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroMdIncrementalRefreshSessionStatistics EXCEPT !.incrementalRefreshSessionStatisticsGroups = one] : one \in CheckedIncrementalRefreshSessionStatisticsGroups }

(***************************************************************************)
(* Snapshot Full Refresh Group: 22 bytes                                   *)
(***************************************************************************)

SnapshotFullRefreshGroup ==
    [ mdEntryPxOptionalEx      : Sample(8),
      mdEntrySizeShortOptional : Sample(4),
      numberOfOrdersOptional   : Sample(4),
      mdPriceLevelOptional     : Sample(1),
      tradingReferenceDate     : Sample(2),
      openCloseSettlFlag       : Sample(1),
      settlPriceType           : Sample(1),
      mdEntryType              : Sample(1) ]

EncodeSnapshotFullRefreshGroup(message) ==
    message.mdEntryPxOptionalEx
        \o message.mdEntrySizeShortOptional
        \o message.numberOfOrdersOptional
        \o message.mdPriceLevelOptional
        \o message.tradingReferenceDate
        \o message.openCloseSettlFlag
        \o message.settlPriceType
        \o message.mdEntryType

DecodeSnapshotFullRefreshGroup(bytes) ==
    LET mdEntryPxOptionalEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET mdEntrySizeShortOptional == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~mdEntrySizeShortOptional.ok THEN Fail ELSE
    LET numberOfOrdersOptional == ReadBytes(mdEntrySizeShortOptional.rest, 4) IN IF ~numberOfOrdersOptional.ok THEN Fail ELSE
    LET mdPriceLevelOptional == ReadBytes(numberOfOrdersOptional.rest, 1) IN IF ~mdPriceLevelOptional.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(mdPriceLevelOptional.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(tradingReferenceDate.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(settlPriceType.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    Ok([ mdEntryPxOptionalEx      |-> mdEntryPxOptionalEx.value,
         mdEntrySizeShortOptional |-> mdEntrySizeShortOptional.value,
         numberOfOrdersOptional   |-> numberOfOrdersOptional.value,
         mdPriceLevelOptional     |-> mdPriceLevelOptional.value,
         tradingReferenceDate     |-> tradingReferenceDate.value,
         openCloseSettlFlag       |-> openCloseSettlFlag.value,
         settlPriceType           |-> settlPriceType.value,
         mdEntryType              |-> mdEntryType.value ], mdEntryType.rest)

ZeroSnapshotFullRefreshGroup ==
    [ mdEntryPxOptionalEx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeShortOptional |-> [i \in 1 .. 4 |-> 0],
      numberOfOrdersOptional   |-> [i \in 1 .. 4 |-> 0],
      mdPriceLevelOptional     |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate     |-> [i \in 1 .. 2 |-> 0],
      openCloseSettlFlag       |-> [i \in 1 .. 1 |-> 0],
      settlPriceType           |-> [i \in 1 .. 1 |-> 0],
      mdEntryType              |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Full Refresh Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshGroup ==
    { ZeroSnapshotFullRefreshGroup }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.mdEntrySizeShortOptional = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.numberOfOrdersOptional = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.mdPriceLevelOptional = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }

(* A run of Snapshot Full Refresh Group, written one after another *)
RECURSIVE EncodeSnapshotFullRefreshGroupList(_)
EncodeSnapshotFullRefreshGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotFullRefreshGroup(Head(messages)) \o EncodeSnapshotFullRefreshGroupList(Tail(messages))

(* As many Snapshot Full Refresh Group as the field that counts them says *)
RECURSIVE ReadSnapshotFullRefreshGroupList(_, _)
ReadSnapshotFullRefreshGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotFullRefreshGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotFullRefreshGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Full Refresh Group of each kind, for the lists that carry them *)
OneSnapshotFullRefreshGroup == { ZeroSnapshotFullRefreshGroup }

(***************************************************************************)
(* Snapshot Full Refresh Groups                                            *)
(***************************************************************************)

SnapshotFullRefreshGroups ==
    [ blockLength              : Sample(2),
      snapshotFullRefreshGroup : SampleLists(OneSnapshotFullRefreshGroup) ]

EncodeSnapshotFullRefreshGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotFullRefreshGroup), 1)
        \o EncodeSnapshotFullRefreshGroupList(message.snapshotFullRefreshGroup)

DecodeSnapshotFullRefreshGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotFullRefreshGroup == ReadSnapshotFullRefreshGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotFullRefreshGroup.ok THEN Fail ELSE
    Ok([ blockLength              |-> blockLength.value,
         snapshotFullRefreshGroup |-> snapshotFullRefreshGroup.value ], snapshotFullRefreshGroup.rest)

ZeroSnapshotFullRefreshGroups ==
    [ blockLength              |-> [i \in 1 .. 2 |-> 0],
      snapshotFullRefreshGroup |-> << >> ]

(* Snapshot Full Refresh Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshGroups ==
    { ZeroSnapshotFullRefreshGroups }
        \cup { [ZeroSnapshotFullRefreshGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshGroups EXCEPT !.snapshotFullRefreshGroup = one] : one \in SampleLists(OneSnapshotFullRefreshGroup) }

(***************************************************************************)
(* Snapshot Full Refresh                                                   *)
(***************************************************************************)

SnapshotFullRefresh ==
    [ lastMsgSeqNumProcessed    : Sample(4),
      totNumReports             : Sample(4),
      securityId                : Sample(4),
      rptSeq                    : Sample(4),
      transactTime              : Sample(8),
      lastUpdateTime            : Sample(8),
      tradeDate                 : Sample(2),
      mdSecurityTradingStatus   : Sample(1),
      highLimitPrice            : Sample(8),
      lowLimitPrice             : Sample(8),
      maxPriceVariation         : Sample(8),
      snapshotFullRefreshGroups : SnapshotFullRefreshGroups ]

EncodeSnapshotFullRefresh(message) ==
    message.lastMsgSeqNumProcessed
        \o message.totNumReports
        \o message.securityId
        \o message.rptSeq
        \o message.transactTime
        \o message.lastUpdateTime
        \o message.tradeDate
        \o message.mdSecurityTradingStatus
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o EncodeSnapshotFullRefreshGroups(message.snapshotFullRefreshGroups)

DecodeSnapshotFullRefresh(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET totNumReports == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~totNumReports.ok THEN Fail ELSE
    LET securityId == ReadBytes(totNumReports.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(securityId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rptSeq.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(transactTime.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(lastUpdateTime.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(tradeDate.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(mdSecurityTradingStatus.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET snapshotFullRefreshGroups == DecodeSnapshotFullRefreshGroups(maxPriceVariation.rest) IN IF ~snapshotFullRefreshGroups.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed    |-> lastMsgSeqNumProcessed.value,
         totNumReports             |-> totNumReports.value,
         securityId                |-> securityId.value,
         rptSeq                    |-> rptSeq.value,
         transactTime              |-> transactTime.value,
         lastUpdateTime            |-> lastUpdateTime.value,
         tradeDate                 |-> tradeDate.value,
         mdSecurityTradingStatus   |-> mdSecurityTradingStatus.value,
         highLimitPrice            |-> highLimitPrice.value,
         lowLimitPrice             |-> lowLimitPrice.value,
         maxPriceVariation         |-> maxPriceVariation.value,
         snapshotFullRefreshGroups |-> snapshotFullRefreshGroups.value ], snapshotFullRefreshGroups.rest)

ZeroSnapshotFullRefresh ==
    [ lastMsgSeqNumProcessed    |-> [i \in 1 .. 4 |-> 0],
      totNumReports             |-> [i \in 1 .. 4 |-> 0],
      securityId                |-> [i \in 1 .. 4 |-> 0],
      rptSeq                    |-> [i \in 1 .. 4 |-> 0],
      transactTime              |-> [i \in 1 .. 8 |-> 0],
      lastUpdateTime            |-> [i \in 1 .. 8 |-> 0],
      tradeDate                 |-> [i \in 1 .. 2 |-> 0],
      mdSecurityTradingStatus   |-> [i \in 1 .. 1 |-> 0],
      highLimitPrice            |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice             |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation         |-> [i \in 1 .. 8 |-> 0],
      snapshotFullRefreshGroups |-> ZeroSnapshotFullRefreshGroups ]

(* Snapshot Full Refresh at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefresh ==
    { ZeroSnapshotFullRefresh }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.totNumReports = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefresh EXCEPT !.snapshotFullRefreshGroups = one] : one \in CheckedSnapshotFullRefreshGroups }

(***************************************************************************)
(* Snapshot Full Refresh Order Book Group: 29 bytes                        *)
(***************************************************************************)

SnapshotFullRefreshOrderBookGroup ==
    [ orderId                 : Sample(8),
      mdOrderPriorityOptional : Sample(8),
      mdEntryPxEx             : Sample(8),
      mdDisplayQty            : Sample(4),
      mdEntryTypeBook         : Sample(1) ]

EncodeSnapshotFullRefreshOrderBookGroup(message) ==
    message.orderId
        \o message.mdOrderPriorityOptional
        \o message.mdEntryPxEx
        \o message.mdDisplayQty
        \o message.mdEntryTypeBook

DecodeSnapshotFullRefreshOrderBookGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET mdOrderPriorityOptional == ReadBytes(orderId.rest, 8) IN IF ~mdOrderPriorityOptional.ok THEN Fail ELSE
    LET mdEntryPxEx == ReadBytes(mdOrderPriorityOptional.rest, 8) IN IF ~mdEntryPxEx.ok THEN Fail ELSE
    LET mdDisplayQty == ReadBytes(mdEntryPxEx.rest, 4) IN IF ~mdDisplayQty.ok THEN Fail ELSE
    LET mdEntryTypeBook == ReadBytes(mdDisplayQty.rest, 1) IN IF ~mdEntryTypeBook.ok THEN Fail ELSE
    Ok([ orderId                 |-> orderId.value,
         mdOrderPriorityOptional |-> mdOrderPriorityOptional.value,
         mdEntryPxEx             |-> mdEntryPxEx.value,
         mdDisplayQty            |-> mdDisplayQty.value,
         mdEntryTypeBook         |-> mdEntryTypeBook.value ], mdEntryTypeBook.rest)

ZeroSnapshotFullRefreshOrderBookGroup ==
    [ orderId                 |-> [i \in 1 .. 8 |-> 0],
      mdOrderPriorityOptional |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxEx             |-> [i \in 1 .. 8 |-> 0],
      mdDisplayQty            |-> [i \in 1 .. 4 |-> 0],
      mdEntryTypeBook         |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Full Refresh Order Book Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrderBookGroup ==
    { ZeroSnapshotFullRefreshOrderBookGroup }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroup EXCEPT !.mdOrderPriorityOptional = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroup EXCEPT !.mdEntryPxEx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroup EXCEPT !.mdDisplayQty = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroup EXCEPT !.mdEntryTypeBook = one] : one \in Sample(1) }

(* A run of Snapshot Full Refresh Order Book Group, written one after another *)
RECURSIVE EncodeSnapshotFullRefreshOrderBookGroupList(_)
EncodeSnapshotFullRefreshOrderBookGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotFullRefreshOrderBookGroup(Head(messages)) \o EncodeSnapshotFullRefreshOrderBookGroupList(Tail(messages))

(* As many Snapshot Full Refresh Order Book Group as the field that counts them says *)
RECURSIVE ReadSnapshotFullRefreshOrderBookGroupList(_, _)
ReadSnapshotFullRefreshOrderBookGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotFullRefreshOrderBookGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotFullRefreshOrderBookGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Full Refresh Order Book Group of each kind, for the lists that carry them *)
OneSnapshotFullRefreshOrderBookGroup == { ZeroSnapshotFullRefreshOrderBookGroup }

(***************************************************************************)
(* Snapshot Full Refresh Order Book Groups                                 *)
(***************************************************************************)

SnapshotFullRefreshOrderBookGroups ==
    [ blockLength                       : Sample(2),
      snapshotFullRefreshOrderBookGroup : SampleLists(OneSnapshotFullRefreshOrderBookGroup) ]

EncodeSnapshotFullRefreshOrderBookGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotFullRefreshOrderBookGroup), 1)
        \o EncodeSnapshotFullRefreshOrderBookGroupList(message.snapshotFullRefreshOrderBookGroup)

DecodeSnapshotFullRefreshOrderBookGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotFullRefreshOrderBookGroup == ReadSnapshotFullRefreshOrderBookGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotFullRefreshOrderBookGroup.ok THEN Fail ELSE
    Ok([ blockLength                       |-> blockLength.value,
         snapshotFullRefreshOrderBookGroup |-> snapshotFullRefreshOrderBookGroup.value ], snapshotFullRefreshOrderBookGroup.rest)

ZeroSnapshotFullRefreshOrderBookGroups ==
    [ blockLength                       |-> [i \in 1 .. 2 |-> 0],
      snapshotFullRefreshOrderBookGroup |-> << >> ]

(* Snapshot Full Refresh Order Book Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrderBookGroups ==
    { ZeroSnapshotFullRefreshOrderBookGroups }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshOrderBookGroups EXCEPT !.snapshotFullRefreshOrderBookGroup = one] : one \in SampleLists(OneSnapshotFullRefreshOrderBookGroup) }

(***************************************************************************)
(* Snapshot Full Refresh Order Book                                        *)
(***************************************************************************)

SnapshotFullRefreshOrderBook ==
    [ lastMsgSeqNumProcessed             : Sample(4),
      totNumReports                      : Sample(4),
      securityId                         : Sample(4),
      noChunks                           : Sample(4),
      currentChunk                       : Sample(4),
      transactTime                       : Sample(8),
      snapshotFullRefreshOrderBookGroups : SnapshotFullRefreshOrderBookGroups ]

EncodeSnapshotFullRefreshOrderBook(message) ==
    message.lastMsgSeqNumProcessed
        \o message.totNumReports
        \o message.securityId
        \o message.noChunks
        \o message.currentChunk
        \o message.transactTime
        \o EncodeSnapshotFullRefreshOrderBookGroups(message.snapshotFullRefreshOrderBookGroups)

DecodeSnapshotFullRefreshOrderBook(bytes) ==
    LET lastMsgSeqNumProcessed == ReadBytes(bytes, 4) IN IF ~lastMsgSeqNumProcessed.ok THEN Fail ELSE
    LET totNumReports == ReadBytes(lastMsgSeqNumProcessed.rest, 4) IN IF ~totNumReports.ok THEN Fail ELSE
    LET securityId == ReadBytes(totNumReports.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET noChunks == ReadBytes(securityId.rest, 4) IN IF ~noChunks.ok THEN Fail ELSE
    LET currentChunk == ReadBytes(noChunks.rest, 4) IN IF ~currentChunk.ok THEN Fail ELSE
    LET transactTime == ReadBytes(currentChunk.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET snapshotFullRefreshOrderBookGroups == DecodeSnapshotFullRefreshOrderBookGroups(transactTime.rest) IN IF ~snapshotFullRefreshOrderBookGroups.ok THEN Fail ELSE
    Ok([ lastMsgSeqNumProcessed             |-> lastMsgSeqNumProcessed.value,
         totNumReports                      |-> totNumReports.value,
         securityId                         |-> securityId.value,
         noChunks                           |-> noChunks.value,
         currentChunk                       |-> currentChunk.value,
         transactTime                       |-> transactTime.value,
         snapshotFullRefreshOrderBookGroups |-> snapshotFullRefreshOrderBookGroups.value ], snapshotFullRefreshOrderBookGroups.rest)

ZeroSnapshotFullRefreshOrderBook ==
    [ lastMsgSeqNumProcessed             |-> [i \in 1 .. 4 |-> 0],
      totNumReports                      |-> [i \in 1 .. 4 |-> 0],
      securityId                         |-> [i \in 1 .. 4 |-> 0],
      noChunks                           |-> [i \in 1 .. 4 |-> 0],
      currentChunk                       |-> [i \in 1 .. 4 |-> 0],
      transactTime                       |-> [i \in 1 .. 8 |-> 0],
      snapshotFullRefreshOrderBookGroups |-> ZeroSnapshotFullRefreshOrderBookGroups ]

(* Snapshot Full Refresh Order Book at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshOrderBook ==
    { ZeroSnapshotFullRefreshOrderBook }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.lastMsgSeqNumProcessed = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.totNumReports = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.noChunks = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.currentChunk = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshOrderBook EXCEPT !.snapshotFullRefreshOrderBookGroups = one] : one \in CheckedSnapshotFullRefreshOrderBookGroups }

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
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup ==
    [ eventType : Sample(1),
      eventTime : Sample(8) ]

EncodeEventsGroup(message) ==
    message.eventType
        \o message.eventTime

DecodeEventsGroup(bytes) ==
    LET eventType == ReadBytes(bytes, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventType.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroEventsGroup ==
    [ eventType |-> [i \in 1 .. 1 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup ==
    { ZeroEventsGroup }
        \cup { [ZeroEventsGroup EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroupList(_)
EncodeEventsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup(Head(messages)) \o EncodeEventsGroupList(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroupList(_, _)
ReadEventsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup == { ZeroEventsGroup }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup) ]

EncodeEventsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroupList(message.eventsGroup)

DecodeEventsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroupList(numInGroup.rest, numInGroup.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups ==
    { ZeroEventsGroups }
        \cup { [ZeroEventsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup) }

(***************************************************************************)
(* Feed Types Group: 4 bytes                                               *)
(***************************************************************************)

FeedTypesGroup ==
    [ mdFeedType  : Sample(3),
      marketDepth : Sample(1) ]

EncodeFeedTypesGroup(message) ==
    message.mdFeedType
        \o message.marketDepth

DecodeFeedTypesGroup(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 3) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroFeedTypesGroup ==
    [ mdFeedType  |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroup ==
    { ZeroFeedTypesGroup }
        \cup { [ZeroFeedTypesGroup EXCEPT !.mdFeedType = one] : one \in Sample(3) }
        \cup { [ZeroFeedTypesGroup EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Feed Types Group, written one after another *)
RECURSIVE EncodeFeedTypesGroupList(_)
EncodeFeedTypesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFeedTypesGroup(Head(messages)) \o EncodeFeedTypesGroupList(Tail(messages))

(* As many Feed Types Group as the field that counts them says *)
RECURSIVE ReadFeedTypesGroupList(_, _)
ReadFeedTypesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFeedTypesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFeedTypesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Feed Types Group of each kind, for the lists that carry them *)
OneFeedTypesGroup == { ZeroFeedTypesGroup }

(***************************************************************************)
(* Feed Types Groups                                                       *)
(***************************************************************************)

FeedTypesGroups ==
    [ blockLength    : Sample(2),
      feedTypesGroup : SampleLists(OneFeedTypesGroup) ]

EncodeFeedTypesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.feedTypesGroup), 1)
        \o EncodeFeedTypesGroupList(message.feedTypesGroup)

DecodeFeedTypesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET feedTypesGroup == ReadFeedTypesGroupList(numInGroup.rest, numInGroup.value) IN IF ~feedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         feedTypesGroup |-> feedTypesGroup.value ], feedTypesGroup.rest)

ZeroFeedTypesGroups ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      feedTypesGroup |-> << >> ]

(* Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroups ==
    { ZeroFeedTypesGroups }
        \cup { [ZeroFeedTypesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFeedTypesGroups EXCEPT !.feedTypesGroup = one] : one \in SampleLists(OneFeedTypesGroup) }

(***************************************************************************)
(* Inst Attrib Group: 4 bytes                                              *)
(***************************************************************************)

InstAttribGroup ==
    [ instAttribValue : Sample(4) ]

EncodeInstAttribGroup(message) ==
    message.instAttribValue

DecodeInstAttribGroup(bytes) ==
    LET instAttribValue == ReadBytes(bytes, 4) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup ==
    [ instAttribValue |-> [i \in 1 .. 4 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup ==
    { ZeroInstAttribGroup }
        \cup { [ZeroInstAttribGroup EXCEPT !.instAttribValue = one] : one \in Sample(4) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroupList(_)
EncodeInstAttribGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup(Head(messages)) \o EncodeInstAttribGroupList(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroupList(_, _)
ReadInstAttribGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup == { ZeroInstAttribGroup }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup) ]

EncodeInstAttribGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instAttribGroup), 1)
        \o EncodeInstAttribGroupList(message.instAttribGroup)

DecodeInstAttribGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroupList(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups ==
    { ZeroInstAttribGroups }
        \cup { [ZeroInstAttribGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup) }

(***************************************************************************)
(* Lot Type Rules Group: 5 bytes                                           *)
(***************************************************************************)

LotTypeRulesGroup ==
    [ lotType    : Sample(1),
      minLotSize : Sample(4) ]

EncodeLotTypeRulesGroup(message) ==
    message.lotType
        \o message.minLotSize

DecodeLotTypeRulesGroup(bytes) ==
    LET lotType == ReadBytes(bytes, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(lotType.rest, 4) IN IF ~minLotSize.ok THEN Fail ELSE
    Ok([ lotType    |-> lotType.value,
         minLotSize |-> minLotSize.value ], minLotSize.rest)

ZeroLotTypeRulesGroup ==
    [ lotType    |-> [i \in 1 .. 1 |-> 0],
      minLotSize |-> [i \in 1 .. 4 |-> 0] ]

(* Lot Type Rules Group at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroup ==
    { ZeroLotTypeRulesGroup }
        \cup { [ZeroLotTypeRulesGroup EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroLotTypeRulesGroup EXCEPT !.minLotSize = one] : one \in Sample(4) }

(* A run of Lot Type Rules Group, written one after another *)
RECURSIVE EncodeLotTypeRulesGroupList(_)
EncodeLotTypeRulesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLotTypeRulesGroup(Head(messages)) \o EncodeLotTypeRulesGroupList(Tail(messages))

(* As many Lot Type Rules Group as the field that counts them says *)
RECURSIVE ReadLotTypeRulesGroupList(_, _)
ReadLotTypeRulesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLotTypeRulesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLotTypeRulesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lot Type Rules Group of each kind, for the lists that carry them *)
OneLotTypeRulesGroup == { ZeroLotTypeRulesGroup }

(***************************************************************************)
(* Lot Type Rules Groups                                                   *)
(***************************************************************************)

LotTypeRulesGroups ==
    [ blockLength       : Sample(2),
      lotTypeRulesGroup : SampleLists(OneLotTypeRulesGroup) ]

EncodeLotTypeRulesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.lotTypeRulesGroup), 1)
        \o EncodeLotTypeRulesGroupList(message.lotTypeRulesGroup)

DecodeLotTypeRulesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET lotTypeRulesGroup == ReadLotTypeRulesGroupList(numInGroup.rest, numInGroup.value) IN IF ~lotTypeRulesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         lotTypeRulesGroup |-> lotTypeRulesGroup.value ], lotTypeRulesGroup.rest)

ZeroLotTypeRulesGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      lotTypeRulesGroup |-> << >> ]

(* Lot Type Rules Groups at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroups ==
    { ZeroLotTypeRulesGroups }
        \cup { [ZeroLotTypeRulesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLotTypeRulesGroups EXCEPT !.lotTypeRulesGroup = one] : one \in SampleLists(OneLotTypeRulesGroup) }

(***************************************************************************)
(* Md Instrument Definition Future                                         *)
(***************************************************************************)

MdInstrumentDefinitionFuture ==
    [ matchEventIndicator     : Sample(1),
      totNumReportsOptional   : Sample(4),
      securityUpdateAction    : Sample(1),
      lastUpdateTime          : Sample(8),
      mdSecurityTradingStatus : Sample(1),
      applId                  : Sample(2),
      marketSegmentId         : Sample(1),
      underlyingProduct       : Sample(1),
      securityExchange        : Sample(4),
      securityGroup           : Sample(6),
      asset                   : Sample(6),
      symbol                  : Sample(20),
      securityId              : Sample(4),
      securityType            : Sample(6),
      cfiCode                 : Sample(6),
      maturityMonthYear       : MaturityMonthYear,
      currency                : Sample(3),
      settlCurrency           : Sample(3),
      matchAlgorithm          : Sample(1),
      minTradeVol             : Sample(4),
      maxTradeVol             : Sample(4),
      minPriceIncrementEx     : Sample(8),
      displayFactor           : Sample(8),
      mainFraction            : Sample(1),
      subFraction             : Sample(1),
      priceDisplayFormat      : Sample(1),
      unitOfMeasure           : Sample(30),
      unitOfMeasureQty        : Sample(8),
      tradingReferencePrice   : Sample(8),
      settlPriceType          : Sample(1),
      openInterestQty         : Sample(4),
      clearedVolume           : Sample(4),
      highLimitPrice          : Sample(8),
      lowLimitPrice           : Sample(8),
      maxPriceVariation       : Sample(8),
      decayQuantity           : Sample(4),
      decayStartDate          : Sample(2),
      originalContractSize    : Sample(4),
      contractMultiplier      : Sample(4),
      contractMultiplierUnit  : Sample(1),
      flowScheduleType        : Sample(1),
      minPriceIncrementAmount : Sample(8),
      userDefinedInstrument   : Sample(1),
      tradingReferenceDate    : Sample(2),
      instrumentGuid          : Sample(8),
      eventsGroups            : EventsGroups,
      feedTypesGroups         : FeedTypesGroups,
      instAttribGroups        : InstAttribGroups,
      lotTypeRulesGroups      : LotTypeRulesGroups ]

EncodeMdInstrumentDefinitionFuture(message) ==
    message.matchEventIndicator
        \o message.totNumReportsOptional
        \o message.securityUpdateAction
        \o message.lastUpdateTime
        \o message.mdSecurityTradingStatus
        \o message.applId
        \o message.marketSegmentId
        \o message.underlyingProduct
        \o message.securityExchange
        \o message.securityGroup
        \o message.asset
        \o message.symbol
        \o message.securityId
        \o message.securityType
        \o message.cfiCode
        \o EncodeMaturityMonthYear(message.maturityMonthYear)
        \o message.currency
        \o message.settlCurrency
        \o message.matchAlgorithm
        \o message.minTradeVol
        \o message.maxTradeVol
        \o message.minPriceIncrementEx
        \o message.displayFactor
        \o message.mainFraction
        \o message.subFraction
        \o message.priceDisplayFormat
        \o message.unitOfMeasure
        \o message.unitOfMeasureQty
        \o message.tradingReferencePrice
        \o message.settlPriceType
        \o message.openInterestQty
        \o message.clearedVolume
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o message.decayQuantity
        \o message.decayStartDate
        \o message.originalContractSize
        \o message.contractMultiplier
        \o message.contractMultiplierUnit
        \o message.flowScheduleType
        \o message.minPriceIncrementAmount
        \o message.userDefinedInstrument
        \o message.tradingReferenceDate
        \o message.instrumentGuid
        \o EncodeEventsGroups(message.eventsGroups)
        \o EncodeFeedTypesGroups(message.feedTypesGroups)
        \o EncodeInstAttribGroups(message.instAttribGroups)
        \o EncodeLotTypeRulesGroups(message.lotTypeRulesGroups)

DecodeMdInstrumentDefinitionFuture(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET totNumReportsOptional == ReadBytes(matchEventIndicator.rest, 4) IN IF ~totNumReportsOptional.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(totNumReportsOptional.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityUpdateAction.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(lastUpdateTime.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET applId == ReadBytes(mdSecurityTradingStatus.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applId.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingProduct == ReadBytes(marketSegmentId.rest, 1) IN IF ~underlyingProduct.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(underlyingProduct.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityExchange.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET symbol == ReadBytes(asset.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear(cfiCode.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityMonthYear.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(currency.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(settlCurrency.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(minTradeVol.rest, 4) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET minPriceIncrementEx == ReadBytes(maxTradeVol.rest, 8) IN IF ~minPriceIncrementEx.ok THEN Fail ELSE
    LET displayFactor == ReadBytes(minPriceIncrementEx.rest, 8) IN IF ~displayFactor.ok THEN Fail ELSE
    LET mainFraction == ReadBytes(displayFactor.rest, 1) IN IF ~mainFraction.ok THEN Fail ELSE
    LET subFraction == ReadBytes(mainFraction.rest, 1) IN IF ~subFraction.ok THEN Fail ELSE
    LET priceDisplayFormat == ReadBytes(subFraction.rest, 1) IN IF ~priceDisplayFormat.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(priceDisplayFormat.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQty == ReadBytes(unitOfMeasure.rest, 8) IN IF ~unitOfMeasureQty.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(unitOfMeasureQty.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(tradingReferencePrice.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET openInterestQty == ReadBytes(settlPriceType.rest, 4) IN IF ~openInterestQty.ok THEN Fail ELSE
    LET clearedVolume == ReadBytes(openInterestQty.rest, 4) IN IF ~clearedVolume.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(clearedVolume.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET decayQuantity == ReadBytes(maxPriceVariation.rest, 4) IN IF ~decayQuantity.ok THEN Fail ELSE
    LET decayStartDate == ReadBytes(decayQuantity.rest, 2) IN IF ~decayStartDate.ok THEN Fail ELSE
    LET originalContractSize == ReadBytes(decayStartDate.rest, 4) IN IF ~originalContractSize.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(originalContractSize.rest, 4) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET contractMultiplierUnit == ReadBytes(contractMultiplier.rest, 1) IN IF ~contractMultiplierUnit.ok THEN Fail ELSE
    LET flowScheduleType == ReadBytes(contractMultiplierUnit.rest, 1) IN IF ~flowScheduleType.ok THEN Fail ELSE
    LET minPriceIncrementAmount == ReadBytes(flowScheduleType.rest, 8) IN IF ~minPriceIncrementAmount.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(minPriceIncrementAmount.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(userDefinedInstrument.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(tradingReferenceDate.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups(instrumentGuid.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET feedTypesGroups == DecodeFeedTypesGroups(eventsGroups.rest) IN IF ~feedTypesGroups.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups(feedTypesGroups.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET lotTypeRulesGroups == DecodeLotTypeRulesGroups(instAttribGroups.rest) IN IF ~lotTypeRulesGroups.ok THEN Fail ELSE
    Ok([ matchEventIndicator     |-> matchEventIndicator.value,
         totNumReportsOptional   |-> totNumReportsOptional.value,
         securityUpdateAction    |-> securityUpdateAction.value,
         lastUpdateTime          |-> lastUpdateTime.value,
         mdSecurityTradingStatus |-> mdSecurityTradingStatus.value,
         applId                  |-> applId.value,
         marketSegmentId         |-> marketSegmentId.value,
         underlyingProduct       |-> underlyingProduct.value,
         securityExchange        |-> securityExchange.value,
         securityGroup           |-> securityGroup.value,
         asset                   |-> asset.value,
         symbol                  |-> symbol.value,
         securityId              |-> securityId.value,
         securityType            |-> securityType.value,
         cfiCode                 |-> cfiCode.value,
         maturityMonthYear       |-> maturityMonthYear.value,
         currency                |-> currency.value,
         settlCurrency           |-> settlCurrency.value,
         matchAlgorithm          |-> matchAlgorithm.value,
         minTradeVol             |-> minTradeVol.value,
         maxTradeVol             |-> maxTradeVol.value,
         minPriceIncrementEx     |-> minPriceIncrementEx.value,
         displayFactor           |-> displayFactor.value,
         mainFraction            |-> mainFraction.value,
         subFraction             |-> subFraction.value,
         priceDisplayFormat      |-> priceDisplayFormat.value,
         unitOfMeasure           |-> unitOfMeasure.value,
         unitOfMeasureQty        |-> unitOfMeasureQty.value,
         tradingReferencePrice   |-> tradingReferencePrice.value,
         settlPriceType          |-> settlPriceType.value,
         openInterestQty         |-> openInterestQty.value,
         clearedVolume           |-> clearedVolume.value,
         highLimitPrice          |-> highLimitPrice.value,
         lowLimitPrice           |-> lowLimitPrice.value,
         maxPriceVariation       |-> maxPriceVariation.value,
         decayQuantity           |-> decayQuantity.value,
         decayStartDate          |-> decayStartDate.value,
         originalContractSize    |-> originalContractSize.value,
         contractMultiplier      |-> contractMultiplier.value,
         contractMultiplierUnit  |-> contractMultiplierUnit.value,
         flowScheduleType        |-> flowScheduleType.value,
         minPriceIncrementAmount |-> minPriceIncrementAmount.value,
         userDefinedInstrument   |-> userDefinedInstrument.value,
         tradingReferenceDate    |-> tradingReferenceDate.value,
         instrumentGuid          |-> instrumentGuid.value,
         eventsGroups            |-> eventsGroups.value,
         feedTypesGroups         |-> feedTypesGroups.value,
         instAttribGroups        |-> instAttribGroups.value,
         lotTypeRulesGroups      |-> lotTypeRulesGroups.value ], lotTypeRulesGroups.rest)

ZeroMdInstrumentDefinitionFuture ==
    [ matchEventIndicator     |-> [i \in 1 .. 1 |-> 0],
      totNumReportsOptional   |-> [i \in 1 .. 4 |-> 0],
      securityUpdateAction    |-> [i \in 1 .. 1 |-> 0],
      lastUpdateTime          |-> [i \in 1 .. 8 |-> 0],
      mdSecurityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      applId                  |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId         |-> [i \in 1 .. 1 |-> 0],
      underlyingProduct       |-> [i \in 1 .. 1 |-> 0],
      securityExchange        |-> [i \in 1 .. 4 |-> 0],
      securityGroup           |-> [i \in 1 .. 6 |-> 0],
      asset                   |-> [i \in 1 .. 6 |-> 0],
      symbol                  |-> [i \in 1 .. 20 |-> 0],
      securityId              |-> [i \in 1 .. 4 |-> 0],
      securityType            |-> [i \in 1 .. 6 |-> 0],
      cfiCode                 |-> [i \in 1 .. 6 |-> 0],
      maturityMonthYear       |-> ZeroMaturityMonthYear,
      currency                |-> [i \in 1 .. 3 |-> 0],
      settlCurrency           |-> [i \in 1 .. 3 |-> 0],
      matchAlgorithm          |-> [i \in 1 .. 1 |-> 0],
      minTradeVol             |-> [i \in 1 .. 4 |-> 0],
      maxTradeVol             |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrementEx     |-> [i \in 1 .. 8 |-> 0],
      displayFactor           |-> [i \in 1 .. 8 |-> 0],
      mainFraction            |-> [i \in 1 .. 1 |-> 0],
      subFraction             |-> [i \in 1 .. 1 |-> 0],
      priceDisplayFormat      |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure           |-> [i \in 1 .. 30 |-> 0],
      unitOfMeasureQty        |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice   |-> [i \in 1 .. 8 |-> 0],
      settlPriceType          |-> [i \in 1 .. 1 |-> 0],
      openInterestQty         |-> [i \in 1 .. 4 |-> 0],
      clearedVolume           |-> [i \in 1 .. 4 |-> 0],
      highLimitPrice          |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice           |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation       |-> [i \in 1 .. 8 |-> 0],
      decayQuantity           |-> [i \in 1 .. 4 |-> 0],
      decayStartDate          |-> [i \in 1 .. 2 |-> 0],
      originalContractSize    |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier      |-> [i \in 1 .. 4 |-> 0],
      contractMultiplierUnit  |-> [i \in 1 .. 1 |-> 0],
      flowScheduleType        |-> [i \in 1 .. 1 |-> 0],
      minPriceIncrementAmount |-> [i \in 1 .. 8 |-> 0],
      userDefinedInstrument   |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate    |-> [i \in 1 .. 2 |-> 0],
      instrumentGuid          |-> [i \in 1 .. 8 |-> 0],
      eventsGroups            |-> ZeroEventsGroups,
      feedTypesGroups         |-> ZeroFeedTypesGroups,
      instAttribGroups        |-> ZeroInstAttribGroups,
      lotTypeRulesGroups      |-> ZeroLotTypeRulesGroups ]

(* Md Instrument Definition Future at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionFuture ==
    { ZeroMdInstrumentDefinitionFuture }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.totNumReportsOptional = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.underlyingProduct = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.maxTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.minPriceIncrementEx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.displayFactor = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.mainFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.subFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.priceDisplayFormat = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.unitOfMeasureQty = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.openInterestQty = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.clearedVolume = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.decayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.decayStartDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.originalContractSize = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.contractMultiplier = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.contractMultiplierUnit = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.flowScheduleType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.minPriceIncrementAmount = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.feedTypesGroups = one] : one \in CheckedFeedTypesGroups }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups }
        \cup { [ZeroMdInstrumentDefinitionFuture EXCEPT !.lotTypeRulesGroups = one] : one \in CheckedLotTypeRulesGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear2 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear2(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear2(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear2 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear2 ==
    { ZeroMaturityMonthYear2 }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear2 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup2 ==
    [ eventType : Sample(1),
      eventTime : Sample(8) ]

EncodeEventsGroup2(message) ==
    message.eventType
        \o message.eventTime

DecodeEventsGroup2(bytes) ==
    LET eventType == ReadBytes(bytes, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventType.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroEventsGroup2 ==
    [ eventType |-> [i \in 1 .. 1 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup2 ==
    { ZeroEventsGroup2 }
        \cup { [ZeroEventsGroup2 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup2 EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup2List(_)
EncodeEventsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup2(Head(messages)) \o EncodeEventsGroup2List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup2List(_, _)
ReadEventsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup2 == { ZeroEventsGroup2 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups2 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup2) ]

EncodeEventsGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup2List(message.eventsGroup)

DecodeEventsGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups2 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups2 ==
    { ZeroEventsGroups2 }
        \cup { [ZeroEventsGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups2 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup2) }

(***************************************************************************)
(* Feed Types Group: 4 bytes                                               *)
(***************************************************************************)

FeedTypesGroup2 ==
    [ mdFeedType  : Sample(3),
      marketDepth : Sample(1) ]

EncodeFeedTypesGroup2(message) ==
    message.mdFeedType
        \o message.marketDepth

DecodeFeedTypesGroup2(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 3) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroFeedTypesGroup2 ==
    [ mdFeedType  |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroup2 ==
    { ZeroFeedTypesGroup2 }
        \cup { [ZeroFeedTypesGroup2 EXCEPT !.mdFeedType = one] : one \in Sample(3) }
        \cup { [ZeroFeedTypesGroup2 EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Feed Types Group, written one after another *)
RECURSIVE EncodeFeedTypesGroup2List(_)
EncodeFeedTypesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFeedTypesGroup2(Head(messages)) \o EncodeFeedTypesGroup2List(Tail(messages))

(* As many Feed Types Group as the field that counts them says *)
RECURSIVE ReadFeedTypesGroup2List(_, _)
ReadFeedTypesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFeedTypesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFeedTypesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Feed Types Group of each kind, for the lists that carry them *)
OneFeedTypesGroup2 == { ZeroFeedTypesGroup2 }

(***************************************************************************)
(* Feed Types Groups                                                       *)
(***************************************************************************)

FeedTypesGroups2 ==
    [ blockLength    : Sample(2),
      feedTypesGroup : SampleLists(OneFeedTypesGroup2) ]

EncodeFeedTypesGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.feedTypesGroup), 1)
        \o EncodeFeedTypesGroup2List(message.feedTypesGroup)

DecodeFeedTypesGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET feedTypesGroup == ReadFeedTypesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~feedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         feedTypesGroup |-> feedTypesGroup.value ], feedTypesGroup.rest)

ZeroFeedTypesGroups2 ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      feedTypesGroup |-> << >> ]

(* Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroups2 ==
    { ZeroFeedTypesGroups2 }
        \cup { [ZeroFeedTypesGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFeedTypesGroups2 EXCEPT !.feedTypesGroup = one] : one \in SampleLists(OneFeedTypesGroup2) }

(***************************************************************************)
(* Inst Attrib Group: 4 bytes                                              *)
(***************************************************************************)

InstAttribGroup2 ==
    [ instAttribValue : Sample(4) ]

EncodeInstAttribGroup2(message) ==
    message.instAttribValue

DecodeInstAttribGroup2(bytes) ==
    LET instAttribValue == ReadBytes(bytes, 4) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup2 ==
    [ instAttribValue |-> [i \in 1 .. 4 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup2 ==
    { ZeroInstAttribGroup2 }
        \cup { [ZeroInstAttribGroup2 EXCEPT !.instAttribValue = one] : one \in Sample(4) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroup2List(_)
EncodeInstAttribGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup2(Head(messages)) \o EncodeInstAttribGroup2List(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroup2List(_, _)
ReadInstAttribGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup2 == { ZeroInstAttribGroup2 }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups2 ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup2) ]

EncodeInstAttribGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instAttribGroup), 1)
        \o EncodeInstAttribGroup2List(message.instAttribGroup)

DecodeInstAttribGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroup2List(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups2 ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups2 ==
    { ZeroInstAttribGroups2 }
        \cup { [ZeroInstAttribGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups2 EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup2) }

(***************************************************************************)
(* Lot Type Rules Group: 5 bytes                                           *)
(***************************************************************************)

LotTypeRulesGroup2 ==
    [ lotType    : Sample(1),
      minLotSize : Sample(4) ]

EncodeLotTypeRulesGroup2(message) ==
    message.lotType
        \o message.minLotSize

DecodeLotTypeRulesGroup2(bytes) ==
    LET lotType == ReadBytes(bytes, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(lotType.rest, 4) IN IF ~minLotSize.ok THEN Fail ELSE
    Ok([ lotType    |-> lotType.value,
         minLotSize |-> minLotSize.value ], minLotSize.rest)

ZeroLotTypeRulesGroup2 ==
    [ lotType    |-> [i \in 1 .. 1 |-> 0],
      minLotSize |-> [i \in 1 .. 4 |-> 0] ]

(* Lot Type Rules Group at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroup2 ==
    { ZeroLotTypeRulesGroup2 }
        \cup { [ZeroLotTypeRulesGroup2 EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroLotTypeRulesGroup2 EXCEPT !.minLotSize = one] : one \in Sample(4) }

(* A run of Lot Type Rules Group, written one after another *)
RECURSIVE EncodeLotTypeRulesGroup2List(_)
EncodeLotTypeRulesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLotTypeRulesGroup2(Head(messages)) \o EncodeLotTypeRulesGroup2List(Tail(messages))

(* As many Lot Type Rules Group as the field that counts them says *)
RECURSIVE ReadLotTypeRulesGroup2List(_, _)
ReadLotTypeRulesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLotTypeRulesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLotTypeRulesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lot Type Rules Group of each kind, for the lists that carry them *)
OneLotTypeRulesGroup2 == { ZeroLotTypeRulesGroup2 }

(***************************************************************************)
(* Lot Type Rules Groups                                                   *)
(***************************************************************************)

LotTypeRulesGroups2 ==
    [ blockLength       : Sample(2),
      lotTypeRulesGroup : SampleLists(OneLotTypeRulesGroup2) ]

EncodeLotTypeRulesGroups2(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.lotTypeRulesGroup), 1)
        \o EncodeLotTypeRulesGroup2List(message.lotTypeRulesGroup)

DecodeLotTypeRulesGroups2(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET lotTypeRulesGroup == ReadLotTypeRulesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~lotTypeRulesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         lotTypeRulesGroup |-> lotTypeRulesGroup.value ], lotTypeRulesGroup.rest)

ZeroLotTypeRulesGroups2 ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      lotTypeRulesGroup |-> << >> ]

(* Lot Type Rules Groups at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroups2 ==
    { ZeroLotTypeRulesGroups2 }
        \cup { [ZeroLotTypeRulesGroups2 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLotTypeRulesGroups2 EXCEPT !.lotTypeRulesGroup = one] : one \in SampleLists(OneLotTypeRulesGroup2) }

(***************************************************************************)
(* Option Underlyings Group: 24 bytes                                      *)
(***************************************************************************)

OptionUnderlyingsGroup ==
    [ underlyingSecurityId : Sample(4),
      underlyingSymbol     : Sample(20) ]

EncodeOptionUnderlyingsGroup(message) ==
    message.underlyingSecurityId
        \o message.underlyingSymbol

DecodeOptionUnderlyingsGroup(bytes) ==
    LET underlyingSecurityId == ReadBytes(bytes, 4) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(underlyingSecurityId.rest, 20) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ underlyingSecurityId |-> underlyingSecurityId.value,
         underlyingSymbol     |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroOptionUnderlyingsGroup ==
    [ underlyingSecurityId |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol     |-> [i \in 1 .. 20 |-> 0] ]

(* Option Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedOptionUnderlyingsGroup ==
    { ZeroOptionUnderlyingsGroup }
        \cup { [ZeroOptionUnderlyingsGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroOptionUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(20) }

(* A run of Option Underlyings Group, written one after another *)
RECURSIVE EncodeOptionUnderlyingsGroupList(_)
EncodeOptionUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionUnderlyingsGroup(Head(messages)) \o EncodeOptionUnderlyingsGroupList(Tail(messages))

(* As many Option Underlyings Group as the field that counts them says *)
RECURSIVE ReadOptionUnderlyingsGroupList(_, _)
ReadOptionUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Underlyings Group of each kind, for the lists that carry them *)
OneOptionUnderlyingsGroup == { ZeroOptionUnderlyingsGroup }

(***************************************************************************)
(* Option Underlyings Groups                                               *)
(***************************************************************************)

OptionUnderlyingsGroups ==
    [ blockLength            : Sample(2),
      optionUnderlyingsGroup : SampleLists(OneOptionUnderlyingsGroup) ]

EncodeOptionUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.optionUnderlyingsGroup), 1)
        \o EncodeOptionUnderlyingsGroupList(message.optionUnderlyingsGroup)

DecodeOptionUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET optionUnderlyingsGroup == ReadOptionUnderlyingsGroupList(numInGroup.rest, numInGroup.value) IN IF ~optionUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength            |-> blockLength.value,
         optionUnderlyingsGroup |-> optionUnderlyingsGroup.value ], optionUnderlyingsGroup.rest)

ZeroOptionUnderlyingsGroups ==
    [ blockLength            |-> [i \in 1 .. 2 |-> 0],
      optionUnderlyingsGroup |-> << >> ]

(* Option Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedOptionUnderlyingsGroups ==
    { ZeroOptionUnderlyingsGroups }
        \cup { [ZeroOptionUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOptionUnderlyingsGroups EXCEPT !.optionUnderlyingsGroup = one] : one \in SampleLists(OneOptionUnderlyingsGroup) }

(***************************************************************************)
(* Option Related Instruments Group: 24 bytes                              *)
(***************************************************************************)

OptionRelatedInstrumentsGroup ==
    [ relatedSecurityId : Sample(4),
      relatedSymbol     : Sample(20) ]

EncodeOptionRelatedInstrumentsGroup(message) ==
    message.relatedSecurityId
        \o message.relatedSymbol

DecodeOptionRelatedInstrumentsGroup(bytes) ==
    LET relatedSecurityId == ReadBytes(bytes, 4) IN IF ~relatedSecurityId.ok THEN Fail ELSE
    LET relatedSymbol == ReadBytes(relatedSecurityId.rest, 20) IN IF ~relatedSymbol.ok THEN Fail ELSE
    Ok([ relatedSecurityId |-> relatedSecurityId.value,
         relatedSymbol     |-> relatedSymbol.value ], relatedSymbol.rest)

ZeroOptionRelatedInstrumentsGroup ==
    [ relatedSecurityId |-> [i \in 1 .. 4 |-> 0],
      relatedSymbol     |-> [i \in 1 .. 20 |-> 0] ]

(* Option Related Instruments Group at zero, then each field in turn at the values it is checked at *)
CheckedOptionRelatedInstrumentsGroup ==
    { ZeroOptionRelatedInstrumentsGroup }
        \cup { [ZeroOptionRelatedInstrumentsGroup EXCEPT !.relatedSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroOptionRelatedInstrumentsGroup EXCEPT !.relatedSymbol = one] : one \in Sample(20) }

(* A run of Option Related Instruments Group, written one after another *)
RECURSIVE EncodeOptionRelatedInstrumentsGroupList(_)
EncodeOptionRelatedInstrumentsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOptionRelatedInstrumentsGroup(Head(messages)) \o EncodeOptionRelatedInstrumentsGroupList(Tail(messages))

(* As many Option Related Instruments Group as the field that counts them says *)
RECURSIVE ReadOptionRelatedInstrumentsGroupList(_, _)
ReadOptionRelatedInstrumentsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOptionRelatedInstrumentsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOptionRelatedInstrumentsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Option Related Instruments Group of each kind, for the lists that carry them *)
OneOptionRelatedInstrumentsGroup == { ZeroOptionRelatedInstrumentsGroup }

(***************************************************************************)
(* Option Related Instruments Groups                                       *)
(***************************************************************************)

OptionRelatedInstrumentsGroups ==
    [ blockLength                   : Sample(2),
      optionRelatedInstrumentsGroup : SampleLists(OneOptionRelatedInstrumentsGroup) ]

EncodeOptionRelatedInstrumentsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.optionRelatedInstrumentsGroup), 1)
        \o EncodeOptionRelatedInstrumentsGroupList(message.optionRelatedInstrumentsGroup)

DecodeOptionRelatedInstrumentsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET optionRelatedInstrumentsGroup == ReadOptionRelatedInstrumentsGroupList(numInGroup.rest, numInGroup.value) IN IF ~optionRelatedInstrumentsGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         optionRelatedInstrumentsGroup |-> optionRelatedInstrumentsGroup.value ], optionRelatedInstrumentsGroup.rest)

ZeroOptionRelatedInstrumentsGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      optionRelatedInstrumentsGroup |-> << >> ]

(* Option Related Instruments Groups at zero, then each field in turn at the values it is checked at *)
CheckedOptionRelatedInstrumentsGroups ==
    { ZeroOptionRelatedInstrumentsGroups }
        \cup { [ZeroOptionRelatedInstrumentsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroOptionRelatedInstrumentsGroups EXCEPT !.optionRelatedInstrumentsGroup = one] : one \in SampleLists(OneOptionRelatedInstrumentsGroup) }

(***************************************************************************)
(* Md Instrument Definition Option                                         *)
(***************************************************************************)

MdInstrumentDefinitionOption ==
    [ matchEventIndicator            : Sample(1),
      totNumReportsOptional          : Sample(4),
      securityUpdateAction           : Sample(1),
      lastUpdateTime                 : Sample(8),
      mdSecurityTradingStatus        : Sample(1),
      applId                         : Sample(2),
      marketSegmentId                : Sample(1),
      underlyingProduct              : Sample(1),
      securityExchange               : Sample(4),
      securityGroup                  : Sample(6),
      asset                          : Sample(6),
      symbol                         : Sample(20),
      securityId                     : Sample(4),
      securityType                   : Sample(6),
      cfiCode                        : Sample(6),
      putOrCall                      : Sample(1),
      maturityMonthYear              : MaturityMonthYear2,
      currency                       : Sample(3),
      strikePrice                    : Sample(8),
      strikeCurrency                 : Sample(3),
      settlCurrency                  : Sample(3),
      minCabPrice                    : Sample(8),
      matchAlgorithm                 : Sample(1),
      minTradeVol                    : Sample(4),
      maxTradeVol                    : Sample(4),
      minPriceIncrementOptionalEx    : Sample(8),
      minPriceIncrementAmount        : Sample(8),
      displayFactor                  : Sample(8),
      tickRule                       : Sample(1),
      mainFraction                   : Sample(1),
      subFraction                    : Sample(1),
      priceDisplayFormat             : Sample(1),
      unitOfMeasure                  : Sample(30),
      unitOfMeasureQty               : Sample(8),
      tradingReferencePrice          : Sample(8),
      settlPriceType                 : Sample(1),
      clearedVolume                  : Sample(4),
      openInterestQty                : Sample(4),
      lowLimitPrice                  : Sample(8),
      highLimitPrice                 : Sample(8),
      userDefinedInstrument          : Sample(1),
      tradingReferenceDate           : Sample(2),
      instrumentGuid                 : Sample(8),
      eventsGroups                   : EventsGroups2,
      feedTypesGroups                : FeedTypesGroups2,
      instAttribGroups               : InstAttribGroups2,
      lotTypeRulesGroups             : LotTypeRulesGroups2,
      optionUnderlyingsGroups        : OptionUnderlyingsGroups,
      optionRelatedInstrumentsGroups : OptionRelatedInstrumentsGroups ]

EncodeMdInstrumentDefinitionOption(message) ==
    message.matchEventIndicator
        \o message.totNumReportsOptional
        \o message.securityUpdateAction
        \o message.lastUpdateTime
        \o message.mdSecurityTradingStatus
        \o message.applId
        \o message.marketSegmentId
        \o message.underlyingProduct
        \o message.securityExchange
        \o message.securityGroup
        \o message.asset
        \o message.symbol
        \o message.securityId
        \o message.securityType
        \o message.cfiCode
        \o message.putOrCall
        \o EncodeMaturityMonthYear2(message.maturityMonthYear)
        \o message.currency
        \o message.strikePrice
        \o message.strikeCurrency
        \o message.settlCurrency
        \o message.minCabPrice
        \o message.matchAlgorithm
        \o message.minTradeVol
        \o message.maxTradeVol
        \o message.minPriceIncrementOptionalEx
        \o message.minPriceIncrementAmount
        \o message.displayFactor
        \o message.tickRule
        \o message.mainFraction
        \o message.subFraction
        \o message.priceDisplayFormat
        \o message.unitOfMeasure
        \o message.unitOfMeasureQty
        \o message.tradingReferencePrice
        \o message.settlPriceType
        \o message.clearedVolume
        \o message.openInterestQty
        \o message.lowLimitPrice
        \o message.highLimitPrice
        \o message.userDefinedInstrument
        \o message.tradingReferenceDate
        \o message.instrumentGuid
        \o EncodeEventsGroups2(message.eventsGroups)
        \o EncodeFeedTypesGroups2(message.feedTypesGroups)
        \o EncodeInstAttribGroups2(message.instAttribGroups)
        \o EncodeLotTypeRulesGroups2(message.lotTypeRulesGroups)
        \o EncodeOptionUnderlyingsGroups(message.optionUnderlyingsGroups)
        \o EncodeOptionRelatedInstrumentsGroups(message.optionRelatedInstrumentsGroups)

DecodeMdInstrumentDefinitionOption(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET totNumReportsOptional == ReadBytes(matchEventIndicator.rest, 4) IN IF ~totNumReportsOptional.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(totNumReportsOptional.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityUpdateAction.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(lastUpdateTime.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET applId == ReadBytes(mdSecurityTradingStatus.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applId.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingProduct == ReadBytes(marketSegmentId.rest, 1) IN IF ~underlyingProduct.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(underlyingProduct.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityExchange.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET symbol == ReadBytes(asset.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(cfiCode.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear2(putOrCall.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityMonthYear.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(currency.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikeCurrency == ReadBytes(strikePrice.rest, 3) IN IF ~strikeCurrency.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(strikeCurrency.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET minCabPrice == ReadBytes(settlCurrency.rest, 8) IN IF ~minCabPrice.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(minCabPrice.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(minTradeVol.rest, 4) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET minPriceIncrementOptionalEx == ReadBytes(maxTradeVol.rest, 8) IN IF ~minPriceIncrementOptionalEx.ok THEN Fail ELSE
    LET minPriceIncrementAmount == ReadBytes(minPriceIncrementOptionalEx.rest, 8) IN IF ~minPriceIncrementAmount.ok THEN Fail ELSE
    LET displayFactor == ReadBytes(minPriceIncrementAmount.rest, 8) IN IF ~displayFactor.ok THEN Fail ELSE
    LET tickRule == ReadBytes(displayFactor.rest, 1) IN IF ~tickRule.ok THEN Fail ELSE
    LET mainFraction == ReadBytes(tickRule.rest, 1) IN IF ~mainFraction.ok THEN Fail ELSE
    LET subFraction == ReadBytes(mainFraction.rest, 1) IN IF ~subFraction.ok THEN Fail ELSE
    LET priceDisplayFormat == ReadBytes(subFraction.rest, 1) IN IF ~priceDisplayFormat.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(priceDisplayFormat.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQty == ReadBytes(unitOfMeasure.rest, 8) IN IF ~unitOfMeasureQty.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(unitOfMeasureQty.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(tradingReferencePrice.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET clearedVolume == ReadBytes(settlPriceType.rest, 4) IN IF ~clearedVolume.ok THEN Fail ELSE
    LET openInterestQty == ReadBytes(clearedVolume.rest, 4) IN IF ~openInterestQty.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(openInterestQty.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(lowLimitPrice.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(highLimitPrice.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(userDefinedInstrument.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(tradingReferenceDate.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups2(instrumentGuid.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET feedTypesGroups == DecodeFeedTypesGroups2(eventsGroups.rest) IN IF ~feedTypesGroups.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups2(feedTypesGroups.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET lotTypeRulesGroups == DecodeLotTypeRulesGroups2(instAttribGroups.rest) IN IF ~lotTypeRulesGroups.ok THEN Fail ELSE
    LET optionUnderlyingsGroups == DecodeOptionUnderlyingsGroups(lotTypeRulesGroups.rest) IN IF ~optionUnderlyingsGroups.ok THEN Fail ELSE
    LET optionRelatedInstrumentsGroups == DecodeOptionRelatedInstrumentsGroups(optionUnderlyingsGroups.rest) IN IF ~optionRelatedInstrumentsGroups.ok THEN Fail ELSE
    Ok([ matchEventIndicator            |-> matchEventIndicator.value,
         totNumReportsOptional          |-> totNumReportsOptional.value,
         securityUpdateAction           |-> securityUpdateAction.value,
         lastUpdateTime                 |-> lastUpdateTime.value,
         mdSecurityTradingStatus        |-> mdSecurityTradingStatus.value,
         applId                         |-> applId.value,
         marketSegmentId                |-> marketSegmentId.value,
         underlyingProduct              |-> underlyingProduct.value,
         securityExchange               |-> securityExchange.value,
         securityGroup                  |-> securityGroup.value,
         asset                          |-> asset.value,
         symbol                         |-> symbol.value,
         securityId                     |-> securityId.value,
         securityType                   |-> securityType.value,
         cfiCode                        |-> cfiCode.value,
         putOrCall                      |-> putOrCall.value,
         maturityMonthYear              |-> maturityMonthYear.value,
         currency                       |-> currency.value,
         strikePrice                    |-> strikePrice.value,
         strikeCurrency                 |-> strikeCurrency.value,
         settlCurrency                  |-> settlCurrency.value,
         minCabPrice                    |-> minCabPrice.value,
         matchAlgorithm                 |-> matchAlgorithm.value,
         minTradeVol                    |-> minTradeVol.value,
         maxTradeVol                    |-> maxTradeVol.value,
         minPriceIncrementOptionalEx    |-> minPriceIncrementOptionalEx.value,
         minPriceIncrementAmount        |-> minPriceIncrementAmount.value,
         displayFactor                  |-> displayFactor.value,
         tickRule                       |-> tickRule.value,
         mainFraction                   |-> mainFraction.value,
         subFraction                    |-> subFraction.value,
         priceDisplayFormat             |-> priceDisplayFormat.value,
         unitOfMeasure                  |-> unitOfMeasure.value,
         unitOfMeasureQty               |-> unitOfMeasureQty.value,
         tradingReferencePrice          |-> tradingReferencePrice.value,
         settlPriceType                 |-> settlPriceType.value,
         clearedVolume                  |-> clearedVolume.value,
         openInterestQty                |-> openInterestQty.value,
         lowLimitPrice                  |-> lowLimitPrice.value,
         highLimitPrice                 |-> highLimitPrice.value,
         userDefinedInstrument          |-> userDefinedInstrument.value,
         tradingReferenceDate           |-> tradingReferenceDate.value,
         instrumentGuid                 |-> instrumentGuid.value,
         eventsGroups                   |-> eventsGroups.value,
         feedTypesGroups                |-> feedTypesGroups.value,
         instAttribGroups               |-> instAttribGroups.value,
         lotTypeRulesGroups             |-> lotTypeRulesGroups.value,
         optionUnderlyingsGroups        |-> optionUnderlyingsGroups.value,
         optionRelatedInstrumentsGroups |-> optionRelatedInstrumentsGroups.value ], optionRelatedInstrumentsGroups.rest)

ZeroMdInstrumentDefinitionOption ==
    [ matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      totNumReportsOptional          |-> [i \in 1 .. 4 |-> 0],
      securityUpdateAction           |-> [i \in 1 .. 1 |-> 0],
      lastUpdateTime                 |-> [i \in 1 .. 8 |-> 0],
      mdSecurityTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      applId                         |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId                |-> [i \in 1 .. 1 |-> 0],
      underlyingProduct              |-> [i \in 1 .. 1 |-> 0],
      securityExchange               |-> [i \in 1 .. 4 |-> 0],
      securityGroup                  |-> [i \in 1 .. 6 |-> 0],
      asset                          |-> [i \in 1 .. 6 |-> 0],
      symbol                         |-> [i \in 1 .. 20 |-> 0],
      securityId                     |-> [i \in 1 .. 4 |-> 0],
      securityType                   |-> [i \in 1 .. 6 |-> 0],
      cfiCode                        |-> [i \in 1 .. 6 |-> 0],
      putOrCall                      |-> [i \in 1 .. 1 |-> 0],
      maturityMonthYear              |-> ZeroMaturityMonthYear2,
      currency                       |-> [i \in 1 .. 3 |-> 0],
      strikePrice                    |-> [i \in 1 .. 8 |-> 0],
      strikeCurrency                 |-> [i \in 1 .. 3 |-> 0],
      settlCurrency                  |-> [i \in 1 .. 3 |-> 0],
      minCabPrice                    |-> [i \in 1 .. 8 |-> 0],
      matchAlgorithm                 |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                    |-> [i \in 1 .. 4 |-> 0],
      maxTradeVol                    |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrementOptionalEx    |-> [i \in 1 .. 8 |-> 0],
      minPriceIncrementAmount        |-> [i \in 1 .. 8 |-> 0],
      displayFactor                  |-> [i \in 1 .. 8 |-> 0],
      tickRule                       |-> [i \in 1 .. 1 |-> 0],
      mainFraction                   |-> [i \in 1 .. 1 |-> 0],
      subFraction                    |-> [i \in 1 .. 1 |-> 0],
      priceDisplayFormat             |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure                  |-> [i \in 1 .. 30 |-> 0],
      unitOfMeasureQty               |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice          |-> [i \in 1 .. 8 |-> 0],
      settlPriceType                 |-> [i \in 1 .. 1 |-> 0],
      clearedVolume                  |-> [i \in 1 .. 4 |-> 0],
      openInterestQty                |-> [i \in 1 .. 4 |-> 0],
      lowLimitPrice                  |-> [i \in 1 .. 8 |-> 0],
      highLimitPrice                 |-> [i \in 1 .. 8 |-> 0],
      userDefinedInstrument          |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate           |-> [i \in 1 .. 2 |-> 0],
      instrumentGuid                 |-> [i \in 1 .. 8 |-> 0],
      eventsGroups                   |-> ZeroEventsGroups2,
      feedTypesGroups                |-> ZeroFeedTypesGroups2,
      instAttribGroups               |-> ZeroInstAttribGroups2,
      lotTypeRulesGroups             |-> ZeroLotTypeRulesGroups2,
      optionUnderlyingsGroups        |-> ZeroOptionUnderlyingsGroups,
      optionRelatedInstrumentsGroups |-> ZeroOptionRelatedInstrumentsGroups ]

(* Md Instrument Definition Option at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionOption ==
    { ZeroMdInstrumentDefinitionOption }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.totNumReportsOptional = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.underlyingProduct = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear2 }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.minCabPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.maxTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.minPriceIncrementOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.minPriceIncrementAmount = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.displayFactor = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.tickRule = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.mainFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.subFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.priceDisplayFormat = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.unitOfMeasureQty = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.clearedVolume = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.openInterestQty = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups2 }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.feedTypesGroups = one] : one \in CheckedFeedTypesGroups2 }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups2 }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.lotTypeRulesGroups = one] : one \in CheckedLotTypeRulesGroups2 }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.optionUnderlyingsGroups = one] : one \in CheckedOptionUnderlyingsGroups }
        \cup { [ZeroMdInstrumentDefinitionOption EXCEPT !.optionRelatedInstrumentsGroups = one] : one \in CheckedOptionRelatedInstrumentsGroups }

(***************************************************************************)
(* Maturity Month Year: 5 bytes                                            *)
(***************************************************************************)

MaturityMonthYear3 ==
    [ year  : Sample(2),
      month : Sample(1),
      day   : Sample(1),
      week  : Sample(1) ]

EncodeMaturityMonthYear3(message) ==
    message.year
        \o message.month
        \o message.day
        \o message.week

DecodeMaturityMonthYear3(bytes) ==
    LET year == ReadBytes(bytes, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 1) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 1) IN IF ~day.ok THEN Fail ELSE
    LET week == ReadBytes(day.rest, 1) IN IF ~week.ok THEN Fail ELSE
    Ok([ year  |-> year.value,
         month |-> month.value,
         day   |-> day.value,
         week  |-> week.value ], week.rest)

ZeroMaturityMonthYear3 ==
    [ year  |-> [i \in 1 .. 2 |-> 0],
      month |-> [i \in 1 .. 1 |-> 0],
      day   |-> [i \in 1 .. 1 |-> 0],
      week  |-> [i \in 1 .. 1 |-> 0] ]

(* Maturity Month Year at zero, then each field in turn at the values it is checked at *)
CheckedMaturityMonthYear3 ==
    { ZeroMaturityMonthYear3 }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.month = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.day = one] : one \in Sample(1) }
        \cup { [ZeroMaturityMonthYear3 EXCEPT !.week = one] : one \in Sample(1) }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup3 ==
    [ eventType : Sample(1),
      eventTime : Sample(8) ]

EncodeEventsGroup3(message) ==
    message.eventType
        \o message.eventTime

DecodeEventsGroup3(bytes) ==
    LET eventType == ReadBytes(bytes, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventType.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroEventsGroup3 ==
    [ eventType |-> [i \in 1 .. 1 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup3 ==
    { ZeroEventsGroup3 }
        \cup { [ZeroEventsGroup3 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup3 EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup3List(_)
EncodeEventsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup3(Head(messages)) \o EncodeEventsGroup3List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup3List(_, _)
ReadEventsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup3 == { ZeroEventsGroup3 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups3 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup3) ]

EncodeEventsGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup3List(message.eventsGroup)

DecodeEventsGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup3List(numInGroup.rest, numInGroup.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups3 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups3 ==
    { ZeroEventsGroups3 }
        \cup { [ZeroEventsGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups3 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup3) }

(***************************************************************************)
(* Feed Types Group: 4 bytes                                               *)
(***************************************************************************)

FeedTypesGroup3 ==
    [ mdFeedType  : Sample(3),
      marketDepth : Sample(1) ]

EncodeFeedTypesGroup3(message) ==
    message.mdFeedType
        \o message.marketDepth

DecodeFeedTypesGroup3(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 3) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroFeedTypesGroup3 ==
    [ mdFeedType  |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroup3 ==
    { ZeroFeedTypesGroup3 }
        \cup { [ZeroFeedTypesGroup3 EXCEPT !.mdFeedType = one] : one \in Sample(3) }
        \cup { [ZeroFeedTypesGroup3 EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Feed Types Group, written one after another *)
RECURSIVE EncodeFeedTypesGroup3List(_)
EncodeFeedTypesGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFeedTypesGroup3(Head(messages)) \o EncodeFeedTypesGroup3List(Tail(messages))

(* As many Feed Types Group as the field that counts them says *)
RECURSIVE ReadFeedTypesGroup3List(_, _)
ReadFeedTypesGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFeedTypesGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFeedTypesGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Feed Types Group of each kind, for the lists that carry them *)
OneFeedTypesGroup3 == { ZeroFeedTypesGroup3 }

(***************************************************************************)
(* Feed Types Groups                                                       *)
(***************************************************************************)

FeedTypesGroups3 ==
    [ blockLength    : Sample(2),
      feedTypesGroup : SampleLists(OneFeedTypesGroup3) ]

EncodeFeedTypesGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.feedTypesGroup), 1)
        \o EncodeFeedTypesGroup3List(message.feedTypesGroup)

DecodeFeedTypesGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET feedTypesGroup == ReadFeedTypesGroup3List(numInGroup.rest, numInGroup.value) IN IF ~feedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         feedTypesGroup |-> feedTypesGroup.value ], feedTypesGroup.rest)

ZeroFeedTypesGroups3 ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      feedTypesGroup |-> << >> ]

(* Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroups3 ==
    { ZeroFeedTypesGroups3 }
        \cup { [ZeroFeedTypesGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFeedTypesGroups3 EXCEPT !.feedTypesGroup = one] : one \in SampleLists(OneFeedTypesGroup3) }

(***************************************************************************)
(* Inst Attrib Group: 4 bytes                                              *)
(***************************************************************************)

InstAttribGroup3 ==
    [ instAttribValue : Sample(4) ]

EncodeInstAttribGroup3(message) ==
    message.instAttribValue

DecodeInstAttribGroup3(bytes) ==
    LET instAttribValue == ReadBytes(bytes, 4) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup3 ==
    [ instAttribValue |-> [i \in 1 .. 4 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup3 ==
    { ZeroInstAttribGroup3 }
        \cup { [ZeroInstAttribGroup3 EXCEPT !.instAttribValue = one] : one \in Sample(4) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroup3List(_)
EncodeInstAttribGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup3(Head(messages)) \o EncodeInstAttribGroup3List(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroup3List(_, _)
ReadInstAttribGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup3 == { ZeroInstAttribGroup3 }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups3 ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup3) ]

EncodeInstAttribGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instAttribGroup), 1)
        \o EncodeInstAttribGroup3List(message.instAttribGroup)

DecodeInstAttribGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroup3List(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups3 ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups3 ==
    { ZeroInstAttribGroups3 }
        \cup { [ZeroInstAttribGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups3 EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup3) }

(***************************************************************************)
(* Lot Type Rules Group: 5 bytes                                           *)
(***************************************************************************)

LotTypeRulesGroup3 ==
    [ lotType    : Sample(1),
      minLotSize : Sample(4) ]

EncodeLotTypeRulesGroup3(message) ==
    message.lotType
        \o message.minLotSize

DecodeLotTypeRulesGroup3(bytes) ==
    LET lotType == ReadBytes(bytes, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(lotType.rest, 4) IN IF ~minLotSize.ok THEN Fail ELSE
    Ok([ lotType    |-> lotType.value,
         minLotSize |-> minLotSize.value ], minLotSize.rest)

ZeroLotTypeRulesGroup3 ==
    [ lotType    |-> [i \in 1 .. 1 |-> 0],
      minLotSize |-> [i \in 1 .. 4 |-> 0] ]

(* Lot Type Rules Group at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroup3 ==
    { ZeroLotTypeRulesGroup3 }
        \cup { [ZeroLotTypeRulesGroup3 EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroLotTypeRulesGroup3 EXCEPT !.minLotSize = one] : one \in Sample(4) }

(* A run of Lot Type Rules Group, written one after another *)
RECURSIVE EncodeLotTypeRulesGroup3List(_)
EncodeLotTypeRulesGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLotTypeRulesGroup3(Head(messages)) \o EncodeLotTypeRulesGroup3List(Tail(messages))

(* As many Lot Type Rules Group as the field that counts them says *)
RECURSIVE ReadLotTypeRulesGroup3List(_, _)
ReadLotTypeRulesGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLotTypeRulesGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLotTypeRulesGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lot Type Rules Group of each kind, for the lists that carry them *)
OneLotTypeRulesGroup3 == { ZeroLotTypeRulesGroup3 }

(***************************************************************************)
(* Lot Type Rules Groups                                                   *)
(***************************************************************************)

LotTypeRulesGroups3 ==
    [ blockLength       : Sample(2),
      lotTypeRulesGroup : SampleLists(OneLotTypeRulesGroup3) ]

EncodeLotTypeRulesGroups3(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.lotTypeRulesGroup), 1)
        \o EncodeLotTypeRulesGroup3List(message.lotTypeRulesGroup)

DecodeLotTypeRulesGroups3(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET lotTypeRulesGroup == ReadLotTypeRulesGroup3List(numInGroup.rest, numInGroup.value) IN IF ~lotTypeRulesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         lotTypeRulesGroup |-> lotTypeRulesGroup.value ], lotTypeRulesGroup.rest)

ZeroLotTypeRulesGroups3 ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      lotTypeRulesGroup |-> << >> ]

(* Lot Type Rules Groups at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroups3 ==
    { ZeroLotTypeRulesGroups3 }
        \cup { [ZeroLotTypeRulesGroups3 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLotTypeRulesGroups3 EXCEPT !.lotTypeRulesGroup = one] : one \in SampleLists(OneLotTypeRulesGroup3) }

(***************************************************************************)
(* Legs Group: 18 bytes                                                    *)
(***************************************************************************)

LegsGroup ==
    [ legSecurityId  : Sample(4),
      legSide        : Sample(1),
      legRatioQty    : Sample(1),
      legPrice       : Sample(8),
      legOptionDelta : Sample(4) ]

EncodeLegsGroup(message) ==
    message.legSecurityId
        \o message.legSide
        \o message.legRatioQty
        \o message.legPrice
        \o message.legOptionDelta

DecodeLegsGroup(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSide.rest, 1) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legRatioQty.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legOptionDelta == ReadBytes(legPrice.rest, 4) IN IF ~legOptionDelta.ok THEN Fail ELSE
    Ok([ legSecurityId  |-> legSecurityId.value,
         legSide        |-> legSide.value,
         legRatioQty    |-> legRatioQty.value,
         legPrice       |-> legPrice.value,
         legOptionDelta |-> legOptionDelta.value ], legOptionDelta.rest)

ZeroLegsGroup ==
    [ legSecurityId  |-> [i \in 1 .. 4 |-> 0],
      legSide        |-> [i \in 1 .. 1 |-> 0],
      legRatioQty    |-> [i \in 1 .. 1 |-> 0],
      legPrice       |-> [i \in 1 .. 8 |-> 0],
      legOptionDelta |-> [i \in 1 .. 4 |-> 0] ]

(* Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedLegsGroup ==
    { ZeroLegsGroup }
        \cup { [ZeroLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(1) }
        \cup { [ZeroLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroLegsGroup EXCEPT !.legOptionDelta = one] : one \in Sample(4) }

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
(* Md Instrument Definition Spread                                         *)
(***************************************************************************)

MdInstrumentDefinitionSpread ==
    [ matchEventIndicator         : Sample(1),
      totNumReportsOptional       : Sample(4),
      securityUpdateAction        : Sample(1),
      lastUpdateTime              : Sample(8),
      mdSecurityTradingStatus     : Sample(1),
      applId                      : Sample(2),
      marketSegmentId             : Sample(1),
      underlyingProductOptional   : Sample(1),
      securityExchange            : Sample(4),
      securityGroup               : Sample(6),
      asset                       : Sample(6),
      symbol                      : Sample(20),
      securityId                  : Sample(4),
      securityType                : Sample(6),
      cfiCode                     : Sample(6),
      maturityMonthYear           : MaturityMonthYear3,
      currency                    : Sample(3),
      securitySubType             : Sample(5),
      userDefinedInstrument       : Sample(1),
      matchAlgorithm              : Sample(1),
      minTradeVol                 : Sample(4),
      maxTradeVol                 : Sample(4),
      minPriceIncrementOptionalEx : Sample(8),
      displayFactor               : Sample(8),
      priceDisplayFormat          : Sample(1),
      priceRatio                  : Sample(8),
      tickRule                    : Sample(1),
      unitOfMeasure               : Sample(30),
      tradingReferencePrice       : Sample(8),
      settlPriceType              : Sample(1),
      openInterestQty             : Sample(4),
      clearedVolume               : Sample(4),
      highLimitPrice              : Sample(8),
      lowLimitPrice               : Sample(8),
      maxPriceVariation           : Sample(8),
      mainFraction                : Sample(1),
      subFraction                 : Sample(1),
      tradingReferenceDate        : Sample(2),
      priceQuoteMethod            : Sample(5),
      riskSet                     : Sample(6),
      marketSet                   : Sample(6),
      instrumentGuid              : Sample(8),
      financialInstrumentFullName : Sample(35),
      eventsGroups                : EventsGroups3,
      feedTypesGroups             : FeedTypesGroups3,
      instAttribGroups            : InstAttribGroups3,
      lotTypeRulesGroups          : LotTypeRulesGroups3,
      legsGroups                  : LegsGroups ]

EncodeMdInstrumentDefinitionSpread(message) ==
    message.matchEventIndicator
        \o message.totNumReportsOptional
        \o message.securityUpdateAction
        \o message.lastUpdateTime
        \o message.mdSecurityTradingStatus
        \o message.applId
        \o message.marketSegmentId
        \o message.underlyingProductOptional
        \o message.securityExchange
        \o message.securityGroup
        \o message.asset
        \o message.symbol
        \o message.securityId
        \o message.securityType
        \o message.cfiCode
        \o EncodeMaturityMonthYear3(message.maturityMonthYear)
        \o message.currency
        \o message.securitySubType
        \o message.userDefinedInstrument
        \o message.matchAlgorithm
        \o message.minTradeVol
        \o message.maxTradeVol
        \o message.minPriceIncrementOptionalEx
        \o message.displayFactor
        \o message.priceDisplayFormat
        \o message.priceRatio
        \o message.tickRule
        \o message.unitOfMeasure
        \o message.tradingReferencePrice
        \o message.settlPriceType
        \o message.openInterestQty
        \o message.clearedVolume
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o message.mainFraction
        \o message.subFraction
        \o message.tradingReferenceDate
        \o message.priceQuoteMethod
        \o message.riskSet
        \o message.marketSet
        \o message.instrumentGuid
        \o message.financialInstrumentFullName
        \o EncodeEventsGroups3(message.eventsGroups)
        \o EncodeFeedTypesGroups3(message.feedTypesGroups)
        \o EncodeInstAttribGroups3(message.instAttribGroups)
        \o EncodeLotTypeRulesGroups3(message.lotTypeRulesGroups)
        \o EncodeLegsGroups(message.legsGroups)

DecodeMdInstrumentDefinitionSpread(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET totNumReportsOptional == ReadBytes(matchEventIndicator.rest, 4) IN IF ~totNumReportsOptional.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(totNumReportsOptional.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityUpdateAction.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(lastUpdateTime.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET applId == ReadBytes(mdSecurityTradingStatus.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applId.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingProductOptional == ReadBytes(marketSegmentId.rest, 1) IN IF ~underlyingProductOptional.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(underlyingProductOptional.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityExchange.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET symbol == ReadBytes(asset.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET maturityMonthYear == DecodeMaturityMonthYear3(cfiCode.rest) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET currency == ReadBytes(maturityMonthYear.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(currency.rest, 5) IN IF ~securitySubType.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(securitySubType.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(userDefinedInstrument.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(minTradeVol.rest, 4) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET minPriceIncrementOptionalEx == ReadBytes(maxTradeVol.rest, 8) IN IF ~minPriceIncrementOptionalEx.ok THEN Fail ELSE
    LET displayFactor == ReadBytes(minPriceIncrementOptionalEx.rest, 8) IN IF ~displayFactor.ok THEN Fail ELSE
    LET priceDisplayFormat == ReadBytes(displayFactor.rest, 1) IN IF ~priceDisplayFormat.ok THEN Fail ELSE
    LET priceRatio == ReadBytes(priceDisplayFormat.rest, 8) IN IF ~priceRatio.ok THEN Fail ELSE
    LET tickRule == ReadBytes(priceRatio.rest, 1) IN IF ~tickRule.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(tickRule.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(unitOfMeasure.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(tradingReferencePrice.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    LET openInterestQty == ReadBytes(settlPriceType.rest, 4) IN IF ~openInterestQty.ok THEN Fail ELSE
    LET clearedVolume == ReadBytes(openInterestQty.rest, 4) IN IF ~clearedVolume.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(clearedVolume.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET mainFraction == ReadBytes(maxPriceVariation.rest, 1) IN IF ~mainFraction.ok THEN Fail ELSE
    LET subFraction == ReadBytes(mainFraction.rest, 1) IN IF ~subFraction.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(subFraction.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET priceQuoteMethod == ReadBytes(tradingReferenceDate.rest, 5) IN IF ~priceQuoteMethod.ok THEN Fail ELSE
    LET riskSet == ReadBytes(priceQuoteMethod.rest, 6) IN IF ~riskSet.ok THEN Fail ELSE
    LET marketSet == ReadBytes(riskSet.rest, 6) IN IF ~marketSet.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(marketSet.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(instrumentGuid.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups3(financialInstrumentFullName.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET feedTypesGroups == DecodeFeedTypesGroups3(eventsGroups.rest) IN IF ~feedTypesGroups.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups3(feedTypesGroups.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET lotTypeRulesGroups == DecodeLotTypeRulesGroups3(instAttribGroups.rest) IN IF ~lotTypeRulesGroups.ok THEN Fail ELSE
    LET legsGroups == DecodeLegsGroups(lotTypeRulesGroups.rest) IN IF ~legsGroups.ok THEN Fail ELSE
    Ok([ matchEventIndicator         |-> matchEventIndicator.value,
         totNumReportsOptional       |-> totNumReportsOptional.value,
         securityUpdateAction        |-> securityUpdateAction.value,
         lastUpdateTime              |-> lastUpdateTime.value,
         mdSecurityTradingStatus     |-> mdSecurityTradingStatus.value,
         applId                      |-> applId.value,
         marketSegmentId             |-> marketSegmentId.value,
         underlyingProductOptional   |-> underlyingProductOptional.value,
         securityExchange            |-> securityExchange.value,
         securityGroup               |-> securityGroup.value,
         asset                       |-> asset.value,
         symbol                      |-> symbol.value,
         securityId                  |-> securityId.value,
         securityType                |-> securityType.value,
         cfiCode                     |-> cfiCode.value,
         maturityMonthYear           |-> maturityMonthYear.value,
         currency                    |-> currency.value,
         securitySubType             |-> securitySubType.value,
         userDefinedInstrument       |-> userDefinedInstrument.value,
         matchAlgorithm              |-> matchAlgorithm.value,
         minTradeVol                 |-> minTradeVol.value,
         maxTradeVol                 |-> maxTradeVol.value,
         minPriceIncrementOptionalEx |-> minPriceIncrementOptionalEx.value,
         displayFactor               |-> displayFactor.value,
         priceDisplayFormat          |-> priceDisplayFormat.value,
         priceRatio                  |-> priceRatio.value,
         tickRule                    |-> tickRule.value,
         unitOfMeasure               |-> unitOfMeasure.value,
         tradingReferencePrice       |-> tradingReferencePrice.value,
         settlPriceType              |-> settlPriceType.value,
         openInterestQty             |-> openInterestQty.value,
         clearedVolume               |-> clearedVolume.value,
         highLimitPrice              |-> highLimitPrice.value,
         lowLimitPrice               |-> lowLimitPrice.value,
         maxPriceVariation           |-> maxPriceVariation.value,
         mainFraction                |-> mainFraction.value,
         subFraction                 |-> subFraction.value,
         tradingReferenceDate        |-> tradingReferenceDate.value,
         priceQuoteMethod            |-> priceQuoteMethod.value,
         riskSet                     |-> riskSet.value,
         marketSet                   |-> marketSet.value,
         instrumentGuid              |-> instrumentGuid.value,
         financialInstrumentFullName |-> financialInstrumentFullName.value,
         eventsGroups                |-> eventsGroups.value,
         feedTypesGroups             |-> feedTypesGroups.value,
         instAttribGroups            |-> instAttribGroups.value,
         lotTypeRulesGroups          |-> lotTypeRulesGroups.value,
         legsGroups                  |-> legsGroups.value ], legsGroups.rest)

ZeroMdInstrumentDefinitionSpread ==
    [ matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      totNumReportsOptional       |-> [i \in 1 .. 4 |-> 0],
      securityUpdateAction        |-> [i \in 1 .. 1 |-> 0],
      lastUpdateTime              |-> [i \in 1 .. 8 |-> 0],
      mdSecurityTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      applId                      |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 1 |-> 0],
      underlyingProductOptional   |-> [i \in 1 .. 1 |-> 0],
      securityExchange            |-> [i \in 1 .. 4 |-> 0],
      securityGroup               |-> [i \in 1 .. 6 |-> 0],
      asset                       |-> [i \in 1 .. 6 |-> 0],
      symbol                      |-> [i \in 1 .. 20 |-> 0],
      securityId                  |-> [i \in 1 .. 4 |-> 0],
      securityType                |-> [i \in 1 .. 6 |-> 0],
      cfiCode                     |-> [i \in 1 .. 6 |-> 0],
      maturityMonthYear           |-> ZeroMaturityMonthYear3,
      currency                    |-> [i \in 1 .. 3 |-> 0],
      securitySubType             |-> [i \in 1 .. 5 |-> 0],
      userDefinedInstrument       |-> [i \in 1 .. 1 |-> 0],
      matchAlgorithm              |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                 |-> [i \in 1 .. 4 |-> 0],
      maxTradeVol                 |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrementOptionalEx |-> [i \in 1 .. 8 |-> 0],
      displayFactor               |-> [i \in 1 .. 8 |-> 0],
      priceDisplayFormat          |-> [i \in 1 .. 1 |-> 0],
      priceRatio                  |-> [i \in 1 .. 8 |-> 0],
      tickRule                    |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure               |-> [i \in 1 .. 30 |-> 0],
      tradingReferencePrice       |-> [i \in 1 .. 8 |-> 0],
      settlPriceType              |-> [i \in 1 .. 1 |-> 0],
      openInterestQty             |-> [i \in 1 .. 4 |-> 0],
      clearedVolume               |-> [i \in 1 .. 4 |-> 0],
      highLimitPrice              |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation           |-> [i \in 1 .. 8 |-> 0],
      mainFraction                |-> [i \in 1 .. 1 |-> 0],
      subFraction                 |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate        |-> [i \in 1 .. 2 |-> 0],
      priceQuoteMethod            |-> [i \in 1 .. 5 |-> 0],
      riskSet                     |-> [i \in 1 .. 6 |-> 0],
      marketSet                   |-> [i \in 1 .. 6 |-> 0],
      instrumentGuid              |-> [i \in 1 .. 8 |-> 0],
      financialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      eventsGroups                |-> ZeroEventsGroups3,
      feedTypesGroups             |-> ZeroFeedTypesGroups3,
      instAttribGroups            |-> ZeroInstAttribGroups3,
      lotTypeRulesGroups          |-> ZeroLotTypeRulesGroups3,
      legsGroups                  |-> ZeroLegsGroups ]

(* Md Instrument Definition Spread at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionSpread ==
    { ZeroMdInstrumentDefinitionSpread }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.totNumReportsOptional = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.underlyingProductOptional = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.maturityMonthYear = one] : one \in CheckedMaturityMonthYear3 }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.securitySubType = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.maxTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.minPriceIncrementOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.displayFactor = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.priceDisplayFormat = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.priceRatio = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.tickRule = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.settlPriceType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.openInterestQty = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.clearedVolume = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.mainFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.subFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.priceQuoteMethod = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.riskSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.marketSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups3 }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.feedTypesGroups = one] : one \in CheckedFeedTypesGroups3 }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups3 }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.lotTypeRulesGroups = one] : one \in CheckedLotTypeRulesGroups3 }
        \cup { [ZeroMdInstrumentDefinitionSpread EXCEPT !.legsGroups = one] : one \in CheckedLegsGroups }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup4 ==
    [ eventType : Sample(1),
      eventTime : Sample(8) ]

EncodeEventsGroup4(message) ==
    message.eventType
        \o message.eventTime

DecodeEventsGroup4(bytes) ==
    LET eventType == ReadBytes(bytes, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventType.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroEventsGroup4 ==
    [ eventType |-> [i \in 1 .. 1 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup4 ==
    { ZeroEventsGroup4 }
        \cup { [ZeroEventsGroup4 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup4 EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup4List(_)
EncodeEventsGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup4(Head(messages)) \o EncodeEventsGroup4List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup4List(_, _)
ReadEventsGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup4 == { ZeroEventsGroup4 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups4 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup4) ]

EncodeEventsGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup4List(message.eventsGroup)

DecodeEventsGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup4List(numInGroup.rest, numInGroup.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups4 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups4 ==
    { ZeroEventsGroups4 }
        \cup { [ZeroEventsGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups4 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup4) }

(***************************************************************************)
(* Feed Types Group: 4 bytes                                               *)
(***************************************************************************)

FeedTypesGroup4 ==
    [ mdFeedType  : Sample(3),
      marketDepth : Sample(1) ]

EncodeFeedTypesGroup4(message) ==
    message.mdFeedType
        \o message.marketDepth

DecodeFeedTypesGroup4(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 3) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroFeedTypesGroup4 ==
    [ mdFeedType  |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroup4 ==
    { ZeroFeedTypesGroup4 }
        \cup { [ZeroFeedTypesGroup4 EXCEPT !.mdFeedType = one] : one \in Sample(3) }
        \cup { [ZeroFeedTypesGroup4 EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Feed Types Group, written one after another *)
RECURSIVE EncodeFeedTypesGroup4List(_)
EncodeFeedTypesGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFeedTypesGroup4(Head(messages)) \o EncodeFeedTypesGroup4List(Tail(messages))

(* As many Feed Types Group as the field that counts them says *)
RECURSIVE ReadFeedTypesGroup4List(_, _)
ReadFeedTypesGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFeedTypesGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFeedTypesGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Feed Types Group of each kind, for the lists that carry them *)
OneFeedTypesGroup4 == { ZeroFeedTypesGroup4 }

(***************************************************************************)
(* Feed Types Groups                                                       *)
(***************************************************************************)

FeedTypesGroups4 ==
    [ blockLength    : Sample(2),
      feedTypesGroup : SampleLists(OneFeedTypesGroup4) ]

EncodeFeedTypesGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.feedTypesGroup), 1)
        \o EncodeFeedTypesGroup4List(message.feedTypesGroup)

DecodeFeedTypesGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET feedTypesGroup == ReadFeedTypesGroup4List(numInGroup.rest, numInGroup.value) IN IF ~feedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         feedTypesGroup |-> feedTypesGroup.value ], feedTypesGroup.rest)

ZeroFeedTypesGroups4 ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      feedTypesGroup |-> << >> ]

(* Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroups4 ==
    { ZeroFeedTypesGroups4 }
        \cup { [ZeroFeedTypesGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFeedTypesGroups4 EXCEPT !.feedTypesGroup = one] : one \in SampleLists(OneFeedTypesGroup4) }

(***************************************************************************)
(* Inst Attrib Group: 4 bytes                                              *)
(***************************************************************************)

InstAttribGroup4 ==
    [ instAttribValue : Sample(4) ]

EncodeInstAttribGroup4(message) ==
    message.instAttribValue

DecodeInstAttribGroup4(bytes) ==
    LET instAttribValue == ReadBytes(bytes, 4) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup4 ==
    [ instAttribValue |-> [i \in 1 .. 4 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup4 ==
    { ZeroInstAttribGroup4 }
        \cup { [ZeroInstAttribGroup4 EXCEPT !.instAttribValue = one] : one \in Sample(4) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroup4List(_)
EncodeInstAttribGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup4(Head(messages)) \o EncodeInstAttribGroup4List(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroup4List(_, _)
ReadInstAttribGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup4 == { ZeroInstAttribGroup4 }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups4 ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup4) ]

EncodeInstAttribGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instAttribGroup), 1)
        \o EncodeInstAttribGroup4List(message.instAttribGroup)

DecodeInstAttribGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroup4List(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups4 ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups4 ==
    { ZeroInstAttribGroups4 }
        \cup { [ZeroInstAttribGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups4 EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup4) }

(***************************************************************************)
(* Lot Type Rules Group: 5 bytes                                           *)
(***************************************************************************)

LotTypeRulesGroup4 ==
    [ lotType    : Sample(1),
      minLotSize : Sample(4) ]

EncodeLotTypeRulesGroup4(message) ==
    message.lotType
        \o message.minLotSize

DecodeLotTypeRulesGroup4(bytes) ==
    LET lotType == ReadBytes(bytes, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(lotType.rest, 4) IN IF ~minLotSize.ok THEN Fail ELSE
    Ok([ lotType    |-> lotType.value,
         minLotSize |-> minLotSize.value ], minLotSize.rest)

ZeroLotTypeRulesGroup4 ==
    [ lotType    |-> [i \in 1 .. 1 |-> 0],
      minLotSize |-> [i \in 1 .. 4 |-> 0] ]

(* Lot Type Rules Group at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroup4 ==
    { ZeroLotTypeRulesGroup4 }
        \cup { [ZeroLotTypeRulesGroup4 EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroLotTypeRulesGroup4 EXCEPT !.minLotSize = one] : one \in Sample(4) }

(* A run of Lot Type Rules Group, written one after another *)
RECURSIVE EncodeLotTypeRulesGroup4List(_)
EncodeLotTypeRulesGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLotTypeRulesGroup4(Head(messages)) \o EncodeLotTypeRulesGroup4List(Tail(messages))

(* As many Lot Type Rules Group as the field that counts them says *)
RECURSIVE ReadLotTypeRulesGroup4List(_, _)
ReadLotTypeRulesGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLotTypeRulesGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLotTypeRulesGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lot Type Rules Group of each kind, for the lists that carry them *)
OneLotTypeRulesGroup4 == { ZeroLotTypeRulesGroup4 }

(***************************************************************************)
(* Lot Type Rules Groups                                                   *)
(***************************************************************************)

LotTypeRulesGroups4 ==
    [ blockLength       : Sample(2),
      lotTypeRulesGroup : SampleLists(OneLotTypeRulesGroup4) ]

EncodeLotTypeRulesGroups4(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.lotTypeRulesGroup), 1)
        \o EncodeLotTypeRulesGroup4List(message.lotTypeRulesGroup)

DecodeLotTypeRulesGroups4(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET lotTypeRulesGroup == ReadLotTypeRulesGroup4List(numInGroup.rest, numInGroup.value) IN IF ~lotTypeRulesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         lotTypeRulesGroup |-> lotTypeRulesGroup.value ], lotTypeRulesGroup.rest)

ZeroLotTypeRulesGroups4 ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      lotTypeRulesGroup |-> << >> ]

(* Lot Type Rules Groups at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroups4 ==
    { ZeroLotTypeRulesGroups4 }
        \cup { [ZeroLotTypeRulesGroups4 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLotTypeRulesGroups4 EXCEPT !.lotTypeRulesGroup = one] : one \in SampleLists(OneLotTypeRulesGroup4) }

(***************************************************************************)
(* Md Instrument Definition Fixed Income                                   *)
(***************************************************************************)

MdInstrumentDefinitionFixedIncome ==
    [ matchEventIndicator         : Sample(1),
      totNumReportsOptional       : Sample(4),
      securityUpdateAction        : Sample(1),
      lastUpdateTime              : Sample(8),
      mdSecurityTradingStatus     : Sample(1),
      applId                      : Sample(2),
      marketSegmentId             : Sample(1),
      underlyingProduct           : Sample(1),
      securityExchange            : Sample(4),
      securityGroup               : Sample(6),
      asset                       : Sample(6),
      symbol                      : Sample(20),
      securityId                  : Sample(4),
      securityType                : Sample(6),
      cfiCode                     : Sample(6),
      currency                    : Sample(3),
      settlCurrency               : Sample(3),
      matchAlgorithm              : Sample(1),
      minTradeVol                 : Sample(4),
      maxTradeVol                 : Sample(4),
      minPriceIncrementOptionalEx : Sample(8),
      displayFactor               : Sample(8),
      mainFraction                : Sample(1),
      subFraction                 : Sample(1),
      priceDisplayFormat          : Sample(1),
      unitOfMeasure               : Sample(30),
      unitOfMeasureQty            : Sample(8),
      tradingReferencePrice       : Sample(8),
      tradingReferenceDate        : Sample(2),
      highLimitPrice              : Sample(8),
      lowLimitPrice               : Sample(8),
      maxPriceVariation           : Sample(8),
      minPriceIncrementAmount     : Sample(8),
      issueDate                   : Sample(2),
      datedDate                   : Sample(2),
      maturityDate                : Sample(2),
      couponRate                  : Sample(8),
      parValue                    : Sample(8),
      couponFrequencyUnit         : Sample(3),
      couponFrequencyPeriod       : Sample(2),
      couponDayCount              : Sample(20),
      countryOfIssue              : Sample(2),
      issuer                      : Sample(25),
      financialInstrumentFullName : Sample(35),
      securityAltId               : Sample(12),
      securityAltIdSource         : Sample(1),
      priceQuoteMethod            : Sample(5),
      partyRoleClearingOrg        : Sample(5),
      userDefinedInstrument       : Sample(1),
      riskSet                     : Sample(6),
      marketSet                   : Sample(6),
      instrumentGuid              : Sample(8),
      eventsGroups                : EventsGroups4,
      feedTypesGroups             : FeedTypesGroups4,
      instAttribGroups            : InstAttribGroups4,
      lotTypeRulesGroups          : LotTypeRulesGroups4 ]

EncodeMdInstrumentDefinitionFixedIncome(message) ==
    message.matchEventIndicator
        \o message.totNumReportsOptional
        \o message.securityUpdateAction
        \o message.lastUpdateTime
        \o message.mdSecurityTradingStatus
        \o message.applId
        \o message.marketSegmentId
        \o message.underlyingProduct
        \o message.securityExchange
        \o message.securityGroup
        \o message.asset
        \o message.symbol
        \o message.securityId
        \o message.securityType
        \o message.cfiCode
        \o message.currency
        \o message.settlCurrency
        \o message.matchAlgorithm
        \o message.minTradeVol
        \o message.maxTradeVol
        \o message.minPriceIncrementOptionalEx
        \o message.displayFactor
        \o message.mainFraction
        \o message.subFraction
        \o message.priceDisplayFormat
        \o message.unitOfMeasure
        \o message.unitOfMeasureQty
        \o message.tradingReferencePrice
        \o message.tradingReferenceDate
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o message.minPriceIncrementAmount
        \o message.issueDate
        \o message.datedDate
        \o message.maturityDate
        \o message.couponRate
        \o message.parValue
        \o message.couponFrequencyUnit
        \o message.couponFrequencyPeriod
        \o message.couponDayCount
        \o message.countryOfIssue
        \o message.issuer
        \o message.financialInstrumentFullName
        \o message.securityAltId
        \o message.securityAltIdSource
        \o message.priceQuoteMethod
        \o message.partyRoleClearingOrg
        \o message.userDefinedInstrument
        \o message.riskSet
        \o message.marketSet
        \o message.instrumentGuid
        \o EncodeEventsGroups4(message.eventsGroups)
        \o EncodeFeedTypesGroups4(message.feedTypesGroups)
        \o EncodeInstAttribGroups4(message.instAttribGroups)
        \o EncodeLotTypeRulesGroups4(message.lotTypeRulesGroups)

DecodeMdInstrumentDefinitionFixedIncome(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET totNumReportsOptional == ReadBytes(matchEventIndicator.rest, 4) IN IF ~totNumReportsOptional.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(totNumReportsOptional.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityUpdateAction.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(lastUpdateTime.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET applId == ReadBytes(mdSecurityTradingStatus.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applId.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingProduct == ReadBytes(marketSegmentId.rest, 1) IN IF ~underlyingProduct.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(underlyingProduct.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityExchange.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET symbol == ReadBytes(asset.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(currency.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(settlCurrency.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(minTradeVol.rest, 4) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET minPriceIncrementOptionalEx == ReadBytes(maxTradeVol.rest, 8) IN IF ~minPriceIncrementOptionalEx.ok THEN Fail ELSE
    LET displayFactor == ReadBytes(minPriceIncrementOptionalEx.rest, 8) IN IF ~displayFactor.ok THEN Fail ELSE
    LET mainFraction == ReadBytes(displayFactor.rest, 1) IN IF ~mainFraction.ok THEN Fail ELSE
    LET subFraction == ReadBytes(mainFraction.rest, 1) IN IF ~subFraction.ok THEN Fail ELSE
    LET priceDisplayFormat == ReadBytes(subFraction.rest, 1) IN IF ~priceDisplayFormat.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(priceDisplayFormat.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQty == ReadBytes(unitOfMeasure.rest, 8) IN IF ~unitOfMeasureQty.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(unitOfMeasureQty.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(tradingReferencePrice.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(tradingReferenceDate.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET minPriceIncrementAmount == ReadBytes(maxPriceVariation.rest, 8) IN IF ~minPriceIncrementAmount.ok THEN Fail ELSE
    LET issueDate == ReadBytes(minPriceIncrementAmount.rest, 2) IN IF ~issueDate.ok THEN Fail ELSE
    LET datedDate == ReadBytes(issueDate.rest, 2) IN IF ~datedDate.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(datedDate.rest, 2) IN IF ~maturityDate.ok THEN Fail ELSE
    LET couponRate == ReadBytes(maturityDate.rest, 8) IN IF ~couponRate.ok THEN Fail ELSE
    LET parValue == ReadBytes(couponRate.rest, 8) IN IF ~parValue.ok THEN Fail ELSE
    LET couponFrequencyUnit == ReadBytes(parValue.rest, 3) IN IF ~couponFrequencyUnit.ok THEN Fail ELSE
    LET couponFrequencyPeriod == ReadBytes(couponFrequencyUnit.rest, 2) IN IF ~couponFrequencyPeriod.ok THEN Fail ELSE
    LET couponDayCount == ReadBytes(couponFrequencyPeriod.rest, 20) IN IF ~couponDayCount.ok THEN Fail ELSE
    LET countryOfIssue == ReadBytes(couponDayCount.rest, 2) IN IF ~countryOfIssue.ok THEN Fail ELSE
    LET issuer == ReadBytes(countryOfIssue.rest, 25) IN IF ~issuer.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(issuer.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET securityAltId == ReadBytes(financialInstrumentFullName.rest, 12) IN IF ~securityAltId.ok THEN Fail ELSE
    LET securityAltIdSource == ReadBytes(securityAltId.rest, 1) IN IF ~securityAltIdSource.ok THEN Fail ELSE
    LET priceQuoteMethod == ReadBytes(securityAltIdSource.rest, 5) IN IF ~priceQuoteMethod.ok THEN Fail ELSE
    LET partyRoleClearingOrg == ReadBytes(priceQuoteMethod.rest, 5) IN IF ~partyRoleClearingOrg.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(partyRoleClearingOrg.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET riskSet == ReadBytes(userDefinedInstrument.rest, 6) IN IF ~riskSet.ok THEN Fail ELSE
    LET marketSet == ReadBytes(riskSet.rest, 6) IN IF ~marketSet.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(marketSet.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups4(instrumentGuid.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET feedTypesGroups == DecodeFeedTypesGroups4(eventsGroups.rest) IN IF ~feedTypesGroups.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups4(feedTypesGroups.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET lotTypeRulesGroups == DecodeLotTypeRulesGroups4(instAttribGroups.rest) IN IF ~lotTypeRulesGroups.ok THEN Fail ELSE
    Ok([ matchEventIndicator         |-> matchEventIndicator.value,
         totNumReportsOptional       |-> totNumReportsOptional.value,
         securityUpdateAction        |-> securityUpdateAction.value,
         lastUpdateTime              |-> lastUpdateTime.value,
         mdSecurityTradingStatus     |-> mdSecurityTradingStatus.value,
         applId                      |-> applId.value,
         marketSegmentId             |-> marketSegmentId.value,
         underlyingProduct           |-> underlyingProduct.value,
         securityExchange            |-> securityExchange.value,
         securityGroup               |-> securityGroup.value,
         asset                       |-> asset.value,
         symbol                      |-> symbol.value,
         securityId                  |-> securityId.value,
         securityType                |-> securityType.value,
         cfiCode                     |-> cfiCode.value,
         currency                    |-> currency.value,
         settlCurrency               |-> settlCurrency.value,
         matchAlgorithm              |-> matchAlgorithm.value,
         minTradeVol                 |-> minTradeVol.value,
         maxTradeVol                 |-> maxTradeVol.value,
         minPriceIncrementOptionalEx |-> minPriceIncrementOptionalEx.value,
         displayFactor               |-> displayFactor.value,
         mainFraction                |-> mainFraction.value,
         subFraction                 |-> subFraction.value,
         priceDisplayFormat          |-> priceDisplayFormat.value,
         unitOfMeasure               |-> unitOfMeasure.value,
         unitOfMeasureQty            |-> unitOfMeasureQty.value,
         tradingReferencePrice       |-> tradingReferencePrice.value,
         tradingReferenceDate        |-> tradingReferenceDate.value,
         highLimitPrice              |-> highLimitPrice.value,
         lowLimitPrice               |-> lowLimitPrice.value,
         maxPriceVariation           |-> maxPriceVariation.value,
         minPriceIncrementAmount     |-> minPriceIncrementAmount.value,
         issueDate                   |-> issueDate.value,
         datedDate                   |-> datedDate.value,
         maturityDate                |-> maturityDate.value,
         couponRate                  |-> couponRate.value,
         parValue                    |-> parValue.value,
         couponFrequencyUnit         |-> couponFrequencyUnit.value,
         couponFrequencyPeriod       |-> couponFrequencyPeriod.value,
         couponDayCount              |-> couponDayCount.value,
         countryOfIssue              |-> countryOfIssue.value,
         issuer                      |-> issuer.value,
         financialInstrumentFullName |-> financialInstrumentFullName.value,
         securityAltId               |-> securityAltId.value,
         securityAltIdSource         |-> securityAltIdSource.value,
         priceQuoteMethod            |-> priceQuoteMethod.value,
         partyRoleClearingOrg        |-> partyRoleClearingOrg.value,
         userDefinedInstrument       |-> userDefinedInstrument.value,
         riskSet                     |-> riskSet.value,
         marketSet                   |-> marketSet.value,
         instrumentGuid              |-> instrumentGuid.value,
         eventsGroups                |-> eventsGroups.value,
         feedTypesGroups             |-> feedTypesGroups.value,
         instAttribGroups            |-> instAttribGroups.value,
         lotTypeRulesGroups          |-> lotTypeRulesGroups.value ], lotTypeRulesGroups.rest)

ZeroMdInstrumentDefinitionFixedIncome ==
    [ matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      totNumReportsOptional       |-> [i \in 1 .. 4 |-> 0],
      securityUpdateAction        |-> [i \in 1 .. 1 |-> 0],
      lastUpdateTime              |-> [i \in 1 .. 8 |-> 0],
      mdSecurityTradingStatus     |-> [i \in 1 .. 1 |-> 0],
      applId                      |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 1 |-> 0],
      underlyingProduct           |-> [i \in 1 .. 1 |-> 0],
      securityExchange            |-> [i \in 1 .. 4 |-> 0],
      securityGroup               |-> [i \in 1 .. 6 |-> 0],
      asset                       |-> [i \in 1 .. 6 |-> 0],
      symbol                      |-> [i \in 1 .. 20 |-> 0],
      securityId                  |-> [i \in 1 .. 4 |-> 0],
      securityType                |-> [i \in 1 .. 6 |-> 0],
      cfiCode                     |-> [i \in 1 .. 6 |-> 0],
      currency                    |-> [i \in 1 .. 3 |-> 0],
      settlCurrency               |-> [i \in 1 .. 3 |-> 0],
      matchAlgorithm              |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                 |-> [i \in 1 .. 4 |-> 0],
      maxTradeVol                 |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrementOptionalEx |-> [i \in 1 .. 8 |-> 0],
      displayFactor               |-> [i \in 1 .. 8 |-> 0],
      mainFraction                |-> [i \in 1 .. 1 |-> 0],
      subFraction                 |-> [i \in 1 .. 1 |-> 0],
      priceDisplayFormat          |-> [i \in 1 .. 1 |-> 0],
      unitOfMeasure               |-> [i \in 1 .. 30 |-> 0],
      unitOfMeasureQty            |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice       |-> [i \in 1 .. 8 |-> 0],
      tradingReferenceDate        |-> [i \in 1 .. 2 |-> 0],
      highLimitPrice              |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation           |-> [i \in 1 .. 8 |-> 0],
      minPriceIncrementAmount     |-> [i \in 1 .. 8 |-> 0],
      issueDate                   |-> [i \in 1 .. 2 |-> 0],
      datedDate                   |-> [i \in 1 .. 2 |-> 0],
      maturityDate                |-> [i \in 1 .. 2 |-> 0],
      couponRate                  |-> [i \in 1 .. 8 |-> 0],
      parValue                    |-> [i \in 1 .. 8 |-> 0],
      couponFrequencyUnit         |-> [i \in 1 .. 3 |-> 0],
      couponFrequencyPeriod       |-> [i \in 1 .. 2 |-> 0],
      couponDayCount              |-> [i \in 1 .. 20 |-> 0],
      countryOfIssue              |-> [i \in 1 .. 2 |-> 0],
      issuer                      |-> [i \in 1 .. 25 |-> 0],
      financialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      securityAltId               |-> [i \in 1 .. 12 |-> 0],
      securityAltIdSource         |-> [i \in 1 .. 1 |-> 0],
      priceQuoteMethod            |-> [i \in 1 .. 5 |-> 0],
      partyRoleClearingOrg        |-> [i \in 1 .. 5 |-> 0],
      userDefinedInstrument       |-> [i \in 1 .. 1 |-> 0],
      riskSet                     |-> [i \in 1 .. 6 |-> 0],
      marketSet                   |-> [i \in 1 .. 6 |-> 0],
      instrumentGuid              |-> [i \in 1 .. 8 |-> 0],
      eventsGroups                |-> ZeroEventsGroups4,
      feedTypesGroups             |-> ZeroFeedTypesGroups4,
      instAttribGroups            |-> ZeroInstAttribGroups4,
      lotTypeRulesGroups          |-> ZeroLotTypeRulesGroups4 ]

(* Md Instrument Definition Fixed Income at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionFixedIncome ==
    { ZeroMdInstrumentDefinitionFixedIncome }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.totNumReportsOptional = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.underlyingProduct = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.maxTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.minPriceIncrementOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.displayFactor = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.mainFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.subFraction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.priceDisplayFormat = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.unitOfMeasureQty = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.minPriceIncrementAmount = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.issueDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.datedDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.maturityDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.couponRate = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.parValue = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.couponFrequencyUnit = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.couponFrequencyPeriod = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.couponDayCount = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.countryOfIssue = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.issuer = one] : one \in Sample(25) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityAltId = one] : one \in Sample(12) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.securityAltIdSource = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.priceQuoteMethod = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.partyRoleClearingOrg = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.riskSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.marketSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups4 }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.feedTypesGroups = one] : one \in CheckedFeedTypesGroups4 }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups4 }
        \cup { [ZeroMdInstrumentDefinitionFixedIncome EXCEPT !.lotTypeRulesGroups = one] : one \in CheckedLotTypeRulesGroups4 }

(***************************************************************************)
(* Events Group: 9 bytes                                                   *)
(***************************************************************************)

EventsGroup5 ==
    [ eventType : Sample(1),
      eventTime : Sample(8) ]

EncodeEventsGroup5(message) ==
    message.eventType
        \o message.eventTime

DecodeEventsGroup5(bytes) ==
    LET eventType == ReadBytes(bytes, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventTime == ReadBytes(eventType.rest, 8) IN IF ~eventTime.ok THEN Fail ELSE
    Ok([ eventType |-> eventType.value,
         eventTime |-> eventTime.value ], eventTime.rest)

ZeroEventsGroup5 ==
    [ eventType |-> [i \in 1 .. 1 |-> 0],
      eventTime |-> [i \in 1 .. 8 |-> 0] ]

(* Events Group at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroup5 ==
    { ZeroEventsGroup5 }
        \cup { [ZeroEventsGroup5 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroEventsGroup5 EXCEPT !.eventTime = one] : one \in Sample(8) }

(* A run of Events Group, written one after another *)
RECURSIVE EncodeEventsGroup5List(_)
EncodeEventsGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEventsGroup5(Head(messages)) \o EncodeEventsGroup5List(Tail(messages))

(* As many Events Group as the field that counts them says *)
RECURSIVE ReadEventsGroup5List(_, _)
ReadEventsGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEventsGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEventsGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Events Group of each kind, for the lists that carry them *)
OneEventsGroup5 == { ZeroEventsGroup5 }

(***************************************************************************)
(* Events Groups                                                           *)
(***************************************************************************)

EventsGroups5 ==
    [ blockLength : Sample(2),
      eventsGroup : SampleLists(OneEventsGroup5) ]

EncodeEventsGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.eventsGroup), 1)
        \o EncodeEventsGroup5List(message.eventsGroup)

DecodeEventsGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET eventsGroup == ReadEventsGroup5List(numInGroup.rest, numInGroup.value) IN IF ~eventsGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         eventsGroup |-> eventsGroup.value ], eventsGroup.rest)

ZeroEventsGroups5 ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      eventsGroup |-> << >> ]

(* Events Groups at zero, then each field in turn at the values it is checked at *)
CheckedEventsGroups5 ==
    { ZeroEventsGroups5 }
        \cup { [ZeroEventsGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroEventsGroups5 EXCEPT !.eventsGroup = one] : one \in SampleLists(OneEventsGroup5) }

(***************************************************************************)
(* Feed Types Group: 4 bytes                                               *)
(***************************************************************************)

FeedTypesGroup5 ==
    [ mdFeedType  : Sample(3),
      marketDepth : Sample(1) ]

EncodeFeedTypesGroup5(message) ==
    message.mdFeedType
        \o message.marketDepth

DecodeFeedTypesGroup5(bytes) ==
    LET mdFeedType == ReadBytes(bytes, 3) IN IF ~mdFeedType.ok THEN Fail ELSE
    LET marketDepth == ReadBytes(mdFeedType.rest, 1) IN IF ~marketDepth.ok THEN Fail ELSE
    Ok([ mdFeedType  |-> mdFeedType.value,
         marketDepth |-> marketDepth.value ], marketDepth.rest)

ZeroFeedTypesGroup5 ==
    [ mdFeedType  |-> [i \in 1 .. 3 |-> 0],
      marketDepth |-> [i \in 1 .. 1 |-> 0] ]

(* Feed Types Group at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroup5 ==
    { ZeroFeedTypesGroup5 }
        \cup { [ZeroFeedTypesGroup5 EXCEPT !.mdFeedType = one] : one \in Sample(3) }
        \cup { [ZeroFeedTypesGroup5 EXCEPT !.marketDepth = one] : one \in Sample(1) }

(* A run of Feed Types Group, written one after another *)
RECURSIVE EncodeFeedTypesGroup5List(_)
EncodeFeedTypesGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFeedTypesGroup5(Head(messages)) \o EncodeFeedTypesGroup5List(Tail(messages))

(* As many Feed Types Group as the field that counts them says *)
RECURSIVE ReadFeedTypesGroup5List(_, _)
ReadFeedTypesGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFeedTypesGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFeedTypesGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Feed Types Group of each kind, for the lists that carry them *)
OneFeedTypesGroup5 == { ZeroFeedTypesGroup5 }

(***************************************************************************)
(* Feed Types Groups                                                       *)
(***************************************************************************)

FeedTypesGroups5 ==
    [ blockLength    : Sample(2),
      feedTypesGroup : SampleLists(OneFeedTypesGroup5) ]

EncodeFeedTypesGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.feedTypesGroup), 1)
        \o EncodeFeedTypesGroup5List(message.feedTypesGroup)

DecodeFeedTypesGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET feedTypesGroup == ReadFeedTypesGroup5List(numInGroup.rest, numInGroup.value) IN IF ~feedTypesGroup.ok THEN Fail ELSE
    Ok([ blockLength    |-> blockLength.value,
         feedTypesGroup |-> feedTypesGroup.value ], feedTypesGroup.rest)

ZeroFeedTypesGroups5 ==
    [ blockLength    |-> [i \in 1 .. 2 |-> 0],
      feedTypesGroup |-> << >> ]

(* Feed Types Groups at zero, then each field in turn at the values it is checked at *)
CheckedFeedTypesGroups5 ==
    { ZeroFeedTypesGroups5 }
        \cup { [ZeroFeedTypesGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroFeedTypesGroups5 EXCEPT !.feedTypesGroup = one] : one \in SampleLists(OneFeedTypesGroup5) }

(***************************************************************************)
(* Inst Attrib Group: 4 bytes                                              *)
(***************************************************************************)

InstAttribGroup5 ==
    [ instAttribValue : Sample(4) ]

EncodeInstAttribGroup5(message) ==
    message.instAttribValue

DecodeInstAttribGroup5(bytes) ==
    LET instAttribValue == ReadBytes(bytes, 4) IN IF ~instAttribValue.ok THEN Fail ELSE
    Ok([ instAttribValue |-> instAttribValue.value ], instAttribValue.rest)

ZeroInstAttribGroup5 ==
    [ instAttribValue |-> [i \in 1 .. 4 |-> 0] ]

(* Inst Attrib Group at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroup5 ==
    { ZeroInstAttribGroup5 }
        \cup { [ZeroInstAttribGroup5 EXCEPT !.instAttribValue = one] : one \in Sample(4) }

(* A run of Inst Attrib Group, written one after another *)
RECURSIVE EncodeInstAttribGroup5List(_)
EncodeInstAttribGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstAttribGroup5(Head(messages)) \o EncodeInstAttribGroup5List(Tail(messages))

(* As many Inst Attrib Group as the field that counts them says *)
RECURSIVE ReadInstAttribGroup5List(_, _)
ReadInstAttribGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstAttribGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstAttribGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Inst Attrib Group of each kind, for the lists that carry them *)
OneInstAttribGroup5 == { ZeroInstAttribGroup5 }

(***************************************************************************)
(* Inst Attrib Groups                                                      *)
(***************************************************************************)

InstAttribGroups5 ==
    [ blockLength     : Sample(2),
      instAttribGroup : SampleLists(OneInstAttribGroup5) ]

EncodeInstAttribGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.instAttribGroup), 1)
        \o EncodeInstAttribGroup5List(message.instAttribGroup)

DecodeInstAttribGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instAttribGroup == ReadInstAttribGroup5List(numInGroup.rest, numInGroup.value) IN IF ~instAttribGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         instAttribGroup |-> instAttribGroup.value ], instAttribGroup.rest)

ZeroInstAttribGroups5 ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      instAttribGroup |-> << >> ]

(* Inst Attrib Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstAttribGroups5 ==
    { ZeroInstAttribGroups5 }
        \cup { [ZeroInstAttribGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstAttribGroups5 EXCEPT !.instAttribGroup = one] : one \in SampleLists(OneInstAttribGroup5) }

(***************************************************************************)
(* Lot Type Rules Group: 5 bytes                                           *)
(***************************************************************************)

LotTypeRulesGroup5 ==
    [ lotType    : Sample(1),
      minLotSize : Sample(4) ]

EncodeLotTypeRulesGroup5(message) ==
    message.lotType
        \o message.minLotSize

DecodeLotTypeRulesGroup5(bytes) ==
    LET lotType == ReadBytes(bytes, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET minLotSize == ReadBytes(lotType.rest, 4) IN IF ~minLotSize.ok THEN Fail ELSE
    Ok([ lotType    |-> lotType.value,
         minLotSize |-> minLotSize.value ], minLotSize.rest)

ZeroLotTypeRulesGroup5 ==
    [ lotType    |-> [i \in 1 .. 1 |-> 0],
      minLotSize |-> [i \in 1 .. 4 |-> 0] ]

(* Lot Type Rules Group at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroup5 ==
    { ZeroLotTypeRulesGroup5 }
        \cup { [ZeroLotTypeRulesGroup5 EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroLotTypeRulesGroup5 EXCEPT !.minLotSize = one] : one \in Sample(4) }

(* A run of Lot Type Rules Group, written one after another *)
RECURSIVE EncodeLotTypeRulesGroup5List(_)
EncodeLotTypeRulesGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLotTypeRulesGroup5(Head(messages)) \o EncodeLotTypeRulesGroup5List(Tail(messages))

(* As many Lot Type Rules Group as the field that counts them says *)
RECURSIVE ReadLotTypeRulesGroup5List(_, _)
ReadLotTypeRulesGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLotTypeRulesGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLotTypeRulesGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Lot Type Rules Group of each kind, for the lists that carry them *)
OneLotTypeRulesGroup5 == { ZeroLotTypeRulesGroup5 }

(***************************************************************************)
(* Lot Type Rules Groups                                                   *)
(***************************************************************************)

LotTypeRulesGroups5 ==
    [ blockLength       : Sample(2),
      lotTypeRulesGroup : SampleLists(OneLotTypeRulesGroup5) ]

EncodeLotTypeRulesGroups5(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.lotTypeRulesGroup), 1)
        \o EncodeLotTypeRulesGroup5List(message.lotTypeRulesGroup)

DecodeLotTypeRulesGroups5(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET lotTypeRulesGroup == ReadLotTypeRulesGroup5List(numInGroup.rest, numInGroup.value) IN IF ~lotTypeRulesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         lotTypeRulesGroup |-> lotTypeRulesGroup.value ], lotTypeRulesGroup.rest)

ZeroLotTypeRulesGroups5 ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      lotTypeRulesGroup |-> << >> ]

(* Lot Type Rules Groups at zero, then each field in turn at the values it is checked at *)
CheckedLotTypeRulesGroups5 ==
    { ZeroLotTypeRulesGroups5 }
        \cup { [ZeroLotTypeRulesGroups5 EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroLotTypeRulesGroups5 EXCEPT !.lotTypeRulesGroup = one] : one \in SampleLists(OneLotTypeRulesGroup5) }

(***************************************************************************)
(* Repo Underlyings Group: 118 bytes                                       *)
(***************************************************************************)

RepoUnderlyingsGroup ==
    [ underlyingSymbol                      : Sample(20),
      underlyingSecurityIdOptional          : Sample(4),
      underlyingSecurityAltId               : Sample(12),
      underlyingSecurityAltIdSource         : Sample(1),
      underlyingFinancialInstrumentFullName : Sample(35),
      underlyingSecurityType                : Sample(6),
      underlyingCountryOfIssue              : Sample(2),
      underlyingIssuer                      : Sample(25),
      underlyingMaxLifeTime                 : Sample(1),
      underlyingMinDaysToMaturity           : Sample(2),
      underlyingInstrumentGuidOptional      : Sample(8),
      underlyingMaturityDate                : Sample(2) ]

EncodeRepoUnderlyingsGroup(message) ==
    message.underlyingSymbol
        \o message.underlyingSecurityIdOptional
        \o message.underlyingSecurityAltId
        \o message.underlyingSecurityAltIdSource
        \o message.underlyingFinancialInstrumentFullName
        \o message.underlyingSecurityType
        \o message.underlyingCountryOfIssue
        \o message.underlyingIssuer
        \o message.underlyingMaxLifeTime
        \o message.underlyingMinDaysToMaturity
        \o message.underlyingInstrumentGuidOptional
        \o message.underlyingMaturityDate

DecodeRepoUnderlyingsGroup(bytes) ==
    LET underlyingSymbol == ReadBytes(bytes, 20) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingSecurityIdOptional == ReadBytes(underlyingSymbol.rest, 4) IN IF ~underlyingSecurityIdOptional.ok THEN Fail ELSE
    LET underlyingSecurityAltId == ReadBytes(underlyingSecurityIdOptional.rest, 12) IN IF ~underlyingSecurityAltId.ok THEN Fail ELSE
    LET underlyingSecurityAltIdSource == ReadBytes(underlyingSecurityAltId.rest, 1) IN IF ~underlyingSecurityAltIdSource.ok THEN Fail ELSE
    LET underlyingFinancialInstrumentFullName == ReadBytes(underlyingSecurityAltIdSource.rest, 35) IN IF ~underlyingFinancialInstrumentFullName.ok THEN Fail ELSE
    LET underlyingSecurityType == ReadBytes(underlyingFinancialInstrumentFullName.rest, 6) IN IF ~underlyingSecurityType.ok THEN Fail ELSE
    LET underlyingCountryOfIssue == ReadBytes(underlyingSecurityType.rest, 2) IN IF ~underlyingCountryOfIssue.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(underlyingCountryOfIssue.rest, 25) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET underlyingMaxLifeTime == ReadBytes(underlyingIssuer.rest, 1) IN IF ~underlyingMaxLifeTime.ok THEN Fail ELSE
    LET underlyingMinDaysToMaturity == ReadBytes(underlyingMaxLifeTime.rest, 2) IN IF ~underlyingMinDaysToMaturity.ok THEN Fail ELSE
    LET underlyingInstrumentGuidOptional == ReadBytes(underlyingMinDaysToMaturity.rest, 8) IN IF ~underlyingInstrumentGuidOptional.ok THEN Fail ELSE
    LET underlyingMaturityDate == ReadBytes(underlyingInstrumentGuidOptional.rest, 2) IN IF ~underlyingMaturityDate.ok THEN Fail ELSE
    Ok([ underlyingSymbol                      |-> underlyingSymbol.value,
         underlyingSecurityIdOptional          |-> underlyingSecurityIdOptional.value,
         underlyingSecurityAltId               |-> underlyingSecurityAltId.value,
         underlyingSecurityAltIdSource         |-> underlyingSecurityAltIdSource.value,
         underlyingFinancialInstrumentFullName |-> underlyingFinancialInstrumentFullName.value,
         underlyingSecurityType                |-> underlyingSecurityType.value,
         underlyingCountryOfIssue              |-> underlyingCountryOfIssue.value,
         underlyingIssuer                      |-> underlyingIssuer.value,
         underlyingMaxLifeTime                 |-> underlyingMaxLifeTime.value,
         underlyingMinDaysToMaturity           |-> underlyingMinDaysToMaturity.value,
         underlyingInstrumentGuidOptional      |-> underlyingInstrumentGuidOptional.value,
         underlyingMaturityDate                |-> underlyingMaturityDate.value ], underlyingMaturityDate.rest)

ZeroRepoUnderlyingsGroup ==
    [ underlyingSymbol                      |-> [i \in 1 .. 20 |-> 0],
      underlyingSecurityIdOptional          |-> [i \in 1 .. 4 |-> 0],
      underlyingSecurityAltId               |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityAltIdSource         |-> [i \in 1 .. 1 |-> 0],
      underlyingFinancialInstrumentFullName |-> [i \in 1 .. 35 |-> 0],
      underlyingSecurityType                |-> [i \in 1 .. 6 |-> 0],
      underlyingCountryOfIssue              |-> [i \in 1 .. 2 |-> 0],
      underlyingIssuer                      |-> [i \in 1 .. 25 |-> 0],
      underlyingMaxLifeTime                 |-> [i \in 1 .. 1 |-> 0],
      underlyingMinDaysToMaturity           |-> [i \in 1 .. 2 |-> 0],
      underlyingInstrumentGuidOptional      |-> [i \in 1 .. 8 |-> 0],
      underlyingMaturityDate                |-> [i \in 1 .. 2 |-> 0] ]

(* Repo Underlyings Group at zero, then each field in turn at the values it is checked at *)
CheckedRepoUnderlyingsGroup ==
    { ZeroRepoUnderlyingsGroup }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingSymbol = one] : one \in Sample(20) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingSecurityIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingSecurityAltId = one] : one \in Sample(12) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingSecurityAltIdSource = one] : one \in Sample(1) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingFinancialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingSecurityType = one] : one \in Sample(6) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingCountryOfIssue = one] : one \in Sample(2) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingIssuer = one] : one \in Sample(25) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingMaxLifeTime = one] : one \in Sample(1) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingMinDaysToMaturity = one] : one \in Sample(2) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingInstrumentGuidOptional = one] : one \in Sample(8) }
        \cup { [ZeroRepoUnderlyingsGroup EXCEPT !.underlyingMaturityDate = one] : one \in Sample(2) }

(* A run of Repo Underlyings Group, written one after another *)
RECURSIVE EncodeRepoUnderlyingsGroupList(_)
EncodeRepoUnderlyingsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRepoUnderlyingsGroup(Head(messages)) \o EncodeRepoUnderlyingsGroupList(Tail(messages))

(* As many Repo Underlyings Group as the field that counts them says *)
RECURSIVE ReadRepoUnderlyingsGroupList(_, _)
ReadRepoUnderlyingsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRepoUnderlyingsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRepoUnderlyingsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Repo Underlyings Group of each kind, for the lists that carry them *)
OneRepoUnderlyingsGroup == { ZeroRepoUnderlyingsGroup }

(***************************************************************************)
(* Repo Underlyings Groups                                                 *)
(***************************************************************************)

RepoUnderlyingsGroups ==
    [ blockLength          : Sample(2),
      repoUnderlyingsGroup : SampleLists(OneRepoUnderlyingsGroup) ]

EncodeRepoUnderlyingsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.repoUnderlyingsGroup), 1)
        \o EncodeRepoUnderlyingsGroupList(message.repoUnderlyingsGroup)

DecodeRepoUnderlyingsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET repoUnderlyingsGroup == ReadRepoUnderlyingsGroupList(numInGroup.rest, numInGroup.value) IN IF ~repoUnderlyingsGroup.ok THEN Fail ELSE
    Ok([ blockLength          |-> blockLength.value,
         repoUnderlyingsGroup |-> repoUnderlyingsGroup.value ], repoUnderlyingsGroup.rest)

ZeroRepoUnderlyingsGroups ==
    [ blockLength          |-> [i \in 1 .. 2 |-> 0],
      repoUnderlyingsGroup |-> << >> ]

(* Repo Underlyings Groups at zero, then each field in turn at the values it is checked at *)
CheckedRepoUnderlyingsGroups ==
    { ZeroRepoUnderlyingsGroups }
        \cup { [ZeroRepoUnderlyingsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRepoUnderlyingsGroups EXCEPT !.repoUnderlyingsGroup = one] : one \in SampleLists(OneRepoUnderlyingsGroup) }

(***************************************************************************)
(* Repo Related Instruments Group: 32 bytes                                *)
(***************************************************************************)

RepoRelatedInstrumentsGroup ==
    [ relatedSecurityId     : Sample(4),
      relatedSymbol         : Sample(20),
      relatedInstrumentGuid : Sample(8) ]

EncodeRepoRelatedInstrumentsGroup(message) ==
    message.relatedSecurityId
        \o message.relatedSymbol
        \o message.relatedInstrumentGuid

DecodeRepoRelatedInstrumentsGroup(bytes) ==
    LET relatedSecurityId == ReadBytes(bytes, 4) IN IF ~relatedSecurityId.ok THEN Fail ELSE
    LET relatedSymbol == ReadBytes(relatedSecurityId.rest, 20) IN IF ~relatedSymbol.ok THEN Fail ELSE
    LET relatedInstrumentGuid == ReadBytes(relatedSymbol.rest, 8) IN IF ~relatedInstrumentGuid.ok THEN Fail ELSE
    Ok([ relatedSecurityId     |-> relatedSecurityId.value,
         relatedSymbol         |-> relatedSymbol.value,
         relatedInstrumentGuid |-> relatedInstrumentGuid.value ], relatedInstrumentGuid.rest)

ZeroRepoRelatedInstrumentsGroup ==
    [ relatedSecurityId     |-> [i \in 1 .. 4 |-> 0],
      relatedSymbol         |-> [i \in 1 .. 20 |-> 0],
      relatedInstrumentGuid |-> [i \in 1 .. 8 |-> 0] ]

(* Repo Related Instruments Group at zero, then each field in turn at the values it is checked at *)
CheckedRepoRelatedInstrumentsGroup ==
    { ZeroRepoRelatedInstrumentsGroup }
        \cup { [ZeroRepoRelatedInstrumentsGroup EXCEPT !.relatedSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroRepoRelatedInstrumentsGroup EXCEPT !.relatedSymbol = one] : one \in Sample(20) }
        \cup { [ZeroRepoRelatedInstrumentsGroup EXCEPT !.relatedInstrumentGuid = one] : one \in Sample(8) }

(* A run of Repo Related Instruments Group, written one after another *)
RECURSIVE EncodeRepoRelatedInstrumentsGroupList(_)
EncodeRepoRelatedInstrumentsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRepoRelatedInstrumentsGroup(Head(messages)) \o EncodeRepoRelatedInstrumentsGroupList(Tail(messages))

(* As many Repo Related Instruments Group as the field that counts them says *)
RECURSIVE ReadRepoRelatedInstrumentsGroupList(_, _)
ReadRepoRelatedInstrumentsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRepoRelatedInstrumentsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRepoRelatedInstrumentsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Repo Related Instruments Group of each kind, for the lists that carry them *)
OneRepoRelatedInstrumentsGroup == { ZeroRepoRelatedInstrumentsGroup }

(***************************************************************************)
(* Repo Related Instruments Groups                                         *)
(***************************************************************************)

RepoRelatedInstrumentsGroups ==
    [ blockLength                 : Sample(2),
      repoRelatedInstrumentsGroup : SampleLists(OneRepoRelatedInstrumentsGroup) ]

EncodeRepoRelatedInstrumentsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.repoRelatedInstrumentsGroup), 1)
        \o EncodeRepoRelatedInstrumentsGroupList(message.repoRelatedInstrumentsGroup)

DecodeRepoRelatedInstrumentsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET repoRelatedInstrumentsGroup == ReadRepoRelatedInstrumentsGroupList(numInGroup.rest, numInGroup.value) IN IF ~repoRelatedInstrumentsGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         repoRelatedInstrumentsGroup |-> repoRelatedInstrumentsGroup.value ], repoRelatedInstrumentsGroup.rest)

ZeroRepoRelatedInstrumentsGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      repoRelatedInstrumentsGroup |-> << >> ]

(* Repo Related Instruments Groups at zero, then each field in turn at the values it is checked at *)
CheckedRepoRelatedInstrumentsGroups ==
    { ZeroRepoRelatedInstrumentsGroups }
        \cup { [ZeroRepoRelatedInstrumentsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRepoRelatedInstrumentsGroups EXCEPT !.repoRelatedInstrumentsGroup = one] : one \in SampleLists(OneRepoRelatedInstrumentsGroup) }

(***************************************************************************)
(* Md Instrument Definition Repo                                           *)
(***************************************************************************)

MdInstrumentDefinitionRepo ==
    [ matchEventIndicator          : Sample(1),
      totNumReportsOptional        : Sample(4),
      securityUpdateAction         : Sample(1),
      lastUpdateTime               : Sample(8),
      mdSecurityTradingStatus      : Sample(1),
      applId                       : Sample(2),
      marketSegmentId              : Sample(1),
      underlyingProduct            : Sample(1),
      securityExchange             : Sample(4),
      securityGroup                : Sample(6),
      asset                        : Sample(6),
      symbol                       : Sample(20),
      securityId                   : Sample(4),
      securityType                 : Sample(6),
      cfiCode                      : Sample(6),
      currency                     : Sample(3),
      settlCurrency                : Sample(3),
      matchAlgorithm               : Sample(1),
      minTradeVol                  : Sample(4),
      maxTradeVol                  : Sample(4),
      minPriceIncrementEx          : Sample(8),
      displayFactor                : Sample(8),
      unitOfMeasure                : Sample(30),
      unitOfMeasureQty             : Sample(8),
      tradingReferencePrice        : Sample(8),
      tradingReferenceDate         : Sample(2),
      highLimitPrice               : Sample(8),
      lowLimitPrice                : Sample(8),
      maxPriceVariation            : Sample(8),
      financialInstrumentFullName  : Sample(35),
      partyRoleClearingOrg         : Sample(5),
      startDate                    : Sample(2),
      endDate                      : Sample(2),
      terminationType              : Sample(8),
      repoSubType                  : Sample(1),
      moneyOrPar                   : Sample(1),
      maxNoOfSubstitutions         : Sample(1),
      priceQuoteMethod             : Sample(5),
      userDefinedInstrument        : Sample(1),
      riskSet                      : Sample(6),
      marketSet                    : Sample(6),
      instrumentGuid               : Sample(8),
      termCode                     : Sample(20),
      eventsGroups                 : EventsGroups5,
      feedTypesGroups              : FeedTypesGroups5,
      instAttribGroups             : InstAttribGroups5,
      lotTypeRulesGroups           : LotTypeRulesGroups5,
      repoUnderlyingsGroups        : RepoUnderlyingsGroups,
      repoRelatedInstrumentsGroups : RepoRelatedInstrumentsGroups ]

EncodeMdInstrumentDefinitionRepo(message) ==
    message.matchEventIndicator
        \o message.totNumReportsOptional
        \o message.securityUpdateAction
        \o message.lastUpdateTime
        \o message.mdSecurityTradingStatus
        \o message.applId
        \o message.marketSegmentId
        \o message.underlyingProduct
        \o message.securityExchange
        \o message.securityGroup
        \o message.asset
        \o message.symbol
        \o message.securityId
        \o message.securityType
        \o message.cfiCode
        \o message.currency
        \o message.settlCurrency
        \o message.matchAlgorithm
        \o message.minTradeVol
        \o message.maxTradeVol
        \o message.minPriceIncrementEx
        \o message.displayFactor
        \o message.unitOfMeasure
        \o message.unitOfMeasureQty
        \o message.tradingReferencePrice
        \o message.tradingReferenceDate
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o message.financialInstrumentFullName
        \o message.partyRoleClearingOrg
        \o message.startDate
        \o message.endDate
        \o message.terminationType
        \o message.repoSubType
        \o message.moneyOrPar
        \o message.maxNoOfSubstitutions
        \o message.priceQuoteMethod
        \o message.userDefinedInstrument
        \o message.riskSet
        \o message.marketSet
        \o message.instrumentGuid
        \o message.termCode
        \o EncodeEventsGroups5(message.eventsGroups)
        \o EncodeFeedTypesGroups5(message.feedTypesGroups)
        \o EncodeInstAttribGroups5(message.instAttribGroups)
        \o EncodeLotTypeRulesGroups5(message.lotTypeRulesGroups)
        \o EncodeRepoUnderlyingsGroups(message.repoUnderlyingsGroups)
        \o EncodeRepoRelatedInstrumentsGroups(message.repoRelatedInstrumentsGroups)

DecodeMdInstrumentDefinitionRepo(bytes) ==
    LET matchEventIndicator == ReadBytes(bytes, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET totNumReportsOptional == ReadBytes(matchEventIndicator.rest, 4) IN IF ~totNumReportsOptional.ok THEN Fail ELSE
    LET securityUpdateAction == ReadBytes(totNumReportsOptional.rest, 1) IN IF ~securityUpdateAction.ok THEN Fail ELSE
    LET lastUpdateTime == ReadBytes(securityUpdateAction.rest, 8) IN IF ~lastUpdateTime.ok THEN Fail ELSE
    LET mdSecurityTradingStatus == ReadBytes(lastUpdateTime.rest, 1) IN IF ~mdSecurityTradingStatus.ok THEN Fail ELSE
    LET applId == ReadBytes(mdSecurityTradingStatus.rest, 2) IN IF ~applId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(applId.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingProduct == ReadBytes(marketSegmentId.rest, 1) IN IF ~underlyingProduct.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(underlyingProduct.rest, 4) IN IF ~securityExchange.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(securityExchange.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET asset == ReadBytes(securityGroup.rest, 6) IN IF ~asset.ok THEN Fail ELSE
    LET symbol == ReadBytes(asset.rest, 20) IN IF ~symbol.ok THEN Fail ELSE
    LET securityId == ReadBytes(symbol.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityType == ReadBytes(securityId.rest, 6) IN IF ~securityType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET currency == ReadBytes(cfiCode.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(currency.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET matchAlgorithm == ReadBytes(settlCurrency.rest, 1) IN IF ~matchAlgorithm.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(matchAlgorithm.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET maxTradeVol == ReadBytes(minTradeVol.rest, 4) IN IF ~maxTradeVol.ok THEN Fail ELSE
    LET minPriceIncrementEx == ReadBytes(maxTradeVol.rest, 8) IN IF ~minPriceIncrementEx.ok THEN Fail ELSE
    LET displayFactor == ReadBytes(minPriceIncrementEx.rest, 8) IN IF ~displayFactor.ok THEN Fail ELSE
    LET unitOfMeasure == ReadBytes(displayFactor.rest, 30) IN IF ~unitOfMeasure.ok THEN Fail ELSE
    LET unitOfMeasureQty == ReadBytes(unitOfMeasure.rest, 8) IN IF ~unitOfMeasureQty.ok THEN Fail ELSE
    LET tradingReferencePrice == ReadBytes(unitOfMeasureQty.rest, 8) IN IF ~tradingReferencePrice.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(tradingReferencePrice.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(tradingReferenceDate.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET financialInstrumentFullName == ReadBytes(maxPriceVariation.rest, 35) IN IF ~financialInstrumentFullName.ok THEN Fail ELSE
    LET partyRoleClearingOrg == ReadBytes(financialInstrumentFullName.rest, 5) IN IF ~partyRoleClearingOrg.ok THEN Fail ELSE
    LET startDate == ReadBytes(partyRoleClearingOrg.rest, 2) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 2) IN IF ~endDate.ok THEN Fail ELSE
    LET terminationType == ReadBytes(endDate.rest, 8) IN IF ~terminationType.ok THEN Fail ELSE
    LET repoSubType == ReadBytes(terminationType.rest, 1) IN IF ~repoSubType.ok THEN Fail ELSE
    LET moneyOrPar == ReadBytes(repoSubType.rest, 1) IN IF ~moneyOrPar.ok THEN Fail ELSE
    LET maxNoOfSubstitutions == ReadBytes(moneyOrPar.rest, 1) IN IF ~maxNoOfSubstitutions.ok THEN Fail ELSE
    LET priceQuoteMethod == ReadBytes(maxNoOfSubstitutions.rest, 5) IN IF ~priceQuoteMethod.ok THEN Fail ELSE
    LET userDefinedInstrument == ReadBytes(priceQuoteMethod.rest, 1) IN IF ~userDefinedInstrument.ok THEN Fail ELSE
    LET riskSet == ReadBytes(userDefinedInstrument.rest, 6) IN IF ~riskSet.ok THEN Fail ELSE
    LET marketSet == ReadBytes(riskSet.rest, 6) IN IF ~marketSet.ok THEN Fail ELSE
    LET instrumentGuid == ReadBytes(marketSet.rest, 8) IN IF ~instrumentGuid.ok THEN Fail ELSE
    LET termCode == ReadBytes(instrumentGuid.rest, 20) IN IF ~termCode.ok THEN Fail ELSE
    LET eventsGroups == DecodeEventsGroups5(termCode.rest) IN IF ~eventsGroups.ok THEN Fail ELSE
    LET feedTypesGroups == DecodeFeedTypesGroups5(eventsGroups.rest) IN IF ~feedTypesGroups.ok THEN Fail ELSE
    LET instAttribGroups == DecodeInstAttribGroups5(feedTypesGroups.rest) IN IF ~instAttribGroups.ok THEN Fail ELSE
    LET lotTypeRulesGroups == DecodeLotTypeRulesGroups5(instAttribGroups.rest) IN IF ~lotTypeRulesGroups.ok THEN Fail ELSE
    LET repoUnderlyingsGroups == DecodeRepoUnderlyingsGroups(lotTypeRulesGroups.rest) IN IF ~repoUnderlyingsGroups.ok THEN Fail ELSE
    LET repoRelatedInstrumentsGroups == DecodeRepoRelatedInstrumentsGroups(repoUnderlyingsGroups.rest) IN IF ~repoRelatedInstrumentsGroups.ok THEN Fail ELSE
    Ok([ matchEventIndicator          |-> matchEventIndicator.value,
         totNumReportsOptional        |-> totNumReportsOptional.value,
         securityUpdateAction         |-> securityUpdateAction.value,
         lastUpdateTime               |-> lastUpdateTime.value,
         mdSecurityTradingStatus      |-> mdSecurityTradingStatus.value,
         applId                       |-> applId.value,
         marketSegmentId              |-> marketSegmentId.value,
         underlyingProduct            |-> underlyingProduct.value,
         securityExchange             |-> securityExchange.value,
         securityGroup                |-> securityGroup.value,
         asset                        |-> asset.value,
         symbol                       |-> symbol.value,
         securityId                   |-> securityId.value,
         securityType                 |-> securityType.value,
         cfiCode                      |-> cfiCode.value,
         currency                     |-> currency.value,
         settlCurrency                |-> settlCurrency.value,
         matchAlgorithm               |-> matchAlgorithm.value,
         minTradeVol                  |-> minTradeVol.value,
         maxTradeVol                  |-> maxTradeVol.value,
         minPriceIncrementEx          |-> minPriceIncrementEx.value,
         displayFactor                |-> displayFactor.value,
         unitOfMeasure                |-> unitOfMeasure.value,
         unitOfMeasureQty             |-> unitOfMeasureQty.value,
         tradingReferencePrice        |-> tradingReferencePrice.value,
         tradingReferenceDate         |-> tradingReferenceDate.value,
         highLimitPrice               |-> highLimitPrice.value,
         lowLimitPrice                |-> lowLimitPrice.value,
         maxPriceVariation            |-> maxPriceVariation.value,
         financialInstrumentFullName  |-> financialInstrumentFullName.value,
         partyRoleClearingOrg         |-> partyRoleClearingOrg.value,
         startDate                    |-> startDate.value,
         endDate                      |-> endDate.value,
         terminationType              |-> terminationType.value,
         repoSubType                  |-> repoSubType.value,
         moneyOrPar                   |-> moneyOrPar.value,
         maxNoOfSubstitutions         |-> maxNoOfSubstitutions.value,
         priceQuoteMethod             |-> priceQuoteMethod.value,
         userDefinedInstrument        |-> userDefinedInstrument.value,
         riskSet                      |-> riskSet.value,
         marketSet                    |-> marketSet.value,
         instrumentGuid               |-> instrumentGuid.value,
         termCode                     |-> termCode.value,
         eventsGroups                 |-> eventsGroups.value,
         feedTypesGroups              |-> feedTypesGroups.value,
         instAttribGroups             |-> instAttribGroups.value,
         lotTypeRulesGroups           |-> lotTypeRulesGroups.value,
         repoUnderlyingsGroups        |-> repoUnderlyingsGroups.value,
         repoRelatedInstrumentsGroups |-> repoRelatedInstrumentsGroups.value ], repoRelatedInstrumentsGroups.rest)

ZeroMdInstrumentDefinitionRepo ==
    [ matchEventIndicator          |-> [i \in 1 .. 1 |-> 0],
      totNumReportsOptional        |-> [i \in 1 .. 4 |-> 0],
      securityUpdateAction         |-> [i \in 1 .. 1 |-> 0],
      lastUpdateTime               |-> [i \in 1 .. 8 |-> 0],
      mdSecurityTradingStatus      |-> [i \in 1 .. 1 |-> 0],
      applId                       |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 1 |-> 0],
      underlyingProduct            |-> [i \in 1 .. 1 |-> 0],
      securityExchange             |-> [i \in 1 .. 4 |-> 0],
      securityGroup                |-> [i \in 1 .. 6 |-> 0],
      asset                        |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 20 |-> 0],
      securityId                   |-> [i \in 1 .. 4 |-> 0],
      securityType                 |-> [i \in 1 .. 6 |-> 0],
      cfiCode                      |-> [i \in 1 .. 6 |-> 0],
      currency                     |-> [i \in 1 .. 3 |-> 0],
      settlCurrency                |-> [i \in 1 .. 3 |-> 0],
      matchAlgorithm               |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                  |-> [i \in 1 .. 4 |-> 0],
      maxTradeVol                  |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrementEx          |-> [i \in 1 .. 8 |-> 0],
      displayFactor                |-> [i \in 1 .. 8 |-> 0],
      unitOfMeasure                |-> [i \in 1 .. 30 |-> 0],
      unitOfMeasureQty             |-> [i \in 1 .. 8 |-> 0],
      tradingReferencePrice        |-> [i \in 1 .. 8 |-> 0],
      tradingReferenceDate         |-> [i \in 1 .. 2 |-> 0],
      highLimitPrice               |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice                |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation            |-> [i \in 1 .. 8 |-> 0],
      financialInstrumentFullName  |-> [i \in 1 .. 35 |-> 0],
      partyRoleClearingOrg         |-> [i \in 1 .. 5 |-> 0],
      startDate                    |-> [i \in 1 .. 2 |-> 0],
      endDate                      |-> [i \in 1 .. 2 |-> 0],
      terminationType              |-> [i \in 1 .. 8 |-> 0],
      repoSubType                  |-> [i \in 1 .. 1 |-> 0],
      moneyOrPar                   |-> [i \in 1 .. 1 |-> 0],
      maxNoOfSubstitutions         |-> [i \in 1 .. 1 |-> 0],
      priceQuoteMethod             |-> [i \in 1 .. 5 |-> 0],
      userDefinedInstrument        |-> [i \in 1 .. 1 |-> 0],
      riskSet                      |-> [i \in 1 .. 6 |-> 0],
      marketSet                    |-> [i \in 1 .. 6 |-> 0],
      instrumentGuid               |-> [i \in 1 .. 8 |-> 0],
      termCode                     |-> [i \in 1 .. 20 |-> 0],
      eventsGroups                 |-> ZeroEventsGroups5,
      feedTypesGroups              |-> ZeroFeedTypesGroups5,
      instAttribGroups             |-> ZeroInstAttribGroups5,
      lotTypeRulesGroups           |-> ZeroLotTypeRulesGroups5,
      repoUnderlyingsGroups        |-> ZeroRepoUnderlyingsGroups,
      repoRelatedInstrumentsGroups |-> ZeroRepoRelatedInstrumentsGroups ]

(* Md Instrument Definition Repo at zero, then each field in turn at the values it is checked at *)
CheckedMdInstrumentDefinitionRepo ==
    { ZeroMdInstrumentDefinitionRepo }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.totNumReportsOptional = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.securityUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.lastUpdateTime = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.mdSecurityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.applId = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.underlyingProduct = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.securityExchange = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.asset = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.symbol = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.securityType = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.matchAlgorithm = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.maxTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.minPriceIncrementEx = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.displayFactor = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.unitOfMeasure = one] : one \in Sample(30) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.unitOfMeasureQty = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.tradingReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.financialInstrumentFullName = one] : one \in Sample(35) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.partyRoleClearingOrg = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.startDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.endDate = one] : one \in Sample(2) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.terminationType = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.repoSubType = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.moneyOrPar = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.maxNoOfSubstitutions = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.priceQuoteMethod = one] : one \in Sample(5) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.userDefinedInstrument = one] : one \in Sample(1) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.riskSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.marketSet = one] : one \in Sample(6) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.instrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.termCode = one] : one \in Sample(20) }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.eventsGroups = one] : one \in CheckedEventsGroups5 }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.feedTypesGroups = one] : one \in CheckedFeedTypesGroups5 }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.instAttribGroups = one] : one \in CheckedInstAttribGroups5 }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.lotTypeRulesGroups = one] : one \in CheckedLotTypeRulesGroups5 }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.repoUnderlyingsGroups = one] : one \in CheckedRepoUnderlyingsGroups }
        \cup { [ZeroMdInstrumentDefinitionRepo EXCEPT !.repoRelatedInstrumentsGroups = one] : one \in CheckedRepoRelatedInstrumentsGroups }

(***************************************************************************)
(* Snapshot Refresh Top Orders Group: 29 bytes                             *)
(***************************************************************************)

SnapshotRefreshTopOrdersGroup ==
    [ orderId         : Sample(8),
      mdOrderPriority : Sample(8),
      mdEntryPxEx     : Sample(8),
      mdDisplayQty    : Sample(4),
      mdEntryTypeBook : Sample(1) ]

EncodeSnapshotRefreshTopOrdersGroup(message) ==
    message.orderId
        \o message.mdOrderPriority
        \o message.mdEntryPxEx
        \o message.mdDisplayQty
        \o message.mdEntryTypeBook

DecodeSnapshotRefreshTopOrdersGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET mdOrderPriority == ReadBytes(orderId.rest, 8) IN IF ~mdOrderPriority.ok THEN Fail ELSE
    LET mdEntryPxEx == ReadBytes(mdOrderPriority.rest, 8) IN IF ~mdEntryPxEx.ok THEN Fail ELSE
    LET mdDisplayQty == ReadBytes(mdEntryPxEx.rest, 4) IN IF ~mdDisplayQty.ok THEN Fail ELSE
    LET mdEntryTypeBook == ReadBytes(mdDisplayQty.rest, 1) IN IF ~mdEntryTypeBook.ok THEN Fail ELSE
    Ok([ orderId         |-> orderId.value,
         mdOrderPriority |-> mdOrderPriority.value,
         mdEntryPxEx     |-> mdEntryPxEx.value,
         mdDisplayQty    |-> mdDisplayQty.value,
         mdEntryTypeBook |-> mdEntryTypeBook.value ], mdEntryTypeBook.rest)

ZeroSnapshotRefreshTopOrdersGroup ==
    [ orderId         |-> [i \in 1 .. 8 |-> 0],
      mdOrderPriority |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxEx     |-> [i \in 1 .. 8 |-> 0],
      mdDisplayQty    |-> [i \in 1 .. 4 |-> 0],
      mdEntryTypeBook |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Refresh Top Orders Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshTopOrdersGroup ==
    { ZeroSnapshotRefreshTopOrdersGroup }
        \cup { [ZeroSnapshotRefreshTopOrdersGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTopOrdersGroup EXCEPT !.mdOrderPriority = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTopOrdersGroup EXCEPT !.mdEntryPxEx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTopOrdersGroup EXCEPT !.mdDisplayQty = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRefreshTopOrdersGroup EXCEPT !.mdEntryTypeBook = one] : one \in Sample(1) }

(* A run of Snapshot Refresh Top Orders Group, written one after another *)
RECURSIVE EncodeSnapshotRefreshTopOrdersGroupList(_)
EncodeSnapshotRefreshTopOrdersGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotRefreshTopOrdersGroup(Head(messages)) \o EncodeSnapshotRefreshTopOrdersGroupList(Tail(messages))

(* As many Snapshot Refresh Top Orders Group as the field that counts them says *)
RECURSIVE ReadSnapshotRefreshTopOrdersGroupList(_, _)
ReadSnapshotRefreshTopOrdersGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotRefreshTopOrdersGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotRefreshTopOrdersGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Refresh Top Orders Group of each kind, for the lists that carry them *)
OneSnapshotRefreshTopOrdersGroup == { ZeroSnapshotRefreshTopOrdersGroup }

(***************************************************************************)
(* Snapshot Refresh Top Orders Groups                                      *)
(***************************************************************************)

SnapshotRefreshTopOrdersGroups ==
    [ blockLength                   : Sample(2),
      snapshotRefreshTopOrdersGroup : SampleLists(OneSnapshotRefreshTopOrdersGroup) ]

EncodeSnapshotRefreshTopOrdersGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotRefreshTopOrdersGroup), 1)
        \o EncodeSnapshotRefreshTopOrdersGroupList(message.snapshotRefreshTopOrdersGroup)

DecodeSnapshotRefreshTopOrdersGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotRefreshTopOrdersGroup == ReadSnapshotRefreshTopOrdersGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotRefreshTopOrdersGroup.ok THEN Fail ELSE
    Ok([ blockLength                   |-> blockLength.value,
         snapshotRefreshTopOrdersGroup |-> snapshotRefreshTopOrdersGroup.value ], snapshotRefreshTopOrdersGroup.rest)

ZeroSnapshotRefreshTopOrdersGroups ==
    [ blockLength                   |-> [i \in 1 .. 2 |-> 0],
      snapshotRefreshTopOrdersGroup |-> << >> ]

(* Snapshot Refresh Top Orders Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshTopOrdersGroups ==
    { ZeroSnapshotRefreshTopOrdersGroups }
        \cup { [ZeroSnapshotRefreshTopOrdersGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotRefreshTopOrdersGroups EXCEPT !.snapshotRefreshTopOrdersGroup = one] : one \in SampleLists(OneSnapshotRefreshTopOrdersGroup) }

(***************************************************************************)
(* Snapshot Refresh Top Orders                                             *)
(***************************************************************************)

SnapshotRefreshTopOrders ==
    [ transactTime                   : Sample(8),
      matchEventIndicator            : Sample(1),
      securityId                     : Sample(4),
      snapshotRefreshTopOrdersGroups : SnapshotRefreshTopOrdersGroups ]

EncodeSnapshotRefreshTopOrders(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.securityId
        \o EncodeSnapshotRefreshTopOrdersGroups(message.snapshotRefreshTopOrdersGroups)

DecodeSnapshotRefreshTopOrders(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET securityId == ReadBytes(matchEventIndicator.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET snapshotRefreshTopOrdersGroups == DecodeSnapshotRefreshTopOrdersGroups(securityId.rest) IN IF ~snapshotRefreshTopOrdersGroups.ok THEN Fail ELSE
    Ok([ transactTime                   |-> transactTime.value,
         matchEventIndicator            |-> matchEventIndicator.value,
         securityId                     |-> securityId.value,
         snapshotRefreshTopOrdersGroups |-> snapshotRefreshTopOrdersGroups.value ], snapshotRefreshTopOrdersGroups.rest)

ZeroSnapshotRefreshTopOrders ==
    [ transactTime                   |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator            |-> [i \in 1 .. 1 |-> 0],
      securityId                     |-> [i \in 1 .. 4 |-> 0],
      snapshotRefreshTopOrdersGroups |-> ZeroSnapshotRefreshTopOrdersGroups ]

(* Snapshot Refresh Top Orders at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRefreshTopOrders ==
    { ZeroSnapshotRefreshTopOrders }
        \cup { [ZeroSnapshotRefreshTopOrders EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotRefreshTopOrders EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotRefreshTopOrders EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRefreshTopOrders EXCEPT !.snapshotRefreshTopOrdersGroups = one] : one \in CheckedSnapshotRefreshTopOrdersGroups }

(***************************************************************************)
(* Security Status Workup Group: 10 bytes                                  *)
(***************************************************************************)

SecurityStatusWorkupGroup ==
    [ orderId            : Sample(8),
      side               : Sample(1),
      aggressorIndicator : Sample(1) ]

EncodeSecurityStatusWorkupGroup(message) ==
    message.orderId
        \o message.side
        \o message.aggressorIndicator

DecodeSecurityStatusWorkupGroup(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(side.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    Ok([ orderId            |-> orderId.value,
         side               |-> side.value,
         aggressorIndicator |-> aggressorIndicator.value ], aggressorIndicator.rest)

ZeroSecurityStatusWorkupGroup ==
    [ orderId            |-> [i \in 1 .. 8 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Security Status Workup Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusWorkupGroup ==
    { ZeroSecurityStatusWorkupGroup }
        \cup { [ZeroSecurityStatusWorkupGroup EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusWorkupGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusWorkupGroup EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }

(* A run of Security Status Workup Group, written one after another *)
RECURSIVE EncodeSecurityStatusWorkupGroupList(_)
EncodeSecurityStatusWorkupGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusWorkupGroup(Head(messages)) \o EncodeSecurityStatusWorkupGroupList(Tail(messages))

(* As many Security Status Workup Group as the field that counts them says *)
RECURSIVE ReadSecurityStatusWorkupGroupList(_, _)
ReadSecurityStatusWorkupGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusWorkupGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusWorkupGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Workup Group of each kind, for the lists that carry them *)
OneSecurityStatusWorkupGroup == { ZeroSecurityStatusWorkupGroup }

(***************************************************************************)
(* Security Status Workup Groups                                           *)
(***************************************************************************)

SecurityStatusWorkupGroups ==
    [ blockLength               : Sample(2),
      securityStatusWorkupGroup : SampleLists(OneSecurityStatusWorkupGroup) ]

EncodeSecurityStatusWorkupGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityStatusWorkupGroup), 1)
        \o EncodeSecurityStatusWorkupGroupList(message.securityStatusWorkupGroup)

DecodeSecurityStatusWorkupGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityStatusWorkupGroup == ReadSecurityStatusWorkupGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityStatusWorkupGroup.ok THEN Fail ELSE
    Ok([ blockLength               |-> blockLength.value,
         securityStatusWorkupGroup |-> securityStatusWorkupGroup.value ], securityStatusWorkupGroup.rest)

ZeroSecurityStatusWorkupGroups ==
    [ blockLength               |-> [i \in 1 .. 2 |-> 0],
      securityStatusWorkupGroup |-> << >> ]

(* Security Status Workup Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusWorkupGroups ==
    { ZeroSecurityStatusWorkupGroups }
        \cup { [ZeroSecurityStatusWorkupGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusWorkupGroups EXCEPT !.securityStatusWorkupGroup = one] : one \in SampleLists(OneSecurityStatusWorkupGroup) }

(***************************************************************************)
(* Security Status Workup                                                  *)
(***************************************************************************)

SecurityStatusWorkup ==
    [ transactTime               : Sample(8),
      mdEntryPxOptionalEx        : Sample(8),
      securityId                 : Sample(4),
      matchEventIndicator        : Sample(1),
      tradeDate                  : Sample(2),
      tradeLinkId                : Sample(4),
      workupTradingStatus        : Sample(1),
      haltReason                 : Sample(1),
      securityTradingEvent       : Sample(1),
      securityStatusWorkupGroups : SecurityStatusWorkupGroups ]

EncodeSecurityStatusWorkup(message) ==
    message.transactTime
        \o message.mdEntryPxOptionalEx
        \o message.securityId
        \o message.matchEventIndicator
        \o message.tradeDate
        \o message.tradeLinkId
        \o message.workupTradingStatus
        \o message.haltReason
        \o message.securityTradingEvent
        \o EncodeSecurityStatusWorkupGroups(message.securityStatusWorkupGroups)

DecodeSecurityStatusWorkup(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET mdEntryPxOptionalEx == ReadBytes(transactTime.rest, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(securityId.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(matchEventIndicator.rest, 2) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeLinkId == ReadBytes(tradeDate.rest, 4) IN IF ~tradeLinkId.ok THEN Fail ELSE
    LET workupTradingStatus == ReadBytes(tradeLinkId.rest, 1) IN IF ~workupTradingStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(workupTradingStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET securityTradingEvent == ReadBytes(haltReason.rest, 1) IN IF ~securityTradingEvent.ok THEN Fail ELSE
    LET securityStatusWorkupGroups == DecodeSecurityStatusWorkupGroups(securityTradingEvent.rest) IN IF ~securityStatusWorkupGroups.ok THEN Fail ELSE
    Ok([ transactTime               |-> transactTime.value,
         mdEntryPxOptionalEx        |-> mdEntryPxOptionalEx.value,
         securityId                 |-> securityId.value,
         matchEventIndicator        |-> matchEventIndicator.value,
         tradeDate                  |-> tradeDate.value,
         tradeLinkId                |-> tradeLinkId.value,
         workupTradingStatus        |-> workupTradingStatus.value,
         haltReason                 |-> haltReason.value,
         securityTradingEvent       |-> securityTradingEvent.value,
         securityStatusWorkupGroups |-> securityStatusWorkupGroups.value ], securityStatusWorkupGroups.rest)

ZeroSecurityStatusWorkup ==
    [ transactTime               |-> [i \in 1 .. 8 |-> 0],
      mdEntryPxOptionalEx        |-> [i \in 1 .. 8 |-> 0],
      securityId                 |-> [i \in 1 .. 4 |-> 0],
      matchEventIndicator        |-> [i \in 1 .. 1 |-> 0],
      tradeDate                  |-> [i \in 1 .. 2 |-> 0],
      tradeLinkId                |-> [i \in 1 .. 4 |-> 0],
      workupTradingStatus        |-> [i \in 1 .. 1 |-> 0],
      haltReason                 |-> [i \in 1 .. 1 |-> 0],
      securityTradingEvent       |-> [i \in 1 .. 1 |-> 0],
      securityStatusWorkupGroups |-> ZeroSecurityStatusWorkupGroups ]

(* Security Status Workup at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusWorkup ==
    { ZeroSecurityStatusWorkup }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.tradeDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.tradeLinkId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.workupTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.securityTradingEvent = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusWorkup EXCEPT !.securityStatusWorkupGroups = one] : one \in CheckedSecurityStatusWorkupGroups }

(***************************************************************************)
(* Snapshot Full Refresh Tcp Group: 26 bytes                               *)
(***************************************************************************)

SnapshotFullRefreshTcpGroup ==
    [ mdEntryPxOptionalEx      : Sample(8),
      mdEntrySizeShortOptional : Sample(4),
      tradeableSize            : Sample(4),
      numberOfOrdersOptional   : Sample(4),
      mdPriceLevelOptional     : Sample(1),
      openCloseSettlFlag       : Sample(1),
      mdEntryType              : Sample(1),
      tradingReferenceDate     : Sample(2),
      settlPriceType           : Sample(1) ]

EncodeSnapshotFullRefreshTcpGroup(message) ==
    message.mdEntryPxOptionalEx
        \o message.mdEntrySizeShortOptional
        \o message.tradeableSize
        \o message.numberOfOrdersOptional
        \o message.mdPriceLevelOptional
        \o message.openCloseSettlFlag
        \o message.mdEntryType
        \o message.tradingReferenceDate
        \o message.settlPriceType

DecodeSnapshotFullRefreshTcpGroup(bytes) ==
    LET mdEntryPxOptionalEx == ReadBytes(bytes, 8) IN IF ~mdEntryPxOptionalEx.ok THEN Fail ELSE
    LET mdEntrySizeShortOptional == ReadBytes(mdEntryPxOptionalEx.rest, 4) IN IF ~mdEntrySizeShortOptional.ok THEN Fail ELSE
    LET tradeableSize == ReadBytes(mdEntrySizeShortOptional.rest, 4) IN IF ~tradeableSize.ok THEN Fail ELSE
    LET numberOfOrdersOptional == ReadBytes(tradeableSize.rest, 4) IN IF ~numberOfOrdersOptional.ok THEN Fail ELSE
    LET mdPriceLevelOptional == ReadBytes(numberOfOrdersOptional.rest, 1) IN IF ~mdPriceLevelOptional.ok THEN Fail ELSE
    LET openCloseSettlFlag == ReadBytes(mdPriceLevelOptional.rest, 1) IN IF ~openCloseSettlFlag.ok THEN Fail ELSE
    LET mdEntryType == ReadBytes(openCloseSettlFlag.rest, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET tradingReferenceDate == ReadBytes(mdEntryType.rest, 2) IN IF ~tradingReferenceDate.ok THEN Fail ELSE
    LET settlPriceType == ReadBytes(tradingReferenceDate.rest, 1) IN IF ~settlPriceType.ok THEN Fail ELSE
    Ok([ mdEntryPxOptionalEx      |-> mdEntryPxOptionalEx.value,
         mdEntrySizeShortOptional |-> mdEntrySizeShortOptional.value,
         tradeableSize            |-> tradeableSize.value,
         numberOfOrdersOptional   |-> numberOfOrdersOptional.value,
         mdPriceLevelOptional     |-> mdPriceLevelOptional.value,
         openCloseSettlFlag       |-> openCloseSettlFlag.value,
         mdEntryType              |-> mdEntryType.value,
         tradingReferenceDate     |-> tradingReferenceDate.value,
         settlPriceType           |-> settlPriceType.value ], settlPriceType.rest)

ZeroSnapshotFullRefreshTcpGroup ==
    [ mdEntryPxOptionalEx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySizeShortOptional |-> [i \in 1 .. 4 |-> 0],
      tradeableSize            |-> [i \in 1 .. 4 |-> 0],
      numberOfOrdersOptional   |-> [i \in 1 .. 4 |-> 0],
      mdPriceLevelOptional     |-> [i \in 1 .. 1 |-> 0],
      openCloseSettlFlag       |-> [i \in 1 .. 1 |-> 0],
      mdEntryType              |-> [i \in 1 .. 1 |-> 0],
      tradingReferenceDate     |-> [i \in 1 .. 2 |-> 0],
      settlPriceType           |-> [i \in 1 .. 1 |-> 0] ]

(* Snapshot Full Refresh Tcp Group at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshTcpGroup ==
    { ZeroSnapshotFullRefreshTcpGroup }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.mdEntryPxOptionalEx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.mdEntrySizeShortOptional = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.tradeableSize = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.numberOfOrdersOptional = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.mdPriceLevelOptional = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.openCloseSettlFlag = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.tradingReferenceDate = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshTcpGroup EXCEPT !.settlPriceType = one] : one \in Sample(1) }

(* A run of Snapshot Full Refresh Tcp Group, written one after another *)
RECURSIVE EncodeSnapshotFullRefreshTcpGroupList(_)
EncodeSnapshotFullRefreshTcpGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSnapshotFullRefreshTcpGroup(Head(messages)) \o EncodeSnapshotFullRefreshTcpGroupList(Tail(messages))

(* As many Snapshot Full Refresh Tcp Group as the field that counts them says *)
RECURSIVE ReadSnapshotFullRefreshTcpGroupList(_, _)
ReadSnapshotFullRefreshTcpGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSnapshotFullRefreshTcpGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSnapshotFullRefreshTcpGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Snapshot Full Refresh Tcp Group of each kind, for the lists that carry them *)
OneSnapshotFullRefreshTcpGroup == { ZeroSnapshotFullRefreshTcpGroup }

(***************************************************************************)
(* Snapshot Full Refresh Tcp Groups                                        *)
(***************************************************************************)

SnapshotFullRefreshTcpGroups ==
    [ blockLength                 : Sample(2),
      snapshotFullRefreshTcpGroup : SampleLists(OneSnapshotFullRefreshTcpGroup) ]

EncodeSnapshotFullRefreshTcpGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.snapshotFullRefreshTcpGroup), 1)
        \o EncodeSnapshotFullRefreshTcpGroupList(message.snapshotFullRefreshTcpGroup)

DecodeSnapshotFullRefreshTcpGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET snapshotFullRefreshTcpGroup == ReadSnapshotFullRefreshTcpGroupList(numInGroup.rest, numInGroup.value) IN IF ~snapshotFullRefreshTcpGroup.ok THEN Fail ELSE
    Ok([ blockLength                 |-> blockLength.value,
         snapshotFullRefreshTcpGroup |-> snapshotFullRefreshTcpGroup.value ], snapshotFullRefreshTcpGroup.rest)

ZeroSnapshotFullRefreshTcpGroups ==
    [ blockLength                 |-> [i \in 1 .. 2 |-> 0],
      snapshotFullRefreshTcpGroup |-> << >> ]

(* Snapshot Full Refresh Tcp Groups at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshTcpGroups ==
    { ZeroSnapshotFullRefreshTcpGroups }
        \cup { [ZeroSnapshotFullRefreshTcpGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotFullRefreshTcpGroups EXCEPT !.snapshotFullRefreshTcpGroup = one] : one \in SampleLists(OneSnapshotFullRefreshTcpGroup) }

(***************************************************************************)
(* Snapshot Full Refresh Tcp                                               *)
(***************************************************************************)

SnapshotFullRefreshTcp ==
    [ transactTime                 : Sample(8),
      matchEventIndicator          : Sample(1),
      securityId                   : Sample(4),
      highLimitPrice               : Sample(8),
      lowLimitPrice                : Sample(8),
      maxPriceVariation            : Sample(8),
      snapshotFullRefreshTcpGroups : SnapshotFullRefreshTcpGroups ]

EncodeSnapshotFullRefreshTcp(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.securityId
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.maxPriceVariation
        \o EncodeSnapshotFullRefreshTcpGroups(message.snapshotFullRefreshTcpGroups)

DecodeSnapshotFullRefreshTcp(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET securityId == ReadBytes(matchEventIndicator.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(securityId.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET maxPriceVariation == ReadBytes(lowLimitPrice.rest, 8) IN IF ~maxPriceVariation.ok THEN Fail ELSE
    LET snapshotFullRefreshTcpGroups == DecodeSnapshotFullRefreshTcpGroups(maxPriceVariation.rest) IN IF ~snapshotFullRefreshTcpGroups.ok THEN Fail ELSE
    Ok([ transactTime                 |-> transactTime.value,
         matchEventIndicator          |-> matchEventIndicator.value,
         securityId                   |-> securityId.value,
         highLimitPrice               |-> highLimitPrice.value,
         lowLimitPrice                |-> lowLimitPrice.value,
         maxPriceVariation            |-> maxPriceVariation.value,
         snapshotFullRefreshTcpGroups |-> snapshotFullRefreshTcpGroups.value ], snapshotFullRefreshTcpGroups.rest)

ZeroSnapshotFullRefreshTcp ==
    [ transactTime                 |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator          |-> [i \in 1 .. 1 |-> 0],
      securityId                   |-> [i \in 1 .. 4 |-> 0],
      highLimitPrice               |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice                |-> [i \in 1 .. 8 |-> 0],
      maxPriceVariation            |-> [i \in 1 .. 8 |-> 0],
      snapshotFullRefreshTcpGroups |-> ZeroSnapshotFullRefreshTcpGroups ]

(* Snapshot Full Refresh Tcp at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotFullRefreshTcp ==
    { ZeroSnapshotFullRefreshTcp }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.maxPriceVariation = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotFullRefreshTcp EXCEPT !.snapshotFullRefreshTcpGroups = one] : one \in CheckedSnapshotFullRefreshTcpGroups }

(***************************************************************************)
(* Collateral Market Value Group: 40 bytes                                 *)
(***************************************************************************)

CollateralMarketValueGroup ==
    [ underlyingSecurityAltId       : Sample(12),
      underlyingSecurityAltIdSource : Sample(1),
      collateralMarketPrice         : Sample(8),
      dirtyPrice                    : Sample(8),
      underlyingInstrumentGuid      : Sample(8),
      mdStreamId                    : Sample(1),
      padding2                      : Sample(2) ]

EncodeCollateralMarketValueGroup(message) ==
    message.underlyingSecurityAltId
        \o message.underlyingSecurityAltIdSource
        \o message.collateralMarketPrice
        \o message.dirtyPrice
        \o message.underlyingInstrumentGuid
        \o message.mdStreamId
        \o message.padding2

DecodeCollateralMarketValueGroup(bytes) ==
    LET underlyingSecurityAltId == ReadBytes(bytes, 12) IN IF ~underlyingSecurityAltId.ok THEN Fail ELSE
    LET underlyingSecurityAltIdSource == ReadBytes(underlyingSecurityAltId.rest, 1) IN IF ~underlyingSecurityAltIdSource.ok THEN Fail ELSE
    LET collateralMarketPrice == ReadBytes(underlyingSecurityAltIdSource.rest, 8) IN IF ~collateralMarketPrice.ok THEN Fail ELSE
    LET dirtyPrice == ReadBytes(collateralMarketPrice.rest, 8) IN IF ~dirtyPrice.ok THEN Fail ELSE
    LET underlyingInstrumentGuid == ReadBytes(dirtyPrice.rest, 8) IN IF ~underlyingInstrumentGuid.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(underlyingInstrumentGuid.rest, 1) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET padding2 == ReadBytes(mdStreamId.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    Ok([ underlyingSecurityAltId       |-> underlyingSecurityAltId.value,
         underlyingSecurityAltIdSource |-> underlyingSecurityAltIdSource.value,
         collateralMarketPrice         |-> collateralMarketPrice.value,
         dirtyPrice                    |-> dirtyPrice.value,
         underlyingInstrumentGuid      |-> underlyingInstrumentGuid.value,
         mdStreamId                    |-> mdStreamId.value,
         padding2                      |-> padding2.value ], padding2.rest)

ZeroCollateralMarketValueGroup ==
    [ underlyingSecurityAltId       |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityAltIdSource |-> [i \in 1 .. 1 |-> 0],
      collateralMarketPrice         |-> [i \in 1 .. 8 |-> 0],
      dirtyPrice                    |-> [i \in 1 .. 8 |-> 0],
      underlyingInstrumentGuid      |-> [i \in 1 .. 8 |-> 0],
      mdStreamId                    |-> [i \in 1 .. 1 |-> 0],
      padding2                      |-> [i \in 1 .. 2 |-> 0] ]

(* Collateral Market Value Group at zero, then each field in turn at the values it is checked at *)
CheckedCollateralMarketValueGroup ==
    { ZeroCollateralMarketValueGroup }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.underlyingSecurityAltId = one] : one \in Sample(12) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.underlyingSecurityAltIdSource = one] : one \in Sample(1) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.collateralMarketPrice = one] : one \in Sample(8) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.dirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.underlyingInstrumentGuid = one] : one \in Sample(8) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.mdStreamId = one] : one \in Sample(1) }
        \cup { [ZeroCollateralMarketValueGroup EXCEPT !.padding2 = one] : one \in Sample(2) }

(* A run of Collateral Market Value Group, written one after another *)
RECURSIVE EncodeCollateralMarketValueGroupList(_)
EncodeCollateralMarketValueGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCollateralMarketValueGroup(Head(messages)) \o EncodeCollateralMarketValueGroupList(Tail(messages))

(* As many Collateral Market Value Group as the field that counts them says *)
RECURSIVE ReadCollateralMarketValueGroupList(_, _)
ReadCollateralMarketValueGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCollateralMarketValueGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCollateralMarketValueGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Collateral Market Value Group of each kind, for the lists that carry them *)
OneCollateralMarketValueGroup == { ZeroCollateralMarketValueGroup }

(***************************************************************************)
(* Collateral Market Value Groups                                          *)
(***************************************************************************)

CollateralMarketValueGroups ==
    [ blockLength                : Sample(2),
      collateralMarketValueGroup : SampleLists(OneCollateralMarketValueGroup) ]

EncodeCollateralMarketValueGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.collateralMarketValueGroup), 1)
        \o EncodeCollateralMarketValueGroupList(message.collateralMarketValueGroup)

DecodeCollateralMarketValueGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET collateralMarketValueGroup == ReadCollateralMarketValueGroupList(numInGroup.rest, numInGroup.value) IN IF ~collateralMarketValueGroup.ok THEN Fail ELSE
    Ok([ blockLength                |-> blockLength.value,
         collateralMarketValueGroup |-> collateralMarketValueGroup.value ], collateralMarketValueGroup.rest)

ZeroCollateralMarketValueGroups ==
    [ blockLength                |-> [i \in 1 .. 2 |-> 0],
      collateralMarketValueGroup |-> << >> ]

(* Collateral Market Value Groups at zero, then each field in turn at the values it is checked at *)
CheckedCollateralMarketValueGroups ==
    { ZeroCollateralMarketValueGroups }
        \cup { [ZeroCollateralMarketValueGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroCollateralMarketValueGroups EXCEPT !.collateralMarketValueGroup = one] : one \in SampleLists(OneCollateralMarketValueGroup) }

(***************************************************************************)
(* Collateral Market Value                                                 *)
(***************************************************************************)

CollateralMarketValue ==
    [ transactTime                : Sample(8),
      matchEventIndicator         : Sample(1),
      padding2                    : Sample(2),
      collateralMarketValueGroups : CollateralMarketValueGroups ]

EncodeCollateralMarketValue(message) ==
    message.transactTime
        \o message.matchEventIndicator
        \o message.padding2
        \o EncodeCollateralMarketValueGroups(message.collateralMarketValueGroups)

DecodeCollateralMarketValue(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET matchEventIndicator == ReadBytes(transactTime.rest, 1) IN IF ~matchEventIndicator.ok THEN Fail ELSE
    LET padding2 == ReadBytes(matchEventIndicator.rest, 2) IN IF ~padding2.ok THEN Fail ELSE
    LET collateralMarketValueGroups == DecodeCollateralMarketValueGroups(padding2.rest) IN IF ~collateralMarketValueGroups.ok THEN Fail ELSE
    Ok([ transactTime                |-> transactTime.value,
         matchEventIndicator         |-> matchEventIndicator.value,
         padding2                    |-> padding2.value,
         collateralMarketValueGroups |-> collateralMarketValueGroups.value ], collateralMarketValueGroups.rest)

ZeroCollateralMarketValue ==
    [ transactTime                |-> [i \in 1 .. 8 |-> 0],
      matchEventIndicator         |-> [i \in 1 .. 1 |-> 0],
      padding2                    |-> [i \in 1 .. 2 |-> 0],
      collateralMarketValueGroups |-> ZeroCollateralMarketValueGroups ]

(* Collateral Market Value at zero, then each field in turn at the values it is checked at *)
CheckedCollateralMarketValue ==
    { ZeroCollateralMarketValue }
        \cup { [ZeroCollateralMarketValue EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCollateralMarketValue EXCEPT !.matchEventIndicator = one] : one \in Sample(1) }
        \cup { [ZeroCollateralMarketValue EXCEPT !.padding2 = one] : one \in Sample(2) }
        \cup { [ZeroCollateralMarketValue EXCEPT !.collateralMarketValueGroups = one] : one \in CheckedCollateralMarketValueGroups }

(***************************************************************************)
(* Negotiate: 78 bytes                                                     *)
(***************************************************************************)

Negotiate ==
    [ hmacSignature    : Sample(32),
      accessKeyId      : Sample(20),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      session          : Sample(5),
      firm             : Sample(5) ]

EncodeNegotiate(message) ==
    message.hmacSignature
        \o message.accessKeyId
        \o message.uuid
        \o message.requestTimestamp
        \o message.session
        \o message.firm

DecodeNegotiate(bytes) ==
    LET hmacSignature == ReadBytes(bytes, 32) IN IF ~hmacSignature.ok THEN Fail ELSE
    LET accessKeyId == ReadBytes(hmacSignature.rest, 20) IN IF ~accessKeyId.ok THEN Fail ELSE
    LET uuid == ReadBytes(accessKeyId.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET session == ReadBytes(requestTimestamp.rest, 5) IN IF ~session.ok THEN Fail ELSE
    LET firm == ReadBytes(session.rest, 5) IN IF ~firm.ok THEN Fail ELSE
    Ok([ hmacSignature    |-> hmacSignature.value,
         accessKeyId      |-> accessKeyId.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         session          |-> session.value,
         firm             |-> firm.value ], firm.rest)

ZeroNegotiate ==
    [ hmacSignature    |-> [i \in 1 .. 32 |-> 0],
      accessKeyId      |-> [i \in 1 .. 20 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      session          |-> [i \in 1 .. 5 |-> 0],
      firm             |-> [i \in 1 .. 5 |-> 0] ]

(* Negotiate at zero, then each field in turn at the values it is checked at *)
CheckedNegotiate ==
    { ZeroNegotiate }
        \cup { [ZeroNegotiate EXCEPT !.hmacSignature = one] : one \in Sample(32) }
        \cup { [ZeroNegotiate EXCEPT !.accessKeyId = one] : one \in Sample(20) }
        \cup { [ZeroNegotiate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.session = one] : one \in Sample(5) }
        \cup { [ZeroNegotiate EXCEPT !.firm = one] : one \in Sample(5) }

(***************************************************************************)
(* Negotiation Reject: 70 bytes                                            *)
(***************************************************************************)

NegotiationReject ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(1),
      padding5         : Sample(5) ]

EncodeNegotiationReject(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.padding5

DecodeNegotiationReject(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 1) IN IF ~errorCodes.ok THEN Fail ELSE
    LET padding5 == ReadBytes(errorCodes.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         padding5         |-> padding5.value ], padding5.rest)

ZeroNegotiationReject ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 1 |-> 0],
      padding5         |-> [i \in 1 .. 5 |-> 0] ]

(* Negotiation Reject at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationReject ==
    { ZeroNegotiationReject }
        \cup { [ZeroNegotiationReject EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroNegotiationReject EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationReject EXCEPT !.errorCodes = one] : one \in Sample(1) }
        \cup { [ZeroNegotiationReject EXCEPT !.padding5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Negotiation Response: 22 bytes                                          *)
(***************************************************************************)

NegotiationResponse ==
    [ uuid                        : Sample(8),
      requestTimestamp            : Sample(8),
      secretKeySecureIdExpiration : Sample(2),
      padding4                    : Sample(4) ]

EncodeNegotiationResponse(message) ==
    message.uuid
        \o message.requestTimestamp
        \o message.secretKeySecureIdExpiration
        \o message.padding4

DecodeNegotiationResponse(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET secretKeySecureIdExpiration == ReadBytes(requestTimestamp.rest, 2) IN IF ~secretKeySecureIdExpiration.ok THEN Fail ELSE
    LET padding4 == ReadBytes(secretKeySecureIdExpiration.rest, 4) IN IF ~padding4.ok THEN Fail ELSE
    Ok([ uuid                        |-> uuid.value,
         requestTimestamp            |-> requestTimestamp.value,
         secretKeySecureIdExpiration |-> secretKeySecureIdExpiration.value,
         padding4                    |-> padding4.value ], padding4.rest)

ZeroNegotiationResponse ==
    [ uuid                        |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp            |-> [i \in 1 .. 8 |-> 0],
      secretKeySecureIdExpiration |-> [i \in 1 .. 2 |-> 0],
      padding4                    |-> [i \in 1 .. 4 |-> 0] ]

(* Negotiation Response at zero, then each field in turn at the values it is checked at *)
CheckedNegotiationResponse ==
    { ZeroNegotiationResponse }
        \cup { [ZeroNegotiationResponse EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiationResponse EXCEPT !.secretKeySecureIdExpiration = one] : one \in Sample(2) }
        \cup { [ZeroNegotiationResponse EXCEPT !.padding4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Terminate: 70 bytes                                                     *)
(***************************************************************************)

Terminate ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(1),
      padding5         : Sample(5) ]

EncodeTerminate(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.padding5

DecodeTerminate(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 1) IN IF ~errorCodes.ok THEN Fail ELSE
    LET padding5 == ReadBytes(errorCodes.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         padding5         |-> padding5.value ], padding5.rest)

ZeroTerminate ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 1 |-> 0],
      padding5         |-> [i \in 1 .. 5 |-> 0] ]

(* Terminate at zero, then each field in turn at the values it is checked at *)
CheckedTerminate ==
    { ZeroTerminate }
        \cup { [ZeroTerminate EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroTerminate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.errorCodes = one] : one \in Sample(1) }
        \cup { [ZeroTerminate EXCEPT !.padding5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Market Data Request Security Group: 6 bytes                             *)
(***************************************************************************)

MarketDataRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeMarketDataRequestSecurityGroup(message) ==
    message.securityGroup

DecodeMarketDataRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroMarketDataRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Market Data Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestSecurityGroup ==
    { ZeroMarketDataRequestSecurityGroup }
        \cup { [ZeroMarketDataRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Market Data Request Security Group, written one after another *)
RECURSIVE EncodeMarketDataRequestSecurityGroupList(_)
EncodeMarketDataRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDataRequestSecurityGroup(Head(messages)) \o EncodeMarketDataRequestSecurityGroupList(Tail(messages))

(* As many Market Data Request Security Group as the field that counts them says *)
RECURSIVE ReadMarketDataRequestSecurityGroupList(_, _)
ReadMarketDataRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDataRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDataRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Data Request Security Group of each kind, for the lists that carry them *)
OneMarketDataRequestSecurityGroup == { ZeroMarketDataRequestSecurityGroup }

(***************************************************************************)
(* Market Data Request Security Groups                                     *)
(***************************************************************************)

MarketDataRequestSecurityGroups ==
    [ blockLength                    : Sample(2),
      marketDataRequestSecurityGroup : SampleLists(OneMarketDataRequestSecurityGroup) ]

EncodeMarketDataRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.marketDataRequestSecurityGroup), 1)
        \o EncodeMarketDataRequestSecurityGroupList(message.marketDataRequestSecurityGroup)

DecodeMarketDataRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketDataRequestSecurityGroup == ReadMarketDataRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketDataRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                    |-> blockLength.value,
         marketDataRequestSecurityGroup |-> marketDataRequestSecurityGroup.value ], marketDataRequestSecurityGroup.rest)

ZeroMarketDataRequestSecurityGroups ==
    [ blockLength                    |-> [i \in 1 .. 2 |-> 0],
      marketDataRequestSecurityGroup |-> << >> ]

(* Market Data Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestSecurityGroups ==
    { ZeroMarketDataRequestSecurityGroups }
        \cup { [ZeroMarketDataRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataRequestSecurityGroups EXCEPT !.marketDataRequestSecurityGroup = one] : one \in SampleLists(OneMarketDataRequestSecurityGroup) }

(***************************************************************************)
(* Market Data Request Related Symbol Group: 4 bytes                       *)
(***************************************************************************)

MarketDataRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeMarketDataRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeMarketDataRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroMarketDataRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Market Data Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestRelatedSymbolGroup ==
    { ZeroMarketDataRequestRelatedSymbolGroup }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Market Data Request Related Symbol Group, written one after another *)
RECURSIVE EncodeMarketDataRequestRelatedSymbolGroupList(_)
EncodeMarketDataRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDataRequestRelatedSymbolGroup(Head(messages)) \o EncodeMarketDataRequestRelatedSymbolGroupList(Tail(messages))

(* As many Market Data Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadMarketDataRequestRelatedSymbolGroupList(_, _)
ReadMarketDataRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDataRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDataRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Data Request Related Symbol Group of each kind, for the lists that carry them *)
OneMarketDataRequestRelatedSymbolGroup == { ZeroMarketDataRequestRelatedSymbolGroup }

(***************************************************************************)
(* Market Data Request Related Symbol Groups                               *)
(***************************************************************************)

MarketDataRequestRelatedSymbolGroups ==
    [ blockLength                         : Sample(2),
      marketDataRequestRelatedSymbolGroup : SampleLists(OneMarketDataRequestRelatedSymbolGroup) ]

EncodeMarketDataRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.marketDataRequestRelatedSymbolGroup), 1)
        \o EncodeMarketDataRequestRelatedSymbolGroupList(message.marketDataRequestRelatedSymbolGroup)

DecodeMarketDataRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketDataRequestRelatedSymbolGroup == ReadMarketDataRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketDataRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         marketDataRequestRelatedSymbolGroup |-> marketDataRequestRelatedSymbolGroup.value ], marketDataRequestRelatedSymbolGroup.rest)

ZeroMarketDataRequestRelatedSymbolGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      marketDataRequestRelatedSymbolGroup |-> << >> ]

(* Market Data Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestRelatedSymbolGroups ==
    { ZeroMarketDataRequestRelatedSymbolGroups }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroups EXCEPT !.marketDataRequestRelatedSymbolGroup = one] : one \in SampleLists(OneMarketDataRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Market Data Request                                                     *)
(***************************************************************************)

MarketDataRequest ==
    [ mdReqId                              : Sample(4),
      subscriptionReqType                  : Sample(1),
      marketDataRequestSecurityGroups      : MarketDataRequestSecurityGroups,
      marketDataRequestRelatedSymbolGroups : MarketDataRequestRelatedSymbolGroups ]

EncodeMarketDataRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeMarketDataRequestSecurityGroups(message.marketDataRequestSecurityGroups)
        \o EncodeMarketDataRequestRelatedSymbolGroups(message.marketDataRequestRelatedSymbolGroups)

DecodeMarketDataRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET marketDataRequestSecurityGroups == DecodeMarketDataRequestSecurityGroups(subscriptionReqType.rest) IN IF ~marketDataRequestSecurityGroups.ok THEN Fail ELSE
    LET marketDataRequestRelatedSymbolGroups == DecodeMarketDataRequestRelatedSymbolGroups(marketDataRequestSecurityGroups.rest) IN IF ~marketDataRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                              |-> mdReqId.value,
         subscriptionReqType                  |-> subscriptionReqType.value,
         marketDataRequestSecurityGroups      |-> marketDataRequestSecurityGroups.value,
         marketDataRequestRelatedSymbolGroups |-> marketDataRequestRelatedSymbolGroups.value ], marketDataRequestRelatedSymbolGroups.rest)

ZeroMarketDataRequest ==
    [ mdReqId                              |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                  |-> [i \in 1 .. 1 |-> 0],
      marketDataRequestSecurityGroups      |-> ZeroMarketDataRequestSecurityGroups,
      marketDataRequestRelatedSymbolGroups |-> ZeroMarketDataRequestRelatedSymbolGroups ]

(* Market Data Request at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequest ==
    { ZeroMarketDataRequest }
        \cup { [ZeroMarketDataRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataRequest EXCEPT !.marketDataRequestSecurityGroups = one] : one \in CheckedMarketDataRequestSecurityGroups }
        \cup { [ZeroMarketDataRequest EXCEPT !.marketDataRequestRelatedSymbolGroups = one] : one \in CheckedMarketDataRequestRelatedSymbolGroups }

(***************************************************************************)
(* Request Ack Security Group: 6 bytes                                     *)
(***************************************************************************)

RequestAckSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeRequestAckSecurityGroup(message) ==
    message.securityGroup

DecodeRequestAckSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroRequestAckSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Request Ack Security Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckSecurityGroup ==
    { ZeroRequestAckSecurityGroup }
        \cup { [ZeroRequestAckSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Request Ack Security Group, written one after another *)
RECURSIVE EncodeRequestAckSecurityGroupList(_)
EncodeRequestAckSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestAckSecurityGroup(Head(messages)) \o EncodeRequestAckSecurityGroupList(Tail(messages))

(* As many Request Ack Security Group as the field that counts them says *)
RECURSIVE ReadRequestAckSecurityGroupList(_, _)
ReadRequestAckSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestAckSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestAckSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Request Ack Security Group of each kind, for the lists that carry them *)
OneRequestAckSecurityGroup == { ZeroRequestAckSecurityGroup }

(***************************************************************************)
(* Request Ack Security Groups                                             *)
(***************************************************************************)

RequestAckSecurityGroups ==
    [ blockLength             : Sample(2),
      requestAckSecurityGroup : SampleLists(OneRequestAckSecurityGroup) ]

EncodeRequestAckSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestAckSecurityGroup), 1)
        \o EncodeRequestAckSecurityGroupList(message.requestAckSecurityGroup)

DecodeRequestAckSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestAckSecurityGroup == ReadRequestAckSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestAckSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         requestAckSecurityGroup |-> requestAckSecurityGroup.value ], requestAckSecurityGroup.rest)

ZeroRequestAckSecurityGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      requestAckSecurityGroup |-> << >> ]

(* Request Ack Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckSecurityGroups ==
    { ZeroRequestAckSecurityGroups }
        \cup { [ZeroRequestAckSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestAckSecurityGroups EXCEPT !.requestAckSecurityGroup = one] : one \in SampleLists(OneRequestAckSecurityGroup) }

(***************************************************************************)
(* Request Ack Related Symbol Group: 4 bytes                               *)
(***************************************************************************)

RequestAckRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeRequestAckRelatedSymbolGroup(message) ==
    message.securityId

DecodeRequestAckRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroRequestAckRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Ack Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckRelatedSymbolGroup ==
    { ZeroRequestAckRelatedSymbolGroup }
        \cup { [ZeroRequestAckRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Request Ack Related Symbol Group, written one after another *)
RECURSIVE EncodeRequestAckRelatedSymbolGroupList(_)
EncodeRequestAckRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestAckRelatedSymbolGroup(Head(messages)) \o EncodeRequestAckRelatedSymbolGroupList(Tail(messages))

(* As many Request Ack Related Symbol Group as the field that counts them says *)
RECURSIVE ReadRequestAckRelatedSymbolGroupList(_, _)
ReadRequestAckRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestAckRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestAckRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Request Ack Related Symbol Group of each kind, for the lists that carry them *)
OneRequestAckRelatedSymbolGroup == { ZeroRequestAckRelatedSymbolGroup }

(***************************************************************************)
(* Request Ack Related Symbol Groups                                       *)
(***************************************************************************)

RequestAckRelatedSymbolGroups ==
    [ blockLength                  : Sample(2),
      requestAckRelatedSymbolGroup : SampleLists(OneRequestAckRelatedSymbolGroup) ]

EncodeRequestAckRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestAckRelatedSymbolGroup), 1)
        \o EncodeRequestAckRelatedSymbolGroupList(message.requestAckRelatedSymbolGroup)

DecodeRequestAckRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestAckRelatedSymbolGroup == ReadRequestAckRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestAckRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                  |-> blockLength.value,
         requestAckRelatedSymbolGroup |-> requestAckRelatedSymbolGroup.value ], requestAckRelatedSymbolGroup.rest)

ZeroRequestAckRelatedSymbolGroups ==
    [ blockLength                  |-> [i \in 1 .. 2 |-> 0],
      requestAckRelatedSymbolGroup |-> << >> ]

(* Request Ack Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestAckRelatedSymbolGroups ==
    { ZeroRequestAckRelatedSymbolGroups }
        \cup { [ZeroRequestAckRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestAckRelatedSymbolGroups EXCEPT !.requestAckRelatedSymbolGroup = one] : one \in SampleLists(OneRequestAckRelatedSymbolGroup) }

(***************************************************************************)
(* Request Ack                                                             *)
(***************************************************************************)

RequestAck ==
    [ mdReqId                       : Sample(4),
      subscriptionReqType           : Sample(1),
      mdReqIdStatus                 : Sample(1),
      requestAckSecurityGroups      : RequestAckSecurityGroups,
      requestAckRelatedSymbolGroups : RequestAckRelatedSymbolGroups ]

EncodeRequestAck(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o message.mdReqIdStatus
        \o EncodeRequestAckSecurityGroups(message.requestAckSecurityGroups)
        \o EncodeRequestAckRelatedSymbolGroups(message.requestAckRelatedSymbolGroups)

DecodeRequestAck(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET mdReqIdStatus == ReadBytes(subscriptionReqType.rest, 1) IN IF ~mdReqIdStatus.ok THEN Fail ELSE
    LET requestAckSecurityGroups == DecodeRequestAckSecurityGroups(mdReqIdStatus.rest) IN IF ~requestAckSecurityGroups.ok THEN Fail ELSE
    LET requestAckRelatedSymbolGroups == DecodeRequestAckRelatedSymbolGroups(requestAckSecurityGroups.rest) IN IF ~requestAckRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                       |-> mdReqId.value,
         subscriptionReqType           |-> subscriptionReqType.value,
         mdReqIdStatus                 |-> mdReqIdStatus.value,
         requestAckSecurityGroups      |-> requestAckSecurityGroups.value,
         requestAckRelatedSymbolGroups |-> requestAckRelatedSymbolGroups.value ], requestAckRelatedSymbolGroups.rest)

ZeroRequestAck ==
    [ mdReqId                       |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType           |-> [i \in 1 .. 1 |-> 0],
      mdReqIdStatus                 |-> [i \in 1 .. 1 |-> 0],
      requestAckSecurityGroups      |-> ZeroRequestAckSecurityGroups,
      requestAckRelatedSymbolGroups |-> ZeroRequestAckRelatedSymbolGroups ]

(* Request Ack at zero, then each field in turn at the values it is checked at *)
CheckedRequestAck ==
    { ZeroRequestAck }
        \cup { [ZeroRequestAck EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroRequestAck EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroRequestAck EXCEPT !.mdReqIdStatus = one] : one \in Sample(1) }
        \cup { [ZeroRequestAck EXCEPT !.requestAckSecurityGroups = one] : one \in CheckedRequestAckSecurityGroups }
        \cup { [ZeroRequestAck EXCEPT !.requestAckRelatedSymbolGroups = one] : one \in CheckedRequestAckRelatedSymbolGroups }

(***************************************************************************)
(* Request Reject: 105 bytes                                               *)
(***************************************************************************)

RequestReject ==
    [ mdReqIdOptional : Sample(4),
      mdReqRejReason  : Sample(1),
      text            : Sample(100) ]

EncodeRequestReject(message) ==
    message.mdReqIdOptional
        \o message.mdReqRejReason
        \o message.text

DecodeRequestReject(bytes) ==
    LET mdReqIdOptional == ReadBytes(bytes, 4) IN IF ~mdReqIdOptional.ok THEN Fail ELSE
    LET mdReqRejReason == ReadBytes(mdReqIdOptional.rest, 1) IN IF ~mdReqRejReason.ok THEN Fail ELSE
    LET text == ReadBytes(mdReqRejReason.rest, 100) IN IF ~text.ok THEN Fail ELSE
    Ok([ mdReqIdOptional |-> mdReqIdOptional.value,
         mdReqRejReason  |-> mdReqRejReason.value,
         text            |-> text.value ], text.rest)

ZeroRequestReject ==
    [ mdReqIdOptional |-> [i \in 1 .. 4 |-> 0],
      mdReqRejReason  |-> [i \in 1 .. 1 |-> 0],
      text            |-> [i \in 1 .. 100 |-> 0] ]

(* Request Reject at zero, then each field in turn at the values it is checked at *)
CheckedRequestReject ==
    { ZeroRequestReject }
        \cup { [ZeroRequestReject EXCEPT !.mdReqIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroRequestReject EXCEPT !.mdReqRejReason = one] : one \in Sample(1) }
        \cup { [ZeroRequestReject EXCEPT !.text = one] : one \in Sample(100) }

(***************************************************************************)
(* Security List Request Security Group: 6 bytes                           *)
(***************************************************************************)

SecurityListRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeSecurityListRequestSecurityGroup(message) ==
    message.securityGroup

DecodeSecurityListRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroSecurityListRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Security List Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestSecurityGroup ==
    { ZeroSecurityListRequestSecurityGroup }
        \cup { [ZeroSecurityListRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Security List Request Security Group, written one after another *)
RECURSIVE EncodeSecurityListRequestSecurityGroupList(_)
EncodeSecurityListRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityListRequestSecurityGroup(Head(messages)) \o EncodeSecurityListRequestSecurityGroupList(Tail(messages))

(* As many Security List Request Security Group as the field that counts them says *)
RECURSIVE ReadSecurityListRequestSecurityGroupList(_, _)
ReadSecurityListRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityListRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityListRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security List Request Security Group of each kind, for the lists that carry them *)
OneSecurityListRequestSecurityGroup == { ZeroSecurityListRequestSecurityGroup }

(***************************************************************************)
(* Security List Request Security Groups                                   *)
(***************************************************************************)

SecurityListRequestSecurityGroups ==
    [ blockLength                      : Sample(2),
      securityListRequestSecurityGroup : SampleLists(OneSecurityListRequestSecurityGroup) ]

EncodeSecurityListRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityListRequestSecurityGroup), 1)
        \o EncodeSecurityListRequestSecurityGroupList(message.securityListRequestSecurityGroup)

DecodeSecurityListRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityListRequestSecurityGroup == ReadSecurityListRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityListRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                      |-> blockLength.value,
         securityListRequestSecurityGroup |-> securityListRequestSecurityGroup.value ], securityListRequestSecurityGroup.rest)

ZeroSecurityListRequestSecurityGroups ==
    [ blockLength                      |-> [i \in 1 .. 2 |-> 0],
      securityListRequestSecurityGroup |-> << >> ]

(* Security List Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestSecurityGroups ==
    { ZeroSecurityListRequestSecurityGroups }
        \cup { [ZeroSecurityListRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListRequestSecurityGroups EXCEPT !.securityListRequestSecurityGroup = one] : one \in SampleLists(OneSecurityListRequestSecurityGroup) }

(***************************************************************************)
(* Security List Request Related Symbol Group: 4 bytes                     *)
(***************************************************************************)

SecurityListRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeSecurityListRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeSecurityListRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroSecurityListRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Security List Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestRelatedSymbolGroup ==
    { ZeroSecurityListRequestRelatedSymbolGroup }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Security List Request Related Symbol Group, written one after another *)
RECURSIVE EncodeSecurityListRequestRelatedSymbolGroupList(_)
EncodeSecurityListRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityListRequestRelatedSymbolGroup(Head(messages)) \o EncodeSecurityListRequestRelatedSymbolGroupList(Tail(messages))

(* As many Security List Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadSecurityListRequestRelatedSymbolGroupList(_, _)
ReadSecurityListRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityListRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityListRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security List Request Related Symbol Group of each kind, for the lists that carry them *)
OneSecurityListRequestRelatedSymbolGroup == { ZeroSecurityListRequestRelatedSymbolGroup }

(***************************************************************************)
(* Security List Request Related Symbol Groups                             *)
(***************************************************************************)

SecurityListRequestRelatedSymbolGroups ==
    [ blockLength                           : Sample(2),
      securityListRequestRelatedSymbolGroup : SampleLists(OneSecurityListRequestRelatedSymbolGroup) ]

EncodeSecurityListRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityListRequestRelatedSymbolGroup), 1)
        \o EncodeSecurityListRequestRelatedSymbolGroupList(message.securityListRequestRelatedSymbolGroup)

DecodeSecurityListRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityListRequestRelatedSymbolGroup == ReadSecurityListRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityListRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                           |-> blockLength.value,
         securityListRequestRelatedSymbolGroup |-> securityListRequestRelatedSymbolGroup.value ], securityListRequestRelatedSymbolGroup.rest)

ZeroSecurityListRequestRelatedSymbolGroups ==
    [ blockLength                           |-> [i \in 1 .. 2 |-> 0],
      securityListRequestRelatedSymbolGroup |-> << >> ]

(* Security List Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestRelatedSymbolGroups ==
    { ZeroSecurityListRequestRelatedSymbolGroups }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroups EXCEPT !.securityListRequestRelatedSymbolGroup = one] : one \in SampleLists(OneSecurityListRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Security List Request                                                   *)
(***************************************************************************)

SecurityListRequest ==
    [ mdReqId                                : Sample(4),
      subscriptionReqType                    : Sample(1),
      securityListRequestSecurityGroups      : SecurityListRequestSecurityGroups,
      securityListRequestRelatedSymbolGroups : SecurityListRequestRelatedSymbolGroups ]

EncodeSecurityListRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeSecurityListRequestSecurityGroups(message.securityListRequestSecurityGroups)
        \o EncodeSecurityListRequestRelatedSymbolGroups(message.securityListRequestRelatedSymbolGroups)

DecodeSecurityListRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET securityListRequestSecurityGroups == DecodeSecurityListRequestSecurityGroups(subscriptionReqType.rest) IN IF ~securityListRequestSecurityGroups.ok THEN Fail ELSE
    LET securityListRequestRelatedSymbolGroups == DecodeSecurityListRequestRelatedSymbolGroups(securityListRequestSecurityGroups.rest) IN IF ~securityListRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                                |-> mdReqId.value,
         subscriptionReqType                    |-> subscriptionReqType.value,
         securityListRequestSecurityGroups      |-> securityListRequestSecurityGroups.value,
         securityListRequestRelatedSymbolGroups |-> securityListRequestRelatedSymbolGroups.value ], securityListRequestRelatedSymbolGroups.rest)

ZeroSecurityListRequest ==
    [ mdReqId                                |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                    |-> [i \in 1 .. 1 |-> 0],
      securityListRequestSecurityGroups      |-> ZeroSecurityListRequestSecurityGroups,
      securityListRequestRelatedSymbolGroups |-> ZeroSecurityListRequestRelatedSymbolGroups ]

(* Security List Request at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequest ==
    { ZeroSecurityListRequest }
        \cup { [ZeroSecurityListRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListRequest EXCEPT !.securityListRequestSecurityGroups = one] : one \in CheckedSecurityListRequestSecurityGroups }
        \cup { [ZeroSecurityListRequest EXCEPT !.securityListRequestRelatedSymbolGroups = one] : one \in CheckedSecurityListRequestRelatedSymbolGroups }

(***************************************************************************)
(* Security Status Request Security Group: 6 bytes                         *)
(***************************************************************************)

SecurityStatusRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeSecurityStatusRequestSecurityGroup(message) ==
    message.securityGroup

DecodeSecurityStatusRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroSecurityStatusRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Security Status Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestSecurityGroup ==
    { ZeroSecurityStatusRequestSecurityGroup }
        \cup { [ZeroSecurityStatusRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Security Status Request Security Group, written one after another *)
RECURSIVE EncodeSecurityStatusRequestSecurityGroupList(_)
EncodeSecurityStatusRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusRequestSecurityGroup(Head(messages)) \o EncodeSecurityStatusRequestSecurityGroupList(Tail(messages))

(* As many Security Status Request Security Group as the field that counts them says *)
RECURSIVE ReadSecurityStatusRequestSecurityGroupList(_, _)
ReadSecurityStatusRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Request Security Group of each kind, for the lists that carry them *)
OneSecurityStatusRequestSecurityGroup == { ZeroSecurityStatusRequestSecurityGroup }

(***************************************************************************)
(* Security Status Request Security Groups                                 *)
(***************************************************************************)

SecurityStatusRequestSecurityGroups ==
    [ blockLength                        : Sample(2),
      securityStatusRequestSecurityGroup : SampleLists(OneSecurityStatusRequestSecurityGroup) ]

EncodeSecurityStatusRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityStatusRequestSecurityGroup), 1)
        \o EncodeSecurityStatusRequestSecurityGroupList(message.securityStatusRequestSecurityGroup)

DecodeSecurityStatusRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityStatusRequestSecurityGroup == ReadSecurityStatusRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityStatusRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                        |-> blockLength.value,
         securityStatusRequestSecurityGroup |-> securityStatusRequestSecurityGroup.value ], securityStatusRequestSecurityGroup.rest)

ZeroSecurityStatusRequestSecurityGroups ==
    [ blockLength                        |-> [i \in 1 .. 2 |-> 0],
      securityStatusRequestSecurityGroup |-> << >> ]

(* Security Status Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestSecurityGroups ==
    { ZeroSecurityStatusRequestSecurityGroups }
        \cup { [ZeroSecurityStatusRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusRequestSecurityGroups EXCEPT !.securityStatusRequestSecurityGroup = one] : one \in SampleLists(OneSecurityStatusRequestSecurityGroup) }

(***************************************************************************)
(* Security Status Request Related Symbol Group: 4 bytes                   *)
(***************************************************************************)

SecurityStatusRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeSecurityStatusRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeSecurityStatusRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroSecurityStatusRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Security Status Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestRelatedSymbolGroup ==
    { ZeroSecurityStatusRequestRelatedSymbolGroup }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Security Status Request Related Symbol Group, written one after another *)
RECURSIVE EncodeSecurityStatusRequestRelatedSymbolGroupList(_)
EncodeSecurityStatusRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusRequestRelatedSymbolGroup(Head(messages)) \o EncodeSecurityStatusRequestRelatedSymbolGroupList(Tail(messages))

(* As many Security Status Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadSecurityStatusRequestRelatedSymbolGroupList(_, _)
ReadSecurityStatusRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Request Related Symbol Group of each kind, for the lists that carry them *)
OneSecurityStatusRequestRelatedSymbolGroup == { ZeroSecurityStatusRequestRelatedSymbolGroup }

(***************************************************************************)
(* Security Status Request Related Symbol Groups                           *)
(***************************************************************************)

SecurityStatusRequestRelatedSymbolGroups ==
    [ blockLength                             : Sample(2),
      securityStatusRequestRelatedSymbolGroup : SampleLists(OneSecurityStatusRequestRelatedSymbolGroup) ]

EncodeSecurityStatusRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityStatusRequestRelatedSymbolGroup), 1)
        \o EncodeSecurityStatusRequestRelatedSymbolGroupList(message.securityStatusRequestRelatedSymbolGroup)

DecodeSecurityStatusRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityStatusRequestRelatedSymbolGroup == ReadSecurityStatusRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityStatusRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                             |-> blockLength.value,
         securityStatusRequestRelatedSymbolGroup |-> securityStatusRequestRelatedSymbolGroup.value ], securityStatusRequestRelatedSymbolGroup.rest)

ZeroSecurityStatusRequestRelatedSymbolGroups ==
    [ blockLength                             |-> [i \in 1 .. 2 |-> 0],
      securityStatusRequestRelatedSymbolGroup |-> << >> ]

(* Security Status Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestRelatedSymbolGroups ==
    { ZeroSecurityStatusRequestRelatedSymbolGroups }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroups EXCEPT !.securityStatusRequestRelatedSymbolGroup = one] : one \in SampleLists(OneSecurityStatusRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Security Status Request                                                 *)
(***************************************************************************)

SecurityStatusRequest ==
    [ mdReqId                                  : Sample(4),
      subscriptionReqType                      : Sample(1),
      securityStatusRequestSecurityGroups      : SecurityStatusRequestSecurityGroups,
      securityStatusRequestRelatedSymbolGroups : SecurityStatusRequestRelatedSymbolGroups ]

EncodeSecurityStatusRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeSecurityStatusRequestSecurityGroups(message.securityStatusRequestSecurityGroups)
        \o EncodeSecurityStatusRequestRelatedSymbolGroups(message.securityStatusRequestRelatedSymbolGroups)

DecodeSecurityStatusRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET securityStatusRequestSecurityGroups == DecodeSecurityStatusRequestSecurityGroups(subscriptionReqType.rest) IN IF ~securityStatusRequestSecurityGroups.ok THEN Fail ELSE
    LET securityStatusRequestRelatedSymbolGroups == DecodeSecurityStatusRequestRelatedSymbolGroups(securityStatusRequestSecurityGroups.rest) IN IF ~securityStatusRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                                  |-> mdReqId.value,
         subscriptionReqType                      |-> subscriptionReqType.value,
         securityStatusRequestSecurityGroups      |-> securityStatusRequestSecurityGroups.value,
         securityStatusRequestRelatedSymbolGroups |-> securityStatusRequestRelatedSymbolGroups.value ], securityStatusRequestRelatedSymbolGroups.rest)

ZeroSecurityStatusRequest ==
    [ mdReqId                                  |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                      |-> [i \in 1 .. 1 |-> 0],
      securityStatusRequestSecurityGroups      |-> ZeroSecurityStatusRequestSecurityGroups,
      securityStatusRequestRelatedSymbolGroups |-> ZeroSecurityStatusRequestRelatedSymbolGroups ]

(* Security Status Request at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequest ==
    { ZeroSecurityStatusRequest }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.securityStatusRequestSecurityGroups = one] : one \in CheckedSecurityStatusRequestSecurityGroups }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.securityStatusRequestRelatedSymbolGroups = one] : one \in CheckedSecurityStatusRequestRelatedSymbolGroups }

(***************************************************************************)
(* Payload, selected by Schema Id and Template Id                          *)
(***************************************************************************)

ChannelResetCode == <<1, 4>>  \* 0x01, 0x04
AdminHeartbeatCode == <<1, 12>>  \* 0x01, 0x0c
AdminLoginCode == <<1, 15>>  \* 0x01, 0x0f
AdminLogoutCode == <<1, 16>>  \* 0x01, 0x10
SecurityStatusCode == <<1, 30>>  \* 0x01, 0x1e
MdIncrementalRefreshVolumeCode == <<1, 37>>  \* 0x01, 0x25
QuoteRequestCode == <<1, 39>>  \* 0x01, 0x27
MdIncrementalRefreshBookCode == <<1, 46>>  \* 0x01, 0x2e
MdIncrementalRefreshOrderBookCode == <<1, 47>>  \* 0x01, 0x2f
MdIncrementalRefreshTradeSummaryCode == <<1, 48>>  \* 0x01, 0x30
MdIncrementalRefreshDailyStatisticsCode == <<1, 49>>  \* 0x01, 0x31
MdIncrementalRefreshLimitsBandingCode == <<1, 50>>  \* 0x01, 0x32
MdIncrementalRefreshSessionStatisticsCode == <<1, 51>>  \* 0x01, 0x33
SnapshotFullRefreshCode == <<1, 52>>  \* 0x01, 0x34
SnapshotFullRefreshOrderBookCode == <<1, 53>>  \* 0x01, 0x35
MdInstrumentDefinitionFutureCode == <<1, 54>>  \* 0x01, 0x36
MdInstrumentDefinitionOptionCode == <<1, 55>>  \* 0x01, 0x37
MdInstrumentDefinitionSpreadCode == <<1, 56>>  \* 0x01, 0x38
MdInstrumentDefinitionFixedIncomeCode == <<1, 57>>  \* 0x01, 0x39
MdInstrumentDefinitionRepoCode == <<1, 58>>  \* 0x01, 0x3a
SnapshotRefreshTopOrdersCode == <<1, 59>>  \* 0x01, 0x3b
SecurityStatusWorkupCode == <<1, 60>>  \* 0x01, 0x3c
SnapshotFullRefreshTcpCode == <<1, 61>>  \* 0x01, 0x3d
CollateralMarketValueCode == <<1, 62>>  \* 0x01, 0x3e
NegotiateCode == <<2, 200>>  \* 0x02, 0xc8
NegotiationRejectCode == <<2, 201>>  \* 0x02, 0xc9
NegotiationResponseCode == <<2, 202>>  \* 0x02, 0xca
TerminateCode == <<2, 203>>  \* 0x02, 0xcb
MarketDataRequestCode == <<2, 205>>  \* 0x02, 0xcd
RequestAckCode == <<2, 206>>  \* 0x02, 0xce
RequestRejectCode == <<2, 207>>  \* 0x02, 0xcf
SecurityListRequestCode == <<2, 208>>  \* 0x02, 0xd0
SecurityStatusRequestCode == <<2, 209>>  \* 0x02, 0xd1
SubscriberHeartbeatCode == <<2, 210>>  \* 0x02, 0xd2

Payload ==
    [ tag : {ChannelResetCode}, body : ChannelReset ]
        \cup [ tag : {AdminHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {AdminLoginCode}, body : AdminLogin ]
        \cup [ tag : {AdminLogoutCode}, body : AdminLogout ]
        \cup [ tag : {SecurityStatusCode}, body : SecurityStatus ]
        \cup [ tag : {MdIncrementalRefreshVolumeCode}, body : MdIncrementalRefreshVolume ]
        \cup [ tag : {QuoteRequestCode}, body : QuoteRequest ]
        \cup [ tag : {MdIncrementalRefreshBookCode}, body : MdIncrementalRefreshBook ]
        \cup [ tag : {MdIncrementalRefreshOrderBookCode}, body : MdIncrementalRefreshOrderBook ]
        \cup [ tag : {MdIncrementalRefreshTradeSummaryCode}, body : MdIncrementalRefreshTradeSummary ]
        \cup [ tag : {MdIncrementalRefreshDailyStatisticsCode}, body : MdIncrementalRefreshDailyStatistics ]
        \cup [ tag : {MdIncrementalRefreshLimitsBandingCode}, body : MdIncrementalRefreshLimitsBanding ]
        \cup [ tag : {MdIncrementalRefreshSessionStatisticsCode}, body : MdIncrementalRefreshSessionStatistics ]
        \cup [ tag : {SnapshotFullRefreshCode}, body : SnapshotFullRefresh ]
        \cup [ tag : {SnapshotFullRefreshOrderBookCode}, body : SnapshotFullRefreshOrderBook ]
        \cup [ tag : {MdInstrumentDefinitionFutureCode}, body : MdInstrumentDefinitionFuture ]
        \cup [ tag : {MdInstrumentDefinitionOptionCode}, body : MdInstrumentDefinitionOption ]
        \cup [ tag : {MdInstrumentDefinitionSpreadCode}, body : MdInstrumentDefinitionSpread ]
        \cup [ tag : {MdInstrumentDefinitionFixedIncomeCode}, body : MdInstrumentDefinitionFixedIncome ]
        \cup [ tag : {MdInstrumentDefinitionRepoCode}, body : MdInstrumentDefinitionRepo ]
        \cup [ tag : {SnapshotRefreshTopOrdersCode}, body : SnapshotRefreshTopOrders ]
        \cup [ tag : {SecurityStatusWorkupCode}, body : SecurityStatusWorkup ]
        \cup [ tag : {SnapshotFullRefreshTcpCode}, body : SnapshotFullRefreshTcp ]
        \cup [ tag : {CollateralMarketValueCode}, body : CollateralMarketValue ]
        \cup [ tag : {NegotiateCode}, body : Negotiate ]
        \cup [ tag : {NegotiationRejectCode}, body : NegotiationReject ]
        \cup [ tag : {NegotiationResponseCode}, body : NegotiationResponse ]
        \cup [ tag : {TerminateCode}, body : Terminate ]
        \cup [ tag : {MarketDataRequestCode}, body : MarketDataRequest ]
        \cup [ tag : {RequestAckCode}, body : RequestAck ]
        \cup [ tag : {RequestRejectCode}, body : RequestReject ]
        \cup [ tag : {SecurityListRequestCode}, body : SecurityListRequest ]
        \cup [ tag : {SecurityStatusRequestCode}, body : SecurityStatusRequest ]
        \cup [ tag : {SubscriberHeartbeatCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = ChannelResetCode -> EncodeChannelReset(message.body)
      [] message.tag = AdminHeartbeatCode -> << >>
      [] message.tag = AdminLoginCode -> EncodeAdminLogin(message.body)
      [] message.tag = AdminLogoutCode -> EncodeAdminLogout(message.body)
      [] message.tag = SecurityStatusCode -> EncodeSecurityStatus(message.body)
      [] message.tag = MdIncrementalRefreshVolumeCode -> EncodeMdIncrementalRefreshVolume(message.body)
      [] message.tag = QuoteRequestCode -> EncodeQuoteRequest(message.body)
      [] message.tag = MdIncrementalRefreshBookCode -> EncodeMdIncrementalRefreshBook(message.body)
      [] message.tag = MdIncrementalRefreshOrderBookCode -> EncodeMdIncrementalRefreshOrderBook(message.body)
      [] message.tag = MdIncrementalRefreshTradeSummaryCode -> EncodeMdIncrementalRefreshTradeSummary(message.body)
      [] message.tag = MdIncrementalRefreshDailyStatisticsCode -> EncodeMdIncrementalRefreshDailyStatistics(message.body)
      [] message.tag = MdIncrementalRefreshLimitsBandingCode -> EncodeMdIncrementalRefreshLimitsBanding(message.body)
      [] message.tag = MdIncrementalRefreshSessionStatisticsCode -> EncodeMdIncrementalRefreshSessionStatistics(message.body)
      [] message.tag = SnapshotFullRefreshCode -> EncodeSnapshotFullRefresh(message.body)
      [] message.tag = SnapshotFullRefreshOrderBookCode -> EncodeSnapshotFullRefreshOrderBook(message.body)
      [] message.tag = MdInstrumentDefinitionFutureCode -> EncodeMdInstrumentDefinitionFuture(message.body)
      [] message.tag = MdInstrumentDefinitionOptionCode -> EncodeMdInstrumentDefinitionOption(message.body)
      [] message.tag = MdInstrumentDefinitionSpreadCode -> EncodeMdInstrumentDefinitionSpread(message.body)
      [] message.tag = MdInstrumentDefinitionFixedIncomeCode -> EncodeMdInstrumentDefinitionFixedIncome(message.body)
      [] message.tag = MdInstrumentDefinitionRepoCode -> EncodeMdInstrumentDefinitionRepo(message.body)
      [] message.tag = SnapshotRefreshTopOrdersCode -> EncodeSnapshotRefreshTopOrders(message.body)
      [] message.tag = SecurityStatusWorkupCode -> EncodeSecurityStatusWorkup(message.body)
      [] message.tag = SnapshotFullRefreshTcpCode -> EncodeSnapshotFullRefreshTcp(message.body)
      [] message.tag = CollateralMarketValueCode -> EncodeCollateralMarketValue(message.body)
      [] message.tag = NegotiateCode -> EncodeNegotiate(message.body)
      [] message.tag = NegotiationRejectCode -> EncodeNegotiationReject(message.body)
      [] message.tag = NegotiationResponseCode -> EncodeNegotiationResponse(message.body)
      [] message.tag = TerminateCode -> EncodeTerminate(message.body)
      [] message.tag = MarketDataRequestCode -> EncodeMarketDataRequest(message.body)
      [] message.tag = RequestAckCode -> EncodeRequestAck(message.body)
      [] message.tag = RequestRejectCode -> EncodeRequestReject(message.body)
      [] message.tag = SecurityListRequestCode -> EncodeSecurityListRequest(message.body)
      [] message.tag = SecurityStatusRequestCode -> EncodeSecurityStatusRequest(message.body)
      [] message.tag = SubscriberHeartbeatCode -> << >>

DecodePayload(schemaId, templateId, bytes) ==
    LET read ==
            CASE <<schemaId, templateId>> = ChannelResetCode -> DecodeChannelReset(bytes)
              [] <<schemaId, templateId>> = AdminHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] <<schemaId, templateId>> = AdminLoginCode -> DecodeAdminLogin(bytes)
              [] <<schemaId, templateId>> = AdminLogoutCode -> DecodeAdminLogout(bytes)
              [] <<schemaId, templateId>> = SecurityStatusCode -> DecodeSecurityStatus(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshVolumeCode -> DecodeMdIncrementalRefreshVolume(bytes)
              [] <<schemaId, templateId>> = QuoteRequestCode -> DecodeQuoteRequest(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshBookCode -> DecodeMdIncrementalRefreshBook(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshOrderBookCode -> DecodeMdIncrementalRefreshOrderBook(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshTradeSummaryCode -> DecodeMdIncrementalRefreshTradeSummary(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshDailyStatisticsCode -> DecodeMdIncrementalRefreshDailyStatistics(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshLimitsBandingCode -> DecodeMdIncrementalRefreshLimitsBanding(bytes)
              [] <<schemaId, templateId>> = MdIncrementalRefreshSessionStatisticsCode -> DecodeMdIncrementalRefreshSessionStatistics(bytes)
              [] <<schemaId, templateId>> = SnapshotFullRefreshCode -> DecodeSnapshotFullRefresh(bytes)
              [] <<schemaId, templateId>> = SnapshotFullRefreshOrderBookCode -> DecodeSnapshotFullRefreshOrderBook(bytes)
              [] <<schemaId, templateId>> = MdInstrumentDefinitionFutureCode -> DecodeMdInstrumentDefinitionFuture(bytes)
              [] <<schemaId, templateId>> = MdInstrumentDefinitionOptionCode -> DecodeMdInstrumentDefinitionOption(bytes)
              [] <<schemaId, templateId>> = MdInstrumentDefinitionSpreadCode -> DecodeMdInstrumentDefinitionSpread(bytes)
              [] <<schemaId, templateId>> = MdInstrumentDefinitionFixedIncomeCode -> DecodeMdInstrumentDefinitionFixedIncome(bytes)
              [] <<schemaId, templateId>> = MdInstrumentDefinitionRepoCode -> DecodeMdInstrumentDefinitionRepo(bytes)
              [] <<schemaId, templateId>> = SnapshotRefreshTopOrdersCode -> DecodeSnapshotRefreshTopOrders(bytes)
              [] <<schemaId, templateId>> = SecurityStatusWorkupCode -> DecodeSecurityStatusWorkup(bytes)
              [] <<schemaId, templateId>> = SnapshotFullRefreshTcpCode -> DecodeSnapshotFullRefreshTcp(bytes)
              [] <<schemaId, templateId>> = CollateralMarketValueCode -> DecodeCollateralMarketValue(bytes)
              [] <<schemaId, templateId>> = NegotiateCode -> DecodeNegotiate(bytes)
              [] <<schemaId, templateId>> = NegotiationRejectCode -> DecodeNegotiationReject(bytes)
              [] <<schemaId, templateId>> = NegotiationResponseCode -> DecodeNegotiationResponse(bytes)
              [] <<schemaId, templateId>> = TerminateCode -> DecodeTerminate(bytes)
              [] <<schemaId, templateId>> = MarketDataRequestCode -> DecodeMarketDataRequest(bytes)
              [] <<schemaId, templateId>> = RequestAckCode -> DecodeRequestAck(bytes)
              [] <<schemaId, templateId>> = RequestRejectCode -> DecodeRequestReject(bytes)
              [] <<schemaId, templateId>> = SecurityListRequestCode -> DecodeSecurityListRequest(bytes)
              [] <<schemaId, templateId>> = SecurityStatusRequestCode -> DecodeSecurityStatusRequest(bytes)
              [] <<schemaId, templateId>> = SubscriberHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> <<schemaId, templateId>>, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ChannelResetCode, body |-> ZeroChannelReset]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ChannelResetCode, body |-> one] : one \in CheckedChannelReset }
        \cup { [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> AdminLoginCode, body |-> one] : one \in CheckedAdminLogin }
        \cup { [tag |-> AdminLogoutCode, body |-> one] : one \in CheckedAdminLogout }
        \cup { [tag |-> SecurityStatusCode, body |-> one] : one \in CheckedSecurityStatus }
        \cup { [tag |-> MdIncrementalRefreshVolumeCode, body |-> one] : one \in CheckedMdIncrementalRefreshVolume }
        \cup { [tag |-> QuoteRequestCode, body |-> one] : one \in CheckedQuoteRequest }
        \cup { [tag |-> MdIncrementalRefreshBookCode, body |-> one] : one \in CheckedMdIncrementalRefreshBook }
        \cup { [tag |-> MdIncrementalRefreshOrderBookCode, body |-> one] : one \in CheckedMdIncrementalRefreshOrderBook }
        \cup { [tag |-> MdIncrementalRefreshTradeSummaryCode, body |-> one] : one \in CheckedMdIncrementalRefreshTradeSummary }
        \cup { [tag |-> MdIncrementalRefreshDailyStatisticsCode, body |-> one] : one \in CheckedMdIncrementalRefreshDailyStatistics }
        \cup { [tag |-> MdIncrementalRefreshLimitsBandingCode, body |-> one] : one \in CheckedMdIncrementalRefreshLimitsBanding }
        \cup { [tag |-> MdIncrementalRefreshSessionStatisticsCode, body |-> one] : one \in CheckedMdIncrementalRefreshSessionStatistics }
        \cup { [tag |-> SnapshotFullRefreshCode, body |-> one] : one \in CheckedSnapshotFullRefresh }
        \cup { [tag |-> SnapshotFullRefreshOrderBookCode, body |-> one] : one \in CheckedSnapshotFullRefreshOrderBook }
        \cup { [tag |-> MdInstrumentDefinitionFutureCode, body |-> one] : one \in CheckedMdInstrumentDefinitionFuture }
        \cup { [tag |-> MdInstrumentDefinitionOptionCode, body |-> one] : one \in CheckedMdInstrumentDefinitionOption }
        \cup { [tag |-> MdInstrumentDefinitionSpreadCode, body |-> one] : one \in CheckedMdInstrumentDefinitionSpread }
        \cup { [tag |-> MdInstrumentDefinitionFixedIncomeCode, body |-> one] : one \in CheckedMdInstrumentDefinitionFixedIncome }
        \cup { [tag |-> MdInstrumentDefinitionRepoCode, body |-> one] : one \in CheckedMdInstrumentDefinitionRepo }
        \cup { [tag |-> SnapshotRefreshTopOrdersCode, body |-> one] : one \in CheckedSnapshotRefreshTopOrders }
        \cup { [tag |-> SecurityStatusWorkupCode, body |-> one] : one \in CheckedSecurityStatusWorkup }
        \cup { [tag |-> SnapshotFullRefreshTcpCode, body |-> one] : one \in CheckedSnapshotFullRefreshTcp }
        \cup { [tag |-> CollateralMarketValueCode, body |-> one] : one \in CheckedCollateralMarketValue }
        \cup { [tag |-> NegotiateCode, body |-> one] : one \in CheckedNegotiate }
        \cup { [tag |-> NegotiationRejectCode, body |-> one] : one \in CheckedNegotiationReject }
        \cup { [tag |-> NegotiationResponseCode, body |-> one] : one \in CheckedNegotiationResponse }
        \cup { [tag |-> TerminateCode, body |-> one] : one \in CheckedTerminate }
        \cup { [tag |-> MarketDataRequestCode, body |-> one] : one \in CheckedMarketDataRequest }
        \cup { [tag |-> RequestAckCode, body |-> one] : one \in CheckedRequestAck }
        \cup { [tag |-> RequestRejectCode, body |-> one] : one \in CheckedRequestReject }
        \cup { [tag |-> SecurityListRequestCode, body |-> one] : one \in CheckedSecurityListRequest }
        \cup { [tag |-> SecurityStatusRequestCode, body |-> one] : one \in CheckedSecurityStatusRequest }
        \cup { [tag |-> SubscriberHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag[2], 2)
        \o EncodeUIntLE(message.payload.tag[1], 2)
        \o message.version
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadUIntLE(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(schemaId.value, templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

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
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> ChannelResetCode, body |-> ZeroChannelReset]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdminHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdminLoginCode, body |-> ZeroAdminLogin]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdminLogoutCode, body |-> ZeroAdminLogout]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusCode, body |-> ZeroSecurityStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshVolumeCode, body |-> ZeroMdIncrementalRefreshVolume]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestCode, body |-> ZeroQuoteRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshBookCode, body |-> ZeroMdIncrementalRefreshBook]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshOrderBookCode, body |-> ZeroMdIncrementalRefreshOrderBook]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshTradeSummaryCode, body |-> ZeroMdIncrementalRefreshTradeSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshDailyStatisticsCode, body |-> ZeroMdIncrementalRefreshDailyStatistics]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshLimitsBandingCode, body |-> ZeroMdIncrementalRefreshLimitsBanding]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdIncrementalRefreshSessionStatisticsCode, body |-> ZeroMdIncrementalRefreshSessionStatistics]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotFullRefreshCode, body |-> ZeroSnapshotFullRefresh]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotFullRefreshOrderBookCode, body |-> ZeroSnapshotFullRefreshOrderBook]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionFutureCode, body |-> ZeroMdInstrumentDefinitionFuture]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionOptionCode, body |-> ZeroMdInstrumentDefinitionOption]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionSpreadCode, body |-> ZeroMdInstrumentDefinitionSpread]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionFixedIncomeCode, body |-> ZeroMdInstrumentDefinitionFixedIncome]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MdInstrumentDefinitionRepoCode, body |-> ZeroMdInstrumentDefinitionRepo]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotRefreshTopOrdersCode, body |-> ZeroSnapshotRefreshTopOrders]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusWorkupCode, body |-> ZeroSecurityStatusWorkup]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SnapshotFullRefreshTcpCode, body |-> ZeroSnapshotFullRefreshTcp]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollateralMarketValueCode, body |-> ZeroCollateralMarketValue]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NegotiateCode, body |-> ZeroNegotiate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NegotiationRejectCode, body |-> ZeroNegotiationReject]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NegotiationResponseCode, body |-> ZeroNegotiationResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TerminateCode, body |-> ZeroTerminate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDataRequestCode, body |-> ZeroMarketDataRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestAckCode, body |-> ZeroRequestAck]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestRejectCode, body |-> ZeroRequestReject]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListRequestCode, body |-> ZeroSecurityListRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusRequestCode, body |-> ZeroSecurityStatusRequest]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SubscriberHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ binaryPacketHeader : BinaryPacketHeader,
      message            : SampleLists(OneMessage) ]

EncodeUdpPacket(message) ==
    EncodeBinaryPacketHeader(message.binaryPacketHeader)
        \o EncodeMessageList(message.message)

DecodeUdpPacket(bytes) ==
    LET binaryPacketHeader == DecodeBinaryPacketHeader(bytes) IN IF ~binaryPacketHeader.ok THEN Fail ELSE
    LET message == ReadMessageAll(binaryPacketHeader.rest) IN IF ~message.ok THEN Fail ELSE
    Ok([ binaryPacketHeader |-> binaryPacketHeader.value,
         message            |-> message.value ], message.rest)

ZeroUdpPacket ==
    [ binaryPacketHeader |-> ZeroBinaryPacketHeader,
      message            |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.binaryPacketHeader = one] : one \in CheckedBinaryPacketHeader }
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

(* Every Binary Packet Header decodes back to what was encoded, and leaves nothing over *)
RoundTripBinaryPacketHeader ==
    \A message \in CheckedBinaryPacketHeader :
        LET read == DecodeBinaryPacketHeader(EncodeBinaryPacketHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Reset Group decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelResetGroup ==
    \A message \in CheckedChannelResetGroup :
        LET read == DecodeChannelResetGroup(EncodeChannelResetGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Reset Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelResetGroups ==
    \A message \in CheckedChannelResetGroups :
        LET read == DecodeChannelResetGroups(EncodeChannelResetGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Reset decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelReset ==
    \A message \in CheckedChannelReset :
        LET read == DecodeChannelReset(EncodeChannelReset(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Admin Login decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminLogin ==
    \A message \in CheckedAdminLogin :
        LET read == DecodeAdminLogin(EncodeAdminLogin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Admin Logout decodes back to what was encoded, and leaves nothing over *)
RoundTripAdminLogout ==
    \A message \in CheckedAdminLogout :
        LET read == DecodeAdminLogout(EncodeAdminLogout(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatus ==
    \A message \in CheckedSecurityStatus :
        LET read == DecodeSecurityStatus(EncodeSecurityStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Volume Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshVolumeGroup ==
    \A message \in CheckedIncrementalRefreshVolumeGroup :
        LET read == DecodeIncrementalRefreshVolumeGroup(EncodeIncrementalRefreshVolumeGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Volume Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshVolumeGroups ==
    \A message \in CheckedIncrementalRefreshVolumeGroups :
        LET read == DecodeIncrementalRefreshVolumeGroups(EncodeIncrementalRefreshVolumeGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Volume decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshVolume ==
    \A message \in CheckedMdIncrementalRefreshVolume :
        LET read == DecodeMdIncrementalRefreshVolume(EncodeMdIncrementalRefreshVolume(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Related Sym Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRelatedSymGroup ==
    \A message \in CheckedRelatedSymGroup :
        LET read == DecodeRelatedSymGroup(EncodeRelatedSymGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Related Sym Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRelatedSymGroups ==
    \A message \in CheckedRelatedSymGroups :
        LET read == DecodeRelatedSymGroups(EncodeRelatedSymGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequest ==
    \A message \in CheckedQuoteRequest :
        LET read == DecodeQuoteRequest(EncodeQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Book Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBookGroup ==
    \A message \in CheckedIncrementalRefreshBookGroup :
        LET read == DecodeIncrementalRefreshBookGroup(EncodeIncrementalRefreshBookGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Book Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBookGroups ==
    \A message \in CheckedIncrementalRefreshBookGroups :
        LET read == DecodeIncrementalRefreshBookGroups(EncodeIncrementalRefreshBookGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Book Order Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBookOrderIdGroup ==
    \A message \in CheckedIncrementalRefreshBookOrderIdGroup :
        LET read == DecodeIncrementalRefreshBookOrderIdGroup(EncodeIncrementalRefreshBookOrderIdGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Book Order Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshBookOrderIdGroups ==
    \A message \in CheckedIncrementalRefreshBookOrderIdGroups :
        LET read == DecodeIncrementalRefreshBookOrderIdGroups(EncodeIncrementalRefreshBookOrderIdGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Book decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshBook ==
    \A message \in CheckedMdIncrementalRefreshBook :
        LET read == DecodeMdIncrementalRefreshBook(EncodeMdIncrementalRefreshBook(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Order Book Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshOrderBookGroup ==
    \A message \in CheckedIncrementalRefreshOrderBookGroup :
        LET read == DecodeIncrementalRefreshOrderBookGroup(EncodeIncrementalRefreshOrderBookGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Order Book Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshOrderBookGroups ==
    \A message \in CheckedIncrementalRefreshOrderBookGroups :
        LET read == DecodeIncrementalRefreshOrderBookGroups(EncodeIncrementalRefreshOrderBookGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Order Book decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshOrderBook ==
    \A message \in CheckedMdIncrementalRefreshOrderBook :
        LET read == DecodeMdIncrementalRefreshOrderBook(EncodeMdIncrementalRefreshOrderBook(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Trade Summary Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTradeSummaryGroup ==
    \A message \in CheckedIncrementalRefreshTradeSummaryGroup :
        LET read == DecodeIncrementalRefreshTradeSummaryGroup(EncodeIncrementalRefreshTradeSummaryGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Trade Summary Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTradeSummaryGroups ==
    \A message \in CheckedIncrementalRefreshTradeSummaryGroups :
        LET read == DecodeIncrementalRefreshTradeSummaryGroups(EncodeIncrementalRefreshTradeSummaryGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Trade Summary Order Id Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTradeSummaryOrderIdGroup ==
    \A message \in CheckedIncrementalRefreshTradeSummaryOrderIdGroup :
        LET read == DecodeIncrementalRefreshTradeSummaryOrderIdGroup(EncodeIncrementalRefreshTradeSummaryOrderIdGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Trade Summary Order Id Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshTradeSummaryOrderIdGroups ==
    \A message \in CheckedIncrementalRefreshTradeSummaryOrderIdGroups :
        LET read == DecodeIncrementalRefreshTradeSummaryOrderIdGroups(EncodeIncrementalRefreshTradeSummaryOrderIdGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Trade Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshTradeSummary ==
    \A message \in CheckedMdIncrementalRefreshTradeSummary :
        LET read == DecodeMdIncrementalRefreshTradeSummary(EncodeMdIncrementalRefreshTradeSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Daily Statistics Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshDailyStatisticsGroup ==
    \A message \in CheckedIncrementalRefreshDailyStatisticsGroup :
        LET read == DecodeIncrementalRefreshDailyStatisticsGroup(EncodeIncrementalRefreshDailyStatisticsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Daily Statistics Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshDailyStatisticsGroups ==
    \A message \in CheckedIncrementalRefreshDailyStatisticsGroups :
        LET read == DecodeIncrementalRefreshDailyStatisticsGroups(EncodeIncrementalRefreshDailyStatisticsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Daily Statistics decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshDailyStatistics ==
    \A message \in CheckedMdIncrementalRefreshDailyStatistics :
        LET read == DecodeMdIncrementalRefreshDailyStatistics(EncodeMdIncrementalRefreshDailyStatistics(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Limits Banding Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshLimitsBandingGroup ==
    \A message \in CheckedIncrementalRefreshLimitsBandingGroup :
        LET read == DecodeIncrementalRefreshLimitsBandingGroup(EncodeIncrementalRefreshLimitsBandingGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Limits Banding Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshLimitsBandingGroups ==
    \A message \in CheckedIncrementalRefreshLimitsBandingGroups :
        LET read == DecodeIncrementalRefreshLimitsBandingGroups(EncodeIncrementalRefreshLimitsBandingGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Limits Banding decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshLimitsBanding ==
    \A message \in CheckedMdIncrementalRefreshLimitsBanding :
        LET read == DecodeMdIncrementalRefreshLimitsBanding(EncodeMdIncrementalRefreshLimitsBanding(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Session Statistics Group decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSessionStatisticsGroup ==
    \A message \in CheckedIncrementalRefreshSessionStatisticsGroup :
        LET read == DecodeIncrementalRefreshSessionStatisticsGroup(EncodeIncrementalRefreshSessionStatisticsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Incremental Refresh Session Statistics Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripIncrementalRefreshSessionStatisticsGroups ==
    \A message \in CheckedIncrementalRefreshSessionStatisticsGroups :
        LET read == DecodeIncrementalRefreshSessionStatisticsGroups(EncodeIncrementalRefreshSessionStatisticsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Incremental Refresh Session Statistics decodes back to what was encoded, and leaves nothing over *)
RoundTripMdIncrementalRefreshSessionStatistics ==
    \A message \in CheckedMdIncrementalRefreshSessionStatistics :
        LET read == DecodeMdIncrementalRefreshSessionStatistics(EncodeMdIncrementalRefreshSessionStatistics(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshGroup ==
    \A message \in CheckedSnapshotFullRefreshGroup :
        LET read == DecodeSnapshotFullRefreshGroup(EncodeSnapshotFullRefreshGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshGroups ==
    \A message \in CheckedSnapshotFullRefreshGroups :
        LET read == DecodeSnapshotFullRefreshGroups(EncodeSnapshotFullRefreshGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefresh ==
    \A message \in CheckedSnapshotFullRefresh :
        LET read == DecodeSnapshotFullRefresh(EncodeSnapshotFullRefresh(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Order Book Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrderBookGroup ==
    \A message \in CheckedSnapshotFullRefreshOrderBookGroup :
        LET read == DecodeSnapshotFullRefreshOrderBookGroup(EncodeSnapshotFullRefreshOrderBookGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Order Book Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrderBookGroups ==
    \A message \in CheckedSnapshotFullRefreshOrderBookGroups :
        LET read == DecodeSnapshotFullRefreshOrderBookGroups(EncodeSnapshotFullRefreshOrderBookGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Order Book decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshOrderBook ==
    \A message \in CheckedSnapshotFullRefreshOrderBook :
        LET read == DecodeSnapshotFullRefreshOrderBook(EncodeSnapshotFullRefreshOrderBook(message))
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

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup ==
    \A message \in CheckedEventsGroup :
        LET read == DecodeEventsGroup(EncodeEventsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups ==
    \A message \in CheckedEventsGroups :
        LET read == DecodeEventsGroups(EncodeEventsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroup ==
    \A message \in CheckedFeedTypesGroup :
        LET read == DecodeFeedTypesGroup(EncodeFeedTypesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroups ==
    \A message \in CheckedFeedTypesGroups :
        LET read == DecodeFeedTypesGroups(EncodeFeedTypesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup ==
    \A message \in CheckedInstAttribGroup :
        LET read == DecodeInstAttribGroup(EncodeInstAttribGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups ==
    \A message \in CheckedInstAttribGroups :
        LET read == DecodeInstAttribGroups(EncodeInstAttribGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroup ==
    \A message \in CheckedLotTypeRulesGroup :
        LET read == DecodeLotTypeRulesGroup(EncodeLotTypeRulesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroups ==
    \A message \in CheckedLotTypeRulesGroups :
        LET read == DecodeLotTypeRulesGroups(EncodeLotTypeRulesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Future decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionFuture ==
    \A message \in CheckedMdInstrumentDefinitionFuture :
        LET read == DecodeMdInstrumentDefinitionFuture(EncodeMdInstrumentDefinitionFuture(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear2 ==
    \A message \in CheckedMaturityMonthYear2 :
        LET read == DecodeMaturityMonthYear2(EncodeMaturityMonthYear2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup2 ==
    \A message \in CheckedEventsGroup2 :
        LET read == DecodeEventsGroup2(EncodeEventsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups2 ==
    \A message \in CheckedEventsGroups2 :
        LET read == DecodeEventsGroups2(EncodeEventsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroup2 ==
    \A message \in CheckedFeedTypesGroup2 :
        LET read == DecodeFeedTypesGroup2(EncodeFeedTypesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroups2 ==
    \A message \in CheckedFeedTypesGroups2 :
        LET read == DecodeFeedTypesGroups2(EncodeFeedTypesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup2 ==
    \A message \in CheckedInstAttribGroup2 :
        LET read == DecodeInstAttribGroup2(EncodeInstAttribGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups2 ==
    \A message \in CheckedInstAttribGroups2 :
        LET read == DecodeInstAttribGroups2(EncodeInstAttribGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroup2 ==
    \A message \in CheckedLotTypeRulesGroup2 :
        LET read == DecodeLotTypeRulesGroup2(EncodeLotTypeRulesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroups2 ==
    \A message \in CheckedLotTypeRulesGroups2 :
        LET read == DecodeLotTypeRulesGroups2(EncodeLotTypeRulesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionUnderlyingsGroup ==
    \A message \in CheckedOptionUnderlyingsGroup :
        LET read == DecodeOptionUnderlyingsGroup(EncodeOptionUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionUnderlyingsGroups ==
    \A message \in CheckedOptionUnderlyingsGroups :
        LET read == DecodeOptionUnderlyingsGroups(EncodeOptionUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Related Instruments Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRelatedInstrumentsGroup ==
    \A message \in CheckedOptionRelatedInstrumentsGroup :
        LET read == DecodeOptionRelatedInstrumentsGroup(EncodeOptionRelatedInstrumentsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Related Instruments Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRelatedInstrumentsGroups ==
    \A message \in CheckedOptionRelatedInstrumentsGroups :
        LET read == DecodeOptionRelatedInstrumentsGroups(EncodeOptionRelatedInstrumentsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Option decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionOption ==
    \A message \in CheckedMdInstrumentDefinitionOption :
        LET read == DecodeMdInstrumentDefinitionOption(EncodeMdInstrumentDefinitionOption(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Maturity Month Year decodes back to what was encoded, and leaves nothing over *)
RoundTripMaturityMonthYear3 ==
    \A message \in CheckedMaturityMonthYear3 :
        LET read == DecodeMaturityMonthYear3(EncodeMaturityMonthYear3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup3 ==
    \A message \in CheckedEventsGroup3 :
        LET read == DecodeEventsGroup3(EncodeEventsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups3 ==
    \A message \in CheckedEventsGroups3 :
        LET read == DecodeEventsGroups3(EncodeEventsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroup3 ==
    \A message \in CheckedFeedTypesGroup3 :
        LET read == DecodeFeedTypesGroup3(EncodeFeedTypesGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroups3 ==
    \A message \in CheckedFeedTypesGroups3 :
        LET read == DecodeFeedTypesGroups3(EncodeFeedTypesGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup3 ==
    \A message \in CheckedInstAttribGroup3 :
        LET read == DecodeInstAttribGroup3(EncodeInstAttribGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups3 ==
    \A message \in CheckedInstAttribGroups3 :
        LET read == DecodeInstAttribGroups3(EncodeInstAttribGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroup3 ==
    \A message \in CheckedLotTypeRulesGroup3 :
        LET read == DecodeLotTypeRulesGroup3(EncodeLotTypeRulesGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroups3 ==
    \A message \in CheckedLotTypeRulesGroups3 :
        LET read == DecodeLotTypeRulesGroups3(EncodeLotTypeRulesGroups3(message))
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

(* Every Md Instrument Definition Spread decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionSpread ==
    \A message \in CheckedMdInstrumentDefinitionSpread :
        LET read == DecodeMdInstrumentDefinitionSpread(EncodeMdInstrumentDefinitionSpread(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup4 ==
    \A message \in CheckedEventsGroup4 :
        LET read == DecodeEventsGroup4(EncodeEventsGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups4 ==
    \A message \in CheckedEventsGroups4 :
        LET read == DecodeEventsGroups4(EncodeEventsGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroup4 ==
    \A message \in CheckedFeedTypesGroup4 :
        LET read == DecodeFeedTypesGroup4(EncodeFeedTypesGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroups4 ==
    \A message \in CheckedFeedTypesGroups4 :
        LET read == DecodeFeedTypesGroups4(EncodeFeedTypesGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup4 ==
    \A message \in CheckedInstAttribGroup4 :
        LET read == DecodeInstAttribGroup4(EncodeInstAttribGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups4 ==
    \A message \in CheckedInstAttribGroups4 :
        LET read == DecodeInstAttribGroups4(EncodeInstAttribGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroup4 ==
    \A message \in CheckedLotTypeRulesGroup4 :
        LET read == DecodeLotTypeRulesGroup4(EncodeLotTypeRulesGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroups4 ==
    \A message \in CheckedLotTypeRulesGroups4 :
        LET read == DecodeLotTypeRulesGroups4(EncodeLotTypeRulesGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Fixed Income decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionFixedIncome ==
    \A message \in CheckedMdInstrumentDefinitionFixedIncome :
        LET read == DecodeMdInstrumentDefinitionFixedIncome(EncodeMdInstrumentDefinitionFixedIncome(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Group decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroup5 ==
    \A message \in CheckedEventsGroup5 :
        LET read == DecodeEventsGroup5(EncodeEventsGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Events Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripEventsGroups5 ==
    \A message \in CheckedEventsGroups5 :
        LET read == DecodeEventsGroups5(EncodeEventsGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroup5 ==
    \A message \in CheckedFeedTypesGroup5 :
        LET read == DecodeFeedTypesGroup5(EncodeFeedTypesGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Feed Types Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFeedTypesGroups5 ==
    \A message \in CheckedFeedTypesGroups5 :
        LET read == DecodeFeedTypesGroups5(EncodeFeedTypesGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroup5 ==
    \A message \in CheckedInstAttribGroup5 :
        LET read == DecodeInstAttribGroup5(EncodeInstAttribGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inst Attrib Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstAttribGroups5 ==
    \A message \in CheckedInstAttribGroups5 :
        LET read == DecodeInstAttribGroups5(EncodeInstAttribGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Group decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroup5 ==
    \A message \in CheckedLotTypeRulesGroup5 :
        LET read == DecodeLotTypeRulesGroup5(EncodeLotTypeRulesGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Type Rules Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripLotTypeRulesGroups5 ==
    \A message \in CheckedLotTypeRulesGroups5 :
        LET read == DecodeLotTypeRulesGroups5(EncodeLotTypeRulesGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Underlyings Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoUnderlyingsGroup ==
    \A message \in CheckedRepoUnderlyingsGroup :
        LET read == DecodeRepoUnderlyingsGroup(EncodeRepoUnderlyingsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Underlyings Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoUnderlyingsGroups ==
    \A message \in CheckedRepoUnderlyingsGroups :
        LET read == DecodeRepoUnderlyingsGroups(EncodeRepoUnderlyingsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Related Instruments Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoRelatedInstrumentsGroup ==
    \A message \in CheckedRepoRelatedInstrumentsGroup :
        LET read == DecodeRepoRelatedInstrumentsGroup(EncodeRepoRelatedInstrumentsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Repo Related Instruments Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRepoRelatedInstrumentsGroups ==
    \A message \in CheckedRepoRelatedInstrumentsGroups :
        LET read == DecodeRepoRelatedInstrumentsGroups(EncodeRepoRelatedInstrumentsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Instrument Definition Repo decodes back to what was encoded, and leaves nothing over *)
RoundTripMdInstrumentDefinitionRepo ==
    \A message \in CheckedMdInstrumentDefinitionRepo :
        LET read == DecodeMdInstrumentDefinitionRepo(EncodeMdInstrumentDefinitionRepo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Top Orders Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshTopOrdersGroup ==
    \A message \in CheckedSnapshotRefreshTopOrdersGroup :
        LET read == DecodeSnapshotRefreshTopOrdersGroup(EncodeSnapshotRefreshTopOrdersGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Top Orders Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshTopOrdersGroups ==
    \A message \in CheckedSnapshotRefreshTopOrdersGroups :
        LET read == DecodeSnapshotRefreshTopOrdersGroups(EncodeSnapshotRefreshTopOrdersGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Refresh Top Orders decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRefreshTopOrders ==
    \A message \in CheckedSnapshotRefreshTopOrders :
        LET read == DecodeSnapshotRefreshTopOrders(EncodeSnapshotRefreshTopOrders(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Workup Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusWorkupGroup ==
    \A message \in CheckedSecurityStatusWorkupGroup :
        LET read == DecodeSecurityStatusWorkupGroup(EncodeSecurityStatusWorkupGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Workup Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusWorkupGroups ==
    \A message \in CheckedSecurityStatusWorkupGroups :
        LET read == DecodeSecurityStatusWorkupGroups(EncodeSecurityStatusWorkupGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Workup decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusWorkup ==
    \A message \in CheckedSecurityStatusWorkup :
        LET read == DecodeSecurityStatusWorkup(EncodeSecurityStatusWorkup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Tcp Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshTcpGroup ==
    \A message \in CheckedSnapshotFullRefreshTcpGroup :
        LET read == DecodeSnapshotFullRefreshTcpGroup(EncodeSnapshotFullRefreshTcpGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Tcp Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshTcpGroups ==
    \A message \in CheckedSnapshotFullRefreshTcpGroups :
        LET read == DecodeSnapshotFullRefreshTcpGroups(EncodeSnapshotFullRefreshTcpGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Full Refresh Tcp decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotFullRefreshTcp ==
    \A message \in CheckedSnapshotFullRefreshTcp :
        LET read == DecodeSnapshotFullRefreshTcp(EncodeSnapshotFullRefreshTcp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collateral Market Value Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCollateralMarketValueGroup ==
    \A message \in CheckedCollateralMarketValueGroup :
        LET read == DecodeCollateralMarketValueGroup(EncodeCollateralMarketValueGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collateral Market Value Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCollateralMarketValueGroups ==
    \A message \in CheckedCollateralMarketValueGroups :
        LET read == DecodeCollateralMarketValueGroups(EncodeCollateralMarketValueGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collateral Market Value decodes back to what was encoded, and leaves nothing over *)
RoundTripCollateralMarketValue ==
    \A message \in CheckedCollateralMarketValue :
        LET read == DecodeCollateralMarketValue(EncodeCollateralMarketValue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiate decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiate ==
    \A message \in CheckedNegotiate :
        LET read == DecodeNegotiate(EncodeNegotiate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiation Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiationReject ==
    \A message \in CheckedNegotiationReject :
        LET read == DecodeNegotiationReject(EncodeNegotiationReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiation Response decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiationResponse ==
    \A message \in CheckedNegotiationResponse :
        LET read == DecodeNegotiationResponse(EncodeNegotiationResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminate ==
    \A message \in CheckedTerminate :
        LET read == DecodeTerminate(EncodeTerminate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestSecurityGroup ==
    \A message \in CheckedMarketDataRequestSecurityGroup :
        LET read == DecodeMarketDataRequestSecurityGroup(EncodeMarketDataRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestSecurityGroups ==
    \A message \in CheckedMarketDataRequestSecurityGroups :
        LET read == DecodeMarketDataRequestSecurityGroups(EncodeMarketDataRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestRelatedSymbolGroup ==
    \A message \in CheckedMarketDataRequestRelatedSymbolGroup :
        LET read == DecodeMarketDataRequestRelatedSymbolGroup(EncodeMarketDataRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestRelatedSymbolGroups ==
    \A message \in CheckedMarketDataRequestRelatedSymbolGroups :
        LET read == DecodeMarketDataRequestRelatedSymbolGroups(EncodeMarketDataRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequest ==
    \A message \in CheckedMarketDataRequest :
        LET read == DecodeMarketDataRequest(EncodeMarketDataRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckSecurityGroup ==
    \A message \in CheckedRequestAckSecurityGroup :
        LET read == DecodeRequestAckSecurityGroup(EncodeRequestAckSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckSecurityGroups ==
    \A message \in CheckedRequestAckSecurityGroups :
        LET read == DecodeRequestAckSecurityGroups(EncodeRequestAckSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckRelatedSymbolGroup ==
    \A message \in CheckedRequestAckRelatedSymbolGroup :
        LET read == DecodeRequestAckRelatedSymbolGroup(EncodeRequestAckRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAckRelatedSymbolGroups ==
    \A message \in CheckedRequestAckRelatedSymbolGroups :
        LET read == DecodeRequestAckRelatedSymbolGroups(EncodeRequestAckRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestAck ==
    \A message \in CheckedRequestAck :
        LET read == DecodeRequestAck(EncodeRequestAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestReject ==
    \A message \in CheckedRequestReject :
        LET read == DecodeRequestReject(EncodeRequestReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestSecurityGroup ==
    \A message \in CheckedSecurityListRequestSecurityGroup :
        LET read == DecodeSecurityListRequestSecurityGroup(EncodeSecurityListRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestSecurityGroups ==
    \A message \in CheckedSecurityListRequestSecurityGroups :
        LET read == DecodeSecurityListRequestSecurityGroups(EncodeSecurityListRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestRelatedSymbolGroup ==
    \A message \in CheckedSecurityListRequestRelatedSymbolGroup :
        LET read == DecodeSecurityListRequestRelatedSymbolGroup(EncodeSecurityListRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestRelatedSymbolGroups ==
    \A message \in CheckedSecurityListRequestRelatedSymbolGroups :
        LET read == DecodeSecurityListRequestRelatedSymbolGroups(EncodeSecurityListRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequest ==
    \A message \in CheckedSecurityListRequest :
        LET read == DecodeSecurityListRequest(EncodeSecurityListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestSecurityGroup ==
    \A message \in CheckedSecurityStatusRequestSecurityGroup :
        LET read == DecodeSecurityStatusRequestSecurityGroup(EncodeSecurityStatusRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestSecurityGroups ==
    \A message \in CheckedSecurityStatusRequestSecurityGroups :
        LET read == DecodeSecurityStatusRequestSecurityGroups(EncodeSecurityStatusRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestRelatedSymbolGroup ==
    \A message \in CheckedSecurityStatusRequestRelatedSymbolGroup :
        LET read == DecodeSecurityStatusRequestRelatedSymbolGroup(EncodeSecurityStatusRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestRelatedSymbolGroups ==
    \A message \in CheckedSecurityStatusRequestRelatedSymbolGroups :
        LET read == DecodeSecurityStatusRequestRelatedSymbolGroups(EncodeSecurityStatusRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequest ==
    \A message \in CheckedSecurityStatusRequest :
        LET read == DecodeSecurityStatusRequest(EncodeSecurityStatusRequest(message))
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

(* A Payload is selected by the Schema Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag[1], message.tag[2], EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
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
