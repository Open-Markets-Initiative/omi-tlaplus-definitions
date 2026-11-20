--------------- MODULE TaifexDerivatives_OrderEntry_v2_18_7 ----------------
(***************************************************************************)
(* Taiwan Futures Exchange Order Entry v2.18.7                             *)
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
(* Header Time: 6 bytes                                                    *)
(***************************************************************************)

HeaderTime ==
    [ headerEpochS : Sample(4),
      headerMs     : Sample(2) ]

EncodeHeaderTime(message) ==
    message.headerEpochS
        \o message.headerMs

DecodeHeaderTime(bytes) ==
    LET headerEpochS == ReadBytes(bytes, 4) IN IF ~headerEpochS.ok THEN Fail ELSE
    LET headerMs == ReadBytes(headerEpochS.rest, 2) IN IF ~headerMs.ok THEN Fail ELSE
    Ok([ headerEpochS |-> headerEpochS.value,
         headerMs     |-> headerMs.value ], headerMs.rest)

ZeroHeaderTime ==
    [ headerEpochS |-> [i \in 1 .. 4 |-> 0],
      headerMs     |-> [i \in 1 .. 2 |-> 0] ]

(* Header Time at zero, then each field in turn at the values it is checked at *)
CheckedHeaderTime ==
    { ZeroHeaderTime }
        \cup { [ZeroHeaderTime EXCEPT !.headerEpochS = one] : one \in Sample(4) }
        \cup { [ZeroHeaderTime EXCEPT !.headerMs = one] : one \in Sample(2) }

(***************************************************************************)
(* Wake Up Call Message: 5 bytes                                           *)
(***************************************************************************)

WakeUpCallMessage ==
    [ statusCode      : Sample(1),
      startInBoundNum : Sample(4) ]

EncodeWakeUpCallMessage(message) ==
    message.statusCode
        \o message.startInBoundNum

DecodeWakeUpCallMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET startInBoundNum == ReadBytes(statusCode.rest, 4) IN IF ~startInBoundNum.ok THEN Fail ELSE
    Ok([ statusCode      |-> statusCode.value,
         startInBoundNum |-> startInBoundNum.value ], startInBoundNum.rest)

ZeroWakeUpCallMessage ==
    [ statusCode      |-> [i \in 1 .. 1 |-> 0],
      startInBoundNum |-> [i \in 1 .. 4 |-> 0] ]

(* Wake Up Call Message at zero, then each field in turn at the values it is checked at *)
CheckedWakeUpCallMessage ==
    { ZeroWakeUpCallMessage }
        \cup { [ZeroWakeUpCallMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroWakeUpCallMessage EXCEPT !.startInBoundNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Wake Up Call Confirmed Message: 1 bytes                                 *)
(***************************************************************************)

WakeUpCallConfirmedMessage ==
    [ version : Sample(1) ]

EncodeWakeUpCallConfirmedMessage(message) ==
    message.version

DecodeWakeUpCallConfirmedMessage(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    Ok([ version |-> version.value ], version.rest)

ZeroWakeUpCallConfirmedMessage ==
    [ version |-> [i \in 1 .. 1 |-> 0] ]

(* Wake Up Call Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedWakeUpCallConfirmedMessage ==
    { ZeroWakeUpCallConfirmedMessage }
        \cup { [ZeroWakeUpCallConfirmedMessage EXCEPT !.version = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Notice Message: 9 bytes                                           *)
(***************************************************************************)

LogonNoticeMessage ==
    [ statusCode     : Sample(1),
      appendNo       : Sample(2),
      endOutBoundNum : Sample(4),
      systemType     : Sample(1),
      encryptMethod  : Sample(1) ]

EncodeLogonNoticeMessage(message) ==
    message.statusCode
        \o message.appendNo
        \o message.endOutBoundNum
        \o message.systemType
        \o message.encryptMethod

DecodeLogonNoticeMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET appendNo == ReadBytes(statusCode.rest, 2) IN IF ~appendNo.ok THEN Fail ELSE
    LET endOutBoundNum == ReadBytes(appendNo.rest, 4) IN IF ~endOutBoundNum.ok THEN Fail ELSE
    LET systemType == ReadBytes(endOutBoundNum.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET encryptMethod == ReadBytes(systemType.rest, 1) IN IF ~encryptMethod.ok THEN Fail ELSE
    Ok([ statusCode     |-> statusCode.value,
         appendNo       |-> appendNo.value,
         endOutBoundNum |-> endOutBoundNum.value,
         systemType     |-> systemType.value,
         encryptMethod  |-> encryptMethod.value ], encryptMethod.rest)

ZeroLogonNoticeMessage ==
    [ statusCode     |-> [i \in 1 .. 1 |-> 0],
      appendNo       |-> [i \in 1 .. 2 |-> 0],
      endOutBoundNum |-> [i \in 1 .. 4 |-> 0],
      systemType     |-> [i \in 1 .. 1 |-> 0],
      encryptMethod  |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Notice Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonNoticeMessage ==
    { ZeroLogonNoticeMessage }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.appendNo = one] : one \in Sample(2) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.endOutBoundNum = one] : one \in Sample(4) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.encryptMethod = one] : one \in Sample(1) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr ==
    { ZeroSubHdr }
        \cup { [ZeroSubHdr EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Final Sequential Number Notification For Group Message: 21 bytes        *)
(***************************************************************************)

FinalSequentialNumberNotificationForGroupMessage ==
    [ subHdr         : SubHdr,
      wideStatusCode : Sample(2),
      partId         : Sample(1),
      endOutBoundNum : Sample(4),
      reserved8      : Sample(8) ]

EncodeFinalSequentialNumberNotificationForGroupMessage(message) ==
    EncodeSubHdr(message.subHdr)
        \o message.wideStatusCode
        \o message.partId
        \o message.endOutBoundNum
        \o message.reserved8

DecodeFinalSequentialNumberNotificationForGroupMessage(bytes) ==
    LET subHdr == DecodeSubHdr(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(subHdr.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET partId == ReadBytes(wideStatusCode.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET endOutBoundNum == ReadBytes(partId.rest, 4) IN IF ~endOutBoundNum.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(endOutBoundNum.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ subHdr         |-> subHdr.value,
         wideStatusCode |-> wideStatusCode.value,
         partId         |-> partId.value,
         endOutBoundNum |-> endOutBoundNum.value,
         reserved8      |-> reserved8.value ], reserved8.rest)

ZeroFinalSequentialNumberNotificationForGroupMessage ==
    [ subHdr         |-> ZeroSubHdr,
      wideStatusCode |-> [i \in 1 .. 2 |-> 0],
      partId         |-> [i \in 1 .. 1 |-> 0],
      endOutBoundNum |-> [i \in 1 .. 4 |-> 0],
      reserved8      |-> [i \in 1 .. 8 |-> 0] ]

(* Final Sequential Number Notification For Group Message at zero, then each field in turn at the values it is checked at *)
CheckedFinalSequentialNumberNotificationForGroupMessage ==
    { ZeroFinalSequentialNumberNotificationForGroupMessage }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.endOutBoundNum = one] : one \in Sample(4) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Request Logon Message: 15 bytes                                         *)
(***************************************************************************)

RequestLogonMessage ==
    [ statusCode      : Sample(1),
      appendNo        : Sample(2),
      fcmId           : Sample(2),
      sessionId       : Sample(2),
      systemType      : Sample(1),
      apCode          : Sample(1),
      keyValue        : Sample(1),
      requestStartSeq : Sample(4),
      cancelOrderSec  : Sample(1) ]

EncodeRequestLogonMessage(message) ==
    message.statusCode
        \o message.appendNo
        \o message.fcmId
        \o message.sessionId
        \o message.systemType
        \o message.apCode
        \o message.keyValue
        \o message.requestStartSeq
        \o message.cancelOrderSec

DecodeRequestLogonMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET appendNo == ReadBytes(statusCode.rest, 2) IN IF ~appendNo.ok THEN Fail ELSE
    LET fcmId == ReadBytes(appendNo.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(fcmId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemType == ReadBytes(sessionId.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET apCode == ReadBytes(systemType.rest, 1) IN IF ~apCode.ok THEN Fail ELSE
    LET keyValue == ReadBytes(apCode.rest, 1) IN IF ~keyValue.ok THEN Fail ELSE
    LET requestStartSeq == ReadBytes(keyValue.rest, 4) IN IF ~requestStartSeq.ok THEN Fail ELSE
    LET cancelOrderSec == ReadBytes(requestStartSeq.rest, 1) IN IF ~cancelOrderSec.ok THEN Fail ELSE
    Ok([ statusCode      |-> statusCode.value,
         appendNo        |-> appendNo.value,
         fcmId           |-> fcmId.value,
         sessionId       |-> sessionId.value,
         systemType      |-> systemType.value,
         apCode          |-> apCode.value,
         keyValue        |-> keyValue.value,
         requestStartSeq |-> requestStartSeq.value,
         cancelOrderSec  |-> cancelOrderSec.value ], cancelOrderSec.rest)

ZeroRequestLogonMessage ==
    [ statusCode      |-> [i \in 1 .. 1 |-> 0],
      appendNo        |-> [i \in 1 .. 2 |-> 0],
      fcmId           |-> [i \in 1 .. 2 |-> 0],
      sessionId       |-> [i \in 1 .. 2 |-> 0],
      systemType      |-> [i \in 1 .. 1 |-> 0],
      apCode          |-> [i \in 1 .. 1 |-> 0],
      keyValue        |-> [i \in 1 .. 1 |-> 0],
      requestStartSeq |-> [i \in 1 .. 4 |-> 0],
      cancelOrderSec  |-> [i \in 1 .. 1 |-> 0] ]

(* Request Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestLogonMessage ==
    { ZeroRequestLogonMessage }
        \cup { [ZeroRequestLogonMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.appendNo = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.apCode = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.keyValue = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.requestStartSeq = one] : one \in Sample(4) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.cancelOrderSec = one] : one \in Sample(1) }

(***************************************************************************)
(* Resend Report Message                                                   *)
(***************************************************************************)

ResendReportMessage ==
    [ statusCode               : Sample(1),
      isEof                    : Sample(1),
      fileSize                 : Sample(4),
      dataUint8HdrMsgLength156 : SampleBytes ]

EncodeResendReportMessage(message) ==
    message.statusCode
        \o message.isEof
        \o message.fileSize
        \o message.dataUint8HdrMsgLength156

DecodeResendReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET isEof == ReadBytes(statusCode.rest, 1) IN IF ~isEof.ok THEN Fail ELSE
    LET fileSize == ReadBytes(isEof.rest, 4) IN IF ~fileSize.ok THEN Fail ELSE
    LET dataUint8HdrMsgLength156 == Ok(fileSize.rest, << >>) IN IF ~dataUint8HdrMsgLength156.ok THEN Fail ELSE
    Ok([ statusCode               |-> statusCode.value,
         isEof                    |-> isEof.value,
         fileSize                 |-> fileSize.value,
         dataUint8HdrMsgLength156 |-> dataUint8HdrMsgLength156.value ], dataUint8HdrMsgLength156.rest)

ZeroResendReportMessage ==
    [ statusCode               |-> [i \in 1 .. 1 |-> 0],
      isEof                    |-> [i \in 1 .. 1 |-> 0],
      fileSize                 |-> [i \in 1 .. 4 |-> 0],
      dataUint8HdrMsgLength156 |-> << >> ]

(* Resend Report Message at zero, then each field in turn at the values it is checked at *)
CheckedResendReportMessage ==
    { ZeroResendReportMessage }
        \cup { [ZeroResendReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroResendReportMessage EXCEPT !.isEof = one] : one \in Sample(1) }
        \cup { [ZeroResendReportMessage EXCEPT !.fileSize = one] : one \in Sample(4) }
        \cup { [ZeroResendReportMessage EXCEPT !.dataUint8HdrMsgLength156 = one] : one \in SampleBytes }

(***************************************************************************)
(* Resend Report Confirmed Message: 1 bytes                                *)
(***************************************************************************)

ResendReportConfirmedMessage ==
    [ statusCode : Sample(1) ]

EncodeResendReportConfirmedMessage(message) ==
    message.statusCode

DecodeResendReportConfirmedMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value ], statusCode.rest)

ZeroResendReportConfirmedMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Resend Report Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedResendReportConfirmedMessage ==
    { ZeroResendReportConfirmedMessage }
        \cup { [ZeroResendReportConfirmedMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Activate Application System Message: 4 bytes                            *)
(***************************************************************************)

ActivateApplicationSystemMessage ==
    [ statusCode     : Sample(1),
      heartBtInt     : Sample(1),
      maxFlowCtrlCnt : Sample(2) ]

EncodeActivateApplicationSystemMessage(message) ==
    message.statusCode
        \o message.heartBtInt
        \o message.maxFlowCtrlCnt

DecodeActivateApplicationSystemMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(statusCode.rest, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET maxFlowCtrlCnt == ReadBytes(heartBtInt.rest, 2) IN IF ~maxFlowCtrlCnt.ok THEN Fail ELSE
    Ok([ statusCode     |-> statusCode.value,
         heartBtInt     |-> heartBtInt.value,
         maxFlowCtrlCnt |-> maxFlowCtrlCnt.value ], maxFlowCtrlCnt.rest)

ZeroActivateApplicationSystemMessage ==
    [ statusCode     |-> [i \in 1 .. 1 |-> 0],
      heartBtInt     |-> [i \in 1 .. 1 |-> 0],
      maxFlowCtrlCnt |-> [i \in 1 .. 2 |-> 0] ]

(* Activate Application System Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemMessage ==
    { ZeroActivateApplicationSystemMessage }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.heartBtInt = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.maxFlowCtrlCnt = one] : one \in Sample(2) }

(***************************************************************************)
(* Activate Application System Confirmed Message: 1 bytes                  *)
(***************************************************************************)

ActivateApplicationSystemConfirmedMessage ==
    [ statusCode : Sample(1) ]

EncodeActivateApplicationSystemConfirmedMessage(message) ==
    message.statusCode

DecodeActivateApplicationSystemConfirmedMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value ], statusCode.rest)

ZeroActivateApplicationSystemConfirmedMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Activate Application System Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemConfirmedMessage ==
    { ZeroActivateApplicationSystemConfirmedMessage }
        \cup { [ZeroActivateApplicationSystemConfirmedMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Logout Confirmed Message: 1 bytes                                       *)
(***************************************************************************)

LogoutConfirmedMessage ==
    [ statusCode : Sample(1) ]

EncodeLogoutConfirmedMessage(message) ==
    message.statusCode

DecodeLogoutConfirmedMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value ], statusCode.rest)

ZeroLogoutConfirmedMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Logout Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutConfirmedMessage ==
    { ZeroLogoutConfirmedMessage }
        \cup { [ZeroLogoutConfirmedMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Confirm Connection Message: 1 bytes                                     *)
(***************************************************************************)

ConfirmConnectionMessage ==
    [ statusCode : Sample(1) ]

EncodeConfirmConnectionMessage(message) ==
    message.statusCode

DecodeConfirmConnectionMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value ], statusCode.rest)

ZeroConfirmConnectionMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Confirm Connection Message at zero, then each field in turn at the values it is checked at *)
CheckedConfirmConnectionMessage ==
    { ZeroConfirmConnectionMessage }
        \cup { [ZeroConfirmConnectionMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Connection Confirmed Message: 1 bytes                                   *)
(***************************************************************************)

ConnectionConfirmedMessage ==
    [ statusCode : Sample(1) ]

EncodeConnectionConfirmedMessage(message) ==
    message.statusCode

DecodeConnectionConfirmedMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value ], statusCode.rest)

ZeroConnectionConfirmedMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0] ]

(* Connection Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedConnectionConfirmedMessage ==
    { ZeroConnectionConfirmedMessage }
        \cup { [ZeroConnectionConfirmedMessage EXCEPT !.statusCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Session Status Request Message: 5 bytes                           *)
(***************************************************************************)

TradeSessionStatusRequestMessage ==
    [ statusCode              : Sample(1),
      tradeReqId              : Sample(2),
      flowGroupNo             : Sample(1),
      subscriptionRequestType : Sample(1) ]

EncodeTradeSessionStatusRequestMessage(message) ==
    message.statusCode
        \o message.tradeReqId
        \o message.flowGroupNo
        \o message.subscriptionRequestType

DecodeTradeSessionStatusRequestMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET tradeReqId == ReadBytes(statusCode.rest, 2) IN IF ~tradeReqId.ok THEN Fail ELSE
    LET flowGroupNo == ReadBytes(tradeReqId.rest, 1) IN IF ~flowGroupNo.ok THEN Fail ELSE
    LET subscriptionRequestType == ReadBytes(flowGroupNo.rest, 1) IN IF ~subscriptionRequestType.ok THEN Fail ELSE
    Ok([ statusCode              |-> statusCode.value,
         tradeReqId              |-> tradeReqId.value,
         flowGroupNo             |-> flowGroupNo.value,
         subscriptionRequestType |-> subscriptionRequestType.value ], subscriptionRequestType.rest)

ZeroTradeSessionStatusRequestMessage ==
    [ statusCode              |-> [i \in 1 .. 1 |-> 0],
      tradeReqId              |-> [i \in 1 .. 2 |-> 0],
      flowGroupNo             |-> [i \in 1 .. 1 |-> 0],
      subscriptionRequestType |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Session Status Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSessionStatusRequestMessage ==
    { ZeroTradeSessionStatusRequestMessage }
        \cup { [ZeroTradeSessionStatusRequestMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeSessionStatusRequestMessage EXCEPT !.tradeReqId = one] : one \in Sample(2) }
        \cup { [ZeroTradeSessionStatusRequestMessage EXCEPT !.flowGroupNo = one] : one \in Sample(1) }
        \cup { [ZeroTradeSessionStatusRequestMessage EXCEPT !.subscriptionRequestType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Session Status Report Message: 5 bytes                            *)
(***************************************************************************)

TradeSessionStatusReportMessage ==
    [ statusCode  : Sample(1),
      tradeReqId  : Sample(2),
      flowGroupNo : Sample(1),
      tradeStatus : Sample(1) ]

EncodeTradeSessionStatusReportMessage(message) ==
    message.statusCode
        \o message.tradeReqId
        \o message.flowGroupNo
        \o message.tradeStatus

DecodeTradeSessionStatusReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET tradeReqId == ReadBytes(statusCode.rest, 2) IN IF ~tradeReqId.ok THEN Fail ELSE
    LET flowGroupNo == ReadBytes(tradeReqId.rest, 1) IN IF ~flowGroupNo.ok THEN Fail ELSE
    LET tradeStatus == ReadBytes(flowGroupNo.rest, 1) IN IF ~tradeStatus.ok THEN Fail ELSE
    Ok([ statusCode  |-> statusCode.value,
         tradeReqId  |-> tradeReqId.value,
         flowGroupNo |-> flowGroupNo.value,
         tradeStatus |-> tradeStatus.value ], tradeStatus.rest)

ZeroTradeSessionStatusReportMessage ==
    [ statusCode  |-> [i \in 1 .. 1 |-> 0],
      tradeReqId  |-> [i \in 1 .. 2 |-> 0],
      flowGroupNo |-> [i \in 1 .. 1 |-> 0],
      tradeStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Session Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSessionStatusReportMessage ==
    { ZeroTradeSessionStatusReportMessage }
        \cup { [ZeroTradeSessionStatusReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeSessionStatusReportMessage EXCEPT !.tradeReqId = one] : one \in Sample(2) }
        \cup { [ZeroTradeSessionStatusReportMessage EXCEPT !.flowGroupNo = one] : one \in Sample(1) }
        \cup { [ZeroTradeSessionStatusReportMessage EXCEPT !.tradeStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum ==
    { ZeroSymbolNum }
        \cup { [ZeroSymbolNum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText ==
    [ symbol : Sample(20) ]

EncodeSymbolText(message) ==
    message.symbol

DecodeSymbolText(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText ==
    { ZeroSymbolText }
        \cup { [ZeroSymbolText EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode == 1  \* 0x01
SymbolTextCode == 2  \* 0x02

SymSymbolX ==
    [ tag : {SymbolNumCode}, body : SymbolNum ]
        \cup [ tag : {SymbolTextCode}, body : SymbolText ]

EncodeSymSymbolX(message) ==
    CASE message.tag = SymbolNumCode -> EncodeSymbolNum(message.body)
      [] message.tag = SymbolTextCode -> EncodeSymbolText(message.body)

DecodeSymSymbolX(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode -> DecodeSymbolNum(bytes)
              [] tag = SymbolTextCode -> DecodeSymbolText(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX == [tag |-> SymbolNumCode, body |-> ZeroSymbolNum]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX ==
    { [tag |-> SymbolNumCode, body |-> one] : one \in CheckedSymbolNum }
        \cup { [tag |-> SymbolTextCode, body |-> one] : one \in CheckedSymbolText }

(***************************************************************************)
(* Order Input Message                                                     *)
(***************************************************************************)

OrderInputMessage ==
    [ execType       : Sample(1),
      cmId           : Sample(2),
      fcmId          : Sample(2),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      userDefine     : Sample(8),
      symSymbolX     : SymSymbolX,
      price          : Sample(4),
      qty            : Sample(2),
      investorAcno   : Sample(4),
      investorFlag   : Sample(1),
      side           : Sample(1),
      ordType        : Sample(1),
      timeInForce    : Sample(1),
      positionEffect : Sample(1),
      orderSource    : Sample(1),
      infoSource     : Sample(3) ]

EncodeOrderInputMessage(message) ==
    message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX(message.symSymbolX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.orderSource
        \o message.infoSource

DecodeOrderInputMessage(bytes) ==
    LET execType == ReadBytes(bytes, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    LET price == ReadBytes(symSymbolX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET orderSource == ReadBytes(positionEffect.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ execType       |-> execType.value,
         cmId           |-> cmId.value,
         fcmId          |-> fcmId.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         userDefine     |-> userDefine.value,
         symSymbolX     |-> symSymbolX.value,
         price          |-> price.value,
         qty            |-> qty.value,
         investorAcno   |-> investorAcno.value,
         investorFlag   |-> investorFlag.value,
         side           |-> side.value,
         ordType        |-> ordType.value,
         timeInForce    |-> timeInForce.value,
         positionEffect |-> positionEffect.value,
         orderSource    |-> orderSource.value,
         infoSource     |-> infoSource.value ], infoSource.rest)

ZeroOrderInputMessage ==
    [ execType       |-> [i \in 1 .. 1 |-> 0],
      cmId           |-> [i \in 1 .. 2 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      userDefine     |-> [i \in 1 .. 8 |-> 0],
      symSymbolX     |-> ZeroSymSymbolX,
      price          |-> [i \in 1 .. 4 |-> 0],
      qty            |-> [i \in 1 .. 2 |-> 0],
      investorAcno   |-> [i \in 1 .. 4 |-> 0],
      investorFlag   |-> [i \in 1 .. 1 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      ordType        |-> [i \in 1 .. 1 |-> 0],
      timeInForce    |-> [i \in 1 .. 1 |-> 0],
      positionEffect |-> [i \in 1 .. 1 |-> 0],
      orderSource    |-> [i \in 1 .. 1 |-> 0],
      infoSource     |-> [i \in 1 .. 3 |-> 0] ]

(* Order Input Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderInputMessage ==
    { ZeroOrderInputMessage }
        \cup { [ZeroOrderInputMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderInputMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderInputMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX }
        \cup { [ZeroOrderInputMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved33   : Sample(33) ]

EncodeLongSymbolNum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved33   |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved33   |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum ==
    { ZeroLongSymbolNum }
        \cup { [ZeroLongSymbolNum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText ==
    [ longSymbol : Sample(40) ]

EncodeLongSymbolText(message) ==
    message.longSymbol

DecodeLongSymbolText(bytes) ==
    LET longSymbol == ReadBytes(bytes, 40) IN IF ~longSymbol.ok THEN Fail ELSE
    Ok([ longSymbol |-> longSymbol.value ], longSymbol.rest)

ZeroLongSymbolText ==
    [ longSymbol |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText ==
    { ZeroLongSymbolText }
        \cup { [ZeroLongSymbolText EXCEPT !.longSymbol = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Long Symbol X, selected by Symbol Type                              *)
(***************************************************************************)

LongSymbolNumCode == 3  \* 0x03
LongSymbolTextCode == 4  \* 0x04

SymLongSymbolX ==
    [ tag : {LongSymbolNumCode}, body : LongSymbolNum ]
        \cup [ tag : {LongSymbolTextCode}, body : LongSymbolText ]

EncodeSymLongSymbolX(message) ==
    CASE message.tag = LongSymbolNumCode -> EncodeLongSymbolNum(message.body)
      [] message.tag = LongSymbolTextCode -> EncodeLongSymbolText(message.body)

DecodeSymLongSymbolX(tag, bytes) ==
    LET read ==
            CASE tag = LongSymbolNumCode -> DecodeLongSymbolNum(bytes)
              [] tag = LongSymbolTextCode -> DecodeLongSymbolText(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongSymbolX == [tag |-> LongSymbolNumCode, body |-> ZeroLongSymbolNum]

(* Each Sym Long Symbol X in turn, at the values the message it names is checked at *)
CheckedSymLongSymbolX ==
    { [tag |-> LongSymbolNumCode, body |-> one] : one \in CheckedLongSymbolNum }
        \cup { [tag |-> LongSymbolTextCode, body |-> one] : one \in CheckedLongSymbolText }

(***************************************************************************)
(* Order Input Long Format Message                                         *)
(***************************************************************************)

OrderInputLongFormatMessage ==
    [ execType       : Sample(1),
      cmId           : Sample(2),
      fcmId          : Sample(2),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      userDefine     : Sample(8),
      symLongSymbolX : SymLongSymbolX,
      price          : Sample(4),
      qty            : Sample(2),
      investorAcno   : Sample(4),
      investorFlag   : Sample(1),
      side           : Sample(1),
      ordType        : Sample(1),
      timeInForce    : Sample(1),
      positionEffect : Sample(1),
      orderSource    : Sample(1),
      infoSource     : Sample(3) ]

EncodeOrderInputLongFormatMessage(message) ==
    message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symLongSymbolX.tag, 1)
        \o EncodeSymLongSymbolX(message.symLongSymbolX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.orderSource
        \o message.infoSource

DecodeOrderInputLongFormatMessage(bytes) ==
    LET execType == ReadBytes(bytes, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symLongSymbolX == DecodeSymLongSymbolX(symbolType.value, symbolType.rest) IN IF ~symLongSymbolX.ok THEN Fail ELSE
    LET price == ReadBytes(symLongSymbolX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET orderSource == ReadBytes(positionEffect.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ execType       |-> execType.value,
         cmId           |-> cmId.value,
         fcmId          |-> fcmId.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         userDefine     |-> userDefine.value,
         symLongSymbolX |-> symLongSymbolX.value,
         price          |-> price.value,
         qty            |-> qty.value,
         investorAcno   |-> investorAcno.value,
         investorFlag   |-> investorFlag.value,
         side           |-> side.value,
         ordType        |-> ordType.value,
         timeInForce    |-> timeInForce.value,
         positionEffect |-> positionEffect.value,
         orderSource    |-> orderSource.value,
         infoSource     |-> infoSource.value ], infoSource.rest)

ZeroOrderInputLongFormatMessage ==
    [ execType       |-> [i \in 1 .. 1 |-> 0],
      cmId           |-> [i \in 1 .. 2 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      userDefine     |-> [i \in 1 .. 8 |-> 0],
      symLongSymbolX |-> ZeroSymLongSymbolX,
      price          |-> [i \in 1 .. 4 |-> 0],
      qty            |-> [i \in 1 .. 2 |-> 0],
      investorAcno   |-> [i \in 1 .. 4 |-> 0],
      investorFlag   |-> [i \in 1 .. 1 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      ordType        |-> [i \in 1 .. 1 |-> 0],
      timeInForce    |-> [i \in 1 .. 1 |-> 0],
      positionEffect |-> [i \in 1 .. 1 |-> 0],
      orderSource    |-> [i \in 1 .. 1 |-> 0],
      infoSource     |-> [i \in 1 .. 3 |-> 0] ]

(* Order Input Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderInputLongFormatMessage ==
    { ZeroOrderInputLongFormatMessage }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroOrderInputLongFormatMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum2 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum2(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum2(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum2 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum2 ==
    { ZeroSymbolNum2 }
        \cup { [ZeroSymbolNum2 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum2 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum2 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum2 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum2 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText2 ==
    [ symbol : Sample(20) ]

EncodeSymbolText2(message) ==
    message.symbol

DecodeSymbolText2(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText2 ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText2 ==
    { ZeroSymbolText2 }
        \cup { [ZeroSymbolText2 EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode2 == 1  \* 0x01
SymbolTextCode2 == 2  \* 0x02

SymSymbolX2 ==
    [ tag : {SymbolNumCode2}, body : SymbolNum2 ]
        \cup [ tag : {SymbolTextCode2}, body : SymbolText2 ]

EncodeSymSymbolX2(message) ==
    CASE message.tag = SymbolNumCode2 -> EncodeSymbolNum2(message.body)
      [] message.tag = SymbolTextCode2 -> EncodeSymbolText2(message.body)

DecodeSymSymbolX2(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode2 -> DecodeSymbolNum2(bytes)
              [] tag = SymbolTextCode2 -> DecodeSymbolText2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX2 == [tag |-> SymbolNumCode2, body |-> ZeroSymbolNum2]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX2 ==
    { [tag |-> SymbolNumCode2, body |-> one] : one \in CheckedSymbolNum2 }
        \cup { [tag |-> SymbolTextCode2, body |-> one] : one \in CheckedSymbolText2 }

(***************************************************************************)
(* Org Trans Time Msg Time: 6 bytes                                        *)
(***************************************************************************)

OrgTransTimeMsgTime ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeOrgTransTimeMsgTime(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeOrgTransTimeMsgTime(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroOrgTransTimeMsgTime ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Org Trans Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTime ==
    { ZeroOrgTransTimeMsgTime }
        \cup { [ZeroOrgTransTimeMsgTime EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeTransactTimeMsgTime(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeTransactTimeMsgTime(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime ==
    { ZeroTransactTimeMsgTime }
        \cup { [ZeroTransactTimeMsgTime EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Message                                             *)
(***************************************************************************)

OrderStatusReportMessage ==
    [ statusCode          : Sample(1),
      execType            : Sample(1),
      cmId                : Sample(2),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      symSymbolX          : SymSymbolX2,
      price               : Sample(4),
      qty                 : Sample(2),
      investorAcno        : Sample(4),
      investorFlag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxSubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeQty           : Sample(2),
      bothLegSides        : Sample(1),
      legPx               : Sample(4),
      bothLegQtys         : Sample(2),
      orgTransTimeMsgTime : OrgTransTimeMsgTime,
      transactTimeMsgTime : TransactTimeMsgTime,
      targetId            : Sample(1),
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1) ]

EncodeOrderStatusReportMessage(message) ==
    message.statusCode
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX2(message.symSymbolX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o message.bothLegSides
        \o message.legPx
        \o message.bothLegQtys
        \o EncodeOrgTransTimeMsgTime(message.orgTransTimeMsgTime)
        \o EncodeTransactTimeMsgTime(message.transactTimeMsgTime)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType

DecodeOrderStatusReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX2(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    LET price == ReadBytes(symSymbolX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(beforeQty.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET legPx == ReadBytes(bothLegSides.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET bothLegQtys == ReadBytes(legPx.rest, 2) IN IF ~bothLegQtys.ok THEN Fail ELSE
    LET orgTransTimeMsgTime == DecodeOrgTransTimeMsgTime(bothLegQtys.rest) IN IF ~orgTransTimeMsgTime.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime(orgTransTimeMsgTime.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTime.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    Ok([ statusCode          |-> statusCode.value,
         execType            |-> execType.value,
         cmId                |-> cmId.value,
         fcmId               |-> fcmId.value,
         orderNo             |-> orderNo.value,
         ordId               |-> ordId.value,
         userDefine          |-> userDefine.value,
         symSymbolX          |-> symSymbolX.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investorAcno        |-> investorAcno.value,
         investorFlag        |-> investorFlag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxSubtotal          |-> pxSubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeQty           |-> beforeQty.value,
         bothLegSides        |-> bothLegSides.value,
         legPx               |-> legPx.value,
         bothLegQtys         |-> bothLegQtys.value,
         orgTransTimeMsgTime |-> orgTransTimeMsgTime.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         targetId            |-> targetId.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value ], protocolType.rest)

ZeroOrderStatusReportMessage ==
    [ statusCode          |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmId                |-> [i \in 1 .. 2 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      symSymbolX          |-> ZeroSymSymbolX2,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investorAcno        |-> [i \in 1 .. 4 |-> 0],
      investorFlag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxSubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeQty           |-> [i \in 1 .. 2 |-> 0],
      bothLegSides        |-> [i \in 1 .. 1 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      bothLegQtys         |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTime |-> ZeroOrgTransTimeMsgTime,
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime,
      targetId            |-> [i \in 1 .. 1 |-> 0],
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportMessage ==
    { ZeroOrderStatusReportMessage }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX2 }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.pxSubtotal = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.beforeQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.bothLegQtys = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orgTransTimeMsgTime = one] : one \in CheckedOrgTransTimeMsgTime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.transactTimeMsgTime = one] : one \in CheckedTransactTimeMsgTime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.protocolType = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum2 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved33   : Sample(33) ]

EncodeLongSymbolNum2(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum2(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved33   |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum2 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved33   |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum2 ==
    { ZeroLongSymbolNum2 }
        \cup { [ZeroLongSymbolNum2 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum2 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum2 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum2 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum2 EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText2 ==
    [ longSymbol : Sample(40) ]

EncodeLongSymbolText2(message) ==
    message.longSymbol

DecodeLongSymbolText2(bytes) ==
    LET longSymbol == ReadBytes(bytes, 40) IN IF ~longSymbol.ok THEN Fail ELSE
    Ok([ longSymbol |-> longSymbol.value ], longSymbol.rest)

ZeroLongSymbolText2 ==
    [ longSymbol |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText2 ==
    { ZeroLongSymbolText2 }
        \cup { [ZeroLongSymbolText2 EXCEPT !.longSymbol = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Long Symbol X, selected by Symbol Type                              *)
(***************************************************************************)

LongSymbolNumCode2 == 3  \* 0x03
LongSymbolTextCode2 == 4  \* 0x04

SymLongSymbolX2 ==
    [ tag : {LongSymbolNumCode2}, body : LongSymbolNum2 ]
        \cup [ tag : {LongSymbolTextCode2}, body : LongSymbolText2 ]

EncodeSymLongSymbolX2(message) ==
    CASE message.tag = LongSymbolNumCode2 -> EncodeLongSymbolNum2(message.body)
      [] message.tag = LongSymbolTextCode2 -> EncodeLongSymbolText2(message.body)

DecodeSymLongSymbolX2(tag, bytes) ==
    LET read ==
            CASE tag = LongSymbolNumCode2 -> DecodeLongSymbolNum2(bytes)
              [] tag = LongSymbolTextCode2 -> DecodeLongSymbolText2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongSymbolX2 == [tag |-> LongSymbolNumCode2, body |-> ZeroLongSymbolNum2]

(* Each Sym Long Symbol X in turn, at the values the message it names is checked at *)
CheckedSymLongSymbolX2 ==
    { [tag |-> LongSymbolNumCode2, body |-> one] : one \in CheckedLongSymbolNum2 }
        \cup { [tag |-> LongSymbolTextCode2, body |-> one] : one \in CheckedLongSymbolText2 }

(***************************************************************************)
(* Org Trans Time Msg Time: 6 bytes                                        *)
(***************************************************************************)

OrgTransTimeMsgTime2 ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeOrgTransTimeMsgTime2(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeOrgTransTimeMsgTime2(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroOrgTransTimeMsgTime2 ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Org Trans Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTime2 ==
    { ZeroOrgTransTimeMsgTime2 }
        \cup { [ZeroOrgTransTimeMsgTime2 EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime2 ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeTransactTimeMsgTime2(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeTransactTimeMsgTime2(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime2 ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime2 ==
    { ZeroTransactTimeMsgTime2 }
        \cup { [ZeroTransactTimeMsgTime2 EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Long Format Message                                 *)
(***************************************************************************)

OrderStatusReportLongFormatMessage ==
    [ statusCode          : Sample(1),
      execType            : Sample(1),
      cmId                : Sample(2),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      symLongSymbolX      : SymLongSymbolX2,
      price               : Sample(4),
      qty                 : Sample(2),
      investorAcno        : Sample(4),
      investorFlag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxSubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeQty           : Sample(2),
      bothLegSides        : Sample(1),
      legPx               : Sample(4),
      bothLegQtys         : Sample(2),
      orgTransTimeMsgTime : OrgTransTimeMsgTime2,
      transactTimeMsgTime : TransactTimeMsgTime2,
      targetId            : Sample(1),
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1) ]

EncodeOrderStatusReportLongFormatMessage(message) ==
    message.statusCode
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symLongSymbolX.tag, 1)
        \o EncodeSymLongSymbolX2(message.symLongSymbolX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o message.bothLegSides
        \o message.legPx
        \o message.bothLegQtys
        \o EncodeOrgTransTimeMsgTime2(message.orgTransTimeMsgTime)
        \o EncodeTransactTimeMsgTime2(message.transactTimeMsgTime)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType

DecodeOrderStatusReportLongFormatMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symLongSymbolX == DecodeSymLongSymbolX2(symbolType.value, symbolType.rest) IN IF ~symLongSymbolX.ok THEN Fail ELSE
    LET price == ReadBytes(symLongSymbolX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(beforeQty.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET legPx == ReadBytes(bothLegSides.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET bothLegQtys == ReadBytes(legPx.rest, 2) IN IF ~bothLegQtys.ok THEN Fail ELSE
    LET orgTransTimeMsgTime == DecodeOrgTransTimeMsgTime2(bothLegQtys.rest) IN IF ~orgTransTimeMsgTime.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime2(orgTransTimeMsgTime.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTime.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    Ok([ statusCode          |-> statusCode.value,
         execType            |-> execType.value,
         cmId                |-> cmId.value,
         fcmId               |-> fcmId.value,
         orderNo             |-> orderNo.value,
         ordId               |-> ordId.value,
         userDefine          |-> userDefine.value,
         symLongSymbolX      |-> symLongSymbolX.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investorAcno        |-> investorAcno.value,
         investorFlag        |-> investorFlag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxSubtotal          |-> pxSubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeQty           |-> beforeQty.value,
         bothLegSides        |-> bothLegSides.value,
         legPx               |-> legPx.value,
         bothLegQtys         |-> bothLegQtys.value,
         orgTransTimeMsgTime |-> orgTransTimeMsgTime.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         targetId            |-> targetId.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value ], protocolType.rest)

ZeroOrderStatusReportLongFormatMessage ==
    [ statusCode          |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmId                |-> [i \in 1 .. 2 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      symLongSymbolX      |-> ZeroSymLongSymbolX2,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investorAcno        |-> [i \in 1 .. 4 |-> 0],
      investorFlag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxSubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeQty           |-> [i \in 1 .. 2 |-> 0],
      bothLegSides        |-> [i \in 1 .. 1 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      bothLegQtys         |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTime |-> ZeroOrgTransTimeMsgTime2,
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime2,
      targetId            |-> [i \in 1 .. 1 |-> 0],
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportLongFormatMessage ==
    { ZeroOrderStatusReportLongFormatMessage }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX2 }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.pxSubtotal = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.beforeQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.bothLegQtys = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.orgTransTimeMsgTime = one] : one \in CheckedOrgTransTimeMsgTime2 }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.transactTimeMsgTime = one] : one \in CheckedTransactTimeMsgTime2 }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.protocolType = one] : one \in Sample(1) }

(***************************************************************************)
(* Error Report Message: 26 bytes                                          *)
(***************************************************************************)

ErrorReportMessage ==
    [ statusCode : Sample(1),
      execType   : Sample(1),
      fcmId      : Sample(2),
      orderNo    : Sample(5),
      ordId      : Sample(4),
      userDefine : Sample(8),
      rptSeq     : Sample(4),
      side       : Sample(1) ]

EncodeErrorReportMessage(message) ==
    message.statusCode
        \o message.execType
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o message.rptSeq
        \o message.side

DecodeErrorReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(execType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(userDefine.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET side == ReadBytes(rptSeq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value,
         execType   |-> execType.value,
         fcmId      |-> fcmId.value,
         orderNo    |-> orderNo.value,
         ordId      |-> ordId.value,
         userDefine |-> userDefine.value,
         rptSeq     |-> rptSeq.value,
         side       |-> side.value ], side.rest)

ZeroErrorReportMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0],
      execType   |-> [i \in 1 .. 1 |-> 0],
      fcmId      |-> [i \in 1 .. 2 |-> 0],
      orderNo    |-> [i \in 1 .. 5 |-> 0],
      ordId      |-> [i \in 1 .. 4 |-> 0],
      userDefine |-> [i \in 1 .. 8 |-> 0],
      rptSeq     |-> [i \in 1 .. 4 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0] ]

(* Error Report Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorReportMessage ==
    { ZeroErrorReportMessage }
        \cup { [ZeroErrorReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroErrorReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroErrorReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroErrorReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroErrorReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroErrorReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroErrorReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroErrorReportMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum3 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum3(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum3(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum3 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum3 ==
    { ZeroSymbolNum3 }
        \cup { [ZeroSymbolNum3 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum3 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum3 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum3 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum3 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText3 ==
    [ symbol : Sample(20) ]

EncodeSymbolText3(message) ==
    message.symbol

DecodeSymbolText3(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText3 ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText3 ==
    { ZeroSymbolText3 }
        \cup { [ZeroSymbolText3 EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode3 == 1  \* 0x01
SymbolTextCode3 == 2  \* 0x02

SymSymbolX3 ==
    [ tag : {SymbolNumCode3}, body : SymbolNum3 ]
        \cup [ tag : {SymbolTextCode3}, body : SymbolText3 ]

EncodeSymSymbolX3(message) ==
    CASE message.tag = SymbolNumCode3 -> EncodeSymbolNum3(message.body)
      [] message.tag = SymbolTextCode3 -> EncodeSymbolText3(message.body)

DecodeSymSymbolX3(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode3 -> DecodeSymbolNum3(bytes)
              [] tag = SymbolTextCode3 -> DecodeSymbolText3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX3 == [tag |-> SymbolNumCode3, body |-> ZeroSymbolNum3]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX3 ==
    { [tag |-> SymbolNumCode3, body |-> one] : one \in CheckedSymbolNum3 }
        \cup { [tag |-> SymbolTextCode3, body |-> one] : one \in CheckedSymbolText3 }

(***************************************************************************)
(* Price Inquiry Input Message                                             *)
(***************************************************************************)

PriceInquiryInputMessage ==
    [ orderNo     : Sample(5),
      ordId       : Sample(4),
      fcmId       : Sample(2),
      symSymbolX  : SymSymbolX3,
      orderSource : Sample(1),
      infoSource  : Sample(3) ]

EncodePriceInquiryInputMessage(message) ==
    message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX3(message.symSymbolX)
        \o message.orderSource
        \o message.infoSource

DecodePriceInquiryInputMessage(bytes) ==
    LET orderNo == ReadBytes(bytes, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(fcmId.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX3(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    LET orderSource == ReadBytes(symSymbolX.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ orderNo     |-> orderNo.value,
         ordId       |-> ordId.value,
         fcmId       |-> fcmId.value,
         symSymbolX  |-> symSymbolX.value,
         orderSource |-> orderSource.value,
         infoSource  |-> infoSource.value ], infoSource.rest)

ZeroPriceInquiryInputMessage ==
    [ orderNo     |-> [i \in 1 .. 5 |-> 0],
      ordId       |-> [i \in 1 .. 4 |-> 0],
      fcmId       |-> [i \in 1 .. 2 |-> 0],
      symSymbolX  |-> ZeroSymSymbolX3,
      orderSource |-> [i \in 1 .. 1 |-> 0],
      infoSource  |-> [i \in 1 .. 3 |-> 0] ]

(* Price Inquiry Input Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceInquiryInputMessage ==
    { ZeroPriceInquiryInputMessage }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX3 }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroPriceInquiryInputMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum3 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved33   : Sample(33) ]

EncodeLongSymbolNum3(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum3(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved33   |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum3 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved33   |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum3 ==
    { ZeroLongSymbolNum3 }
        \cup { [ZeroLongSymbolNum3 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum3 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum3 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum3 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum3 EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText3 ==
    [ longSymbol : Sample(40) ]

EncodeLongSymbolText3(message) ==
    message.longSymbol

DecodeLongSymbolText3(bytes) ==
    LET longSymbol == ReadBytes(bytes, 40) IN IF ~longSymbol.ok THEN Fail ELSE
    Ok([ longSymbol |-> longSymbol.value ], longSymbol.rest)

ZeroLongSymbolText3 ==
    [ longSymbol |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText3 ==
    { ZeroLongSymbolText3 }
        \cup { [ZeroLongSymbolText3 EXCEPT !.longSymbol = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Long Symbol X, selected by Symbol Type                              *)
(***************************************************************************)

LongSymbolNumCode3 == 3  \* 0x03
LongSymbolTextCode3 == 4  \* 0x04

SymLongSymbolX3 ==
    [ tag : {LongSymbolNumCode3}, body : LongSymbolNum3 ]
        \cup [ tag : {LongSymbolTextCode3}, body : LongSymbolText3 ]

EncodeSymLongSymbolX3(message) ==
    CASE message.tag = LongSymbolNumCode3 -> EncodeLongSymbolNum3(message.body)
      [] message.tag = LongSymbolTextCode3 -> EncodeLongSymbolText3(message.body)

DecodeSymLongSymbolX3(tag, bytes) ==
    LET read ==
            CASE tag = LongSymbolNumCode3 -> DecodeLongSymbolNum3(bytes)
              [] tag = LongSymbolTextCode3 -> DecodeLongSymbolText3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongSymbolX3 == [tag |-> LongSymbolNumCode3, body |-> ZeroLongSymbolNum3]

(* Each Sym Long Symbol X in turn, at the values the message it names is checked at *)
CheckedSymLongSymbolX3 ==
    { [tag |-> LongSymbolNumCode3, body |-> one] : one \in CheckedLongSymbolNum3 }
        \cup { [tag |-> LongSymbolTextCode3, body |-> one] : one \in CheckedLongSymbolText3 }

(***************************************************************************)
(* Price Inquiry Input Long Format Message                                 *)
(***************************************************************************)

PriceInquiryInputLongFormatMessage ==
    [ orderNo        : Sample(5),
      ordId          : Sample(4),
      fcmId          : Sample(2),
      symLongSymbolX : SymLongSymbolX3,
      orderSource    : Sample(1),
      infoSource     : Sample(3) ]

EncodePriceInquiryInputLongFormatMessage(message) ==
    message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeUIntBE(message.symLongSymbolX.tag, 1)
        \o EncodeSymLongSymbolX3(message.symLongSymbolX)
        \o message.orderSource
        \o message.infoSource

DecodePriceInquiryInputLongFormatMessage(bytes) ==
    LET orderNo == ReadBytes(bytes, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(fcmId.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symLongSymbolX == DecodeSymLongSymbolX3(symbolType.value, symbolType.rest) IN IF ~symLongSymbolX.ok THEN Fail ELSE
    LET orderSource == ReadBytes(symLongSymbolX.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         fcmId          |-> fcmId.value,
         symLongSymbolX |-> symLongSymbolX.value,
         orderSource    |-> orderSource.value,
         infoSource     |-> infoSource.value ], infoSource.rest)

ZeroPriceInquiryInputLongFormatMessage ==
    [ orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      symLongSymbolX |-> ZeroSymLongSymbolX3,
      orderSource    |-> [i \in 1 .. 1 |-> 0],
      infoSource     |-> [i \in 1 .. 3 |-> 0] ]

(* Price Inquiry Input Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceInquiryInputLongFormatMessage ==
    { ZeroPriceInquiryInputLongFormatMessage }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX3 }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroPriceInquiryInputLongFormatMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum4 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum4(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum4(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum4 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum4 ==
    { ZeroSymbolNum4 }
        \cup { [ZeroSymbolNum4 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum4 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum4 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum4 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum4 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText4 ==
    [ symbol : Sample(20) ]

EncodeSymbolText4(message) ==
    message.symbol

DecodeSymbolText4(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText4 ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText4 ==
    { ZeroSymbolText4 }
        \cup { [ZeroSymbolText4 EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode4 == 1  \* 0x01
SymbolTextCode4 == 2  \* 0x02

SymSymbolX4 ==
    [ tag : {SymbolNumCode4}, body : SymbolNum4 ]
        \cup [ tag : {SymbolTextCode4}, body : SymbolText4 ]

EncodeSymSymbolX4(message) ==
    CASE message.tag = SymbolNumCode4 -> EncodeSymbolNum4(message.body)
      [] message.tag = SymbolTextCode4 -> EncodeSymbolText4(message.body)

DecodeSymSymbolX4(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode4 -> DecodeSymbolNum4(bytes)
              [] tag = SymbolTextCode4 -> DecodeSymbolText4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX4 == [tag |-> SymbolNumCode4, body |-> ZeroSymbolNum4]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX4 ==
    { [tag |-> SymbolNumCode4, body |-> one] : one \in CheckedSymbolNum4 }
        \cup { [tag |-> SymbolTextCode4, body |-> one] : one \in CheckedSymbolText4 }

(***************************************************************************)
(* Price Inquiry Reply Message                                             *)
(***************************************************************************)

PriceInquiryReplyMessage ==
    [ statusCode : Sample(1),
      orderNo    : Sample(5),
      ordId      : Sample(4),
      fcmId      : Sample(2),
      symSymbolX : SymSymbolX4 ]

EncodePriceInquiryReplyMessage(message) ==
    message.statusCode
        \o message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX4(message.symSymbolX)

DecodePriceInquiryReplyMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET orderNo == ReadBytes(statusCode.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(fcmId.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX4(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    Ok([ statusCode |-> statusCode.value,
         orderNo    |-> orderNo.value,
         ordId      |-> ordId.value,
         fcmId      |-> fcmId.value,
         symSymbolX |-> symSymbolX.value ], symSymbolX.rest)

ZeroPriceInquiryReplyMessage ==
    [ statusCode |-> [i \in 1 .. 1 |-> 0],
      orderNo    |-> [i \in 1 .. 5 |-> 0],
      ordId      |-> [i \in 1 .. 4 |-> 0],
      fcmId      |-> [i \in 1 .. 2 |-> 0],
      symSymbolX |-> ZeroSymSymbolX4 ]

(* Price Inquiry Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceInquiryReplyMessage ==
    { ZeroPriceInquiryReplyMessage }
        \cup { [ZeroPriceInquiryReplyMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroPriceInquiryReplyMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroPriceInquiryReplyMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroPriceInquiryReplyMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroPriceInquiryReplyMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX4 }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum4 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved33   : Sample(33) ]

EncodeLongSymbolNum4(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum4(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved33   |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum4 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved33   |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum4 ==
    { ZeroLongSymbolNum4 }
        \cup { [ZeroLongSymbolNum4 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum4 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum4 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum4 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum4 EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText4 ==
    [ longSymbol : Sample(40) ]

EncodeLongSymbolText4(message) ==
    message.longSymbol

DecodeLongSymbolText4(bytes) ==
    LET longSymbol == ReadBytes(bytes, 40) IN IF ~longSymbol.ok THEN Fail ELSE
    Ok([ longSymbol |-> longSymbol.value ], longSymbol.rest)

ZeroLongSymbolText4 ==
    [ longSymbol |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText4 ==
    { ZeroLongSymbolText4 }
        \cup { [ZeroLongSymbolText4 EXCEPT !.longSymbol = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Long Symbol X, selected by Symbol Type                              *)
(***************************************************************************)

LongSymbolNumCode4 == 3  \* 0x03
LongSymbolTextCode4 == 4  \* 0x04

SymLongSymbolX4 ==
    [ tag : {LongSymbolNumCode4}, body : LongSymbolNum4 ]
        \cup [ tag : {LongSymbolTextCode4}, body : LongSymbolText4 ]

EncodeSymLongSymbolX4(message) ==
    CASE message.tag = LongSymbolNumCode4 -> EncodeLongSymbolNum4(message.body)
      [] message.tag = LongSymbolTextCode4 -> EncodeLongSymbolText4(message.body)

DecodeSymLongSymbolX4(tag, bytes) ==
    LET read ==
            CASE tag = LongSymbolNumCode4 -> DecodeLongSymbolNum4(bytes)
              [] tag = LongSymbolTextCode4 -> DecodeLongSymbolText4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongSymbolX4 == [tag |-> LongSymbolNumCode4, body |-> ZeroLongSymbolNum4]

(* Each Sym Long Symbol X in turn, at the values the message it names is checked at *)
CheckedSymLongSymbolX4 ==
    { [tag |-> LongSymbolNumCode4, body |-> one] : one \in CheckedLongSymbolNum4 }
        \cup { [tag |-> LongSymbolTextCode4, body |-> one] : one \in CheckedLongSymbolText4 }

(***************************************************************************)
(* Price Inquiry Reply Long Format Message                                 *)
(***************************************************************************)

PriceInquiryReplyLongFormatMessage ==
    [ statusCode     : Sample(1),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      fcmId          : Sample(2),
      symLongSymbolX : SymLongSymbolX4 ]

EncodePriceInquiryReplyLongFormatMessage(message) ==
    message.statusCode
        \o message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeUIntBE(message.symLongSymbolX.tag, 1)
        \o EncodeSymLongSymbolX4(message.symLongSymbolX)

DecodePriceInquiryReplyLongFormatMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET orderNo == ReadBytes(statusCode.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(fcmId.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symLongSymbolX == DecodeSymLongSymbolX4(symbolType.value, symbolType.rest) IN IF ~symLongSymbolX.ok THEN Fail ELSE
    Ok([ statusCode     |-> statusCode.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         fcmId          |-> fcmId.value,
         symLongSymbolX |-> symLongSymbolX.value ], symLongSymbolX.rest)

ZeroPriceInquiryReplyLongFormatMessage ==
    [ statusCode     |-> [i \in 1 .. 1 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      symLongSymbolX |-> ZeroSymLongSymbolX4 ]

(* Price Inquiry Reply Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceInquiryReplyLongFormatMessage ==
    { ZeroPriceInquiryReplyLongFormatMessage }
        \cup { [ZeroPriceInquiryReplyLongFormatMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroPriceInquiryReplyLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroPriceInquiryReplyLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroPriceInquiryReplyLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroPriceInquiryReplyLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX4 }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum5 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum5(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum5(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum5 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum5 ==
    { ZeroSymbolNum5 }
        \cup { [ZeroSymbolNum5 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum5 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum5 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum5 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum5 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText5 ==
    [ symbol : Sample(20) ]

EncodeSymbolText5(message) ==
    message.symbol

DecodeSymbolText5(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText5 ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText5 ==
    { ZeroSymbolText5 }
        \cup { [ZeroSymbolText5 EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode5 == 1  \* 0x01
SymbolTextCode5 == 2  \* 0x02

SymSymbolX5 ==
    [ tag : {SymbolNumCode5}, body : SymbolNum5 ]
        \cup [ tag : {SymbolTextCode5}, body : SymbolText5 ]

EncodeSymSymbolX5(message) ==
    CASE message.tag = SymbolNumCode5 -> EncodeSymbolNum5(message.body)
      [] message.tag = SymbolTextCode5 -> EncodeSymbolText5(message.body)

DecodeSymSymbolX5(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode5 -> DecodeSymbolNum5(bytes)
              [] tag = SymbolTextCode5 -> DecodeSymbolText5(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX5 == [tag |-> SymbolNumCode5, body |-> ZeroSymbolNum5]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX5 ==
    { [tag |-> SymbolNumCode5, body |-> one] : one \in CheckedSymbolNum5 }
        \cup { [tag |-> SymbolTextCode5, body |-> one] : one \in CheckedSymbolText5 }

(***************************************************************************)
(* Quote Input Message                                                     *)
(***************************************************************************)

QuoteInputMessage ==
    [ execType       : Sample(1),
      cmId           : Sample(2),
      fcmId          : Sample(2),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      userDefine     : Sample(8),
      symSymbolX     : SymSymbolX5,
      bidPx          : Sample(4),
      offerPx        : Sample(4),
      bidSize        : Sample(2),
      offerSize      : Sample(2),
      investorAcno   : Sample(4),
      investorFlag   : Sample(1),
      timeInForce    : Sample(1),
      positionEffect : Sample(1),
      orderSource    : Sample(1),
      infoSource     : Sample(3) ]

EncodeQuoteInputMessage(message) ==
    message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX5(message.symSymbolX)
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.investorAcno
        \o message.investorFlag
        \o message.timeInForce
        \o message.positionEffect
        \o message.orderSource
        \o message.infoSource

DecodeQuoteInputMessage(bytes) ==
    LET execType == ReadBytes(bytes, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX5(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    LET bidPx == ReadBytes(symSymbolX.rest, 4) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 4) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(offerSize.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(investorFlag.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET orderSource == ReadBytes(positionEffect.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ execType       |-> execType.value,
         cmId           |-> cmId.value,
         fcmId          |-> fcmId.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         userDefine     |-> userDefine.value,
         symSymbolX     |-> symSymbolX.value,
         bidPx          |-> bidPx.value,
         offerPx        |-> offerPx.value,
         bidSize        |-> bidSize.value,
         offerSize      |-> offerSize.value,
         investorAcno   |-> investorAcno.value,
         investorFlag   |-> investorFlag.value,
         timeInForce    |-> timeInForce.value,
         positionEffect |-> positionEffect.value,
         orderSource    |-> orderSource.value,
         infoSource     |-> infoSource.value ], infoSource.rest)

ZeroQuoteInputMessage ==
    [ execType       |-> [i \in 1 .. 1 |-> 0],
      cmId           |-> [i \in 1 .. 2 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      userDefine     |-> [i \in 1 .. 8 |-> 0],
      symSymbolX     |-> ZeroSymSymbolX5,
      bidPx          |-> [i \in 1 .. 4 |-> 0],
      offerPx        |-> [i \in 1 .. 4 |-> 0],
      bidSize        |-> [i \in 1 .. 2 |-> 0],
      offerSize      |-> [i \in 1 .. 2 |-> 0],
      investorAcno   |-> [i \in 1 .. 4 |-> 0],
      investorFlag   |-> [i \in 1 .. 1 |-> 0],
      timeInForce    |-> [i \in 1 .. 1 |-> 0],
      positionEffect |-> [i \in 1 .. 1 |-> 0],
      orderSource    |-> [i \in 1 .. 1 |-> 0],
      infoSource     |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Input Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteInputMessage ==
    { ZeroQuoteInputMessage }
        \cup { [ZeroQuoteInputMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX5 }
        \cup { [ZeroQuoteInputMessage EXCEPT !.bidPx = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.offerPx = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum5 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved33   : Sample(33) ]

EncodeLongSymbolNum5(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum5(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved33   |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum5 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved33   |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum5 ==
    { ZeroLongSymbolNum5 }
        \cup { [ZeroLongSymbolNum5 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum5 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum5 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum5 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum5 EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText5 ==
    [ longSymbol : Sample(40) ]

EncodeLongSymbolText5(message) ==
    message.longSymbol

DecodeLongSymbolText5(bytes) ==
    LET longSymbol == ReadBytes(bytes, 40) IN IF ~longSymbol.ok THEN Fail ELSE
    Ok([ longSymbol |-> longSymbol.value ], longSymbol.rest)

ZeroLongSymbolText5 ==
    [ longSymbol |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText5 ==
    { ZeroLongSymbolText5 }
        \cup { [ZeroLongSymbolText5 EXCEPT !.longSymbol = one] : one \in Sample(40) }

(***************************************************************************)
(* Sym Long Symbol X, selected by Symbol Type                              *)
(***************************************************************************)

LongSymbolNumCode5 == 3  \* 0x03
LongSymbolTextCode5 == 4  \* 0x04

SymLongSymbolX5 ==
    [ tag : {LongSymbolNumCode5}, body : LongSymbolNum5 ]
        \cup [ tag : {LongSymbolTextCode5}, body : LongSymbolText5 ]

EncodeSymLongSymbolX5(message) ==
    CASE message.tag = LongSymbolNumCode5 -> EncodeLongSymbolNum5(message.body)
      [] message.tag = LongSymbolTextCode5 -> EncodeLongSymbolText5(message.body)

DecodeSymLongSymbolX5(tag, bytes) ==
    LET read ==
            CASE tag = LongSymbolNumCode5 -> DecodeLongSymbolNum5(bytes)
              [] tag = LongSymbolTextCode5 -> DecodeLongSymbolText5(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymLongSymbolX5 == [tag |-> LongSymbolNumCode5, body |-> ZeroLongSymbolNum5]

(* Each Sym Long Symbol X in turn, at the values the message it names is checked at *)
CheckedSymLongSymbolX5 ==
    { [tag |-> LongSymbolNumCode5, body |-> one] : one \in CheckedLongSymbolNum5 }
        \cup { [tag |-> LongSymbolTextCode5, body |-> one] : one \in CheckedLongSymbolText5 }

(***************************************************************************)
(* Quote Input Long Format Message                                         *)
(***************************************************************************)

QuoteInputLongFormatMessage ==
    [ execType       : Sample(1),
      cmId           : Sample(2),
      fcmId          : Sample(2),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      userDefine     : Sample(8),
      symLongSymbolX : SymLongSymbolX5,
      bidPx          : Sample(4),
      offerPx        : Sample(4),
      bidSize        : Sample(2),
      offerSize      : Sample(2),
      investorAcno   : Sample(4),
      investorFlag   : Sample(1),
      timeInForce    : Sample(1),
      positionEffect : Sample(1),
      orderSource    : Sample(1),
      infoSource     : Sample(3) ]

EncodeQuoteInputLongFormatMessage(message) ==
    message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symLongSymbolX.tag, 1)
        \o EncodeSymLongSymbolX5(message.symLongSymbolX)
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.investorAcno
        \o message.investorFlag
        \o message.timeInForce
        \o message.positionEffect
        \o message.orderSource
        \o message.infoSource

DecodeQuoteInputLongFormatMessage(bytes) ==
    LET execType == ReadBytes(bytes, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symLongSymbolX == DecodeSymLongSymbolX5(symbolType.value, symbolType.rest) IN IF ~symLongSymbolX.ok THEN Fail ELSE
    LET bidPx == ReadBytes(symLongSymbolX.rest, 4) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 4) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(offerSize.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(investorFlag.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET orderSource == ReadBytes(positionEffect.rest, 1) IN IF ~orderSource.ok THEN Fail ELSE
    LET infoSource == ReadBytes(orderSource.rest, 3) IN IF ~infoSource.ok THEN Fail ELSE
    Ok([ execType       |-> execType.value,
         cmId           |-> cmId.value,
         fcmId          |-> fcmId.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         userDefine     |-> userDefine.value,
         symLongSymbolX |-> symLongSymbolX.value,
         bidPx          |-> bidPx.value,
         offerPx        |-> offerPx.value,
         bidSize        |-> bidSize.value,
         offerSize      |-> offerSize.value,
         investorAcno   |-> investorAcno.value,
         investorFlag   |-> investorFlag.value,
         timeInForce    |-> timeInForce.value,
         positionEffect |-> positionEffect.value,
         orderSource    |-> orderSource.value,
         infoSource     |-> infoSource.value ], infoSource.rest)

ZeroQuoteInputLongFormatMessage ==
    [ execType       |-> [i \in 1 .. 1 |-> 0],
      cmId           |-> [i \in 1 .. 2 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      userDefine     |-> [i \in 1 .. 8 |-> 0],
      symLongSymbolX |-> ZeroSymLongSymbolX5,
      bidPx          |-> [i \in 1 .. 4 |-> 0],
      offerPx        |-> [i \in 1 .. 4 |-> 0],
      bidSize        |-> [i \in 1 .. 2 |-> 0],
      offerSize      |-> [i \in 1 .. 2 |-> 0],
      investorAcno   |-> [i \in 1 .. 4 |-> 0],
      investorFlag   |-> [i \in 1 .. 1 |-> 0],
      timeInForce    |-> [i \in 1 .. 1 |-> 0],
      positionEffect |-> [i \in 1 .. 1 |-> 0],
      orderSource    |-> [i \in 1 .. 1 |-> 0],
      infoSource     |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Input Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteInputLongFormatMessage ==
    { ZeroQuoteInputLongFormatMessage }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX5 }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.bidPx = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.offerPx = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.orderSource = one] : one \in Sample(1) }
        \cup { [ZeroQuoteInputLongFormatMessage EXCEPT !.infoSource = one] : one \in Sample(3) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime3 ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeTransactTimeMsgTime3(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeTransactTimeMsgTime3(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime3 ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime3 ==
    { ZeroTransactTimeMsgTime3 }
        \cup { [ZeroTransactTimeMsgTime3 EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime3 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Condensed Version Order Status Report Message: 52 bytes                 *)
(***************************************************************************)

CondensedVersionOrderStatusReportMessage ==
    [ statusCode          : Sample(1),
      execType            : Sample(1),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      side                : Sample(1),
      positionEffect      : Sample(1),
      leavesQty           : Sample(2),
      beforeQty           : Sample(2),
      legPx               : Sample(4),
      bothLegQtys         : Sample(2),
      transactTimeMsgTime : TransactTimeMsgTime3,
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1),
      price               : Sample(4) ]

EncodeCondensedVersionOrderStatusReportMessage(message) ==
    message.statusCode
        \o message.execType
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o message.side
        \o message.positionEffect
        \o message.leavesQty
        \o message.beforeQty
        \o message.legPx
        \o message.bothLegQtys
        \o EncodeTransactTimeMsgTime3(message.transactTimeMsgTime)
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType
        \o message.price

DecodeCondensedVersionOrderStatusReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(execType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET side == ReadBytes(userDefine.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(side.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(positionEffect.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET legPx == ReadBytes(beforeQty.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET bothLegQtys == ReadBytes(legPx.rest, 2) IN IF ~bothLegQtys.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime3(bothLegQtys.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET uniqId == ReadBytes(transactTimeMsgTime.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    LET price == ReadBytes(protocolType.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ statusCode          |-> statusCode.value,
         execType            |-> execType.value,
         fcmId               |-> fcmId.value,
         orderNo             |-> orderNo.value,
         ordId               |-> ordId.value,
         userDefine          |-> userDefine.value,
         side                |-> side.value,
         positionEffect      |-> positionEffect.value,
         leavesQty           |-> leavesQty.value,
         beforeQty           |-> beforeQty.value,
         legPx               |-> legPx.value,
         bothLegQtys         |-> bothLegQtys.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value,
         price               |-> price.value ], price.rest)

ZeroCondensedVersionOrderStatusReportMessage ==
    [ statusCode          |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeQty           |-> [i \in 1 .. 2 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      bothLegQtys         |-> [i \in 1 .. 2 |-> 0],
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime3,
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0] ]

(* Condensed Version Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedCondensedVersionOrderStatusReportMessage ==
    { ZeroCondensedVersionOrderStatusReportMessage }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.beforeQty = one] : one \in Sample(2) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.bothLegQtys = one] : one \in Sample(2) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.transactTimeMsgTime = one] : one \in CheckedTransactTimeMsgTime3 }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.protocolType = one] : one \in Sample(1) }
        \cup { [ZeroCondensedVersionOrderStatusReportMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum6 ==
    [ pseq1        : Sample(2),
      pseq2        : Sample(2),
      bothLegSides : Sample(1),
      combOp       : Sample(1),
      reserved13   : Sample(13) ]

EncodeSymbolNum6(message) ==
    message.pseq1
        \o message.pseq2
        \o message.bothLegSides
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum6(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(pseq2.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET combOp == ReadBytes(bothLegSides.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1        |-> pseq1.value,
         pseq2        |-> pseq2.value,
         bothLegSides |-> bothLegSides.value,
         combOp       |-> combOp.value,
         reserved13   |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum6 ==
    [ pseq1        |-> [i \in 1 .. 2 |-> 0],
      pseq2        |-> [i \in 1 .. 2 |-> 0],
      bothLegSides |-> [i \in 1 .. 1 |-> 0],
      combOp       |-> [i \in 1 .. 1 |-> 0],
      reserved13   |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum6 ==
    { ZeroSymbolNum6 }
        \cup { [ZeroSymbolNum6 EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum6 EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum6 EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum6 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum6 EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText6 ==
    [ symbol : Sample(20) ]

EncodeSymbolText6(message) ==
    message.symbol

DecodeSymbolText6(bytes) ==
    LET symbol == ReadBytes(bytes, 20) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value ], symbol.rest)

ZeroSymbolText6 ==
    [ symbol |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText6 ==
    { ZeroSymbolText6 }
        \cup { [ZeroSymbolText6 EXCEPT !.symbol = one] : one \in Sample(20) }

(***************************************************************************)
(* Sym Symbol X, selected by Symbol Type                                   *)
(***************************************************************************)

SymbolNumCode6 == 1  \* 0x01
SymbolTextCode6 == 2  \* 0x02

SymSymbolX6 ==
    [ tag : {SymbolNumCode6}, body : SymbolNum6 ]
        \cup [ tag : {SymbolTextCode6}, body : SymbolText6 ]

EncodeSymSymbolX6(message) ==
    CASE message.tag = SymbolNumCode6 -> EncodeSymbolNum6(message.body)
      [] message.tag = SymbolTextCode6 -> EncodeSymbolText6(message.body)

DecodeSymSymbolX6(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumCode6 -> DecodeSymbolNum6(bytes)
              [] tag = SymbolTextCode6 -> DecodeSymbolText6(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymSymbolX6 == [tag |-> SymbolNumCode6, body |-> ZeroSymbolNum6]

(* Each Sym Symbol X in turn, at the values the message it names is checked at *)
CheckedSymSymbolX6 ==
    { [tag |-> SymbolNumCode6, body |-> one] : one \in CheckedSymbolNum6 }
        \cup { [tag |-> SymbolTextCode6, body |-> one] : one \in CheckedSymbolText6 }

(***************************************************************************)
(* Org Trans Time Msg Time: 6 bytes                                        *)
(***************************************************************************)

OrgTransTimeMsgTime3 ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeOrgTransTimeMsgTime3(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeOrgTransTimeMsgTime3(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroOrgTransTimeMsgTime3 ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Org Trans Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTime3 ==
    { ZeroOrgTransTimeMsgTime3 }
        \cup { [ZeroOrgTransTimeMsgTime3 EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTime3 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime4 ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeTransactTimeMsgTime4(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeTransactTimeMsgTime4(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime4 ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime4 ==
    { ZeroTransactTimeMsgTime4 }
        \cup { [ZeroTransactTimeMsgTime4 EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime4 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Execution Report Including Head Office And Branch Offices Message       *)
(***************************************************************************)

ExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    [ statusCode          : Sample(1),
      execType            : Sample(1),
      cmId                : Sample(2),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      symSymbolX          : SymSymbolX6,
      price               : Sample(4),
      qty                 : Sample(2),
      investorAcno        : Sample(4),
      investorFlag        : Sample(1),
      side                : Sample(1),
      ordType             : Sample(1),
      timeInForce         : Sample(1),
      positionEffect      : Sample(1),
      lastPx              : Sample(4),
      lastQty             : Sample(2),
      pxSubtotal          : Sample(8),
      cumQty              : Sample(2),
      leavesQty           : Sample(2),
      beforeQty           : Sample(2),
      bothLegSides        : Sample(1),
      legPx               : Sample(4),
      bothLegQtys         : Sample(2),
      orgTransTimeMsgTime : OrgTransTimeMsgTime3,
      transactTimeMsgTime : TransactTimeMsgTime4,
      targetId            : Sample(1),
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1),
      rptSessionId        : Sample(2) ]

EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message) ==
    message.statusCode
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeUIntBE(message.symSymbolX.tag, 1)
        \o EncodeSymSymbolX6(message.symSymbolX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o message.bothLegSides
        \o message.legPx
        \o message.bothLegQtys
        \o EncodeOrgTransTimeMsgTime3(message.orgTransTimeMsgTime)
        \o EncodeTransactTimeMsgTime4(message.transactTimeMsgTime)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType
        \o message.rptSessionId

DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symbolType == ReadUIntBE(userDefine.rest, 1) IN IF ~symbolType.ok THEN Fail ELSE
    LET symSymbolX == DecodeSymSymbolX6(symbolType.value, symbolType.rest) IN IF ~symSymbolX.ok THEN Fail ELSE
    LET price == ReadBytes(symSymbolX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET bothLegSides == ReadBytes(beforeQty.rest, 1) IN IF ~bothLegSides.ok THEN Fail ELSE
    LET legPx == ReadBytes(bothLegSides.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET bothLegQtys == ReadBytes(legPx.rest, 2) IN IF ~bothLegQtys.ok THEN Fail ELSE
    LET orgTransTimeMsgTime == DecodeOrgTransTimeMsgTime3(bothLegQtys.rest) IN IF ~orgTransTimeMsgTime.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime4(orgTransTimeMsgTime.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTime.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    LET rptSessionId == ReadBytes(protocolType.rest, 2) IN IF ~rptSessionId.ok THEN Fail ELSE
    Ok([ statusCode          |-> statusCode.value,
         execType            |-> execType.value,
         cmId                |-> cmId.value,
         fcmId               |-> fcmId.value,
         orderNo             |-> orderNo.value,
         ordId               |-> ordId.value,
         userDefine          |-> userDefine.value,
         symSymbolX          |-> symSymbolX.value,
         price               |-> price.value,
         qty                 |-> qty.value,
         investorAcno        |-> investorAcno.value,
         investorFlag        |-> investorFlag.value,
         side                |-> side.value,
         ordType             |-> ordType.value,
         timeInForce         |-> timeInForce.value,
         positionEffect      |-> positionEffect.value,
         lastPx              |-> lastPx.value,
         lastQty             |-> lastQty.value,
         pxSubtotal          |-> pxSubtotal.value,
         cumQty              |-> cumQty.value,
         leavesQty           |-> leavesQty.value,
         beforeQty           |-> beforeQty.value,
         bothLegSides        |-> bothLegSides.value,
         legPx               |-> legPx.value,
         bothLegQtys         |-> bothLegQtys.value,
         orgTransTimeMsgTime |-> orgTransTimeMsgTime.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         targetId            |-> targetId.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value,
         rptSessionId        |-> rptSessionId.value ], rptSessionId.rest)

ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    [ statusCode          |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmId                |-> [i \in 1 .. 2 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      symSymbolX          |-> ZeroSymSymbolX6,
      price               |-> [i \in 1 .. 4 |-> 0],
      qty                 |-> [i \in 1 .. 2 |-> 0],
      investorAcno        |-> [i \in 1 .. 4 |-> 0],
      investorFlag        |-> [i \in 1 .. 1 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      ordType             |-> [i \in 1 .. 1 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      positionEffect      |-> [i \in 1 .. 1 |-> 0],
      lastPx              |-> [i \in 1 .. 4 |-> 0],
      lastQty             |-> [i \in 1 .. 2 |-> 0],
      pxSubtotal          |-> [i \in 1 .. 8 |-> 0],
      cumQty              |-> [i \in 1 .. 2 |-> 0],
      leavesQty           |-> [i \in 1 .. 2 |-> 0],
      beforeQty           |-> [i \in 1 .. 2 |-> 0],
      bothLegSides        |-> [i \in 1 .. 1 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      bothLegQtys         |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTime |-> ZeroOrgTransTimeMsgTime3,
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime4,
      targetId            |-> [i \in 1 .. 1 |-> 0],
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0],
      rptSessionId        |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Report Including Head Office And Branch Offices Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    { ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX6 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.pxSubtotal = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.beforeQty = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.bothLegSides = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.bothLegQtys = one] : one \in Sample(2) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.orgTransTimeMsgTime = one] : one \in CheckedOrgTransTimeMsgTime3 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.transactTimeMsgTime = one] : one \in CheckedTransactTimeMsgTime4 }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.protocolType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportIncludingHeadOfficeAndBranchOfficesMessage EXCEPT !.rptSessionId = one] : one \in Sample(2) }

(***************************************************************************)
(* Bulletin Request Message                                                *)
(***************************************************************************)

BulletinRequestMessage ==
    [ fcmReqId                : Sample(4),
      bulletinReqId           : Sample(4),
      systemType              : Sample(1),
      dataCharHdrMsgLength159 : SampleBytes ]

EncodeBulletinRequestMessage(message) ==
    message.fcmReqId
        \o message.bulletinReqId
        \o message.systemType
        \o message.dataCharHdrMsgLength159

DecodeBulletinRequestMessage(bytes) ==
    LET fcmReqId == ReadBytes(bytes, 4) IN IF ~fcmReqId.ok THEN Fail ELSE
    LET bulletinReqId == ReadBytes(fcmReqId.rest, 4) IN IF ~bulletinReqId.ok THEN Fail ELSE
    LET systemType == ReadBytes(bulletinReqId.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET dataCharHdrMsgLength159 == Ok(systemType.rest, << >>) IN IF ~dataCharHdrMsgLength159.ok THEN Fail ELSE
    Ok([ fcmReqId                |-> fcmReqId.value,
         bulletinReqId           |-> bulletinReqId.value,
         systemType              |-> systemType.value,
         dataCharHdrMsgLength159 |-> dataCharHdrMsgLength159.value ], dataCharHdrMsgLength159.rest)

ZeroBulletinRequestMessage ==
    [ fcmReqId                |-> [i \in 1 .. 4 |-> 0],
      bulletinReqId           |-> [i \in 1 .. 4 |-> 0],
      systemType              |-> [i \in 1 .. 1 |-> 0],
      dataCharHdrMsgLength159 |-> << >> ]

(* Bulletin Request Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinRequestMessage ==
    { ZeroBulletinRequestMessage }
        \cup { [ZeroBulletinRequestMessage EXCEPT !.fcmReqId = one] : one \in Sample(4) }
        \cup { [ZeroBulletinRequestMessage EXCEPT !.bulletinReqId = one] : one \in Sample(4) }
        \cup { [ZeroBulletinRequestMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroBulletinRequestMessage EXCEPT !.dataCharHdrMsgLength159 = one] : one \in SampleBytes }

(***************************************************************************)
(* Bulletin Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

BulletinTimeMsgTime ==
    [ msgTimeEpochS : Sample(4),
      ms            : Sample(2) ]

EncodeBulletinTimeMsgTime(message) ==
    message.msgTimeEpochS
        \o message.ms

DecodeBulletinTimeMsgTime(bytes) ==
    LET msgTimeEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeEpochS.ok THEN Fail ELSE
    LET ms == ReadBytes(msgTimeEpochS.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ msgTimeEpochS |-> msgTimeEpochS.value,
         ms            |-> ms.value ], ms.rest)

ZeroBulletinTimeMsgTime ==
    [ msgTimeEpochS |-> [i \in 1 .. 4 |-> 0],
      ms            |-> [i \in 1 .. 2 |-> 0] ]

(* Bulletin Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedBulletinTimeMsgTime ==
    { ZeroBulletinTimeMsgTime }
        \cup { [ZeroBulletinTimeMsgTime EXCEPT !.msgTimeEpochS = one] : one \in Sample(4) }
        \cup { [ZeroBulletinTimeMsgTime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Bulletin Report Message                                                 *)
(***************************************************************************)

BulletinReportMessage ==
    [ statusCode               : Sample(1),
      fcmReqId                 : Sample(4),
      bulletinSeq              : Sample(4),
      bulletinTimeMsgTime      : BulletinTimeMsgTime,
      systemType               : Sample(1),
      dataCharHdrMsgLength1516 : SampleBytes ]

EncodeBulletinReportMessage(message) ==
    message.statusCode
        \o message.fcmReqId
        \o message.bulletinSeq
        \o EncodeBulletinTimeMsgTime(message.bulletinTimeMsgTime)
        \o message.systemType
        \o message.dataCharHdrMsgLength1516

DecodeBulletinReportMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET fcmReqId == ReadBytes(statusCode.rest, 4) IN IF ~fcmReqId.ok THEN Fail ELSE
    LET bulletinSeq == ReadBytes(fcmReqId.rest, 4) IN IF ~bulletinSeq.ok THEN Fail ELSE
    LET bulletinTimeMsgTime == DecodeBulletinTimeMsgTime(bulletinSeq.rest) IN IF ~bulletinTimeMsgTime.ok THEN Fail ELSE
    LET systemType == ReadBytes(bulletinTimeMsgTime.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET dataCharHdrMsgLength1516 == Ok(systemType.rest, << >>) IN IF ~dataCharHdrMsgLength1516.ok THEN Fail ELSE
    Ok([ statusCode               |-> statusCode.value,
         fcmReqId                 |-> fcmReqId.value,
         bulletinSeq              |-> bulletinSeq.value,
         bulletinTimeMsgTime      |-> bulletinTimeMsgTime.value,
         systemType               |-> systemType.value,
         dataCharHdrMsgLength1516 |-> dataCharHdrMsgLength1516.value ], dataCharHdrMsgLength1516.rest)

ZeroBulletinReportMessage ==
    [ statusCode               |-> [i \in 1 .. 1 |-> 0],
      fcmReqId                 |-> [i \in 1 .. 4 |-> 0],
      bulletinSeq              |-> [i \in 1 .. 4 |-> 0],
      bulletinTimeMsgTime      |-> ZeroBulletinTimeMsgTime,
      systemType               |-> [i \in 1 .. 1 |-> 0],
      dataCharHdrMsgLength1516 |-> << >> ]

(* Bulletin Report Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinReportMessage ==
    { ZeroBulletinReportMessage }
        \cup { [ZeroBulletinReportMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroBulletinReportMessage EXCEPT !.fcmReqId = one] : one \in Sample(4) }
        \cup { [ZeroBulletinReportMessage EXCEPT !.bulletinSeq = one] : one \in Sample(4) }
        \cup { [ZeroBulletinReportMessage EXCEPT !.bulletinTimeMsgTime = one] : one \in CheckedBulletinTimeMsgTime }
        \cup { [ZeroBulletinReportMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroBulletinReportMessage EXCEPT !.dataCharHdrMsgLength1516 = one] : one \in SampleBytes }

(***************************************************************************)
(* System Setting Message                                                  *)
(***************************************************************************)

SystemSettingMessage ==
    [ dataCharHdrMsgLength15 : SampleBytes ]

EncodeSystemSettingMessage(message) ==
    message.dataCharHdrMsgLength15

DecodeSystemSettingMessage(bytes) ==
    LET dataCharHdrMsgLength15 == Ok(bytes, << >>) IN IF ~dataCharHdrMsgLength15.ok THEN Fail ELSE
    Ok([ dataCharHdrMsgLength15 |-> dataCharHdrMsgLength15.value ], dataCharHdrMsgLength15.rest)

ZeroSystemSettingMessage ==
    [ dataCharHdrMsgLength15 |-> << >> ]

(* System Setting Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemSettingMessage ==
    { ZeroSystemSettingMessage }
        \cup { [ZeroSystemSettingMessage EXCEPT !.dataCharHdrMsgLength15 = one] : one \in SampleBytes }

(***************************************************************************)
(* System Notification Message                                             *)
(***************************************************************************)

SystemNotificationMessage ==
    [ statusCode              : Sample(1),
      dataCharHdrMsgLength151 : SampleBytes ]

EncodeSystemNotificationMessage(message) ==
    message.statusCode
        \o message.dataCharHdrMsgLength151

DecodeSystemNotificationMessage(bytes) ==
    LET statusCode == ReadBytes(bytes, 1) IN IF ~statusCode.ok THEN Fail ELSE
    LET dataCharHdrMsgLength151 == Ok(statusCode.rest, << >>) IN IF ~dataCharHdrMsgLength151.ok THEN Fail ELSE
    Ok([ statusCode              |-> statusCode.value,
         dataCharHdrMsgLength151 |-> dataCharHdrMsgLength151.value ], dataCharHdrMsgLength151.rest)

ZeroSystemNotificationMessage ==
    [ statusCode              |-> [i \in 1 .. 1 |-> 0],
      dataCharHdrMsgLength151 |-> << >> ]

(* System Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemNotificationMessage ==
    { ZeroSystemNotificationMessage }
        \cup { [ZeroSystemNotificationMessage EXCEPT !.statusCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemNotificationMessage EXCEPT !.dataCharHdrMsgLength151 = one] : one \in SampleBytes }

(***************************************************************************)
(* Symbol Num X: 4 bytes                                                   *)
(***************************************************************************)

SymbolNumX ==
    [ pseq : Sample(4) ]

EncodeSymbolNumX(message) ==
    message.pseq

DecodeSymbolNumX(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolNumX ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNumX ==
    { ZeroSymbolNumX }
        \cup { [ZeroSymbolNumX EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Txt X: 20 bytes                                                  *)
(***************************************************************************)

SymbolTxtX ==
    [ prodId : Sample(20) ]

EncodeSymbolTxtX(message) ==
    message.prodId

DecodeSymbolTxtX(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroSymbolTxtX ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolTxtX ==
    { ZeroSymbolTxtX }
        \cup { [ZeroSymbolTxtX EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Sym Symbol Num X: 4 bytes                                           *)
(***************************************************************************)

LegSymSymbolNumX ==
    [ pseq : Sample(4) ]

EncodeLegSymSymbolNumX(message) ==
    message.pseq

DecodeLegSymSymbolNumX(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegSymSymbolNumX ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Sym Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolNumX ==
    { ZeroLegSymSymbolNumX }
        \cup { [ZeroLegSymSymbolNumX EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Entry Num: 7 bytes                                                  *)
(***************************************************************************)

LegEntryNum ==
    [ legSymSymbolNumX : LegSymSymbolNumX,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryNum(message) ==
    EncodeLegSymSymbolNumX(message.legSymSymbolNumX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryNum(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryNum ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum ==
    { ZeroLegEntryNum }
        \cup { [ZeroLegEntryNum EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX }
        \cup { [ZeroLegEntryNum EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Num, written one after another *)
RECURSIVE EncodeLegEntryNumList(_)
EncodeLegEntryNumList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryNum(Head(messages)) \o EncodeLegEntryNumList(Tail(messages))

(* As many Leg Entry Num as the field that counts them says *)
RECURSIVE ReadLegEntryNumList(_, _)
ReadLegEntryNumList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryNum(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryNumList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Num of each kind, for the lists that carry them *)
OneLegEntryNum == { ZeroLegEntryNum }

(***************************************************************************)
(* Multi Leg Num                                                           *)
(***************************************************************************)

MultiLegNum ==
    [ combOp      : Sample(1),
      legEntryNum : SampleLists(OneLegEntryNum) ]

EncodeMultiLegNum(message) ==
    EncodeUIntBE(Len(message.legEntryNum), 1)
        \o message.combOp
        \o EncodeLegEntryNumList(message.legEntryNum)

DecodeMultiLegNum(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryNum == ReadLegEntryNumList(combOp.rest, noLeg.value) IN IF ~legEntryNum.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryNum |-> legEntryNum.value ], legEntryNum.rest)

ZeroMultiLegNum ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryNum |-> << >> ]

(* Multi Leg Num at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegNum ==
    { ZeroMultiLegNum }
        \cup { [ZeroMultiLegNum EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegNum EXCEPT !.legEntryNum = one] : one \in SampleLists(OneLegEntryNum) }

(***************************************************************************)
(* Leg Sym Symbol Txt X: 20 bytes                                          *)
(***************************************************************************)

LegSymSymbolTxtX ==
    [ prodId : Sample(20) ]

EncodeLegSymSymbolTxtX(message) ==
    message.prodId

DecodeLegSymSymbolTxtX(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroLegSymSymbolTxtX ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Leg Sym Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolTxtX ==
    { ZeroLegSymSymbolTxtX }
        \cup { [ZeroLegSymSymbolTxtX EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Entry Txt: 23 bytes                                                 *)
(***************************************************************************)

LegEntryTxt ==
    [ legSymSymbolTxtX : LegSymSymbolTxtX,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryTxt(message) ==
    EncodeLegSymSymbolTxtX(message.legSymSymbolTxtX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryTxt(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryTxt ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt ==
    { ZeroLegEntryTxt }
        \cup { [ZeroLegEntryTxt EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX }
        \cup { [ZeroLegEntryTxt EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Txt, written one after another *)
RECURSIVE EncodeLegEntryTxtList(_)
EncodeLegEntryTxtList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryTxt(Head(messages)) \o EncodeLegEntryTxtList(Tail(messages))

(* As many Leg Entry Txt as the field that counts them says *)
RECURSIVE ReadLegEntryTxtList(_, _)
ReadLegEntryTxtList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryTxt(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryTxtList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Txt of each kind, for the lists that carry them *)
OneLegEntryTxt == { ZeroLegEntryTxt }

(***************************************************************************)
(* Multi Leg Txt                                                           *)
(***************************************************************************)

MultiLegTxt ==
    [ combOp      : Sample(1),
      legEntryTxt : SampleLists(OneLegEntryTxt) ]

EncodeMultiLegTxt(message) ==
    EncodeUIntBE(Len(message.legEntryTxt), 1)
        \o message.combOp
        \o EncodeLegEntryTxtList(message.legEntryTxt)

DecodeMultiLegTxt(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryTxt == ReadLegEntryTxtList(combOp.rest, noLeg.value) IN IF ~legEntryTxt.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryTxt |-> legEntryTxt.value ], legEntryTxt.rest)

ZeroMultiLegTxt ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryTxt |-> << >> ]

(* Multi Leg Txt at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegTxt ==
    { ZeroMultiLegTxt }
        \cup { [ZeroMultiLegTxt EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegTxt EXCEPT !.legEntryTxt = one] : one \in SampleLists(OneLegEntryTxt) }

(***************************************************************************)
(* Sym Flex Product X, selected by Msg Type Ext                            *)
(***************************************************************************)

SymbolNumXCode == 1  \* 0x01
SymbolTxtXCode == 2  \* 0x02
MultiLegNumCode == 3  \* 0x03
MultiLegTxtCode == 4  \* 0x04

SymFlexProductX ==
    [ tag : {SymbolNumXCode}, body : SymbolNumX ]
        \cup [ tag : {SymbolTxtXCode}, body : SymbolTxtX ]
        \cup [ tag : {MultiLegNumCode}, body : MultiLegNum ]
        \cup [ tag : {MultiLegTxtCode}, body : MultiLegTxt ]

EncodeSymFlexProductX(message) ==
    CASE message.tag = SymbolNumXCode -> EncodeSymbolNumX(message.body)
      [] message.tag = SymbolTxtXCode -> EncodeSymbolTxtX(message.body)
      [] message.tag = MultiLegNumCode -> EncodeMultiLegNum(message.body)
      [] message.tag = MultiLegTxtCode -> EncodeMultiLegTxt(message.body)

DecodeSymFlexProductX(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumXCode -> DecodeSymbolNumX(bytes)
              [] tag = SymbolTxtXCode -> DecodeSymbolTxtX(bytes)
              [] tag = MultiLegNumCode -> DecodeMultiLegNum(bytes)
              [] tag = MultiLegTxtCode -> DecodeMultiLegTxt(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexProductX == [tag |-> SymbolNumXCode, body |-> ZeroSymbolNumX]

(* Each Sym Flex Product X in turn, at the values the message it names is checked at *)
CheckedSymFlexProductX ==
    { [tag |-> SymbolNumXCode, body |-> one] : one \in CheckedSymbolNumX }
        \cup { [tag |-> SymbolTxtXCode, body |-> one] : one \in CheckedSymbolTxtX }
        \cup { [tag |-> MultiLegNumCode, body |-> one] : one \in CheckedMultiLegNum }
        \cup { [tag |-> MultiLegTxtCode, body |-> one] : one \in CheckedMultiLegTxt }

(***************************************************************************)
(* Flex Order Input Single Message                                         *)
(***************************************************************************)

FlexOrderInputSingleMessage ==
    [ preserve        : Sample(1),
      msgTimeNs       : Sample(4),
      execType        : Sample(1),
      cmId            : Sample(2),
      fcmId           : Sample(2),
      orderNo         : Sample(5),
      ordId           : Sample(4),
      userDefine      : Sample(8),
      symFlexProductX : SymFlexProductX,
      price           : Sample(4),
      qty             : Sample(2),
      investorAcno    : Sample(4),
      investorFlag    : Sample(1),
      side            : Sample(1),
      ordType         : Sample(1),
      timeInForce     : Sample(1),
      positionEffect  : Sample(1),
      reserved12      : Sample(12) ]

EncodeFlexOrderInputSingleMessage(message) ==
    EncodeUIntBE(message.symFlexProductX.tag, 1)
        \o message.preserve
        \o message.msgTimeNs
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeSymFlexProductX(message.symFlexProductX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.reserved12

DecodeFlexOrderInputSingleMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    LET execType == ReadBytes(msgTimeNs.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symFlexProductX == DecodeSymFlexProductX(msgTypeExt.value, userDefine.rest) IN IF ~symFlexProductX.ok THEN Fail ELSE
    LET price == ReadBytes(symFlexProductX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(positionEffect.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ preserve        |-> preserve.value,
         msgTimeNs       |-> msgTimeNs.value,
         execType        |-> execType.value,
         cmId            |-> cmId.value,
         fcmId           |-> fcmId.value,
         orderNo         |-> orderNo.value,
         ordId           |-> ordId.value,
         userDefine      |-> userDefine.value,
         symFlexProductX |-> symFlexProductX.value,
         price           |-> price.value,
         qty             |-> qty.value,
         investorAcno    |-> investorAcno.value,
         investorFlag    |-> investorFlag.value,
         side            |-> side.value,
         ordType         |-> ordType.value,
         timeInForce     |-> timeInForce.value,
         positionEffect  |-> positionEffect.value,
         reserved12      |-> reserved12.value ], reserved12.rest)

ZeroFlexOrderInputSingleMessage ==
    [ preserve        |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs       |-> [i \in 1 .. 4 |-> 0],
      execType        |-> [i \in 1 .. 1 |-> 0],
      cmId            |-> [i \in 1 .. 2 |-> 0],
      fcmId           |-> [i \in 1 .. 2 |-> 0],
      orderNo         |-> [i \in 1 .. 5 |-> 0],
      ordId           |-> [i \in 1 .. 4 |-> 0],
      userDefine      |-> [i \in 1 .. 8 |-> 0],
      symFlexProductX |-> ZeroSymFlexProductX,
      price           |-> [i \in 1 .. 4 |-> 0],
      qty             |-> [i \in 1 .. 2 |-> 0],
      investorAcno    |-> [i \in 1 .. 4 |-> 0],
      investorFlag    |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      ordType         |-> [i \in 1 .. 1 |-> 0],
      timeInForce     |-> [i \in 1 .. 1 |-> 0],
      positionEffect  |-> [i \in 1 .. 1 |-> 0],
      reserved12      |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Order Input Single Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexOrderInputSingleMessage ==
    { ZeroFlexOrderInputSingleMessage }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.msgTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderInputSingleMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Symbol Num X: 4 bytes                                                   *)
(***************************************************************************)

SymbolNumX2 ==
    [ pseq : Sample(4) ]

EncodeSymbolNumX2(message) ==
    message.pseq

DecodeSymbolNumX2(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolNumX2 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNumX2 ==
    { ZeroSymbolNumX2 }
        \cup { [ZeroSymbolNumX2 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Txt X: 20 bytes                                                  *)
(***************************************************************************)

SymbolTxtX2 ==
    [ prodId : Sample(20) ]

EncodeSymbolTxtX2(message) ==
    message.prodId

DecodeSymbolTxtX2(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroSymbolTxtX2 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolTxtX2 ==
    { ZeroSymbolTxtX2 }
        \cup { [ZeroSymbolTxtX2 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Sym Symbol Num X: 4 bytes                                           *)
(***************************************************************************)

LegSymSymbolNumX2 ==
    [ pseq : Sample(4) ]

EncodeLegSymSymbolNumX2(message) ==
    message.pseq

DecodeLegSymSymbolNumX2(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegSymSymbolNumX2 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Sym Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolNumX2 ==
    { ZeroLegSymSymbolNumX2 }
        \cup { [ZeroLegSymSymbolNumX2 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Entry Num: 7 bytes                                                  *)
(***************************************************************************)

LegEntryNum2 ==
    [ legSymSymbolNumX : LegSymSymbolNumX2,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryNum2(message) ==
    EncodeLegSymSymbolNumX2(message.legSymSymbolNumX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryNum2(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX2(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryNum2 ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX2,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum2 ==
    { ZeroLegEntryNum2 }
        \cup { [ZeroLegEntryNum2 EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX2 }
        \cup { [ZeroLegEntryNum2 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum2 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Num, written one after another *)
RECURSIVE EncodeLegEntryNum2List(_)
EncodeLegEntryNum2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryNum2(Head(messages)) \o EncodeLegEntryNum2List(Tail(messages))

(* As many Leg Entry Num as the field that counts them says *)
RECURSIVE ReadLegEntryNum2List(_, _)
ReadLegEntryNum2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryNum2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryNum2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Num of each kind, for the lists that carry them *)
OneLegEntryNum2 == { ZeroLegEntryNum2 }

(***************************************************************************)
(* Multi Leg Num                                                           *)
(***************************************************************************)

MultiLegNum2 ==
    [ combOp      : Sample(1),
      legEntryNum : SampleLists(OneLegEntryNum2) ]

EncodeMultiLegNum2(message) ==
    EncodeUIntBE(Len(message.legEntryNum), 1)
        \o message.combOp
        \o EncodeLegEntryNum2List(message.legEntryNum)

DecodeMultiLegNum2(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryNum == ReadLegEntryNum2List(combOp.rest, noLeg.value) IN IF ~legEntryNum.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryNum |-> legEntryNum.value ], legEntryNum.rest)

ZeroMultiLegNum2 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryNum |-> << >> ]

(* Multi Leg Num at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegNum2 ==
    { ZeroMultiLegNum2 }
        \cup { [ZeroMultiLegNum2 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegNum2 EXCEPT !.legEntryNum = one] : one \in SampleLists(OneLegEntryNum2) }

(***************************************************************************)
(* Leg Sym Symbol Txt X: 20 bytes                                          *)
(***************************************************************************)

LegSymSymbolTxtX2 ==
    [ prodId : Sample(20) ]

EncodeLegSymSymbolTxtX2(message) ==
    message.prodId

DecodeLegSymSymbolTxtX2(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroLegSymSymbolTxtX2 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Leg Sym Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolTxtX2 ==
    { ZeroLegSymSymbolTxtX2 }
        \cup { [ZeroLegSymSymbolTxtX2 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Entry Txt: 23 bytes                                                 *)
(***************************************************************************)

LegEntryTxt2 ==
    [ legSymSymbolTxtX : LegSymSymbolTxtX2,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryTxt2(message) ==
    EncodeLegSymSymbolTxtX2(message.legSymSymbolTxtX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryTxt2(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX2(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryTxt2 ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX2,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt2 ==
    { ZeroLegEntryTxt2 }
        \cup { [ZeroLegEntryTxt2 EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX2 }
        \cup { [ZeroLegEntryTxt2 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt2 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Txt, written one after another *)
RECURSIVE EncodeLegEntryTxt2List(_)
EncodeLegEntryTxt2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryTxt2(Head(messages)) \o EncodeLegEntryTxt2List(Tail(messages))

(* As many Leg Entry Txt as the field that counts them says *)
RECURSIVE ReadLegEntryTxt2List(_, _)
ReadLegEntryTxt2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryTxt2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryTxt2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Txt of each kind, for the lists that carry them *)
OneLegEntryTxt2 == { ZeroLegEntryTxt2 }

(***************************************************************************)
(* Multi Leg Txt                                                           *)
(***************************************************************************)

MultiLegTxt2 ==
    [ combOp      : Sample(1),
      legEntryTxt : SampleLists(OneLegEntryTxt2) ]

EncodeMultiLegTxt2(message) ==
    EncodeUIntBE(Len(message.legEntryTxt), 1)
        \o message.combOp
        \o EncodeLegEntryTxt2List(message.legEntryTxt)

DecodeMultiLegTxt2(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryTxt == ReadLegEntryTxt2List(combOp.rest, noLeg.value) IN IF ~legEntryTxt.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryTxt |-> legEntryTxt.value ], legEntryTxt.rest)

ZeroMultiLegTxt2 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryTxt |-> << >> ]

(* Multi Leg Txt at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegTxt2 ==
    { ZeroMultiLegTxt2 }
        \cup { [ZeroMultiLegTxt2 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegTxt2 EXCEPT !.legEntryTxt = one] : one \in SampleLists(OneLegEntryTxt2) }

(***************************************************************************)
(* Sym Flex Product X, selected by Msg Type Ext                            *)
(***************************************************************************)

SymbolNumXCode2 == 1  \* 0x01
SymbolTxtXCode2 == 2  \* 0x02
MultiLegNumCode2 == 3  \* 0x03
MultiLegTxtCode2 == 4  \* 0x04

SymFlexProductX2 ==
    [ tag : {SymbolNumXCode2}, body : SymbolNumX2 ]
        \cup [ tag : {SymbolTxtXCode2}, body : SymbolTxtX2 ]
        \cup [ tag : {MultiLegNumCode2}, body : MultiLegNum2 ]
        \cup [ tag : {MultiLegTxtCode2}, body : MultiLegTxt2 ]

EncodeSymFlexProductX2(message) ==
    CASE message.tag = SymbolNumXCode2 -> EncodeSymbolNumX2(message.body)
      [] message.tag = SymbolTxtXCode2 -> EncodeSymbolTxtX2(message.body)
      [] message.tag = MultiLegNumCode2 -> EncodeMultiLegNum2(message.body)
      [] message.tag = MultiLegTxtCode2 -> EncodeMultiLegTxt2(message.body)

DecodeSymFlexProductX2(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumXCode2 -> DecodeSymbolNumX2(bytes)
              [] tag = SymbolTxtXCode2 -> DecodeSymbolTxtX2(bytes)
              [] tag = MultiLegNumCode2 -> DecodeMultiLegNum2(bytes)
              [] tag = MultiLegTxtCode2 -> DecodeMultiLegTxt2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexProductX2 == [tag |-> SymbolNumXCode2, body |-> ZeroSymbolNumX2]

(* Each Sym Flex Product X in turn, at the values the message it names is checked at *)
CheckedSymFlexProductX2 ==
    { [tag |-> SymbolNumXCode2, body |-> one] : one \in CheckedSymbolNumX2 }
        \cup { [tag |-> SymbolTxtXCode2, body |-> one] : one \in CheckedSymbolTxtX2 }
        \cup { [tag |-> MultiLegNumCode2, body |-> one] : one \in CheckedMultiLegNum2 }
        \cup { [tag |-> MultiLegTxtCode2, body |-> one] : one \in CheckedMultiLegTxt2 }

(***************************************************************************)
(* Flex Price Inquiry Input Message                                        *)
(***************************************************************************)

FlexPriceInquiryInputMessage ==
    [ preserve        : Sample(1),
      msgTimeNs       : Sample(4),
      orderNo         : Sample(5),
      ordId           : Sample(4),
      fcmId           : Sample(2),
      symFlexProductX : SymFlexProductX2,
      reserved8       : Sample(8) ]

EncodeFlexPriceInquiryInputMessage(message) ==
    EncodeUIntBE(message.symFlexProductX.tag, 1)
        \o message.preserve
        \o message.msgTimeNs
        \o message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeSymFlexProductX2(message.symFlexProductX)
        \o message.reserved8

DecodeFlexPriceInquiryInputMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    LET orderNo == ReadBytes(msgTimeNs.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symFlexProductX == DecodeSymFlexProductX2(msgTypeExt.value, fcmId.rest) IN IF ~symFlexProductX.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(symFlexProductX.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ preserve        |-> preserve.value,
         msgTimeNs       |-> msgTimeNs.value,
         orderNo         |-> orderNo.value,
         ordId           |-> ordId.value,
         fcmId           |-> fcmId.value,
         symFlexProductX |-> symFlexProductX.value,
         reserved8       |-> reserved8.value ], reserved8.rest)

ZeroFlexPriceInquiryInputMessage ==
    [ preserve        |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs       |-> [i \in 1 .. 4 |-> 0],
      orderNo         |-> [i \in 1 .. 5 |-> 0],
      ordId           |-> [i \in 1 .. 4 |-> 0],
      fcmId           |-> [i \in 1 .. 2 |-> 0],
      symFlexProductX |-> ZeroSymFlexProductX2,
      reserved8       |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Price Inquiry Input Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexPriceInquiryInputMessage ==
    { ZeroFlexPriceInquiryInputMessage }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.msgTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX2 }
        \cup { [ZeroFlexPriceInquiryInputMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol Num X: 4 bytes                                                   *)
(***************************************************************************)

SymbolNumX3 ==
    [ pseq : Sample(4) ]

EncodeSymbolNumX3(message) ==
    message.pseq

DecodeSymbolNumX3(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolNumX3 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNumX3 ==
    { ZeroSymbolNumX3 }
        \cup { [ZeroSymbolNumX3 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Txt X: 20 bytes                                                  *)
(***************************************************************************)

SymbolTxtX3 ==
    [ prodId : Sample(20) ]

EncodeSymbolTxtX3(message) ==
    message.prodId

DecodeSymbolTxtX3(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroSymbolTxtX3 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolTxtX3 ==
    { ZeroSymbolTxtX3 }
        \cup { [ZeroSymbolTxtX3 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Sym Symbol Num X: 4 bytes                                           *)
(***************************************************************************)

LegSymSymbolNumX3 ==
    [ pseq : Sample(4) ]

EncodeLegSymSymbolNumX3(message) ==
    message.pseq

DecodeLegSymSymbolNumX3(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegSymSymbolNumX3 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Sym Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolNumX3 ==
    { ZeroLegSymSymbolNumX3 }
        \cup { [ZeroLegSymSymbolNumX3 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Entry Num: 7 bytes                                                  *)
(***************************************************************************)

LegEntryNum3 ==
    [ legSymSymbolNumX : LegSymSymbolNumX3,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryNum3(message) ==
    EncodeLegSymSymbolNumX3(message.legSymSymbolNumX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryNum3(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX3(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryNum3 ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX3,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum3 ==
    { ZeroLegEntryNum3 }
        \cup { [ZeroLegEntryNum3 EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX3 }
        \cup { [ZeroLegEntryNum3 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum3 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Num, written one after another *)
RECURSIVE EncodeLegEntryNum3List(_)
EncodeLegEntryNum3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryNum3(Head(messages)) \o EncodeLegEntryNum3List(Tail(messages))

(* As many Leg Entry Num as the field that counts them says *)
RECURSIVE ReadLegEntryNum3List(_, _)
ReadLegEntryNum3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryNum3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryNum3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Num of each kind, for the lists that carry them *)
OneLegEntryNum3 == { ZeroLegEntryNum3 }

(***************************************************************************)
(* Multi Leg Num                                                           *)
(***************************************************************************)

MultiLegNum3 ==
    [ combOp      : Sample(1),
      legEntryNum : SampleLists(OneLegEntryNum3) ]

EncodeMultiLegNum3(message) ==
    EncodeUIntBE(Len(message.legEntryNum), 1)
        \o message.combOp
        \o EncodeLegEntryNum3List(message.legEntryNum)

DecodeMultiLegNum3(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryNum == ReadLegEntryNum3List(combOp.rest, noLeg.value) IN IF ~legEntryNum.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryNum |-> legEntryNum.value ], legEntryNum.rest)

ZeroMultiLegNum3 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryNum |-> << >> ]

(* Multi Leg Num at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegNum3 ==
    { ZeroMultiLegNum3 }
        \cup { [ZeroMultiLegNum3 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegNum3 EXCEPT !.legEntryNum = one] : one \in SampleLists(OneLegEntryNum3) }

(***************************************************************************)
(* Leg Sym Symbol Txt X: 20 bytes                                          *)
(***************************************************************************)

LegSymSymbolTxtX3 ==
    [ prodId : Sample(20) ]

EncodeLegSymSymbolTxtX3(message) ==
    message.prodId

DecodeLegSymSymbolTxtX3(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroLegSymSymbolTxtX3 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Leg Sym Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolTxtX3 ==
    { ZeroLegSymSymbolTxtX3 }
        \cup { [ZeroLegSymSymbolTxtX3 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Entry Txt: 23 bytes                                                 *)
(***************************************************************************)

LegEntryTxt3 ==
    [ legSymSymbolTxtX : LegSymSymbolTxtX3,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryTxt3(message) ==
    EncodeLegSymSymbolTxtX3(message.legSymSymbolTxtX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryTxt3(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX3(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryTxt3 ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX3,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt3 ==
    { ZeroLegEntryTxt3 }
        \cup { [ZeroLegEntryTxt3 EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX3 }
        \cup { [ZeroLegEntryTxt3 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt3 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Txt, written one after another *)
RECURSIVE EncodeLegEntryTxt3List(_)
EncodeLegEntryTxt3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryTxt3(Head(messages)) \o EncodeLegEntryTxt3List(Tail(messages))

(* As many Leg Entry Txt as the field that counts them says *)
RECURSIVE ReadLegEntryTxt3List(_, _)
ReadLegEntryTxt3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryTxt3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryTxt3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Txt of each kind, for the lists that carry them *)
OneLegEntryTxt3 == { ZeroLegEntryTxt3 }

(***************************************************************************)
(* Multi Leg Txt                                                           *)
(***************************************************************************)

MultiLegTxt3 ==
    [ combOp      : Sample(1),
      legEntryTxt : SampleLists(OneLegEntryTxt3) ]

EncodeMultiLegTxt3(message) ==
    EncodeUIntBE(Len(message.legEntryTxt), 1)
        \o message.combOp
        \o EncodeLegEntryTxt3List(message.legEntryTxt)

DecodeMultiLegTxt3(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryTxt == ReadLegEntryTxt3List(combOp.rest, noLeg.value) IN IF ~legEntryTxt.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryTxt |-> legEntryTxt.value ], legEntryTxt.rest)

ZeroMultiLegTxt3 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryTxt |-> << >> ]

(* Multi Leg Txt at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegTxt3 ==
    { ZeroMultiLegTxt3 }
        \cup { [ZeroMultiLegTxt3 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegTxt3 EXCEPT !.legEntryTxt = one] : one \in SampleLists(OneLegEntryTxt3) }

(***************************************************************************)
(* Sym Flex Product X, selected by Msg Type Ext                            *)
(***************************************************************************)

SymbolNumXCode3 == 1  \* 0x01
SymbolTxtXCode3 == 2  \* 0x02
MultiLegNumCode3 == 3  \* 0x03
MultiLegTxtCode3 == 4  \* 0x04

SymFlexProductX3 ==
    [ tag : {SymbolNumXCode3}, body : SymbolNumX3 ]
        \cup [ tag : {SymbolTxtXCode3}, body : SymbolTxtX3 ]
        \cup [ tag : {MultiLegNumCode3}, body : MultiLegNum3 ]
        \cup [ tag : {MultiLegTxtCode3}, body : MultiLegTxt3 ]

EncodeSymFlexProductX3(message) ==
    CASE message.tag = SymbolNumXCode3 -> EncodeSymbolNumX3(message.body)
      [] message.tag = SymbolTxtXCode3 -> EncodeSymbolTxtX3(message.body)
      [] message.tag = MultiLegNumCode3 -> EncodeMultiLegNum3(message.body)
      [] message.tag = MultiLegTxtCode3 -> EncodeMultiLegTxt3(message.body)

DecodeSymFlexProductX3(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumXCode3 -> DecodeSymbolNumX3(bytes)
              [] tag = SymbolTxtXCode3 -> DecodeSymbolTxtX3(bytes)
              [] tag = MultiLegNumCode3 -> DecodeMultiLegNum3(bytes)
              [] tag = MultiLegTxtCode3 -> DecodeMultiLegTxt3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexProductX3 == [tag |-> SymbolNumXCode3, body |-> ZeroSymbolNumX3]

(* Each Sym Flex Product X in turn, at the values the message it names is checked at *)
CheckedSymFlexProductX3 ==
    { [tag |-> SymbolNumXCode3, body |-> one] : one \in CheckedSymbolNumX3 }
        \cup { [tag |-> SymbolTxtXCode3, body |-> one] : one \in CheckedSymbolTxtX3 }
        \cup { [tag |-> MultiLegNumCode3, body |-> one] : one \in CheckedMultiLegNum3 }
        \cup { [tag |-> MultiLegTxtCode3, body |-> one] : one \in CheckedMultiLegTxt3 }

(***************************************************************************)
(* Flex Quote Input Message                                                *)
(***************************************************************************)

FlexQuoteInputMessage ==
    [ preserve        : Sample(1),
      msgTimeNs       : Sample(4),
      execType        : Sample(1),
      cmId            : Sample(2),
      fcmId           : Sample(2),
      orderNo         : Sample(5),
      ordId           : Sample(4),
      userDefine      : Sample(8),
      symFlexProductX : SymFlexProductX3,
      bidPx           : Sample(4),
      offerPx         : Sample(4),
      bidSize         : Sample(2),
      offerSize       : Sample(2),
      investorAcno    : Sample(4),
      investorFlag    : Sample(1),
      timeInForce     : Sample(1),
      positionEffect  : Sample(1),
      reserved12      : Sample(12) ]

EncodeFlexQuoteInputMessage(message) ==
    EncodeUIntBE(message.symFlexProductX.tag, 1)
        \o message.preserve
        \o message.msgTimeNs
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeSymFlexProductX3(message.symFlexProductX)
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.investorAcno
        \o message.investorFlag
        \o message.timeInForce
        \o message.positionEffect
        \o message.reserved12

DecodeFlexQuoteInputMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    LET execType == ReadBytes(msgTimeNs.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symFlexProductX == DecodeSymFlexProductX3(msgTypeExt.value, userDefine.rest) IN IF ~symFlexProductX.ok THEN Fail ELSE
    LET bidPx == ReadBytes(symFlexProductX.rest, 4) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 4) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(offerSize.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(investorFlag.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(positionEffect.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ preserve        |-> preserve.value,
         msgTimeNs       |-> msgTimeNs.value,
         execType        |-> execType.value,
         cmId            |-> cmId.value,
         fcmId           |-> fcmId.value,
         orderNo         |-> orderNo.value,
         ordId           |-> ordId.value,
         userDefine      |-> userDefine.value,
         symFlexProductX |-> symFlexProductX.value,
         bidPx           |-> bidPx.value,
         offerPx         |-> offerPx.value,
         bidSize         |-> bidSize.value,
         offerSize       |-> offerSize.value,
         investorAcno    |-> investorAcno.value,
         investorFlag    |-> investorFlag.value,
         timeInForce     |-> timeInForce.value,
         positionEffect  |-> positionEffect.value,
         reserved12      |-> reserved12.value ], reserved12.rest)

ZeroFlexQuoteInputMessage ==
    [ preserve        |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs       |-> [i \in 1 .. 4 |-> 0],
      execType        |-> [i \in 1 .. 1 |-> 0],
      cmId            |-> [i \in 1 .. 2 |-> 0],
      fcmId           |-> [i \in 1 .. 2 |-> 0],
      orderNo         |-> [i \in 1 .. 5 |-> 0],
      ordId           |-> [i \in 1 .. 4 |-> 0],
      userDefine      |-> [i \in 1 .. 8 |-> 0],
      symFlexProductX |-> ZeroSymFlexProductX3,
      bidPx           |-> [i \in 1 .. 4 |-> 0],
      offerPx         |-> [i \in 1 .. 4 |-> 0],
      bidSize         |-> [i \in 1 .. 2 |-> 0],
      offerSize       |-> [i \in 1 .. 2 |-> 0],
      investorAcno    |-> [i \in 1 .. 4 |-> 0],
      investorFlag    |-> [i \in 1 .. 1 |-> 0],
      timeInForce     |-> [i \in 1 .. 1 |-> 0],
      positionEffect  |-> [i \in 1 .. 1 |-> 0],
      reserved12      |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Quote Input Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexQuoteInputMessage ==
    { ZeroFlexQuoteInputMessage }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.msgTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX3 }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.bidPx = one] : one \in Sample(4) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.offerPx = one] : one \in Sample(4) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroFlexQuoteInputMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr2 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr2(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr2(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr2 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr2 ==
    { ZeroSubHdr2 }
        \cup { [ZeroSubHdr2 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr2 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr2 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Request For Supplementary Flex Group Report Message: 11 bytes           *)
(***************************************************************************)

RequestForSupplementaryFlexGroupReportMessage ==
    [ subHdr          : SubHdr2,
      partId          : Sample(1),
      requestStartSeq : Sample(4) ]

EncodeRequestForSupplementaryFlexGroupReportMessage(message) ==
    EncodeSubHdr2(message.subHdr)
        \o message.partId
        \o message.requestStartSeq

DecodeRequestForSupplementaryFlexGroupReportMessage(bytes) ==
    LET subHdr == DecodeSubHdr2(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET requestStartSeq == ReadBytes(partId.rest, 4) IN IF ~requestStartSeq.ok THEN Fail ELSE
    Ok([ subHdr          |-> subHdr.value,
         partId          |-> partId.value,
         requestStartSeq |-> requestStartSeq.value ], requestStartSeq.rest)

ZeroRequestForSupplementaryFlexGroupReportMessage ==
    [ subHdr          |-> ZeroSubHdr2,
      partId          |-> [i \in 1 .. 1 |-> 0],
      requestStartSeq |-> [i \in 1 .. 4 |-> 0] ]

(* Request For Supplementary Flex Group Report Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestForSupplementaryFlexGroupReportMessage ==
    { ZeroRequestForSupplementaryFlexGroupReportMessage }
        \cup { [ZeroRequestForSupplementaryFlexGroupReportMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr2 }
        \cup { [ZeroRequestForSupplementaryFlexGroupReportMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroRequestForSupplementaryFlexGroupReportMessage EXCEPT !.requestStartSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr3 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr3(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr3(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr3 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr3 ==
    { ZeroSubHdr3 }
        \cup { [ZeroSubHdr3 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr3 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr3 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Temporary Suspension Of Supplementary Flex Group Report Message: 7      *)
(* bytes                                                                   *)
(***************************************************************************)

TemporarySuspensionOfSupplementaryFlexGroupReportMessage ==
    [ subHdr : SubHdr3,
      partId : Sample(1) ]

EncodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(message) ==
    EncodeSubHdr3(message.subHdr)
        \o message.partId

DecodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(bytes) ==
    LET subHdr == DecodeSubHdr3(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    Ok([ subHdr |-> subHdr.value,
         partId |-> partId.value ], partId.rest)

ZeroTemporarySuspensionOfSupplementaryFlexGroupReportMessage ==
    [ subHdr |-> ZeroSubHdr3,
      partId |-> [i \in 1 .. 1 |-> 0] ]

(* Temporary Suspension Of Supplementary Flex Group Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTemporarySuspensionOfSupplementaryFlexGroupReportMessage ==
    { ZeroTemporarySuspensionOfSupplementaryFlexGroupReportMessage }
        \cup { [ZeroTemporarySuspensionOfSupplementaryFlexGroupReportMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr3 }
        \cup { [ZeroTemporarySuspensionOfSupplementaryFlexGroupReportMessage EXCEPT !.partId = one] : one \in Sample(1) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr4 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr4(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr4(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr4 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr4 ==
    { ZeroSubHdr4 }
        \cup { [ZeroSubHdr4 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr4 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr4 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Product Definition Request Message: 56 bytes                       *)
(***************************************************************************)

FlexProductDefinitionRequestMessage ==
    [ subHdr              : SubHdr4,
      securityRequestType : Sample(1),
      securityReqId       : Sample(4),
      type                : Sample(1),
      fcmId               : Sample(2),
      investorAcno        : Sample(4),
      applicationType     : Sample(1),
      rootSymbol          : Sample(3),
      expiryType          : Sample(1),
      contractDate        : Sample(8),
      strikePrice         : Sample(4),
      callPutCode         : Sample(1),
      reserved20          : Sample(20) ]

EncodeFlexProductDefinitionRequestMessage(message) ==
    EncodeSubHdr4(message.subHdr)
        \o message.securityRequestType
        \o message.securityReqId
        \o message.type
        \o message.fcmId
        \o message.investorAcno
        \o message.applicationType
        \o message.rootSymbol
        \o message.expiryType
        \o message.contractDate
        \o message.strikePrice
        \o message.callPutCode
        \o message.reserved20

DecodeFlexProductDefinitionRequestMessage(bytes) ==
    LET subHdr == DecodeSubHdr4(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(subHdr.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(securityRequestType.rest, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET type == ReadBytes(securityReqId.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET fcmId == ReadBytes(type.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(fcmId.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET applicationType == ReadBytes(investorAcno.rest, 1) IN IF ~applicationType.ok THEN Fail ELSE
    LET rootSymbol == ReadBytes(applicationType.rest, 3) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryType == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryType.ok THEN Fail ELSE
    LET contractDate == ReadBytes(expiryType.rest, 8) IN IF ~contractDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(contractDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(strikePrice.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET reserved20 == ReadBytes(callPutCode.rest, 20) IN IF ~reserved20.ok THEN Fail ELSE
    Ok([ subHdr              |-> subHdr.value,
         securityRequestType |-> securityRequestType.value,
         securityReqId       |-> securityReqId.value,
         type                |-> type.value,
         fcmId               |-> fcmId.value,
         investorAcno        |-> investorAcno.value,
         applicationType     |-> applicationType.value,
         rootSymbol          |-> rootSymbol.value,
         expiryType          |-> expiryType.value,
         contractDate        |-> contractDate.value,
         strikePrice         |-> strikePrice.value,
         callPutCode         |-> callPutCode.value,
         reserved20          |-> reserved20.value ], reserved20.rest)

ZeroFlexProductDefinitionRequestMessage ==
    [ subHdr              |-> ZeroSubHdr4,
      securityRequestType |-> [i \in 1 .. 1 |-> 0],
      securityReqId       |-> [i \in 1 .. 4 |-> 0],
      type                |-> [i \in 1 .. 1 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      investorAcno        |-> [i \in 1 .. 4 |-> 0],
      applicationType     |-> [i \in 1 .. 1 |-> 0],
      rootSymbol          |-> [i \in 1 .. 3 |-> 0],
      expiryType          |-> [i \in 1 .. 1 |-> 0],
      contractDate        |-> [i \in 1 .. 8 |-> 0],
      strikePrice         |-> [i \in 1 .. 4 |-> 0],
      callPutCode         |-> [i \in 1 .. 1 |-> 0],
      reserved20          |-> [i \in 1 .. 20 |-> 0] ]

(* Flex Product Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexProductDefinitionRequestMessage ==
    { ZeroFlexProductDefinitionRequestMessage }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr4 }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.applicationType = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.rootSymbol = one] : one \in Sample(3) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.expiryType = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.contractDate = one] : one \in Sample(8) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionRequestMessage EXCEPT !.reserved20 = one] : one \in Sample(20) }

(***************************************************************************)
(* Symbol Num X: 4 bytes                                                   *)
(***************************************************************************)

SymbolNumX4 ==
    [ pseq : Sample(4) ]

EncodeSymbolNumX4(message) ==
    message.pseq

DecodeSymbolNumX4(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolNumX4 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNumX4 ==
    { ZeroSymbolNumX4 }
        \cup { [ZeroSymbolNumX4 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Txt X: 20 bytes                                                  *)
(***************************************************************************)

SymbolTxtX4 ==
    [ prodId : Sample(20) ]

EncodeSymbolTxtX4(message) ==
    message.prodId

DecodeSymbolTxtX4(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroSymbolTxtX4 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolTxtX4 ==
    { ZeroSymbolTxtX4 }
        \cup { [ZeroSymbolTxtX4 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Sym Symbol Num X: 4 bytes                                           *)
(***************************************************************************)

LegSymSymbolNumX4 ==
    [ pseq : Sample(4) ]

EncodeLegSymSymbolNumX4(message) ==
    message.pseq

DecodeLegSymSymbolNumX4(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegSymSymbolNumX4 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Sym Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolNumX4 ==
    { ZeroLegSymSymbolNumX4 }
        \cup { [ZeroLegSymSymbolNumX4 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Entry Num: 7 bytes                                                  *)
(***************************************************************************)

LegEntryNum4 ==
    [ legSymSymbolNumX : LegSymSymbolNumX4,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryNum4(message) ==
    EncodeLegSymSymbolNumX4(message.legSymSymbolNumX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryNum4(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX4(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryNum4 ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX4,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum4 ==
    { ZeroLegEntryNum4 }
        \cup { [ZeroLegEntryNum4 EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX4 }
        \cup { [ZeroLegEntryNum4 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum4 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Num, written one after another *)
RECURSIVE EncodeLegEntryNum4List(_)
EncodeLegEntryNum4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryNum4(Head(messages)) \o EncodeLegEntryNum4List(Tail(messages))

(* As many Leg Entry Num as the field that counts them says *)
RECURSIVE ReadLegEntryNum4List(_, _)
ReadLegEntryNum4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryNum4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryNum4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Num of each kind, for the lists that carry them *)
OneLegEntryNum4 == { ZeroLegEntryNum4 }

(***************************************************************************)
(* Multi Leg Num                                                           *)
(***************************************************************************)

MultiLegNum4 ==
    [ combOp      : Sample(1),
      legEntryNum : SampleLists(OneLegEntryNum4) ]

EncodeMultiLegNum4(message) ==
    EncodeUIntBE(Len(message.legEntryNum), 1)
        \o message.combOp
        \o EncodeLegEntryNum4List(message.legEntryNum)

DecodeMultiLegNum4(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryNum == ReadLegEntryNum4List(combOp.rest, noLeg.value) IN IF ~legEntryNum.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryNum |-> legEntryNum.value ], legEntryNum.rest)

ZeroMultiLegNum4 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryNum |-> << >> ]

(* Multi Leg Num at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegNum4 ==
    { ZeroMultiLegNum4 }
        \cup { [ZeroMultiLegNum4 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegNum4 EXCEPT !.legEntryNum = one] : one \in SampleLists(OneLegEntryNum4) }

(***************************************************************************)
(* Leg Sym Symbol Txt X: 20 bytes                                          *)
(***************************************************************************)

LegSymSymbolTxtX4 ==
    [ prodId : Sample(20) ]

EncodeLegSymSymbolTxtX4(message) ==
    message.prodId

DecodeLegSymSymbolTxtX4(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroLegSymSymbolTxtX4 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Leg Sym Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolTxtX4 ==
    { ZeroLegSymSymbolTxtX4 }
        \cup { [ZeroLegSymSymbolTxtX4 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Entry Txt: 23 bytes                                                 *)
(***************************************************************************)

LegEntryTxt4 ==
    [ legSymSymbolTxtX : LegSymSymbolTxtX4,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryTxt4(message) ==
    EncodeLegSymSymbolTxtX4(message.legSymSymbolTxtX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryTxt4(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX4(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryTxt4 ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX4,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt4 ==
    { ZeroLegEntryTxt4 }
        \cup { [ZeroLegEntryTxt4 EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX4 }
        \cup { [ZeroLegEntryTxt4 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt4 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Txt, written one after another *)
RECURSIVE EncodeLegEntryTxt4List(_)
EncodeLegEntryTxt4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryTxt4(Head(messages)) \o EncodeLegEntryTxt4List(Tail(messages))

(* As many Leg Entry Txt as the field that counts them says *)
RECURSIVE ReadLegEntryTxt4List(_, _)
ReadLegEntryTxt4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryTxt4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryTxt4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Txt of each kind, for the lists that carry them *)
OneLegEntryTxt4 == { ZeroLegEntryTxt4 }

(***************************************************************************)
(* Multi Leg Txt                                                           *)
(***************************************************************************)

MultiLegTxt4 ==
    [ combOp      : Sample(1),
      legEntryTxt : SampleLists(OneLegEntryTxt4) ]

EncodeMultiLegTxt4(message) ==
    EncodeUIntBE(Len(message.legEntryTxt), 1)
        \o message.combOp
        \o EncodeLegEntryTxt4List(message.legEntryTxt)

DecodeMultiLegTxt4(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryTxt == ReadLegEntryTxt4List(combOp.rest, noLeg.value) IN IF ~legEntryTxt.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryTxt |-> legEntryTxt.value ], legEntryTxt.rest)

ZeroMultiLegTxt4 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryTxt |-> << >> ]

(* Multi Leg Txt at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegTxt4 ==
    { ZeroMultiLegTxt4 }
        \cup { [ZeroMultiLegTxt4 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegTxt4 EXCEPT !.legEntryTxt = one] : one \in SampleLists(OneLegEntryTxt4) }

(***************************************************************************)
(* Sym Flex Product X, selected by Msg Type Ext                            *)
(***************************************************************************)

SymbolNumXCode4 == 1  \* 0x01
SymbolTxtXCode4 == 2  \* 0x02
MultiLegNumCode4 == 3  \* 0x03
MultiLegTxtCode4 == 4  \* 0x04

SymFlexProductX4 ==
    [ tag : {SymbolNumXCode4}, body : SymbolNumX4 ]
        \cup [ tag : {SymbolTxtXCode4}, body : SymbolTxtX4 ]
        \cup [ tag : {MultiLegNumCode4}, body : MultiLegNum4 ]
        \cup [ tag : {MultiLegTxtCode4}, body : MultiLegTxt4 ]

EncodeSymFlexProductX4(message) ==
    CASE message.tag = SymbolNumXCode4 -> EncodeSymbolNumX4(message.body)
      [] message.tag = SymbolTxtXCode4 -> EncodeSymbolTxtX4(message.body)
      [] message.tag = MultiLegNumCode4 -> EncodeMultiLegNum4(message.body)
      [] message.tag = MultiLegTxtCode4 -> EncodeMultiLegTxt4(message.body)

DecodeSymFlexProductX4(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumXCode4 -> DecodeSymbolNumX4(bytes)
              [] tag = SymbolTxtXCode4 -> DecodeSymbolTxtX4(bytes)
              [] tag = MultiLegNumCode4 -> DecodeMultiLegNum4(bytes)
              [] tag = MultiLegTxtCode4 -> DecodeMultiLegTxt4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexProductX4 == [tag |-> SymbolNumXCode4, body |-> ZeroSymbolNumX4]

(* Each Sym Flex Product X in turn, at the values the message it names is checked at *)
CheckedSymFlexProductX4 ==
    { [tag |-> SymbolNumXCode4, body |-> one] : one \in CheckedSymbolNumX4 }
        \cup { [tag |-> SymbolTxtXCode4, body |-> one] : one \in CheckedSymbolTxtX4 }
        \cup { [tag |-> MultiLegNumCode4, body |-> one] : one \in CheckedMultiLegNum4 }
        \cup { [tag |-> MultiLegTxtCode4, body |-> one] : one \in CheckedMultiLegTxt4 }

(***************************************************************************)
(* Org Trans Time Msg Time X: 8 bytes                                      *)
(***************************************************************************)

OrgTransTimeMsgTimeX ==
    [ msgTimeXEpochS : Sample(4),
      nanosecond     : Sample(4) ]

EncodeOrgTransTimeMsgTimeX(message) ==
    message.msgTimeXEpochS
        \o message.nanosecond

DecodeOrgTransTimeMsgTimeX(bytes) ==
    LET msgTimeXEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeXEpochS.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(msgTimeXEpochS.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ msgTimeXEpochS |-> msgTimeXEpochS.value,
         nanosecond     |-> nanosecond.value ], nanosecond.rest)

ZeroOrgTransTimeMsgTimeX ==
    [ msgTimeXEpochS |-> [i \in 1 .. 4 |-> 0],
      nanosecond     |-> [i \in 1 .. 4 |-> 0] ]

(* Org Trans Time Msg Time X at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTimeX ==
    { ZeroOrgTransTimeMsgTimeX }
        \cup { [ZeroOrgTransTimeMsgTimeX EXCEPT !.msgTimeXEpochS = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTimeX EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Transact Time Msg Time X: 8 bytes                                       *)
(***************************************************************************)

TransactTimeMsgTimeX ==
    [ msgTimeXEpochS : Sample(4),
      nanosecond     : Sample(4) ]

EncodeTransactTimeMsgTimeX(message) ==
    message.msgTimeXEpochS
        \o message.nanosecond

DecodeTransactTimeMsgTimeX(bytes) ==
    LET msgTimeXEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeXEpochS.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(msgTimeXEpochS.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ msgTimeXEpochS |-> msgTimeXEpochS.value,
         nanosecond     |-> nanosecond.value ], nanosecond.rest)

ZeroTransactTimeMsgTimeX ==
    [ msgTimeXEpochS |-> [i \in 1 .. 4 |-> 0],
      nanosecond     |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time Msg Time X at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTimeX ==
    { ZeroTransactTimeMsgTimeX }
        \cup { [ZeroTransactTimeMsgTimeX EXCEPT !.msgTimeXEpochS = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTimeX EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Order Status Report Message                                        *)
(***************************************************************************)

FlexOrderStatusReportMessage ==
    [ preserve             : Sample(1),
      msgTimeNs            : Sample(4),
      partId               : Sample(1),
      noLeg                : Sample(1),
      wideStatusCode       : Sample(2),
      execType             : Sample(1),
      cmId                 : Sample(2),
      fcmId                : Sample(2),
      orderNo              : Sample(5),
      ordId                : Sample(4),
      userDefine           : Sample(8),
      symFlexProductX      : SymFlexProductX4,
      price                : Sample(4),
      qty                  : Sample(2),
      investorAcno         : Sample(4),
      investorFlag         : Sample(1),
      side                 : Sample(1),
      ordType              : Sample(1),
      timeInForce          : Sample(1),
      positionEffect       : Sample(1),
      lastPx               : Sample(4),
      lastQty              : Sample(2),
      pxSubtotal           : Sample(8),
      cumQty               : Sample(2),
      leavesQty            : Sample(2),
      beforeQty            : Sample(2),
      orgTransTimeMsgTimeX : OrgTransTimeMsgTimeX,
      transactTimeMsgTimeX : TransactTimeMsgTimeX,
      targetId             : Sample(1),
      uniqId               : Sample(4),
      rptSeq               : Sample(4),
      rptSessionId         : Sample(2),
      rptSessionSeq        : Sample(4),
      reserved12           : Sample(12) ]

EncodeFlexOrderStatusReportMessage(message) ==
    EncodeUIntBE(message.symFlexProductX.tag, 1)
        \o message.preserve
        \o message.msgTimeNs
        \o message.partId
        \o message.noLeg
        \o message.wideStatusCode
        \o message.execType
        \o message.cmId
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o EncodeSymFlexProductX4(message.symFlexProductX)
        \o message.price
        \o message.qty
        \o message.investorAcno
        \o message.investorFlag
        \o message.side
        \o message.ordType
        \o message.timeInForce
        \o message.positionEffect
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o EncodeOrgTransTimeMsgTimeX(message.orgTransTimeMsgTimeX)
        \o EncodeTransactTimeMsgTimeX(message.transactTimeMsgTimeX)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.rptSessionId
        \o message.rptSessionSeq
        \o message.reserved12

DecodeFlexOrderStatusReportMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    LET partId == ReadBytes(msgTimeNs.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET noLeg == ReadBytes(partId.rest, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(noLeg.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(wideStatusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET cmId == ReadBytes(execType.rest, 2) IN IF ~cmId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(cmId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET symFlexProductX == DecodeSymFlexProductX4(msgTypeExt.value, userDefine.rest) IN IF ~symFlexProductX.ok THEN Fail ELSE
    LET price == ReadBytes(symFlexProductX.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET qty == ReadBytes(price.rest, 2) IN IF ~qty.ok THEN Fail ELSE
    LET investorAcno == ReadBytes(qty.rest, 4) IN IF ~investorAcno.ok THEN Fail ELSE
    LET investorFlag == ReadBytes(investorAcno.rest, 1) IN IF ~investorFlag.ok THEN Fail ELSE
    LET side == ReadBytes(investorFlag.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(timeInForce.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET orgTransTimeMsgTimeX == DecodeOrgTransTimeMsgTimeX(beforeQty.rest) IN IF ~orgTransTimeMsgTimeX.ok THEN Fail ELSE
    LET transactTimeMsgTimeX == DecodeTransactTimeMsgTimeX(orgTransTimeMsgTimeX.rest) IN IF ~transactTimeMsgTimeX.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTimeX.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET rptSessionId == ReadBytes(rptSeq.rest, 2) IN IF ~rptSessionId.ok THEN Fail ELSE
    LET rptSessionSeq == ReadBytes(rptSessionId.rest, 4) IN IF ~rptSessionSeq.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(rptSessionSeq.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ preserve             |-> preserve.value,
         msgTimeNs            |-> msgTimeNs.value,
         partId               |-> partId.value,
         noLeg                |-> noLeg.value,
         wideStatusCode       |-> wideStatusCode.value,
         execType             |-> execType.value,
         cmId                 |-> cmId.value,
         fcmId                |-> fcmId.value,
         orderNo              |-> orderNo.value,
         ordId                |-> ordId.value,
         userDefine           |-> userDefine.value,
         symFlexProductX      |-> symFlexProductX.value,
         price                |-> price.value,
         qty                  |-> qty.value,
         investorAcno         |-> investorAcno.value,
         investorFlag         |-> investorFlag.value,
         side                 |-> side.value,
         ordType              |-> ordType.value,
         timeInForce          |-> timeInForce.value,
         positionEffect       |-> positionEffect.value,
         lastPx               |-> lastPx.value,
         lastQty              |-> lastQty.value,
         pxSubtotal           |-> pxSubtotal.value,
         cumQty               |-> cumQty.value,
         leavesQty            |-> leavesQty.value,
         beforeQty            |-> beforeQty.value,
         orgTransTimeMsgTimeX |-> orgTransTimeMsgTimeX.value,
         transactTimeMsgTimeX |-> transactTimeMsgTimeX.value,
         targetId             |-> targetId.value,
         uniqId               |-> uniqId.value,
         rptSeq               |-> rptSeq.value,
         rptSessionId         |-> rptSessionId.value,
         rptSessionSeq        |-> rptSessionSeq.value,
         reserved12           |-> reserved12.value ], reserved12.rest)

ZeroFlexOrderStatusReportMessage ==
    [ preserve             |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs            |-> [i \in 1 .. 4 |-> 0],
      partId               |-> [i \in 1 .. 1 |-> 0],
      noLeg                |-> [i \in 1 .. 1 |-> 0],
      wideStatusCode       |-> [i \in 1 .. 2 |-> 0],
      execType             |-> [i \in 1 .. 1 |-> 0],
      cmId                 |-> [i \in 1 .. 2 |-> 0],
      fcmId                |-> [i \in 1 .. 2 |-> 0],
      orderNo              |-> [i \in 1 .. 5 |-> 0],
      ordId                |-> [i \in 1 .. 4 |-> 0],
      userDefine           |-> [i \in 1 .. 8 |-> 0],
      symFlexProductX      |-> ZeroSymFlexProductX4,
      price                |-> [i \in 1 .. 4 |-> 0],
      qty                  |-> [i \in 1 .. 2 |-> 0],
      investorAcno         |-> [i \in 1 .. 4 |-> 0],
      investorFlag         |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      ordType              |-> [i \in 1 .. 1 |-> 0],
      timeInForce          |-> [i \in 1 .. 1 |-> 0],
      positionEffect       |-> [i \in 1 .. 1 |-> 0],
      lastPx               |-> [i \in 1 .. 4 |-> 0],
      lastQty              |-> [i \in 1 .. 2 |-> 0],
      pxSubtotal           |-> [i \in 1 .. 8 |-> 0],
      cumQty               |-> [i \in 1 .. 2 |-> 0],
      leavesQty            |-> [i \in 1 .. 2 |-> 0],
      beforeQty            |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTimeX |-> ZeroOrgTransTimeMsgTimeX,
      transactTimeMsgTimeX |-> ZeroTransactTimeMsgTimeX,
      targetId             |-> [i \in 1 .. 1 |-> 0],
      uniqId               |-> [i \in 1 .. 4 |-> 0],
      rptSeq               |-> [i \in 1 .. 4 |-> 0],
      rptSessionId         |-> [i \in 1 .. 2 |-> 0],
      rptSessionSeq        |-> [i \in 1 .. 4 |-> 0],
      reserved12           |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexOrderStatusReportMessage ==
    { ZeroFlexOrderStatusReportMessage }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.msgTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.noLeg = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX4 }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.qty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.investorAcno = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.investorFlag = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.lastPx = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.lastQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.pxSubtotal = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.cumQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.leavesQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.beforeQty = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.orgTransTimeMsgTimeX = one] : one \in CheckedOrgTransTimeMsgTimeX }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.transactTimeMsgTimeX = one] : one \in CheckedTransactTimeMsgTimeX }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptSessionId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.rptSessionSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr5 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr5(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr5(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr5 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr5 ==
    { ZeroSubHdr5 }
        \cup { [ZeroSubHdr5 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr5 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr5 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Error Report Message: 47 bytes                                     *)
(***************************************************************************)

FlexErrorReportMessage ==
    [ subHdr         : SubHdr5,
      partId         : Sample(1),
      oriMessageType : Sample(1),
      wideStatusCode : Sample(2),
      execType       : Sample(1),
      fcmId          : Sample(2),
      orderNo        : Sample(5),
      ordId          : Sample(4),
      userDefine     : Sample(8),
      rptSeq         : Sample(4),
      side           : Sample(1),
      reserved12     : Sample(12) ]

EncodeFlexErrorReportMessage(message) ==
    EncodeSubHdr5(message.subHdr)
        \o message.partId
        \o message.oriMessageType
        \o message.wideStatusCode
        \o message.execType
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o message.rptSeq
        \o message.side
        \o message.reserved12

DecodeFlexErrorReportMessage(bytes) ==
    LET subHdr == DecodeSubHdr5(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET oriMessageType == ReadBytes(partId.rest, 1) IN IF ~oriMessageType.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(oriMessageType.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET execType == ReadBytes(wideStatusCode.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(execType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(userDefine.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET side == ReadBytes(rptSeq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(side.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ subHdr         |-> subHdr.value,
         partId         |-> partId.value,
         oriMessageType |-> oriMessageType.value,
         wideStatusCode |-> wideStatusCode.value,
         execType       |-> execType.value,
         fcmId          |-> fcmId.value,
         orderNo        |-> orderNo.value,
         ordId          |-> ordId.value,
         userDefine     |-> userDefine.value,
         rptSeq         |-> rptSeq.value,
         side           |-> side.value,
         reserved12     |-> reserved12.value ], reserved12.rest)

ZeroFlexErrorReportMessage ==
    [ subHdr         |-> ZeroSubHdr5,
      partId         |-> [i \in 1 .. 1 |-> 0],
      oriMessageType |-> [i \in 1 .. 1 |-> 0],
      wideStatusCode |-> [i \in 1 .. 2 |-> 0],
      execType       |-> [i \in 1 .. 1 |-> 0],
      fcmId          |-> [i \in 1 .. 2 |-> 0],
      orderNo        |-> [i \in 1 .. 5 |-> 0],
      ordId          |-> [i \in 1 .. 4 |-> 0],
      userDefine     |-> [i \in 1 .. 8 |-> 0],
      rptSeq         |-> [i \in 1 .. 4 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      reserved12     |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Error Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexErrorReportMessage ==
    { ZeroFlexErrorReportMessage }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr5 }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.oriMessageType = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Symbol Num X: 4 bytes                                                   *)
(***************************************************************************)

SymbolNumX5 ==
    [ pseq : Sample(4) ]

EncodeSymbolNumX5(message) ==
    message.pseq

DecodeSymbolNumX5(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroSymbolNumX5 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNumX5 ==
    { ZeroSymbolNumX5 }
        \cup { [ZeroSymbolNumX5 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Symbol Txt X: 20 bytes                                                  *)
(***************************************************************************)

SymbolTxtX5 ==
    [ prodId : Sample(20) ]

EncodeSymbolTxtX5(message) ==
    message.prodId

DecodeSymbolTxtX5(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroSymbolTxtX5 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedSymbolTxtX5 ==
    { ZeroSymbolTxtX5 }
        \cup { [ZeroSymbolTxtX5 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Sym Symbol Num X: 4 bytes                                           *)
(***************************************************************************)

LegSymSymbolNumX5 ==
    [ pseq : Sample(4) ]

EncodeLegSymSymbolNumX5(message) ==
    message.pseq

DecodeLegSymSymbolNumX5(bytes) ==
    LET pseq == ReadBytes(bytes, 4) IN IF ~pseq.ok THEN Fail ELSE
    Ok([ pseq |-> pseq.value ], pseq.rest)

ZeroLegSymSymbolNumX5 ==
    [ pseq |-> [i \in 1 .. 4 |-> 0] ]

(* Leg Sym Symbol Num X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolNumX5 ==
    { ZeroLegSymSymbolNumX5 }
        \cup { [ZeroLegSymSymbolNumX5 EXCEPT !.pseq = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Entry Num: 7 bytes                                                  *)
(***************************************************************************)

LegEntryNum5 ==
    [ legSymSymbolNumX : LegSymSymbolNumX5,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryNum5(message) ==
    EncodeLegSymSymbolNumX5(message.legSymSymbolNumX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryNum5(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX5(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryNum5 ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX5,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum5 ==
    { ZeroLegEntryNum5 }
        \cup { [ZeroLegEntryNum5 EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX5 }
        \cup { [ZeroLegEntryNum5 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum5 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Num, written one after another *)
RECURSIVE EncodeLegEntryNum5List(_)
EncodeLegEntryNum5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryNum5(Head(messages)) \o EncodeLegEntryNum5List(Tail(messages))

(* As many Leg Entry Num as the field that counts them says *)
RECURSIVE ReadLegEntryNum5List(_, _)
ReadLegEntryNum5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryNum5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryNum5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Num of each kind, for the lists that carry them *)
OneLegEntryNum5 == { ZeroLegEntryNum5 }

(***************************************************************************)
(* Multi Leg Num                                                           *)
(***************************************************************************)

MultiLegNum5 ==
    [ combOp      : Sample(1),
      legEntryNum : SampleLists(OneLegEntryNum5) ]

EncodeMultiLegNum5(message) ==
    EncodeUIntBE(Len(message.legEntryNum), 1)
        \o message.combOp
        \o EncodeLegEntryNum5List(message.legEntryNum)

DecodeMultiLegNum5(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryNum == ReadLegEntryNum5List(combOp.rest, noLeg.value) IN IF ~legEntryNum.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryNum |-> legEntryNum.value ], legEntryNum.rest)

ZeroMultiLegNum5 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryNum |-> << >> ]

(* Multi Leg Num at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegNum5 ==
    { ZeroMultiLegNum5 }
        \cup { [ZeroMultiLegNum5 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegNum5 EXCEPT !.legEntryNum = one] : one \in SampleLists(OneLegEntryNum5) }

(***************************************************************************)
(* Leg Sym Symbol Txt X: 20 bytes                                          *)
(***************************************************************************)

LegSymSymbolTxtX5 ==
    [ prodId : Sample(20) ]

EncodeLegSymSymbolTxtX5(message) ==
    message.prodId

DecodeLegSymSymbolTxtX5(bytes) ==
    LET prodId == ReadBytes(bytes, 20) IN IF ~prodId.ok THEN Fail ELSE
    Ok([ prodId |-> prodId.value ], prodId.rest)

ZeroLegSymSymbolTxtX5 ==
    [ prodId |-> [i \in 1 .. 20 |-> 0] ]

(* Leg Sym Symbol Txt X at zero, then each field in turn at the values it is checked at *)
CheckedLegSymSymbolTxtX5 ==
    { ZeroLegSymSymbolTxtX5 }
        \cup { [ZeroLegSymSymbolTxtX5 EXCEPT !.prodId = one] : one \in Sample(20) }

(***************************************************************************)
(* Leg Entry Txt: 23 bytes                                                 *)
(***************************************************************************)

LegEntryTxt5 ==
    [ legSymSymbolTxtX : LegSymSymbolTxtX5,
      legSide          : Sample(1),
      legQty           : Sample(2) ]

EncodeLegEntryTxt5(message) ==
    EncodeLegSymSymbolTxtX5(message.legSymSymbolTxtX)
        \o message.legSide
        \o message.legQty

DecodeLegEntryTxt5(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX5(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legQty == ReadBytes(legSide.rest, 2) IN IF ~legQty.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSide          |-> legSide.value,
         legQty           |-> legQty.value ], legQty.rest)

ZeroLegEntryTxt5 ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX5,
      legSide          |-> [i \in 1 .. 1 |-> 0],
      legQty           |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt5 ==
    { ZeroLegEntryTxt5 }
        \cup { [ZeroLegEntryTxt5 EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX5 }
        \cup { [ZeroLegEntryTxt5 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt5 EXCEPT !.legQty = one] : one \in Sample(2) }

(* A run of Leg Entry Txt, written one after another *)
RECURSIVE EncodeLegEntryTxt5List(_)
EncodeLegEntryTxt5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegEntryTxt5(Head(messages)) \o EncodeLegEntryTxt5List(Tail(messages))

(* As many Leg Entry Txt as the field that counts them says *)
RECURSIVE ReadLegEntryTxt5List(_, _)
ReadLegEntryTxt5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegEntryTxt5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegEntryTxt5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Entry Txt of each kind, for the lists that carry them *)
OneLegEntryTxt5 == { ZeroLegEntryTxt5 }

(***************************************************************************)
(* Multi Leg Txt                                                           *)
(***************************************************************************)

MultiLegTxt5 ==
    [ combOp      : Sample(1),
      legEntryTxt : SampleLists(OneLegEntryTxt5) ]

EncodeMultiLegTxt5(message) ==
    EncodeUIntBE(Len(message.legEntryTxt), 1)
        \o message.combOp
        \o EncodeLegEntryTxt5List(message.legEntryTxt)

DecodeMultiLegTxt5(bytes) ==
    LET noLeg == ReadUIntBE(bytes, 1) IN IF ~noLeg.ok THEN Fail ELSE
    LET combOp == ReadBytes(noLeg.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET legEntryTxt == ReadLegEntryTxt5List(combOp.rest, noLeg.value) IN IF ~legEntryTxt.ok THEN Fail ELSE
    Ok([ combOp      |-> combOp.value,
         legEntryTxt |-> legEntryTxt.value ], legEntryTxt.rest)

ZeroMultiLegTxt5 ==
    [ combOp      |-> [i \in 1 .. 1 |-> 0],
      legEntryTxt |-> << >> ]

(* Multi Leg Txt at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegTxt5 ==
    { ZeroMultiLegTxt5 }
        \cup { [ZeroMultiLegTxt5 EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegTxt5 EXCEPT !.legEntryTxt = one] : one \in SampleLists(OneLegEntryTxt5) }

(***************************************************************************)
(* Sym Flex Product X, selected by Msg Type Ext                            *)
(***************************************************************************)

SymbolNumXCode5 == 1  \* 0x01
SymbolTxtXCode5 == 2  \* 0x02
MultiLegNumCode5 == 3  \* 0x03
MultiLegTxtCode5 == 4  \* 0x04

SymFlexProductX5 ==
    [ tag : {SymbolNumXCode5}, body : SymbolNumX5 ]
        \cup [ tag : {SymbolTxtXCode5}, body : SymbolTxtX5 ]
        \cup [ tag : {MultiLegNumCode5}, body : MultiLegNum5 ]
        \cup [ tag : {MultiLegTxtCode5}, body : MultiLegTxt5 ]

EncodeSymFlexProductX5(message) ==
    CASE message.tag = SymbolNumXCode5 -> EncodeSymbolNumX5(message.body)
      [] message.tag = SymbolTxtXCode5 -> EncodeSymbolTxtX5(message.body)
      [] message.tag = MultiLegNumCode5 -> EncodeMultiLegNum5(message.body)
      [] message.tag = MultiLegTxtCode5 -> EncodeMultiLegTxt5(message.body)

DecodeSymFlexProductX5(tag, bytes) ==
    LET read ==
            CASE tag = SymbolNumXCode5 -> DecodeSymbolNumX5(bytes)
              [] tag = SymbolTxtXCode5 -> DecodeSymbolTxtX5(bytes)
              [] tag = MultiLegNumCode5 -> DecodeMultiLegNum5(bytes)
              [] tag = MultiLegTxtCode5 -> DecodeMultiLegTxt5(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSymFlexProductX5 == [tag |-> SymbolNumXCode5, body |-> ZeroSymbolNumX5]

(* Each Sym Flex Product X in turn, at the values the message it names is checked at *)
CheckedSymFlexProductX5 ==
    { [tag |-> SymbolNumXCode5, body |-> one] : one \in CheckedSymbolNumX5 }
        \cup { [tag |-> SymbolTxtXCode5, body |-> one] : one \in CheckedSymbolTxtX5 }
        \cup { [tag |-> MultiLegNumCode5, body |-> one] : one \in CheckedMultiLegNum5 }
        \cup { [tag |-> MultiLegTxtCode5, body |-> one] : one \in CheckedMultiLegTxt5 }

(***************************************************************************)
(* Flex Price Inquiry Reply Message                                        *)
(***************************************************************************)

FlexPriceInquiryReplyMessage ==
    [ preserve        : Sample(1),
      msgTimeNs       : Sample(4),
      partId          : Sample(1),
      wideStatusCode  : Sample(2),
      orderNo         : Sample(5),
      ordId           : Sample(4),
      fcmId           : Sample(2),
      symFlexProductX : SymFlexProductX5,
      reserved8       : Sample(8) ]

EncodeFlexPriceInquiryReplyMessage(message) ==
    EncodeUIntBE(message.symFlexProductX.tag, 1)
        \o message.preserve
        \o message.msgTimeNs
        \o message.partId
        \o message.wideStatusCode
        \o message.orderNo
        \o message.ordId
        \o message.fcmId
        \o EncodeSymFlexProductX5(message.symFlexProductX)
        \o message.reserved8

DecodeFlexPriceInquiryReplyMessage(bytes) ==
    LET msgTypeExt == ReadUIntBE(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    LET partId == ReadBytes(msgTimeNs.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(partId.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET orderNo == ReadBytes(wideStatusCode.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(ordId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET symFlexProductX == DecodeSymFlexProductX5(msgTypeExt.value, fcmId.rest) IN IF ~symFlexProductX.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(symFlexProductX.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ preserve        |-> preserve.value,
         msgTimeNs       |-> msgTimeNs.value,
         partId          |-> partId.value,
         wideStatusCode  |-> wideStatusCode.value,
         orderNo         |-> orderNo.value,
         ordId           |-> ordId.value,
         fcmId           |-> fcmId.value,
         symFlexProductX |-> symFlexProductX.value,
         reserved8       |-> reserved8.value ], reserved8.rest)

ZeroFlexPriceInquiryReplyMessage ==
    [ preserve        |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs       |-> [i \in 1 .. 4 |-> 0],
      partId          |-> [i \in 1 .. 1 |-> 0],
      wideStatusCode  |-> [i \in 1 .. 2 |-> 0],
      orderNo         |-> [i \in 1 .. 5 |-> 0],
      ordId           |-> [i \in 1 .. 4 |-> 0],
      fcmId           |-> [i \in 1 .. 2 |-> 0],
      symFlexProductX |-> ZeroSymFlexProductX5,
      reserved8       |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Price Inquiry Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexPriceInquiryReplyMessage ==
    { ZeroFlexPriceInquiryReplyMessage }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.msgTimeNs = one] : one \in Sample(4) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX5 }
        \cup { [ZeroFlexPriceInquiryReplyMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr6 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr6(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr6(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr6 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr6 ==
    { ZeroSubHdr6 }
        \cup { [ZeroSubHdr6 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr6 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr6 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Send Flex Group Report Resend Message                                   *)
(***************************************************************************)

SendFlexGroupReportResendMessage ==
    [ subHdr                    : SubHdr6,
      wideStatusCode            : Sample(2),
      partId                    : Sample(1),
      isEof                     : Sample(1),
      fileSize                  : Sample(4),
      dataUint8HdrMsgLength1514 : SampleBytes ]

EncodeSendFlexGroupReportResendMessage(message) ==
    EncodeSubHdr6(message.subHdr)
        \o message.wideStatusCode
        \o message.partId
        \o message.isEof
        \o message.fileSize
        \o message.dataUint8HdrMsgLength1514

DecodeSendFlexGroupReportResendMessage(bytes) ==
    LET subHdr == DecodeSubHdr6(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(subHdr.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET partId == ReadBytes(wideStatusCode.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET isEof == ReadBytes(partId.rest, 1) IN IF ~isEof.ok THEN Fail ELSE
    LET fileSize == ReadBytes(isEof.rest, 4) IN IF ~fileSize.ok THEN Fail ELSE
    LET dataUint8HdrMsgLength1514 == Ok(fileSize.rest, << >>) IN IF ~dataUint8HdrMsgLength1514.ok THEN Fail ELSE
    Ok([ subHdr                    |-> subHdr.value,
         wideStatusCode            |-> wideStatusCode.value,
         partId                    |-> partId.value,
         isEof                     |-> isEof.value,
         fileSize                  |-> fileSize.value,
         dataUint8HdrMsgLength1514 |-> dataUint8HdrMsgLength1514.value ], dataUint8HdrMsgLength1514.rest)

ZeroSendFlexGroupReportResendMessage ==
    [ subHdr                    |-> ZeroSubHdr6,
      wideStatusCode            |-> [i \in 1 .. 2 |-> 0],
      partId                    |-> [i \in 1 .. 1 |-> 0],
      isEof                     |-> [i \in 1 .. 1 |-> 0],
      fileSize                  |-> [i \in 1 .. 4 |-> 0],
      dataUint8HdrMsgLength1514 |-> << >> ]

(* Send Flex Group Report Resend Message at zero, then each field in turn at the values it is checked at *)
CheckedSendFlexGroupReportResendMessage ==
    { ZeroSendFlexGroupReportResendMessage }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr6 }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.isEof = one] : one \in Sample(1) }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.fileSize = one] : one \in Sample(4) }
        \cup { [ZeroSendFlexGroupReportResendMessage EXCEPT !.dataUint8HdrMsgLength1514 = one] : one \in SampleBytes }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr7 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr7(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr7(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr7 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr7 ==
    { ZeroSubHdr7 }
        \cup { [ZeroSubHdr7 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr7 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr7 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Product Definition Message: 13 bytes                               *)
(***************************************************************************)

FlexProductDefinitionMessage ==
    [ subHdr              : SubHdr7,
      securityRequestType : Sample(1),
      securityReqId       : Sample(4),
      wideStatusCode      : Sample(2) ]

EncodeFlexProductDefinitionMessage(message) ==
    EncodeSubHdr7(message.subHdr)
        \o message.securityRequestType
        \o message.securityReqId
        \o message.wideStatusCode

DecodeFlexProductDefinitionMessage(bytes) ==
    LET subHdr == DecodeSubHdr7(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET securityRequestType == ReadBytes(subHdr.rest, 1) IN IF ~securityRequestType.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(securityRequestType.rest, 4) IN IF ~securityReqId.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(securityReqId.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    Ok([ subHdr              |-> subHdr.value,
         securityRequestType |-> securityRequestType.value,
         securityReqId       |-> securityReqId.value,
         wideStatusCode      |-> wideStatusCode.value ], wideStatusCode.rest)

ZeroFlexProductDefinitionMessage ==
    [ subHdr              |-> ZeroSubHdr7,
      securityRequestType |-> [i \in 1 .. 1 |-> 0],
      securityReqId       |-> [i \in 1 .. 4 |-> 0],
      wideStatusCode      |-> [i \in 1 .. 2 |-> 0] ]

(* Flex Product Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexProductDefinitionMessage ==
    { ZeroFlexProductDefinitionMessage }
        \cup { [ZeroFlexProductDefinitionMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr7 }
        \cup { [ZeroFlexProductDefinitionMessage EXCEPT !.securityRequestType = one] : one \in Sample(1) }
        \cup { [ZeroFlexProductDefinitionMessage EXCEPT !.securityReqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexProductDefinitionMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr8 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr8(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr8(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr8 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr8 ==
    { ZeroSubHdr8 }
        \cup { [ZeroSubHdr8 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr8 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr8 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Bulletin Request Message                                           *)
(***************************************************************************)

FlexBulletinRequestMessage ==
    [ subHdr                   : SubHdr8,
      fcmReqId                 : Sample(4),
      bulletinReqId            : Sample(4),
      systemType               : Sample(1),
      dataCharHdrMsgLength1515 : SampleBytes ]

EncodeFlexBulletinRequestMessage(message) ==
    EncodeSubHdr8(message.subHdr)
        \o message.fcmReqId
        \o message.bulletinReqId
        \o message.systemType
        \o message.dataCharHdrMsgLength1515

DecodeFlexBulletinRequestMessage(bytes) ==
    LET subHdr == DecodeSubHdr8(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET fcmReqId == ReadBytes(subHdr.rest, 4) IN IF ~fcmReqId.ok THEN Fail ELSE
    LET bulletinReqId == ReadBytes(fcmReqId.rest, 4) IN IF ~bulletinReqId.ok THEN Fail ELSE
    LET systemType == ReadBytes(bulletinReqId.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET dataCharHdrMsgLength1515 == Ok(systemType.rest, << >>) IN IF ~dataCharHdrMsgLength1515.ok THEN Fail ELSE
    Ok([ subHdr                   |-> subHdr.value,
         fcmReqId                 |-> fcmReqId.value,
         bulletinReqId            |-> bulletinReqId.value,
         systemType               |-> systemType.value,
         dataCharHdrMsgLength1515 |-> dataCharHdrMsgLength1515.value ], dataCharHdrMsgLength1515.rest)

ZeroFlexBulletinRequestMessage ==
    [ subHdr                   |-> ZeroSubHdr8,
      fcmReqId                 |-> [i \in 1 .. 4 |-> 0],
      bulletinReqId            |-> [i \in 1 .. 4 |-> 0],
      systemType               |-> [i \in 1 .. 1 |-> 0],
      dataCharHdrMsgLength1515 |-> << >> ]

(* Flex Bulletin Request Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexBulletinRequestMessage ==
    { ZeroFlexBulletinRequestMessage }
        \cup { [ZeroFlexBulletinRequestMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr8 }
        \cup { [ZeroFlexBulletinRequestMessage EXCEPT !.fcmReqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexBulletinRequestMessage EXCEPT !.bulletinReqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexBulletinRequestMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroFlexBulletinRequestMessage EXCEPT !.dataCharHdrMsgLength1515 = one] : one \in SampleBytes }

(***************************************************************************)
(* Sub Hdr: 6 bytes                                                        *)
(***************************************************************************)

SubHdr9 ==
    [ msgTypeExt : Sample(1),
      preserve   : Sample(1),
      msgTimeNs  : Sample(4) ]

EncodeSubHdr9(message) ==
    message.msgTypeExt
        \o message.preserve
        \o message.msgTimeNs

DecodeSubHdr9(bytes) ==
    LET msgTypeExt == ReadBytes(bytes, 1) IN IF ~msgTypeExt.ok THEN Fail ELSE
    LET preserve == ReadBytes(msgTypeExt.rest, 1) IN IF ~preserve.ok THEN Fail ELSE
    LET msgTimeNs == ReadBytes(preserve.rest, 4) IN IF ~msgTimeNs.ok THEN Fail ELSE
    Ok([ msgTypeExt |-> msgTypeExt.value,
         preserve   |-> preserve.value,
         msgTimeNs  |-> msgTimeNs.value ], msgTimeNs.rest)

ZeroSubHdr9 ==
    [ msgTypeExt |-> [i \in 1 .. 1 |-> 0],
      preserve   |-> [i \in 1 .. 1 |-> 0],
      msgTimeNs  |-> [i \in 1 .. 4 |-> 0] ]

(* Sub Hdr at zero, then each field in turn at the values it is checked at *)
CheckedSubHdr9 ==
    { ZeroSubHdr9 }
        \cup { [ZeroSubHdr9 EXCEPT !.msgTypeExt = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr9 EXCEPT !.preserve = one] : one \in Sample(1) }
        \cup { [ZeroSubHdr9 EXCEPT !.msgTimeNs = one] : one \in Sample(4) }

(***************************************************************************)
(* Bulletin Time Msg Time X: 8 bytes                                       *)
(***************************************************************************)

BulletinTimeMsgTimeX ==
    [ msgTimeXEpochS : Sample(4),
      nanosecond     : Sample(4) ]

EncodeBulletinTimeMsgTimeX(message) ==
    message.msgTimeXEpochS
        \o message.nanosecond

DecodeBulletinTimeMsgTimeX(bytes) ==
    LET msgTimeXEpochS == ReadBytes(bytes, 4) IN IF ~msgTimeXEpochS.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(msgTimeXEpochS.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ msgTimeXEpochS |-> msgTimeXEpochS.value,
         nanosecond     |-> nanosecond.value ], nanosecond.rest)

ZeroBulletinTimeMsgTimeX ==
    [ msgTimeXEpochS |-> [i \in 1 .. 4 |-> 0],
      nanosecond     |-> [i \in 1 .. 4 |-> 0] ]

(* Bulletin Time Msg Time X at zero, then each field in turn at the values it is checked at *)
CheckedBulletinTimeMsgTimeX ==
    { ZeroBulletinTimeMsgTimeX }
        \cup { [ZeroBulletinTimeMsgTimeX EXCEPT !.msgTimeXEpochS = one] : one \in Sample(4) }
        \cup { [ZeroBulletinTimeMsgTimeX EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Bulletin Report Message                                            *)
(***************************************************************************)

FlexBulletinReportMessage ==
    [ subHdr                   : SubHdr9,
      wideStatusCode           : Sample(2),
      fcmReqId                 : Sample(4),
      bulletinSeq              : Sample(4),
      bulletinTimeMsgTimeX     : BulletinTimeMsgTimeX,
      systemType               : Sample(1),
      dataCharHdrMsgLength1525 : SampleBytes ]

EncodeFlexBulletinReportMessage(message) ==
    EncodeSubHdr9(message.subHdr)
        \o message.wideStatusCode
        \o message.fcmReqId
        \o message.bulletinSeq
        \o EncodeBulletinTimeMsgTimeX(message.bulletinTimeMsgTimeX)
        \o message.systemType
        \o message.dataCharHdrMsgLength1525

DecodeFlexBulletinReportMessage(bytes) ==
    LET subHdr == DecodeSubHdr9(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET wideStatusCode == ReadBytes(subHdr.rest, 2) IN IF ~wideStatusCode.ok THEN Fail ELSE
    LET fcmReqId == ReadBytes(wideStatusCode.rest, 4) IN IF ~fcmReqId.ok THEN Fail ELSE
    LET bulletinSeq == ReadBytes(fcmReqId.rest, 4) IN IF ~bulletinSeq.ok THEN Fail ELSE
    LET bulletinTimeMsgTimeX == DecodeBulletinTimeMsgTimeX(bulletinSeq.rest) IN IF ~bulletinTimeMsgTimeX.ok THEN Fail ELSE
    LET systemType == ReadBytes(bulletinTimeMsgTimeX.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET dataCharHdrMsgLength1525 == Ok(systemType.rest, << >>) IN IF ~dataCharHdrMsgLength1525.ok THEN Fail ELSE
    Ok([ subHdr                   |-> subHdr.value,
         wideStatusCode           |-> wideStatusCode.value,
         fcmReqId                 |-> fcmReqId.value,
         bulletinSeq              |-> bulletinSeq.value,
         bulletinTimeMsgTimeX     |-> bulletinTimeMsgTimeX.value,
         systemType               |-> systemType.value,
         dataCharHdrMsgLength1525 |-> dataCharHdrMsgLength1525.value ], dataCharHdrMsgLength1525.rest)

ZeroFlexBulletinReportMessage ==
    [ subHdr                   |-> ZeroSubHdr9,
      wideStatusCode           |-> [i \in 1 .. 2 |-> 0],
      fcmReqId                 |-> [i \in 1 .. 4 |-> 0],
      bulletinSeq              |-> [i \in 1 .. 4 |-> 0],
      bulletinTimeMsgTimeX     |-> ZeroBulletinTimeMsgTimeX,
      systemType               |-> [i \in 1 .. 1 |-> 0],
      dataCharHdrMsgLength1525 |-> << >> ]

(* Flex Bulletin Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexBulletinReportMessage ==
    { ZeroFlexBulletinReportMessage }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr9 }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.wideStatusCode = one] : one \in Sample(2) }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.fcmReqId = one] : one \in Sample(4) }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.bulletinSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.bulletinTimeMsgTimeX = one] : one \in CheckedBulletinTimeMsgTimeX }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroFlexBulletinReportMessage EXCEPT !.dataCharHdrMsgLength1525 = one] : one \in SampleBytes }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

WakeUpCallMessageCode == 10  \* 0x0a
WakeUpCallConfirmedMessageCode == 20  \* 0x14
LogonNoticeMessageCode == 30  \* 0x1e
FinalSequentialNumberNotificationForGroupMessageCode == 230  \* 0xe6
RequestLogonMessageCode == 40  \* 0x28
ResendReportMessageCode == 41  \* 0x29
ResendReportConfirmedMessageCode == 42  \* 0x2a
ActivateApplicationSystemMessageCode == 50  \* 0x32
ActivateApplicationSystemConfirmedMessageCode == 60  \* 0x3c
LogoutMessageCode == 70  \* 0x46
LogoutConfirmedMessageCode == 80  \* 0x50
ConfirmConnectionMessageCode == 104  \* 0x68
ConnectionConfirmedMessageCode == 105  \* 0x69
TradeSessionStatusRequestMessageCode == 111  \* 0x6f
TradeSessionStatusReportMessageCode == 112  \* 0x70
OrderInputMessageCode == 101  \* 0x65
OrderInputLongFormatMessageCode == 131  \* 0x83
OrderStatusReportMessageCode == 102  \* 0x66
OrderStatusReportLongFormatMessageCode == 132  \* 0x84
ErrorReportMessageCode == 103  \* 0x67
PriceInquiryInputMessageCode == 107  \* 0x6b
PriceInquiryInputLongFormatMessageCode == 137  \* 0x89
PriceInquiryReplyMessageCode == 108  \* 0x6c
PriceInquiryReplyLongFormatMessageCode == 138  \* 0x8a
QuoteInputMessageCode == 109  \* 0x6d
QuoteInputLongFormatMessageCode == 139  \* 0x8b
CondensedVersionOrderStatusReportMessageCode == 122  \* 0x7a
ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode == 106  \* 0x6a
BulletinRequestMessageCode == 113  \* 0x71
BulletinReportMessageCode == 114  \* 0x72
SystemSettingMessageCode == 117  \* 0x75
SystemNotificationMessageCode == 118  \* 0x76
FlexOrderInputSingleMessageCode == 201  \* 0xc9
FlexPriceInquiryInputMessageCode == 207  \* 0xcf
FlexQuoteInputMessageCode == 209  \* 0xd1
RequestForSupplementaryFlexGroupReportMessageCode == 240  \* 0xf0
TemporarySuspensionOfSupplementaryFlexGroupReportMessageCode == 242  \* 0xf2
FlexProductDefinitionRequestMessageCode == 219  \* 0xdb
FlexOrderStatusReportMessageCode == 202  \* 0xca
FlexErrorReportMessageCode == 203  \* 0xcb
FlexPriceInquiryReplyMessageCode == 208  \* 0xd0
SendFlexGroupReportResendMessageCode == 241  \* 0xf1
FlexProductDefinitionMessageCode == 220  \* 0xdc
FlexBulletinRequestMessageCode == 213  \* 0xd5
FlexBulletinReportMessageCode == 214  \* 0xd6

Payload ==
    [ tag : {WakeUpCallMessageCode}, body : WakeUpCallMessage ]
        \cup [ tag : {WakeUpCallConfirmedMessageCode}, body : WakeUpCallConfirmedMessage ]
        \cup [ tag : {LogonNoticeMessageCode}, body : LogonNoticeMessage ]
        \cup [ tag : {FinalSequentialNumberNotificationForGroupMessageCode}, body : FinalSequentialNumberNotificationForGroupMessage ]
        \cup [ tag : {RequestLogonMessageCode}, body : RequestLogonMessage ]
        \cup [ tag : {ResendReportMessageCode}, body : ResendReportMessage ]
        \cup [ tag : {ResendReportConfirmedMessageCode}, body : ResendReportConfirmedMessage ]
        \cup [ tag : {ActivateApplicationSystemMessageCode}, body : ActivateApplicationSystemMessage ]
        \cup [ tag : {ActivateApplicationSystemConfirmedMessageCode}, body : ActivateApplicationSystemConfirmedMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutConfirmedMessageCode}, body : LogoutConfirmedMessage ]
        \cup [ tag : {ConfirmConnectionMessageCode}, body : ConfirmConnectionMessage ]
        \cup [ tag : {ConnectionConfirmedMessageCode}, body : ConnectionConfirmedMessage ]
        \cup [ tag : {TradeSessionStatusRequestMessageCode}, body : TradeSessionStatusRequestMessage ]
        \cup [ tag : {TradeSessionStatusReportMessageCode}, body : TradeSessionStatusReportMessage ]
        \cup [ tag : {OrderInputMessageCode}, body : OrderInputMessage ]
        \cup [ tag : {OrderInputLongFormatMessageCode}, body : OrderInputLongFormatMessage ]
        \cup [ tag : {OrderStatusReportMessageCode}, body : OrderStatusReportMessage ]
        \cup [ tag : {OrderStatusReportLongFormatMessageCode}, body : OrderStatusReportLongFormatMessage ]
        \cup [ tag : {ErrorReportMessageCode}, body : ErrorReportMessage ]
        \cup [ tag : {PriceInquiryInputMessageCode}, body : PriceInquiryInputMessage ]
        \cup [ tag : {PriceInquiryInputLongFormatMessageCode}, body : PriceInquiryInputLongFormatMessage ]
        \cup [ tag : {PriceInquiryReplyMessageCode}, body : PriceInquiryReplyMessage ]
        \cup [ tag : {PriceInquiryReplyLongFormatMessageCode}, body : PriceInquiryReplyLongFormatMessage ]
        \cup [ tag : {QuoteInputMessageCode}, body : QuoteInputMessage ]
        \cup [ tag : {QuoteInputLongFormatMessageCode}, body : QuoteInputLongFormatMessage ]
        \cup [ tag : {CondensedVersionOrderStatusReportMessageCode}, body : CondensedVersionOrderStatusReportMessage ]
        \cup [ tag : {ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode}, body : ExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ]
        \cup [ tag : {BulletinRequestMessageCode}, body : BulletinRequestMessage ]
        \cup [ tag : {BulletinReportMessageCode}, body : BulletinReportMessage ]
        \cup [ tag : {SystemSettingMessageCode}, body : SystemSettingMessage ]
        \cup [ tag : {SystemNotificationMessageCode}, body : SystemNotificationMessage ]
        \cup [ tag : {FlexOrderInputSingleMessageCode}, body : FlexOrderInputSingleMessage ]
        \cup [ tag : {FlexPriceInquiryInputMessageCode}, body : FlexPriceInquiryInputMessage ]
        \cup [ tag : {FlexQuoteInputMessageCode}, body : FlexQuoteInputMessage ]
        \cup [ tag : {RequestForSupplementaryFlexGroupReportMessageCode}, body : RequestForSupplementaryFlexGroupReportMessage ]
        \cup [ tag : {TemporarySuspensionOfSupplementaryFlexGroupReportMessageCode}, body : TemporarySuspensionOfSupplementaryFlexGroupReportMessage ]
        \cup [ tag : {FlexProductDefinitionRequestMessageCode}, body : FlexProductDefinitionRequestMessage ]
        \cup [ tag : {FlexOrderStatusReportMessageCode}, body : FlexOrderStatusReportMessage ]
        \cup [ tag : {FlexErrorReportMessageCode}, body : FlexErrorReportMessage ]
        \cup [ tag : {FlexPriceInquiryReplyMessageCode}, body : FlexPriceInquiryReplyMessage ]
        \cup [ tag : {SendFlexGroupReportResendMessageCode}, body : SendFlexGroupReportResendMessage ]
        \cup [ tag : {FlexProductDefinitionMessageCode}, body : FlexProductDefinitionMessage ]
        \cup [ tag : {FlexBulletinRequestMessageCode}, body : FlexBulletinRequestMessage ]
        \cup [ tag : {FlexBulletinReportMessageCode}, body : FlexBulletinReportMessage ]

EncodePayload(message) ==
    CASE message.tag = WakeUpCallMessageCode -> EncodeWakeUpCallMessage(message.body)
      [] message.tag = WakeUpCallConfirmedMessageCode -> EncodeWakeUpCallConfirmedMessage(message.body)
      [] message.tag = LogonNoticeMessageCode -> EncodeLogonNoticeMessage(message.body)
      [] message.tag = FinalSequentialNumberNotificationForGroupMessageCode -> EncodeFinalSequentialNumberNotificationForGroupMessage(message.body)
      [] message.tag = RequestLogonMessageCode -> EncodeRequestLogonMessage(message.body)
      [] message.tag = ResendReportMessageCode -> EncodeResendReportMessage(message.body)
      [] message.tag = ResendReportConfirmedMessageCode -> EncodeResendReportConfirmedMessage(message.body)
      [] message.tag = ActivateApplicationSystemMessageCode -> EncodeActivateApplicationSystemMessage(message.body)
      [] message.tag = ActivateApplicationSystemConfirmedMessageCode -> EncodeActivateApplicationSystemConfirmedMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = LogoutConfirmedMessageCode -> EncodeLogoutConfirmedMessage(message.body)
      [] message.tag = ConfirmConnectionMessageCode -> EncodeConfirmConnectionMessage(message.body)
      [] message.tag = ConnectionConfirmedMessageCode -> EncodeConnectionConfirmedMessage(message.body)
      [] message.tag = TradeSessionStatusRequestMessageCode -> EncodeTradeSessionStatusRequestMessage(message.body)
      [] message.tag = TradeSessionStatusReportMessageCode -> EncodeTradeSessionStatusReportMessage(message.body)
      [] message.tag = OrderInputMessageCode -> EncodeOrderInputMessage(message.body)
      [] message.tag = OrderInputLongFormatMessageCode -> EncodeOrderInputLongFormatMessage(message.body)
      [] message.tag = OrderStatusReportMessageCode -> EncodeOrderStatusReportMessage(message.body)
      [] message.tag = OrderStatusReportLongFormatMessageCode -> EncodeOrderStatusReportLongFormatMessage(message.body)
      [] message.tag = ErrorReportMessageCode -> EncodeErrorReportMessage(message.body)
      [] message.tag = PriceInquiryInputMessageCode -> EncodePriceInquiryInputMessage(message.body)
      [] message.tag = PriceInquiryInputLongFormatMessageCode -> EncodePriceInquiryInputLongFormatMessage(message.body)
      [] message.tag = PriceInquiryReplyMessageCode -> EncodePriceInquiryReplyMessage(message.body)
      [] message.tag = PriceInquiryReplyLongFormatMessageCode -> EncodePriceInquiryReplyLongFormatMessage(message.body)
      [] message.tag = QuoteInputMessageCode -> EncodeQuoteInputMessage(message.body)
      [] message.tag = QuoteInputLongFormatMessageCode -> EncodeQuoteInputLongFormatMessage(message.body)
      [] message.tag = CondensedVersionOrderStatusReportMessageCode -> EncodeCondensedVersionOrderStatusReportMessage(message.body)
      [] message.tag = ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode -> EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message.body)
      [] message.tag = BulletinRequestMessageCode -> EncodeBulletinRequestMessage(message.body)
      [] message.tag = BulletinReportMessageCode -> EncodeBulletinReportMessage(message.body)
      [] message.tag = SystemSettingMessageCode -> EncodeSystemSettingMessage(message.body)
      [] message.tag = SystemNotificationMessageCode -> EncodeSystemNotificationMessage(message.body)
      [] message.tag = FlexOrderInputSingleMessageCode -> EncodeFlexOrderInputSingleMessage(message.body)
      [] message.tag = FlexPriceInquiryInputMessageCode -> EncodeFlexPriceInquiryInputMessage(message.body)
      [] message.tag = FlexQuoteInputMessageCode -> EncodeFlexQuoteInputMessage(message.body)
      [] message.tag = RequestForSupplementaryFlexGroupReportMessageCode -> EncodeRequestForSupplementaryFlexGroupReportMessage(message.body)
      [] message.tag = TemporarySuspensionOfSupplementaryFlexGroupReportMessageCode -> EncodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(message.body)
      [] message.tag = FlexProductDefinitionRequestMessageCode -> EncodeFlexProductDefinitionRequestMessage(message.body)
      [] message.tag = FlexOrderStatusReportMessageCode -> EncodeFlexOrderStatusReportMessage(message.body)
      [] message.tag = FlexErrorReportMessageCode -> EncodeFlexErrorReportMessage(message.body)
      [] message.tag = FlexPriceInquiryReplyMessageCode -> EncodeFlexPriceInquiryReplyMessage(message.body)
      [] message.tag = SendFlexGroupReportResendMessageCode -> EncodeSendFlexGroupReportResendMessage(message.body)
      [] message.tag = FlexProductDefinitionMessageCode -> EncodeFlexProductDefinitionMessage(message.body)
      [] message.tag = FlexBulletinRequestMessageCode -> EncodeFlexBulletinRequestMessage(message.body)
      [] message.tag = FlexBulletinReportMessageCode -> EncodeFlexBulletinReportMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = WakeUpCallMessageCode -> DecodeWakeUpCallMessage(bytes)
              [] tag = WakeUpCallConfirmedMessageCode -> DecodeWakeUpCallConfirmedMessage(bytes)
              [] tag = LogonNoticeMessageCode -> DecodeLogonNoticeMessage(bytes)
              [] tag = FinalSequentialNumberNotificationForGroupMessageCode -> DecodeFinalSequentialNumberNotificationForGroupMessage(bytes)
              [] tag = RequestLogonMessageCode -> DecodeRequestLogonMessage(bytes)
              [] tag = ResendReportMessageCode -> DecodeResendReportMessage(bytes)
              [] tag = ResendReportConfirmedMessageCode -> DecodeResendReportConfirmedMessage(bytes)
              [] tag = ActivateApplicationSystemMessageCode -> DecodeActivateApplicationSystemMessage(bytes)
              [] tag = ActivateApplicationSystemConfirmedMessageCode -> DecodeActivateApplicationSystemConfirmedMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutConfirmedMessageCode -> DecodeLogoutConfirmedMessage(bytes)
              [] tag = ConfirmConnectionMessageCode -> DecodeConfirmConnectionMessage(bytes)
              [] tag = ConnectionConfirmedMessageCode -> DecodeConnectionConfirmedMessage(bytes)
              [] tag = TradeSessionStatusRequestMessageCode -> DecodeTradeSessionStatusRequestMessage(bytes)
              [] tag = TradeSessionStatusReportMessageCode -> DecodeTradeSessionStatusReportMessage(bytes)
              [] tag = OrderInputMessageCode -> DecodeOrderInputMessage(bytes)
              [] tag = OrderInputLongFormatMessageCode -> DecodeOrderInputLongFormatMessage(bytes)
              [] tag = OrderStatusReportMessageCode -> DecodeOrderStatusReportMessage(bytes)
              [] tag = OrderStatusReportLongFormatMessageCode -> DecodeOrderStatusReportLongFormatMessage(bytes)
              [] tag = ErrorReportMessageCode -> DecodeErrorReportMessage(bytes)
              [] tag = PriceInquiryInputMessageCode -> DecodePriceInquiryInputMessage(bytes)
              [] tag = PriceInquiryInputLongFormatMessageCode -> DecodePriceInquiryInputLongFormatMessage(bytes)
              [] tag = PriceInquiryReplyMessageCode -> DecodePriceInquiryReplyMessage(bytes)
              [] tag = PriceInquiryReplyLongFormatMessageCode -> DecodePriceInquiryReplyLongFormatMessage(bytes)
              [] tag = QuoteInputMessageCode -> DecodeQuoteInputMessage(bytes)
              [] tag = QuoteInputLongFormatMessageCode -> DecodeQuoteInputLongFormatMessage(bytes)
              [] tag = CondensedVersionOrderStatusReportMessageCode -> DecodeCondensedVersionOrderStatusReportMessage(bytes)
              [] tag = ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode -> DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(bytes)
              [] tag = BulletinRequestMessageCode -> DecodeBulletinRequestMessage(bytes)
              [] tag = BulletinReportMessageCode -> DecodeBulletinReportMessage(bytes)
              [] tag = SystemSettingMessageCode -> DecodeSystemSettingMessage(bytes)
              [] tag = SystemNotificationMessageCode -> DecodeSystemNotificationMessage(bytes)
              [] tag = FlexOrderInputSingleMessageCode -> DecodeFlexOrderInputSingleMessage(bytes)
              [] tag = FlexPriceInquiryInputMessageCode -> DecodeFlexPriceInquiryInputMessage(bytes)
              [] tag = FlexQuoteInputMessageCode -> DecodeFlexQuoteInputMessage(bytes)
              [] tag = RequestForSupplementaryFlexGroupReportMessageCode -> DecodeRequestForSupplementaryFlexGroupReportMessage(bytes)
              [] tag = TemporarySuspensionOfSupplementaryFlexGroupReportMessageCode -> DecodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(bytes)
              [] tag = FlexProductDefinitionRequestMessageCode -> DecodeFlexProductDefinitionRequestMessage(bytes)
              [] tag = FlexOrderStatusReportMessageCode -> DecodeFlexOrderStatusReportMessage(bytes)
              [] tag = FlexErrorReportMessageCode -> DecodeFlexErrorReportMessage(bytes)
              [] tag = FlexPriceInquiryReplyMessageCode -> DecodeFlexPriceInquiryReplyMessage(bytes)
              [] tag = SendFlexGroupReportResendMessageCode -> DecodeSendFlexGroupReportResendMessage(bytes)
              [] tag = FlexProductDefinitionMessageCode -> DecodeFlexProductDefinitionMessage(bytes)
              [] tag = FlexBulletinRequestMessageCode -> DecodeFlexBulletinRequestMessage(bytes)
              [] tag = FlexBulletinReportMessageCode -> DecodeFlexBulletinReportMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> WakeUpCallMessageCode, body |-> ZeroWakeUpCallMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> WakeUpCallMessageCode, body |-> one] : one \in CheckedWakeUpCallMessage }
        \cup { [tag |-> WakeUpCallConfirmedMessageCode, body |-> one] : one \in CheckedWakeUpCallConfirmedMessage }
        \cup { [tag |-> LogonNoticeMessageCode, body |-> one] : one \in CheckedLogonNoticeMessage }
        \cup { [tag |-> FinalSequentialNumberNotificationForGroupMessageCode, body |-> one] : one \in CheckedFinalSequentialNumberNotificationForGroupMessage }
        \cup { [tag |-> RequestLogonMessageCode, body |-> one] : one \in CheckedRequestLogonMessage }
        \cup { [tag |-> ResendReportMessageCode, body |-> one] : one \in CheckedResendReportMessage }
        \cup { [tag |-> ResendReportConfirmedMessageCode, body |-> one] : one \in CheckedResendReportConfirmedMessage }
        \cup { [tag |-> ActivateApplicationSystemMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemMessage }
        \cup { [tag |-> ActivateApplicationSystemConfirmedMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemConfirmedMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutConfirmedMessageCode, body |-> one] : one \in CheckedLogoutConfirmedMessage }
        \cup { [tag |-> ConfirmConnectionMessageCode, body |-> one] : one \in CheckedConfirmConnectionMessage }
        \cup { [tag |-> ConnectionConfirmedMessageCode, body |-> one] : one \in CheckedConnectionConfirmedMessage }
        \cup { [tag |-> TradeSessionStatusRequestMessageCode, body |-> one] : one \in CheckedTradeSessionStatusRequestMessage }
        \cup { [tag |-> TradeSessionStatusReportMessageCode, body |-> one] : one \in CheckedTradeSessionStatusReportMessage }
        \cup { [tag |-> OrderInputMessageCode, body |-> one] : one \in CheckedOrderInputMessage }
        \cup { [tag |-> OrderInputLongFormatMessageCode, body |-> one] : one \in CheckedOrderInputLongFormatMessage }
        \cup { [tag |-> OrderStatusReportMessageCode, body |-> one] : one \in CheckedOrderStatusReportMessage }
        \cup { [tag |-> OrderStatusReportLongFormatMessageCode, body |-> one] : one \in CheckedOrderStatusReportLongFormatMessage }
        \cup { [tag |-> ErrorReportMessageCode, body |-> one] : one \in CheckedErrorReportMessage }
        \cup { [tag |-> PriceInquiryInputMessageCode, body |-> one] : one \in CheckedPriceInquiryInputMessage }
        \cup { [tag |-> PriceInquiryInputLongFormatMessageCode, body |-> one] : one \in CheckedPriceInquiryInputLongFormatMessage }
        \cup { [tag |-> PriceInquiryReplyMessageCode, body |-> one] : one \in CheckedPriceInquiryReplyMessage }
        \cup { [tag |-> PriceInquiryReplyLongFormatMessageCode, body |-> one] : one \in CheckedPriceInquiryReplyLongFormatMessage }
        \cup { [tag |-> QuoteInputMessageCode, body |-> one] : one \in CheckedQuoteInputMessage }
        \cup { [tag |-> QuoteInputLongFormatMessageCode, body |-> one] : one \in CheckedQuoteInputLongFormatMessage }
        \cup { [tag |-> CondensedVersionOrderStatusReportMessageCode, body |-> one] : one \in CheckedCondensedVersionOrderStatusReportMessage }
        \cup { [tag |-> ExecutionReportIncludingHeadOfficeAndBranchOfficesMessageCode, body |-> one] : one \in CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage }
        \cup { [tag |-> BulletinRequestMessageCode, body |-> one] : one \in CheckedBulletinRequestMessage }
        \cup { [tag |-> BulletinReportMessageCode, body |-> one] : one \in CheckedBulletinReportMessage }
        \cup { [tag |-> SystemSettingMessageCode, body |-> one] : one \in CheckedSystemSettingMessage }
        \cup { [tag |-> SystemNotificationMessageCode, body |-> one] : one \in CheckedSystemNotificationMessage }
        \cup { [tag |-> FlexOrderInputSingleMessageCode, body |-> one] : one \in CheckedFlexOrderInputSingleMessage }
        \cup { [tag |-> FlexPriceInquiryInputMessageCode, body |-> one] : one \in CheckedFlexPriceInquiryInputMessage }
        \cup { [tag |-> FlexQuoteInputMessageCode, body |-> one] : one \in CheckedFlexQuoteInputMessage }
        \cup { [tag |-> RequestForSupplementaryFlexGroupReportMessageCode, body |-> one] : one \in CheckedRequestForSupplementaryFlexGroupReportMessage }
        \cup { [tag |-> TemporarySuspensionOfSupplementaryFlexGroupReportMessageCode, body |-> one] : one \in CheckedTemporarySuspensionOfSupplementaryFlexGroupReportMessage }
        \cup { [tag |-> FlexProductDefinitionRequestMessageCode, body |-> one] : one \in CheckedFlexProductDefinitionRequestMessage }
        \cup { [tag |-> FlexOrderStatusReportMessageCode, body |-> one] : one \in CheckedFlexOrderStatusReportMessage }
        \cup { [tag |-> FlexErrorReportMessageCode, body |-> one] : one \in CheckedFlexErrorReportMessage }
        \cup { [tag |-> FlexPriceInquiryReplyMessageCode, body |-> one] : one \in CheckedFlexPriceInquiryReplyMessage }
        \cup { [tag |-> SendFlexGroupReportResendMessageCode, body |-> one] : one \in CheckedSendFlexGroupReportResendMessage }
        \cup { [tag |-> FlexProductDefinitionMessageCode, body |-> one] : one \in CheckedFlexProductDefinitionMessage }
        \cup { [tag |-> FlexBulletinRequestMessageCode, body |-> one] : one \in CheckedFlexBulletinRequestMessage }
        \cup { [tag |-> FlexBulletinReportMessageCode, body |-> one] : one \in CheckedFlexBulletinReportMessage }

(***************************************************************************)
(* Message Tail: 1 bytes                                                   *)
(***************************************************************************)

MessageTail ==
    [ checkSum : Sample(1) ]

EncodeMessageTail(message) ==
    message.checkSum

DecodeMessageTail(bytes) ==
    LET checkSum == ReadBytes(bytes, 1) IN IF ~checkSum.ok THEN Fail ELSE
    Ok([ checkSum |-> checkSum.value ], checkSum.rest)

ZeroMessageTail ==
    [ checkSum |-> [i \in 1 .. 1 |-> 0] ]

(* Message Tail at zero, then each field in turn at the values it is checked at *)
CheckedMessageTail ==
    { ZeroMessageTail }
        \cup { [ZeroMessageTail EXCEPT !.checkSum = one] : one \in Sample(1) }

(***************************************************************************)
(* Tmp Message, framed by Msg Length                                       *)
(***************************************************************************)

TmpMessage ==
    [ msgSeqNum   : Sample(4),
      headerTime  : HeaderTime,
      fcmId       : Sample(2),
      sessionId   : Sample(2),
      payload     : Payload,
      messageTail : MessageTail ]

EncodeTmpMessageBody(message) ==
    message.msgSeqNum
        \o EncodeHeaderTime(message.headerTime)
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.fcmId
        \o message.sessionId
        \o EncodePayload(message.payload)
        \o EncodeMessageTail(message.messageTail)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeTmpMessage(message) ==
    LET body == EncodeTmpMessageBody(message)
    IN  EncodeUIntBE(Len(body) - 1, 2) \o body

DecodeTmpMessageBody(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET headerTime == DecodeHeaderTime(msgSeqNum.rest) IN IF ~headerTime.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(headerTime.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(messageType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(fcmId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    IF Len(sessionId.rest) < 1 THEN Fail ELSE
    LET kept == SubSeq(sessionId.rest, Len(sessionId.rest), Len(sessionId.rest))
        payload == DecodePayload(messageType.value, SubSeq(sessionId.rest, 1, Len(sessionId.rest) - 1))
    IN  IF ~payload.ok \/ payload.rest # << >> THEN Fail ELSE
    LET messageTail == DecodeMessageTail(kept) IN IF ~messageTail.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         headerTime  |-> headerTime.value,
         fcmId       |-> fcmId.value,
         sessionId   |-> sessionId.value,
         payload     |-> payload.value,
         messageTail |-> messageTail.value ], messageTail.rest)

DecodeTmpMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeTmpMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTmpMessage ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      headerTime  |-> ZeroHeaderTime,
      fcmId       |-> [i \in 1 .. 2 |-> 0],
      sessionId   |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload,
      messageTail |-> ZeroMessageTail ]

(* Tmp Message at zero, then each field in turn at the values it is checked at *)
CheckedTmpMessage ==
    { ZeroTmpMessage }
        \cup { [ZeroTmpMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTmpMessage EXCEPT !.headerTime = one] : one \in CheckedHeaderTime }
        \cup { [ZeroTmpMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroTmpMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroTmpMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroTmpMessage EXCEPT !.messageTail = one] : one \in CheckedMessageTail }

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

(* Every Header Time decodes back to what was encoded, and leaves nothing over *)
RoundTripHeaderTime ==
    \A message \in CheckedHeaderTime :
        LET read == DecodeHeaderTime(EncodeHeaderTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wake Up Call Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWakeUpCallMessage ==
    \A message \in CheckedWakeUpCallMessage :
        LET read == DecodeWakeUpCallMessage(EncodeWakeUpCallMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wake Up Call Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWakeUpCallConfirmedMessage ==
    \A message \in CheckedWakeUpCallConfirmedMessage :
        LET read == DecodeWakeUpCallConfirmedMessage(EncodeWakeUpCallConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Notice Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonNoticeMessage ==
    \A message \in CheckedLogonNoticeMessage :
        LET read == DecodeLogonNoticeMessage(EncodeLogonNoticeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr ==
    \A message \in CheckedSubHdr :
        LET read == DecodeSubHdr(EncodeSubHdr(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Final Sequential Number Notification For Group Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinalSequentialNumberNotificationForGroupMessage ==
    \A message \in CheckedFinalSequentialNumberNotificationForGroupMessage :
        LET read == DecodeFinalSequentialNumberNotificationForGroupMessage(EncodeFinalSequentialNumberNotificationForGroupMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestLogonMessage ==
    \A message \in CheckedRequestLogonMessage :
        LET read == DecodeRequestLogonMessage(EncodeRequestLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendReportMessage ==
    \A message \in CheckedResendReportMessage :
        LET read == DecodeResendReportMessage(EncodeResendReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Resend Report Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResendReportConfirmedMessage ==
    \A message \in CheckedResendReportConfirmedMessage :
        LET read == DecodeResendReportConfirmedMessage(EncodeResendReportConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Activate Application System Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActivateApplicationSystemMessage ==
    \A message \in CheckedActivateApplicationSystemMessage :
        LET read == DecodeActivateApplicationSystemMessage(EncodeActivateApplicationSystemMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Activate Application System Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripActivateApplicationSystemConfirmedMessage ==
    \A message \in CheckedActivateApplicationSystemConfirmedMessage :
        LET read == DecodeActivateApplicationSystemConfirmedMessage(EncodeActivateApplicationSystemConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutConfirmedMessage ==
    \A message \in CheckedLogoutConfirmedMessage :
        LET read == DecodeLogoutConfirmedMessage(EncodeLogoutConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Confirm Connection Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConfirmConnectionMessage ==
    \A message \in CheckedConfirmConnectionMessage :
        LET read == DecodeConfirmConnectionMessage(EncodeConfirmConnectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Connection Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConnectionConfirmedMessage ==
    \A message \in CheckedConnectionConfirmedMessage :
        LET read == DecodeConnectionConfirmedMessage(EncodeConnectionConfirmedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Session Status Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSessionStatusRequestMessage ==
    \A message \in CheckedTradeSessionStatusRequestMessage :
        LET read == DecodeTradeSessionStatusRequestMessage(EncodeTradeSessionStatusRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Session Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSessionStatusReportMessage ==
    \A message \in CheckedTradeSessionStatusReportMessage :
        LET read == DecodeTradeSessionStatusReportMessage(EncodeTradeSessionStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum ==
    \A message \in CheckedSymbolNum :
        LET read == DecodeSymbolNum(EncodeSymbolNum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText ==
    \A message \in CheckedSymbolText :
        LET read == DecodeSymbolText(EncodeSymbolText(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderInputMessage ==
    \A message \in CheckedOrderInputMessage :
        LET read == DecodeOrderInputMessage(EncodeOrderInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolNum ==
    \A message \in CheckedLongSymbolNum :
        LET read == DecodeLongSymbolNum(EncodeLongSymbolNum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolText ==
    \A message \in CheckedLongSymbolText :
        LET read == DecodeLongSymbolText(EncodeLongSymbolText(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Input Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderInputLongFormatMessage ==
    \A message \in CheckedOrderInputLongFormatMessage :
        LET read == DecodeOrderInputLongFormatMessage(EncodeOrderInputLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum2 ==
    \A message \in CheckedSymbolNum2 :
        LET read == DecodeSymbolNum2(EncodeSymbolNum2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText2 ==
    \A message \in CheckedSymbolText2 :
        LET read == DecodeSymbolText2(EncodeSymbolText2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Org Trans Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgTransTimeMsgTime ==
    \A message \in CheckedOrgTransTimeMsgTime :
        LET read == DecodeOrgTransTimeMsgTime(EncodeOrgTransTimeMsgTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgTime ==
    \A message \in CheckedTransactTimeMsgTime :
        LET read == DecodeTransactTimeMsgTime(EncodeTransactTimeMsgTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusReportMessage ==
    \A message \in CheckedOrderStatusReportMessage :
        LET read == DecodeOrderStatusReportMessage(EncodeOrderStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolNum2 ==
    \A message \in CheckedLongSymbolNum2 :
        LET read == DecodeLongSymbolNum2(EncodeLongSymbolNum2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolText2 ==
    \A message \in CheckedLongSymbolText2 :
        LET read == DecodeLongSymbolText2(EncodeLongSymbolText2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Org Trans Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgTransTimeMsgTime2 ==
    \A message \in CheckedOrgTransTimeMsgTime2 :
        LET read == DecodeOrgTransTimeMsgTime2(EncodeOrgTransTimeMsgTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgTime2 ==
    \A message \in CheckedTransactTimeMsgTime2 :
        LET read == DecodeTransactTimeMsgTime2(EncodeTransactTimeMsgTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Report Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusReportLongFormatMessage ==
    \A message \in CheckedOrderStatusReportLongFormatMessage :
        LET read == DecodeOrderStatusReportLongFormatMessage(EncodeOrderStatusReportLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorReportMessage ==
    \A message \in CheckedErrorReportMessage :
        LET read == DecodeErrorReportMessage(EncodeErrorReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum3 ==
    \A message \in CheckedSymbolNum3 :
        LET read == DecodeSymbolNum3(EncodeSymbolNum3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText3 ==
    \A message \in CheckedSymbolText3 :
        LET read == DecodeSymbolText3(EncodeSymbolText3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Inquiry Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceInquiryInputMessage ==
    \A message \in CheckedPriceInquiryInputMessage :
        LET read == DecodePriceInquiryInputMessage(EncodePriceInquiryInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolNum3 ==
    \A message \in CheckedLongSymbolNum3 :
        LET read == DecodeLongSymbolNum3(EncodeLongSymbolNum3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolText3 ==
    \A message \in CheckedLongSymbolText3 :
        LET read == DecodeLongSymbolText3(EncodeLongSymbolText3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Inquiry Input Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceInquiryInputLongFormatMessage ==
    \A message \in CheckedPriceInquiryInputLongFormatMessage :
        LET read == DecodePriceInquiryInputLongFormatMessage(EncodePriceInquiryInputLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum4 ==
    \A message \in CheckedSymbolNum4 :
        LET read == DecodeSymbolNum4(EncodeSymbolNum4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText4 ==
    \A message \in CheckedSymbolText4 :
        LET read == DecodeSymbolText4(EncodeSymbolText4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Inquiry Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceInquiryReplyMessage ==
    \A message \in CheckedPriceInquiryReplyMessage :
        LET read == DecodePriceInquiryReplyMessage(EncodePriceInquiryReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolNum4 ==
    \A message \in CheckedLongSymbolNum4 :
        LET read == DecodeLongSymbolNum4(EncodeLongSymbolNum4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolText4 ==
    \A message \in CheckedLongSymbolText4 :
        LET read == DecodeLongSymbolText4(EncodeLongSymbolText4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Inquiry Reply Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceInquiryReplyLongFormatMessage ==
    \A message \in CheckedPriceInquiryReplyLongFormatMessage :
        LET read == DecodePriceInquiryReplyLongFormatMessage(EncodePriceInquiryReplyLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum5 ==
    \A message \in CheckedSymbolNum5 :
        LET read == DecodeSymbolNum5(EncodeSymbolNum5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText5 ==
    \A message \in CheckedSymbolText5 :
        LET read == DecodeSymbolText5(EncodeSymbolText5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteInputMessage ==
    \A message \in CheckedQuoteInputMessage :
        LET read == DecodeQuoteInputMessage(EncodeQuoteInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolNum5 ==
    \A message \in CheckedLongSymbolNum5 :
        LET read == DecodeLongSymbolNum5(EncodeLongSymbolNum5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripLongSymbolText5 ==
    \A message \in CheckedLongSymbolText5 :
        LET read == DecodeLongSymbolText5(EncodeLongSymbolText5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Input Long Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteInputLongFormatMessage ==
    \A message \in CheckedQuoteInputLongFormatMessage :
        LET read == DecodeQuoteInputLongFormatMessage(EncodeQuoteInputLongFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgTime3 ==
    \A message \in CheckedTransactTimeMsgTime3 :
        LET read == DecodeTransactTimeMsgTime3(EncodeTransactTimeMsgTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Condensed Version Order Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCondensedVersionOrderStatusReportMessage ==
    \A message \in CheckedCondensedVersionOrderStatusReportMessage :
        LET read == DecodeCondensedVersionOrderStatusReportMessage(EncodeCondensedVersionOrderStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNum6 ==
    \A message \in CheckedSymbolNum6 :
        LET read == DecodeSymbolNum6(EncodeSymbolNum6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Text decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolText6 ==
    \A message \in CheckedSymbolText6 :
        LET read == DecodeSymbolText6(EncodeSymbolText6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Org Trans Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgTransTimeMsgTime3 ==
    \A message \in CheckedOrgTransTimeMsgTime3 :
        LET read == DecodeOrgTransTimeMsgTime3(EncodeOrgTransTimeMsgTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgTime4 ==
    \A message \in CheckedTransactTimeMsgTime4 :
        LET read == DecodeTransactTimeMsgTime4(EncodeTransactTimeMsgTime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Including Head Office And Branch Offices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportIncludingHeadOfficeAndBranchOfficesMessage ==
    \A message \in CheckedExecutionReportIncludingHeadOfficeAndBranchOfficesMessage :
        LET read == DecodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(EncodeExecutionReportIncludingHeadOfficeAndBranchOfficesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletin Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinRequestMessage ==
    \A message \in CheckedBulletinRequestMessage :
        LET read == DecodeBulletinRequestMessage(EncodeBulletinRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletin Time Msg Time decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinTimeMsgTime ==
    \A message \in CheckedBulletinTimeMsgTime :
        LET read == DecodeBulletinTimeMsgTime(EncodeBulletinTimeMsgTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletin Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinReportMessage ==
    \A message \in CheckedBulletinReportMessage :
        LET read == DecodeBulletinReportMessage(EncodeBulletinReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Setting Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemSettingMessage ==
    \A message \in CheckedSystemSettingMessage :
        LET read == DecodeSystemSettingMessage(EncodeSystemSettingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemNotificationMessage ==
    \A message \in CheckedSystemNotificationMessage :
        LET read == DecodeSystemNotificationMessage(EncodeSystemNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNumX ==
    \A message \in CheckedSymbolNumX :
        LET read == DecodeSymbolNumX(EncodeSymbolNumX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolTxtX ==
    \A message \in CheckedSymbolTxtX :
        LET read == DecodeSymbolTxtX(EncodeSymbolTxtX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolNumX ==
    \A message \in CheckedLegSymSymbolNumX :
        LET read == DecodeLegSymSymbolNumX(EncodeLegSymSymbolNumX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryNum ==
    \A message \in CheckedLegEntryNum :
        LET read == DecodeLegEntryNum(EncodeLegEntryNum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Num decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegNum ==
    \A message \in CheckedMultiLegNum :
        LET read == DecodeMultiLegNum(EncodeMultiLegNum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolTxtX ==
    \A message \in CheckedLegSymSymbolTxtX :
        LET read == DecodeLegSymSymbolTxtX(EncodeLegSymSymbolTxtX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryTxt ==
    \A message \in CheckedLegEntryTxt :
        LET read == DecodeLegEntryTxt(EncodeLegEntryTxt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegTxt ==
    \A message \in CheckedMultiLegTxt :
        LET read == DecodeMultiLegTxt(EncodeMultiLegTxt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Order Input Single Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexOrderInputSingleMessage ==
    \A message \in CheckedFlexOrderInputSingleMessage :
        LET read == DecodeFlexOrderInputSingleMessage(EncodeFlexOrderInputSingleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNumX2 ==
    \A message \in CheckedSymbolNumX2 :
        LET read == DecodeSymbolNumX2(EncodeSymbolNumX2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolTxtX2 ==
    \A message \in CheckedSymbolTxtX2 :
        LET read == DecodeSymbolTxtX2(EncodeSymbolTxtX2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolNumX2 ==
    \A message \in CheckedLegSymSymbolNumX2 :
        LET read == DecodeLegSymSymbolNumX2(EncodeLegSymSymbolNumX2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryNum2 ==
    \A message \in CheckedLegEntryNum2 :
        LET read == DecodeLegEntryNum2(EncodeLegEntryNum2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Num decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegNum2 ==
    \A message \in CheckedMultiLegNum2 :
        LET read == DecodeMultiLegNum2(EncodeMultiLegNum2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolTxtX2 ==
    \A message \in CheckedLegSymSymbolTxtX2 :
        LET read == DecodeLegSymSymbolTxtX2(EncodeLegSymSymbolTxtX2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryTxt2 ==
    \A message \in CheckedLegEntryTxt2 :
        LET read == DecodeLegEntryTxt2(EncodeLegEntryTxt2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegTxt2 ==
    \A message \in CheckedMultiLegTxt2 :
        LET read == DecodeMultiLegTxt2(EncodeMultiLegTxt2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Price Inquiry Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexPriceInquiryInputMessage ==
    \A message \in CheckedFlexPriceInquiryInputMessage :
        LET read == DecodeFlexPriceInquiryInputMessage(EncodeFlexPriceInquiryInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNumX3 ==
    \A message \in CheckedSymbolNumX3 :
        LET read == DecodeSymbolNumX3(EncodeSymbolNumX3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolTxtX3 ==
    \A message \in CheckedSymbolTxtX3 :
        LET read == DecodeSymbolTxtX3(EncodeSymbolTxtX3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolNumX3 ==
    \A message \in CheckedLegSymSymbolNumX3 :
        LET read == DecodeLegSymSymbolNumX3(EncodeLegSymSymbolNumX3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryNum3 ==
    \A message \in CheckedLegEntryNum3 :
        LET read == DecodeLegEntryNum3(EncodeLegEntryNum3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Num decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegNum3 ==
    \A message \in CheckedMultiLegNum3 :
        LET read == DecodeMultiLegNum3(EncodeMultiLegNum3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolTxtX3 ==
    \A message \in CheckedLegSymSymbolTxtX3 :
        LET read == DecodeLegSymSymbolTxtX3(EncodeLegSymSymbolTxtX3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryTxt3 ==
    \A message \in CheckedLegEntryTxt3 :
        LET read == DecodeLegEntryTxt3(EncodeLegEntryTxt3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegTxt3 ==
    \A message \in CheckedMultiLegTxt3 :
        LET read == DecodeMultiLegTxt3(EncodeMultiLegTxt3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Quote Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexQuoteInputMessage ==
    \A message \in CheckedFlexQuoteInputMessage :
        LET read == DecodeFlexQuoteInputMessage(EncodeFlexQuoteInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr2 ==
    \A message \in CheckedSubHdr2 :
        LET read == DecodeSubHdr2(EncodeSubHdr2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Supplementary Flex Group Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForSupplementaryFlexGroupReportMessage ==
    \A message \in CheckedRequestForSupplementaryFlexGroupReportMessage :
        LET read == DecodeRequestForSupplementaryFlexGroupReportMessage(EncodeRequestForSupplementaryFlexGroupReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr3 ==
    \A message \in CheckedSubHdr3 :
        LET read == DecodeSubHdr3(EncodeSubHdr3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Temporary Suspension Of Supplementary Flex Group Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTemporarySuspensionOfSupplementaryFlexGroupReportMessage ==
    \A message \in CheckedTemporarySuspensionOfSupplementaryFlexGroupReportMessage :
        LET read == DecodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(EncodeTemporarySuspensionOfSupplementaryFlexGroupReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr4 ==
    \A message \in CheckedSubHdr4 :
        LET read == DecodeSubHdr4(EncodeSubHdr4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Product Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexProductDefinitionRequestMessage ==
    \A message \in CheckedFlexProductDefinitionRequestMessage :
        LET read == DecodeFlexProductDefinitionRequestMessage(EncodeFlexProductDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNumX4 ==
    \A message \in CheckedSymbolNumX4 :
        LET read == DecodeSymbolNumX4(EncodeSymbolNumX4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolTxtX4 ==
    \A message \in CheckedSymbolTxtX4 :
        LET read == DecodeSymbolTxtX4(EncodeSymbolTxtX4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolNumX4 ==
    \A message \in CheckedLegSymSymbolNumX4 :
        LET read == DecodeLegSymSymbolNumX4(EncodeLegSymSymbolNumX4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryNum4 ==
    \A message \in CheckedLegEntryNum4 :
        LET read == DecodeLegEntryNum4(EncodeLegEntryNum4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Num decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegNum4 ==
    \A message \in CheckedMultiLegNum4 :
        LET read == DecodeMultiLegNum4(EncodeMultiLegNum4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolTxtX4 ==
    \A message \in CheckedLegSymSymbolTxtX4 :
        LET read == DecodeLegSymSymbolTxtX4(EncodeLegSymSymbolTxtX4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryTxt4 ==
    \A message \in CheckedLegEntryTxt4 :
        LET read == DecodeLegEntryTxt4(EncodeLegEntryTxt4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegTxt4 ==
    \A message \in CheckedMultiLegTxt4 :
        LET read == DecodeMultiLegTxt4(EncodeMultiLegTxt4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Org Trans Time Msg Time X decodes back to what was encoded, and leaves nothing over *)
RoundTripOrgTransTimeMsgTimeX ==
    \A message \in CheckedOrgTransTimeMsgTimeX :
        LET read == DecodeOrgTransTimeMsgTimeX(EncodeOrgTransTimeMsgTimeX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time Msg Time X decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTimeMsgTimeX ==
    \A message \in CheckedTransactTimeMsgTimeX :
        LET read == DecodeTransactTimeMsgTimeX(EncodeTransactTimeMsgTimeX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Order Status Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexOrderStatusReportMessage ==
    \A message \in CheckedFlexOrderStatusReportMessage :
        LET read == DecodeFlexOrderStatusReportMessage(EncodeFlexOrderStatusReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr5 ==
    \A message \in CheckedSubHdr5 :
        LET read == DecodeSubHdr5(EncodeSubHdr5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Error Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexErrorReportMessage ==
    \A message \in CheckedFlexErrorReportMessage :
        LET read == DecodeFlexErrorReportMessage(EncodeFlexErrorReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolNumX5 ==
    \A message \in CheckedSymbolNumX5 :
        LET read == DecodeSymbolNumX5(EncodeSymbolNumX5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolTxtX5 ==
    \A message \in CheckedSymbolTxtX5 :
        LET read == DecodeSymbolTxtX5(EncodeSymbolTxtX5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Num X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolNumX5 ==
    \A message \in CheckedLegSymSymbolNumX5 :
        LET read == DecodeLegSymSymbolNumX5(EncodeLegSymSymbolNumX5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Num decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryNum5 ==
    \A message \in CheckedLegEntryNum5 :
        LET read == DecodeLegEntryNum5(EncodeLegEntryNum5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Num decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegNum5 ==
    \A message \in CheckedMultiLegNum5 :
        LET read == DecodeMultiLegNum5(EncodeMultiLegNum5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Sym Symbol Txt X decodes back to what was encoded, and leaves nothing over *)
RoundTripLegSymSymbolTxtX5 ==
    \A message \in CheckedLegSymSymbolTxtX5 :
        LET read == DecodeLegSymSymbolTxtX5(EncodeLegSymSymbolTxtX5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Entry Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripLegEntryTxt5 ==
    \A message \in CheckedLegEntryTxt5 :
        LET read == DecodeLegEntryTxt5(EncodeLegEntryTxt5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Txt decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegTxt5 ==
    \A message \in CheckedMultiLegTxt5 :
        LET read == DecodeMultiLegTxt5(EncodeMultiLegTxt5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Price Inquiry Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexPriceInquiryReplyMessage ==
    \A message \in CheckedFlexPriceInquiryReplyMessage :
        LET read == DecodeFlexPriceInquiryReplyMessage(EncodeFlexPriceInquiryReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr6 ==
    \A message \in CheckedSubHdr6 :
        LET read == DecodeSubHdr6(EncodeSubHdr6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Send Flex Group Report Resend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSendFlexGroupReportResendMessage ==
    \A message \in CheckedSendFlexGroupReportResendMessage :
        LET read == DecodeSendFlexGroupReportResendMessage(EncodeSendFlexGroupReportResendMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr7 ==
    \A message \in CheckedSubHdr7 :
        LET read == DecodeSubHdr7(EncodeSubHdr7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Product Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexProductDefinitionMessage ==
    \A message \in CheckedFlexProductDefinitionMessage :
        LET read == DecodeFlexProductDefinitionMessage(EncodeFlexProductDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr8 ==
    \A message \in CheckedSubHdr8 :
        LET read == DecodeSubHdr8(EncodeSubHdr8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Bulletin Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexBulletinRequestMessage ==
    \A message \in CheckedFlexBulletinRequestMessage :
        LET read == DecodeFlexBulletinRequestMessage(EncodeFlexBulletinRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sub Hdr decodes back to what was encoded, and leaves nothing over *)
RoundTripSubHdr9 ==
    \A message \in CheckedSubHdr9 :
        LET read == DecodeSubHdr9(EncodeSubHdr9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletin Time Msg Time X decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinTimeMsgTimeX ==
    \A message \in CheckedBulletinTimeMsgTimeX :
        LET read == DecodeBulletinTimeMsgTimeX(EncodeBulletinTimeMsgTimeX(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Bulletin Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexBulletinReportMessage ==
    \A message \in CheckedFlexBulletinReportMessage :
        LET read == DecodeFlexBulletinReportMessage(EncodeFlexBulletinReportMessage(message))
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

(* Every Tmp Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTmpMessage ==
    \A message \in CheckedTmpMessage :
        LET read == DecodeTmpMessage(EncodeTmpMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX ==
    \A message \in CheckedSymSymbolX :
        LET sent == EncodeSymSymbolX(message)
            read == DecodeSymSymbolX(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX ==
    \A message \in CheckedSymLongSymbolX :
        LET sent == EncodeSymLongSymbolX(message)
            read == DecodeSymLongSymbolX(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX2 ==
    \A message \in CheckedSymSymbolX2 :
        LET sent == EncodeSymSymbolX2(message)
            read == DecodeSymSymbolX2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX2 ==
    \A message \in CheckedSymLongSymbolX2 :
        LET sent == EncodeSymLongSymbolX2(message)
            read == DecodeSymLongSymbolX2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX3 ==
    \A message \in CheckedSymSymbolX3 :
        LET sent == EncodeSymSymbolX3(message)
            read == DecodeSymSymbolX3(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX3 ==
    \A message \in CheckedSymLongSymbolX3 :
        LET sent == EncodeSymLongSymbolX3(message)
            read == DecodeSymLongSymbolX3(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX4 ==
    \A message \in CheckedSymSymbolX4 :
        LET sent == EncodeSymSymbolX4(message)
            read == DecodeSymSymbolX4(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX4 ==
    \A message \in CheckedSymLongSymbolX4 :
        LET sent == EncodeSymLongSymbolX4(message)
            read == DecodeSymLongSymbolX4(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX5 ==
    \A message \in CheckedSymSymbolX5 :
        LET sent == EncodeSymSymbolX5(message)
            read == DecodeSymSymbolX5(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX5 ==
    \A message \in CheckedSymLongSymbolX5 :
        LET sent == EncodeSymLongSymbolX5(message)
            read == DecodeSymLongSymbolX5(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Symbol X is selected by the Symbol Type it is written under *)
SelectsSymSymbolX6 ==
    \A message \in CheckedSymSymbolX6 :
        LET sent == EncodeSymSymbolX6(message)
            read == DecodeSymSymbolX6(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX ==
    \A message \in CheckedSymFlexProductX :
        LET sent == EncodeSymFlexProductX(message)
            read == DecodeSymFlexProductX(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX2 ==
    \A message \in CheckedSymFlexProductX2 :
        LET sent == EncodeSymFlexProductX2(message)
            read == DecodeSymFlexProductX2(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX3 ==
    \A message \in CheckedSymFlexProductX3 :
        LET sent == EncodeSymFlexProductX3(message)
            read == DecodeSymFlexProductX3(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX4 ==
    \A message \in CheckedSymFlexProductX4 :
        LET sent == EncodeSymFlexProductX4(message)
            read == DecodeSymFlexProductX4(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX5 ==
    \A message \in CheckedSymFlexProductX5 :
        LET sent == EncodeSymFlexProductX5(message)
            read == DecodeSymFlexProductX5(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesTmpMessage ==
    \A message \in CheckedTmpMessage :
        LET bytes == EncodeTmpMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
