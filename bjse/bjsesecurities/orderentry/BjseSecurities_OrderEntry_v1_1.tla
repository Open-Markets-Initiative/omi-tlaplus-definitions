------------------ MODULE BjseSecurities_OrderEntry_v1_1 -------------------
(***************************************************************************)
(* Beijing Stock Exchange Bjse Order Entry v1.1                            *)
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
(* Business Reject Message: 103 bytes                                      *)
(***************************************************************************)

BusinessRejectMessage ==
    [ applId               : Sample(3),
      transactTime         : Sample(8),
      submittingPbuid      : Sample(6),
      securityId           : Sample(8),
      securityIdSource     : Sample(4),
      refSeqNum            : Sample(8),
      refMsgType           : Sample(4),
      businessRejectRefId  : Sample(10),
      businessRejectReason : Sample(2),
      businessRejectText   : Sample(50) ]

EncodeBusinessRejectMessage(message) ==
    message.applId
        \o message.transactTime
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.refSeqNum
        \o message.refMsgType
        \o message.businessRejectRefId
        \o message.businessRejectReason
        \o message.businessRejectText

DecodeBusinessRejectMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(applId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(transactTime.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET refSeqNum == ReadBytes(securityIdSource.rest, 8) IN IF ~refSeqNum.ok THEN Fail ELSE
    LET refMsgType == ReadBytes(refSeqNum.rest, 4) IN IF ~refMsgType.ok THEN Fail ELSE
    LET businessRejectRefId == ReadBytes(refMsgType.rest, 10) IN IF ~businessRejectRefId.ok THEN Fail ELSE
    LET businessRejectReason == ReadBytes(businessRejectRefId.rest, 2) IN IF ~businessRejectReason.ok THEN Fail ELSE
    LET businessRejectText == ReadBytes(businessRejectReason.rest, 50) IN IF ~businessRejectText.ok THEN Fail ELSE
    Ok([ applId               |-> applId.value,
         transactTime         |-> transactTime.value,
         submittingPbuid      |-> submittingPbuid.value,
         securityId           |-> securityId.value,
         securityIdSource     |-> securityIdSource.value,
         refSeqNum            |-> refSeqNum.value,
         refMsgType           |-> refMsgType.value,
         businessRejectRefId  |-> businessRejectRefId.value,
         businessRejectReason |-> businessRejectReason.value,
         businessRejectText   |-> businessRejectText.value ], businessRejectText.rest)

ZeroBusinessRejectMessage ==
    [ applId               |-> [i \in 1 .. 3 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      submittingPbuid      |-> [i \in 1 .. 6 |-> 0],
      securityId           |-> [i \in 1 .. 8 |-> 0],
      securityIdSource     |-> [i \in 1 .. 4 |-> 0],
      refSeqNum            |-> [i \in 1 .. 8 |-> 0],
      refMsgType           |-> [i \in 1 .. 4 |-> 0],
      businessRejectRefId  |-> [i \in 1 .. 10 |-> 0],
      businessRejectReason |-> [i \in 1 .. 2 |-> 0],
      businessRejectText   |-> [i \in 1 .. 50 |-> 0] ]

(* Business Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessRejectMessage ==
    { ZeroBusinessRejectMessage }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.refSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.refMsgType = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectRefId = one] : one \in Sample(10) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.businessRejectText = one] : one \in Sample(50) }

(***************************************************************************)
(* Partition Reports: 12 bytes                                             *)
(***************************************************************************)

PartitionReports ==
    [ partitionNo : Sample(4),
      reportIndex : Sample(8) ]

EncodePartitionReports(message) ==
    message.partitionNo
        \o message.reportIndex

DecodePartitionReports(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    Ok([ partitionNo |-> partitionNo.value,
         reportIndex |-> reportIndex.value ], reportIndex.rest)

ZeroPartitionReports ==
    [ partitionNo |-> [i \in 1 .. 4 |-> 0],
      reportIndex |-> [i \in 1 .. 8 |-> 0] ]

(* Partition Reports at zero, then each field in turn at the values it is checked at *)
CheckedPartitionReports ==
    { ZeroPartitionReports }
        \cup { [ZeroPartitionReports EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroPartitionReports EXCEPT !.reportIndex = one] : one \in Sample(8) }

(* A run of Partition Reports, written one after another *)
RECURSIVE EncodePartitionReportsList(_)
EncodePartitionReportsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartitionReports(Head(messages)) \o EncodePartitionReportsList(Tail(messages))

(* As many Partition Reports as the field that counts them says *)
RECURSIVE ReadPartitionReportsList(_, _)
ReadPartitionReportsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartitionReports(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartitionReportsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Partition Reports of each kind, for the lists that carry them *)
OnePartitionReports == { ZeroPartitionReports }

(***************************************************************************)
(* Report Synchronization Message                                          *)
(***************************************************************************)

ReportSynchronizationMessage ==
    [ partitionReports : SampleLists(OnePartitionReports) ]

EncodeReportSynchronizationMessage(message) ==
    EncodeUIntBE(Len(message.partitionReports), 4)
        \o EncodePartitionReportsList(message.partitionReports)

DecodeReportSynchronizationMessage(bytes) ==
    LET noPartitions == ReadUIntBE(bytes, 4) IN IF ~noPartitions.ok THEN Fail ELSE
    LET partitionReports == ReadPartitionReportsList(noPartitions.rest, noPartitions.value) IN IF ~partitionReports.ok THEN Fail ELSE
    Ok([ partitionReports |-> partitionReports.value ], partitionReports.rest)

ZeroReportSynchronizationMessage ==
    [ partitionReports |-> << >> ]

(* Report Synchronization Message at zero, then each field in turn at the values it is checked at *)
CheckedReportSynchronizationMessage ==
    { ZeroReportSynchronizationMessage }
        \cup { [ZeroReportSynchronizationMessage EXCEPT !.partitionReports = one] : one \in SampleLists(OnePartitionReports) }

(***************************************************************************)
(* Platform State Info Message: 4 bytes                                    *)
(***************************************************************************)

PlatformStateInfoMessage ==
    [ platformId    : Sample(2),
      platformState : Sample(2) ]

EncodePlatformStateInfoMessage(message) ==
    message.platformId
        \o message.platformState

DecodePlatformStateInfoMessage(bytes) ==
    LET platformId == ReadBytes(bytes, 2) IN IF ~platformId.ok THEN Fail ELSE
    LET platformState == ReadBytes(platformId.rest, 2) IN IF ~platformState.ok THEN Fail ELSE
    Ok([ platformId    |-> platformId.value,
         platformState |-> platformState.value ], platformState.rest)

ZeroPlatformStateInfoMessage ==
    [ platformId    |-> [i \in 1 .. 2 |-> 0],
      platformState |-> [i \in 1 .. 2 |-> 0] ]

(* Platform State Info Message at zero, then each field in turn at the values it is checked at *)
CheckedPlatformStateInfoMessage ==
    { ZeroPlatformStateInfoMessage }
        \cup { [ZeroPlatformStateInfoMessage EXCEPT !.platformId = one] : one \in Sample(2) }
        \cup { [ZeroPlatformStateInfoMessage EXCEPT !.platformState = one] : one \in Sample(2) }

(***************************************************************************)
(* Report Finished Message: 14 bytes                                       *)
(***************************************************************************)

ReportFinishedMessage ==
    [ partitionNo : Sample(4),
      reportIndex : Sample(8),
      platformId  : Sample(2) ]

EncodeReportFinishedMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.platformId

DecodeReportFinishedMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET platformId == ReadBytes(reportIndex.rest, 2) IN IF ~platformId.ok THEN Fail ELSE
    Ok([ partitionNo |-> partitionNo.value,
         reportIndex |-> reportIndex.value,
         platformId  |-> platformId.value ], platformId.rest)

ZeroReportFinishedMessage ==
    [ partitionNo |-> [i \in 1 .. 4 |-> 0],
      reportIndex |-> [i \in 1 .. 8 |-> 0],
      platformId  |-> [i \in 1 .. 2 |-> 0] ]

(* Report Finished Message at zero, then each field in turn at the values it is checked at *)
CheckedReportFinishedMessage ==
    { ZeroReportFinishedMessage }
        \cup { [ZeroReportFinishedMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroReportFinishedMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroReportFinishedMessage EXCEPT !.platformId = one] : one \in Sample(2) }

(***************************************************************************)
(* Partitions: 4 bytes                                                     *)
(***************************************************************************)

Partitions ==
    [ partitionNo : Sample(4) ]

EncodePartitions(message) ==
    message.partitionNo

DecodePartitions(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    Ok([ partitionNo |-> partitionNo.value ], partitionNo.rest)

ZeroPartitions ==
    [ partitionNo |-> [i \in 1 .. 4 |-> 0] ]

(* Partitions at zero, then each field in turn at the values it is checked at *)
CheckedPartitions ==
    { ZeroPartitions }
        \cup { [ZeroPartitions EXCEPT !.partitionNo = one] : one \in Sample(4) }

(* A run of Partitions, written one after another *)
RECURSIVE EncodePartitionsList(_)
EncodePartitionsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartitions(Head(messages)) \o EncodePartitionsList(Tail(messages))

(* As many Partitions as the field that counts them says *)
RECURSIVE ReadPartitionsList(_, _)
ReadPartitionsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartitions(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartitionsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Partitions of each kind, for the lists that carry them *)
OnePartitions == { ZeroPartitions }

(***************************************************************************)
(* Platform Info Message                                                   *)
(***************************************************************************)

PlatformInfoMessage ==
    [ platformId : Sample(2),
      partitions : SampleLists(OnePartitions) ]

EncodePlatformInfoMessage(message) ==
    message.platformId
        \o EncodeUIntBE(Len(message.partitions), 4)
        \o EncodePartitionsList(message.partitions)

DecodePlatformInfoMessage(bytes) ==
    LET platformId == ReadBytes(bytes, 2) IN IF ~platformId.ok THEN Fail ELSE
    LET noPartitions == ReadUIntBE(platformId.rest, 4) IN IF ~noPartitions.ok THEN Fail ELSE
    LET partitions == ReadPartitionsList(noPartitions.rest, noPartitions.value) IN IF ~partitions.ok THEN Fail ELSE
    Ok([ platformId |-> platformId.value,
         partitions |-> partitions.value ], partitions.rest)

ZeroPlatformInfoMessage ==
    [ platformId |-> [i \in 1 .. 2 |-> 0],
      partitions |-> << >> ]

(* Platform Info Message at zero, then each field in turn at the values it is checked at *)
CheckedPlatformInfoMessage ==
    { ZeroPlatformInfoMessage }
        \cup { [ZeroPlatformInfoMessage EXCEPT !.platformId = one] : one \in Sample(2) }
        \cup { [ZeroPlatformInfoMessage EXCEPT !.partitions = one] : one \in SampleLists(OnePartitions) }

(***************************************************************************)
(* Trading Session Status Message: 42 bytes                                *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ marketId            : Sample(8),
      marketSegmentId     : Sample(8),
      tradingSessionId    : Sample(4),
      tradingSessionSubId : Sample(4),
      tradSesStatus       : Sample(2),
      tradSesStartTime    : Sample(8),
      tradSesEndTime      : Sample(8) ]

EncodeTradingSessionStatusMessage(message) ==
    message.marketId
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.tradSesStartTime
        \o message.tradSesEndTime

DecodeTradingSessionStatusMessage(bytes) ==
    LET marketId == ReadBytes(bytes, 8) IN IF ~marketId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(marketId.rest, 8) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 4) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 2) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET tradSesStartTime == ReadBytes(tradSesStatus.rest, 8) IN IF ~tradSesStartTime.ok THEN Fail ELSE
    LET tradSesEndTime == ReadBytes(tradSesStartTime.rest, 8) IN IF ~tradSesEndTime.ok THEN Fail ELSE
    Ok([ marketId            |-> marketId.value,
         marketSegmentId     |-> marketSegmentId.value,
         tradingSessionId    |-> tradingSessionId.value,
         tradingSessionSubId |-> tradingSessionSubId.value,
         tradSesStatus       |-> tradSesStatus.value,
         tradSesStartTime    |-> tradSesStartTime.value,
         tradSesEndTime      |-> tradSesEndTime.value ], tradSesEndTime.rest)

ZeroTradingSessionStatusMessage ==
    [ marketId            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId     |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId    |-> [i \in 1 .. 4 |-> 0],
      tradingSessionSubId |-> [i \in 1 .. 4 |-> 0],
      tradSesStatus       |-> [i \in 1 .. 2 |-> 0],
      tradSesStartTime    |-> [i \in 1 .. 8 |-> 0],
      tradSesEndTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.marketId = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.marketSegmentId = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesStatus = one] : one \in Sample(2) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesStartTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesEndTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Bond Spot Matching New Order Message: 131 bytes                         *)
(***************************************************************************)

BondSpotMatchingNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      stopPx            : Sample(8),
      minQty            : Sample(8),
      maxPriceLevels    : Sample(2),
      timeInForce       : Sample(1),
      cashMargin        : Sample(1),
      settlType         : Sample(1),
      settlPeriod       : Sample(1) ]

EncodeBondSpotMatchingNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.stopPx
        \o message.minQty
        \o message.maxPriceLevels
        \o message.timeInForce
        \o message.cashMargin
        \o message.settlType
        \o message.settlPeriod

DecodeBondSpotMatchingNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxPriceLevels == ReadBytes(minQty.rest, 2) IN IF ~maxPriceLevels.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(maxPriceLevels.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(timeInForce.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET settlType == ReadBytes(cashMargin.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         stopPx            |-> stopPx.value,
         minQty            |-> minQty.value,
         maxPriceLevels    |-> maxPriceLevels.value,
         timeInForce       |-> timeInForce.value,
         cashMargin        |-> cashMargin.value,
         settlType         |-> settlType.value,
         settlPeriod       |-> settlPeriod.value ], settlPeriod.rest)

ZeroBondSpotMatchingNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      stopPx            |-> [i \in 1 .. 8 |-> 0],
      minQty            |-> [i \in 1 .. 8 |-> 0],
      maxPriceLevels    |-> [i \in 1 .. 2 |-> 0],
      timeInForce       |-> [i \in 1 .. 1 |-> 0],
      cashMargin        |-> [i \in 1 .. 1 |-> 0],
      settlType         |-> [i \in 1 .. 1 |-> 0],
      settlPeriod       |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Matching New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotMatchingNewOrderMessage ==
    { ZeroBondSpotMatchingNewOrderMessage }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.maxPriceLevels = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingNewOrderMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }

(***************************************************************************)
(* Centralized Auction New Order Message: 129 bytes                        *)
(***************************************************************************)

CentralizedAuctionNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      stopPx            : Sample(8),
      minQty            : Sample(8),
      maxPriceLevels    : Sample(2),
      timeInForce       : Sample(1),
      cashMargin        : Sample(1) ]

EncodeCentralizedAuctionNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.stopPx
        \o message.minQty
        \o message.maxPriceLevels
        \o message.timeInForce
        \o message.cashMargin

DecodeCentralizedAuctionNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxPriceLevels == ReadBytes(minQty.rest, 2) IN IF ~maxPriceLevels.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(maxPriceLevels.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(timeInForce.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         stopPx            |-> stopPx.value,
         minQty            |-> minQty.value,
         maxPriceLevels    |-> maxPriceLevels.value,
         timeInForce       |-> timeInForce.value,
         cashMargin        |-> cashMargin.value ], cashMargin.rest)

ZeroCentralizedAuctionNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      stopPx            |-> [i \in 1 .. 8 |-> 0],
      minQty            |-> [i \in 1 .. 8 |-> 0],
      maxPriceLevels    |-> [i \in 1 .. 2 |-> 0],
      timeInForce       |-> [i \in 1 .. 1 |-> 0],
      cashMargin        |-> [i \in 1 .. 1 |-> 0] ]

(* Centralized Auction New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCentralizedAuctionNewOrderMessage ==
    { ZeroCentralizedAuctionNewOrderMessage }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.maxPriceLevels = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionNewOrderMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Conversion New Order Message: 109 bytes                                 *)
(***************************************************************************)

ConversionNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8) ]

EncodeConversionNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price

DecodeConversionNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value ], price.rest)

ZeroConversionNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Conversion New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedConversionNewOrderMessage ==
    { ZeroConversionNewOrderMessage }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroConversionNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Inquiry New Order Message: 109 bytes                                    *)
(***************************************************************************)

InquiryNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8) ]

EncodeInquiryNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price

DecodeInquiryNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value ], price.rest)

ZeroInquiryNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Inquiry New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedInquiryNewOrderMessage ==
    { ZeroInquiryNewOrderMessage }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroInquiryNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Subscription New Order Message: 109 bytes                               *)
(***************************************************************************)

SubscriptionNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8) ]

EncodeSubscriptionNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price

DecodeSubscriptionNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value ], price.rest)

ZeroSubscriptionNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Subscription New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionNewOrderMessage ==
    { ZeroSubscriptionNewOrderMessage }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Put Back New Order Message: 109 bytes                                   *)
(***************************************************************************)

PutBackNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8) ]

EncodePutBackNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price

DecodePutBackNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value ], price.rest)

ZeroPutBackNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Put Back New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPutBackNewOrderMessage ==
    { ZeroPutBackNewOrderMessage }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroPutBackNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Tender Offer Acceptance New Order Message: 109 bytes                    *)
(***************************************************************************)

TenderOfferAcceptanceNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8) ]

EncodeTenderOfferAcceptanceNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price

DecodeTenderOfferAcceptanceNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value ], price.rest)

ZeroTenderOfferAcceptanceNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0] ]

(* Tender Offer Acceptance New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedTenderOfferAcceptanceNewOrderMessage ==
    { ZeroTenderOfferAcceptanceNewOrderMessage }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Refinancing Securities Lending Non Agreed New Order Message: 114 bytes  *)
(***************************************************************************)

RefinancingSecuritiesLendingNonAgreedNewOrderMessage ==
    [ applId            : Sample(3),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      clOrdId           : Sample(10),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      expirationDays    : Sample(2),
      expirationType    : Sample(1),
      shareProperty     : Sample(2) ]

EncodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.expirationDays
        \o message.expirationType
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(clOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET side == ReadBytes(orderRestrictions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(price.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(expirationType.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ applId            |-> applId.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         clOrdId           |-> clOrdId.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         expirationDays    |-> expirationDays.value,
         expirationType    |-> expirationType.value,
         shareProperty     |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage ==
    [ applId            |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      expirationDays    |-> [i \in 1 .. 2 |-> 0],
      expirationType    |-> [i \in 1 .. 1 |-> 0],
      shareProperty     |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Non Agreed New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingNonAgreedNewOrderMessage ==
    { ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedNewOrderMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancel Request Message: 121 bytes                                 *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ applId           : Sample(3),
      submittingPbuid  : Sample(6),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      ownerType        : Sample(2),
      clearingFirm     : Sample(2),
      transactTime     : Sample(8),
      userInfo         : Sample(32),
      clOrdId          : Sample(10),
      origClOrdId      : Sample(10),
      accountId        : Sample(10),
      branchId         : Sample(2),
      orderId          : Sample(16),
      orderQty         : Sample(8) ]

EncodeOrderCancelRequestMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.origClOrdId
        \o message.accountId
        \o message.branchId
        \o message.orderId
        \o message.orderQty

DecodeOrderCancelRequestMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(origClOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderId == ReadBytes(branchId.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    Ok([ applId           |-> applId.value,
         submittingPbuid  |-> submittingPbuid.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         ownerType        |-> ownerType.value,
         clearingFirm     |-> clearingFirm.value,
         transactTime     |-> transactTime.value,
         userInfo         |-> userInfo.value,
         clOrdId          |-> clOrdId.value,
         origClOrdId      |-> origClOrdId.value,
         accountId        |-> accountId.value,
         branchId         |-> branchId.value,
         orderId          |-> orderId.value,
         orderQty         |-> orderQty.value ], orderQty.rest)

ZeroOrderCancelRequestMessage ==
    [ applId           |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid  |-> [i \in 1 .. 6 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      ownerType        |-> [i \in 1 .. 2 |-> 0],
      clearingFirm     |-> [i \in 1 .. 2 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userInfo         |-> [i \in 1 .. 32 |-> 0],
      clOrdId          |-> [i \in 1 .. 10 |-> 0],
      origClOrdId      |-> [i \in 1 .. 10 |-> 0],
      accountId        |-> [i \in 1 .. 10 |-> 0],
      branchId         |-> [i \in 1 .. 2 |-> 0],
      orderId          |-> [i \in 1 .. 16 |-> 0],
      orderQty         |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderQty = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Reject Message: 150 bytes                                        *)
(***************************************************************************)

CancelRejectMessage ==
    [ partitionNo      : Sample(4),
      reportIndex      : Sample(8),
      applId           : Sample(3),
      reportingPbuid   : Sample(6),
      submittingPbuid  : Sample(6),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      ownerType        : Sample(2),
      clearingFirm     : Sample(2),
      transactTime     : Sample(8),
      userInfo         : Sample(32),
      clOrdId          : Sample(10),
      origClOrdId      : Sample(10),
      accountId        : Sample(10),
      branchId         : Sample(2),
      ordStatus        : Sample(1),
      cxlRejReason     : Sample(2),
      rejectText       : Sample(16),
      orderId          : Sample(16) ]

EncodeCancelRejectMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.clOrdId
        \o message.origClOrdId
        \o message.accountId
        \o message.branchId
        \o message.ordStatus
        \o message.cxlRejReason
        \o message.rejectText
        \o message.orderId

DecodeCancelRejectMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(userInfo.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET accountId == ReadBytes(origClOrdId.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(branchId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~cxlRejReason.ok THEN Fail ELSE
    LET rejectText == ReadBytes(cxlRejReason.rest, 16) IN IF ~rejectText.ok THEN Fail ELSE
    LET orderId == ReadBytes(rejectText.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ partitionNo      |-> partitionNo.value,
         reportIndex      |-> reportIndex.value,
         applId           |-> applId.value,
         reportingPbuid   |-> reportingPbuid.value,
         submittingPbuid  |-> submittingPbuid.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         ownerType        |-> ownerType.value,
         clearingFirm     |-> clearingFirm.value,
         transactTime     |-> transactTime.value,
         userInfo         |-> userInfo.value,
         clOrdId          |-> clOrdId.value,
         origClOrdId      |-> origClOrdId.value,
         accountId        |-> accountId.value,
         branchId         |-> branchId.value,
         ordStatus        |-> ordStatus.value,
         cxlRejReason     |-> cxlRejReason.value,
         rejectText       |-> rejectText.value,
         orderId          |-> orderId.value ], orderId.rest)

ZeroCancelRejectMessage ==
    [ partitionNo      |-> [i \in 1 .. 4 |-> 0],
      reportIndex      |-> [i \in 1 .. 8 |-> 0],
      applId           |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid   |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid  |-> [i \in 1 .. 6 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      ownerType        |-> [i \in 1 .. 2 |-> 0],
      clearingFirm     |-> [i \in 1 .. 2 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userInfo         |-> [i \in 1 .. 32 |-> 0],
      clOrdId          |-> [i \in 1 .. 10 |-> 0],
      origClOrdId      |-> [i \in 1 .. 10 |-> 0],
      accountId        |-> [i \in 1 .. 10 |-> 0],
      branchId         |-> [i \in 1 .. 2 |-> 0],
      ordStatus        |-> [i \in 1 .. 1 |-> 0],
      cxlRejReason     |-> [i \in 1 .. 2 |-> 0],
      rejectText       |-> [i \in 1 .. 16 |-> 0],
      orderId          |-> [i \in 1 .. 16 |-> 0] ]

(* Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectMessage ==
    { ZeroCancelRejectMessage }
        \cup { [ZeroCancelRejectMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.cxlRejReason = one] : one \in Sample(2) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.rejectText = one] : one \in Sample(16) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.orderId = one] : one \in Sample(16) }

(***************************************************************************)
(* Bond Spot Matching Execution Report Message: 209 bytes                  *)
(***************************************************************************)

BondSpotMatchingExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      stopPx            : Sample(8),
      minQty            : Sample(8),
      maxPriceLevels    : Sample(2),
      timeInForce       : Sample(1),
      cashMargin        : Sample(1) ]

EncodeBondSpotMatchingExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.stopPx
        \o message.minQty
        \o message.maxPriceLevels
        \o message.timeInForce
        \o message.cashMargin

DecodeBondSpotMatchingExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET stopPx == ReadBytes(orderRestrictions.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxPriceLevels == ReadBytes(minQty.rest, 2) IN IF ~maxPriceLevels.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(maxPriceLevels.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(timeInForce.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         stopPx            |-> stopPx.value,
         minQty            |-> minQty.value,
         maxPriceLevels    |-> maxPriceLevels.value,
         timeInForce       |-> timeInForce.value,
         cashMargin        |-> cashMargin.value ], cashMargin.rest)

ZeroBondSpotMatchingExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      stopPx            |-> [i \in 1 .. 8 |-> 0],
      minQty            |-> [i \in 1 .. 8 |-> 0],
      maxPriceLevels    |-> [i \in 1 .. 2 |-> 0],
      timeInForce       |-> [i \in 1 .. 1 |-> 0],
      cashMargin        |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Matching Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotMatchingExecutionReportMessage ==
    { ZeroBondSpotMatchingExecutionReportMessage }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.maxPriceLevels = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingExecutionReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Centralized Auction Execution Report Message: 209 bytes                 *)
(***************************************************************************)

CentralizedAuctionExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      stopPx            : Sample(8),
      minQty            : Sample(8),
      maxPriceLevels    : Sample(2),
      timeInForce       : Sample(1),
      cashMargin        : Sample(1) ]

EncodeCentralizedAuctionExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.stopPx
        \o message.minQty
        \o message.maxPriceLevels
        \o message.timeInForce
        \o message.cashMargin

DecodeCentralizedAuctionExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET stopPx == ReadBytes(orderRestrictions.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET minQty == ReadBytes(stopPx.rest, 8) IN IF ~minQty.ok THEN Fail ELSE
    LET maxPriceLevels == ReadBytes(minQty.rest, 2) IN IF ~maxPriceLevels.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(maxPriceLevels.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(timeInForce.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         stopPx            |-> stopPx.value,
         minQty            |-> minQty.value,
         maxPriceLevels    |-> maxPriceLevels.value,
         timeInForce       |-> timeInForce.value,
         cashMargin        |-> cashMargin.value ], cashMargin.rest)

ZeroCentralizedAuctionExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      stopPx            |-> [i \in 1 .. 8 |-> 0],
      minQty            |-> [i \in 1 .. 8 |-> 0],
      maxPriceLevels    |-> [i \in 1 .. 2 |-> 0],
      timeInForce       |-> [i \in 1 .. 1 |-> 0],
      cashMargin        |-> [i \in 1 .. 1 |-> 0] ]

(* Centralized Auction Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedCentralizedAuctionExecutionReportMessage ==
    { ZeroCentralizedAuctionExecutionReportMessage }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.minQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.maxPriceLevels = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionExecutionReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Conversion Execution Report Message: 189 bytes                          *)
(***************************************************************************)

ConversionExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4) ]

EncodeConversionExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions

DecodeConversionExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value ], orderRestrictions.rest)

ZeroConversionExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0] ]

(* Conversion Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedConversionExecutionReportMessage ==
    { ZeroConversionExecutionReportMessage }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroConversionExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquiry Execution Report Message: 189 bytes                             *)
(***************************************************************************)

InquiryExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4) ]

EncodeInquiryExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions

DecodeInquiryExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value ], orderRestrictions.rest)

ZeroInquiryExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0] ]

(* Inquiry Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedInquiryExecutionReportMessage ==
    { ZeroInquiryExecutionReportMessage }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroInquiryExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscription Execution Report Message: 189 bytes                        *)
(***************************************************************************)

SubscriptionExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4) ]

EncodeSubscriptionExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions

DecodeSubscriptionExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value ], orderRestrictions.rest)

ZeroSubscriptionExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0] ]

(* Subscription Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionExecutionReportMessage ==
    { ZeroSubscriptionExecutionReportMessage }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }

(***************************************************************************)
(* Put Back Execution Report Message: 189 bytes                            *)
(***************************************************************************)

PutBackExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4) ]

EncodePutBackExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions

DecodePutBackExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value ], orderRestrictions.rest)

ZeroPutBackExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0] ]

(* Put Back Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedPutBackExecutionReportMessage ==
    { ZeroPutBackExecutionReportMessage }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroPutBackExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }

(***************************************************************************)
(* Tender Offer Acceptance Execution Report Message: 189 bytes             *)
(***************************************************************************)

TenderOfferAcceptanceExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4) ]

EncodeTenderOfferAcceptanceExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions

DecodeTenderOfferAcceptanceExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value ], orderRestrictions.rest)

ZeroTenderOfferAcceptanceExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0] ]

(* Tender Offer Acceptance Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTenderOfferAcceptanceExecutionReportMessage ==
    { ZeroTenderOfferAcceptanceExecutionReportMessage }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroTenderOfferAcceptanceExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }

(***************************************************************************)
(* Refinancing Securities Lending Non Agreed Execution Report Message: 194 *)
(* bytes                                                                   *)
(***************************************************************************)

RefinancingSecuritiesLendingNonAgreedExecutionReportMessage ==
    [ partitionNo       : Sample(4),
      reportIndex       : Sample(8),
      applId            : Sample(3),
      reportingPbuid    : Sample(6),
      submittingPbuid   : Sample(6),
      securityId        : Sample(8),
      securityIdSource  : Sample(4),
      ownerType         : Sample(2),
      clearingFirm      : Sample(2),
      transactTime      : Sample(8),
      userInfo          : Sample(32),
      orderId           : Sample(16),
      clOrdId           : Sample(10),
      origClOrdId       : Sample(10),
      execId            : Sample(16),
      execType          : Sample(1),
      ordStatus         : Sample(1),
      ordRejReason      : Sample(2),
      leavesQty         : Sample(8),
      cumQty            : Sample(8),
      side              : Sample(1),
      ordType           : Sample(1),
      orderQty          : Sample(8),
      price             : Sample(8),
      accountId         : Sample(10),
      branchId          : Sample(2),
      orderRestrictions : Sample(4),
      expirationDays    : Sample(2),
      expirationType    : Sample(1),
      shareProperty     : Sample(2) ]

EncodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.ordRejReason
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.ordType
        \o message.orderQty
        \o message.price
        \o message.accountId
        \o message.branchId
        \o message.orderRestrictions
        \o message.expirationDays
        \o message.expirationType
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 10) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(origClOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 2) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(ordRejReason.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET orderQty == ReadBytes(ordType.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET accountId == ReadBytes(price.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET orderRestrictions == ReadBytes(branchId.rest, 4) IN IF ~orderRestrictions.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(orderRestrictions.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(expirationType.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ partitionNo       |-> partitionNo.value,
         reportIndex       |-> reportIndex.value,
         applId            |-> applId.value,
         reportingPbuid    |-> reportingPbuid.value,
         submittingPbuid   |-> submittingPbuid.value,
         securityId        |-> securityId.value,
         securityIdSource  |-> securityIdSource.value,
         ownerType         |-> ownerType.value,
         clearingFirm      |-> clearingFirm.value,
         transactTime      |-> transactTime.value,
         userInfo          |-> userInfo.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         origClOrdId       |-> origClOrdId.value,
         execId            |-> execId.value,
         execType          |-> execType.value,
         ordStatus         |-> ordStatus.value,
         ordRejReason      |-> ordRejReason.value,
         leavesQty         |-> leavesQty.value,
         cumQty            |-> cumQty.value,
         side              |-> side.value,
         ordType           |-> ordType.value,
         orderQty          |-> orderQty.value,
         price             |-> price.value,
         accountId         |-> accountId.value,
         branchId          |-> branchId.value,
         orderRestrictions |-> orderRestrictions.value,
         expirationDays    |-> expirationDays.value,
         expirationType    |-> expirationType.value,
         shareProperty     |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage ==
    [ partitionNo       |-> [i \in 1 .. 4 |-> 0],
      reportIndex       |-> [i \in 1 .. 8 |-> 0],
      applId            |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid    |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid   |-> [i \in 1 .. 6 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      securityIdSource  |-> [i \in 1 .. 4 |-> 0],
      ownerType         |-> [i \in 1 .. 2 |-> 0],
      clearingFirm      |-> [i \in 1 .. 2 |-> 0],
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      userInfo          |-> [i \in 1 .. 32 |-> 0],
      orderId           |-> [i \in 1 .. 16 |-> 0],
      clOrdId           |-> [i \in 1 .. 10 |-> 0],
      origClOrdId       |-> [i \in 1 .. 10 |-> 0],
      execId            |-> [i \in 1 .. 16 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      ordStatus         |-> [i \in 1 .. 1 |-> 0],
      ordRejReason      |-> [i \in 1 .. 2 |-> 0],
      leavesQty         |-> [i \in 1 .. 8 |-> 0],
      cumQty            |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      ordType           |-> [i \in 1 .. 1 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      accountId         |-> [i \in 1 .. 10 |-> 0],
      branchId          |-> [i \in 1 .. 2 |-> 0],
      orderRestrictions |-> [i \in 1 .. 4 |-> 0],
      expirationDays    |-> [i \in 1 .. 2 |-> 0],
      expirationType    |-> [i \in 1 .. 1 |-> 0],
      shareProperty     |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Non Agreed Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingNonAgreedExecutionReportMessage ==
    { ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.origClOrdId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.ordRejReason = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.orderRestrictions = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedExecutionReportMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Bond Spot Matching Trade Execution Report Message: 175 bytes            *)
(***************************************************************************)

BondSpotMatchingTradeExecutionReportMessage ==
    [ partitionNo      : Sample(4),
      reportIndex      : Sample(8),
      applId           : Sample(3),
      reportingPbuid   : Sample(6),
      submittingPbuid  : Sample(6),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      ownerType        : Sample(2),
      clearingFirm     : Sample(2),
      transactTime     : Sample(8),
      userInfo         : Sample(32),
      orderId          : Sample(16),
      clOrdId          : Sample(10),
      execId           : Sample(16),
      execType         : Sample(1),
      ordStatus        : Sample(1),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      leavesQty        : Sample(8),
      cumQty           : Sample(8),
      side             : Sample(1),
      accountId        : Sample(10),
      branchId         : Sample(2),
      cashMargin       : Sample(1),
      settlType        : Sample(1),
      settlPeriod      : Sample(1) ]

EncodeBondSpotMatchingTradeExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.lastPx
        \o message.lastQty
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.accountId
        \o message.branchId
        \o message.cashMargin
        \o message.settlType
        \o message.settlPeriod

DecodeBondSpotMatchingTradeExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastPx == ReadBytes(ordStatus.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastQty.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET accountId == ReadBytes(side.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(branchId.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET settlType == ReadBytes(cashMargin.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    Ok([ partitionNo      |-> partitionNo.value,
         reportIndex      |-> reportIndex.value,
         applId           |-> applId.value,
         reportingPbuid   |-> reportingPbuid.value,
         submittingPbuid  |-> submittingPbuid.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         ownerType        |-> ownerType.value,
         clearingFirm     |-> clearingFirm.value,
         transactTime     |-> transactTime.value,
         userInfo         |-> userInfo.value,
         orderId          |-> orderId.value,
         clOrdId          |-> clOrdId.value,
         execId           |-> execId.value,
         execType         |-> execType.value,
         ordStatus        |-> ordStatus.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         leavesQty        |-> leavesQty.value,
         cumQty           |-> cumQty.value,
         side             |-> side.value,
         accountId        |-> accountId.value,
         branchId         |-> branchId.value,
         cashMargin       |-> cashMargin.value,
         settlType        |-> settlType.value,
         settlPeriod      |-> settlPeriod.value ], settlPeriod.rest)

ZeroBondSpotMatchingTradeExecutionReportMessage ==
    [ partitionNo      |-> [i \in 1 .. 4 |-> 0],
      reportIndex      |-> [i \in 1 .. 8 |-> 0],
      applId           |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid   |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid  |-> [i \in 1 .. 6 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      ownerType        |-> [i \in 1 .. 2 |-> 0],
      clearingFirm     |-> [i \in 1 .. 2 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userInfo         |-> [i \in 1 .. 32 |-> 0],
      orderId          |-> [i \in 1 .. 16 |-> 0],
      clOrdId          |-> [i \in 1 .. 10 |-> 0],
      execId           |-> [i \in 1 .. 16 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      ordStatus        |-> [i \in 1 .. 1 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      leavesQty        |-> [i \in 1 .. 8 |-> 0],
      cumQty           |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      accountId        |-> [i \in 1 .. 10 |-> 0],
      branchId         |-> [i \in 1 .. 2 |-> 0],
      cashMargin       |-> [i \in 1 .. 1 |-> 0],
      settlType        |-> [i \in 1 .. 1 |-> 0],
      settlPeriod      |-> [i \in 1 .. 1 |-> 0] ]

(* Bond Spot Matching Trade Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotMatchingTradeExecutionReportMessage ==
    { ZeroBondSpotMatchingTradeExecutionReportMessage }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotMatchingTradeExecutionReportMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }

(***************************************************************************)
(* Centralized Auction Trade Execution Report Message: 173 bytes           *)
(***************************************************************************)

CentralizedAuctionTradeExecutionReportMessage ==
    [ partitionNo      : Sample(4),
      reportIndex      : Sample(8),
      applId           : Sample(3),
      reportingPbuid   : Sample(6),
      submittingPbuid  : Sample(6),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      ownerType        : Sample(2),
      clearingFirm     : Sample(2),
      transactTime     : Sample(8),
      userInfo         : Sample(32),
      orderId          : Sample(16),
      clOrdId          : Sample(10),
      execId           : Sample(16),
      execType         : Sample(1),
      ordStatus        : Sample(1),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      leavesQty        : Sample(8),
      cumQty           : Sample(8),
      side             : Sample(1),
      accountId        : Sample(10),
      branchId         : Sample(2),
      cashMargin       : Sample(1) ]

EncodeCentralizedAuctionTradeExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.lastPx
        \o message.lastQty
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.accountId
        \o message.branchId
        \o message.cashMargin

DecodeCentralizedAuctionTradeExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastPx == ReadBytes(ordStatus.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastQty.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET accountId == ReadBytes(side.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(branchId.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ partitionNo      |-> partitionNo.value,
         reportIndex      |-> reportIndex.value,
         applId           |-> applId.value,
         reportingPbuid   |-> reportingPbuid.value,
         submittingPbuid  |-> submittingPbuid.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         ownerType        |-> ownerType.value,
         clearingFirm     |-> clearingFirm.value,
         transactTime     |-> transactTime.value,
         userInfo         |-> userInfo.value,
         orderId          |-> orderId.value,
         clOrdId          |-> clOrdId.value,
         execId           |-> execId.value,
         execType         |-> execType.value,
         ordStatus        |-> ordStatus.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         leavesQty        |-> leavesQty.value,
         cumQty           |-> cumQty.value,
         side             |-> side.value,
         accountId        |-> accountId.value,
         branchId         |-> branchId.value,
         cashMargin       |-> cashMargin.value ], cashMargin.rest)

ZeroCentralizedAuctionTradeExecutionReportMessage ==
    [ partitionNo      |-> [i \in 1 .. 4 |-> 0],
      reportIndex      |-> [i \in 1 .. 8 |-> 0],
      applId           |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid   |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid  |-> [i \in 1 .. 6 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      ownerType        |-> [i \in 1 .. 2 |-> 0],
      clearingFirm     |-> [i \in 1 .. 2 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userInfo         |-> [i \in 1 .. 32 |-> 0],
      orderId          |-> [i \in 1 .. 16 |-> 0],
      clOrdId          |-> [i \in 1 .. 10 |-> 0],
      execId           |-> [i \in 1 .. 16 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      ordStatus        |-> [i \in 1 .. 1 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      leavesQty        |-> [i \in 1 .. 8 |-> 0],
      cumQty           |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      accountId        |-> [i \in 1 .. 10 |-> 0],
      branchId         |-> [i \in 1 .. 2 |-> 0],
      cashMargin       |-> [i \in 1 .. 1 |-> 0] ]

(* Centralized Auction Trade Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedCentralizedAuctionTradeExecutionReportMessage ==
    { ZeroCentralizedAuctionTradeExecutionReportMessage }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroCentralizedAuctionTradeExecutionReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Refinancing Securities Lending Non Agreed Trade Execution Report        *)
(* Message: 181 bytes                                                      *)
(***************************************************************************)

RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage ==
    [ partitionNo      : Sample(4),
      reportIndex      : Sample(8),
      applId           : Sample(3),
      reportingPbuid   : Sample(6),
      submittingPbuid  : Sample(6),
      securityId       : Sample(8),
      securityIdSource : Sample(4),
      ownerType        : Sample(2),
      clearingFirm     : Sample(2),
      transactTime     : Sample(8),
      userInfo         : Sample(32),
      orderId          : Sample(16),
      clOrdId          : Sample(10),
      execId           : Sample(16),
      execType         : Sample(1),
      ordStatus        : Sample(1),
      lastPx           : Sample(8),
      lastQty          : Sample(8),
      leavesQty        : Sample(8),
      cumQty           : Sample(8),
      side             : Sample(1),
      accountId        : Sample(10),
      branchId         : Sample(2),
      expirationDays   : Sample(2),
      expirationType   : Sample(1),
      maturityDate     : Sample(4),
      shareProperty    : Sample(2) ]

EncodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.orderId
        \o message.clOrdId
        \o message.execId
        \o message.execType
        \o message.ordStatus
        \o message.lastPx
        \o message.lastQty
        \o message.leavesQty
        \o message.cumQty
        \o message.side
        \o message.accountId
        \o message.branchId
        \o message.expirationDays
        \o message.expirationType
        \o message.maturityDate
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET orderId == ReadBytes(userInfo.rest, 16) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 10) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET execType == ReadBytes(execId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execType.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET lastPx == ReadBytes(ordStatus.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastQty.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET side == ReadBytes(cumQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET accountId == ReadBytes(side.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(branchId.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(expirationType.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(maturityDate.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ partitionNo      |-> partitionNo.value,
         reportIndex      |-> reportIndex.value,
         applId           |-> applId.value,
         reportingPbuid   |-> reportingPbuid.value,
         submittingPbuid  |-> submittingPbuid.value,
         securityId       |-> securityId.value,
         securityIdSource |-> securityIdSource.value,
         ownerType        |-> ownerType.value,
         clearingFirm     |-> clearingFirm.value,
         transactTime     |-> transactTime.value,
         userInfo         |-> userInfo.value,
         orderId          |-> orderId.value,
         clOrdId          |-> clOrdId.value,
         execId           |-> execId.value,
         execType         |-> execType.value,
         ordStatus        |-> ordStatus.value,
         lastPx           |-> lastPx.value,
         lastQty          |-> lastQty.value,
         leavesQty        |-> leavesQty.value,
         cumQty           |-> cumQty.value,
         side             |-> side.value,
         accountId        |-> accountId.value,
         branchId         |-> branchId.value,
         expirationDays   |-> expirationDays.value,
         expirationType   |-> expirationType.value,
         maturityDate     |-> maturityDate.value,
         shareProperty    |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage ==
    [ partitionNo      |-> [i \in 1 .. 4 |-> 0],
      reportIndex      |-> [i \in 1 .. 8 |-> 0],
      applId           |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid   |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid  |-> [i \in 1 .. 6 |-> 0],
      securityId       |-> [i \in 1 .. 8 |-> 0],
      securityIdSource |-> [i \in 1 .. 4 |-> 0],
      ownerType        |-> [i \in 1 .. 2 |-> 0],
      clearingFirm     |-> [i \in 1 .. 2 |-> 0],
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userInfo         |-> [i \in 1 .. 32 |-> 0],
      orderId          |-> [i \in 1 .. 16 |-> 0],
      clOrdId          |-> [i \in 1 .. 10 |-> 0],
      execId           |-> [i \in 1 .. 16 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      ordStatus        |-> [i \in 1 .. 1 |-> 0],
      lastPx           |-> [i \in 1 .. 8 |-> 0],
      lastQty          |-> [i \in 1 .. 8 |-> 0],
      leavesQty        |-> [i \in 1 .. 8 |-> 0],
      cumQty           |-> [i \in 1 .. 8 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      accountId        |-> [i \in 1 .. 10 |-> 0],
      branchId         |-> [i \in 1 .. 2 |-> 0],
      expirationDays   |-> [i \in 1 .. 2 |-> 0],
      expirationType   |-> [i \in 1 .. 1 |-> 0],
      maturityDate     |-> [i \in 1 .. 4 |-> 0],
      shareProperty    |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Non Agreed Trade Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage ==
    { ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.clOrdId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Bond Spot Negotiated Trade Capture Report Message: 294 bytes            *)
(***************************************************************************)

BondSpotNegotiatedTradeCaptureReportMessage ==
    [ applId                 : Sample(3),
      submittingPbuid        : Sample(6),
      securityId             : Sample(8),
      securityIdSource       : Sample(4),
      ownerType              : Sample(2),
      clearingFirm           : Sample(2),
      transactTime           : Sample(8),
      userInfo               : Sample(32),
      tradeReportId          : Sample(10),
      tradeReportType        : Sample(1),
      tradeReportTransType   : Sample(1),
      tradeHandlingInstr     : Sample(1),
      tradeReportRefId       : Sample(10),
      lastPx                 : Sample(8),
      lastQty                : Sample(8),
      trdType                : Sample(2),
      trdSubType             : Sample(2),
      confirmId              : Sample(4),
      side                   : Sample(1),
      pbuid                  : Sample(6),
      accountId              : Sample(10),
      branchId               : Sample(2),
      counterpartyPbuid      : Sample(6),
      counterpartyAccountId  : Sample(10),
      counterpartyBranchId   : Sample(2),
      memberId               : Sample(6),
      traderCode             : Sample(5),
      counterpartyMemberId   : Sample(6),
      counterpartyTraderCode : Sample(5),
      settlType              : Sample(1),
      settlPeriod            : Sample(1),
      cashMargin             : Sample(1),
      memo                   : Sample(120) ]

EncodeBondSpotNegotiatedTradeCaptureReportMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.memberId
        \o message.traderCode
        \o message.counterpartyMemberId
        \o message.counterpartyTraderCode
        \o message.settlType
        \o message.settlPeriod
        \o message.cashMargin
        \o message.memo

DecodeBondSpotNegotiatedTradeCaptureReportMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(userInfo.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET side == ReadBytes(confirmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET memberId == ReadBytes(counterpartyBranchId.rest, 6) IN IF ~memberId.ok THEN Fail ELSE
    LET traderCode == ReadBytes(memberId.rest, 5) IN IF ~traderCode.ok THEN Fail ELSE
    LET counterpartyMemberId == ReadBytes(traderCode.rest, 6) IN IF ~counterpartyMemberId.ok THEN Fail ELSE
    LET counterpartyTraderCode == ReadBytes(counterpartyMemberId.rest, 5) IN IF ~counterpartyTraderCode.ok THEN Fail ELSE
    LET settlType == ReadBytes(counterpartyTraderCode.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(settlPeriod.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET memo == ReadBytes(cashMargin.rest, 120) IN IF ~memo.ok THEN Fail ELSE
    Ok([ applId                 |-> applId.value,
         submittingPbuid        |-> submittingPbuid.value,
         securityId             |-> securityId.value,
         securityIdSource       |-> securityIdSource.value,
         ownerType              |-> ownerType.value,
         clearingFirm           |-> clearingFirm.value,
         transactTime           |-> transactTime.value,
         userInfo               |-> userInfo.value,
         tradeReportId          |-> tradeReportId.value,
         tradeReportType        |-> tradeReportType.value,
         tradeReportTransType   |-> tradeReportTransType.value,
         tradeHandlingInstr     |-> tradeHandlingInstr.value,
         tradeReportRefId       |-> tradeReportRefId.value,
         lastPx                 |-> lastPx.value,
         lastQty                |-> lastQty.value,
         trdType                |-> trdType.value,
         trdSubType             |-> trdSubType.value,
         confirmId              |-> confirmId.value,
         side                   |-> side.value,
         pbuid                  |-> pbuid.value,
         accountId              |-> accountId.value,
         branchId               |-> branchId.value,
         counterpartyPbuid      |-> counterpartyPbuid.value,
         counterpartyAccountId  |-> counterpartyAccountId.value,
         counterpartyBranchId   |-> counterpartyBranchId.value,
         memberId               |-> memberId.value,
         traderCode             |-> traderCode.value,
         counterpartyMemberId   |-> counterpartyMemberId.value,
         counterpartyTraderCode |-> counterpartyTraderCode.value,
         settlType              |-> settlType.value,
         settlPeriod            |-> settlPeriod.value,
         cashMargin             |-> cashMargin.value,
         memo                   |-> memo.value ], memo.rest)

ZeroBondSpotNegotiatedTradeCaptureReportMessage ==
    [ applId                 |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid        |-> [i \in 1 .. 6 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      securityIdSource       |-> [i \in 1 .. 4 |-> 0],
      ownerType              |-> [i \in 1 .. 2 |-> 0],
      clearingFirm           |-> [i \in 1 .. 2 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      userInfo               |-> [i \in 1 .. 32 |-> 0],
      tradeReportId          |-> [i \in 1 .. 10 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType   |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr     |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId       |-> [i \in 1 .. 10 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastQty                |-> [i \in 1 .. 8 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      trdSubType             |-> [i \in 1 .. 2 |-> 0],
      confirmId              |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      pbuid                  |-> [i \in 1 .. 6 |-> 0],
      accountId              |-> [i \in 1 .. 10 |-> 0],
      branchId               |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid      |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId  |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId   |-> [i \in 1 .. 2 |-> 0],
      memberId               |-> [i \in 1 .. 6 |-> 0],
      traderCode             |-> [i \in 1 .. 5 |-> 0],
      counterpartyMemberId   |-> [i \in 1 .. 6 |-> 0],
      counterpartyTraderCode |-> [i \in 1 .. 5 |-> 0],
      settlType              |-> [i \in 1 .. 1 |-> 0],
      settlPeriod            |-> [i \in 1 .. 1 |-> 0],
      cashMargin             |-> [i \in 1 .. 1 |-> 0],
      memo                   |-> [i \in 1 .. 120 |-> 0] ]

(* Bond Spot Negotiated Trade Capture Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotNegotiatedTradeCaptureReportMessage ==
    { ZeroBondSpotNegotiatedTradeCaptureReportMessage }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.memberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.traderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.counterpartyMemberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.counterpartyTraderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportMessage EXCEPT !.memo = one] : one \in Sample(120) }

(***************************************************************************)
(* Refinancing Securities Lending Agreed Trade Capture Report Message: 154 *)
(* bytes                                                                   *)
(***************************************************************************)

RefinancingSecuritiesLendingAgreedTradeCaptureReportMessage ==
    [ applId                : Sample(3),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      tradeReportRefId      : Sample(10),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2),
      expirationDays        : Sample(2),
      expirationType        : Sample(1),
      shareProperty         : Sample(2) ]

EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.expirationDays
        \o message.expirationType
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(userInfo.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET side == ReadBytes(confirmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(counterpartyBranchId.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(expirationType.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ applId                |-> applId.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         tradeReportRefId      |-> tradeReportRefId.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value,
         expirationDays        |-> expirationDays.value,
         expirationType        |-> expirationType.value,
         shareProperty         |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage ==
    [ applId                |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId      |-> [i \in 1 .. 10 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0],
      expirationDays        |-> [i \in 1 .. 2 |-> 0],
      expirationType        |-> [i \in 1 .. 1 |-> 0],
      shareProperty         |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Agreed Trade Capture Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage ==
    { ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Mutual Trade Confirmation Trade Capture Report Message: 149 bytes       *)
(***************************************************************************)

MutualTradeConfirmationTradeCaptureReportMessage ==
    [ applId                : Sample(3),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      tradeReportRefId      : Sample(10),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2) ]

EncodeMutualTradeConfirmationTradeCaptureReportMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMutualTradeConfirmationTradeCaptureReportMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(userInfo.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET side == ReadBytes(confirmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ applId                |-> applId.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         tradeReportRefId      |-> tradeReportRefId.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMutualTradeConfirmationTradeCaptureReportMessage ==
    [ applId                |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId      |-> [i \in 1 .. 10 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0] ]

(* Mutual Trade Confirmation Trade Capture Report Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualTradeConfirmationTradeCaptureReportMessage ==
    { ZeroMutualTradeConfirmationTradeCaptureReportMessage }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Making Mutual Trade Confirmation Trade Capture Report Message:   *)
(* 149 bytes                                                               *)
(***************************************************************************)

MarketMakingMutualTradeConfirmationTradeCaptureReportMessage ==
    [ applId                : Sample(3),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      tradeReportRefId      : Sample(10),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2) ]

EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(userInfo.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET side == ReadBytes(confirmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ applId                |-> applId.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         tradeReportRefId      |-> tradeReportRefId.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage ==
    [ applId                |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId      |-> [i \in 1 .. 10 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0] ]

(* Market Making Mutual Trade Confirmation Trade Capture Report Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportMessage ==
    { ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* After Hours Block Trade Trade Capture Report Message: 150 bytes         *)
(***************************************************************************)

AfterHoursBlockTradeTradeCaptureReportMessage ==
    [ applId                : Sample(3),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      tradeReportRefId      : Sample(10),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2),
      cashMargin            : Sample(1) ]

EncodeAfterHoursBlockTradeTradeCaptureReportMessage(message) ==
    message.applId
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.cashMargin

DecodeAfterHoursBlockTradeTradeCaptureReportMessage(bytes) ==
    LET applId == ReadBytes(bytes, 3) IN IF ~applId.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(applId.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(userInfo.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRefId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET side == ReadBytes(confirmId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(counterpartyBranchId.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ applId                |-> applId.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         tradeReportRefId      |-> tradeReportRefId.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value,
         cashMargin            |-> cashMargin.value ], cashMargin.rest)

ZeroAfterHoursBlockTradeTradeCaptureReportMessage ==
    [ applId                |-> [i \in 1 .. 3 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId      |-> [i \in 1 .. 10 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0],
      cashMargin            |-> [i \in 1 .. 1 |-> 0] ]

(* After Hours Block Trade Trade Capture Report Message at zero, then each field in turn at the values it is checked at *)
CheckedAfterHoursBlockTradeTradeCaptureReportMessage ==
    { ZeroAfterHoursBlockTradeTradeCaptureReportMessage }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Spot Negotiated Trade Capture Report Ack Message: 348 bytes        *)
(***************************************************************************)

BondSpotNegotiatedTradeCaptureReportAckMessage ==
    [ partitionNo             : Sample(4),
      reportIndex             : Sample(8),
      applId                  : Sample(3),
      reportingPbuid          : Sample(6),
      submittingPbuid         : Sample(6),
      securityId              : Sample(8),
      securityIdSource        : Sample(4),
      ownerType               : Sample(2),
      clearingFirm            : Sample(2),
      transactTime            : Sample(8),
      userInfo                : Sample(32),
      tradeId                 : Sample(16),
      tradeReportId           : Sample(10),
      tradeReportType         : Sample(1),
      tradeReportTransType    : Sample(1),
      tradeHandlingInstr      : Sample(1),
      tradeReportRefId        : Sample(10),
      trdAckStatus            : Sample(1),
      trdRptStatus            : Sample(1),
      tradeReportRejectReason : Sample(2),
      lastPx                  : Sample(8),
      lastQty                 : Sample(8),
      trdType                 : Sample(2),
      trdSubType              : Sample(2),
      confirmId               : Sample(4),
      execId                  : Sample(16),
      side                    : Sample(1),
      pbuid                   : Sample(6),
      accountId               : Sample(10),
      branchId                : Sample(2),
      counterpartyPbuid       : Sample(6),
      counterpartyAccountId   : Sample(10),
      counterpartyBranchId    : Sample(2),
      memberId                : Sample(6),
      traderCode              : Sample(5),
      counterpartyMemberId    : Sample(6),
      counterpartyTraderCode  : Sample(5),
      settlType               : Sample(1),
      settlPeriod             : Sample(1),
      cashMargin              : Sample(1),
      memo                    : Sample(120) ]

EncodeBondSpotNegotiatedTradeCaptureReportAckMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.trdAckStatus
        \o message.trdRptStatus
        \o message.tradeReportRejectReason
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.memberId
        \o message.traderCode
        \o message.counterpartyMemberId
        \o message.counterpartyTraderCode
        \o message.settlType
        \o message.settlPeriod
        \o message.cashMargin
        \o message.memo

DecodeBondSpotNegotiatedTradeCaptureReportAckMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET trdAckStatus == ReadBytes(tradeReportRefId.rest, 1) IN IF ~trdAckStatus.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(trdAckStatus.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradeReportRejectReason == ReadBytes(trdRptStatus.rest, 2) IN IF ~tradeReportRejectReason.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRejectReason.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET memberId == ReadBytes(counterpartyBranchId.rest, 6) IN IF ~memberId.ok THEN Fail ELSE
    LET traderCode == ReadBytes(memberId.rest, 5) IN IF ~traderCode.ok THEN Fail ELSE
    LET counterpartyMemberId == ReadBytes(traderCode.rest, 6) IN IF ~counterpartyMemberId.ok THEN Fail ELSE
    LET counterpartyTraderCode == ReadBytes(counterpartyMemberId.rest, 5) IN IF ~counterpartyTraderCode.ok THEN Fail ELSE
    LET settlType == ReadBytes(counterpartyTraderCode.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(settlPeriod.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET memo == ReadBytes(cashMargin.rest, 120) IN IF ~memo.ok THEN Fail ELSE
    Ok([ partitionNo             |-> partitionNo.value,
         reportIndex             |-> reportIndex.value,
         applId                  |-> applId.value,
         reportingPbuid          |-> reportingPbuid.value,
         submittingPbuid         |-> submittingPbuid.value,
         securityId              |-> securityId.value,
         securityIdSource        |-> securityIdSource.value,
         ownerType               |-> ownerType.value,
         clearingFirm            |-> clearingFirm.value,
         transactTime            |-> transactTime.value,
         userInfo                |-> userInfo.value,
         tradeId                 |-> tradeId.value,
         tradeReportId           |-> tradeReportId.value,
         tradeReportType         |-> tradeReportType.value,
         tradeReportTransType    |-> tradeReportTransType.value,
         tradeHandlingInstr      |-> tradeHandlingInstr.value,
         tradeReportRefId        |-> tradeReportRefId.value,
         trdAckStatus            |-> trdAckStatus.value,
         trdRptStatus            |-> trdRptStatus.value,
         tradeReportRejectReason |-> tradeReportRejectReason.value,
         lastPx                  |-> lastPx.value,
         lastQty                 |-> lastQty.value,
         trdType                 |-> trdType.value,
         trdSubType              |-> trdSubType.value,
         confirmId               |-> confirmId.value,
         execId                  |-> execId.value,
         side                    |-> side.value,
         pbuid                   |-> pbuid.value,
         accountId               |-> accountId.value,
         branchId                |-> branchId.value,
         counterpartyPbuid       |-> counterpartyPbuid.value,
         counterpartyAccountId   |-> counterpartyAccountId.value,
         counterpartyBranchId    |-> counterpartyBranchId.value,
         memberId                |-> memberId.value,
         traderCode              |-> traderCode.value,
         counterpartyMemberId    |-> counterpartyMemberId.value,
         counterpartyTraderCode  |-> counterpartyTraderCode.value,
         settlType               |-> settlType.value,
         settlPeriod             |-> settlPeriod.value,
         cashMargin              |-> cashMargin.value,
         memo                    |-> memo.value ], memo.rest)

ZeroBondSpotNegotiatedTradeCaptureReportAckMessage ==
    [ partitionNo             |-> [i \in 1 .. 4 |-> 0],
      reportIndex             |-> [i \in 1 .. 8 |-> 0],
      applId                  |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid          |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid         |-> [i \in 1 .. 6 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      securityIdSource        |-> [i \in 1 .. 4 |-> 0],
      ownerType               |-> [i \in 1 .. 2 |-> 0],
      clearingFirm            |-> [i \in 1 .. 2 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      userInfo                |-> [i \in 1 .. 32 |-> 0],
      tradeId                 |-> [i \in 1 .. 16 |-> 0],
      tradeReportId           |-> [i \in 1 .. 10 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType    |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr      |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId        |-> [i \in 1 .. 10 |-> 0],
      trdAckStatus            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeReportRejectReason |-> [i \in 1 .. 2 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                 |-> [i \in 1 .. 8 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      trdSubType              |-> [i \in 1 .. 2 |-> 0],
      confirmId               |-> [i \in 1 .. 4 |-> 0],
      execId                  |-> [i \in 1 .. 16 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pbuid                   |-> [i \in 1 .. 6 |-> 0],
      accountId               |-> [i \in 1 .. 10 |-> 0],
      branchId                |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid       |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId   |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId    |-> [i \in 1 .. 2 |-> 0],
      memberId                |-> [i \in 1 .. 6 |-> 0],
      traderCode              |-> [i \in 1 .. 5 |-> 0],
      counterpartyMemberId    |-> [i \in 1 .. 6 |-> 0],
      counterpartyTraderCode  |-> [i \in 1 .. 5 |-> 0],
      settlType               |-> [i \in 1 .. 1 |-> 0],
      settlPeriod             |-> [i \in 1 .. 1 |-> 0],
      cashMargin              |-> [i \in 1 .. 1 |-> 0],
      memo                    |-> [i \in 1 .. 120 |-> 0] ]

(* Bond Spot Negotiated Trade Capture Report Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotNegotiatedTradeCaptureReportAckMessage ==
    { ZeroBondSpotNegotiatedTradeCaptureReportAckMessage }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.trdAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.tradeReportRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.memberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.traderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.counterpartyMemberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.counterpartyTraderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportAckMessage EXCEPT !.memo = one] : one \in Sample(120) }

(***************************************************************************)
(* Refinancing Securities Lending Agreed Trade Capture Report Ack Message: *)
(* 208 bytes                                                               *)
(***************************************************************************)

RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage ==
    [ partitionNo             : Sample(4),
      reportIndex             : Sample(8),
      applId                  : Sample(3),
      reportingPbuid          : Sample(6),
      submittingPbuid         : Sample(6),
      securityId              : Sample(8),
      securityIdSource        : Sample(4),
      ownerType               : Sample(2),
      clearingFirm            : Sample(2),
      transactTime            : Sample(8),
      userInfo                : Sample(32),
      tradeId                 : Sample(16),
      tradeReportId           : Sample(10),
      tradeReportType         : Sample(1),
      tradeReportTransType    : Sample(1),
      tradeHandlingInstr      : Sample(1),
      tradeReportRefId        : Sample(10),
      trdAckStatus            : Sample(1),
      trdRptStatus            : Sample(1),
      tradeReportRejectReason : Sample(2),
      lastPx                  : Sample(8),
      lastQty                 : Sample(8),
      trdType                 : Sample(2),
      trdSubType              : Sample(2),
      confirmId               : Sample(4),
      execId                  : Sample(16),
      side                    : Sample(1),
      pbuid                   : Sample(6),
      accountId               : Sample(10),
      branchId                : Sample(2),
      counterpartyPbuid       : Sample(6),
      counterpartyAccountId   : Sample(10),
      counterpartyBranchId    : Sample(2),
      expirationDays          : Sample(2),
      expirationType          : Sample(1),
      shareProperty           : Sample(2) ]

EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.trdAckStatus
        \o message.trdRptStatus
        \o message.tradeReportRejectReason
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.expirationDays
        \o message.expirationType
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET trdAckStatus == ReadBytes(tradeReportRefId.rest, 1) IN IF ~trdAckStatus.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(trdAckStatus.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradeReportRejectReason == ReadBytes(trdRptStatus.rest, 2) IN IF ~tradeReportRejectReason.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRejectReason.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(counterpartyBranchId.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(expirationType.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ partitionNo             |-> partitionNo.value,
         reportIndex             |-> reportIndex.value,
         applId                  |-> applId.value,
         reportingPbuid          |-> reportingPbuid.value,
         submittingPbuid         |-> submittingPbuid.value,
         securityId              |-> securityId.value,
         securityIdSource        |-> securityIdSource.value,
         ownerType               |-> ownerType.value,
         clearingFirm            |-> clearingFirm.value,
         transactTime            |-> transactTime.value,
         userInfo                |-> userInfo.value,
         tradeId                 |-> tradeId.value,
         tradeReportId           |-> tradeReportId.value,
         tradeReportType         |-> tradeReportType.value,
         tradeReportTransType    |-> tradeReportTransType.value,
         tradeHandlingInstr      |-> tradeHandlingInstr.value,
         tradeReportRefId        |-> tradeReportRefId.value,
         trdAckStatus            |-> trdAckStatus.value,
         trdRptStatus            |-> trdRptStatus.value,
         tradeReportRejectReason |-> tradeReportRejectReason.value,
         lastPx                  |-> lastPx.value,
         lastQty                 |-> lastQty.value,
         trdType                 |-> trdType.value,
         trdSubType              |-> trdSubType.value,
         confirmId               |-> confirmId.value,
         execId                  |-> execId.value,
         side                    |-> side.value,
         pbuid                   |-> pbuid.value,
         accountId               |-> accountId.value,
         branchId                |-> branchId.value,
         counterpartyPbuid       |-> counterpartyPbuid.value,
         counterpartyAccountId   |-> counterpartyAccountId.value,
         counterpartyBranchId    |-> counterpartyBranchId.value,
         expirationDays          |-> expirationDays.value,
         expirationType          |-> expirationType.value,
         shareProperty           |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage ==
    [ partitionNo             |-> [i \in 1 .. 4 |-> 0],
      reportIndex             |-> [i \in 1 .. 8 |-> 0],
      applId                  |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid          |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid         |-> [i \in 1 .. 6 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      securityIdSource        |-> [i \in 1 .. 4 |-> 0],
      ownerType               |-> [i \in 1 .. 2 |-> 0],
      clearingFirm            |-> [i \in 1 .. 2 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      userInfo                |-> [i \in 1 .. 32 |-> 0],
      tradeId                 |-> [i \in 1 .. 16 |-> 0],
      tradeReportId           |-> [i \in 1 .. 10 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType    |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr      |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId        |-> [i \in 1 .. 10 |-> 0],
      trdAckStatus            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeReportRejectReason |-> [i \in 1 .. 2 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                 |-> [i \in 1 .. 8 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      trdSubType              |-> [i \in 1 .. 2 |-> 0],
      confirmId               |-> [i \in 1 .. 4 |-> 0],
      execId                  |-> [i \in 1 .. 16 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pbuid                   |-> [i \in 1 .. 6 |-> 0],
      accountId               |-> [i \in 1 .. 10 |-> 0],
      branchId                |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid       |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId   |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId    |-> [i \in 1 .. 2 |-> 0],
      expirationDays          |-> [i \in 1 .. 2 |-> 0],
      expirationType          |-> [i \in 1 .. 1 |-> 0],
      shareProperty           |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Agreed Trade Capture Report Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage ==
    { ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.trdAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.tradeReportRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Mutual Trade Confirmation Trade Capture Report Ack Message: 203 bytes   *)
(***************************************************************************)

MutualTradeConfirmationTradeCaptureReportAckMessage ==
    [ partitionNo             : Sample(4),
      reportIndex             : Sample(8),
      applId                  : Sample(3),
      reportingPbuid          : Sample(6),
      submittingPbuid         : Sample(6),
      securityId              : Sample(8),
      securityIdSource        : Sample(4),
      ownerType               : Sample(2),
      clearingFirm            : Sample(2),
      transactTime            : Sample(8),
      userInfo                : Sample(32),
      tradeId                 : Sample(16),
      tradeReportId           : Sample(10),
      tradeReportType         : Sample(1),
      tradeReportTransType    : Sample(1),
      tradeHandlingInstr      : Sample(1),
      tradeReportRefId        : Sample(10),
      trdAckStatus            : Sample(1),
      trdRptStatus            : Sample(1),
      tradeReportRejectReason : Sample(2),
      lastPx                  : Sample(8),
      lastQty                 : Sample(8),
      trdType                 : Sample(2),
      trdSubType              : Sample(2),
      confirmId               : Sample(4),
      execId                  : Sample(16),
      side                    : Sample(1),
      pbuid                   : Sample(6),
      accountId               : Sample(10),
      branchId                : Sample(2),
      counterpartyPbuid       : Sample(6),
      counterpartyAccountId   : Sample(10),
      counterpartyBranchId    : Sample(2) ]

EncodeMutualTradeConfirmationTradeCaptureReportAckMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.trdAckStatus
        \o message.trdRptStatus
        \o message.tradeReportRejectReason
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMutualTradeConfirmationTradeCaptureReportAckMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET trdAckStatus == ReadBytes(tradeReportRefId.rest, 1) IN IF ~trdAckStatus.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(trdAckStatus.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradeReportRejectReason == ReadBytes(trdRptStatus.rest, 2) IN IF ~tradeReportRejectReason.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRejectReason.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ partitionNo             |-> partitionNo.value,
         reportIndex             |-> reportIndex.value,
         applId                  |-> applId.value,
         reportingPbuid          |-> reportingPbuid.value,
         submittingPbuid         |-> submittingPbuid.value,
         securityId              |-> securityId.value,
         securityIdSource        |-> securityIdSource.value,
         ownerType               |-> ownerType.value,
         clearingFirm            |-> clearingFirm.value,
         transactTime            |-> transactTime.value,
         userInfo                |-> userInfo.value,
         tradeId                 |-> tradeId.value,
         tradeReportId           |-> tradeReportId.value,
         tradeReportType         |-> tradeReportType.value,
         tradeReportTransType    |-> tradeReportTransType.value,
         tradeHandlingInstr      |-> tradeHandlingInstr.value,
         tradeReportRefId        |-> tradeReportRefId.value,
         trdAckStatus            |-> trdAckStatus.value,
         trdRptStatus            |-> trdRptStatus.value,
         tradeReportRejectReason |-> tradeReportRejectReason.value,
         lastPx                  |-> lastPx.value,
         lastQty                 |-> lastQty.value,
         trdType                 |-> trdType.value,
         trdSubType              |-> trdSubType.value,
         confirmId               |-> confirmId.value,
         execId                  |-> execId.value,
         side                    |-> side.value,
         pbuid                   |-> pbuid.value,
         accountId               |-> accountId.value,
         branchId                |-> branchId.value,
         counterpartyPbuid       |-> counterpartyPbuid.value,
         counterpartyAccountId   |-> counterpartyAccountId.value,
         counterpartyBranchId    |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMutualTradeConfirmationTradeCaptureReportAckMessage ==
    [ partitionNo             |-> [i \in 1 .. 4 |-> 0],
      reportIndex             |-> [i \in 1 .. 8 |-> 0],
      applId                  |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid          |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid         |-> [i \in 1 .. 6 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      securityIdSource        |-> [i \in 1 .. 4 |-> 0],
      ownerType               |-> [i \in 1 .. 2 |-> 0],
      clearingFirm            |-> [i \in 1 .. 2 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      userInfo                |-> [i \in 1 .. 32 |-> 0],
      tradeId                 |-> [i \in 1 .. 16 |-> 0],
      tradeReportId           |-> [i \in 1 .. 10 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType    |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr      |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId        |-> [i \in 1 .. 10 |-> 0],
      trdAckStatus            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeReportRejectReason |-> [i \in 1 .. 2 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                 |-> [i \in 1 .. 8 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      trdSubType              |-> [i \in 1 .. 2 |-> 0],
      confirmId               |-> [i \in 1 .. 4 |-> 0],
      execId                  |-> [i \in 1 .. 16 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pbuid                   |-> [i \in 1 .. 6 |-> 0],
      accountId               |-> [i \in 1 .. 10 |-> 0],
      branchId                |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid       |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId   |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId    |-> [i \in 1 .. 2 |-> 0] ]

(* Mutual Trade Confirmation Trade Capture Report Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualTradeConfirmationTradeCaptureReportAckMessage ==
    { ZeroMutualTradeConfirmationTradeCaptureReportAckMessage }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Making Mutual Trade Confirmation Trade Capture Report Ack        *)
(* Message: 203 bytes                                                      *)
(***************************************************************************)

MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage ==
    [ partitionNo             : Sample(4),
      reportIndex             : Sample(8),
      applId                  : Sample(3),
      reportingPbuid          : Sample(6),
      submittingPbuid         : Sample(6),
      securityId              : Sample(8),
      securityIdSource        : Sample(4),
      ownerType               : Sample(2),
      clearingFirm            : Sample(2),
      transactTime            : Sample(8),
      userInfo                : Sample(32),
      tradeId                 : Sample(16),
      tradeReportId           : Sample(10),
      tradeReportType         : Sample(1),
      tradeReportTransType    : Sample(1),
      tradeHandlingInstr      : Sample(1),
      tradeReportRefId        : Sample(10),
      trdAckStatus            : Sample(1),
      trdRptStatus            : Sample(1),
      tradeReportRejectReason : Sample(2),
      lastPx                  : Sample(8),
      lastQty                 : Sample(8),
      trdType                 : Sample(2),
      trdSubType              : Sample(2),
      confirmId               : Sample(4),
      execId                  : Sample(16),
      side                    : Sample(1),
      pbuid                   : Sample(6),
      accountId               : Sample(10),
      branchId                : Sample(2),
      counterpartyPbuid       : Sample(6),
      counterpartyAccountId   : Sample(10),
      counterpartyBranchId    : Sample(2) ]

EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.trdAckStatus
        \o message.trdRptStatus
        \o message.tradeReportRejectReason
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET trdAckStatus == ReadBytes(tradeReportRefId.rest, 1) IN IF ~trdAckStatus.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(trdAckStatus.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradeReportRejectReason == ReadBytes(trdRptStatus.rest, 2) IN IF ~tradeReportRejectReason.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRejectReason.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ partitionNo             |-> partitionNo.value,
         reportIndex             |-> reportIndex.value,
         applId                  |-> applId.value,
         reportingPbuid          |-> reportingPbuid.value,
         submittingPbuid         |-> submittingPbuid.value,
         securityId              |-> securityId.value,
         securityIdSource        |-> securityIdSource.value,
         ownerType               |-> ownerType.value,
         clearingFirm            |-> clearingFirm.value,
         transactTime            |-> transactTime.value,
         userInfo                |-> userInfo.value,
         tradeId                 |-> tradeId.value,
         tradeReportId           |-> tradeReportId.value,
         tradeReportType         |-> tradeReportType.value,
         tradeReportTransType    |-> tradeReportTransType.value,
         tradeHandlingInstr      |-> tradeHandlingInstr.value,
         tradeReportRefId        |-> tradeReportRefId.value,
         trdAckStatus            |-> trdAckStatus.value,
         trdRptStatus            |-> trdRptStatus.value,
         tradeReportRejectReason |-> tradeReportRejectReason.value,
         lastPx                  |-> lastPx.value,
         lastQty                 |-> lastQty.value,
         trdType                 |-> trdType.value,
         trdSubType              |-> trdSubType.value,
         confirmId               |-> confirmId.value,
         execId                  |-> execId.value,
         side                    |-> side.value,
         pbuid                   |-> pbuid.value,
         accountId               |-> accountId.value,
         branchId                |-> branchId.value,
         counterpartyPbuid       |-> counterpartyPbuid.value,
         counterpartyAccountId   |-> counterpartyAccountId.value,
         counterpartyBranchId    |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage ==
    [ partitionNo             |-> [i \in 1 .. 4 |-> 0],
      reportIndex             |-> [i \in 1 .. 8 |-> 0],
      applId                  |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid          |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid         |-> [i \in 1 .. 6 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      securityIdSource        |-> [i \in 1 .. 4 |-> 0],
      ownerType               |-> [i \in 1 .. 2 |-> 0],
      clearingFirm            |-> [i \in 1 .. 2 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      userInfo                |-> [i \in 1 .. 32 |-> 0],
      tradeId                 |-> [i \in 1 .. 16 |-> 0],
      tradeReportId           |-> [i \in 1 .. 10 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType    |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr      |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId        |-> [i \in 1 .. 10 |-> 0],
      trdAckStatus            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeReportRejectReason |-> [i \in 1 .. 2 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                 |-> [i \in 1 .. 8 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      trdSubType              |-> [i \in 1 .. 2 |-> 0],
      confirmId               |-> [i \in 1 .. 4 |-> 0],
      execId                  |-> [i \in 1 .. 16 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pbuid                   |-> [i \in 1 .. 6 |-> 0],
      accountId               |-> [i \in 1 .. 10 |-> 0],
      branchId                |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid       |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId   |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId    |-> [i \in 1 .. 2 |-> 0] ]

(* Market Making Mutual Trade Confirmation Trade Capture Report Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage ==
    { ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.tradeReportRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* After Hours Block Trade Trade Capture Report Ack Message: 204 bytes     *)
(***************************************************************************)

AfterHoursBlockTradeTradeCaptureReportAckMessage ==
    [ partitionNo             : Sample(4),
      reportIndex             : Sample(8),
      applId                  : Sample(3),
      reportingPbuid          : Sample(6),
      submittingPbuid         : Sample(6),
      securityId              : Sample(8),
      securityIdSource        : Sample(4),
      ownerType               : Sample(2),
      clearingFirm            : Sample(2),
      transactTime            : Sample(8),
      userInfo                : Sample(32),
      tradeId                 : Sample(16),
      tradeReportId           : Sample(10),
      tradeReportType         : Sample(1),
      tradeReportTransType    : Sample(1),
      tradeHandlingInstr      : Sample(1),
      tradeReportRefId        : Sample(10),
      trdAckStatus            : Sample(1),
      trdRptStatus            : Sample(1),
      tradeReportRejectReason : Sample(2),
      lastPx                  : Sample(8),
      lastQty                 : Sample(8),
      trdType                 : Sample(2),
      trdSubType              : Sample(2),
      confirmId               : Sample(4),
      execId                  : Sample(16),
      side                    : Sample(1),
      pbuid                   : Sample(6),
      accountId               : Sample(10),
      branchId                : Sample(2),
      counterpartyPbuid       : Sample(6),
      counterpartyAccountId   : Sample(10),
      counterpartyBranchId    : Sample(2),
      cashMargin              : Sample(1) ]

EncodeAfterHoursBlockTradeTradeCaptureReportAckMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.tradeReportRefId
        \o message.trdAckStatus
        \o message.trdRptStatus
        \o message.tradeReportRejectReason
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.cashMargin

DecodeAfterHoursBlockTradeTradeCaptureReportAckMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET tradeReportRefId == ReadBytes(tradeHandlingInstr.rest, 10) IN IF ~tradeReportRefId.ok THEN Fail ELSE
    LET trdAckStatus == ReadBytes(tradeReportRefId.rest, 1) IN IF ~trdAckStatus.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(trdAckStatus.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET tradeReportRejectReason == ReadBytes(trdRptStatus.rest, 2) IN IF ~tradeReportRejectReason.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeReportRejectReason.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(counterpartyBranchId.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ partitionNo             |-> partitionNo.value,
         reportIndex             |-> reportIndex.value,
         applId                  |-> applId.value,
         reportingPbuid          |-> reportingPbuid.value,
         submittingPbuid         |-> submittingPbuid.value,
         securityId              |-> securityId.value,
         securityIdSource        |-> securityIdSource.value,
         ownerType               |-> ownerType.value,
         clearingFirm            |-> clearingFirm.value,
         transactTime            |-> transactTime.value,
         userInfo                |-> userInfo.value,
         tradeId                 |-> tradeId.value,
         tradeReportId           |-> tradeReportId.value,
         tradeReportType         |-> tradeReportType.value,
         tradeReportTransType    |-> tradeReportTransType.value,
         tradeHandlingInstr      |-> tradeHandlingInstr.value,
         tradeReportRefId        |-> tradeReportRefId.value,
         trdAckStatus            |-> trdAckStatus.value,
         trdRptStatus            |-> trdRptStatus.value,
         tradeReportRejectReason |-> tradeReportRejectReason.value,
         lastPx                  |-> lastPx.value,
         lastQty                 |-> lastQty.value,
         trdType                 |-> trdType.value,
         trdSubType              |-> trdSubType.value,
         confirmId               |-> confirmId.value,
         execId                  |-> execId.value,
         side                    |-> side.value,
         pbuid                   |-> pbuid.value,
         accountId               |-> accountId.value,
         branchId                |-> branchId.value,
         counterpartyPbuid       |-> counterpartyPbuid.value,
         counterpartyAccountId   |-> counterpartyAccountId.value,
         counterpartyBranchId    |-> counterpartyBranchId.value,
         cashMargin              |-> cashMargin.value ], cashMargin.rest)

ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage ==
    [ partitionNo             |-> [i \in 1 .. 4 |-> 0],
      reportIndex             |-> [i \in 1 .. 8 |-> 0],
      applId                  |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid          |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid         |-> [i \in 1 .. 6 |-> 0],
      securityId              |-> [i \in 1 .. 8 |-> 0],
      securityIdSource        |-> [i \in 1 .. 4 |-> 0],
      ownerType               |-> [i \in 1 .. 2 |-> 0],
      clearingFirm            |-> [i \in 1 .. 2 |-> 0],
      transactTime            |-> [i \in 1 .. 8 |-> 0],
      userInfo                |-> [i \in 1 .. 32 |-> 0],
      tradeId                 |-> [i \in 1 .. 16 |-> 0],
      tradeReportId           |-> [i \in 1 .. 10 |-> 0],
      tradeReportType         |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType    |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr      |-> [i \in 1 .. 1 |-> 0],
      tradeReportRefId        |-> [i \in 1 .. 10 |-> 0],
      trdAckStatus            |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus            |-> [i \in 1 .. 1 |-> 0],
      tradeReportRejectReason |-> [i \in 1 .. 2 |-> 0],
      lastPx                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                 |-> [i \in 1 .. 8 |-> 0],
      trdType                 |-> [i \in 1 .. 2 |-> 0],
      trdSubType              |-> [i \in 1 .. 2 |-> 0],
      confirmId               |-> [i \in 1 .. 4 |-> 0],
      execId                  |-> [i \in 1 .. 16 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      pbuid                   |-> [i \in 1 .. 6 |-> 0],
      accountId               |-> [i \in 1 .. 10 |-> 0],
      branchId                |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid       |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId   |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId    |-> [i \in 1 .. 2 |-> 0],
      cashMargin              |-> [i \in 1 .. 1 |-> 0] ]

(* After Hours Block Trade Trade Capture Report Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedAfterHoursBlockTradeTradeCaptureReportAckMessage ==
    { ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeReportRefId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.trdAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.tradeReportRejectReason = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportAckMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Bond Spot Negotiated Trade Capture Report Confirmation Message: 334     *)
(* bytes                                                                   *)
(***************************************************************************)

BondSpotNegotiatedTradeCaptureReportConfirmationMessage ==
    [ partitionNo            : Sample(4),
      reportIndex            : Sample(8),
      applId                 : Sample(3),
      reportingPbuid         : Sample(6),
      submittingPbuid        : Sample(6),
      securityId             : Sample(8),
      securityIdSource       : Sample(4),
      ownerType              : Sample(2),
      clearingFirm           : Sample(2),
      transactTime           : Sample(8),
      userInfo               : Sample(32),
      tradeId                : Sample(16),
      tradeReportId          : Sample(10),
      tradeReportType        : Sample(1),
      tradeReportTransType   : Sample(1),
      tradeHandlingInstr     : Sample(1),
      lastPx                 : Sample(8),
      lastQty                : Sample(8),
      trdType                : Sample(2),
      trdSubType             : Sample(2),
      confirmId              : Sample(4),
      execId                 : Sample(16),
      side                   : Sample(1),
      pbuid                  : Sample(6),
      accountId              : Sample(10),
      branchId               : Sample(2),
      counterpartyPbuid      : Sample(6),
      counterpartyAccountId  : Sample(10),
      counterpartyBranchId   : Sample(2),
      memberId               : Sample(6),
      traderCode             : Sample(5),
      counterpartyMemberId   : Sample(6),
      counterpartyTraderCode : Sample(5),
      settlType              : Sample(1),
      settlPeriod            : Sample(1),
      cashMargin             : Sample(1),
      memo                   : Sample(120) ]

EncodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.memberId
        \o message.traderCode
        \o message.counterpartyMemberId
        \o message.counterpartyTraderCode
        \o message.settlType
        \o message.settlPeriod
        \o message.cashMargin
        \o message.memo

DecodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeHandlingInstr.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET memberId == ReadBytes(counterpartyBranchId.rest, 6) IN IF ~memberId.ok THEN Fail ELSE
    LET traderCode == ReadBytes(memberId.rest, 5) IN IF ~traderCode.ok THEN Fail ELSE
    LET counterpartyMemberId == ReadBytes(traderCode.rest, 6) IN IF ~counterpartyMemberId.ok THEN Fail ELSE
    LET counterpartyTraderCode == ReadBytes(counterpartyMemberId.rest, 5) IN IF ~counterpartyTraderCode.ok THEN Fail ELSE
    LET settlType == ReadBytes(counterpartyTraderCode.rest, 1) IN IF ~settlType.ok THEN Fail ELSE
    LET settlPeriod == ReadBytes(settlType.rest, 1) IN IF ~settlPeriod.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(settlPeriod.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    LET memo == ReadBytes(cashMargin.rest, 120) IN IF ~memo.ok THEN Fail ELSE
    Ok([ partitionNo            |-> partitionNo.value,
         reportIndex            |-> reportIndex.value,
         applId                 |-> applId.value,
         reportingPbuid         |-> reportingPbuid.value,
         submittingPbuid        |-> submittingPbuid.value,
         securityId             |-> securityId.value,
         securityIdSource       |-> securityIdSource.value,
         ownerType              |-> ownerType.value,
         clearingFirm           |-> clearingFirm.value,
         transactTime           |-> transactTime.value,
         userInfo               |-> userInfo.value,
         tradeId                |-> tradeId.value,
         tradeReportId          |-> tradeReportId.value,
         tradeReportType        |-> tradeReportType.value,
         tradeReportTransType   |-> tradeReportTransType.value,
         tradeHandlingInstr     |-> tradeHandlingInstr.value,
         lastPx                 |-> lastPx.value,
         lastQty                |-> lastQty.value,
         trdType                |-> trdType.value,
         trdSubType             |-> trdSubType.value,
         confirmId              |-> confirmId.value,
         execId                 |-> execId.value,
         side                   |-> side.value,
         pbuid                  |-> pbuid.value,
         accountId              |-> accountId.value,
         branchId               |-> branchId.value,
         counterpartyPbuid      |-> counterpartyPbuid.value,
         counterpartyAccountId  |-> counterpartyAccountId.value,
         counterpartyBranchId   |-> counterpartyBranchId.value,
         memberId               |-> memberId.value,
         traderCode             |-> traderCode.value,
         counterpartyMemberId   |-> counterpartyMemberId.value,
         counterpartyTraderCode |-> counterpartyTraderCode.value,
         settlType              |-> settlType.value,
         settlPeriod            |-> settlPeriod.value,
         cashMargin             |-> cashMargin.value,
         memo                   |-> memo.value ], memo.rest)

ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage ==
    [ partitionNo            |-> [i \in 1 .. 4 |-> 0],
      reportIndex            |-> [i \in 1 .. 8 |-> 0],
      applId                 |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid         |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid        |-> [i \in 1 .. 6 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      securityIdSource       |-> [i \in 1 .. 4 |-> 0],
      ownerType              |-> [i \in 1 .. 2 |-> 0],
      clearingFirm           |-> [i \in 1 .. 2 |-> 0],
      transactTime           |-> [i \in 1 .. 8 |-> 0],
      userInfo               |-> [i \in 1 .. 32 |-> 0],
      tradeId                |-> [i \in 1 .. 16 |-> 0],
      tradeReportId          |-> [i \in 1 .. 10 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType   |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr     |-> [i \in 1 .. 1 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastQty                |-> [i \in 1 .. 8 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      trdSubType             |-> [i \in 1 .. 2 |-> 0],
      confirmId              |-> [i \in 1 .. 4 |-> 0],
      execId                 |-> [i \in 1 .. 16 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      pbuid                  |-> [i \in 1 .. 6 |-> 0],
      accountId              |-> [i \in 1 .. 10 |-> 0],
      branchId               |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid      |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId  |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId   |-> [i \in 1 .. 2 |-> 0],
      memberId               |-> [i \in 1 .. 6 |-> 0],
      traderCode             |-> [i \in 1 .. 5 |-> 0],
      counterpartyMemberId   |-> [i \in 1 .. 6 |-> 0],
      counterpartyTraderCode |-> [i \in 1 .. 5 |-> 0],
      settlType              |-> [i \in 1 .. 1 |-> 0],
      settlPeriod            |-> [i \in 1 .. 1 |-> 0],
      cashMargin             |-> [i \in 1 .. 1 |-> 0],
      memo                   |-> [i \in 1 .. 120 |-> 0] ]

(* Bond Spot Negotiated Trade Capture Report Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedBondSpotNegotiatedTradeCaptureReportConfirmationMessage ==
    { ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.memberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.traderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyMemberId = one] : one \in Sample(6) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyTraderCode = one] : one \in Sample(5) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.settlType = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.settlPeriod = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }
        \cup { [ZeroBondSpotNegotiatedTradeCaptureReportConfirmationMessage EXCEPT !.memo = one] : one \in Sample(120) }

(***************************************************************************)
(* Refinancing Securities Lending Agreed Trade Capture Report Confirmation *)
(* Message: 198 bytes                                                      *)
(***************************************************************************)

RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage ==
    [ partitionNo           : Sample(4),
      reportIndex           : Sample(8),
      applId                : Sample(3),
      reportingPbuid        : Sample(6),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeId               : Sample(16),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      execId                : Sample(16),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2),
      expirationDays        : Sample(2),
      expirationType        : Sample(1),
      maturityDate          : Sample(4),
      shareProperty         : Sample(2) ]

EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.expirationDays
        \o message.expirationType
        \o message.maturityDate
        \o message.shareProperty

DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeHandlingInstr.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET expirationDays == ReadBytes(counterpartyBranchId.rest, 2) IN IF ~expirationDays.ok THEN Fail ELSE
    LET expirationType == ReadBytes(expirationDays.rest, 1) IN IF ~expirationType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(expirationType.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET shareProperty == ReadBytes(maturityDate.rest, 2) IN IF ~shareProperty.ok THEN Fail ELSE
    Ok([ partitionNo           |-> partitionNo.value,
         reportIndex           |-> reportIndex.value,
         applId                |-> applId.value,
         reportingPbuid        |-> reportingPbuid.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeId               |-> tradeId.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value,
         expirationDays        |-> expirationDays.value,
         expirationType        |-> expirationType.value,
         maturityDate          |-> maturityDate.value,
         shareProperty         |-> shareProperty.value ], shareProperty.rest)

ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage ==
    [ partitionNo           |-> [i \in 1 .. 4 |-> 0],
      reportIndex           |-> [i \in 1 .. 8 |-> 0],
      applId                |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid        |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeId               |-> [i \in 1 .. 16 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 16 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0],
      expirationDays        |-> [i \in 1 .. 2 |-> 0],
      expirationType        |-> [i \in 1 .. 1 |-> 0],
      maturityDate          |-> [i \in 1 .. 4 |-> 0],
      shareProperty         |-> [i \in 1 .. 2 |-> 0] ]

(* Refinancing Securities Lending Agreed Trade Capture Report Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage ==
    { ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.expirationDays = one] : one \in Sample(2) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.expirationType = one] : one \in Sample(1) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage EXCEPT !.shareProperty = one] : one \in Sample(2) }

(***************************************************************************)
(* Mutual Trade Confirmation Trade Capture Report Confirmation Message:    *)
(* 189 bytes                                                               *)
(***************************************************************************)

MutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    [ partitionNo           : Sample(4),
      reportIndex           : Sample(8),
      applId                : Sample(3),
      reportingPbuid        : Sample(6),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeId               : Sample(16),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      execId                : Sample(16),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2) ]

EncodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeHandlingInstr.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ partitionNo           |-> partitionNo.value,
         reportIndex           |-> reportIndex.value,
         applId                |-> applId.value,
         reportingPbuid        |-> reportingPbuid.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeId               |-> tradeId.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    [ partitionNo           |-> [i \in 1 .. 4 |-> 0],
      reportIndex           |-> [i \in 1 .. 8 |-> 0],
      applId                |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid        |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeId               |-> [i \in 1 .. 16 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 16 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0] ]

(* Mutual Trade Confirmation Trade Capture Report Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    { ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Making Mutual Trade Confirmation Trade Capture Report            *)
(* Confirmation Message: 189 bytes                                         *)
(***************************************************************************)

MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    [ partitionNo           : Sample(4),
      reportIndex           : Sample(8),
      applId                : Sample(3),
      reportingPbuid        : Sample(6),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeId               : Sample(16),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      execId                : Sample(16),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2) ]

EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId

DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeHandlingInstr.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    Ok([ partitionNo           |-> partitionNo.value,
         reportIndex           |-> reportIndex.value,
         applId                |-> applId.value,
         reportingPbuid        |-> reportingPbuid.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeId               |-> tradeId.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value ], counterpartyBranchId.rest)

ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    [ partitionNo           |-> [i \in 1 .. 4 |-> 0],
      reportIndex           |-> [i \in 1 .. 8 |-> 0],
      applId                |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid        |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeId               |-> [i \in 1 .. 16 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 16 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0] ]

(* Market Making Mutual Trade Confirmation Trade Capture Report Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    { ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }

(***************************************************************************)
(* After Hours Block Trade Trade Capture Report Confirmation Message: 190  *)
(* bytes                                                                   *)
(***************************************************************************)

AfterHoursBlockTradeTradeCaptureReportConfirmationMessage ==
    [ partitionNo           : Sample(4),
      reportIndex           : Sample(8),
      applId                : Sample(3),
      reportingPbuid        : Sample(6),
      submittingPbuid       : Sample(6),
      securityId            : Sample(8),
      securityIdSource      : Sample(4),
      ownerType             : Sample(2),
      clearingFirm          : Sample(2),
      transactTime          : Sample(8),
      userInfo              : Sample(32),
      tradeId               : Sample(16),
      tradeReportId         : Sample(10),
      tradeReportType       : Sample(1),
      tradeReportTransType  : Sample(1),
      tradeHandlingInstr    : Sample(1),
      lastPx                : Sample(8),
      lastQty               : Sample(8),
      trdType               : Sample(2),
      trdSubType            : Sample(2),
      confirmId             : Sample(4),
      execId                : Sample(16),
      side                  : Sample(1),
      pbuid                 : Sample(6),
      accountId             : Sample(10),
      branchId              : Sample(2),
      counterpartyPbuid     : Sample(6),
      counterpartyAccountId : Sample(10),
      counterpartyBranchId  : Sample(2),
      cashMargin            : Sample(1) ]

EncodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(message) ==
    message.partitionNo
        \o message.reportIndex
        \o message.applId
        \o message.reportingPbuid
        \o message.submittingPbuid
        \o message.securityId
        \o message.securityIdSource
        \o message.ownerType
        \o message.clearingFirm
        \o message.transactTime
        \o message.userInfo
        \o message.tradeId
        \o message.tradeReportId
        \o message.tradeReportType
        \o message.tradeReportTransType
        \o message.tradeHandlingInstr
        \o message.lastPx
        \o message.lastQty
        \o message.trdType
        \o message.trdSubType
        \o message.confirmId
        \o message.execId
        \o message.side
        \o message.pbuid
        \o message.accountId
        \o message.branchId
        \o message.counterpartyPbuid
        \o message.counterpartyAccountId
        \o message.counterpartyBranchId
        \o message.cashMargin

DecodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(bytes) ==
    LET partitionNo == ReadBytes(bytes, 4) IN IF ~partitionNo.ok THEN Fail ELSE
    LET reportIndex == ReadBytes(partitionNo.rest, 8) IN IF ~reportIndex.ok THEN Fail ELSE
    LET applId == ReadBytes(reportIndex.rest, 3) IN IF ~applId.ok THEN Fail ELSE
    LET reportingPbuid == ReadBytes(applId.rest, 6) IN IF ~reportingPbuid.ok THEN Fail ELSE
    LET submittingPbuid == ReadBytes(reportingPbuid.rest, 6) IN IF ~submittingPbuid.ok THEN Fail ELSE
    LET securityId == ReadBytes(submittingPbuid.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET securityIdSource == ReadBytes(securityId.rest, 4) IN IF ~securityIdSource.ok THEN Fail ELSE
    LET ownerType == ReadBytes(securityIdSource.rest, 2) IN IF ~ownerType.ok THEN Fail ELSE
    LET clearingFirm == ReadBytes(ownerType.rest, 2) IN IF ~clearingFirm.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingFirm.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET userInfo == ReadBytes(transactTime.rest, 32) IN IF ~userInfo.ok THEN Fail ELSE
    LET tradeId == ReadBytes(userInfo.rest, 16) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeId.rest, 10) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradeReportId.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportTransType == ReadBytes(tradeReportType.rest, 1) IN IF ~tradeReportTransType.ok THEN Fail ELSE
    LET tradeHandlingInstr == ReadBytes(tradeReportTransType.rest, 1) IN IF ~tradeHandlingInstr.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeHandlingInstr.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET trdType == ReadBytes(lastQty.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET trdSubType == ReadBytes(trdType.rest, 2) IN IF ~trdSubType.ok THEN Fail ELSE
    LET confirmId == ReadBytes(trdSubType.rest, 4) IN IF ~confirmId.ok THEN Fail ELSE
    LET execId == ReadBytes(confirmId.rest, 16) IN IF ~execId.ok THEN Fail ELSE
    LET side == ReadBytes(execId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pbuid == ReadBytes(side.rest, 6) IN IF ~pbuid.ok THEN Fail ELSE
    LET accountId == ReadBytes(pbuid.rest, 10) IN IF ~accountId.ok THEN Fail ELSE
    LET branchId == ReadBytes(accountId.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET counterpartyPbuid == ReadBytes(branchId.rest, 6) IN IF ~counterpartyPbuid.ok THEN Fail ELSE
    LET counterpartyAccountId == ReadBytes(counterpartyPbuid.rest, 10) IN IF ~counterpartyAccountId.ok THEN Fail ELSE
    LET counterpartyBranchId == ReadBytes(counterpartyAccountId.rest, 2) IN IF ~counterpartyBranchId.ok THEN Fail ELSE
    LET cashMargin == ReadBytes(counterpartyBranchId.rest, 1) IN IF ~cashMargin.ok THEN Fail ELSE
    Ok([ partitionNo           |-> partitionNo.value,
         reportIndex           |-> reportIndex.value,
         applId                |-> applId.value,
         reportingPbuid        |-> reportingPbuid.value,
         submittingPbuid       |-> submittingPbuid.value,
         securityId            |-> securityId.value,
         securityIdSource      |-> securityIdSource.value,
         ownerType             |-> ownerType.value,
         clearingFirm          |-> clearingFirm.value,
         transactTime          |-> transactTime.value,
         userInfo              |-> userInfo.value,
         tradeId               |-> tradeId.value,
         tradeReportId         |-> tradeReportId.value,
         tradeReportType       |-> tradeReportType.value,
         tradeReportTransType  |-> tradeReportTransType.value,
         tradeHandlingInstr    |-> tradeHandlingInstr.value,
         lastPx                |-> lastPx.value,
         lastQty               |-> lastQty.value,
         trdType               |-> trdType.value,
         trdSubType            |-> trdSubType.value,
         confirmId             |-> confirmId.value,
         execId                |-> execId.value,
         side                  |-> side.value,
         pbuid                 |-> pbuid.value,
         accountId             |-> accountId.value,
         branchId              |-> branchId.value,
         counterpartyPbuid     |-> counterpartyPbuid.value,
         counterpartyAccountId |-> counterpartyAccountId.value,
         counterpartyBranchId  |-> counterpartyBranchId.value,
         cashMargin            |-> cashMargin.value ], cashMargin.rest)

ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage ==
    [ partitionNo           |-> [i \in 1 .. 4 |-> 0],
      reportIndex           |-> [i \in 1 .. 8 |-> 0],
      applId                |-> [i \in 1 .. 3 |-> 0],
      reportingPbuid        |-> [i \in 1 .. 6 |-> 0],
      submittingPbuid       |-> [i \in 1 .. 6 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      securityIdSource      |-> [i \in 1 .. 4 |-> 0],
      ownerType             |-> [i \in 1 .. 2 |-> 0],
      clearingFirm          |-> [i \in 1 .. 2 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      userInfo              |-> [i \in 1 .. 32 |-> 0],
      tradeId               |-> [i \in 1 .. 16 |-> 0],
      tradeReportId         |-> [i \in 1 .. 10 |-> 0],
      tradeReportType       |-> [i \in 1 .. 1 |-> 0],
      tradeReportTransType  |-> [i \in 1 .. 1 |-> 0],
      tradeHandlingInstr    |-> [i \in 1 .. 1 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      trdType               |-> [i \in 1 .. 2 |-> 0],
      trdSubType            |-> [i \in 1 .. 2 |-> 0],
      confirmId             |-> [i \in 1 .. 4 |-> 0],
      execId                |-> [i \in 1 .. 16 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pbuid                 |-> [i \in 1 .. 6 |-> 0],
      accountId             |-> [i \in 1 .. 10 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      counterpartyPbuid     |-> [i \in 1 .. 6 |-> 0],
      counterpartyAccountId |-> [i \in 1 .. 10 |-> 0],
      counterpartyBranchId  |-> [i \in 1 .. 2 |-> 0],
      cashMargin            |-> [i \in 1 .. 1 |-> 0] ]

(* After Hours Block Trade Trade Capture Report Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedAfterHoursBlockTradeTradeCaptureReportConfirmationMessage ==
    { ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.partitionNo = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.reportIndex = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.applId = one] : one \in Sample(3) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.reportingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.submittingPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.securityIdSource = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.ownerType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.clearingFirm = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.userInfo = one] : one \in Sample(32) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.tradeId = one] : one \in Sample(16) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.tradeReportTransType = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.tradeHandlingInstr = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.trdSubType = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.confirmId = one] : one \in Sample(4) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.execId = one] : one \in Sample(16) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.pbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.accountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyPbuid = one] : one \in Sample(6) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyAccountId = one] : one \in Sample(10) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.counterpartyBranchId = one] : one \in Sample(2) }
        \cup { [ZeroAfterHoursBlockTradeTradeCaptureReportConfirmationMessage EXCEPT !.cashMargin = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

LogonMessageCode == 1  \* 0x01
LogoutMessageCode == 2  \* 0x02
HeartbeatMessageCode == 3  \* 0x03
BusinessRejectMessageCode == 4  \* 0x04
ReportSynchronizationMessageCode == 5  \* 0x05
PlatformStateInfoMessageCode == 6  \* 0x06
ReportFinishedMessageCode == 7  \* 0x07
PlatformInfoMessageCode == 9  \* 0x09
TradingSessionStatusMessageCode == 10  \* 0x0a
BondSpotMatchingNewOrderMessageCode == 101010  \* 0x18a92
CentralizedAuctionNewOrderMessageCode == 101040  \* 0x18ab0
ConversionNewOrderMessageCode == 101041  \* 0x18ab1
InquiryNewOrderMessageCode == 101042  \* 0x18ab2
SubscriptionNewOrderMessageCode == 101043  \* 0x18ab3
PutBackNewOrderMessageCode == 101044  \* 0x18ab4
TenderOfferAcceptanceNewOrderMessageCode == 101045  \* 0x18ab5
RefinancingSecuritiesLendingNonAgreedNewOrderMessageCode == 101050  \* 0x18aba
OrderCancelRequestMessageCode == 102000  \* 0x18e70
CancelRejectMessageCode == 201000  \* 0x31128
BondSpotMatchingExecutionReportMessageCode == 202010  \* 0x3151a
CentralizedAuctionExecutionReportMessageCode == 202040  \* 0x31538
ConversionExecutionReportMessageCode == 202041  \* 0x31539
InquiryExecutionReportMessageCode == 202042  \* 0x3153a
SubscriptionExecutionReportMessageCode == 202043  \* 0x3153b
PutBackExecutionReportMessageCode == 202044  \* 0x3153c
TenderOfferAcceptanceExecutionReportMessageCode == 202045  \* 0x3153d
RefinancingSecuritiesLendingNonAgreedExecutionReportMessageCode == 202050  \* 0x31542
BondSpotMatchingTradeExecutionReportMessageCode == 203010  \* 0x31902
CentralizedAuctionTradeExecutionReportMessageCode == 203040  \* 0x31920
RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessageCode == 203050  \* 0x3192a
BondSpotNegotiatedTradeCaptureReportMessageCode == 103031  \* 0x19277
RefinancingSecuritiesLendingAgreedTradeCaptureReportMessageCode == 103051  \* 0x1928b
MutualTradeConfirmationTradeCaptureReportMessageCode == 103060  \* 0x19294
MarketMakingMutualTradeConfirmationTradeCaptureReportMessageCode == 103061  \* 0x19295
AfterHoursBlockTradeTradeCaptureReportMessageCode == 103062  \* 0x19296
BondSpotNegotiatedTradeCaptureReportAckMessageCode == 204031  \* 0x31cff
RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessageCode == 204051  \* 0x31d13
MutualTradeConfirmationTradeCaptureReportAckMessageCode == 204060  \* 0x31d1c
MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessageCode == 204061  \* 0x31d1d
AfterHoursBlockTradeTradeCaptureReportAckMessageCode == 204062  \* 0x31d1e
BondSpotNegotiatedTradeCaptureReportConfirmationMessageCode == 205031  \* 0x320e7
RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessageCode == 205051  \* 0x320fb
MutualTradeConfirmationTradeCaptureReportConfirmationMessageCode == 205060  \* 0x32104
MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessageCode == 205061  \* 0x32105
AfterHoursBlockTradeTradeCaptureReportConfirmationMessageCode == 205062  \* 0x32106

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {BusinessRejectMessageCode}, body : BusinessRejectMessage ]
        \cup [ tag : {ReportSynchronizationMessageCode}, body : ReportSynchronizationMessage ]
        \cup [ tag : {PlatformStateInfoMessageCode}, body : PlatformStateInfoMessage ]
        \cup [ tag : {ReportFinishedMessageCode}, body : ReportFinishedMessage ]
        \cup [ tag : {PlatformInfoMessageCode}, body : PlatformInfoMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {BondSpotMatchingNewOrderMessageCode}, body : BondSpotMatchingNewOrderMessage ]
        \cup [ tag : {CentralizedAuctionNewOrderMessageCode}, body : CentralizedAuctionNewOrderMessage ]
        \cup [ tag : {ConversionNewOrderMessageCode}, body : ConversionNewOrderMessage ]
        \cup [ tag : {InquiryNewOrderMessageCode}, body : InquiryNewOrderMessage ]
        \cup [ tag : {SubscriptionNewOrderMessageCode}, body : SubscriptionNewOrderMessage ]
        \cup [ tag : {PutBackNewOrderMessageCode}, body : PutBackNewOrderMessage ]
        \cup [ tag : {TenderOfferAcceptanceNewOrderMessageCode}, body : TenderOfferAcceptanceNewOrderMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingNonAgreedNewOrderMessageCode}, body : RefinancingSecuritiesLendingNonAgreedNewOrderMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {CancelRejectMessageCode}, body : CancelRejectMessage ]
        \cup [ tag : {BondSpotMatchingExecutionReportMessageCode}, body : BondSpotMatchingExecutionReportMessage ]
        \cup [ tag : {CentralizedAuctionExecutionReportMessageCode}, body : CentralizedAuctionExecutionReportMessage ]
        \cup [ tag : {ConversionExecutionReportMessageCode}, body : ConversionExecutionReportMessage ]
        \cup [ tag : {InquiryExecutionReportMessageCode}, body : InquiryExecutionReportMessage ]
        \cup [ tag : {SubscriptionExecutionReportMessageCode}, body : SubscriptionExecutionReportMessage ]
        \cup [ tag : {PutBackExecutionReportMessageCode}, body : PutBackExecutionReportMessage ]
        \cup [ tag : {TenderOfferAcceptanceExecutionReportMessageCode}, body : TenderOfferAcceptanceExecutionReportMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingNonAgreedExecutionReportMessageCode}, body : RefinancingSecuritiesLendingNonAgreedExecutionReportMessage ]
        \cup [ tag : {BondSpotMatchingTradeExecutionReportMessageCode}, body : BondSpotMatchingTradeExecutionReportMessage ]
        \cup [ tag : {CentralizedAuctionTradeExecutionReportMessageCode}, body : CentralizedAuctionTradeExecutionReportMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessageCode}, body : RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage ]
        \cup [ tag : {BondSpotNegotiatedTradeCaptureReportMessageCode}, body : BondSpotNegotiatedTradeCaptureReportMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingAgreedTradeCaptureReportMessageCode}, body : RefinancingSecuritiesLendingAgreedTradeCaptureReportMessage ]
        \cup [ tag : {MutualTradeConfirmationTradeCaptureReportMessageCode}, body : MutualTradeConfirmationTradeCaptureReportMessage ]
        \cup [ tag : {MarketMakingMutualTradeConfirmationTradeCaptureReportMessageCode}, body : MarketMakingMutualTradeConfirmationTradeCaptureReportMessage ]
        \cup [ tag : {AfterHoursBlockTradeTradeCaptureReportMessageCode}, body : AfterHoursBlockTradeTradeCaptureReportMessage ]
        \cup [ tag : {BondSpotNegotiatedTradeCaptureReportAckMessageCode}, body : BondSpotNegotiatedTradeCaptureReportAckMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessageCode}, body : RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage ]
        \cup [ tag : {MutualTradeConfirmationTradeCaptureReportAckMessageCode}, body : MutualTradeConfirmationTradeCaptureReportAckMessage ]
        \cup [ tag : {MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessageCode}, body : MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage ]
        \cup [ tag : {AfterHoursBlockTradeTradeCaptureReportAckMessageCode}, body : AfterHoursBlockTradeTradeCaptureReportAckMessage ]
        \cup [ tag : {BondSpotNegotiatedTradeCaptureReportConfirmationMessageCode}, body : BondSpotNegotiatedTradeCaptureReportConfirmationMessage ]
        \cup [ tag : {RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessageCode}, body : RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage ]
        \cup [ tag : {MutualTradeConfirmationTradeCaptureReportConfirmationMessageCode}, body : MutualTradeConfirmationTradeCaptureReportConfirmationMessage ]
        \cup [ tag : {MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessageCode}, body : MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage ]
        \cup [ tag : {AfterHoursBlockTradeTradeCaptureReportConfirmationMessageCode}, body : AfterHoursBlockTradeTradeCaptureReportConfirmationMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = BusinessRejectMessageCode -> EncodeBusinessRejectMessage(message.body)
      [] message.tag = ReportSynchronizationMessageCode -> EncodeReportSynchronizationMessage(message.body)
      [] message.tag = PlatformStateInfoMessageCode -> EncodePlatformStateInfoMessage(message.body)
      [] message.tag = ReportFinishedMessageCode -> EncodeReportFinishedMessage(message.body)
      [] message.tag = PlatformInfoMessageCode -> EncodePlatformInfoMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = BondSpotMatchingNewOrderMessageCode -> EncodeBondSpotMatchingNewOrderMessage(message.body)
      [] message.tag = CentralizedAuctionNewOrderMessageCode -> EncodeCentralizedAuctionNewOrderMessage(message.body)
      [] message.tag = ConversionNewOrderMessageCode -> EncodeConversionNewOrderMessage(message.body)
      [] message.tag = InquiryNewOrderMessageCode -> EncodeInquiryNewOrderMessage(message.body)
      [] message.tag = SubscriptionNewOrderMessageCode -> EncodeSubscriptionNewOrderMessage(message.body)
      [] message.tag = PutBackNewOrderMessageCode -> EncodePutBackNewOrderMessage(message.body)
      [] message.tag = TenderOfferAcceptanceNewOrderMessageCode -> EncodeTenderOfferAcceptanceNewOrderMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingNonAgreedNewOrderMessageCode -> EncodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = CancelRejectMessageCode -> EncodeCancelRejectMessage(message.body)
      [] message.tag = BondSpotMatchingExecutionReportMessageCode -> EncodeBondSpotMatchingExecutionReportMessage(message.body)
      [] message.tag = CentralizedAuctionExecutionReportMessageCode -> EncodeCentralizedAuctionExecutionReportMessage(message.body)
      [] message.tag = ConversionExecutionReportMessageCode -> EncodeConversionExecutionReportMessage(message.body)
      [] message.tag = InquiryExecutionReportMessageCode -> EncodeInquiryExecutionReportMessage(message.body)
      [] message.tag = SubscriptionExecutionReportMessageCode -> EncodeSubscriptionExecutionReportMessage(message.body)
      [] message.tag = PutBackExecutionReportMessageCode -> EncodePutBackExecutionReportMessage(message.body)
      [] message.tag = TenderOfferAcceptanceExecutionReportMessageCode -> EncodeTenderOfferAcceptanceExecutionReportMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingNonAgreedExecutionReportMessageCode -> EncodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(message.body)
      [] message.tag = BondSpotMatchingTradeExecutionReportMessageCode -> EncodeBondSpotMatchingTradeExecutionReportMessage(message.body)
      [] message.tag = CentralizedAuctionTradeExecutionReportMessageCode -> EncodeCentralizedAuctionTradeExecutionReportMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessageCode -> EncodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(message.body)
      [] message.tag = BondSpotNegotiatedTradeCaptureReportMessageCode -> EncodeBondSpotNegotiatedTradeCaptureReportMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportMessageCode -> EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(message.body)
      [] message.tag = MutualTradeConfirmationTradeCaptureReportMessageCode -> EncodeMutualTradeConfirmationTradeCaptureReportMessage(message.body)
      [] message.tag = MarketMakingMutualTradeConfirmationTradeCaptureReportMessageCode -> EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(message.body)
      [] message.tag = AfterHoursBlockTradeTradeCaptureReportMessageCode -> EncodeAfterHoursBlockTradeTradeCaptureReportMessage(message.body)
      [] message.tag = BondSpotNegotiatedTradeCaptureReportAckMessageCode -> EncodeBondSpotNegotiatedTradeCaptureReportAckMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessageCode -> EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(message.body)
      [] message.tag = MutualTradeConfirmationTradeCaptureReportAckMessageCode -> EncodeMutualTradeConfirmationTradeCaptureReportAckMessage(message.body)
      [] message.tag = MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessageCode -> EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(message.body)
      [] message.tag = AfterHoursBlockTradeTradeCaptureReportAckMessageCode -> EncodeAfterHoursBlockTradeTradeCaptureReportAckMessage(message.body)
      [] message.tag = BondSpotNegotiatedTradeCaptureReportConfirmationMessageCode -> EncodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(message.body)
      [] message.tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessageCode -> EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(message.body)
      [] message.tag = MutualTradeConfirmationTradeCaptureReportConfirmationMessageCode -> EncodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message.body)
      [] message.tag = MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessageCode -> EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message.body)
      [] message.tag = AfterHoursBlockTradeTradeCaptureReportConfirmationMessageCode -> EncodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = BusinessRejectMessageCode -> DecodeBusinessRejectMessage(bytes)
              [] tag = ReportSynchronizationMessageCode -> DecodeReportSynchronizationMessage(bytes)
              [] tag = PlatformStateInfoMessageCode -> DecodePlatformStateInfoMessage(bytes)
              [] tag = ReportFinishedMessageCode -> DecodeReportFinishedMessage(bytes)
              [] tag = PlatformInfoMessageCode -> DecodePlatformInfoMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = BondSpotMatchingNewOrderMessageCode -> DecodeBondSpotMatchingNewOrderMessage(bytes)
              [] tag = CentralizedAuctionNewOrderMessageCode -> DecodeCentralizedAuctionNewOrderMessage(bytes)
              [] tag = ConversionNewOrderMessageCode -> DecodeConversionNewOrderMessage(bytes)
              [] tag = InquiryNewOrderMessageCode -> DecodeInquiryNewOrderMessage(bytes)
              [] tag = SubscriptionNewOrderMessageCode -> DecodeSubscriptionNewOrderMessage(bytes)
              [] tag = PutBackNewOrderMessageCode -> DecodePutBackNewOrderMessage(bytes)
              [] tag = TenderOfferAcceptanceNewOrderMessageCode -> DecodeTenderOfferAcceptanceNewOrderMessage(bytes)
              [] tag = RefinancingSecuritiesLendingNonAgreedNewOrderMessageCode -> DecodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = CancelRejectMessageCode -> DecodeCancelRejectMessage(bytes)
              [] tag = BondSpotMatchingExecutionReportMessageCode -> DecodeBondSpotMatchingExecutionReportMessage(bytes)
              [] tag = CentralizedAuctionExecutionReportMessageCode -> DecodeCentralizedAuctionExecutionReportMessage(bytes)
              [] tag = ConversionExecutionReportMessageCode -> DecodeConversionExecutionReportMessage(bytes)
              [] tag = InquiryExecutionReportMessageCode -> DecodeInquiryExecutionReportMessage(bytes)
              [] tag = SubscriptionExecutionReportMessageCode -> DecodeSubscriptionExecutionReportMessage(bytes)
              [] tag = PutBackExecutionReportMessageCode -> DecodePutBackExecutionReportMessage(bytes)
              [] tag = TenderOfferAcceptanceExecutionReportMessageCode -> DecodeTenderOfferAcceptanceExecutionReportMessage(bytes)
              [] tag = RefinancingSecuritiesLendingNonAgreedExecutionReportMessageCode -> DecodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(bytes)
              [] tag = BondSpotMatchingTradeExecutionReportMessageCode -> DecodeBondSpotMatchingTradeExecutionReportMessage(bytes)
              [] tag = CentralizedAuctionTradeExecutionReportMessageCode -> DecodeCentralizedAuctionTradeExecutionReportMessage(bytes)
              [] tag = RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessageCode -> DecodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(bytes)
              [] tag = BondSpotNegotiatedTradeCaptureReportMessageCode -> DecodeBondSpotNegotiatedTradeCaptureReportMessage(bytes)
              [] tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportMessageCode -> DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(bytes)
              [] tag = MutualTradeConfirmationTradeCaptureReportMessageCode -> DecodeMutualTradeConfirmationTradeCaptureReportMessage(bytes)
              [] tag = MarketMakingMutualTradeConfirmationTradeCaptureReportMessageCode -> DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(bytes)
              [] tag = AfterHoursBlockTradeTradeCaptureReportMessageCode -> DecodeAfterHoursBlockTradeTradeCaptureReportMessage(bytes)
              [] tag = BondSpotNegotiatedTradeCaptureReportAckMessageCode -> DecodeBondSpotNegotiatedTradeCaptureReportAckMessage(bytes)
              [] tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessageCode -> DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(bytes)
              [] tag = MutualTradeConfirmationTradeCaptureReportAckMessageCode -> DecodeMutualTradeConfirmationTradeCaptureReportAckMessage(bytes)
              [] tag = MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessageCode -> DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(bytes)
              [] tag = AfterHoursBlockTradeTradeCaptureReportAckMessageCode -> DecodeAfterHoursBlockTradeTradeCaptureReportAckMessage(bytes)
              [] tag = BondSpotNegotiatedTradeCaptureReportConfirmationMessageCode -> DecodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(bytes)
              [] tag = RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessageCode -> DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(bytes)
              [] tag = MutualTradeConfirmationTradeCaptureReportConfirmationMessageCode -> DecodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(bytes)
              [] tag = MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessageCode -> DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(bytes)
              [] tag = AfterHoursBlockTradeTradeCaptureReportConfirmationMessageCode -> DecodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> BusinessRejectMessageCode, body |-> one] : one \in CheckedBusinessRejectMessage }
        \cup { [tag |-> ReportSynchronizationMessageCode, body |-> one] : one \in CheckedReportSynchronizationMessage }
        \cup { [tag |-> PlatformStateInfoMessageCode, body |-> one] : one \in CheckedPlatformStateInfoMessage }
        \cup { [tag |-> ReportFinishedMessageCode, body |-> one] : one \in CheckedReportFinishedMessage }
        \cup { [tag |-> PlatformInfoMessageCode, body |-> one] : one \in CheckedPlatformInfoMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> BondSpotMatchingNewOrderMessageCode, body |-> one] : one \in CheckedBondSpotMatchingNewOrderMessage }
        \cup { [tag |-> CentralizedAuctionNewOrderMessageCode, body |-> one] : one \in CheckedCentralizedAuctionNewOrderMessage }
        \cup { [tag |-> ConversionNewOrderMessageCode, body |-> one] : one \in CheckedConversionNewOrderMessage }
        \cup { [tag |-> InquiryNewOrderMessageCode, body |-> one] : one \in CheckedInquiryNewOrderMessage }
        \cup { [tag |-> SubscriptionNewOrderMessageCode, body |-> one] : one \in CheckedSubscriptionNewOrderMessage }
        \cup { [tag |-> PutBackNewOrderMessageCode, body |-> one] : one \in CheckedPutBackNewOrderMessage }
        \cup { [tag |-> TenderOfferAcceptanceNewOrderMessageCode, body |-> one] : one \in CheckedTenderOfferAcceptanceNewOrderMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingNonAgreedNewOrderMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingNonAgreedNewOrderMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> CancelRejectMessageCode, body |-> one] : one \in CheckedCancelRejectMessage }
        \cup { [tag |-> BondSpotMatchingExecutionReportMessageCode, body |-> one] : one \in CheckedBondSpotMatchingExecutionReportMessage }
        \cup { [tag |-> CentralizedAuctionExecutionReportMessageCode, body |-> one] : one \in CheckedCentralizedAuctionExecutionReportMessage }
        \cup { [tag |-> ConversionExecutionReportMessageCode, body |-> one] : one \in CheckedConversionExecutionReportMessage }
        \cup { [tag |-> InquiryExecutionReportMessageCode, body |-> one] : one \in CheckedInquiryExecutionReportMessage }
        \cup { [tag |-> SubscriptionExecutionReportMessageCode, body |-> one] : one \in CheckedSubscriptionExecutionReportMessage }
        \cup { [tag |-> PutBackExecutionReportMessageCode, body |-> one] : one \in CheckedPutBackExecutionReportMessage }
        \cup { [tag |-> TenderOfferAcceptanceExecutionReportMessageCode, body |-> one] : one \in CheckedTenderOfferAcceptanceExecutionReportMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingNonAgreedExecutionReportMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingNonAgreedExecutionReportMessage }
        \cup { [tag |-> BondSpotMatchingTradeExecutionReportMessageCode, body |-> one] : one \in CheckedBondSpotMatchingTradeExecutionReportMessage }
        \cup { [tag |-> CentralizedAuctionTradeExecutionReportMessageCode, body |-> one] : one \in CheckedCentralizedAuctionTradeExecutionReportMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage }
        \cup { [tag |-> BondSpotNegotiatedTradeCaptureReportMessageCode, body |-> one] : one \in CheckedBondSpotNegotiatedTradeCaptureReportMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingAgreedTradeCaptureReportMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage }
        \cup { [tag |-> MutualTradeConfirmationTradeCaptureReportMessageCode, body |-> one] : one \in CheckedMutualTradeConfirmationTradeCaptureReportMessage }
        \cup { [tag |-> MarketMakingMutualTradeConfirmationTradeCaptureReportMessageCode, body |-> one] : one \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportMessage }
        \cup { [tag |-> AfterHoursBlockTradeTradeCaptureReportMessageCode, body |-> one] : one \in CheckedAfterHoursBlockTradeTradeCaptureReportMessage }
        \cup { [tag |-> BondSpotNegotiatedTradeCaptureReportAckMessageCode, body |-> one] : one \in CheckedBondSpotNegotiatedTradeCaptureReportAckMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage }
        \cup { [tag |-> MutualTradeConfirmationTradeCaptureReportAckMessageCode, body |-> one] : one \in CheckedMutualTradeConfirmationTradeCaptureReportAckMessage }
        \cup { [tag |-> MarketMakingMutualTradeConfirmationTradeCaptureReportAckMessageCode, body |-> one] : one \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage }
        \cup { [tag |-> AfterHoursBlockTradeTradeCaptureReportAckMessageCode, body |-> one] : one \in CheckedAfterHoursBlockTradeTradeCaptureReportAckMessage }
        \cup { [tag |-> BondSpotNegotiatedTradeCaptureReportConfirmationMessageCode, body |-> one] : one \in CheckedBondSpotNegotiatedTradeCaptureReportConfirmationMessage }
        \cup { [tag |-> RefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessageCode, body |-> one] : one \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage }
        \cup { [tag |-> MutualTradeConfirmationTradeCaptureReportConfirmationMessageCode, body |-> one] : one \in CheckedMutualTradeConfirmationTradeCaptureReportConfirmationMessage }
        \cup { [tag |-> MarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessageCode, body |-> one] : one \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage }
        \cup { [tag |-> AfterHoursBlockTradeTradeCaptureReportConfirmationMessageCode, body |-> one] : one \in CheckedAfterHoursBlockTradeTradeCaptureReportConfirmationMessage }

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

(* Every Business Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessRejectMessage ==
    \A message \in CheckedBusinessRejectMessage :
        LET read == DecodeBusinessRejectMessage(EncodeBusinessRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partition Reports decodes back to what was encoded, and leaves nothing over *)
RoundTripPartitionReports ==
    \A message \in CheckedPartitionReports :
        LET read == DecodePartitionReports(EncodePartitionReports(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Report Synchronization Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReportSynchronizationMessage ==
    \A message \in CheckedReportSynchronizationMessage :
        LET read == DecodeReportSynchronizationMessage(EncodeReportSynchronizationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Platform State Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlatformStateInfoMessage ==
    \A message \in CheckedPlatformStateInfoMessage :
        LET read == DecodePlatformStateInfoMessage(EncodePlatformStateInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Report Finished Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReportFinishedMessage ==
    \A message \in CheckedReportFinishedMessage :
        LET read == DecodeReportFinishedMessage(EncodeReportFinishedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partitions decodes back to what was encoded, and leaves nothing over *)
RoundTripPartitions ==
    \A message \in CheckedPartitions :
        LET read == DecodePartitions(EncodePartitions(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Platform Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPlatformInfoMessage ==
    \A message \in CheckedPlatformInfoMessage :
        LET read == DecodePlatformInfoMessage(EncodePlatformInfoMessage(message))
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

(* Every Bond Spot Matching New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotMatchingNewOrderMessage ==
    \A message \in CheckedBondSpotMatchingNewOrderMessage :
        LET read == DecodeBondSpotMatchingNewOrderMessage(EncodeBondSpotMatchingNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Centralized Auction New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCentralizedAuctionNewOrderMessage ==
    \A message \in CheckedCentralizedAuctionNewOrderMessage :
        LET read == DecodeCentralizedAuctionNewOrderMessage(EncodeCentralizedAuctionNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conversion New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConversionNewOrderMessage ==
    \A message \in CheckedConversionNewOrderMessage :
        LET read == DecodeConversionNewOrderMessage(EncodeConversionNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquiry New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInquiryNewOrderMessage ==
    \A message \in CheckedInquiryNewOrderMessage :
        LET read == DecodeInquiryNewOrderMessage(EncodeInquiryNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionNewOrderMessage ==
    \A message \in CheckedSubscriptionNewOrderMessage :
        LET read == DecodeSubscriptionNewOrderMessage(EncodeSubscriptionNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Put Back New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPutBackNewOrderMessage ==
    \A message \in CheckedPutBackNewOrderMessage :
        LET read == DecodePutBackNewOrderMessage(EncodePutBackNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tender Offer Acceptance New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTenderOfferAcceptanceNewOrderMessage ==
    \A message \in CheckedTenderOfferAcceptanceNewOrderMessage :
        LET read == DecodeTenderOfferAcceptanceNewOrderMessage(EncodeTenderOfferAcceptanceNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Non Agreed New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingNonAgreedNewOrderMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingNonAgreedNewOrderMessage :
        LET read == DecodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(EncodeRefinancingSecuritiesLendingNonAgreedNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectMessage ==
    \A message \in CheckedCancelRejectMessage :
        LET read == DecodeCancelRejectMessage(EncodeCancelRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Matching Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotMatchingExecutionReportMessage ==
    \A message \in CheckedBondSpotMatchingExecutionReportMessage :
        LET read == DecodeBondSpotMatchingExecutionReportMessage(EncodeBondSpotMatchingExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Centralized Auction Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCentralizedAuctionExecutionReportMessage ==
    \A message \in CheckedCentralizedAuctionExecutionReportMessage :
        LET read == DecodeCentralizedAuctionExecutionReportMessage(EncodeCentralizedAuctionExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conversion Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConversionExecutionReportMessage ==
    \A message \in CheckedConversionExecutionReportMessage :
        LET read == DecodeConversionExecutionReportMessage(EncodeConversionExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquiry Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInquiryExecutionReportMessage ==
    \A message \in CheckedInquiryExecutionReportMessage :
        LET read == DecodeInquiryExecutionReportMessage(EncodeInquiryExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionExecutionReportMessage ==
    \A message \in CheckedSubscriptionExecutionReportMessage :
        LET read == DecodeSubscriptionExecutionReportMessage(EncodeSubscriptionExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Put Back Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPutBackExecutionReportMessage ==
    \A message \in CheckedPutBackExecutionReportMessage :
        LET read == DecodePutBackExecutionReportMessage(EncodePutBackExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tender Offer Acceptance Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTenderOfferAcceptanceExecutionReportMessage ==
    \A message \in CheckedTenderOfferAcceptanceExecutionReportMessage :
        LET read == DecodeTenderOfferAcceptanceExecutionReportMessage(EncodeTenderOfferAcceptanceExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Non Agreed Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingNonAgreedExecutionReportMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingNonAgreedExecutionReportMessage :
        LET read == DecodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(EncodeRefinancingSecuritiesLendingNonAgreedExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Matching Trade Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotMatchingTradeExecutionReportMessage ==
    \A message \in CheckedBondSpotMatchingTradeExecutionReportMessage :
        LET read == DecodeBondSpotMatchingTradeExecutionReportMessage(EncodeBondSpotMatchingTradeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Centralized Auction Trade Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCentralizedAuctionTradeExecutionReportMessage ==
    \A message \in CheckedCentralizedAuctionTradeExecutionReportMessage :
        LET read == DecodeCentralizedAuctionTradeExecutionReportMessage(EncodeCentralizedAuctionTradeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Non Agreed Trade Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage :
        LET read == DecodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(EncodeRefinancingSecuritiesLendingNonAgreedTradeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Negotiated Trade Capture Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotNegotiatedTradeCaptureReportMessage ==
    \A message \in CheckedBondSpotNegotiatedTradeCaptureReportMessage :
        LET read == DecodeBondSpotNegotiatedTradeCaptureReportMessage(EncodeBondSpotNegotiatedTradeCaptureReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Agreed Trade Capture Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage :
        LET read == DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mutual Trade Confirmation Trade Capture Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualTradeConfirmationTradeCaptureReportMessage ==
    \A message \in CheckedMutualTradeConfirmationTradeCaptureReportMessage :
        LET read == DecodeMutualTradeConfirmationTradeCaptureReportMessage(EncodeMutualTradeConfirmationTradeCaptureReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Making Mutual Trade Confirmation Trade Capture Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakingMutualTradeConfirmationTradeCaptureReportMessage ==
    \A message \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportMessage :
        LET read == DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every After Hours Block Trade Trade Capture Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAfterHoursBlockTradeTradeCaptureReportMessage ==
    \A message \in CheckedAfterHoursBlockTradeTradeCaptureReportMessage :
        LET read == DecodeAfterHoursBlockTradeTradeCaptureReportMessage(EncodeAfterHoursBlockTradeTradeCaptureReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Negotiated Trade Capture Report Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotNegotiatedTradeCaptureReportAckMessage ==
    \A message \in CheckedBondSpotNegotiatedTradeCaptureReportAckMessage :
        LET read == DecodeBondSpotNegotiatedTradeCaptureReportAckMessage(EncodeBondSpotNegotiatedTradeCaptureReportAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Agreed Trade Capture Report Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage :
        LET read == DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mutual Trade Confirmation Trade Capture Report Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualTradeConfirmationTradeCaptureReportAckMessage ==
    \A message \in CheckedMutualTradeConfirmationTradeCaptureReportAckMessage :
        LET read == DecodeMutualTradeConfirmationTradeCaptureReportAckMessage(EncodeMutualTradeConfirmationTradeCaptureReportAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Making Mutual Trade Confirmation Trade Capture Report Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage ==
    \A message \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage :
        LET read == DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every After Hours Block Trade Trade Capture Report Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAfterHoursBlockTradeTradeCaptureReportAckMessage ==
    \A message \in CheckedAfterHoursBlockTradeTradeCaptureReportAckMessage :
        LET read == DecodeAfterHoursBlockTradeTradeCaptureReportAckMessage(EncodeAfterHoursBlockTradeTradeCaptureReportAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Spot Negotiated Trade Capture Report Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBondSpotNegotiatedTradeCaptureReportConfirmationMessage ==
    \A message \in CheckedBondSpotNegotiatedTradeCaptureReportConfirmationMessage :
        LET read == DecodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(EncodeBondSpotNegotiatedTradeCaptureReportConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refinancing Securities Lending Agreed Trade Capture Report Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage ==
    \A message \in CheckedRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage :
        LET read == DecodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(EncodeRefinancingSecuritiesLendingAgreedTradeCaptureReportConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mutual Trade Confirmation Trade Capture Report Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    \A message \in CheckedMutualTradeConfirmationTradeCaptureReportConfirmationMessage :
        LET read == DecodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(EncodeMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Making Mutual Trade Confirmation Trade Capture Report Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage ==
    \A message \in CheckedMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage :
        LET read == DecodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(EncodeMarketMakingMutualTradeConfirmationTradeCaptureReportConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every After Hours Block Trade Trade Capture Report Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAfterHoursBlockTradeTradeCaptureReportConfirmationMessage ==
    \A message \in CheckedAfterHoursBlockTradeTradeCaptureReportConfirmationMessage :
        LET read == DecodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(EncodeAfterHoursBlockTradeTradeCaptureReportConfirmationMessage(message))
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
