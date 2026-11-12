----------------- MODULE BjseSecurities_TcpMarketData_v1_1 -----------------
(***************************************************************************)
(* Beijing Stock Exchange Bjse Tcp Market Data v1.1                        *)
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
(* Logon Message: 92 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ senderCompId     : Sample(20),
      targetCompId     : Sample(20),
      heartBtInt       : Sample(4),
      password         : Sample(16),
      defaultApplVerId : Sample(32) ]

EncodeLogonMessage(message) ==
    message.senderCompId
        \o message.targetCompId
        \o message.heartBtInt
        \o message.password
        \o message.defaultApplVerId

DecodeLogonMessage(bytes) ==
    LET senderCompId == ReadBytes(bytes, 20) IN IF ~senderCompId.ok THEN Fail ELSE
    LET targetCompId == ReadBytes(senderCompId.rest, 20) IN IF ~targetCompId.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(targetCompId.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET password == ReadBytes(heartBtInt.rest, 16) IN IF ~password.ok THEN Fail ELSE
    LET defaultApplVerId == ReadBytes(password.rest, 32) IN IF ~defaultApplVerId.ok THEN Fail ELSE
    Ok([ senderCompId     |-> senderCompId.value,
         targetCompId     |-> targetCompId.value,
         heartBtInt       |-> heartBtInt.value,
         password         |-> password.value,
         defaultApplVerId |-> defaultApplVerId.value ], defaultApplVerId.rest)

ZeroLogonMessage ==
    [ senderCompId     |-> [i \in 1 .. 20 |-> 0],
      targetCompId     |-> [i \in 1 .. 20 |-> 0],
      heartBtInt       |-> [i \in 1 .. 4 |-> 0],
      password         |-> [i \in 1 .. 16 |-> 0],
      defaultApplVerId |-> [i \in 1 .. 32 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.senderCompId = one] : one \in Sample(20) }
        \cup { [ZeroLogonMessage EXCEPT !.targetCompId = one] : one \in Sample(20) }
        \cup { [ZeroLogonMessage EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(16) }
        \cup { [ZeroLogonMessage EXCEPT !.defaultApplVerId = one] : one \in Sample(32) }

(***************************************************************************)
(* Logout Message: 204 bytes                                               *)
(***************************************************************************)

LogoutMessage ==
    [ sessionStatus : Sample(4),
      text          : Sample(200) ]

EncodeLogoutMessage(message) ==
    message.sessionStatus
        \o message.text

DecodeLogoutMessage(bytes) ==
    LET sessionStatus == ReadBytes(bytes, 4) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET text == ReadBytes(sessionStatus.rest, 200) IN IF ~text.ok THEN Fail ELSE
    Ok([ sessionStatus |-> sessionStatus.value,
         text          |-> text.value ], text.rest)

ZeroLogoutMessage ==
    [ sessionStatus |-> [i \in 1 .. 4 |-> 0],
      text          |-> [i \in 1 .. 200 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.sessionStatus = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.text = one] : one \in Sample(200) }

(***************************************************************************)
(* Channel Heartbeat Message: 20 bytes                                     *)
(***************************************************************************)

ChannelHeartbeatMessage ==
    [ channelNo      : Sample(2),
      applLastSeqNum : Sample(8),
      endOfChannel   : Sample(2),
      origTime       : Sample(8) ]

EncodeChannelHeartbeatMessage(message) ==
    message.channelNo
        \o message.applLastSeqNum
        \o message.endOfChannel
        \o message.origTime

DecodeChannelHeartbeatMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applLastSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applLastSeqNum.ok THEN Fail ELSE
    LET endOfChannel == ReadBytes(applLastSeqNum.rest, 2) IN IF ~endOfChannel.ok THEN Fail ELSE
    LET origTime == ReadBytes(endOfChannel.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    Ok([ channelNo      |-> channelNo.value,
         applLastSeqNum |-> applLastSeqNum.value,
         endOfChannel   |-> endOfChannel.value,
         origTime       |-> origTime.value ], origTime.rest)

ZeroChannelHeartbeatMessage ==
    [ channelNo      |-> [i \in 1 .. 2 |-> 0],
      applLastSeqNum |-> [i \in 1 .. 8 |-> 0],
      endOfChannel   |-> [i \in 1 .. 2 |-> 0],
      origTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Channel Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedChannelHeartbeatMessage ==
    { ZeroChannelHeartbeatMessage }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.applLastSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.endOfChannel = one] : one \in Sample(2) }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.origTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Retransmission Message: 52 bytes                                        *)
(***************************************************************************)

RetransmissionMessage ==
    [ resendType    : Sample(1),
      channelNo     : Sample(2),
      applBegSeqNum : Sample(8),
      applEndSeqNum : Sample(8),
      newsId        : Sample(16),
      resendStatus  : Sample(1),
      rejectText    : Sample(16) ]

EncodeRetransmissionMessage(message) ==
    message.resendType
        \o message.channelNo
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.newsId
        \o message.resendStatus
        \o message.rejectText

DecodeRetransmissionMessage(bytes) ==
    LET resendType == ReadBytes(bytes, 1) IN IF ~resendType.ok THEN Fail ELSE
    LET channelNo == ReadBytes(resendType.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applBegSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET newsId == ReadBytes(applEndSeqNum.rest, 16) IN IF ~newsId.ok THEN Fail ELSE
    LET resendStatus == ReadBytes(newsId.rest, 1) IN IF ~resendStatus.ok THEN Fail ELSE
    LET rejectText == ReadBytes(resendStatus.rest, 16) IN IF ~rejectText.ok THEN Fail ELSE
    Ok([ resendType    |-> resendType.value,
         channelNo     |-> channelNo.value,
         applBegSeqNum |-> applBegSeqNum.value,
         applEndSeqNum |-> applEndSeqNum.value,
         newsId        |-> newsId.value,
         resendStatus  |-> resendStatus.value,
         rejectText    |-> rejectText.value ], rejectText.rest)

ZeroRetransmissionMessage ==
    [ resendType    |-> [i \in 1 .. 1 |-> 0],
      channelNo     |-> [i \in 1 .. 2 |-> 0],
      applBegSeqNum |-> [i \in 1 .. 8 |-> 0],
      applEndSeqNum |-> [i \in 1 .. 8 |-> 0],
      newsId        |-> [i \in 1 .. 16 |-> 0],
      resendStatus  |-> [i \in 1 .. 1 |-> 0],
      rejectText    |-> [i \in 1 .. 16 |-> 0] ]

(* Retransmission Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionMessage ==
    { ZeroRetransmissionMessage }
        \cup { [ZeroRetransmissionMessage EXCEPT !.resendType = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.newsId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.resendStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionMessage EXCEPT !.rejectText = one] : one \in Sample(16) }

(***************************************************************************)
(* Md Stream I Ds: 15 bytes                                                *)
(***************************************************************************)

MdStreamIDs ==
    [ mdStreamId       : Sample(3),
      stockNum         : Sample(4),
      tradingPhaseCode : Sample(8) ]

EncodeMdStreamIDs(message) ==
    message.mdStreamId
        \o message.stockNum
        \o message.tradingPhaseCode

DecodeMdStreamIDs(bytes) ==
    LET mdStreamId == ReadBytes(bytes, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET stockNum == ReadBytes(mdStreamId.rest, 4) IN IF ~stockNum.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(stockNum.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    Ok([ mdStreamId       |-> mdStreamId.value,
         stockNum         |-> stockNum.value,
         tradingPhaseCode |-> tradingPhaseCode.value ], tradingPhaseCode.rest)

ZeroMdStreamIDs ==
    [ mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      stockNum         |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0] ]

(* Md Stream I Ds at zero, then each field in turn at the values it is checked at *)
CheckedMdStreamIDs ==
    { ZeroMdStreamIDs }
        \cup { [ZeroMdStreamIDs EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroMdStreamIDs EXCEPT !.stockNum = one] : one \in Sample(4) }
        \cup { [ZeroMdStreamIDs EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }

(* A run of Md Stream I Ds, written one after another *)
RECURSIVE EncodeMdStreamIDsList(_)
EncodeMdStreamIDsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdStreamIDs(Head(messages)) \o EncodeMdStreamIDsList(Tail(messages))

(* As many Md Stream I Ds as the field that counts them says *)
RECURSIVE ReadMdStreamIDsList(_, _)
ReadMdStreamIDsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdStreamIDs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdStreamIDsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Stream I Ds of each kind, for the lists that carry them *)
OneMdStreamIDs == { ZeroMdStreamIDs }

(***************************************************************************)
(* Snapshot Channel Statistics Message                                     *)
(***************************************************************************)

SnapshotChannelStatisticsMessage ==
    [ origTime    : Sample(8),
      channelNo   : Sample(2),
      mdStreamIDs : SampleLists(OneMdStreamIDs) ]

EncodeSnapshotChannelStatisticsMessage(message) ==
    message.origTime
        \o message.channelNo
        \o EncodeUIntBE(Len(message.mdStreamIDs), 4)
        \o EncodeMdStreamIDsList(message.mdStreamIDs)

DecodeSnapshotChannelStatisticsMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET noMdStreamId == ReadUIntBE(channelNo.rest, 4) IN IF ~noMdStreamId.ok THEN Fail ELSE
    LET mdStreamIDs == ReadMdStreamIDsList(noMdStreamId.rest, noMdStreamId.value) IN IF ~mdStreamIDs.ok THEN Fail ELSE
    Ok([ origTime    |-> origTime.value,
         channelNo   |-> channelNo.value,
         mdStreamIDs |-> mdStreamIDs.value ], mdStreamIDs.rest)

ZeroSnapshotChannelStatisticsMessage ==
    [ origTime    |-> [i \in 1 .. 8 |-> 0],
      channelNo   |-> [i \in 1 .. 2 |-> 0],
      mdStreamIDs |-> << >> ]

(* Snapshot Channel Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotChannelStatisticsMessage ==
    { ZeroSnapshotChannelStatisticsMessage }
        \cup { [ZeroSnapshotChannelStatisticsMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotChannelStatisticsMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotChannelStatisticsMessage EXCEPT !.mdStreamIDs = one] : one \in SampleLists(OneMdStreamIDs) }

(***************************************************************************)
(* Business Reject Message: 74 bytes                                       *)
(***************************************************************************)

BusinessRejectMessage ==
    [ refSeqNum            : Sample(8),
      refMsgType           : Sample(4),
      businessRejectRefId  : Sample(10),
      businessRejectReason : Sample(2),
      businessRejectText   : Sample(50) ]

EncodeBusinessRejectMessage(message) ==
    message.refSeqNum
        \o message.refMsgType
        \o message.businessRejectRefId
        \o message.businessRejectReason
        \o message.businessRejectText

DecodeBusinessRejectMessage(bytes) ==
    LET refSeqNum == ReadBytes(bytes, 8) IN IF ~refSeqNum.ok THEN Fail ELSE
    LET refMsgType == ReadBytes(refSeqNum.rest, 4) IN IF ~refMsgType.ok THEN Fail ELSE
    LET businessRejectRefId == ReadBytes(refMsgType.rest, 10) IN IF ~businessRejectRefId.ok THEN Fail ELSE
    LET businessRejectReason == ReadBytes(businessRejectRefId.rest, 2) IN IF ~businessRejectReason.ok THEN Fail ELSE
    LET businessRejectText == ReadBytes(businessRejectReason.rest, 50) IN IF ~businessRejectText.ok THEN Fail ELSE
    Ok([ refSeqNum            |-> refSeqNum.value,
         refMsgType           |-> refMsgType.value,
         businessRejectRefId  |-> businessRejectRefId.value,
         businessRejectReason |-> businessRejectReason.value,
         businessRejectText   |-> businessRejectText.value ], businessRejectText.rest)

ZeroBusinessRejectMessage ==
    [ refSeqNum            |-> [i \in 1 .. 8 |-> 0],
      refMsgType           |-> [i \in 1 .. 4 |-> 0],
      businessRejectRefId  |-> [i \in 1 .. 10 |-> 0],
      businessRejectReason |-> [i \in 1 .. 2 |-> 0],
      businessRejectText   |-> [i \in 1 .. 50 |-> 0] ]

(* Business Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessRejectMessage ==
    { ZeroBusinessRejectMessage }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.refSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.refMsgType = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectRefId = one] : one \in Sample(10) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectText = one] : one \in Sample(50) }

(***************************************************************************)
(* Switch: 4 bytes                                                         *)
(***************************************************************************)

Switch ==
    [ securitySwitchType   : Sample(2),
      securitySwitchStatus : Sample(2) ]

EncodeSwitch(message) ==
    message.securitySwitchType
        \o message.securitySwitchStatus

DecodeSwitch(bytes) ==
    LET securitySwitchType == ReadBytes(bytes, 2) IN IF ~securitySwitchType.ok THEN Fail ELSE
    LET securitySwitchStatus == ReadBytes(securitySwitchType.rest, 2) IN IF ~securitySwitchStatus.ok THEN Fail ELSE
    Ok([ securitySwitchType   |-> securitySwitchType.value,
         securitySwitchStatus |-> securitySwitchStatus.value ], securitySwitchStatus.rest)

ZeroSwitch ==
    [ securitySwitchType   |-> [i \in 1 .. 2 |-> 0],
      securitySwitchStatus |-> [i \in 1 .. 2 |-> 0] ]

(* Switch at zero, then each field in turn at the values it is checked at *)
CheckedSwitch ==
    { ZeroSwitch }
        \cup { [ZeroSwitch EXCEPT !.securitySwitchType = one] : one \in Sample(2) }
        \cup { [ZeroSwitch EXCEPT !.securitySwitchStatus = one] : one \in Sample(2) }

(* A run of Switch, written one after another *)
RECURSIVE EncodeSwitchList(_)
EncodeSwitchList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSwitch(Head(messages)) \o EncodeSwitchList(Tail(messages))

(* As many Switch as the field that counts them says *)
RECURSIVE ReadSwitchList(_, _)
ReadSwitchList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSwitch(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSwitchList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Switch of each kind, for the lists that carry them *)
OneSwitch == { ZeroSwitch }

(***************************************************************************)
(* Security Real Time Status Message                                       *)
(***************************************************************************)

SecurityRealTimeStatusMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      securitySymbol   : Sample(40),
      switch           : SampleLists(OneSwitch) ]

EncodeSecurityRealTimeStatusMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.securityId
        \o message.securityIdSource
        \o message.securitySymbol
        \o EncodeUIntBE(Len(message.switch), 4)
        \o EncodeSwitchList(message.switch)

DecodeSecurityRealTimeStatusMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(channelNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(securityIdSource.rest, 40) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET noSwitch == ReadUIntBE(securitySymbol.rest, 4) IN IF ~noSwitch.ok THEN Fail ELSE
    LET switch == ReadSwitchList(noSwitch.rest, noSwitch.value) IN IF ~switch.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         securitySymbol   |-> securitySymbol.value,
         switch           |-> switch.value ], switch.rest)

ZeroSecurityRealTimeStatusMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      securitySymbol   |-> [i \in 1 .. 40 |-> 0],
      switch           |-> << >> ]

(* Security Real Time Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityRealTimeStatusMessage ==
    { ZeroSecurityRealTimeStatusMessage }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.securitySymbol = one] : one \in Sample(40) }
        \cup { [ZeroSecurityRealTimeStatusMessage EXCEPT !.switch = one] : one \in SampleLists(OneSwitch) }

(***************************************************************************)
(* Announcement Message                                                    *)
(***************************************************************************)

AnnouncementMessage ==
    [ origTime      : Sample(8),
      channelNo     : Sample(2),
      newsId        : Sample(16),
      headline      : Sample(128),
      newsType      : Sample(1),
      rawDataFormat : Sample(8),
      rawData       : SampleBytes ]

EncodeAnnouncementMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.newsId
        \o message.headline
        \o message.newsType
        \o message.rawDataFormat
        \o EncodeUIntBE(Len(message.rawData), 4)
        \o message.rawData

DecodeAnnouncementMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET newsId == ReadBytes(channelNo.rest, 16) IN IF ~newsId.ok THEN Fail ELSE
    LET headline == ReadBytes(newsId.rest, 128) IN IF ~headline.ok THEN Fail ELSE
    LET newsType == ReadBytes(headline.rest, 1) IN IF ~newsType.ok THEN Fail ELSE
    LET rawDataFormat == ReadBytes(newsType.rest, 8) IN IF ~rawDataFormat.ok THEN Fail ELSE
    LET rawDataLength == ReadUIntBE(rawDataFormat.rest, 4) IN IF ~rawDataLength.ok THEN Fail ELSE
    LET rawData == ReadBytes(rawDataLength.rest, rawDataLength.value) IN IF ~rawData.ok THEN Fail ELSE
    Ok([ origTime      |-> origTime.value,
         channelNo     |-> channelNo.value,
         newsId        |-> newsId.value,
         headline      |-> headline.value,
         newsType      |-> newsType.value,
         rawDataFormat |-> rawDataFormat.value,
         rawData       |-> rawData.value ], rawData.rest)

ZeroAnnouncementMessage ==
    [ origTime      |-> [i \in 1 .. 8 |-> 0],
      channelNo     |-> [i \in 1 .. 2 |-> 0],
      newsId        |-> [i \in 1 .. 16 |-> 0],
      headline      |-> [i \in 1 .. 128 |-> 0],
      newsType      |-> [i \in 1 .. 1 |-> 0],
      rawDataFormat |-> [i \in 1 .. 8 |-> 0],
      rawData       |-> << >> ]

(* Announcement Message at zero, then each field in turn at the values it is checked at *)
CheckedAnnouncementMessage ==
    { ZeroAnnouncementMessage }
        \cup { [ZeroAnnouncementMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.newsId = one] : one \in Sample(16) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.headline = one] : one \in Sample(128) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.newsType = one] : one \in Sample(1) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.rawDataFormat = one] : one \in Sample(8) }
        \cup { [ZeroAnnouncementMessage EXCEPT !.rawData = one] : one \in SampleBytes }

(***************************************************************************)
(* Orders: 8 bytes                                                         *)
(***************************************************************************)

Orders ==
    [ orderQty : Sample(8) ]

EncodeOrders(message) ==
    message.orderQty

DecodeOrders(bytes) ==
    LET orderQty == ReadBytes(bytes, 8) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ orderQty |-> orderQty.value ], orderQty.rest)

ZeroOrders ==
    [ orderQty |-> [i \in 1 .. 8 |-> 0] ]

(* Orders at zero, then each field in turn at the values it is checked at *)
CheckedOrders ==
    { ZeroOrders }
        \cup { [ZeroOrders EXCEPT !.orderQty = one] : one \in Sample(8) }

(* A run of Orders, written one after another *)
RECURSIVE EncodeOrdersList(_)
EncodeOrdersList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrders(Head(messages)) \o EncodeOrdersList(Tail(messages))

(* As many Orders as the field that counts them says *)
RECURSIVE ReadOrdersList(_, _)
ReadOrdersList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrders(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrdersList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Orders of each kind, for the lists that carry them *)
OneOrders == { ZeroOrders }

(***************************************************************************)
(* Md Entries                                                              *)
(***************************************************************************)

MdEntries ==
    [ mdEntryType    : Sample(2),
      mdEntryPx      : Sample(8),
      mdEntrySize    : Sample(8),
      mdPriceLevel   : Sample(2),
      numberOfOrders : Sample(8),
      orders         : SampleLists(OneOrders) ]

EncodeMdEntries(message) ==
    message.mdEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdPriceLevel
        \o message.numberOfOrders
        \o EncodeUIntBE(Len(message.orders), 4)
        \o EncodeOrdersList(message.orders)

DecodeMdEntries(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdPriceLevel == ReadBytes(mdEntrySize.rest, 2) IN IF ~mdPriceLevel.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdPriceLevel.rest, 8) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET noOrders == ReadUIntBE(numberOfOrders.rest, 4) IN IF ~noOrders.ok THEN Fail ELSE
    LET orders == ReadOrdersList(noOrders.rest, noOrders.value) IN IF ~orders.ok THEN Fail ELSE
    Ok([ mdEntryType    |-> mdEntryType.value,
         mdEntryPx      |-> mdEntryPx.value,
         mdEntrySize    |-> mdEntrySize.value,
         mdPriceLevel   |-> mdPriceLevel.value,
         numberOfOrders |-> numberOfOrders.value,
         orders         |-> orders.value ], orders.rest)

ZeroMdEntries ==
    [ mdEntryType    |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize    |-> [i \in 1 .. 8 |-> 0],
      mdPriceLevel   |-> [i \in 1 .. 2 |-> 0],
      numberOfOrders |-> [i \in 1 .. 8 |-> 0],
      orders         |-> << >> ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries ==
    { ZeroMdEntries }
        \cup { [ZeroMdEntries EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroMdEntries EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries EXCEPT !.mdPriceLevel = one] : one \in Sample(2) }
        \cup { [ZeroMdEntries EXCEPT !.numberOfOrders = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries EXCEPT !.orders = one] : one \in SampleLists(OneOrders) }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntriesList(_)
EncodeMdEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries(Head(messages)) \o EncodeMdEntriesList(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntriesList(_, _)
ReadMdEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries == { ZeroMdEntries }

(***************************************************************************)
(* Sub Trading Phase Codes: 9 bytes                                        *)
(***************************************************************************)

SubTradingPhaseCodes ==
    [ subTradingPhaseCode : Sample(8),
      tradingType         : Sample(1) ]

EncodeSubTradingPhaseCodes(message) ==
    message.subTradingPhaseCode
        \o message.tradingType

DecodeSubTradingPhaseCodes(bytes) ==
    LET subTradingPhaseCode == ReadBytes(bytes, 8) IN IF ~subTradingPhaseCode.ok THEN Fail ELSE
    LET tradingType == ReadBytes(subTradingPhaseCode.rest, 1) IN IF ~tradingType.ok THEN Fail ELSE
    Ok([ subTradingPhaseCode |-> subTradingPhaseCode.value,
         tradingType         |-> tradingType.value ], tradingType.rest)

ZeroSubTradingPhaseCodes ==
    [ subTradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      tradingType         |-> [i \in 1 .. 1 |-> 0] ]

(* Sub Trading Phase Codes at zero, then each field in turn at the values it is checked at *)
CheckedSubTradingPhaseCodes ==
    { ZeroSubTradingPhaseCodes }
        \cup { [ZeroSubTradingPhaseCodes EXCEPT !.subTradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSubTradingPhaseCodes EXCEPT !.tradingType = one] : one \in Sample(1) }

(* A run of Sub Trading Phase Codes, written one after another *)
RECURSIVE EncodeSubTradingPhaseCodesList(_)
EncodeSubTradingPhaseCodesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSubTradingPhaseCodes(Head(messages)) \o EncodeSubTradingPhaseCodesList(Tail(messages))

(* As many Sub Trading Phase Codes as the field that counts them says *)
RECURSIVE ReadSubTradingPhaseCodesList(_, _)
ReadSubTradingPhaseCodesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSubTradingPhaseCodes(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSubTradingPhaseCodesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sub Trading Phase Codes of each kind, for the lists that carry them *)
OneSubTradingPhaseCodes == { ZeroSubTradingPhaseCodes }

(***************************************************************************)
(* Bond Spot Trading Snapshot Message                                      *)
(***************************************************************************)

BondSpotTradingSnapshotMessage ==
    [ origTime             : Sample(8),
      channelNo            : Sample(2),
      mdStreamId           : Sample(3),
      securityId           : Sample(8),
      securityIdSource     : Sample(4),
      tradingPhaseCode     : Sample(8),
      preClosePx           : Sample(8),
      numTrades            : Sample(8),
      totalVolumeTrade     : Sample(8),
      totalValueTrade      : Sample(8),
      mdEntries            : SampleLists(OneMdEntries),
      subTradingPhaseCodes : SampleLists(OneSubTradingPhaseCodes),
      auctionVolumeTrade   : Sample(8),
      auctionValueTrade    : Sample(8),
      tradeTime            : Sample(8) ]

EncodeBondSpotTradingSnapshotMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.preClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.mdEntries), 4)
        \o EncodeMdEntriesList(message.mdEntries)
        \o EncodeUIntBE(Len(message.subTradingPhaseCodes), 4)
        \o EncodeSubTradingPhaseCodesList(message.subTradingPhaseCodes)
        \o message.auctionVolumeTrade
        \o message.auctionValueTrade
        \o message.tradeTime

DecodeBondSpotTradingSnapshotMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET preClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~preClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(preClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    LET noSubTradingPhaseCodes == ReadUIntBE(mdEntries.rest, 4) IN IF ~noSubTradingPhaseCodes.ok THEN Fail ELSE
    LET subTradingPhaseCodes == ReadSubTradingPhaseCodesList(noSubTradingPhaseCodes.rest, noSubTradingPhaseCodes.value) IN IF ~subTradingPhaseCodes.ok THEN Fail ELSE
    LET auctionVolumeTrade == ReadBytes(subTradingPhaseCodes.rest, 8) IN IF ~auctionVolumeTrade.ok THEN Fail ELSE
    LET auctionValueTrade == ReadBytes(auctionVolumeTrade.rest, 8) IN IF ~auctionValueTrade.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(auctionValueTrade.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    Ok([ origTime             |-> origTime.value,
         channelNo            |-> channelNo.value,
         mdStreamId           |-> mdStreamId.value,
         securityId           |-> securityId.value,
         securityIdSource     |-> securityIdSource.value,
         tradingPhaseCode     |-> tradingPhaseCode.value,
         preClosePx           |-> preClosePx.value,
         numTrades            |-> numTrades.value,
         totalVolumeTrade     |-> totalVolumeTrade.value,
         totalValueTrade      |-> totalValueTrade.value,
         mdEntries            |-> mdEntries.value,
         subTradingPhaseCodes |-> subTradingPhaseCodes.value,
         auctionVolumeTrade   |-> auctionVolumeTrade.value,
         auctionValueTrade    |-> auctionValueTrade.value,
         tradeTime            |-> tradeTime.value ], tradeTime.rest)

ZeroBondSpotTradingSnapshotMessage ==
    [ origTime             |-> [i \in 1 .. 8 |-> 0],
      channelNo            |-> [i \in 1 .. 2 |-> 0],
      mdStreamId           |-> [i \in 1 .. 3 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      securityIdSource     |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode     |-> [i \in 1 .. 8 |-> 0],
      preClosePx           |-> [i \in 1 .. 8 |-> 0],
      numTrades            |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade     |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade      |-> [i \in 1 .. 8 |-> 0],
      mdEntries            |-> << >>,
      subTradingPhaseCodes |-> << >>,
      auctionVolumeTrade   |-> [i \in 1 .. 8 |-> 0],
      auctionValueTrade    |-> [i \in 1 .. 8 |-> 0],
      tradeTime            |-> [i \in 1 .. 8 |-> 0] ]

(* Bond Spot Trading Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotTradingSnapshotMessage ==
    { ZeroBondSpotTradingSnapshotMessage }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.preClosePx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.subTradingPhaseCodes = one] : one \in SampleLists(OneSubTradingPhaseCodes) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.auctionVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.auctionValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotTradingSnapshotMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Orders: 8 bytes                                                         *)
(***************************************************************************)

Orders2 ==
    [ orderQty : Sample(8) ]

EncodeOrders2(message) ==
    message.orderQty

DecodeOrders2(bytes) ==
    LET orderQty == ReadBytes(bytes, 8) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ orderQty |-> orderQty.value ], orderQty.rest)

ZeroOrders2 ==
    [ orderQty |-> [i \in 1 .. 8 |-> 0] ]

(* Orders at zero, then each field in turn at the values it is checked at *)
CheckedOrders2 ==
    { ZeroOrders2 }
        \cup { [ZeroOrders2 EXCEPT !.orderQty = one] : one \in Sample(8) }

(* A run of Orders, written one after another *)
RECURSIVE EncodeOrders2List(_)
EncodeOrders2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrders2(Head(messages)) \o EncodeOrders2List(Tail(messages))

(* As many Orders as the field that counts them says *)
RECURSIVE ReadOrders2List(_, _)
ReadOrders2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrders2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrders2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Orders of each kind, for the lists that carry them *)
OneOrders2 == { ZeroOrders2 }

(***************************************************************************)
(* Md Entries                                                              *)
(***************************************************************************)

MdEntries2 ==
    [ mdEntryType    : Sample(2),
      mdEntryPx      : Sample(8),
      mdEntrySize    : Sample(8),
      mdPriceLevel   : Sample(2),
      numberOfOrders : Sample(8),
      orders         : SampleLists(OneOrders2) ]

EncodeMdEntries2(message) ==
    message.mdEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdPriceLevel
        \o message.numberOfOrders
        \o EncodeUIntBE(Len(message.orders), 4)
        \o EncodeOrders2List(message.orders)

DecodeMdEntries2(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdPriceLevel == ReadBytes(mdEntrySize.rest, 2) IN IF ~mdPriceLevel.ok THEN Fail ELSE
    LET numberOfOrders == ReadBytes(mdPriceLevel.rest, 8) IN IF ~numberOfOrders.ok THEN Fail ELSE
    LET noOrders == ReadUIntBE(numberOfOrders.rest, 4) IN IF ~noOrders.ok THEN Fail ELSE
    LET orders == ReadOrders2List(noOrders.rest, noOrders.value) IN IF ~orders.ok THEN Fail ELSE
    Ok([ mdEntryType    |-> mdEntryType.value,
         mdEntryPx      |-> mdEntryPx.value,
         mdEntrySize    |-> mdEntrySize.value,
         mdPriceLevel   |-> mdPriceLevel.value,
         numberOfOrders |-> numberOfOrders.value,
         orders         |-> orders.value ], orders.rest)

ZeroMdEntries2 ==
    [ mdEntryType    |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx      |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize    |-> [i \in 1 .. 8 |-> 0],
      mdPriceLevel   |-> [i \in 1 .. 2 |-> 0],
      numberOfOrders |-> [i \in 1 .. 8 |-> 0],
      orders         |-> << >> ]

(* Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedMdEntries2 ==
    { ZeroMdEntries2 }
        \cup { [ZeroMdEntries2 EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroMdEntries2 EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries2 EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries2 EXCEPT !.mdPriceLevel = one] : one \in Sample(2) }
        \cup { [ZeroMdEntries2 EXCEPT !.numberOfOrders = one] : one \in Sample(8) }
        \cup { [ZeroMdEntries2 EXCEPT !.orders = one] : one \in SampleLists(OneOrders2) }

(* A run of Md Entries, written one after another *)
RECURSIVE EncodeMdEntries2List(_)
EncodeMdEntries2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntries2(Head(messages)) \o EncodeMdEntries2List(Tail(messages))

(* As many Md Entries as the field that counts them says *)
RECURSIVE ReadMdEntries2List(_, _)
ReadMdEntries2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntries2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntries2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entries of each kind, for the lists that carry them *)
OneMdEntries2 == { ZeroMdEntries2 }

(***************************************************************************)
(* Auction Trading Snapshot Message                                        *)
(***************************************************************************)

AuctionTradingSnapshotMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      preClosePx       : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      mdEntries        : SampleLists(OneMdEntries2) ]

EncodeAuctionTradingSnapshotMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.preClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.mdEntries), 4)
        \o EncodeMdEntries2List(message.mdEntries)

DecodeAuctionTradingSnapshotMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET preClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~preClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(preClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntries2List(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         preClosePx       |-> preClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         mdEntries        |-> mdEntries.value ], mdEntries.rest)

ZeroAuctionTradingSnapshotMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      preClosePx       |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      mdEntries        |-> << >> ]

(* Auction Trading Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradingSnapshotMessage ==
    { ZeroAuctionTradingSnapshotMessage }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.preClosePx = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradingSnapshotMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries2) }

(***************************************************************************)
(* Index Md Entries: 10 bytes                                              *)
(***************************************************************************)

IndexMdEntries ==
    [ mdEntryType : Sample(2),
      mdEntryPx   : Sample(8) ]

EncodeIndexMdEntries(message) ==
    message.mdEntryType
        \o message.mdEntryPx

DecodeIndexMdEntries(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroIndexMdEntries ==
    [ mdEntryType |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx   |-> [i \in 1 .. 8 |-> 0] ]

(* Index Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedIndexMdEntries ==
    { ZeroIndexMdEntries }
        \cup { [ZeroIndexMdEntries EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroIndexMdEntries EXCEPT !.mdEntryPx = one] : one \in Sample(8) }

(* A run of Index Md Entries, written one after another *)
RECURSIVE EncodeIndexMdEntriesList(_)
EncodeIndexMdEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIndexMdEntries(Head(messages)) \o EncodeIndexMdEntriesList(Tail(messages))

(* As many Index Md Entries as the field that counts them says *)
RECURSIVE ReadIndexMdEntriesList(_, _)
ReadIndexMdEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIndexMdEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIndexMdEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Index Md Entries of each kind, for the lists that carry them *)
OneIndexMdEntries == { ZeroIndexMdEntries }

(***************************************************************************)
(* Index Snapshot Message                                                  *)
(***************************************************************************)

IndexSnapshotMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      preClosePx       : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      indexMdEntries   : SampleLists(OneIndexMdEntries) ]

EncodeIndexSnapshotMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.preClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.indexMdEntries), 4)
        \o EncodeIndexMdEntriesList(message.indexMdEntries)

DecodeIndexSnapshotMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET preClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~preClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(preClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET indexMdEntries == ReadIndexMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~indexMdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         preClosePx       |-> preClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         indexMdEntries   |-> indexMdEntries.value ], indexMdEntries.rest)

ZeroIndexSnapshotMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      preClosePx       |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      indexMdEntries   |-> << >> ]

(* Index Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexSnapshotMessage ==
    { ZeroIndexSnapshotMessage }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.preClosePx = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.indexMdEntries = one] : one \in SampleLists(OneIndexMdEntries) }

(***************************************************************************)
(* Bond Spot Matching Large Order Tick Message: 53 bytes                   *)
(***************************************************************************)

BondSpotMatchingLargeOrderTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transactTime     : Sample(8),
      ordType          : Sample(1),
      settlType        : Sample(1),
      settlPeriod      : Sample(1) ]

EncodeBondSpotMatchingLargeOrderTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transactTime
        \o message.ordType
        \o message.settlType
        \o message.settlPeriod

DecodeBondSpotMatchingLargeOrderTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transactTime == ReadBytes(side.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET ordType == ReadBytes(transactTime.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET settlType == ReadBytes(ordType.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transactTime     |-> transactTime.value,
         ordType          |-> ordType.value,
         settlType        |-> settlType.value,
         settlPeriod      |-> settlPeriod.value ], settlPeriod.rest)

ZeroBondSpotMatchingLargeOrderTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      ordType          |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 1 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Matching Large Order Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotMatchingLargeOrderTickMessage ==
    { ZeroBondSpotMatchingLargeOrderTickMessage }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingLargeOrderTickMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }

(***************************************************************************)
(* Agreement Trading Order Tick Message: 54 bytes                          *)
(***************************************************************************)

AgreementTradingOrderTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transactTime     : Sample(8),
      confirmId        : Sample(4) ]

EncodeAgreementTradingOrderTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transactTime
        \o message.confirmId

DecodeAgreementTradingOrderTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transactTime == ReadBytes(side.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET confirmId == ReadBytes(transactTime.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transactTime     |-> transactTime.value,
         confirmId        |-> confirmId.value ], confirmId.rest)

ZeroAgreementTradingOrderTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      confirmId        |-> [i \in 1 .. 4 |-> 0] ]

(* Agreement Trading Order Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedAgreementTradingOrderTickMessage ==
    { ZeroAgreementTradingOrderTickMessage }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAgreementTradingOrderTickMessage EXCEPT !.confirmId = one] : one \in Sample(4) }

(***************************************************************************)
(* Securities Lending Order Tick Message: 53 bytes                         *)
(***************************************************************************)

SecuritiesLendingOrderTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transactTime     : Sample(8),
      expirationDays   : Sample(2),
      expirationType   : Sample(1) ]

EncodeSecuritiesLendingOrderTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transactTime
        \o message.expirationDays
        \o message.expirationType

DecodeSecuritiesLendingOrderTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transactTime == ReadBytes(side.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(transactTime.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transactTime     |-> transactTime.value,
         expirationDays   |-> expirationDays.value,
         expirationType   |-> expirationType.value ], expirationType.rest)

ZeroSecuritiesLendingOrderTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      expirationDays   |-> [i \in 1 .. 2 |-> 0],
      expirationType   |-> [i \in 1 .. 1 |-> 0] ]

(* Securities Lending Order Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesLendingOrderTickMessage ==
    { ZeroSecuritiesLendingOrderTickMessage }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesLendingOrderTickMessage EXCEPT !.expirationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Spot Matching Large Trade Tick Message: 76 bytes                   *)
(***************************************************************************)

BondSpotMatchingLargeTradeTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      bidApplSeqNum    : Sample(8),
      askApplSeqNum    : Sample(8),
      tradePrice       : Sample(8),
      tradeQty         : Sample(8),
      tradeMoney       : Sample(8),
      execType         : Sample(1),
      transactTime     : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(1) ]

EncodeBondSpotMatchingLargeTradeTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.bidApplSeqNum
        \o message.askApplSeqNum
        \o message.tradePrice
        \o message.tradeQty
        \o message.tradeMoney
        \o message.execType
        \o message.transactTime
        \o message.settlPeriod
        \o message.settlType

DecodeBondSpotMatchingLargeTradeTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(securityIdSource.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET askApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~askApplSeqNum.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(askApplSeqNum.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeQty == ReadBytes(tradePrice.rest, 8) IN IF ~tradeQty.ok THEN Fail ELSE
    LET tradeMoney == ReadBytes(tradeQty.rest, 8) IN IF ~tradeMoney.ok THEN Fail ELSE
    LET execType == ReadBytes(tradeMoney.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execType.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(transactTime.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         askApplSeqNum    |-> askApplSeqNum.value,
         tradePrice       |-> tradePrice.value,
         tradeQty         |-> tradeQty.value,
         tradeMoney       |-> tradeMoney.value,
         execType         |-> execType.value,
         transactTime     |-> transactTime.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value ], settlType.rest)

ZeroBondSpotMatchingLargeTradeTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      askApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      tradePrice       |-> [i \in 1 .. 8 |-> 0],
      tradeQty         |-> [i \in 1 .. 8 |-> 0],
      tradeMoney       |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Matching Large Trade Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotMatchingLargeTradeTickMessage ==
    { ZeroBondSpotMatchingLargeTradeTickMessage }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.askApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.tradeQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.tradeMoney = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingLargeTradeTickMessage EXCEPT !.settlType = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Spot Negotiated Trade Tick Message: 76 bytes                       *)
(***************************************************************************)

BondSpotNegotiatedTradeTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      bidApplSeqNum    : Sample(8),
      askApplSeqNum    : Sample(8),
      tradePrice       : Sample(8),
      tradeQty         : Sample(8),
      tradeMoney       : Sample(8),
      execType         : Sample(1),
      transactTime     : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(1) ]

EncodeBondSpotNegotiatedTradeTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.bidApplSeqNum
        \o message.askApplSeqNum
        \o message.tradePrice
        \o message.tradeQty
        \o message.tradeMoney
        \o message.execType
        \o message.transactTime
        \o message.settlPeriod
        \o message.settlType

DecodeBondSpotNegotiatedTradeTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(securityIdSource.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET askApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~askApplSeqNum.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(askApplSeqNum.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeQty == ReadBytes(tradePrice.rest, 8) IN IF ~tradeQty.ok THEN Fail ELSE
    LET tradeMoney == ReadBytes(tradeQty.rest, 8) IN IF ~tradeMoney.ok THEN Fail ELSE
    LET execType == ReadBytes(tradeMoney.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execType.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(transactTime.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         askApplSeqNum    |-> askApplSeqNum.value,
         tradePrice       |-> tradePrice.value,
         tradeQty         |-> tradeQty.value,
         tradeMoney       |-> tradeMoney.value,
         execType         |-> execType.value,
         transactTime     |-> transactTime.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value ], settlType.rest)

ZeroBondSpotNegotiatedTradeTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      askApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      tradePrice       |-> [i \in 1 .. 8 |-> 0],
      tradeQty         |-> [i \in 1 .. 8 |-> 0],
      tradeMoney       |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Negotiated Trade Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotNegotiatedTradeTickMessage ==
    { ZeroBondSpotNegotiatedTradeTickMessage }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.askApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.tradeQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.tradeMoney = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeTickMessage EXCEPT !.settlType = one] : one \in Sample(1) }

(***************************************************************************)
(* Securities Lending Trade Tick Message: 74 bytes                         *)
(***************************************************************************)

SecuritiesLendingTradeTickMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      bidApplSeqNum    : Sample(8),
      askApplSeqNum    : Sample(8),
      tradePrice       : Sample(8),
      tradeQty         : Sample(8),
      tradeMoney       : Sample(8),
      execType         : Sample(1),
      transactTime     : Sample(8) ]

EncodeSecuritiesLendingTradeTickMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.bidApplSeqNum
        \o message.askApplSeqNum
        \o message.tradePrice
        \o message.tradeQty
        \o message.tradeMoney
        \o message.execType
        \o message.transactTime

DecodeSecuritiesLendingTradeTickMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(securityIdSource.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET askApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~askApplSeqNum.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(askApplSeqNum.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeQty == ReadBytes(tradePrice.rest, 8) IN IF ~tradeQty.ok THEN Fail ELSE
    LET tradeMoney == ReadBytes(tradeQty.rest, 8) IN IF ~tradeMoney.ok THEN Fail ELSE
    LET execType == ReadBytes(tradeMoney.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transactTime == ReadBytes(execType.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         askApplSeqNum    |-> askApplSeqNum.value,
         tradePrice       |-> tradePrice.value,
         tradeQty         |-> tradeQty.value,
         tradeMoney       |-> tradeMoney.value,
         execType         |-> execType.value,
         transactTime     |-> transactTime.value ], transactTime.rest)

ZeroSecuritiesLendingTradeTickMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      askApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      tradePrice       |-> [i \in 1 .. 8 |-> 0],
      tradeQty         |-> [i \in 1 .. 8 |-> 0],
      tradeMoney       |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0] ]

(* Securities Lending Trade Tick Message at zero, then each field in turn at the values it is checked at *)
CheckedSecuritiesLendingTradeTickMessage ==
    { ZeroSecuritiesLendingTradeTickMessage }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.askApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.tradeQty = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.tradeMoney = one] : one \in Sample(8) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroSecuritiesLendingTradeTickMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

LogonMessageCode == 1  \* 0x01
LogoutMessageCode == 2  \* 0x02
HeartbeatMessageCode == 3  \* 0x03
ChannelHeartbeatMessageCode == 301000  \* 0x497c8
RetransmissionMessageCode == 302000  \* 0x49bb0
SnapshotChannelStatisticsMessageCode == 303000  \* 0x49f98
BusinessRejectMessageCode == 8  \* 0x08
SecurityRealTimeStatusMessageCode == 304000  \* 0x4a380
AnnouncementMessageCode == 305000  \* 0x4a768
BondSpotTradingSnapshotMessageCode == 306001  \* 0x4ab51
AuctionTradingSnapshotMessageCode == 306002  \* 0x4ab52
IndexSnapshotMessageCode == 306003  \* 0x4ab53
BondSpotMatchingLargeOrderTickMessageCode == 307011  \* 0x4af43
AgreementTradingOrderTickMessageCode == 307021  \* 0x4af4d
SecuritiesLendingOrderTickMessageCode == 307023  \* 0x4af4f
BondSpotMatchingLargeTradeTickMessageCode == 308011  \* 0x4b32b
BondSpotNegotiatedTradeTickMessageCode == 308012  \* 0x4b32c
SecuritiesLendingTradeTickMessageCode == 308023  \* 0x4b337

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ChannelHeartbeatMessageCode}, body : ChannelHeartbeatMessage ]
        \cup [ tag : {RetransmissionMessageCode}, body : RetransmissionMessage ]
        \cup [ tag : {SnapshotChannelStatisticsMessageCode}, body : SnapshotChannelStatisticsMessage ]
        \cup [ tag : {BusinessRejectMessageCode}, body : BusinessRejectMessage ]
        \cup [ tag : {SecurityRealTimeStatusMessageCode}, body : SecurityRealTimeStatusMessage ]
        \cup [ tag : {AnnouncementMessageCode}, body : AnnouncementMessage ]
        \cup [ tag : {BondSpotTradingSnapshotMessageCode}, body : BondSpotTradingSnapshotMessage ]
        \cup [ tag : {AuctionTradingSnapshotMessageCode}, body : AuctionTradingSnapshotMessage ]
        \cup [ tag : {IndexSnapshotMessageCode}, body : IndexSnapshotMessage ]
        \cup [ tag : {BondSpotMatchingLargeOrderTickMessageCode}, body : BondSpotMatchingLargeOrderTickMessage ]
        \cup [ tag : {AgreementTradingOrderTickMessageCode}, body : AgreementTradingOrderTickMessage ]
        \cup [ tag : {SecuritiesLendingOrderTickMessageCode}, body : SecuritiesLendingOrderTickMessage ]
        \cup [ tag : {BondSpotMatchingLargeTradeTickMessageCode}, body : BondSpotMatchingLargeTradeTickMessage ]
        \cup [ tag : {BondSpotNegotiatedTradeTickMessageCode}, body : BondSpotNegotiatedTradeTickMessage ]
        \cup [ tag : {SecuritiesLendingTradeTickMessageCode}, body : SecuritiesLendingTradeTickMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = ChannelHeartbeatMessageCode -> EncodeChannelHeartbeatMessage(message.body)
      [] message.tag = RetransmissionMessageCode -> EncodeRetransmissionMessage(message.body)
      [] message.tag = SnapshotChannelStatisticsMessageCode -> EncodeSnapshotChannelStatisticsMessage(message.body)
      [] message.tag = BusinessRejectMessageCode -> EncodeBusinessRejectMessage(message.body)
      [] message.tag = SecurityRealTimeStatusMessageCode -> EncodeSecurityRealTimeStatusMessage(message.body)
      [] message.tag = AnnouncementMessageCode -> EncodeAnnouncementMessage(message.body)
      [] message.tag = BondSpotTradingSnapshotMessageCode -> EncodeBondSpotTradingSnapshotMessage(message.body)
      [] message.tag = AuctionTradingSnapshotMessageCode -> EncodeAuctionTradingSnapshotMessage(message.body)
      [] message.tag = IndexSnapshotMessageCode -> EncodeIndexSnapshotMessage(message.body)
      [] message.tag = BondSpotMatchingLargeOrderTickMessageCode -> EncodeBondSpotMatchingLargeOrderTickMessage(message.body)
      [] message.tag = AgreementTradingOrderTickMessageCode -> EncodeAgreementTradingOrderTickMessage(message.body)
      [] message.tag = SecuritiesLendingOrderTickMessageCode -> EncodeSecuritiesLendingOrderTickMessage(message.body)
      [] message.tag = BondSpotMatchingLargeTradeTickMessageCode -> EncodeBondSpotMatchingLargeTradeTickMessage(message.body)
      [] message.tag = BondSpotNegotiatedTradeTickMessageCode -> EncodeBondSpotNegotiatedTradeTickMessage(message.body)
      [] message.tag = SecuritiesLendingTradeTickMessageCode -> EncodeSecuritiesLendingTradeTickMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ChannelHeartbeatMessageCode -> DecodeChannelHeartbeatMessage(bytes)
              [] tag = RetransmissionMessageCode -> DecodeRetransmissionMessage(bytes)
              [] tag = SnapshotChannelStatisticsMessageCode -> DecodeSnapshotChannelStatisticsMessage(bytes)
              [] tag = BusinessRejectMessageCode -> DecodeBusinessRejectMessage(bytes)
              [] tag = SecurityRealTimeStatusMessageCode -> DecodeSecurityRealTimeStatusMessage(bytes)
              [] tag = AnnouncementMessageCode -> DecodeAnnouncementMessage(bytes)
              [] tag = BondSpotTradingSnapshotMessageCode -> DecodeBondSpotTradingSnapshotMessage(bytes)
              [] tag = AuctionTradingSnapshotMessageCode -> DecodeAuctionTradingSnapshotMessage(bytes)
              [] tag = IndexSnapshotMessageCode -> DecodeIndexSnapshotMessage(bytes)
              [] tag = BondSpotMatchingLargeOrderTickMessageCode -> DecodeBondSpotMatchingLargeOrderTickMessage(bytes)
              [] tag = AgreementTradingOrderTickMessageCode -> DecodeAgreementTradingOrderTickMessage(bytes)
              [] tag = SecuritiesLendingOrderTickMessageCode -> DecodeSecuritiesLendingOrderTickMessage(bytes)
              [] tag = BondSpotMatchingLargeTradeTickMessageCode -> DecodeBondSpotMatchingLargeTradeTickMessage(bytes)
              [] tag = BondSpotNegotiatedTradeTickMessageCode -> DecodeBondSpotNegotiatedTradeTickMessage(bytes)
              [] tag = SecuritiesLendingTradeTickMessageCode -> DecodeSecuritiesLendingTradeTickMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ChannelHeartbeatMessageCode, body |-> one] : one \in CheckedChannelHeartbeatMessage }
        \cup { [tag |-> RetransmissionMessageCode, body |-> one] : one \in CheckedRetransmissionMessage }
        \cup { [tag |-> SnapshotChannelStatisticsMessageCode, body |-> one] : one \in CheckedSnapshotChannelStatisticsMessage }
        \cup { [tag |-> BusinessRejectMessageCode, body |-> one] : one \in CheckedBusinessRejectMessage }
        \cup { [tag |-> SecurityRealTimeStatusMessageCode, body |-> one] : one \in CheckedSecurityRealTimeStatusMessage }
        \cup { [tag |-> AnnouncementMessageCode, body |-> one] : one \in CheckedAnnouncementMessage }
        \cup { [tag |-> BondSpotTradingSnapshotMessageCode, body |-> one] : one \in CheckedBondSpotTradingSnapshotMessage }
        \cup { [tag |-> AuctionTradingSnapshotMessageCode, body |-> one] : one \in CheckedAuctionTradingSnapshotMessage }
        \cup { [tag |-> IndexSnapshotMessageCode, body |-> one] : one \in CheckedIndexSnapshotMessage }
        \cup { [tag |-> BondSpotMatchingLargeOrderTickMessageCode, body |-> one] : one \in CheckedBondSpotMatchingLargeOrderTickMessage }
        \cup { [tag |-> AgreementTradingOrderTickMessageCode, body |-> one] : one \in CheckedAgreementTradingOrderTickMessage }
        \cup { [tag |-> SecuritiesLendingOrderTickMessageCode, body |-> one] : one \in CheckedSecuritiesLendingOrderTickMessage }
        \cup { [tag |-> BondSpotMatchingLargeTradeTickMessageCode, body |-> one] : one \in CheckedBondSpotMatchingLargeTradeTickMessage }
        \cup { [tag |-> BondSpotNegotiatedTradeTickMessageCode, body |-> one] : one \in CheckedBondSpotNegotiatedTradeTickMessage }
        \cup { [tag |-> SecuritiesLendingTradeTickMessageCode, body |-> one] : one \in CheckedSecuritiesLendingTradeTickMessage }

(***************************************************************************)
(* Message Tail: 4 bytes                                                   *)
(***************************************************************************)

MessageTail ==
    [ checksum : Sample(4) ]

EncodeMessageTail(message) ==
    message.checksum

DecodeMessageTail(bytes) ==
    LET checksum == ReadBytes(bytes, 4) IN IF ~checksum.ok THEN Fail ELSE
    Ok([ checksum |-> checksum.value ], checksum.rest)

ZeroMessageTail ==
    [ checksum |-> [i \in 1 .. 4 |-> 0] ]

(* Message Tail at zero, then each field in turn at the values it is checked at *)
CheckedMessageTail ==
    { ZeroMessageTail }
        \cup { [ZeroMessageTail EXCEPT !.checksum = one] : one \in Sample(4) }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ bodyLength  : 0 .. 255,
      payload     : Payload,
      messageTail : MessageTail ]

EncodeMessage(message) ==
    EncodeUIntBE(message.payload.tag, 4)
        \o EncodeUIntBE(message.bodyLength, 4)
        \o EncodePayload(message.payload)
        \o EncodeMessageTail(message.messageTail)

DecodeMessage(bytes) ==
    LET msgType == ReadUIntBE(bytes, 4) IN IF ~msgType.ok THEN Fail ELSE
    LET bodyLength == ReadUIntBE(msgType.rest, 4) IN IF ~bodyLength.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, bodyLength.rest) IN IF ~payload.ok THEN Fail ELSE
    LET messageTail == DecodeMessageTail(payload.rest) IN IF ~messageTail.ok THEN Fail ELSE
    Ok([ bodyLength  |-> bodyLength.value,
         payload     |-> payload.value,
         messageTail |-> messageTail.value ], messageTail.rest)

ZeroMessage ==
    [ bodyLength  |-> 0,
      payload     |-> ZeroPayload,
      messageTail |-> ZeroMessageTail ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.bodyLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroMessage EXCEPT !.messageTail = one] : one \in CheckedMessageTail }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Channel Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripChannelHeartbeatMessage ==
    \A message \in CheckedChannelHeartbeatMessage :
        LET read == DecodeChannelHeartbeatMessage(EncodeChannelHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionMessage ==
    \A message \in CheckedRetransmissionMessage :
        LET read == DecodeRetransmissionMessage(EncodeRetransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Stream I Ds decodes back to what was encoded, and leaves nothing over *)
RoundTripMdStreamIDs ==
    \A message \in CheckedMdStreamIDs :
        LET read == DecodeMdStreamIDs(EncodeMdStreamIDs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Channel Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotChannelStatisticsMessage ==
    \A message \in CheckedSnapshotChannelStatisticsMessage :
        LET read == DecodeSnapshotChannelStatisticsMessage(EncodeSnapshotChannelStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessRejectMessage ==
    \A message \in CheckedBusinessRejectMessage :
        LET read == DecodeBusinessRejectMessage(EncodeBusinessRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Switch decodes back to what was encoded, and leaves nothing over *)
RoundTripSwitch ==
    \A message \in CheckedSwitch :
        LET read == DecodeSwitch(EncodeSwitch(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Real Time Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityRealTimeStatusMessage ==
    \A message \in CheckedSecurityRealTimeStatusMessage :
        LET read == DecodeSecurityRealTimeStatusMessage(EncodeSecurityRealTimeStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Announcement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnnouncementMessage ==
    \A message \in CheckedAnnouncementMessage :
        LET read == DecodeAnnouncementMessage(EncodeAnnouncementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders decodes back to what was encoded, and leaves nothing over *)
RoundTripOrders ==
    \A message \in CheckedOrders :
        LET read == DecodeOrders(EncodeOrders(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries ==
    \A message \in CheckedMdEntries :
        LET read == DecodeMdEntries(EncodeMdEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Trading Phase Codes decodes back to what was encoded, and leaves nothing over *)
RoundTripSubTradingPhaseCodes ==
    \A message \in CheckedSubTradingPhaseCodes :
        LET read == DecodeSubTradingPhaseCodes(EncodeSubTradingPhaseCodes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Trading Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotTradingSnapshotMessage ==
    \A message \in CheckedBondSpotTradingSnapshotMessage :
        LET read == DecodeBondSpotTradingSnapshotMessage(EncodeBondSpotTradingSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orders decodes back to what was encoded, and leaves nothing over *)
RoundTripOrders2 ==
    \A message \in CheckedOrders2 :
        LET read == DecodeOrders2(EncodeOrders2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntries2 ==
    \A message \in CheckedMdEntries2 :
        LET read == DecodeMdEntries2(EncodeMdEntries2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trading Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradingSnapshotMessage ==
    \A message \in CheckedAuctionTradingSnapshotMessage :
        LET read == DecodeAuctionTradingSnapshotMessage(EncodeAuctionTradingSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMdEntries ==
    \A message \in CheckedIndexMdEntries :
        LET read == DecodeIndexMdEntries(EncodeIndexMdEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSnapshotMessage ==
    \A message \in CheckedIndexSnapshotMessage :
        LET read == DecodeIndexSnapshotMessage(EncodeIndexSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Matching Large Order Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotMatchingLargeOrderTickMessage ==
    \A message \in CheckedBondSpotMatchingLargeOrderTickMessage :
        LET read == DecodeBondSpotMatchingLargeOrderTickMessage(EncodeBondSpotMatchingLargeOrderTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Agreement Trading Order Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAgreementTradingOrderTickMessage ==
    \A message \in CheckedAgreementTradingOrderTickMessage :
        LET read == DecodeAgreementTradingOrderTickMessage(EncodeAgreementTradingOrderTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Lending Order Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesLendingOrderTickMessage ==
    \A message \in CheckedSecuritiesLendingOrderTickMessage :
        LET read == DecodeSecuritiesLendingOrderTickMessage(EncodeSecuritiesLendingOrderTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Matching Large Trade Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotMatchingLargeTradeTickMessage ==
    \A message \in CheckedBondSpotMatchingLargeTradeTickMessage :
        LET read == DecodeBondSpotMatchingLargeTradeTickMessage(EncodeBondSpotMatchingLargeTradeTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Negotiated Trade Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotNegotiatedTradeTickMessage ==
    \A message \in CheckedBondSpotNegotiatedTradeTickMessage :
        LET read == DecodeBondSpotNegotiatedTradeTickMessage(EncodeBondSpotNegotiatedTradeTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Securities Lending Trade Tick Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecuritiesLendingTradeTickMessage ==
    \A message \in CheckedSecuritiesLendingTradeTickMessage :
        LET read == DecodeSecuritiesLendingTradeTickMessage(EncodeSecuritiesLendingTradeTickMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Tail decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageTail ==
    \A message \in CheckedMessageTail :
        LET read == DecodeMessageTail(EncodeMessageTail(message))
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

(* A Payload is selected by the Msg Type it is written under *)
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
