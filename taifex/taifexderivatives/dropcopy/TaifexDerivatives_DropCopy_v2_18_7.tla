---------------- MODULE TaifexDerivatives_DropCopy_v2_18_7 -----------------
(***************************************************************************)
(* Taiwan Futures Exchange Drop Copy Service v2.18.7                       *)
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
    [ statusCodeUint81 : Sample(1),
      startInBoundNum  : Sample(4) ]

EncodeWakeUpCallMessage(message) ==
    message.statusCodeUint81
        \o message.startInBoundNum

DecodeWakeUpCallMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET startInBoundNum == ReadBytes(statusCodeUint81.rest, 4) IN IF ~startInBoundNum.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         startInBoundNum  |-> startInBoundNum.value ], startInBoundNum.rest)

ZeroWakeUpCallMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      startInBoundNum  |-> [i \in 1 .. 4 |-> 0] ]

(* Wake Up Call Message at zero, then each field in turn at the values it is checked at *)
CheckedWakeUpCallMessage ==
    { ZeroWakeUpCallMessage }
        \cup { [ZeroWakeUpCallMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
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
    [ statusCodeUint81 : Sample(1),
      appendNo         : Sample(2),
      endOutBoundNum   : Sample(4),
      systemType       : Sample(1),
      encryptMethod    : Sample(1) ]

EncodeLogonNoticeMessage(message) ==
    message.statusCodeUint81
        \o message.appendNo
        \o message.endOutBoundNum
        \o message.systemType
        \o message.encryptMethod

DecodeLogonNoticeMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET appendNo == ReadBytes(statusCodeUint81.rest, 2) IN IF ~appendNo.ok THEN Fail ELSE
    LET endOutBoundNum == ReadBytes(appendNo.rest, 4) IN IF ~endOutBoundNum.ok THEN Fail ELSE
    LET systemType == ReadBytes(endOutBoundNum.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET encryptMethod == ReadBytes(systemType.rest, 1) IN IF ~encryptMethod.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         appendNo         |-> appendNo.value,
         endOutBoundNum   |-> endOutBoundNum.value,
         systemType       |-> systemType.value,
         encryptMethod    |-> encryptMethod.value ], encryptMethod.rest)

ZeroLogonNoticeMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      appendNo         |-> [i \in 1 .. 2 |-> 0],
      endOutBoundNum   |-> [i \in 1 .. 4 |-> 0],
      systemType       |-> [i \in 1 .. 1 |-> 0],
      encryptMethod    |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Notice Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonNoticeMessage ==
    { ZeroLogonNoticeMessage }
        \cup { [ZeroLogonNoticeMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
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
    [ subHdr            : SubHdr,
      statusCodeUint162 : Sample(2),
      partId            : Sample(1),
      endOutBoundNum    : Sample(4),
      reserved8         : Sample(8) ]

EncodeFinalSequentialNumberNotificationForGroupMessage(message) ==
    EncodeSubHdr(message.subHdr)
        \o message.statusCodeUint162
        \o message.partId
        \o message.endOutBoundNum
        \o message.reserved8

DecodeFinalSequentialNumberNotificationForGroupMessage(bytes) ==
    LET subHdr == DecodeSubHdr(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET statusCodeUint162 == ReadBytes(subHdr.rest, 2) IN IF ~statusCodeUint162.ok THEN Fail ELSE
    LET partId == ReadBytes(statusCodeUint162.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET endOutBoundNum == ReadBytes(partId.rest, 4) IN IF ~endOutBoundNum.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(endOutBoundNum.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ subHdr            |-> subHdr.value,
         statusCodeUint162 |-> statusCodeUint162.value,
         partId            |-> partId.value,
         endOutBoundNum    |-> endOutBoundNum.value,
         reserved8         |-> reserved8.value ], reserved8.rest)

ZeroFinalSequentialNumberNotificationForGroupMessage ==
    [ subHdr            |-> ZeroSubHdr,
      statusCodeUint162 |-> [i \in 1 .. 2 |-> 0],
      partId            |-> [i \in 1 .. 1 |-> 0],
      endOutBoundNum    |-> [i \in 1 .. 4 |-> 0],
      reserved8         |-> [i \in 1 .. 8 |-> 0] ]

(* Final Sequential Number Notification For Group Message at zero, then each field in turn at the values it is checked at *)
CheckedFinalSequentialNumberNotificationForGroupMessage ==
    { ZeroFinalSequentialNumberNotificationForGroupMessage }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.statusCodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.endOutBoundNum = one] : one \in Sample(4) }
        \cup { [ZeroFinalSequentialNumberNotificationForGroupMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Request Logon Message: 15 bytes                                         *)
(***************************************************************************)

RequestLogonMessage ==
    [ statusCodeUint81 : Sample(1),
      appendNo         : Sample(2),
      fcmId            : Sample(2),
      sessionId        : Sample(2),
      systemType       : Sample(1),
      apCode           : Sample(1),
      keyValue         : Sample(1),
      requestStartSeq  : Sample(4),
      cancelOrderSec   : Sample(1) ]

EncodeRequestLogonMessage(message) ==
    message.statusCodeUint81
        \o message.appendNo
        \o message.fcmId
        \o message.sessionId
        \o message.systemType
        \o message.apCode
        \o message.keyValue
        \o message.requestStartSeq
        \o message.cancelOrderSec

DecodeRequestLogonMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET appendNo == ReadBytes(statusCodeUint81.rest, 2) IN IF ~appendNo.ok THEN Fail ELSE
    LET fcmId == ReadBytes(appendNo.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(fcmId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemType == ReadBytes(sessionId.rest, 1) IN IF ~systemType.ok THEN Fail ELSE
    LET apCode == ReadBytes(systemType.rest, 1) IN IF ~apCode.ok THEN Fail ELSE
    LET keyValue == ReadBytes(apCode.rest, 1) IN IF ~keyValue.ok THEN Fail ELSE
    LET requestStartSeq == ReadBytes(keyValue.rest, 4) IN IF ~requestStartSeq.ok THEN Fail ELSE
    LET cancelOrderSec == ReadBytes(requestStartSeq.rest, 1) IN IF ~cancelOrderSec.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         appendNo         |-> appendNo.value,
         fcmId            |-> fcmId.value,
         sessionId        |-> sessionId.value,
         systemType       |-> systemType.value,
         apCode           |-> apCode.value,
         keyValue         |-> keyValue.value,
         requestStartSeq  |-> requestStartSeq.value,
         cancelOrderSec   |-> cancelOrderSec.value ], cancelOrderSec.rest)

ZeroRequestLogonMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      appendNo         |-> [i \in 1 .. 2 |-> 0],
      fcmId            |-> [i \in 1 .. 2 |-> 0],
      sessionId        |-> [i \in 1 .. 2 |-> 0],
      systemType       |-> [i \in 1 .. 1 |-> 0],
      apCode           |-> [i \in 1 .. 1 |-> 0],
      keyValue         |-> [i \in 1 .. 1 |-> 0],
      requestStartSeq  |-> [i \in 1 .. 4 |-> 0],
      cancelOrderSec   |-> [i \in 1 .. 1 |-> 0] ]

(* Request Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestLogonMessage ==
    { ZeroRequestLogonMessage }
        \cup { [ZeroRequestLogonMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.appendNo = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.systemType = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.apCode = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.keyValue = one] : one \in Sample(1) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.requestStartSeq = one] : one \in Sample(4) }
        \cup { [ZeroRequestLogonMessage EXCEPT !.cancelOrderSec = one] : one \in Sample(1) }

(***************************************************************************)
(* Activate Application System Message: 4 bytes                            *)
(***************************************************************************)

ActivateApplicationSystemMessage ==
    [ statusCodeUint81 : Sample(1),
      heartBtInt       : Sample(1),
      maxFlowCtrlCnt   : Sample(2) ]

EncodeActivateApplicationSystemMessage(message) ==
    message.statusCodeUint81
        \o message.heartBtInt
        \o message.maxFlowCtrlCnt

DecodeActivateApplicationSystemMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(statusCodeUint81.rest, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET maxFlowCtrlCnt == ReadBytes(heartBtInt.rest, 2) IN IF ~maxFlowCtrlCnt.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         heartBtInt       |-> heartBtInt.value,
         maxFlowCtrlCnt   |-> maxFlowCtrlCnt.value ], maxFlowCtrlCnt.rest)

ZeroActivateApplicationSystemMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      heartBtInt       |-> [i \in 1 .. 1 |-> 0],
      maxFlowCtrlCnt   |-> [i \in 1 .. 2 |-> 0] ]

(* Activate Application System Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemMessage ==
    { ZeroActivateApplicationSystemMessage }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.heartBtInt = one] : one \in Sample(1) }
        \cup { [ZeroActivateApplicationSystemMessage EXCEPT !.maxFlowCtrlCnt = one] : one \in Sample(2) }

(***************************************************************************)
(* Activate Application System Confirmed Message: 1 bytes                  *)
(***************************************************************************)

ActivateApplicationSystemConfirmedMessage ==
    [ statusCodeUint81 : Sample(1) ]

EncodeActivateApplicationSystemConfirmedMessage(message) ==
    message.statusCodeUint81

DecodeActivateApplicationSystemConfirmedMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value ], statusCodeUint81.rest)

ZeroActivateApplicationSystemConfirmedMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Activate Application System Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedActivateApplicationSystemConfirmedMessage ==
    { ZeroActivateApplicationSystemConfirmedMessage }
        \cup { [ZeroActivateApplicationSystemConfirmedMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Logout Confirmed Message: 1 bytes                                       *)
(***************************************************************************)

LogoutConfirmedMessage ==
    [ statusCodeUint81 : Sample(1) ]

EncodeLogoutConfirmedMessage(message) ==
    message.statusCodeUint81

DecodeLogoutConfirmedMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value ], statusCodeUint81.rest)

ZeroLogoutConfirmedMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Logout Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutConfirmedMessage ==
    { ZeroLogoutConfirmedMessage }
        \cup { [ZeroLogoutConfirmedMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Confirm Connection Message: 1 bytes                                     *)
(***************************************************************************)

ConfirmConnectionMessage ==
    [ statusCodeUint81 : Sample(1) ]

EncodeConfirmConnectionMessage(message) ==
    message.statusCodeUint81

DecodeConfirmConnectionMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value ], statusCodeUint81.rest)

ZeroConfirmConnectionMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Confirm Connection Message at zero, then each field in turn at the values it is checked at *)
CheckedConfirmConnectionMessage ==
    { ZeroConfirmConnectionMessage }
        \cup { [ZeroConfirmConnectionMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Connection Confirmed Message: 1 bytes                                   *)
(***************************************************************************)

ConnectionConfirmedMessage ==
    [ statusCodeUint81 : Sample(1) ]

EncodeConnectionConfirmedMessage(message) ==
    message.statusCodeUint81

DecodeConnectionConfirmedMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value ], statusCodeUint81.rest)

ZeroConnectionConfirmedMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0] ]

(* Connection Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedConnectionConfirmedMessage ==
    { ZeroConnectionConfirmedMessage }
        \cup { [ZeroConnectionConfirmedMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Num: 19 bytes                                                    *)
(***************************************************************************)

SymbolNum ==
    [ pseq1          : Sample(2),
      pseq2          : Sample(2),
      legSideUint822 : Sample(1),
      combOp         : Sample(1),
      reserved13     : Sample(13) ]

EncodeSymbolNum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.legSideUint822
        \o message.combOp
        \o message.reserved13

DecodeSymbolNum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET legSideUint822 == ReadBytes(pseq2.rest, 1) IN IF ~legSideUint822.ok THEN Fail ELSE
    LET combOp == ReadBytes(legSideUint822.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved13 == ReadBytes(combOp.rest, 13) IN IF ~reserved13.ok THEN Fail ELSE
    Ok([ pseq1          |-> pseq1.value,
         pseq2          |-> pseq2.value,
         legSideUint822 |-> legSideUint822.value,
         combOp         |-> combOp.value,
         reserved13     |-> reserved13.value ], reserved13.rest)

ZeroSymbolNum ==
    [ pseq1          |-> [i \in 1 .. 2 |-> 0],
      pseq2          |-> [i \in 1 .. 2 |-> 0],
      legSideUint822 |-> [i \in 1 .. 1 |-> 0],
      combOp         |-> [i \in 1 .. 1 |-> 0],
      reserved13     |-> [i \in 1 .. 13 |-> 0] ]

(* Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedSymbolNum ==
    { ZeroSymbolNum }
        \cup { [ZeroSymbolNum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroSymbolNum EXCEPT !.legSideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroSymbolNum EXCEPT !.reserved13 = one] : one \in Sample(13) }

(***************************************************************************)
(* Symbol Text: 20 bytes                                                   *)
(***************************************************************************)

SymbolText ==
    [ symbolChar2020 : Sample(20) ]

EncodeSymbolText(message) ==
    message.symbolChar2020

DecodeSymbolText(bytes) ==
    LET symbolChar2020 == ReadBytes(bytes, 20) IN IF ~symbolChar2020.ok THEN Fail ELSE
    Ok([ symbolChar2020 |-> symbolChar2020.value ], symbolChar2020.rest)

ZeroSymbolText ==
    [ symbolChar2020 |-> [i \in 1 .. 20 |-> 0] ]

(* Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedSymbolText ==
    { ZeroSymbolText }
        \cup { [ZeroSymbolText EXCEPT !.symbolChar2020 = one] : one \in Sample(20) }

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
(* Org Trans Time Msg Time: 6 bytes                                        *)
(***************************************************************************)

OrgTransTimeMsgTime ==
    [ epochSInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeOrgTransTimeMsgTime(message) ==
    message.epochSInt324
        \o message.ms

DecodeOrgTransTimeMsgTime(bytes) ==
    LET epochSInt324 == ReadBytes(bytes, 4) IN IF ~epochSInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochSInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochSInt324 |-> epochSInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroOrgTransTimeMsgTime ==
    [ epochSInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Org Trans Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTime ==
    { ZeroOrgTransTimeMsgTime }
        \cup { [ZeroOrgTransTimeMsgTime EXCEPT !.epochSInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime ==
    [ epochSInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeTransactTimeMsgTime(message) ==
    message.epochSInt324
        \o message.ms

DecodeTransactTimeMsgTime(bytes) ==
    LET epochSInt324 == ReadBytes(bytes, 4) IN IF ~epochSInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochSInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochSInt324 |-> epochSInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime ==
    [ epochSInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime ==
    { ZeroTransactTimeMsgTime }
        \cup { [ZeroTransactTimeMsgTime EXCEPT !.epochSInt324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Message                                             *)
(***************************************************************************)

OrderStatusReportMessage ==
    [ statusCodeUint81    : Sample(1),
      execType            : Sample(1),
      cmId                : Sample(2),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      symSymbolX          : SymSymbolX,
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
      legSideUint822      : Sample(1),
      legPx               : Sample(4),
      legQtyUint1624      : Sample(2),
      orgTransTimeMsgTime : OrgTransTimeMsgTime,
      transactTimeMsgTime : TransactTimeMsgTime,
      targetId            : Sample(1),
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1) ]

EncodeOrderStatusReportMessage(message) ==
    message.statusCodeUint81
        \o message.execType
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
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o message.legSideUint822
        \o message.legPx
        \o message.legQtyUint1624
        \o EncodeOrgTransTimeMsgTime(message.orgTransTimeMsgTime)
        \o EncodeTransactTimeMsgTime(message.transactTimeMsgTime)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType

DecodeOrderStatusReportMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
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
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET legSideUint822 == ReadBytes(beforeQty.rest, 1) IN IF ~legSideUint822.ok THEN Fail ELSE
    LET legPx == ReadBytes(legSideUint822.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET legQtyUint1624 == ReadBytes(legPx.rest, 2) IN IF ~legQtyUint1624.ok THEN Fail ELSE
    LET orgTransTimeMsgTime == DecodeOrgTransTimeMsgTime(legQtyUint1624.rest) IN IF ~orgTransTimeMsgTime.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime(orgTransTimeMsgTime.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTime.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    Ok([ statusCodeUint81    |-> statusCodeUint81.value,
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
         legSideUint822      |-> legSideUint822.value,
         legPx               |-> legPx.value,
         legQtyUint1624      |-> legQtyUint1624.value,
         orgTransTimeMsgTime |-> orgTransTimeMsgTime.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         targetId            |-> targetId.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value ], protocolType.rest)

ZeroOrderStatusReportMessage ==
    [ statusCodeUint81    |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmId                |-> [i \in 1 .. 2 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      symSymbolX          |-> ZeroSymSymbolX,
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
      legSideUint822      |-> [i \in 1 .. 1 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      legQtyUint1624      |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTime |-> ZeroOrgTransTimeMsgTime,
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime,
      targetId            |-> [i \in 1 .. 1 |-> 0],
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportMessage ==
    { ZeroOrderStatusReportMessage }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.symSymbolX = one] : one \in CheckedSymSymbolX }
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
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legSideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.legQtyUint1624 = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.orgTransTimeMsgTime = one] : one \in CheckedOrgTransTimeMsgTime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.transactTimeMsgTime = one] : one \in CheckedTransactTimeMsgTime }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.uniqId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportMessage EXCEPT !.protocolType = one] : one \in Sample(1) }

(***************************************************************************)
(* Long Symbol Num: 39 bytes                                               *)
(***************************************************************************)

LongSymbolNum ==
    [ pseq1          : Sample(2),
      pseq2          : Sample(2),
      legSideUint822 : Sample(1),
      combOp         : Sample(1),
      reserved33     : Sample(33) ]

EncodeLongSymbolNum(message) ==
    message.pseq1
        \o message.pseq2
        \o message.legSideUint822
        \o message.combOp
        \o message.reserved33

DecodeLongSymbolNum(bytes) ==
    LET pseq1 == ReadBytes(bytes, 2) IN IF ~pseq1.ok THEN Fail ELSE
    LET pseq2 == ReadBytes(pseq1.rest, 2) IN IF ~pseq2.ok THEN Fail ELSE
    LET legSideUint822 == ReadBytes(pseq2.rest, 1) IN IF ~legSideUint822.ok THEN Fail ELSE
    LET combOp == ReadBytes(legSideUint822.rest, 1) IN IF ~combOp.ok THEN Fail ELSE
    LET reserved33 == ReadBytes(combOp.rest, 33) IN IF ~reserved33.ok THEN Fail ELSE
    Ok([ pseq1          |-> pseq1.value,
         pseq2          |-> pseq2.value,
         legSideUint822 |-> legSideUint822.value,
         combOp         |-> combOp.value,
         reserved33     |-> reserved33.value ], reserved33.rest)

ZeroLongSymbolNum ==
    [ pseq1          |-> [i \in 1 .. 2 |-> 0],
      pseq2          |-> [i \in 1 .. 2 |-> 0],
      legSideUint822 |-> [i \in 1 .. 1 |-> 0],
      combOp         |-> [i \in 1 .. 1 |-> 0],
      reserved33     |-> [i \in 1 .. 33 |-> 0] ]

(* Long Symbol Num at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolNum ==
    { ZeroLongSymbolNum }
        \cup { [ZeroLongSymbolNum EXCEPT !.pseq1 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum EXCEPT !.pseq2 = one] : one \in Sample(2) }
        \cup { [ZeroLongSymbolNum EXCEPT !.legSideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum EXCEPT !.combOp = one] : one \in Sample(1) }
        \cup { [ZeroLongSymbolNum EXCEPT !.reserved33 = one] : one \in Sample(33) }

(***************************************************************************)
(* Long Symbol Text: 40 bytes                                              *)
(***************************************************************************)

LongSymbolText ==
    [ symbolChar4040 : Sample(40) ]

EncodeLongSymbolText(message) ==
    message.symbolChar4040

DecodeLongSymbolText(bytes) ==
    LET symbolChar4040 == ReadBytes(bytes, 40) IN IF ~symbolChar4040.ok THEN Fail ELSE
    Ok([ symbolChar4040 |-> symbolChar4040.value ], symbolChar4040.rest)

ZeroLongSymbolText ==
    [ symbolChar4040 |-> [i \in 1 .. 40 |-> 0] ]

(* Long Symbol Text at zero, then each field in turn at the values it is checked at *)
CheckedLongSymbolText ==
    { ZeroLongSymbolText }
        \cup { [ZeroLongSymbolText EXCEPT !.symbolChar4040 = one] : one \in Sample(40) }

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
(* Org Trans Time Msg Time: 6 bytes                                        *)
(***************************************************************************)

OrgTransTimeMsgTime2 ==
    [ epochSInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeOrgTransTimeMsgTime2(message) ==
    message.epochSInt324
        \o message.ms

DecodeOrgTransTimeMsgTime2(bytes) ==
    LET epochSInt324 == ReadBytes(bytes, 4) IN IF ~epochSInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochSInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochSInt324 |-> epochSInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroOrgTransTimeMsgTime2 ==
    [ epochSInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Org Trans Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTime2 ==
    { ZeroOrgTransTimeMsgTime2 }
        \cup { [ZeroOrgTransTimeMsgTime2 EXCEPT !.epochSInt324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Transact Time Msg Time: 6 bytes                                         *)
(***************************************************************************)

TransactTimeMsgTime2 ==
    [ epochSInt324 : Sample(4),
      ms           : Sample(2) ]

EncodeTransactTimeMsgTime2(message) ==
    message.epochSInt324
        \o message.ms

DecodeTransactTimeMsgTime2(bytes) ==
    LET epochSInt324 == ReadBytes(bytes, 4) IN IF ~epochSInt324.ok THEN Fail ELSE
    LET ms == ReadBytes(epochSInt324.rest, 2) IN IF ~ms.ok THEN Fail ELSE
    Ok([ epochSInt324 |-> epochSInt324.value,
         ms           |-> ms.value ], ms.rest)

ZeroTransactTimeMsgTime2 ==
    [ epochSInt324 |-> [i \in 1 .. 4 |-> 0],
      ms           |-> [i \in 1 .. 2 |-> 0] ]

(* Transact Time Msg Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTime2 ==
    { ZeroTransactTimeMsgTime2 }
        \cup { [ZeroTransactTimeMsgTime2 EXCEPT !.epochSInt324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTime2 EXCEPT !.ms = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Status Report Long Format Message                                 *)
(***************************************************************************)

OrderStatusReportLongFormatMessage ==
    [ statusCodeUint81    : Sample(1),
      execType            : Sample(1),
      cmId                : Sample(2),
      fcmId               : Sample(2),
      orderNo             : Sample(5),
      ordId               : Sample(4),
      userDefine          : Sample(8),
      symLongSymbolX      : SymLongSymbolX,
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
      legSideUint822      : Sample(1),
      legPx               : Sample(4),
      legQtyUint1624      : Sample(2),
      orgTransTimeMsgTime : OrgTransTimeMsgTime2,
      transactTimeMsgTime : TransactTimeMsgTime2,
      targetId            : Sample(1),
      uniqId              : Sample(4),
      rptSeq              : Sample(4),
      protocolType        : Sample(1) ]

EncodeOrderStatusReportLongFormatMessage(message) ==
    message.statusCodeUint81
        \o message.execType
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
        \o message.lastPx
        \o message.lastQty
        \o message.pxSubtotal
        \o message.cumQty
        \o message.leavesQty
        \o message.beforeQty
        \o message.legSideUint822
        \o message.legPx
        \o message.legQtyUint1624
        \o EncodeOrgTransTimeMsgTime2(message.orgTransTimeMsgTime)
        \o EncodeTransactTimeMsgTime2(message.transactTimeMsgTime)
        \o message.targetId
        \o message.uniqId
        \o message.rptSeq
        \o message.protocolType

DecodeOrderStatusReportLongFormatMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
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
    LET lastPx == ReadBytes(positionEffect.rest, 4) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 2) IN IF ~lastQty.ok THEN Fail ELSE
    LET pxSubtotal == ReadBytes(lastQty.rest, 8) IN IF ~pxSubtotal.ok THEN Fail ELSE
    LET cumQty == ReadBytes(pxSubtotal.rest, 2) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 2) IN IF ~leavesQty.ok THEN Fail ELSE
    LET beforeQty == ReadBytes(leavesQty.rest, 2) IN IF ~beforeQty.ok THEN Fail ELSE
    LET legSideUint822 == ReadBytes(beforeQty.rest, 1) IN IF ~legSideUint822.ok THEN Fail ELSE
    LET legPx == ReadBytes(legSideUint822.rest, 4) IN IF ~legPx.ok THEN Fail ELSE
    LET legQtyUint1624 == ReadBytes(legPx.rest, 2) IN IF ~legQtyUint1624.ok THEN Fail ELSE
    LET orgTransTimeMsgTime == DecodeOrgTransTimeMsgTime2(legQtyUint1624.rest) IN IF ~orgTransTimeMsgTime.ok THEN Fail ELSE
    LET transactTimeMsgTime == DecodeTransactTimeMsgTime2(orgTransTimeMsgTime.rest) IN IF ~transactTimeMsgTime.ok THEN Fail ELSE
    LET targetId == ReadBytes(transactTimeMsgTime.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET uniqId == ReadBytes(targetId.rest, 4) IN IF ~uniqId.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(uniqId.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET protocolType == ReadBytes(rptSeq.rest, 1) IN IF ~protocolType.ok THEN Fail ELSE
    Ok([ statusCodeUint81    |-> statusCodeUint81.value,
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
         legSideUint822      |-> legSideUint822.value,
         legPx               |-> legPx.value,
         legQtyUint1624      |-> legQtyUint1624.value,
         orgTransTimeMsgTime |-> orgTransTimeMsgTime.value,
         transactTimeMsgTime |-> transactTimeMsgTime.value,
         targetId            |-> targetId.value,
         uniqId              |-> uniqId.value,
         rptSeq              |-> rptSeq.value,
         protocolType        |-> protocolType.value ], protocolType.rest)

ZeroOrderStatusReportLongFormatMessage ==
    [ statusCodeUint81    |-> [i \in 1 .. 1 |-> 0],
      execType            |-> [i \in 1 .. 1 |-> 0],
      cmId                |-> [i \in 1 .. 2 |-> 0],
      fcmId               |-> [i \in 1 .. 2 |-> 0],
      orderNo             |-> [i \in 1 .. 5 |-> 0],
      ordId               |-> [i \in 1 .. 4 |-> 0],
      userDefine          |-> [i \in 1 .. 8 |-> 0],
      symLongSymbolX      |-> ZeroSymLongSymbolX,
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
      legSideUint822      |-> [i \in 1 .. 1 |-> 0],
      legPx               |-> [i \in 1 .. 4 |-> 0],
      legQtyUint1624      |-> [i \in 1 .. 2 |-> 0],
      orgTransTimeMsgTime |-> ZeroOrgTransTimeMsgTime2,
      transactTimeMsgTime |-> ZeroTransactTimeMsgTime2,
      targetId            |-> [i \in 1 .. 1 |-> 0],
      uniqId              |-> [i \in 1 .. 4 |-> 0],
      rptSeq              |-> [i \in 1 .. 4 |-> 0],
      protocolType        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Status Report Long Format Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusReportLongFormatMessage ==
    { ZeroOrderStatusReportLongFormatMessage }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.symLongSymbolX = one] : one \in CheckedSymLongSymbolX }
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
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legSideUint822 = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legPx = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusReportLongFormatMessage EXCEPT !.legQtyUint1624 = one] : one \in Sample(2) }
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
    [ statusCodeUint81 : Sample(1),
      execType         : Sample(1),
      fcmId            : Sample(2),
      orderNo          : Sample(5),
      ordId            : Sample(4),
      userDefine       : Sample(8),
      rptSeq           : Sample(4),
      side             : Sample(1) ]

EncodeErrorReportMessage(message) ==
    message.statusCodeUint81
        \o message.execType
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o message.rptSeq
        \o message.side

DecodeErrorReportMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCodeUint81.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(execType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(userDefine.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET side == ReadBytes(rptSeq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         execType         |-> execType.value,
         fcmId            |-> fcmId.value,
         orderNo          |-> orderNo.value,
         ordId            |-> ordId.value,
         userDefine       |-> userDefine.value,
         rptSeq           |-> rptSeq.value,
         side             |-> side.value ], side.rest)

ZeroErrorReportMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      execType         |-> [i \in 1 .. 1 |-> 0],
      fcmId            |-> [i \in 1 .. 2 |-> 0],
      orderNo          |-> [i \in 1 .. 5 |-> 0],
      ordId            |-> [i \in 1 .. 4 |-> 0],
      userDefine       |-> [i \in 1 .. 8 |-> 0],
      rptSeq           |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0] ]

(* Error Report Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorReportMessage ==
    { ZeroErrorReportMessage }
        \cup { [ZeroErrorReportMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroErrorReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroErrorReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroErrorReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroErrorReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroErrorReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroErrorReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroErrorReportMessage EXCEPT !.side = one] : one \in Sample(1) }

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
      legSideUint81    : Sample(1),
      legQtyUint162    : Sample(2) ]

EncodeLegEntryNum(message) ==
    EncodeLegSymSymbolNumX(message.legSymSymbolNumX)
        \o message.legSideUint81
        \o message.legQtyUint162

DecodeLegEntryNum(bytes) ==
    LET legSymSymbolNumX == DecodeLegSymSymbolNumX(bytes) IN IF ~legSymSymbolNumX.ok THEN Fail ELSE
    LET legSideUint81 == ReadBytes(legSymSymbolNumX.rest, 1) IN IF ~legSideUint81.ok THEN Fail ELSE
    LET legQtyUint162 == ReadBytes(legSideUint81.rest, 2) IN IF ~legQtyUint162.ok THEN Fail ELSE
    Ok([ legSymSymbolNumX |-> legSymSymbolNumX.value,
         legSideUint81    |-> legSideUint81.value,
         legQtyUint162    |-> legQtyUint162.value ], legQtyUint162.rest)

ZeroLegEntryNum ==
    [ legSymSymbolNumX |-> ZeroLegSymSymbolNumX,
      legSideUint81    |-> [i \in 1 .. 1 |-> 0],
      legQtyUint162    |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Num at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryNum ==
    { ZeroLegEntryNum }
        \cup { [ZeroLegEntryNum EXCEPT !.legSymSymbolNumX = one] : one \in CheckedLegSymSymbolNumX }
        \cup { [ZeroLegEntryNum EXCEPT !.legSideUint81 = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryNum EXCEPT !.legQtyUint162 = one] : one \in Sample(2) }

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
      legSideUint81    : Sample(1),
      legQtyUint162    : Sample(2) ]

EncodeLegEntryTxt(message) ==
    EncodeLegSymSymbolTxtX(message.legSymSymbolTxtX)
        \o message.legSideUint81
        \o message.legQtyUint162

DecodeLegEntryTxt(bytes) ==
    LET legSymSymbolTxtX == DecodeLegSymSymbolTxtX(bytes) IN IF ~legSymSymbolTxtX.ok THEN Fail ELSE
    LET legSideUint81 == ReadBytes(legSymSymbolTxtX.rest, 1) IN IF ~legSideUint81.ok THEN Fail ELSE
    LET legQtyUint162 == ReadBytes(legSideUint81.rest, 2) IN IF ~legQtyUint162.ok THEN Fail ELSE
    Ok([ legSymSymbolTxtX |-> legSymSymbolTxtX.value,
         legSideUint81    |-> legSideUint81.value,
         legQtyUint162    |-> legQtyUint162.value ], legQtyUint162.rest)

ZeroLegEntryTxt ==
    [ legSymSymbolTxtX |-> ZeroLegSymSymbolTxtX,
      legSideUint81    |-> [i \in 1 .. 1 |-> 0],
      legQtyUint162    |-> [i \in 1 .. 2 |-> 0] ]

(* Leg Entry Txt at zero, then each field in turn at the values it is checked at *)
CheckedLegEntryTxt ==
    { ZeroLegEntryTxt }
        \cup { [ZeroLegEntryTxt EXCEPT !.legSymSymbolTxtX = one] : one \in CheckedLegSymSymbolTxtX }
        \cup { [ZeroLegEntryTxt EXCEPT !.legSideUint81 = one] : one \in Sample(1) }
        \cup { [ZeroLegEntryTxt EXCEPT !.legQtyUint162 = one] : one \in Sample(2) }

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
(* Org Trans Time Msg Time X: 8 bytes                                      *)
(***************************************************************************)

OrgTransTimeMsgTimeX ==
    [ epochSUint324 : Sample(4),
      nanosecond    : Sample(4) ]

EncodeOrgTransTimeMsgTimeX(message) ==
    message.epochSUint324
        \o message.nanosecond

DecodeOrgTransTimeMsgTimeX(bytes) ==
    LET epochSUint324 == ReadBytes(bytes, 4) IN IF ~epochSUint324.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(epochSUint324.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ epochSUint324 |-> epochSUint324.value,
         nanosecond    |-> nanosecond.value ], nanosecond.rest)

ZeroOrgTransTimeMsgTimeX ==
    [ epochSUint324 |-> [i \in 1 .. 4 |-> 0],
      nanosecond    |-> [i \in 1 .. 4 |-> 0] ]

(* Org Trans Time Msg Time X at zero, then each field in turn at the values it is checked at *)
CheckedOrgTransTimeMsgTimeX ==
    { ZeroOrgTransTimeMsgTimeX }
        \cup { [ZeroOrgTransTimeMsgTimeX EXCEPT !.epochSUint324 = one] : one \in Sample(4) }
        \cup { [ZeroOrgTransTimeMsgTimeX EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Transact Time Msg Time X: 8 bytes                                       *)
(***************************************************************************)

TransactTimeMsgTimeX ==
    [ epochSUint324 : Sample(4),
      nanosecond    : Sample(4) ]

EncodeTransactTimeMsgTimeX(message) ==
    message.epochSUint324
        \o message.nanosecond

DecodeTransactTimeMsgTimeX(bytes) ==
    LET epochSUint324 == ReadBytes(bytes, 4) IN IF ~epochSUint324.ok THEN Fail ELSE
    LET nanosecond == ReadBytes(epochSUint324.rest, 4) IN IF ~nanosecond.ok THEN Fail ELSE
    Ok([ epochSUint324 |-> epochSUint324.value,
         nanosecond    |-> nanosecond.value ], nanosecond.rest)

ZeroTransactTimeMsgTimeX ==
    [ epochSUint324 |-> [i \in 1 .. 4 |-> 0],
      nanosecond    |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time Msg Time X at zero, then each field in turn at the values it is checked at *)
CheckedTransactTimeMsgTimeX ==
    { ZeroTransactTimeMsgTimeX }
        \cup { [ZeroTransactTimeMsgTimeX EXCEPT !.epochSUint324 = one] : one \in Sample(4) }
        \cup { [ZeroTransactTimeMsgTimeX EXCEPT !.nanosecond = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Order Status Report Message                                        *)
(***************************************************************************)

FlexOrderStatusReportMessage ==
    [ preserve             : Sample(1),
      msgTimeNs            : Sample(4),
      partId               : Sample(1),
      noLeg                : Sample(1),
      statusCodeUint162    : Sample(2),
      execType             : Sample(1),
      cmId                 : Sample(2),
      fcmId                : Sample(2),
      orderNo              : Sample(5),
      ordId                : Sample(4),
      userDefine           : Sample(8),
      symFlexProductX      : SymFlexProductX,
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
        \o message.statusCodeUint162
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
    LET statusCodeUint162 == ReadBytes(noLeg.rest, 2) IN IF ~statusCodeUint162.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCodeUint162.rest, 1) IN IF ~execType.ok THEN Fail ELSE
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
         statusCodeUint162    |-> statusCodeUint162.value,
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
      statusCodeUint162    |-> [i \in 1 .. 2 |-> 0],
      execType             |-> [i \in 1 .. 1 |-> 0],
      cmId                 |-> [i \in 1 .. 2 |-> 0],
      fcmId                |-> [i \in 1 .. 2 |-> 0],
      orderNo              |-> [i \in 1 .. 5 |-> 0],
      ordId                |-> [i \in 1 .. 4 |-> 0],
      userDefine           |-> [i \in 1 .. 8 |-> 0],
      symFlexProductX      |-> ZeroSymFlexProductX,
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
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.statusCodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.cmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexOrderStatusReportMessage EXCEPT !.symFlexProductX = one] : one \in CheckedSymFlexProductX }
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
(* Flex Error Report Message: 47 bytes                                     *)
(***************************************************************************)

FlexErrorReportMessage ==
    [ subHdr            : SubHdr2,
      partId            : Sample(1),
      oriMessageType    : Sample(1),
      statusCodeUint162 : Sample(2),
      execType          : Sample(1),
      fcmId             : Sample(2),
      orderNo           : Sample(5),
      ordId             : Sample(4),
      userDefine        : Sample(8),
      rptSeq            : Sample(4),
      side              : Sample(1),
      reserved12        : Sample(12) ]

EncodeFlexErrorReportMessage(message) ==
    EncodeSubHdr2(message.subHdr)
        \o message.partId
        \o message.oriMessageType
        \o message.statusCodeUint162
        \o message.execType
        \o message.fcmId
        \o message.orderNo
        \o message.ordId
        \o message.userDefine
        \o message.rptSeq
        \o message.side
        \o message.reserved12

DecodeFlexErrorReportMessage(bytes) ==
    LET subHdr == DecodeSubHdr2(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET oriMessageType == ReadBytes(partId.rest, 1) IN IF ~oriMessageType.ok THEN Fail ELSE
    LET statusCodeUint162 == ReadBytes(oriMessageType.rest, 2) IN IF ~statusCodeUint162.ok THEN Fail ELSE
    LET execType == ReadBytes(statusCodeUint162.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET fcmId == ReadBytes(execType.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET orderNo == ReadBytes(fcmId.rest, 5) IN IF ~orderNo.ok THEN Fail ELSE
    LET ordId == ReadBytes(orderNo.rest, 4) IN IF ~ordId.ok THEN Fail ELSE
    LET userDefine == ReadBytes(ordId.rest, 8) IN IF ~userDefine.ok THEN Fail ELSE
    LET rptSeq == ReadBytes(userDefine.rest, 4) IN IF ~rptSeq.ok THEN Fail ELSE
    LET side == ReadBytes(rptSeq.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(side.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ subHdr            |-> subHdr.value,
         partId            |-> partId.value,
         oriMessageType    |-> oriMessageType.value,
         statusCodeUint162 |-> statusCodeUint162.value,
         execType          |-> execType.value,
         fcmId             |-> fcmId.value,
         orderNo           |-> orderNo.value,
         ordId             |-> ordId.value,
         userDefine        |-> userDefine.value,
         rptSeq            |-> rptSeq.value,
         side              |-> side.value,
         reserved12        |-> reserved12.value ], reserved12.rest)

ZeroFlexErrorReportMessage ==
    [ subHdr            |-> ZeroSubHdr2,
      partId            |-> [i \in 1 .. 1 |-> 0],
      oriMessageType    |-> [i \in 1 .. 1 |-> 0],
      statusCodeUint162 |-> [i \in 1 .. 2 |-> 0],
      execType          |-> [i \in 1 .. 1 |-> 0],
      fcmId             |-> [i \in 1 .. 2 |-> 0],
      orderNo           |-> [i \in 1 .. 5 |-> 0],
      ordId             |-> [i \in 1 .. 4 |-> 0],
      userDefine        |-> [i \in 1 .. 8 |-> 0],
      rptSeq            |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      reserved12        |-> [i \in 1 .. 12 |-> 0] ]

(* Flex Error Report Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexErrorReportMessage ==
    { ZeroFlexErrorReportMessage }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr2 }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.oriMessageType = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.statusCodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.orderNo = one] : one \in Sample(5) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.ordId = one] : one \in Sample(4) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.userDefine = one] : one \in Sample(8) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.rptSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFlexErrorReportMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Drop Copy Initiate Operation Message: 7 bytes                           *)
(***************************************************************************)

DropCopyInitiateOperationMessage ==
    [ fcmId    : Sample(2),
      targetId : Sample(1),
      reqCmSeq : Sample(4) ]

EncodeDropCopyInitiateOperationMessage(message) ==
    message.fcmId
        \o message.targetId
        \o message.reqCmSeq

DecodeDropCopyInitiateOperationMessage(bytes) ==
    LET fcmId == ReadBytes(bytes, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET targetId == ReadBytes(fcmId.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET reqCmSeq == ReadBytes(targetId.rest, 4) IN IF ~reqCmSeq.ok THEN Fail ELSE
    Ok([ fcmId    |-> fcmId.value,
         targetId |-> targetId.value,
         reqCmSeq |-> reqCmSeq.value ], reqCmSeq.rest)

ZeroDropCopyInitiateOperationMessage ==
    [ fcmId    |-> [i \in 1 .. 2 |-> 0],
      targetId |-> [i \in 1 .. 1 |-> 0],
      reqCmSeq |-> [i \in 1 .. 4 |-> 0] ]

(* Drop Copy Initiate Operation Message at zero, then each field in turn at the values it is checked at *)
CheckedDropCopyInitiateOperationMessage ==
    { ZeroDropCopyInitiateOperationMessage }
        \cup { [ZeroDropCopyInitiateOperationMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroDropCopyInitiateOperationMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroDropCopyInitiateOperationMessage EXCEPT !.reqCmSeq = one] : one \in Sample(4) }

(***************************************************************************)
(* Drop Copy Initiate Operation Confirmed Message: 8 bytes                 *)
(***************************************************************************)

DropCopyInitiateOperationConfirmedMessage ==
    [ statusCodeUint81 : Sample(1),
      fcmId            : Sample(2),
      targetId         : Sample(1),
      reqCmSeq         : Sample(4) ]

EncodeDropCopyInitiateOperationConfirmedMessage(message) ==
    message.statusCodeUint81
        \o message.fcmId
        \o message.targetId
        \o message.reqCmSeq

DecodeDropCopyInitiateOperationConfirmedMessage(bytes) ==
    LET statusCodeUint81 == ReadBytes(bytes, 1) IN IF ~statusCodeUint81.ok THEN Fail ELSE
    LET fcmId == ReadBytes(statusCodeUint81.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET targetId == ReadBytes(fcmId.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET reqCmSeq == ReadBytes(targetId.rest, 4) IN IF ~reqCmSeq.ok THEN Fail ELSE
    Ok([ statusCodeUint81 |-> statusCodeUint81.value,
         fcmId            |-> fcmId.value,
         targetId         |-> targetId.value,
         reqCmSeq         |-> reqCmSeq.value ], reqCmSeq.rest)

ZeroDropCopyInitiateOperationConfirmedMessage ==
    [ statusCodeUint81 |-> [i \in 1 .. 1 |-> 0],
      fcmId            |-> [i \in 1 .. 2 |-> 0],
      targetId         |-> [i \in 1 .. 1 |-> 0],
      reqCmSeq         |-> [i \in 1 .. 4 |-> 0] ]

(* Drop Copy Initiate Operation Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedDropCopyInitiateOperationConfirmedMessage ==
    { ZeroDropCopyInitiateOperationConfirmedMessage }
        \cup { [ZeroDropCopyInitiateOperationConfirmedMessage EXCEPT !.statusCodeUint81 = one] : one \in Sample(1) }
        \cup { [ZeroDropCopyInitiateOperationConfirmedMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroDropCopyInitiateOperationConfirmedMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroDropCopyInitiateOperationConfirmedMessage EXCEPT !.reqCmSeq = one] : one \in Sample(4) }

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
(* Flex Drop Copy Initiate Operation Message: 14 bytes                     *)
(***************************************************************************)

FlexDropCopyInitiateOperationMessage ==
    [ subHdr   : SubHdr3,
      partId   : Sample(1),
      fcmId    : Sample(2),
      targetId : Sample(1),
      reqCmSeq : Sample(4) ]

EncodeFlexDropCopyInitiateOperationMessage(message) ==
    EncodeSubHdr3(message.subHdr)
        \o message.partId
        \o message.fcmId
        \o message.targetId
        \o message.reqCmSeq

DecodeFlexDropCopyInitiateOperationMessage(bytes) ==
    LET subHdr == DecodeSubHdr3(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET fcmId == ReadBytes(partId.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET targetId == ReadBytes(fcmId.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET reqCmSeq == ReadBytes(targetId.rest, 4) IN IF ~reqCmSeq.ok THEN Fail ELSE
    Ok([ subHdr   |-> subHdr.value,
         partId   |-> partId.value,
         fcmId    |-> fcmId.value,
         targetId |-> targetId.value,
         reqCmSeq |-> reqCmSeq.value ], reqCmSeq.rest)

ZeroFlexDropCopyInitiateOperationMessage ==
    [ subHdr   |-> ZeroSubHdr3,
      partId   |-> [i \in 1 .. 1 |-> 0],
      fcmId    |-> [i \in 1 .. 2 |-> 0],
      targetId |-> [i \in 1 .. 1 |-> 0],
      reqCmSeq |-> [i \in 1 .. 4 |-> 0] ]

(* Flex Drop Copy Initiate Operation Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexDropCopyInitiateOperationMessage ==
    { ZeroFlexDropCopyInitiateOperationMessage }
        \cup { [ZeroFlexDropCopyInitiateOperationMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr3 }
        \cup { [ZeroFlexDropCopyInitiateOperationMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexDropCopyInitiateOperationMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexDropCopyInitiateOperationMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroFlexDropCopyInitiateOperationMessage EXCEPT !.reqCmSeq = one] : one \in Sample(4) }

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
(* Flex Drop Copy Initiate Operation Confirmed Message: 32 bytes           *)
(***************************************************************************)

FlexDropCopyInitiateOperationConfirmedMessage ==
    [ subHdr            : SubHdr4,
      partId            : Sample(1),
      statusCodeUint162 : Sample(2),
      fcmId             : Sample(2),
      targetId          : Sample(1),
      reqCmSeq          : Sample(4),
      reserved16        : Sample(16) ]

EncodeFlexDropCopyInitiateOperationConfirmedMessage(message) ==
    EncodeSubHdr4(message.subHdr)
        \o message.partId
        \o message.statusCodeUint162
        \o message.fcmId
        \o message.targetId
        \o message.reqCmSeq
        \o message.reserved16

DecodeFlexDropCopyInitiateOperationConfirmedMessage(bytes) ==
    LET subHdr == DecodeSubHdr4(bytes) IN IF ~subHdr.ok THEN Fail ELSE
    LET partId == ReadBytes(subHdr.rest, 1) IN IF ~partId.ok THEN Fail ELSE
    LET statusCodeUint162 == ReadBytes(partId.rest, 2) IN IF ~statusCodeUint162.ok THEN Fail ELSE
    LET fcmId == ReadBytes(statusCodeUint162.rest, 2) IN IF ~fcmId.ok THEN Fail ELSE
    LET targetId == ReadBytes(fcmId.rest, 1) IN IF ~targetId.ok THEN Fail ELSE
    LET reqCmSeq == ReadBytes(targetId.rest, 4) IN IF ~reqCmSeq.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(reqCmSeq.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ subHdr            |-> subHdr.value,
         partId            |-> partId.value,
         statusCodeUint162 |-> statusCodeUint162.value,
         fcmId             |-> fcmId.value,
         targetId          |-> targetId.value,
         reqCmSeq          |-> reqCmSeq.value,
         reserved16        |-> reserved16.value ], reserved16.rest)

ZeroFlexDropCopyInitiateOperationConfirmedMessage ==
    [ subHdr            |-> ZeroSubHdr4,
      partId            |-> [i \in 1 .. 1 |-> 0],
      statusCodeUint162 |-> [i \in 1 .. 2 |-> 0],
      fcmId             |-> [i \in 1 .. 2 |-> 0],
      targetId          |-> [i \in 1 .. 1 |-> 0],
      reqCmSeq          |-> [i \in 1 .. 4 |-> 0],
      reserved16        |-> [i \in 1 .. 16 |-> 0] ]

(* Flex Drop Copy Initiate Operation Confirmed Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexDropCopyInitiateOperationConfirmedMessage ==
    { ZeroFlexDropCopyInitiateOperationConfirmedMessage }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.subHdr = one] : one \in CheckedSubHdr4 }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.partId = one] : one \in Sample(1) }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.statusCodeUint162 = one] : one \in Sample(2) }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.fcmId = one] : one \in Sample(2) }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.targetId = one] : one \in Sample(1) }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.reqCmSeq = one] : one \in Sample(4) }
        \cup { [ZeroFlexDropCopyInitiateOperationConfirmedMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

WakeUpCallMessageCode == 10  \* 0x0a
WakeUpCallConfirmedMessageCode == 20  \* 0x14
LogonNoticeMessageCode == 30  \* 0x1e
FinalSequentialNumberNotificationForGroupMessageCode == 230  \* 0xe6
RequestLogonMessageCode == 40  \* 0x28
ActivateApplicationSystemMessageCode == 50  \* 0x32
ActivateApplicationSystemConfirmedMessageCode == 60  \* 0x3c
LogoutMessageCode == 70  \* 0x46
LogoutConfirmedMessageCode == 80  \* 0x50
ConfirmConnectionMessageCode == 104  \* 0x68
ConnectionConfirmedMessageCode == 105  \* 0x69
OrderStatusReportMessageCode == 102  \* 0x66
OrderStatusReportLongFormatMessageCode == 132  \* 0x84
ErrorReportMessageCode == 103  \* 0x67
FlexOrderStatusReportMessageCode == 202  \* 0xca
FlexErrorReportMessageCode == 203  \* 0xcb
DropCopyInitiateOperationMessageCode == 115  \* 0x73
DropCopyInitiateOperationConfirmedMessageCode == 116  \* 0x74
FlexDropCopyInitiateOperationMessageCode == 215  \* 0xd7
FlexDropCopyInitiateOperationConfirmedMessageCode == 216  \* 0xd8

Payload ==
    [ tag : {WakeUpCallMessageCode}, body : WakeUpCallMessage ]
        \cup [ tag : {WakeUpCallConfirmedMessageCode}, body : WakeUpCallConfirmedMessage ]
        \cup [ tag : {LogonNoticeMessageCode}, body : LogonNoticeMessage ]
        \cup [ tag : {FinalSequentialNumberNotificationForGroupMessageCode}, body : FinalSequentialNumberNotificationForGroupMessage ]
        \cup [ tag : {RequestLogonMessageCode}, body : RequestLogonMessage ]
        \cup [ tag : {ActivateApplicationSystemMessageCode}, body : ActivateApplicationSystemMessage ]
        \cup [ tag : {ActivateApplicationSystemConfirmedMessageCode}, body : ActivateApplicationSystemConfirmedMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutConfirmedMessageCode}, body : LogoutConfirmedMessage ]
        \cup [ tag : {ConfirmConnectionMessageCode}, body : ConfirmConnectionMessage ]
        \cup [ tag : {ConnectionConfirmedMessageCode}, body : ConnectionConfirmedMessage ]
        \cup [ tag : {OrderStatusReportMessageCode}, body : OrderStatusReportMessage ]
        \cup [ tag : {OrderStatusReportLongFormatMessageCode}, body : OrderStatusReportLongFormatMessage ]
        \cup [ tag : {ErrorReportMessageCode}, body : ErrorReportMessage ]
        \cup [ tag : {FlexOrderStatusReportMessageCode}, body : FlexOrderStatusReportMessage ]
        \cup [ tag : {FlexErrorReportMessageCode}, body : FlexErrorReportMessage ]
        \cup [ tag : {DropCopyInitiateOperationMessageCode}, body : DropCopyInitiateOperationMessage ]
        \cup [ tag : {DropCopyInitiateOperationConfirmedMessageCode}, body : DropCopyInitiateOperationConfirmedMessage ]
        \cup [ tag : {FlexDropCopyInitiateOperationMessageCode}, body : FlexDropCopyInitiateOperationMessage ]
        \cup [ tag : {FlexDropCopyInitiateOperationConfirmedMessageCode}, body : FlexDropCopyInitiateOperationConfirmedMessage ]

EncodePayload(message) ==
    CASE message.tag = WakeUpCallMessageCode -> EncodeWakeUpCallMessage(message.body)
      [] message.tag = WakeUpCallConfirmedMessageCode -> EncodeWakeUpCallConfirmedMessage(message.body)
      [] message.tag = LogonNoticeMessageCode -> EncodeLogonNoticeMessage(message.body)
      [] message.tag = FinalSequentialNumberNotificationForGroupMessageCode -> EncodeFinalSequentialNumberNotificationForGroupMessage(message.body)
      [] message.tag = RequestLogonMessageCode -> EncodeRequestLogonMessage(message.body)
      [] message.tag = ActivateApplicationSystemMessageCode -> EncodeActivateApplicationSystemMessage(message.body)
      [] message.tag = ActivateApplicationSystemConfirmedMessageCode -> EncodeActivateApplicationSystemConfirmedMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = LogoutConfirmedMessageCode -> EncodeLogoutConfirmedMessage(message.body)
      [] message.tag = ConfirmConnectionMessageCode -> EncodeConfirmConnectionMessage(message.body)
      [] message.tag = ConnectionConfirmedMessageCode -> EncodeConnectionConfirmedMessage(message.body)
      [] message.tag = OrderStatusReportMessageCode -> EncodeOrderStatusReportMessage(message.body)
      [] message.tag = OrderStatusReportLongFormatMessageCode -> EncodeOrderStatusReportLongFormatMessage(message.body)
      [] message.tag = ErrorReportMessageCode -> EncodeErrorReportMessage(message.body)
      [] message.tag = FlexOrderStatusReportMessageCode -> EncodeFlexOrderStatusReportMessage(message.body)
      [] message.tag = FlexErrorReportMessageCode -> EncodeFlexErrorReportMessage(message.body)
      [] message.tag = DropCopyInitiateOperationMessageCode -> EncodeDropCopyInitiateOperationMessage(message.body)
      [] message.tag = DropCopyInitiateOperationConfirmedMessageCode -> EncodeDropCopyInitiateOperationConfirmedMessage(message.body)
      [] message.tag = FlexDropCopyInitiateOperationMessageCode -> EncodeFlexDropCopyInitiateOperationMessage(message.body)
      [] message.tag = FlexDropCopyInitiateOperationConfirmedMessageCode -> EncodeFlexDropCopyInitiateOperationConfirmedMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = WakeUpCallMessageCode -> DecodeWakeUpCallMessage(bytes)
              [] tag = WakeUpCallConfirmedMessageCode -> DecodeWakeUpCallConfirmedMessage(bytes)
              [] tag = LogonNoticeMessageCode -> DecodeLogonNoticeMessage(bytes)
              [] tag = FinalSequentialNumberNotificationForGroupMessageCode -> DecodeFinalSequentialNumberNotificationForGroupMessage(bytes)
              [] tag = RequestLogonMessageCode -> DecodeRequestLogonMessage(bytes)
              [] tag = ActivateApplicationSystemMessageCode -> DecodeActivateApplicationSystemMessage(bytes)
              [] tag = ActivateApplicationSystemConfirmedMessageCode -> DecodeActivateApplicationSystemConfirmedMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutConfirmedMessageCode -> DecodeLogoutConfirmedMessage(bytes)
              [] tag = ConfirmConnectionMessageCode -> DecodeConfirmConnectionMessage(bytes)
              [] tag = ConnectionConfirmedMessageCode -> DecodeConnectionConfirmedMessage(bytes)
              [] tag = OrderStatusReportMessageCode -> DecodeOrderStatusReportMessage(bytes)
              [] tag = OrderStatusReportLongFormatMessageCode -> DecodeOrderStatusReportLongFormatMessage(bytes)
              [] tag = ErrorReportMessageCode -> DecodeErrorReportMessage(bytes)
              [] tag = FlexOrderStatusReportMessageCode -> DecodeFlexOrderStatusReportMessage(bytes)
              [] tag = FlexErrorReportMessageCode -> DecodeFlexErrorReportMessage(bytes)
              [] tag = DropCopyInitiateOperationMessageCode -> DecodeDropCopyInitiateOperationMessage(bytes)
              [] tag = DropCopyInitiateOperationConfirmedMessageCode -> DecodeDropCopyInitiateOperationConfirmedMessage(bytes)
              [] tag = FlexDropCopyInitiateOperationMessageCode -> DecodeFlexDropCopyInitiateOperationMessage(bytes)
              [] tag = FlexDropCopyInitiateOperationConfirmedMessageCode -> DecodeFlexDropCopyInitiateOperationConfirmedMessage(bytes)
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
        \cup { [tag |-> ActivateApplicationSystemMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemMessage }
        \cup { [tag |-> ActivateApplicationSystemConfirmedMessageCode, body |-> one] : one \in CheckedActivateApplicationSystemConfirmedMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutConfirmedMessageCode, body |-> one] : one \in CheckedLogoutConfirmedMessage }
        \cup { [tag |-> ConfirmConnectionMessageCode, body |-> one] : one \in CheckedConfirmConnectionMessage }
        \cup { [tag |-> ConnectionConfirmedMessageCode, body |-> one] : one \in CheckedConnectionConfirmedMessage }
        \cup { [tag |-> OrderStatusReportMessageCode, body |-> one] : one \in CheckedOrderStatusReportMessage }
        \cup { [tag |-> OrderStatusReportLongFormatMessageCode, body |-> one] : one \in CheckedOrderStatusReportLongFormatMessage }
        \cup { [tag |-> ErrorReportMessageCode, body |-> one] : one \in CheckedErrorReportMessage }
        \cup { [tag |-> FlexOrderStatusReportMessageCode, body |-> one] : one \in CheckedFlexOrderStatusReportMessage }
        \cup { [tag |-> FlexErrorReportMessageCode, body |-> one] : one \in CheckedFlexErrorReportMessage }
        \cup { [tag |-> DropCopyInitiateOperationMessageCode, body |-> one] : one \in CheckedDropCopyInitiateOperationMessage }
        \cup { [tag |-> DropCopyInitiateOperationConfirmedMessageCode, body |-> one] : one \in CheckedDropCopyInitiateOperationConfirmedMessage }
        \cup { [tag |-> FlexDropCopyInitiateOperationMessageCode, body |-> one] : one \in CheckedFlexDropCopyInitiateOperationMessage }
        \cup { [tag |-> FlexDropCopyInitiateOperationConfirmedMessageCode, body |-> one] : one \in CheckedFlexDropCopyInitiateOperationConfirmedMessage }

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
    LET payload == DecodePayload(messageType.value, sessionId.rest) IN IF ~payload.ok THEN Fail ELSE
    LET messageTail == DecodeMessageTail(payload.rest) IN IF ~messageTail.ok THEN Fail ELSE
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
RoundTripSubHdr2 ==
    \A message \in CheckedSubHdr2 :
        LET read == DecodeSubHdr2(EncodeSubHdr2(message))
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

(* Every Drop Copy Initiate Operation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDropCopyInitiateOperationMessage ==
    \A message \in CheckedDropCopyInitiateOperationMessage :
        LET read == DecodeDropCopyInitiateOperationMessage(EncodeDropCopyInitiateOperationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Drop Copy Initiate Operation Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDropCopyInitiateOperationConfirmedMessage ==
    \A message \in CheckedDropCopyInitiateOperationConfirmedMessage :
        LET read == DecodeDropCopyInitiateOperationConfirmedMessage(EncodeDropCopyInitiateOperationConfirmedMessage(message))
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

(* Every Flex Drop Copy Initiate Operation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDropCopyInitiateOperationMessage ==
    \A message \in CheckedFlexDropCopyInitiateOperationMessage :
        LET read == DecodeFlexDropCopyInitiateOperationMessage(EncodeFlexDropCopyInitiateOperationMessage(message))
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

(* Every Flex Drop Copy Initiate Operation Confirmed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDropCopyInitiateOperationConfirmedMessage ==
    \A message \in CheckedFlexDropCopyInitiateOperationConfirmedMessage :
        LET read == DecodeFlexDropCopyInitiateOperationConfirmedMessage(EncodeFlexDropCopyInitiateOperationConfirmedMessage(message))
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
        LET read == DecodeSymSymbolX(message.tag, EncodeSymSymbolX(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Long Symbol X is selected by the Symbol Type it is written under *)
SelectsSymLongSymbolX ==
    \A message \in CheckedSymLongSymbolX :
        LET read == DecodeSymLongSymbolX(message.tag, EncodeSymLongSymbolX(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sym Flex Product X is selected by the Msg Type Ext it is written under *)
SelectsSymFlexProductX ==
    \A message \in CheckedSymFlexProductX :
        LET read == DecodeSymFlexProductX(message.tag, EncodeSymFlexProductX(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
