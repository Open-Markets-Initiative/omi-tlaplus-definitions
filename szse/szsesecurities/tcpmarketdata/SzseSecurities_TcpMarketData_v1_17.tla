---------------- MODULE SzseSecurities_TcpMarketData_v1_17 -----------------
(***************************************************************************)
(* Shenzhen Stock Exchange Szse Tcp Market Data v1.17                      *)
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
(* Channel Heartbeat Message: 12 bytes                                     *)
(***************************************************************************)

ChannelHeartbeatMessage ==
    [ channelNo      : Sample(2),
      applLastSeqNum : Sample(8),
      endOfChannel   : Sample(2) ]

EncodeChannelHeartbeatMessage(message) ==
    message.channelNo
        \o message.applLastSeqNum
        \o message.endOfChannel

DecodeChannelHeartbeatMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applLastSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applLastSeqNum.ok THEN Fail ELSE
    LET endOfChannel == ReadBytes(applLastSeqNum.rest, 2) IN IF ~endOfChannel.ok THEN Fail ELSE
    Ok([ channelNo      |-> channelNo.value,
         applLastSeqNum |-> applLastSeqNum.value,
         endOfChannel   |-> endOfChannel.value ], endOfChannel.rest)

ZeroChannelHeartbeatMessage ==
    [ channelNo      |-> [i \in 1 .. 2 |-> 0],
      applLastSeqNum |-> [i \in 1 .. 8 |-> 0],
      endOfChannel   |-> [i \in 1 .. 2 |-> 0] ]

(* Channel Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedChannelHeartbeatMessage ==
    { ZeroChannelHeartbeatMessage }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.applLastSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroChannelHeartbeatMessage EXCEPT !.endOfChannel = one] : one \in Sample(2) }

(***************************************************************************)
(* Retransmitting Message: 44 bytes                                        *)
(***************************************************************************)

RetransmittingMessage ==
    [ resendType    : Sample(1),
      channelNo     : Sample(2),
      applBegSeqNum : Sample(8),
      applEndSeqNum : Sample(8),
      newsId        : Sample(8),
      resendStatus  : Sample(1),
      rejectText    : Sample(16) ]

EncodeRetransmittingMessage(message) ==
    message.resendType
        \o message.channelNo
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.newsId
        \o message.resendStatus
        \o message.rejectText

DecodeRetransmittingMessage(bytes) ==
    LET resendType == ReadBytes(bytes, 1) IN IF ~resendType.ok THEN Fail ELSE
    LET channelNo == ReadBytes(resendType.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applBegSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET newsId == ReadBytes(applEndSeqNum.rest, 8) IN IF ~newsId.ok THEN Fail ELSE
    LET resendStatus == ReadBytes(newsId.rest, 1) IN IF ~resendStatus.ok THEN Fail ELSE
    LET rejectText == ReadBytes(resendStatus.rest, 16) IN IF ~rejectText.ok THEN Fail ELSE
    Ok([ resendType    |-> resendType.value,
         channelNo     |-> channelNo.value,
         applBegSeqNum |-> applBegSeqNum.value,
         applEndSeqNum |-> applEndSeqNum.value,
         newsId        |-> newsId.value,
         resendStatus  |-> resendStatus.value,
         rejectText    |-> rejectText.value ], rejectText.rest)

ZeroRetransmittingMessage ==
    [ resendType    |-> [i \in 1 .. 1 |-> 0],
      channelNo     |-> [i \in 1 .. 2 |-> 0],
      applBegSeqNum |-> [i \in 1 .. 8 |-> 0],
      applEndSeqNum |-> [i \in 1 .. 8 |-> 0],
      newsId        |-> [i \in 1 .. 8 |-> 0],
      resendStatus  |-> [i \in 1 .. 1 |-> 0],
      rejectText    |-> [i \in 1 .. 16 |-> 0] ]

(* Retransmitting Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmittingMessage ==
    { ZeroRetransmittingMessage }
        \cup { [ZeroRetransmittingMessage EXCEPT !.resendType = one] : one \in Sample(1) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.newsId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.resendStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmittingMessage EXCEPT !.rejectText = one] : one \in Sample(16) }

(***************************************************************************)
(* Client User Information Reporting Message: 26 bytes                     *)
(***************************************************************************)

ClientUserInformationReportingMessage ==
    [ origTime    : Sample(8),
      versionCode : Sample(16),
      userNum     : Sample(2) ]

EncodeClientUserInformationReportingMessage(message) ==
    message.origTime
        \o message.versionCode
        \o message.userNum

DecodeClientUserInformationReportingMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET versionCode == ReadBytes(origTime.rest, 16) IN IF ~versionCode.ok THEN Fail ELSE
    LET userNum == ReadBytes(versionCode.rest, 2) IN IF ~userNum.ok THEN Fail ELSE
    Ok([ origTime    |-> origTime.value,
         versionCode |-> versionCode.value,
         userNum     |-> userNum.value ], userNum.rest)

ZeroClientUserInformationReportingMessage ==
    [ origTime    |-> [i \in 1 .. 8 |-> 0],
      versionCode |-> [i \in 1 .. 16 |-> 0],
      userNum     |-> [i \in 1 .. 2 |-> 0] ]

(* Client User Information Reporting Message at zero, then each field in turn at the values it is checked at *)
CheckedClientUserInformationReportingMessage ==
    { ZeroClientUserInformationReportingMessage }
        \cup { [ZeroClientUserInformationReportingMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroClientUserInformationReportingMessage EXCEPT !.versionCode = one] : one \in Sample(16) }
        \cup { [ZeroClientUserInformationReportingMessage EXCEPT !.userNum = one] : one \in Sample(2) }

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
(* Statistics Of Snapshot Data Channel Message                             *)
(***************************************************************************)

StatisticsOfSnapshotDataChannelMessage ==
    [ origTime    : Sample(8),
      channelNo   : Sample(2),
      mdStreamIDs : SampleLists(OneMdStreamIDs) ]

EncodeStatisticsOfSnapshotDataChannelMessage(message) ==
    message.origTime
        \o message.channelNo
        \o EncodeUIntBE(Len(message.mdStreamIDs), 4)
        \o EncodeMdStreamIDsList(message.mdStreamIDs)

DecodeStatisticsOfSnapshotDataChannelMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET noMdStreamId == ReadUIntBE(channelNo.rest, 4) IN IF ~noMdStreamId.ok THEN Fail ELSE
    LET mdStreamIDs == ReadMdStreamIDsList(noMdStreamId.rest, noMdStreamId.value) IN IF ~mdStreamIDs.ok THEN Fail ELSE
    Ok([ origTime    |-> origTime.value,
         channelNo   |-> channelNo.value,
         mdStreamIDs |-> mdStreamIDs.value ], mdStreamIDs.rest)

ZeroStatisticsOfSnapshotDataChannelMessage ==
    [ origTime    |-> [i \in 1 .. 8 |-> 0],
      channelNo   |-> [i \in 1 .. 2 |-> 0],
      mdStreamIDs |-> << >> ]

(* Statistics Of Snapshot Data Channel Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsOfSnapshotDataChannelMessage ==
    { ZeroStatisticsOfSnapshotDataChannelMessage }
        \cup { [ZeroStatisticsOfSnapshotDataChannelMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsOfSnapshotDataChannelMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroStatisticsOfSnapshotDataChannelMessage EXCEPT !.mdStreamIDs = one] : one \in SampleLists(OneMdStreamIDs) }

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
(* Real Time Market Status Message: 69 bytes                               *)
(***************************************************************************)

RealTimeMarketStatusMessage ==
    [ origTime            : Sample(8),
      channelNo           : Sample(2),
      marketId            : Sample(8),
      marketSegmentId     : Sample(8),
      tradingSessionId    : Sample(4),
      tradingSessionSubId : Sample(4),
      tradSesStatus       : Sample(2),
      tradSesStartTime    : Sample(8),
      tradSesEndTime      : Sample(8),
      thredholdAmount     : Sample(8),
      posAmt              : Sample(8),
      amountsStatus       : Sample(1) ]

EncodeRealTimeMarketStatusMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.marketId
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.tradSesStartTime
        \o message.tradSesEndTime
        \o message.thredholdAmount
        \o message.posAmt
        \o message.amountsStatus

DecodeRealTimeMarketStatusMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET marketId == ReadBytes(channelNo.rest, 8) IN IF ~marketId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(marketId.rest, 8) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 4) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 2) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET tradSesStartTime == ReadBytes(tradSesStatus.rest, 8) IN IF ~tradSesStartTime.ok THEN Fail ELSE
    LET tradSesEndTime == ReadBytes(tradSesStartTime.rest, 8) IN IF ~tradSesEndTime.ok THEN Fail ELSE
    LET thredholdAmount == ReadBytes(tradSesEndTime.rest, 8) IN IF ~thredholdAmount.ok THEN Fail ELSE
    LET posAmt == ReadBytes(thredholdAmount.rest, 8) IN IF ~posAmt.ok THEN Fail ELSE
    LET amountsStatus == ReadBytes(posAmt.rest, 1) IN IF ~amountsStatus.ok THEN Fail ELSE
    Ok([ origTime            |-> origTime.value,
         channelNo           |-> channelNo.value,
         marketId            |-> marketId.value,
         marketSegmentId     |-> marketSegmentId.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradingSessionSubId |-> tradingSessionSubId.value,
         tradSesStatus       |-> tradSesStatus.value,
         tradSesStartTime    |-> tradSesStartTime.value,
         tradSesEndTime      |-> tradSesEndTime.value,
         thredholdAmount     |-> thredholdAmount.value,
         posAmt              |-> posAmt.value,
         amountsStatus       |-> amountsStatus.value ], amountsStatus.rest)

ZeroRealTimeMarketStatusMessage ==
    [ origTime            |-> [i \in 1 .. 8 |-> 0],
      channelNo           |-> [i \in 1 .. 2 |-> 0],
      marketId            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId     |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 4 |-> 0],
      tradingSessionSubId |-> [i \in 1 .. 4 |-> 0],
      tradSesStatus       |-> [i \in 1 .. 2 |-> 0],
      tradSesStartTime    |-> [i \in 1 .. 8 |-> 0],
      tradSesEndTime      |-> [i \in 1 .. 8 |-> 0],
      thredholdAmount     |-> [i \in 1 .. 8 |-> 0],
      posAmt              |-> [i \in 1 .. 8 |-> 0],
      amountsStatus       |-> [i \in 1 .. 1 |-> 0] ]

(* Real Time Market Status Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeMarketStatusMessage ==
    { ZeroRealTimeMarketStatusMessage }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.marketId = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.marketSegmentId = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.tradSesStatus = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.tradSesStartTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.tradSesEndTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.thredholdAmount = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.posAmt = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeMarketStatusMessage EXCEPT !.amountsStatus = one] : one \in Sample(1) }

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
(* Real Time Status Of Security Message                                    *)
(***************************************************************************)

RealTimeStatusOfSecurityMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      financialStatus  : Sample(8),
      switch           : SampleLists(OneSwitch) ]

EncodeRealTimeStatusOfSecurityMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.securityId
        \o message.securityIdSource
        \o message.financialStatus
        \o EncodeUIntBE(Len(message.switch), 4)
        \o EncodeSwitchList(message.switch)

DecodeRealTimeStatusOfSecurityMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET securityId == ReadBytes(channelNo.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET financialStatus == ReadBytes(securityIdSource.rest, 8) IN IF ~financialStatus.ok THEN Fail ELSE
    LET noSwitch == ReadUIntBE(financialStatus.rest, 4) IN IF ~noSwitch.ok THEN Fail ELSE
    LET switch == ReadSwitchList(noSwitch.rest, noSwitch.value) IN IF ~switch.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         financialStatus  |-> financialStatus.value,
         switch           |-> switch.value ], switch.rest)

ZeroRealTimeStatusOfSecurityMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      financialStatus  |-> [i \in 1 .. 8 |-> 0],
      switch           |-> << >> ]

(* Real Time Status Of Security Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeStatusOfSecurityMessage ==
    { ZeroRealTimeStatusOfSecurityMessage }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.financialStatus = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeStatusOfSecurityMessage EXCEPT !.switch = one] : one \in SampleLists(OneSwitch) }

(***************************************************************************)
(* Announcements Message                                                   *)
(***************************************************************************)

AnnouncementsMessage ==
    [ origTime      : Sample(8),
      channelNo     : Sample(2),
      newsId        : Sample(8),
      headline      : Sample(128),
      rawDataFormat : Sample(8),
      rawData       : SampleBytes ]

EncodeAnnouncementsMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.newsId
        \o message.headline
        \o message.rawDataFormat
        \o EncodeUIntBE(Len(message.rawData), 4)
        \o message.rawData

DecodeAnnouncementsMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET newsId == ReadBytes(channelNo.rest, 8) IN IF ~newsId.ok THEN Fail ELSE
    LET headline == ReadBytes(newsId.rest, 128) IN IF ~headline.ok THEN Fail ELSE
    LET rawDataFormat == ReadBytes(headline.rest, 8) IN IF ~rawDataFormat.ok THEN Fail ELSE
    LET rawDataLength == ReadUIntBE(rawDataFormat.rest, 4) IN IF ~rawDataLength.ok THEN Fail ELSE
    LET rawData == ReadBytes(rawDataLength.rest, rawDataLength.value) IN IF ~rawData.ok THEN Fail ELSE
    Ok([ origTime      |-> origTime.value,
         channelNo     |-> channelNo.value,
         newsId        |-> newsId.value,
         headline      |-> headline.value,
         rawDataFormat |-> rawDataFormat.value,
         rawData       |-> rawData.value ], rawData.rest)

ZeroAnnouncementsMessage ==
    [ origTime      |-> [i \in 1 .. 8 |-> 0],
      channelNo     |-> [i \in 1 .. 2 |-> 0],
      newsId        |-> [i \in 1 .. 8 |-> 0],
      headline      |-> [i \in 1 .. 128 |-> 0],
      rawDataFormat |-> [i \in 1 .. 8 |-> 0],
      rawData       |-> << >> ]

(* Announcements Message at zero, then each field in turn at the values it is checked at *)
CheckedAnnouncementsMessage ==
    { ZeroAnnouncementsMessage }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.newsId = one] : one \in Sample(8) }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.headline = one] : one \in Sample(128) }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.rawDataFormat = one] : one \in Sample(8) }
        \cup { [ZeroAnnouncementsMessage EXCEPT !.rawData = one] : one \in SampleBytes }

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
(* Snapshot Data Of Cash Auction Message                                   *)
(***************************************************************************)

SnapshotDataOfCashAuctionMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      prevClosePx      : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      mdEntries        : SampleLists(OneMdEntries) ]

EncodeSnapshotDataOfCashAuctionMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.mdEntries), 4)
        \o EncodeMdEntriesList(message.mdEntries)

DecodeSnapshotDataOfCashAuctionMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         prevClosePx      |-> prevClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         mdEntries        |-> mdEntries.value ], mdEntries.rest)

ZeroSnapshotDataOfCashAuctionMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      mdEntries        |-> << >> ]

(* Snapshot Data Of Cash Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataOfCashAuctionMessage ==
    { ZeroSnapshotDataOfCashAuctionMessage }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfCashAuctionMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries) }

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
(* Snapshot Data Of Spot Bond Trading Message                              *)
(***************************************************************************)

SnapshotDataOfSpotBondTradingMessage ==
    [ origTime             : Sample(8),
      channelNo            : Sample(2),
      mdStreamId           : Sample(3),
      securityId           : Sample(8),
      securityIdSource     : Sample(4),
      tradingPhaseCode     : Sample(8),
      prevClosePx          : Sample(8),
      numTrades            : Sample(8),
      totalVolumeTrade     : Sample(8),
      totalValueTrade      : Sample(8),
      mdEntries            : SampleLists(OneMdEntries2),
      subTradingPhaseCodes : SampleLists(OneSubTradingPhaseCodes),
      auctionVolumeTrade   : Sample(8),
      auctionValueTrade    : Sample(8) ]

EncodeSnapshotDataOfSpotBondTradingMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.mdEntries), 4)
        \o EncodeMdEntries2List(message.mdEntries)
        \o EncodeUIntBE(Len(message.subTradingPhaseCodes), 4)
        \o EncodeSubTradingPhaseCodesList(message.subTradingPhaseCodes)
        \o message.auctionVolumeTrade
        \o message.auctionValueTrade

DecodeSnapshotDataOfSpotBondTradingMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET mdEntries == ReadMdEntries2List(noMdEntries.rest, noMdEntries.value) IN IF ~mdEntries.ok THEN Fail ELSE
    LET noSubTradingPhaseCodes == ReadUIntBE(mdEntries.rest, 4) IN IF ~noSubTradingPhaseCodes.ok THEN Fail ELSE
    LET subTradingPhaseCodes == ReadSubTradingPhaseCodesList(noSubTradingPhaseCodes.rest, noSubTradingPhaseCodes.value) IN IF ~subTradingPhaseCodes.ok THEN Fail ELSE
    LET auctionVolumeTrade == ReadBytes(subTradingPhaseCodes.rest, 8) IN IF ~auctionVolumeTrade.ok THEN Fail ELSE
    LET auctionValueTrade == ReadBytes(auctionVolumeTrade.rest, 8) IN IF ~auctionValueTrade.ok THEN Fail ELSE
    Ok([ origTime             |-> origTime.value,
         channelNo            |-> channelNo.value,
         mdStreamId           |-> mdStreamId.value,
         securityId           |-> securityId.value,
         securityIdSource     |-> securityIdSource.value,
         tradingPhaseCode     |-> tradingPhaseCode.value,
         prevClosePx          |-> prevClosePx.value,
         numTrades            |-> numTrades.value,
         totalVolumeTrade     |-> totalVolumeTrade.value,
         totalValueTrade      |-> totalValueTrade.value,
         mdEntries            |-> mdEntries.value,
         subTradingPhaseCodes |-> subTradingPhaseCodes.value,
         auctionVolumeTrade   |-> auctionVolumeTrade.value,
         auctionValueTrade    |-> auctionValueTrade.value ], auctionValueTrade.rest)

ZeroSnapshotDataOfSpotBondTradingMessage ==
    [ origTime             |-> [i \in 1 .. 8 |-> 0],
      channelNo            |-> [i \in 1 .. 2 |-> 0],
      mdStreamId           |-> [i \in 1 .. 3 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      securityIdSource     |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode     |-> [i \in 1 .. 8 |-> 0],
      prevClosePx          |-> [i \in 1 .. 8 |-> 0],
      numTrades            |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade     |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade      |-> [i \in 1 .. 8 |-> 0],
      mdEntries            |-> << >>,
      subTradingPhaseCodes |-> << >>,
      auctionVolumeTrade   |-> [i \in 1 .. 8 |-> 0],
      auctionValueTrade    |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Data Of Spot Bond Trading Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataOfSpotBondTradingMessage ==
    { ZeroSnapshotDataOfSpotBondTradingMessage }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.mdEntries = one] : one \in SampleLists(OneMdEntries2) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.subTradingPhaseCodes = one] : one \in SampleLists(OneSubTradingPhaseCodes) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.auctionVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfSpotBondTradingMessage EXCEPT !.auctionValueTrade = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Md Entries: 18 bytes                                              *)
(***************************************************************************)

TradeMdEntries ==
    [ mdEntryType : Sample(2),
      mdEntryPx   : Sample(8),
      mdEntrySize : Sample(8) ]

EncodeTradeMdEntries(message) ==
    message.mdEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize

DecodeTradeMdEntries(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value ], mdEntrySize.rest)

ZeroTradeMdEntries ==
    [ mdEntryType |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedTradeMdEntries ==
    { ZeroTradeMdEntries }
        \cup { [ZeroTradeMdEntries EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroTradeMdEntries EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMdEntries EXCEPT !.mdEntrySize = one] : one \in Sample(8) }

(* A run of Trade Md Entries, written one after another *)
RECURSIVE EncodeTradeMdEntriesList(_)
EncodeTradeMdEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeMdEntries(Head(messages)) \o EncodeTradeMdEntriesList(Tail(messages))

(* As many Trade Md Entries as the field that counts them says *)
RECURSIVE ReadTradeMdEntriesList(_, _)
ReadTradeMdEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeMdEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeMdEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Md Entries of each kind, for the lists that carry them *)
OneTradeMdEntries == { ZeroTradeMdEntries }

(***************************************************************************)
(* Snapshot Data Of After Hour Trading Block Trade Message                 *)
(***************************************************************************)

SnapshotDataOfAfterHourTradingBlockTradeMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      prevClosePx      : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      tradeMdEntries   : SampleLists(OneTradeMdEntries) ]

EncodeSnapshotDataOfAfterHourTradingBlockTradeMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.tradeMdEntries), 4)
        \o EncodeTradeMdEntriesList(message.tradeMdEntries)

DecodeSnapshotDataOfAfterHourTradingBlockTradeMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET tradeMdEntries == ReadTradeMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~tradeMdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         prevClosePx      |-> prevClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         tradeMdEntries   |-> tradeMdEntries.value ], tradeMdEntries.rest)

ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      tradeMdEntries   |-> << >> ]

(* Snapshot Data Of After Hour Trading Block Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataOfAfterHourTradingBlockTradeMessage ==
    { ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingBlockTradeMessage EXCEPT !.tradeMdEntries = one] : one \in SampleLists(OneTradeMdEntries) }

(***************************************************************************)
(* Trade Md Entries: 18 bytes                                              *)
(***************************************************************************)

TradeMdEntries2 ==
    [ mdEntryType : Sample(2),
      mdEntryPx   : Sample(8),
      mdEntrySize : Sample(8) ]

EncodeTradeMdEntries2(message) ==
    message.mdEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize

DecodeTradeMdEntries2(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value ], mdEntrySize.rest)

ZeroTradeMdEntries2 ==
    [ mdEntryType |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx   |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedTradeMdEntries2 ==
    { ZeroTradeMdEntries2 }
        \cup { [ZeroTradeMdEntries2 EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroTradeMdEntries2 EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMdEntries2 EXCEPT !.mdEntrySize = one] : one \in Sample(8) }

(* A run of Trade Md Entries, written one after another *)
RECURSIVE EncodeTradeMdEntries2List(_)
EncodeTradeMdEntries2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeMdEntries2(Head(messages)) \o EncodeTradeMdEntries2List(Tail(messages))

(* As many Trade Md Entries as the field that counts them says *)
RECURSIVE ReadTradeMdEntries2List(_, _)
ReadTradeMdEntries2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeMdEntries2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeMdEntries2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Md Entries of each kind, for the lists that carry them *)
OneTradeMdEntries2 == { ZeroTradeMdEntries2 }

(***************************************************************************)
(* Snapshot Data Of After Hour Trading Message                             *)
(***************************************************************************)

SnapshotDataOfAfterHourTradingMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      prevClosePx      : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      tradeMdEntries   : SampleLists(OneTradeMdEntries2) ]

EncodeSnapshotDataOfAfterHourTradingMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.tradeMdEntries), 4)
        \o EncodeTradeMdEntries2List(message.tradeMdEntries)

DecodeSnapshotDataOfAfterHourTradingMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET tradeMdEntries == ReadTradeMdEntries2List(noMdEntries.rest, noMdEntries.value) IN IF ~tradeMdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         prevClosePx      |-> prevClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         tradeMdEntries   |-> tradeMdEntries.value ], tradeMdEntries.rest)

ZeroSnapshotDataOfAfterHourTradingMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      tradeMdEntries   |-> << >> ]

(* Snapshot Data Of After Hour Trading Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataOfAfterHourTradingMessage ==
    { ZeroSnapshotDataOfAfterHourTradingMessage }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfAfterHourTradingMessage EXCEPT !.tradeMdEntries = one] : one \in SampleLists(OneTradeMdEntries2) }

(***************************************************************************)
(* Hk Stocks Md Entries: 20 bytes                                          *)
(***************************************************************************)

HkStocksMdEntries ==
    [ mdEntryType  : Sample(2),
      mdEntryPx    : Sample(8),
      mdEntrySize  : Sample(8),
      mdPriceLevel : Sample(2) ]

EncodeHkStocksMdEntries(message) ==
    message.mdEntryType
        \o message.mdEntryPx
        \o message.mdEntrySize
        \o message.mdPriceLevel

DecodeHkStocksMdEntries(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 8) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdPriceLevel == ReadBytes(mdEntrySize.rest, 2) IN IF ~mdPriceLevel.ok THEN Fail ELSE
    Ok([ mdEntryType  |-> mdEntryType.value,
         mdEntryPx    |-> mdEntryPx.value,
         mdEntrySize  |-> mdEntrySize.value,
         mdPriceLevel |-> mdPriceLevel.value ], mdPriceLevel.rest)

ZeroHkStocksMdEntries ==
    [ mdEntryType  |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx    |-> [i \in 1 .. 8 |-> 0],
      mdEntrySize  |-> [i \in 1 .. 8 |-> 0],
      mdPriceLevel |-> [i \in 1 .. 2 |-> 0] ]

(* Hk Stocks Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedHkStocksMdEntries ==
    { ZeroHkStocksMdEntries }
        \cup { [ZeroHkStocksMdEntries EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroHkStocksMdEntries EXCEPT !.mdEntryPx = one] : one \in Sample(8) }
        \cup { [ZeroHkStocksMdEntries EXCEPT !.mdEntrySize = one] : one \in Sample(8) }
        \cup { [ZeroHkStocksMdEntries EXCEPT !.mdPriceLevel = one] : one \in Sample(2) }

(* A run of Hk Stocks Md Entries, written one after another *)
RECURSIVE EncodeHkStocksMdEntriesList(_)
EncodeHkStocksMdEntriesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeHkStocksMdEntries(Head(messages)) \o EncodeHkStocksMdEntriesList(Tail(messages))

(* As many Hk Stocks Md Entries as the field that counts them says *)
RECURSIVE ReadHkStocksMdEntriesList(_, _)
ReadHkStocksMdEntriesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeHkStocksMdEntries(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadHkStocksMdEntriesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Hk Stocks Md Entries of each kind, for the lists that carry them *)
OneHkStocksMdEntries == { ZeroHkStocksMdEntries }

(***************************************************************************)
(* Complex Event Times: 16 bytes                                           *)
(***************************************************************************)

ComplexEventTimes ==
    [ complexEventStartTime : Sample(8),
      complexEventEndTime   : Sample(8) ]

EncodeComplexEventTimes(message) ==
    message.complexEventStartTime
        \o message.complexEventEndTime

DecodeComplexEventTimes(bytes) ==
    LET complexEventStartTime == ReadBytes(bytes, 8) IN IF ~complexEventStartTime.ok THEN Fail ELSE
    LET complexEventEndTime == ReadBytes(complexEventStartTime.rest, 8) IN IF ~complexEventEndTime.ok THEN Fail ELSE
    Ok([ complexEventStartTime |-> complexEventStartTime.value,
         complexEventEndTime   |-> complexEventEndTime.value ], complexEventEndTime.rest)

ZeroComplexEventTimes ==
    [ complexEventStartTime |-> [i \in 1 .. 8 |-> 0],
      complexEventEndTime   |-> [i \in 1 .. 8 |-> 0] ]

(* Complex Event Times at zero, then each field in turn at the values it is checked at *)
CheckedComplexEventTimes ==
    { ZeroComplexEventTimes }
        \cup { [ZeroComplexEventTimes EXCEPT !.complexEventStartTime = one] : one \in Sample(8) }
        \cup { [ZeroComplexEventTimes EXCEPT !.complexEventEndTime = one] : one \in Sample(8) }

(* A run of Complex Event Times, written one after another *)
RECURSIVE EncodeComplexEventTimesList(_)
EncodeComplexEventTimesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexEventTimes(Head(messages)) \o EncodeComplexEventTimesList(Tail(messages))

(* As many Complex Event Times as the field that counts them says *)
RECURSIVE ReadComplexEventTimesList(_, _)
ReadComplexEventTimesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexEventTimes(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexEventTimesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Event Times of each kind, for the lists that carry them *)
OneComplexEventTimes == { ZeroComplexEventTimes }

(***************************************************************************)
(* Snapshot Data Of Eligible Hk Stocks Message                             *)
(***************************************************************************)

SnapshotDataOfEligibleHkStocksMessage ==
    [ origTime          : Sample(8),
      channelNo         : Sample(2),
      mdStreamId        : Sample(3),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      tradingPhaseCode  : Sample(8),
      prevClosePx       : Sample(8),
      numTrades         : Sample(8),
      totalVolumeTrade  : Sample(8),
      totalValueTrade   : Sample(8),
      hkStocksMdEntries : SampleLists(OneHkStocksMdEntries),
      complexEventTimes : SampleLists(OneComplexEventTimes) ]

EncodeSnapshotDataOfEligibleHkStocksMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.hkStocksMdEntries), 4)
        \o EncodeHkStocksMdEntriesList(message.hkStocksMdEntries)
        \o EncodeUIntBE(Len(message.complexEventTimes), 4)
        \o EncodeComplexEventTimesList(message.complexEventTimes)

DecodeSnapshotDataOfEligibleHkStocksMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET hkStocksMdEntries == ReadHkStocksMdEntriesList(noMdEntries.rest, noMdEntries.value) IN IF ~hkStocksMdEntries.ok THEN Fail ELSE
    LET noComplexEventTimes == ReadUIntBE(hkStocksMdEntries.rest, 4) IN IF ~noComplexEventTimes.ok THEN Fail ELSE
    LET complexEventTimes == ReadComplexEventTimesList(noComplexEventTimes.rest, noComplexEventTimes.value) IN IF ~complexEventTimes.ok THEN Fail ELSE
    Ok([ origTime          |-> origTime.value,
         channelNo         |-> channelNo.value,
         mdStreamId        |-> mdStreamId.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         tradingPhaseCode  |-> tradingPhaseCode.value,
         prevClosePx       |-> prevClosePx.value,
         numTrades         |-> numTrades.value,
         totalVolumeTrade  |-> totalVolumeTrade.value,
         totalValueTrade   |-> totalValueTrade.value,
         hkStocksMdEntries |-> hkStocksMdEntries.value,
         complexEventTimes |-> complexEventTimes.value ], complexEventTimes.rest)

ZeroSnapshotDataOfEligibleHkStocksMessage ==
    [ origTime          |-> [i \in 1 .. 8 |-> 0],
      channelNo         |-> [i \in 1 .. 2 |-> 0],
      mdStreamId        |-> [i \in 1 .. 3 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode  |-> [i \in 1 .. 8 |-> 0],
      prevClosePx       |-> [i \in 1 .. 8 |-> 0],
      numTrades         |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade  |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade   |-> [i \in 1 .. 8 |-> 0],
      hkStocksMdEntries |-> << >>,
      complexEventTimes |-> << >> ]

(* Snapshot Data Of Eligible Hk Stocks Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataOfEligibleHkStocksMessage ==
    { ZeroSnapshotDataOfEligibleHkStocksMessage }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.hkStocksMdEntries = one] : one \in SampleLists(OneHkStocksMdEntries) }
        \cup { [ZeroSnapshotDataOfEligibleHkStocksMessage EXCEPT !.complexEventTimes = one] : one \in SampleLists(OneComplexEventTimes) }

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
      prevClosePx      : Sample(8),
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
        \o message.prevClosePx
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
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
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
         prevClosePx      |-> prevClosePx.value,
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
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroIndexSnapshotMessage EXCEPT !.indexMdEntries = one] : one \in SampleLists(OneIndexMdEntries) }

(***************************************************************************)
(* Statistic Indicator Snapshot Message: 69 bytes                          *)
(***************************************************************************)

StatisticIndicatorSnapshotMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      prevClosePx      : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      stockNum         : Sample(4) ]

EncodeStatisticIndicatorSnapshotMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o message.stockNum

DecodeStatisticIndicatorSnapshotMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET stockNum == ReadBytes(totalValueTrade.rest, 4) IN IF ~stockNum.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         prevClosePx      |-> prevClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         stockNum         |-> stockNum.value ], stockNum.rest)

ZeroStatisticIndicatorSnapshotMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      stockNum         |-> [i \in 1 .. 4 |-> 0] ]

(* Statistic Indicator Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticIndicatorSnapshotMessage ==
    { ZeroStatisticIndicatorSnapshotMessage }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroStatisticIndicatorSnapshotMessage EXCEPT !.stockNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Md Entries: 10 bytes                                              *)
(***************************************************************************)

IndexMdEntries2 ==
    [ mdEntryType : Sample(2),
      mdEntryPx   : Sample(8) ]

EncodeIndexMdEntries2(message) ==
    message.mdEntryType
        \o message.mdEntryPx

DecodeIndexMdEntries2(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 2) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == ReadBytes(mdEntryType.rest, 8) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroIndexMdEntries2 ==
    [ mdEntryType |-> [i \in 1 .. 2 |-> 0],
      mdEntryPx   |-> [i \in 1 .. 8 |-> 0] ]

(* Index Md Entries at zero, then each field in turn at the values it is checked at *)
CheckedIndexMdEntries2 ==
    { ZeroIndexMdEntries2 }
        \cup { [ZeroIndexMdEntries2 EXCEPT !.mdEntryType = one] : one \in Sample(2) }
        \cup { [ZeroIndexMdEntries2 EXCEPT !.mdEntryPx = one] : one \in Sample(8) }

(* A run of Index Md Entries, written one after another *)
RECURSIVE EncodeIndexMdEntries2List(_)
EncodeIndexMdEntries2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIndexMdEntries2(Head(messages)) \o EncodeIndexMdEntries2List(Tail(messages))

(* As many Index Md Entries as the field that counts them says *)
RECURSIVE ReadIndexMdEntries2List(_, _)
ReadIndexMdEntries2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIndexMdEntries2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIndexMdEntries2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Index Md Entries of each kind, for the lists that carry them *)
OneIndexMdEntries2 == { ZeroIndexMdEntries2 }

(***************************************************************************)
(* Real Time Reference Net Value Of Funds Snapshot Message                 *)
(***************************************************************************)

RealTimeReferenceNetValueOfFundsSnapshotMessage ==
    [ origTime         : Sample(8),
      channelNo        : Sample(2),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      tradingPhaseCode : Sample(8),
      prevClosePx      : Sample(8),
      numTrades        : Sample(8),
      totalVolumeTrade : Sample(8),
      totalValueTrade  : Sample(8),
      indexMdEntries   : SampleLists(OneIndexMdEntries2) ]

EncodeRealTimeReferenceNetValueOfFundsSnapshotMessage(message) ==
    message.origTime
        \o message.channelNo
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.tradingPhaseCode
        \o message.prevClosePx
        \o message.numTrades
        \o message.totalVolumeTrade
        \o message.totalValueTrade
        \o EncodeUIntBE(Len(message.indexMdEntries), 4)
        \o EncodeIndexMdEntries2List(message.indexMdEntries)

DecodeRealTimeReferenceNetValueOfFundsSnapshotMessage(bytes) ==
    LET origTime == ReadBytes(bytes, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET channelNo == ReadBytes(origTime.rest, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(channelNo.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(securityIdSource.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    LET prevClosePx == ReadBytes(tradingPhaseCode.rest, 8) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET numTrades == ReadBytes(prevClosePx.rest, 8) IN IF ~numTrades.ok THEN Fail ELSE
    LET totalVolumeTrade == ReadBytes(numTrades.rest, 8) IN IF ~totalVolumeTrade.ok THEN Fail ELSE
    LET totalValueTrade == ReadBytes(totalVolumeTrade.rest, 8) IN IF ~totalValueTrade.ok THEN Fail ELSE
    LET noMdEntries == ReadUIntBE(totalValueTrade.rest, 4) IN IF ~noMdEntries.ok THEN Fail ELSE
    LET indexMdEntries == ReadIndexMdEntries2List(noMdEntries.rest, noMdEntries.value) IN IF ~indexMdEntries.ok THEN Fail ELSE
    Ok([ origTime         |-> origTime.value,
         channelNo        |-> channelNo.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         tradingPhaseCode |-> tradingPhaseCode.value,
         prevClosePx      |-> prevClosePx.value,
         numTrades        |-> numTrades.value,
         totalVolumeTrade |-> totalVolumeTrade.value,
         totalValueTrade  |-> totalValueTrade.value,
         indexMdEntries   |-> indexMdEntries.value ], indexMdEntries.rest)

ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage ==
    [ origTime         |-> [i \in 1 .. 8 |-> 0],
      channelNo        |-> [i \in 1 .. 2 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseCode |-> [i \in 1 .. 8 |-> 0],
      prevClosePx      |-> [i \in 1 .. 8 |-> 0],
      numTrades        |-> [i \in 1 .. 8 |-> 0],
      totalVolumeTrade |-> [i \in 1 .. 8 |-> 0],
      totalValueTrade  |-> [i \in 1 .. 8 |-> 0],
      indexMdEntries   |-> << >> ]

(* Real Time Reference Net Value Of Funds Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeReferenceNetValueOfFundsSnapshotMessage ==
    { ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.prevClosePx = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.numTrades = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.totalVolumeTrade = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.totalValueTrade = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeReferenceNetValueOfFundsSnapshotMessage EXCEPT !.indexMdEntries = one] : one \in SampleLists(OneIndexMdEntries2) }

(***************************************************************************)
(* Order Tick Data In Call Auction Message: 51 bytes                       *)
(***************************************************************************)

OrderTickDataInCallAuctionMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      ordType          : Sample(1) ]

EncodeOrderTickDataInCallAuctionMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.ordType

DecodeOrderTickDataInCallAuctionMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET ordType == ReadBytes(transacTime.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         ordType          |-> ordType.value ], ordType.rest)

ZeroOrderTickDataInCallAuctionMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      ordType          |-> [i \in 1 .. 1 |-> 0] ]

(* Order Tick Data In Call Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataInCallAuctionMessage ==
    { ZeroOrderTickDataInCallAuctionMessage }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataInCallAuctionMessage EXCEPT !.ordType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Tick Data Of Negotiable Trade Message: 100 bytes                  *)
(***************************************************************************)

OrderTickDataOfNegotiableTradeMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      confirmId        : Sample(8),
      contactor        : Sample(12),
      contactInfo      : Sample(30) ]

EncodeOrderTickDataOfNegotiableTradeMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.confirmId
        \o message.contactor
        \o message.contactInfo

DecodeOrderTickDataOfNegotiableTradeMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET confirmId == ReadBytes(transacTime.rest, 8) IN IF ~confirmId.ok THEN Fail ELSE
    LET contactor == ReadBytes(confirmId.rest, 12) IN IF ~contactor.ok THEN Fail ELSE
    LET contactInfo == ReadBytes(contactor.rest, 30) IN IF ~contactInfo.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         confirmId        |-> confirmId.value,
         contactor        |-> contactor.value,
         contactInfo      |-> contactInfo.value ], contactInfo.rest)

ZeroOrderTickDataOfNegotiableTradeMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      confirmId        |-> [i \in 1 .. 8 |-> 0],
      contactor        |-> [i \in 1 .. 12 |-> 0],
      contactInfo      |-> [i \in 1 .. 30 |-> 0] ]

(* Order Tick Data Of Negotiable Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataOfNegotiableTradeMessage ==
    { ZeroOrderTickDataOfNegotiableTradeMessage }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.confirmId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.contactor = one] : one \in Sample(12) }
        \cup { [ZeroOrderTickDataOfNegotiableTradeMessage EXCEPT !.contactInfo = one] : one \in Sample(30) }

(***************************************************************************)
(* Order Tick Data Of Security Lending Message: 53 bytes                   *)
(***************************************************************************)

OrderTickDataOfSecurityLendingMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      expirationDays   : Sample(2),
      expirationType   : Sample(1) ]

EncodeOrderTickDataOfSecurityLendingMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.expirationDays
        \o message.expirationType

DecodeOrderTickDataOfSecurityLendingMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(transacTime.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         expirationDays   |-> expirationDays.value,
         expirationType   |-> expirationType.value ], expirationType.rest)

ZeroOrderTickDataOfSecurityLendingMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      expirationDays   |-> [i \in 1 .. 2 |-> 0],
      expirationType   |-> [i \in 1 .. 1 |-> 0] ]

(* Order Tick Data Of Security Lending Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataOfSecurityLendingMessage ==
    { ZeroOrderTickDataOfSecurityLendingMessage }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSecurityLendingMessage EXCEPT !.expirationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Tick Data Of Spot Bond Trading Matching Deal Message: 51 bytes    *)
(***************************************************************************)

OrderTickDataOfSpotBondTradingMatchingDealMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      ordType          : Sample(1) ]

EncodeOrderTickDataOfSpotBondTradingMatchingDealMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.ordType

DecodeOrderTickDataOfSpotBondTradingMatchingDealMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET ordType == ReadBytes(transacTime.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         ordType          |-> ordType.value ], ordType.rest)

ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      ordType          |-> [i \in 1 .. 1 |-> 0] ]

(* Order Tick Data Of Spot Bond Trading Matching Deal Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataOfSpotBondTradingMatchingDealMessage ==
    { ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingMatchingDealMessage EXCEPT !.ordType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Tick Data Of Spot Bond Trading Quotation Message: 377 bytes       *)
(***************************************************************************)

OrderTickDataOfSpotBondTradingQuotationMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      quoteId          : Sample(10),
      memberId         : Sample(6),
      investorType     : Sample(2),
      investorId       : Sample(10),
      investorName     : Sample(120),
      traderCode       : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(2),
      memo             : Sample(160),
      minQty           : Sample(8) ]

EncodeOrderTickDataOfSpotBondTradingQuotationMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.quoteId
        \o message.memberId
        \o message.investorType
        \o message.investorId
        \o message.investorName
        \o message.traderCode
        \o message.settlPeriod
        \o message.settlType
        \o message.memo
        \o message.minQty

DecodeOrderTickDataOfSpotBondTradingQuotationMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET quoteId == ReadBytes(transacTime.rest, 10) IN IF ~quoteId.ok THEN Fail ELSE
    LET memberId == ReadBytes(quoteId.rest, 6) IN IF ~memberId.ok THEN Fail ELSE
    LET investorType == ReadBytes(memberId.rest, 2) IN IF ~investorType.ok THEN Fail ELSE
    LET investorId == ReadBytes(investorType.rest, 10) IN IF ~investorId.ok THEN Fail ELSE
    LET investorName == ReadBytes(investorId.rest, 120) IN IF ~investorName.ok THEN Fail ELSE
    LET traderCode == ReadBytes(investorName.rest, 8) IN IF ~traderCode.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(traderCode.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 2) IN IF ~settlType.ok THEN Fail ELSE
    LET memo == ReadBytes(settlType.rest, 160) IN IF ~memo.ok THEN Fail ELSE
    LET minQty == ReadBytes(memo.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         quoteId          |-> quoteId.value,
         memberId         |-> memberId.value,
         investorType     |-> investorType.value,
         investorId       |-> investorId.value,
         investorName     |-> investorName.value,
         traderCode       |-> traderCode.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value,
         memo             |-> memo.value,
         minQty           |-> minQty.value ], minQty.rest)

ZeroOrderTickDataOfSpotBondTradingQuotationMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      quoteId          |-> [i \in 1 .. 10 |-> 0],
      memberId         |-> [i \in 1 .. 6 |-> 0],
      investorType     |-> [i \in 1 .. 2 |-> 0],
      investorId       |-> [i \in 1 .. 10 |-> 0],
      investorName     |-> [i \in 1 .. 120 |-> 0],
      traderCode       |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 2 |-> 0],
      memo             |-> [i \in 1 .. 160 |-> 0],
      minQty           |-> [i \in 1 .. 8 |-> 0] ]

(* Order Tick Data Of Spot Bond Trading Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataOfSpotBondTradingQuotationMessage ==
    { ZeroOrderTickDataOfSpotBondTradingQuotationMessage }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.quoteId = one] : one \in Sample(10) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.memberId = one] : one \in Sample(6) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.investorType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.investorId = one] : one \in Sample(10) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.investorName = one] : one \in Sample(120) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.traderCode = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.settlType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.memo = one] : one \in Sample(160) }
        \cup { [ZeroOrderTickDataOfSpotBondTradingQuotationMessage EXCEPT !.minQty = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Tick Data Of Bid Quotation Message: 407 bytes                     *)
(***************************************************************************)

OrderTickDataOfBidQuotationMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      price            : Sample(8),
      orderQty         : Sample(8),
      side             : Sample(1),
      transacTime      : Sample(8),
      memberId         : Sample(6),
      investorType     : Sample(2),
      investorId       : Sample(10),
      investorName     : Sample(120),
      traderCode       : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(2),
      memo             : Sample(160),
      secondaryOrderId : Sample(16),
      bidTransType     : Sample(2),
      bidExecInstType  : Sample(2),
      lowLimitPrice    : Sample(8),
      highLimitPrice   : Sample(8),
      minQty           : Sample(8),
      tradeDate        : Sample(4) ]

EncodeOrderTickDataOfBidQuotationMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.securityId
        \o message.securityIdSource
        \o message.price
        \o message.orderQty
        \o message.side
        \o message.transacTime
        \o message.memberId
        \o message.investorType
        \o message.investorId
        \o message.investorName
        \o message.traderCode
        \o message.settlPeriod
        \o message.settlType
        \o message.memo
        \o message.secondaryOrderId
        \o message.bidTransType
        \o message.bidExecInstType
        \o message.lowLimitPrice
        \o message.highLimitPrice
        \o message.minQty
        \o message.tradeDate

DecodeOrderTickDataOfBidQuotationMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET securityId == ReadBytes(mdStreamId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET price == ReadBytes(securityIdSource.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET transacTime == ReadBytes(side.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET memberId == ReadBytes(transacTime.rest, 6) IN IF ~memberId.ok THEN Fail ELSE
    LET investorType == ReadBytes(memberId.rest, 2) IN IF ~investorType.ok THEN Fail ELSE
    LET investorId == ReadBytes(investorType.rest, 10) IN IF ~investorId.ok THEN Fail ELSE
    LET investorName == ReadBytes(investorId.rest, 120) IN IF ~investorName.ok THEN Fail ELSE
    LET traderCode == ReadBytes(investorName.rest, 8) IN IF ~traderCode.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(traderCode.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 2) IN IF ~settlType.ok THEN Fail ELSE
    LET memo == ReadBytes(settlType.rest, 160) IN IF ~memo.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(memo.rest, 16) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET bidTransType == ReadBytes(secondaryOrderId.rest, 2) IN IF ~bidTransType.ok THEN Fail ELSE
    LET bidExecInstType == ReadBytes(bidTransType.rest, 2) IN IF ~bidExecInstType.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(bidExecInstType.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(lowLimitPrice.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET minQty == ReadBytes(highLimitPrice.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(minQty.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         price            |-> price.value,
         orderQty         |-> orderQty.value,
         side             |-> side.value,
         transacTime      |-> transacTime.value,
         memberId         |-> memberId.value,
         investorType     |-> investorType.value,
         investorId       |-> investorId.value,
         investorName     |-> investorName.value,
         traderCode       |-> traderCode.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value,
         memo             |-> memo.value,
         secondaryOrderId |-> secondaryOrderId.value,
         bidTransType     |-> bidTransType.value,
         bidExecInstType  |-> bidExecInstType.value,
         lowLimitPrice    |-> lowLimitPrice.value,
         highLimitPrice   |-> highLimitPrice.value,
         minQty           |-> minQty.value,
         tradeDate        |-> tradeDate.value ], tradeDate.rest)

ZeroOrderTickDataOfBidQuotationMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      memberId         |-> [i \in 1 .. 6 |-> 0],
      investorType     |-> [i \in 1 .. 2 |-> 0],
      investorId       |-> [i \in 1 .. 10 |-> 0],
      investorName     |-> [i \in 1 .. 120 |-> 0],
      traderCode       |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 2 |-> 0],
      memo             |-> [i \in 1 .. 160 |-> 0],
      secondaryOrderId |-> [i \in 1 .. 16 |-> 0],
      bidTransType     |-> [i \in 1 .. 2 |-> 0],
      bidExecInstType  |-> [i \in 1 .. 2 |-> 0],
      lowLimitPrice    |-> [i \in 1 .. 8 |-> 0],
      highLimitPrice   |-> [i \in 1 .. 8 |-> 0],
      minQty           |-> [i \in 1 .. 8 |-> 0],
      tradeDate        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Tick Data Of Bid Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderTickDataOfBidQuotationMessage ==
    { ZeroOrderTickDataOfBidQuotationMessage }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.memberId = one] : one \in Sample(6) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.investorType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.investorId = one] : one \in Sample(10) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.investorName = one] : one \in Sample(120) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.traderCode = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.settlType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.memo = one] : one \in Sample(160) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(16) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.bidTransType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.bidExecInstType = one] : one \in Sample(2) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderTickDataOfBidQuotationMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Transaction Tick Data In Call Auction Message: 66 bytes                 *)
(***************************************************************************)

TransactionTickDataInCallAuctionMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8) ]

EncodeTransactionTickDataInCallAuctionMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime

DecodeTransactionTickDataInCallAuctionMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value ], transacTime.rest)

ZeroTransactionTickDataInCallAuctionMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Transaction Tick Data In Call Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataInCallAuctionMessage ==
    { ZeroTransactionTickDataInCallAuctionMessage }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataInCallAuctionMessage EXCEPT !.transacTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Transaction Tick Data Of Negotiable Trade Message: 66 bytes             *)
(***************************************************************************)

TransactionTickDataOfNegotiableTradeMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8) ]

EncodeTransactionTickDataOfNegotiableTradeMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime

DecodeTransactionTickDataOfNegotiableTradeMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value ], transacTime.rest)

ZeroTransactionTickDataOfNegotiableTradeMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Transaction Tick Data Of Negotiable Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataOfNegotiableTradeMessage ==
    { ZeroTransactionTickDataOfNegotiableTradeMessage }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfNegotiableTradeMessage EXCEPT !.transacTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Transaction Tick Data Of Security Lending Message: 66 bytes             *)
(***************************************************************************)

TransactionTickDataOfSecurityLendingMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8) ]

EncodeTransactionTickDataOfSecurityLendingMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime

DecodeTransactionTickDataOfSecurityLendingMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value ], transacTime.rest)

ZeroTransactionTickDataOfSecurityLendingMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Transaction Tick Data Of Security Lending Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataOfSecurityLendingMessage ==
    { ZeroTransactionTickDataOfSecurityLendingMessage }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfSecurityLendingMessage EXCEPT !.transacTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Transaction Tick Data Of Bond General Pledged Repo Message: 66 bytes    *)
(***************************************************************************)

TransactionTickDataOfBondGeneralPledgedRepoMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8) ]

EncodeTransactionTickDataOfBondGeneralPledgedRepoMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime

DecodeTransactionTickDataOfBondGeneralPledgedRepoMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value ], transacTime.rest)

ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Transaction Tick Data Of Bond General Pledged Repo Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataOfBondGeneralPledgedRepoMessage ==
    { ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfBondGeneralPledgedRepoMessage EXCEPT !.transacTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Transaction Tick Data Of Spot Bond Trading Quotation Message: 69 bytes  *)
(***************************************************************************)

TransactionTickDataOfSpotBondTradingQuotationMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(2) ]

EncodeTransactionTickDataOfSpotBondTradingQuotationMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime
        \o message.settlPeriod
        \o message.settlType

DecodeTransactionTickDataOfSpotBondTradingQuotationMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(transacTime.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 2) IN IF ~settlType.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value ], settlType.rest)

ZeroTransactionTickDataOfSpotBondTradingQuotationMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 2 |-> 0] ]

(* Transaction Tick Data Of Spot Bond Trading Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataOfSpotBondTradingQuotationMessage ==
    { ZeroTransactionTickDataOfSpotBondTradingQuotationMessage }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfSpotBondTradingQuotationMessage EXCEPT !.settlType = one] : one \in Sample(2) }

(***************************************************************************)
(* Transaction Tick Data Of Bid Quotation Message: 95 bytes                *)
(***************************************************************************)

TransactionTickDataOfBidQuotationMessage ==
    [ channelNo        : Sample(2),
      applSeqNum       : Sample(8),
      mdStreamId       : Sample(3),
      bidApplSeqNum    : Sample(8),
      offerApplSeqNum  : Sample(8),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      execType         : Sample(1),
      transacTime      : Sample(8),
      settlPeriod      : Sample(1),
      settlType        : Sample(2),
      secondaryOrderId : Sample(16),
      bidExecInstType  : Sample(2),
      marginPrice      : Sample(8) ]

EncodeTransactionTickDataOfBidQuotationMessage(message) ==
    message.channelNo
        \o message.applSeqNum
        \o message.mdStreamId
        \o message.bidApplSeqNum
        \o message.offerApplSeqNum
        \o message.securityId
        \o message.securityIdSource
        \o message.lastPx
        \o message.lastQty
        \o message.execType
        \o message.transacTime
        \o message.settlPeriod
        \o message.settlType
        \o message.secondaryOrderId
        \o message.bidExecInstType
        \o message.marginPrice

DecodeTransactionTickDataOfBidQuotationMessage(bytes) ==
    LET channelNo == ReadBytes(bytes, 2) IN IF ~channelNo.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(channelNo.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET mdStreamId == ReadBytes(applSeqNum.rest, 3) IN IF ~mdStreamId.ok THEN Fail ELSE
    LET bidApplSeqNum == ReadBytes(mdStreamId.rest, 8) IN IF ~bidApplSeqNum.ok THEN Fail ELSE
    LET offerApplSeqNum == ReadBytes(bidApplSeqNum.rest, 8) IN IF ~offerApplSeqNum.ok THEN Fail ELSE
    LET securityId == ReadBytes(offerApplSeqNum.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityIdSource.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET execType == ReadBytes(lastQty.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET transacTime == ReadBytes(execType.rest, 8) IN IF ~transacTime.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(transacTime.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET settlType == ReadBytes(settlPeriod.rest, 2) IN IF ~settlType.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(settlType.rest, 16) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET bidExecInstType == ReadBytes(secondaryOrderId.rest, 2) IN IF ~bidExecInstType.ok THEN Fail ELSE
    LET marginPrice == ReadBytes(bidExecInstType.rest, 8) IN IF ~marginPrice.ok THEN Fail ELSE
    Ok([ channelNo        |-> channelNo.value,
         applSeqNum       |-> applSeqNum.value,
         mdStreamId       |-> mdStreamId.value,
         bidApplSeqNum    |-> bidApplSeqNum.value,
         offerApplSeqNum  |-> offerApplSeqNum.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         execType         |-> execType.value,
         transacTime      |-> transacTime.value,
         settlPeriod      |-> settlPeriod.value,
         settlType        |-> settlType.value,
         secondaryOrderId |-> secondaryOrderId.value,
         bidExecInstType  |-> bidExecInstType.value,
         marginPrice      |-> marginPrice.value ], marginPrice.rest)

ZeroTransactionTickDataOfBidQuotationMessage ==
    [ channelNo        |-> [i \in 1 .. 2 |-> 0],
      applSeqNum       |-> [i \in 1 .. 8 |-> 0],
      mdStreamId       |-> [i \in 1 .. 3 |-> 0],
      bidApplSeqNum    |-> [i \in 1 .. 8 |-> 0],
      offerApplSeqNum  |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      transacTime      |-> [i \in 1 .. 8 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 2 |-> 0],
      secondaryOrderId |-> [i \in 1 .. 16 |-> 0],
      bidExecInstType  |-> [i \in 1 .. 2 |-> 0],
      marginPrice      |-> [i \in 1 .. 8 |-> 0] ]

(* Transaction Tick Data Of Bid Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedTransactionTickDataOfBidQuotationMessage ==
    { ZeroTransactionTickDataOfBidQuotationMessage }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.channelNo = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.mdStreamId = one] : one \in Sample(3) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.bidApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.offerApplSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.transacTime = one] : one \in Sample(8) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.settlType = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(16) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.bidExecInstType = one] : one \in Sample(2) }
        \cup { [ZeroTransactionTickDataOfBidQuotationMessage EXCEPT !.marginPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

LogonMessageCode == 1  \* 0x01
LogoutMessageCode == 2  \* 0x02
HeartbeatMessageCode == 3  \* 0x03
ChannelHeartbeatMessageCode == 390095  \* 0x5f3cf
RetransmittingMessageCode == 390094  \* 0x5f3ce
ClientUserInformationReportingMessageCode == 390093  \* 0x5f3cd
StatisticsOfSnapshotDataChannelMessageCode == 390090  \* 0x5f3ca
BusinessRejectMessageCode == 8  \* 0x08
RealTimeMarketStatusMessageCode == 390019  \* 0x5f383
RealTimeStatusOfSecurityMessageCode == 390013  \* 0x5f37d
AnnouncementsMessageCode == 390012  \* 0x5f37c
SnapshotDataOfCashAuctionMessageCode == 300111  \* 0x4944f
SnapshotDataOfSpotBondTradingMessageCode == 300211  \* 0x494b3
SnapshotDataOfAfterHourTradingBlockTradeMessageCode == 300611  \* 0x49643
SnapshotDataOfAfterHourTradingMessageCode == 303711  \* 0x4a25f
SnapshotDataOfEligibleHkStocksMessageCode == 306311  \* 0x4ac87
IndexSnapshotMessageCode == 309011  \* 0x4b713
StatisticIndicatorSnapshotMessageCode == 309111  \* 0x4b777
RealTimeReferenceNetValueOfFundsSnapshotMessageCode == 309211  \* 0x4b7db
OrderTickDataInCallAuctionMessageCode == 300192  \* 0x494a0
OrderTickDataOfNegotiableTradeMessageCode == 300592  \* 0x49630
OrderTickDataOfSecurityLendingMessageCode == 300792  \* 0x496f8
OrderTickDataOfSpotBondTradingMatchingDealMessageCode == 300292  \* 0x49504
OrderTickDataOfSpotBondTradingQuotationMessageCode == 300392  \* 0x49568
OrderTickDataOfBidQuotationMessageCode == 300492  \* 0x495cc
TransactionTickDataInCallAuctionMessageCode == 300191  \* 0x4949f
TransactionTickDataOfNegotiableTradeMessageCode == 300591  \* 0x4962f
TransactionTickDataOfSecurityLendingMessageCode == 300791  \* 0x496f7
TransactionTickDataOfBondGeneralPledgedRepoMessageCode == 300291  \* 0x49503
TransactionTickDataOfSpotBondTradingQuotationMessageCode == 300391  \* 0x49567
TransactionTickDataOfBidQuotationMessageCode == 300491  \* 0x495cb

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ChannelHeartbeatMessageCode}, body : ChannelHeartbeatMessage ]
        \cup [ tag : {RetransmittingMessageCode}, body : RetransmittingMessage ]
        \cup [ tag : {ClientUserInformationReportingMessageCode}, body : ClientUserInformationReportingMessage ]
        \cup [ tag : {StatisticsOfSnapshotDataChannelMessageCode}, body : StatisticsOfSnapshotDataChannelMessage ]
        \cup [ tag : {BusinessRejectMessageCode}, body : BusinessRejectMessage ]
        \cup [ tag : {RealTimeMarketStatusMessageCode}, body : RealTimeMarketStatusMessage ]
        \cup [ tag : {RealTimeStatusOfSecurityMessageCode}, body : RealTimeStatusOfSecurityMessage ]
        \cup [ tag : {AnnouncementsMessageCode}, body : AnnouncementsMessage ]
        \cup [ tag : {SnapshotDataOfCashAuctionMessageCode}, body : SnapshotDataOfCashAuctionMessage ]
        \cup [ tag : {SnapshotDataOfSpotBondTradingMessageCode}, body : SnapshotDataOfSpotBondTradingMessage ]
        \cup [ tag : {SnapshotDataOfAfterHourTradingBlockTradeMessageCode}, body : SnapshotDataOfAfterHourTradingBlockTradeMessage ]
        \cup [ tag : {SnapshotDataOfAfterHourTradingMessageCode}, body : SnapshotDataOfAfterHourTradingMessage ]
        \cup [ tag : {SnapshotDataOfEligibleHkStocksMessageCode}, body : SnapshotDataOfEligibleHkStocksMessage ]
        \cup [ tag : {IndexSnapshotMessageCode}, body : IndexSnapshotMessage ]
        \cup [ tag : {StatisticIndicatorSnapshotMessageCode}, body : StatisticIndicatorSnapshotMessage ]
        \cup [ tag : {RealTimeReferenceNetValueOfFundsSnapshotMessageCode}, body : RealTimeReferenceNetValueOfFundsSnapshotMessage ]
        \cup [ tag : {OrderTickDataInCallAuctionMessageCode}, body : OrderTickDataInCallAuctionMessage ]
        \cup [ tag : {OrderTickDataOfNegotiableTradeMessageCode}, body : OrderTickDataOfNegotiableTradeMessage ]
        \cup [ tag : {OrderTickDataOfSecurityLendingMessageCode}, body : OrderTickDataOfSecurityLendingMessage ]
        \cup [ tag : {OrderTickDataOfSpotBondTradingMatchingDealMessageCode}, body : OrderTickDataOfSpotBondTradingMatchingDealMessage ]
        \cup [ tag : {OrderTickDataOfSpotBondTradingQuotationMessageCode}, body : OrderTickDataOfSpotBondTradingQuotationMessage ]
        \cup [ tag : {OrderTickDataOfBidQuotationMessageCode}, body : OrderTickDataOfBidQuotationMessage ]
        \cup [ tag : {TransactionTickDataInCallAuctionMessageCode}, body : TransactionTickDataInCallAuctionMessage ]
        \cup [ tag : {TransactionTickDataOfNegotiableTradeMessageCode}, body : TransactionTickDataOfNegotiableTradeMessage ]
        \cup [ tag : {TransactionTickDataOfSecurityLendingMessageCode}, body : TransactionTickDataOfSecurityLendingMessage ]
        \cup [ tag : {TransactionTickDataOfBondGeneralPledgedRepoMessageCode}, body : TransactionTickDataOfBondGeneralPledgedRepoMessage ]
        \cup [ tag : {TransactionTickDataOfSpotBondTradingQuotationMessageCode}, body : TransactionTickDataOfSpotBondTradingQuotationMessage ]
        \cup [ tag : {TransactionTickDataOfBidQuotationMessageCode}, body : TransactionTickDataOfBidQuotationMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = ChannelHeartbeatMessageCode -> EncodeChannelHeartbeatMessage(message.body)
      [] message.tag = RetransmittingMessageCode -> EncodeRetransmittingMessage(message.body)
      [] message.tag = ClientUserInformationReportingMessageCode -> EncodeClientUserInformationReportingMessage(message.body)
      [] message.tag = StatisticsOfSnapshotDataChannelMessageCode -> EncodeStatisticsOfSnapshotDataChannelMessage(message.body)
      [] message.tag = BusinessRejectMessageCode -> EncodeBusinessRejectMessage(message.body)
      [] message.tag = RealTimeMarketStatusMessageCode -> EncodeRealTimeMarketStatusMessage(message.body)
      [] message.tag = RealTimeStatusOfSecurityMessageCode -> EncodeRealTimeStatusOfSecurityMessage(message.body)
      [] message.tag = AnnouncementsMessageCode -> EncodeAnnouncementsMessage(message.body)
      [] message.tag = SnapshotDataOfCashAuctionMessageCode -> EncodeSnapshotDataOfCashAuctionMessage(message.body)
      [] message.tag = SnapshotDataOfSpotBondTradingMessageCode -> EncodeSnapshotDataOfSpotBondTradingMessage(message.body)
      [] message.tag = SnapshotDataOfAfterHourTradingBlockTradeMessageCode -> EncodeSnapshotDataOfAfterHourTradingBlockTradeMessage(message.body)
      [] message.tag = SnapshotDataOfAfterHourTradingMessageCode -> EncodeSnapshotDataOfAfterHourTradingMessage(message.body)
      [] message.tag = SnapshotDataOfEligibleHkStocksMessageCode -> EncodeSnapshotDataOfEligibleHkStocksMessage(message.body)
      [] message.tag = IndexSnapshotMessageCode -> EncodeIndexSnapshotMessage(message.body)
      [] message.tag = StatisticIndicatorSnapshotMessageCode -> EncodeStatisticIndicatorSnapshotMessage(message.body)
      [] message.tag = RealTimeReferenceNetValueOfFundsSnapshotMessageCode -> EncodeRealTimeReferenceNetValueOfFundsSnapshotMessage(message.body)
      [] message.tag = OrderTickDataInCallAuctionMessageCode -> EncodeOrderTickDataInCallAuctionMessage(message.body)
      [] message.tag = OrderTickDataOfNegotiableTradeMessageCode -> EncodeOrderTickDataOfNegotiableTradeMessage(message.body)
      [] message.tag = OrderTickDataOfSecurityLendingMessageCode -> EncodeOrderTickDataOfSecurityLendingMessage(message.body)
      [] message.tag = OrderTickDataOfSpotBondTradingMatchingDealMessageCode -> EncodeOrderTickDataOfSpotBondTradingMatchingDealMessage(message.body)
      [] message.tag = OrderTickDataOfSpotBondTradingQuotationMessageCode -> EncodeOrderTickDataOfSpotBondTradingQuotationMessage(message.body)
      [] message.tag = OrderTickDataOfBidQuotationMessageCode -> EncodeOrderTickDataOfBidQuotationMessage(message.body)
      [] message.tag = TransactionTickDataInCallAuctionMessageCode -> EncodeTransactionTickDataInCallAuctionMessage(message.body)
      [] message.tag = TransactionTickDataOfNegotiableTradeMessageCode -> EncodeTransactionTickDataOfNegotiableTradeMessage(message.body)
      [] message.tag = TransactionTickDataOfSecurityLendingMessageCode -> EncodeTransactionTickDataOfSecurityLendingMessage(message.body)
      [] message.tag = TransactionTickDataOfBondGeneralPledgedRepoMessageCode -> EncodeTransactionTickDataOfBondGeneralPledgedRepoMessage(message.body)
      [] message.tag = TransactionTickDataOfSpotBondTradingQuotationMessageCode -> EncodeTransactionTickDataOfSpotBondTradingQuotationMessage(message.body)
      [] message.tag = TransactionTickDataOfBidQuotationMessageCode -> EncodeTransactionTickDataOfBidQuotationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ChannelHeartbeatMessageCode -> DecodeChannelHeartbeatMessage(bytes)
              [] tag = RetransmittingMessageCode -> DecodeRetransmittingMessage(bytes)
              [] tag = ClientUserInformationReportingMessageCode -> DecodeClientUserInformationReportingMessage(bytes)
              [] tag = StatisticsOfSnapshotDataChannelMessageCode -> DecodeStatisticsOfSnapshotDataChannelMessage(bytes)
              [] tag = BusinessRejectMessageCode -> DecodeBusinessRejectMessage(bytes)
              [] tag = RealTimeMarketStatusMessageCode -> DecodeRealTimeMarketStatusMessage(bytes)
              [] tag = RealTimeStatusOfSecurityMessageCode -> DecodeRealTimeStatusOfSecurityMessage(bytes)
              [] tag = AnnouncementsMessageCode -> DecodeAnnouncementsMessage(bytes)
              [] tag = SnapshotDataOfCashAuctionMessageCode -> DecodeSnapshotDataOfCashAuctionMessage(bytes)
              [] tag = SnapshotDataOfSpotBondTradingMessageCode -> DecodeSnapshotDataOfSpotBondTradingMessage(bytes)
              [] tag = SnapshotDataOfAfterHourTradingBlockTradeMessageCode -> DecodeSnapshotDataOfAfterHourTradingBlockTradeMessage(bytes)
              [] tag = SnapshotDataOfAfterHourTradingMessageCode -> DecodeSnapshotDataOfAfterHourTradingMessage(bytes)
              [] tag = SnapshotDataOfEligibleHkStocksMessageCode -> DecodeSnapshotDataOfEligibleHkStocksMessage(bytes)
              [] tag = IndexSnapshotMessageCode -> DecodeIndexSnapshotMessage(bytes)
              [] tag = StatisticIndicatorSnapshotMessageCode -> DecodeStatisticIndicatorSnapshotMessage(bytes)
              [] tag = RealTimeReferenceNetValueOfFundsSnapshotMessageCode -> DecodeRealTimeReferenceNetValueOfFundsSnapshotMessage(bytes)
              [] tag = OrderTickDataInCallAuctionMessageCode -> DecodeOrderTickDataInCallAuctionMessage(bytes)
              [] tag = OrderTickDataOfNegotiableTradeMessageCode -> DecodeOrderTickDataOfNegotiableTradeMessage(bytes)
              [] tag = OrderTickDataOfSecurityLendingMessageCode -> DecodeOrderTickDataOfSecurityLendingMessage(bytes)
              [] tag = OrderTickDataOfSpotBondTradingMatchingDealMessageCode -> DecodeOrderTickDataOfSpotBondTradingMatchingDealMessage(bytes)
              [] tag = OrderTickDataOfSpotBondTradingQuotationMessageCode -> DecodeOrderTickDataOfSpotBondTradingQuotationMessage(bytes)
              [] tag = OrderTickDataOfBidQuotationMessageCode -> DecodeOrderTickDataOfBidQuotationMessage(bytes)
              [] tag = TransactionTickDataInCallAuctionMessageCode -> DecodeTransactionTickDataInCallAuctionMessage(bytes)
              [] tag = TransactionTickDataOfNegotiableTradeMessageCode -> DecodeTransactionTickDataOfNegotiableTradeMessage(bytes)
              [] tag = TransactionTickDataOfSecurityLendingMessageCode -> DecodeTransactionTickDataOfSecurityLendingMessage(bytes)
              [] tag = TransactionTickDataOfBondGeneralPledgedRepoMessageCode -> DecodeTransactionTickDataOfBondGeneralPledgedRepoMessage(bytes)
              [] tag = TransactionTickDataOfSpotBondTradingQuotationMessageCode -> DecodeTransactionTickDataOfSpotBondTradingQuotationMessage(bytes)
              [] tag = TransactionTickDataOfBidQuotationMessageCode -> DecodeTransactionTickDataOfBidQuotationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ChannelHeartbeatMessageCode, body |-> one] : one \in CheckedChannelHeartbeatMessage }
        \cup { [tag |-> RetransmittingMessageCode, body |-> one] : one \in CheckedRetransmittingMessage }
        \cup { [tag |-> ClientUserInformationReportingMessageCode, body |-> one] : one \in CheckedClientUserInformationReportingMessage }
        \cup { [tag |-> StatisticsOfSnapshotDataChannelMessageCode, body |-> one] : one \in CheckedStatisticsOfSnapshotDataChannelMessage }
        \cup { [tag |-> BusinessRejectMessageCode, body |-> one] : one \in CheckedBusinessRejectMessage }
        \cup { [tag |-> RealTimeMarketStatusMessageCode, body |-> one] : one \in CheckedRealTimeMarketStatusMessage }
        \cup { [tag |-> RealTimeStatusOfSecurityMessageCode, body |-> one] : one \in CheckedRealTimeStatusOfSecurityMessage }
        \cup { [tag |-> AnnouncementsMessageCode, body |-> one] : one \in CheckedAnnouncementsMessage }
        \cup { [tag |-> SnapshotDataOfCashAuctionMessageCode, body |-> one] : one \in CheckedSnapshotDataOfCashAuctionMessage }
        \cup { [tag |-> SnapshotDataOfSpotBondTradingMessageCode, body |-> one] : one \in CheckedSnapshotDataOfSpotBondTradingMessage }
        \cup { [tag |-> SnapshotDataOfAfterHourTradingBlockTradeMessageCode, body |-> one] : one \in CheckedSnapshotDataOfAfterHourTradingBlockTradeMessage }
        \cup { [tag |-> SnapshotDataOfAfterHourTradingMessageCode, body |-> one] : one \in CheckedSnapshotDataOfAfterHourTradingMessage }
        \cup { [tag |-> SnapshotDataOfEligibleHkStocksMessageCode, body |-> one] : one \in CheckedSnapshotDataOfEligibleHkStocksMessage }
        \cup { [tag |-> IndexSnapshotMessageCode, body |-> one] : one \in CheckedIndexSnapshotMessage }
        \cup { [tag |-> StatisticIndicatorSnapshotMessageCode, body |-> one] : one \in CheckedStatisticIndicatorSnapshotMessage }
        \cup { [tag |-> RealTimeReferenceNetValueOfFundsSnapshotMessageCode, body |-> one] : one \in CheckedRealTimeReferenceNetValueOfFundsSnapshotMessage }
        \cup { [tag |-> OrderTickDataInCallAuctionMessageCode, body |-> one] : one \in CheckedOrderTickDataInCallAuctionMessage }
        \cup { [tag |-> OrderTickDataOfNegotiableTradeMessageCode, body |-> one] : one \in CheckedOrderTickDataOfNegotiableTradeMessage }
        \cup { [tag |-> OrderTickDataOfSecurityLendingMessageCode, body |-> one] : one \in CheckedOrderTickDataOfSecurityLendingMessage }
        \cup { [tag |-> OrderTickDataOfSpotBondTradingMatchingDealMessageCode, body |-> one] : one \in CheckedOrderTickDataOfSpotBondTradingMatchingDealMessage }
        \cup { [tag |-> OrderTickDataOfSpotBondTradingQuotationMessageCode, body |-> one] : one \in CheckedOrderTickDataOfSpotBondTradingQuotationMessage }
        \cup { [tag |-> OrderTickDataOfBidQuotationMessageCode, body |-> one] : one \in CheckedOrderTickDataOfBidQuotationMessage }
        \cup { [tag |-> TransactionTickDataInCallAuctionMessageCode, body |-> one] : one \in CheckedTransactionTickDataInCallAuctionMessage }
        \cup { [tag |-> TransactionTickDataOfNegotiableTradeMessageCode, body |-> one] : one \in CheckedTransactionTickDataOfNegotiableTradeMessage }
        \cup { [tag |-> TransactionTickDataOfSecurityLendingMessageCode, body |-> one] : one \in CheckedTransactionTickDataOfSecurityLendingMessage }
        \cup { [tag |-> TransactionTickDataOfBondGeneralPledgedRepoMessageCode, body |-> one] : one \in CheckedTransactionTickDataOfBondGeneralPledgedRepoMessage }
        \cup { [tag |-> TransactionTickDataOfSpotBondTradingQuotationMessageCode, body |-> one] : one \in CheckedTransactionTickDataOfSpotBondTradingQuotationMessage }
        \cup { [tag |-> TransactionTickDataOfBidQuotationMessageCode, body |-> one] : one \in CheckedTransactionTickDataOfBidQuotationMessage }

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

(* Every Retransmitting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmittingMessage ==
    \A message \in CheckedRetransmittingMessage :
        LET read == DecodeRetransmittingMessage(EncodeRetransmittingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client User Information Reporting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientUserInformationReportingMessage ==
    \A message \in CheckedClientUserInformationReportingMessage :
        LET read == DecodeClientUserInformationReportingMessage(EncodeClientUserInformationReportingMessage(message))
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

(* Every Statistics Of Snapshot Data Channel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsOfSnapshotDataChannelMessage ==
    \A message \in CheckedStatisticsOfSnapshotDataChannelMessage :
        LET read == DecodeStatisticsOfSnapshotDataChannelMessage(EncodeStatisticsOfSnapshotDataChannelMessage(message))
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

(* Every Real Time Market Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeMarketStatusMessage ==
    \A message \in CheckedRealTimeMarketStatusMessage :
        LET read == DecodeRealTimeMarketStatusMessage(EncodeRealTimeMarketStatusMessage(message))
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

(* Every Real Time Status Of Security Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeStatusOfSecurityMessage ==
    \A message \in CheckedRealTimeStatusOfSecurityMessage :
        LET read == DecodeRealTimeStatusOfSecurityMessage(EncodeRealTimeStatusOfSecurityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Announcements Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnnouncementsMessage ==
    \A message \in CheckedAnnouncementsMessage :
        LET read == DecodeAnnouncementsMessage(EncodeAnnouncementsMessage(message))
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

(* Every Snapshot Data Of Cash Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataOfCashAuctionMessage ==
    \A message \in CheckedSnapshotDataOfCashAuctionMessage :
        LET read == DecodeSnapshotDataOfCashAuctionMessage(EncodeSnapshotDataOfCashAuctionMessage(message))
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

(* Every Sub Trading Phase Codes decodes back to what was encoded, and leaves nothing over *)
RoundTripSubTradingPhaseCodes ==
    \A message \in CheckedSubTradingPhaseCodes :
        LET read == DecodeSubTradingPhaseCodes(EncodeSubTradingPhaseCodes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Data Of Spot Bond Trading Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataOfSpotBondTradingMessage ==
    \A message \in CheckedSnapshotDataOfSpotBondTradingMessage :
        LET read == DecodeSnapshotDataOfSpotBondTradingMessage(EncodeSnapshotDataOfSpotBondTradingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMdEntries ==
    \A message \in CheckedTradeMdEntries :
        LET read == DecodeTradeMdEntries(EncodeTradeMdEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Data Of After Hour Trading Block Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataOfAfterHourTradingBlockTradeMessage ==
    \A message \in CheckedSnapshotDataOfAfterHourTradingBlockTradeMessage :
        LET read == DecodeSnapshotDataOfAfterHourTradingBlockTradeMessage(EncodeSnapshotDataOfAfterHourTradingBlockTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMdEntries2 ==
    \A message \in CheckedTradeMdEntries2 :
        LET read == DecodeTradeMdEntries2(EncodeTradeMdEntries2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Data Of After Hour Trading Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataOfAfterHourTradingMessage ==
    \A message \in CheckedSnapshotDataOfAfterHourTradingMessage :
        LET read == DecodeSnapshotDataOfAfterHourTradingMessage(EncodeSnapshotDataOfAfterHourTradingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hk Stocks Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripHkStocksMdEntries ==
    \A message \in CheckedHkStocksMdEntries :
        LET read == DecodeHkStocksMdEntries(EncodeHkStocksMdEntries(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Event Times decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexEventTimes ==
    \A message \in CheckedComplexEventTimes :
        LET read == DecodeComplexEventTimes(EncodeComplexEventTimes(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Data Of Eligible Hk Stocks Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataOfEligibleHkStocksMessage ==
    \A message \in CheckedSnapshotDataOfEligibleHkStocksMessage :
        LET read == DecodeSnapshotDataOfEligibleHkStocksMessage(EncodeSnapshotDataOfEligibleHkStocksMessage(message))
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

(* Every Statistic Indicator Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticIndicatorSnapshotMessage ==
    \A message \in CheckedStatisticIndicatorSnapshotMessage :
        LET read == DecodeStatisticIndicatorSnapshotMessage(EncodeStatisticIndicatorSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Md Entries decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexMdEntries2 ==
    \A message \in CheckedIndexMdEntries2 :
        LET read == DecodeIndexMdEntries2(EncodeIndexMdEntries2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Real Time Reference Net Value Of Funds Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeReferenceNetValueOfFundsSnapshotMessage ==
    \A message \in CheckedRealTimeReferenceNetValueOfFundsSnapshotMessage :
        LET read == DecodeRealTimeReferenceNetValueOfFundsSnapshotMessage(EncodeRealTimeReferenceNetValueOfFundsSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data In Call Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataInCallAuctionMessage ==
    \A message \in CheckedOrderTickDataInCallAuctionMessage :
        LET read == DecodeOrderTickDataInCallAuctionMessage(EncodeOrderTickDataInCallAuctionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data Of Negotiable Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataOfNegotiableTradeMessage ==
    \A message \in CheckedOrderTickDataOfNegotiableTradeMessage :
        LET read == DecodeOrderTickDataOfNegotiableTradeMessage(EncodeOrderTickDataOfNegotiableTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data Of Security Lending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataOfSecurityLendingMessage ==
    \A message \in CheckedOrderTickDataOfSecurityLendingMessage :
        LET read == DecodeOrderTickDataOfSecurityLendingMessage(EncodeOrderTickDataOfSecurityLendingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data Of Spot Bond Trading Matching Deal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataOfSpotBondTradingMatchingDealMessage ==
    \A message \in CheckedOrderTickDataOfSpotBondTradingMatchingDealMessage :
        LET read == DecodeOrderTickDataOfSpotBondTradingMatchingDealMessage(EncodeOrderTickDataOfSpotBondTradingMatchingDealMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data Of Spot Bond Trading Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataOfSpotBondTradingQuotationMessage ==
    \A message \in CheckedOrderTickDataOfSpotBondTradingQuotationMessage :
        LET read == DecodeOrderTickDataOfSpotBondTradingQuotationMessage(EncodeOrderTickDataOfSpotBondTradingQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Tick Data Of Bid Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderTickDataOfBidQuotationMessage ==
    \A message \in CheckedOrderTickDataOfBidQuotationMessage :
        LET read == DecodeOrderTickDataOfBidQuotationMessage(EncodeOrderTickDataOfBidQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data In Call Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataInCallAuctionMessage ==
    \A message \in CheckedTransactionTickDataInCallAuctionMessage :
        LET read == DecodeTransactionTickDataInCallAuctionMessage(EncodeTransactionTickDataInCallAuctionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data Of Negotiable Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataOfNegotiableTradeMessage ==
    \A message \in CheckedTransactionTickDataOfNegotiableTradeMessage :
        LET read == DecodeTransactionTickDataOfNegotiableTradeMessage(EncodeTransactionTickDataOfNegotiableTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data Of Security Lending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataOfSecurityLendingMessage ==
    \A message \in CheckedTransactionTickDataOfSecurityLendingMessage :
        LET read == DecodeTransactionTickDataOfSecurityLendingMessage(EncodeTransactionTickDataOfSecurityLendingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data Of Bond General Pledged Repo Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataOfBondGeneralPledgedRepoMessage ==
    \A message \in CheckedTransactionTickDataOfBondGeneralPledgedRepoMessage :
        LET read == DecodeTransactionTickDataOfBondGeneralPledgedRepoMessage(EncodeTransactionTickDataOfBondGeneralPledgedRepoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data Of Spot Bond Trading Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataOfSpotBondTradingQuotationMessage ==
    \A message \in CheckedTransactionTickDataOfSpotBondTradingQuotationMessage :
        LET read == DecodeTransactionTickDataOfSpotBondTradingQuotationMessage(EncodeTransactionTickDataOfSpotBondTradingQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transaction Tick Data Of Bid Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactionTickDataOfBidQuotationMessage ==
    \A message \in CheckedTransactionTickDataOfBidQuotationMessage :
        LET read == DecodeTransactionTickDataOfBidQuotationMessage(EncodeTransactionTickDataOfBidQuotationMessage(message))
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
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
