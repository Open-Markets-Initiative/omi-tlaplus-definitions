-------------------- MODULE Eurex_T7_Edci_v14_1_Server ---------------------
(***************************************************************************)
(* Eurex Exchange Extended Derivatives Clearing Interface v14.1            *)
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
(* Note: Delete Order Broadcast fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Alignment Padding pads to a 8 byte boundary: it is read as the    *)
(* bytes left to the end of the frame, and the frame's length is trusted   *)
(* to keep that boundary.                                                  *)
(*                                                                         *)
(* Note: Forced Logout Notification fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Heartbeat Notification fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Logon Response fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logout Response fills what is left of the frame Body Len states,  *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Order Exec Report Broadcast fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Partition List Notification fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Reject fills what is left of the frame Body Len states, which is  *)
(* what it is read from.                                                   *)
(*                                                                         *)
(* Note: Session List Notification fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Session Status Broadcast fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
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
(* Rbc Header Comp: 16 bytes                                               *)
(***************************************************************************)

RbcHeaderComp ==
    [ sendingTime          : Sample(8),
      partyIdExecutingUnit : Sample(4),
      partitionId          : Sample(2),
      applId               : Sample(1),
      lastFragment         : Sample(1) ]

EncodeRbcHeaderComp(message) ==
    message.sendingTime
        \o message.partyIdExecutingUnit
        \o message.partitionId
        \o message.applId
        \o message.lastFragment

DecodeRbcHeaderComp(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(sendingTime.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partitionId == ReadBytes(partyIdExecutingUnit.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         partyIdExecutingUnit |-> partyIdExecutingUnit.value,
         partitionId          |-> partitionId.value,
         applId               |-> applId.value,
         lastFragment         |-> lastFragment.value ], lastFragment.rest)

ZeroRbcHeaderComp ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      partyIdExecutingUnit |-> [i \in 1 .. 4 |-> 0],
      partitionId          |-> [i \in 1 .. 2 |-> 0],
      applId               |-> [i \in 1 .. 1 |-> 0],
      lastFragment         |-> [i \in 1 .. 1 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp ==
    { ZeroRbcHeaderComp }
        \cup { [ZeroRbcHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Affected Ord Grp Comp: 88 bytes                                         *)
(***************************************************************************)

AffectedOrdGrpComp ==
    [ affectedOrderId        : Sample(8),
      affectedClOrdId        : Sample(8),
      affectedOrigClOrdId    : Sample(8),
      securityId             : Sample(8),
      partyIdSessionId       : Sample(4),
      partyIdExecutingTrader : Sample(4),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      affectedFixClOrdId     : Sample(20),
      affectedFixOrigClOrdId : Sample(20),
      pad6                   : Sample(6) ]

EncodeAffectedOrdGrpComp(message) ==
    message.affectedOrderId
        \o message.affectedClOrdId
        \o message.affectedOrigClOrdId
        \o message.securityId
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.ordStatus
        \o message.execType
        \o message.affectedFixClOrdId
        \o message.affectedFixOrigClOrdId
        \o message.pad6

DecodeAffectedOrdGrpComp(bytes) ==
    LET affectedOrderId == ReadBytes(bytes, 8) IN IF ~affectedOrderId.ok THEN Fail ELSE
    LET affectedClOrdId == ReadBytes(affectedOrderId.rest, 8) IN IF ~affectedClOrdId.ok THEN Fail ELSE
    LET affectedOrigClOrdId == ReadBytes(affectedClOrdId.rest, 8) IN IF ~affectedOrigClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(affectedOrigClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(securityId.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdExecutingTrader.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET affectedFixClOrdId == ReadBytes(execType.rest, 20) IN IF ~affectedFixClOrdId.ok THEN Fail ELSE
    LET affectedFixOrigClOrdId == ReadBytes(affectedFixClOrdId.rest, 20) IN IF ~affectedFixOrigClOrdId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(affectedFixOrigClOrdId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ affectedOrderId        |-> affectedOrderId.value,
         affectedClOrdId        |-> affectedClOrdId.value,
         affectedOrigClOrdId    |-> affectedOrigClOrdId.value,
         securityId             |-> securityId.value,
         partyIdSessionId       |-> partyIdSessionId.value,
         partyIdExecutingTrader |-> partyIdExecutingTrader.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         affectedFixClOrdId     |-> affectedFixClOrdId.value,
         affectedFixOrigClOrdId |-> affectedFixOrigClOrdId.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroAffectedOrdGrpComp ==
    [ affectedOrderId        |-> [i \in 1 .. 8 |-> 0],
      affectedClOrdId        |-> [i \in 1 .. 8 |-> 0],
      affectedOrigClOrdId    |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      partyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      affectedFixClOrdId     |-> [i \in 1 .. 20 |-> 0],
      affectedFixOrigClOrdId |-> [i \in 1 .. 20 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* Affected Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrdGrpComp ==
    { ZeroAffectedOrdGrpComp }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedOrigClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedFixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedFixOrigClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Affected Ord Grp Comp, written one after another *)
RECURSIVE EncodeAffectedOrdGrpCompList(_)
EncodeAffectedOrdGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAffectedOrdGrpComp(Head(messages)) \o EncodeAffectedOrdGrpCompList(Tail(messages))

(* As many Affected Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadAffectedOrdGrpCompList(_, _)
ReadAffectedOrdGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAffectedOrdGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAffectedOrdGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Affected Ord Grp Comp of each kind, for the lists that carry them *)
OneAffectedOrdGrpComp == { ZeroAffectedOrdGrpComp }

(***************************************************************************)
(* Delete Order Broadcast                                                  *)
(***************************************************************************)

DeleteOrderBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderComp      : RbcHeaderComp,
      execId             : Sample(8),
      marketSegmentId    : Sample(4),
      pad2v2             : Sample(2),
      affectedOrdGrpComp : SampleLists(OneAffectedOrdGrpComp) ]

EncodeDeleteOrderBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp(message.rbcHeaderComp)
        \o message.execId
        \o message.marketSegmentId
        \o EncodeUIntLE(Len(message.affectedOrdGrpComp), 2)
        \o message.pad2v2
        \o EncodeAffectedOrdGrpCompList(message.affectedOrdGrpComp)

DecodeDeleteOrderBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET execId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(execId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noAffectedOrders == ReadUIntLE(marketSegmentId.rest, 2) IN IF ~noAffectedOrders.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(noAffectedOrders.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpCompList(pad2v2.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderComp      |-> rbcHeaderComp.value,
         execId             |-> execId.value,
         marketSegmentId    |-> marketSegmentId.value,
         pad2v2             |-> pad2v2.value,
         affectedOrdGrpComp |-> affectedOrdGrpComp.value ], affectedOrdGrpComp.rest)

ZeroDeleteOrderBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp      |-> ZeroRbcHeaderComp,
      execId             |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      pad2v2             |-> [i \in 1 .. 2 |-> 0],
      affectedOrdGrpComp |-> << >> ]

(* Delete Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderBroadcast ==
    { ZeroDeleteOrderBroadcast }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp) }

(***************************************************************************)
(* Notif Header Comp: 8 bytes                                              *)
(***************************************************************************)

NotifHeaderComp ==
    [ sendingTime : Sample(8) ]

EncodeNotifHeaderComp(message) ==
    message.sendingTime

DecodeNotifHeaderComp(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroNotifHeaderComp ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Notif Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotifHeaderComp ==
    { ZeroNotifHeaderComp }
        \cup { [ZeroNotifHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Forced Logout Notification                                              *)
(***************************************************************************)

ForcedLogoutNotification ==
    [ pad2             : Sample(2),
      notifHeaderComp  : NotifHeaderComp,
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeForcedLogoutNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp(message.notifHeaderComp)
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.varText
        \o message.alignmentPadding

DecodeForcedLogoutNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(notifHeaderComp.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET varText == ReadBytes(varTextLen.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroForcedLogoutNotification ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp,
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Forced Logout Notification at zero, then each field in turn at the values it is checked at *)
CheckedForcedLogoutNotification ==
    { ZeroForcedLogoutNotification }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Notif Header Comp: 8 bytes                                              *)
(***************************************************************************)

NotifHeaderComp2 ==
    [ sendingTime : Sample(8) ]

EncodeNotifHeaderComp2(message) ==
    message.sendingTime

DecodeNotifHeaderComp2(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroNotifHeaderComp2 ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Notif Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotifHeaderComp2 ==
    { ZeroNotifHeaderComp2 }
        \cup { [ZeroNotifHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Heartbeat Notification: 10 bytes                                        *)
(***************************************************************************)

HeartbeatNotification ==
    [ pad2            : Sample(2),
      notifHeaderComp : NotifHeaderComp2 ]

EncodeHeartbeatNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp2(message.notifHeaderComp)

DecodeHeartbeatNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp2(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    Ok([ pad2            |-> pad2.value,
         notifHeaderComp |-> notifHeaderComp.value ], notifHeaderComp.rest)

ZeroHeartbeatNotification ==
    [ pad2            |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp |-> ZeroNotifHeaderComp2 ]

(* Heartbeat Notification at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatNotification ==
    { ZeroHeartbeatNotification }
        \cup { [ZeroHeartbeatNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroHeartbeatNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp2 }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp ==
    [ requestTime  : Sample(8),
      sendingTime  : Sample(8),
      msgSeqNum    : Sample(4),
      lastFragment : Sample(1),
      pad3         : Sample(3) ]

EncodeResponseHeaderComp(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeResponseHeaderComp(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime  |-> requestTime.value,
         sendingTime  |-> sendingTime.value,
         msgSeqNum    |-> msgSeqNum.value,
         lastFragment |-> lastFragment.value,
         pad3         |-> pad3.value ], pad3.rest)

ZeroResponseHeaderComp ==
    [ requestTime  |-> [i \in 1 .. 8 |-> 0],
      sendingTime  |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum    |-> [i \in 1 .. 4 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      pad3         |-> [i \in 1 .. 3 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp ==
    { ZeroResponseHeaderComp }
        \cup { [ZeroResponseHeaderComp EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Logon Response: 74 bytes                                                *)
(***************************************************************************)

LogonResponse ==
    [ pad2                    : Sample(2),
      responseHeaderComp      : ResponseHeaderComp,
      heartBtInt              : Sample(4),
      sessionInstanceId       : Sample(4),
      marketId                : Sample(2),
      tradSesMode             : Sample(1),
      defaultCstmApplVerId    : Sample(30),
      defaultCstmApplVerSubId : Sample(5),
      pad2v2                  : Sample(2) ]

EncodeLogonResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp(message.responseHeaderComp)
        \o message.heartBtInt
        \o message.sessionInstanceId
        \o message.marketId
        \o message.tradSesMode
        \o message.defaultCstmApplVerId
        \o message.defaultCstmApplVerSubId
        \o message.pad2v2

DecodeLogonResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(responseHeaderComp.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET sessionInstanceId == ReadBytes(heartBtInt.rest, 4) IN IF ~sessionInstanceId.ok THEN Fail ELSE
    LET marketId == ReadBytes(sessionInstanceId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET tradSesMode == ReadBytes(marketId.rest, 1) IN IF ~tradSesMode.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(tradSesMode.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET defaultCstmApplVerSubId == ReadBytes(defaultCstmApplVerId.rest, 5) IN IF ~defaultCstmApplVerSubId.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(defaultCstmApplVerSubId.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2                    |-> pad2.value,
         responseHeaderComp      |-> responseHeaderComp.value,
         heartBtInt              |-> heartBtInt.value,
         sessionInstanceId       |-> sessionInstanceId.value,
         marketId                |-> marketId.value,
         tradSesMode             |-> tradSesMode.value,
         defaultCstmApplVerId    |-> defaultCstmApplVerId.value,
         defaultCstmApplVerSubId |-> defaultCstmApplVerSubId.value,
         pad2v2                  |-> pad2v2.value ], pad2v2.rest)

ZeroLogonResponse ==
    [ pad2                    |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp      |-> ZeroResponseHeaderComp,
      heartBtInt              |-> [i \in 1 .. 4 |-> 0],
      sessionInstanceId       |-> [i \in 1 .. 4 |-> 0],
      marketId                |-> [i \in 1 .. 2 |-> 0],
      tradSesMode             |-> [i \in 1 .. 1 |-> 0],
      defaultCstmApplVerId    |-> [i \in 1 .. 30 |-> 0],
      defaultCstmApplVerSubId |-> [i \in 1 .. 5 |-> 0],
      pad2v2                  |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Response at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponse ==
    { ZeroLogonResponse }
        \cup { [ZeroLogonResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogonResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp }
        \cup { [ZeroLogonResponse EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.sessionInstanceId = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroLogonResponse EXCEPT !.tradSesMode = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponse EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonResponse EXCEPT !.defaultCstmApplVerSubId = one] : one \in Sample(5) }
        \cup { [ZeroLogonResponse EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp2 ==
    [ requestTime  : Sample(8),
      sendingTime  : Sample(8),
      msgSeqNum    : Sample(4),
      lastFragment : Sample(1),
      pad3         : Sample(3) ]

EncodeResponseHeaderComp2(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeResponseHeaderComp2(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime  |-> requestTime.value,
         sendingTime  |-> sendingTime.value,
         msgSeqNum    |-> msgSeqNum.value,
         lastFragment |-> lastFragment.value,
         pad3         |-> pad3.value ], pad3.rest)

ZeroResponseHeaderComp2 ==
    [ requestTime  |-> [i \in 1 .. 8 |-> 0],
      sendingTime  |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum    |-> [i \in 1 .. 4 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      pad3         |-> [i \in 1 .. 3 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp2 ==
    { ZeroResponseHeaderComp2 }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Logout Response: 26 bytes                                               *)
(***************************************************************************)

LogoutResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp2 ]

EncodeLogoutResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp2(message.responseHeaderComp)

DecodeLogoutResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp2(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroLogoutResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp2 ]

(* Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponse ==
    { ZeroLogoutResponse }
        \cup { [ZeroLogoutResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp2 }

(***************************************************************************)
(* Rbc Header Comp: 16 bytes                                               *)
(***************************************************************************)

RbcHeaderComp2 ==
    [ sendingTime          : Sample(8),
      partyIdExecutingUnit : Sample(4),
      partitionId          : Sample(2),
      applId               : Sample(1),
      lastFragment         : Sample(1) ]

EncodeRbcHeaderComp2(message) ==
    message.sendingTime
        \o message.partyIdExecutingUnit
        \o message.partitionId
        \o message.applId
        \o message.lastFragment

DecodeRbcHeaderComp2(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(sendingTime.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partitionId == ReadBytes(partyIdExecutingUnit.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         partyIdExecutingUnit |-> partyIdExecutingUnit.value,
         partitionId          |-> partitionId.value,
         applId               |-> applId.value,
         lastFragment         |-> lastFragment.value ], lastFragment.rest)

ZeroRbcHeaderComp2 ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      partyIdExecutingUnit |-> [i \in 1 .. 4 |-> 0],
      partitionId          |-> [i \in 1 .. 2 |-> 0],
      applId               |-> [i \in 1 .. 1 |-> 0],
      lastFragment         |-> [i \in 1 .. 1 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp2 ==
    { ZeroRbcHeaderComp2 }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Grp Comp: 24 bytes                                                *)
(***************************************************************************)

FillsGrpComp ==
    [ fillPx      : Sample(8),
      fillQty     : Sample(8),
      fillMatchId : Sample(4),
      fillExecId  : Sample(4) ]

EncodeFillsGrpComp(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId

DecodeFillsGrpComp(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    Ok([ fillPx      |-> fillPx.value,
         fillQty     |-> fillQty.value,
         fillMatchId |-> fillMatchId.value,
         fillExecId  |-> fillExecId.value ], fillExecId.rest)

ZeroFillsGrpComp ==
    [ fillPx      |-> [i \in 1 .. 8 |-> 0],
      fillQty     |-> [i \in 1 .. 8 |-> 0],
      fillMatchId |-> [i \in 1 .. 4 |-> 0],
      fillExecId  |-> [i \in 1 .. 4 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp ==
    { ZeroFillsGrpComp }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillExecId = one] : one \in Sample(4) }

(* A run of Fills Grp Comp, written one after another *)
RECURSIVE EncodeFillsGrpCompList(_)
EncodeFillsGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGrpComp(Head(messages)) \o EncodeFillsGrpCompList(Tail(messages))

(* As many Fills Grp Comp as the field that counts them says *)
RECURSIVE ReadFillsGrpCompList(_, _)
ReadFillsGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Grp Comp of each kind, for the lists that carry them *)
OneFillsGrpComp == { ZeroFillsGrpComp }

(***************************************************************************)
(* Order Exec Report Broadcast                                             *)
(***************************************************************************)

OrderExecReportBroadcast ==
    [ pad2                                    : Sample(2),
      rbcHeaderComp                           : RbcHeaderComp2,
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      securityId                              : Sample(8),
      execId                                  : Sample(8),
      price                                   : Sample(8),
      stopPx                                  : Sample(8),
      leavesQty                               : Sample(8),
      cumQty                                  : Sample(8),
      cxlQty                                  : Sample(8),
      orderQty                                : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      matchInstCrossId                        : Sample(4),
      expireDate                              : Sample(4),
      partyIdSessionId                        : Sample(4),
      partyIdExecutingTrader                  : Sample(4),
      productComplex                          : Sample(1),
      ordStatus                               : Sample(1),
      execType                                : Sample(1),
      side                                    : Sample(1),
      ordType                                 : Sample(1),
      matchType                               : Sample(1),
      tradingCapacity                         : Sample(1),
      timeInForce                             : Sample(1),
      execInst                                : Sample(1),
      triggered                               : Sample(1),
      tradingSessionSubId                     : Sample(1),
      applSeqIndicator                        : Sample(1),
      selfMatchPreventionInstruction          : Sample(1),
      crossMatchInstruction                   : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      crossedIndicator                        : Sample(1),
      custOrderHandlingInst                   : Sample(1),
      orderOrigination                        : Sample(1),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText3                               : Sample(12),
      fixClOrdId                              : Sample(20),
      fixOrigClOrdId                          : Sample(20),
      partyEndClientIdentification            : Sample(20),
      fillsGrpComp                            : SampleLists(OneFillsGrpComp) ]

EncodeOrderExecReportBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp2(message.rbcHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.price
        \o message.stopPx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.expireDate
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.productComplex
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.ordType
        \o message.matchType
        \o message.tradingCapacity
        \o message.timeInForce
        \o message.execInst
        \o message.triggered
        \o message.tradingSessionSubId
        \o message.applSeqIndicator
        \o message.selfMatchPreventionInstruction
        \o message.crossMatchInstruction
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.crossedIndicator
        \o message.custOrderHandlingInst
        \o message.orderOrigination
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.fixClOrdId
        \o message.fixOrigClOrdId
        \o message.partyEndClientIdentification
        \o EncodeFillsGrpCompList(message.fillsGrpComp)

DecodeOrderExecReportBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp2(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET price == ReadBytes(execId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(stopPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(orderQty.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(matchInstCrossId.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(expireDate.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET productComplex == ReadBytes(partyIdExecutingTrader.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(productComplex.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET matchType == ReadBytes(ordType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(matchType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(tradingCapacity.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET triggered == ReadBytes(execInst.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(triggered.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(applSeqIndicator.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET crossMatchInstruction == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~crossMatchInstruction.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(crossMatchInstruction.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(executingTraderQualifier.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(noFills.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(crossedIndicator.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(custOrderHandlingInst.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(orderOrigination.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText3.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET fixOrigClOrdId == ReadBytes(fixClOrdId.rest, 20) IN IF ~fixOrigClOrdId.ok THEN Fail ELSE
    LET partyEndClientIdentification == ReadBytes(fixOrigClOrdId.rest, 20) IN IF ~partyEndClientIdentification.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpCompList(partyEndClientIdentification.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                                    |-> pad2.value,
         rbcHeaderComp                           |-> rbcHeaderComp.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         securityId                              |-> securityId.value,
         execId                                  |-> execId.value,
         price                                   |-> price.value,
         stopPx                                  |-> stopPx.value,
         leavesQty                               |-> leavesQty.value,
         cumQty                                  |-> cumQty.value,
         cxlQty                                  |-> cxlQty.value,
         orderQty                                |-> orderQty.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         expireDate                              |-> expireDate.value,
         partyIdSessionId                        |-> partyIdSessionId.value,
         partyIdExecutingTrader                  |-> partyIdExecutingTrader.value,
         productComplex                          |-> productComplex.value,
         ordStatus                               |-> ordStatus.value,
         execType                                |-> execType.value,
         side                                    |-> side.value,
         ordType                                 |-> ordType.value,
         matchType                               |-> matchType.value,
         tradingCapacity                         |-> tradingCapacity.value,
         timeInForce                             |-> timeInForce.value,
         execInst                                |-> execInst.value,
         triggered                               |-> triggered.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         selfMatchPreventionInstruction          |-> selfMatchPreventionInstruction.value,
         crossMatchInstruction                   |-> crossMatchInstruction.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         crossedIndicator                        |-> crossedIndicator.value,
         custOrderHandlingInst                   |-> custOrderHandlingInst.value,
         orderOrigination                        |-> orderOrigination.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText3                               |-> freeText3.value,
         fixClOrdId                              |-> fixClOrdId.value,
         fixOrigClOrdId                          |-> fixOrigClOrdId.value,
         partyEndClientIdentification            |-> partyEndClientIdentification.value,
         fillsGrpComp                            |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecReportBroadcast ==
    [ pad2                                    |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                           |-> ZeroRbcHeaderComp2,
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      execId                                  |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      stopPx                                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty                               |-> [i \in 1 .. 8 |-> 0],
      cumQty                                  |-> [i \in 1 .. 8 |-> 0],
      cxlQty                                  |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      expireDate                              |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId                        |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader                  |-> [i \in 1 .. 4 |-> 0],
      productComplex                          |-> [i \in 1 .. 1 |-> 0],
      ordStatus                               |-> [i \in 1 .. 1 |-> 0],
      execType                                |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      ordType                                 |-> [i \in 1 .. 1 |-> 0],
      matchType                               |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      triggered                               |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction          |-> [i \in 1 .. 1 |-> 0],
      crossMatchInstruction                   |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator                        |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst                   |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText3                               |-> [i \in 1 .. 12 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      fixOrigClOrdId                          |-> [i \in 1 .. 20 |-> 0],
      partyEndClientIdentification            |-> [i \in 1 .. 20 |-> 0],
      fillsGrpComp                            |-> << >> ]

(* Order Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecReportBroadcast ==
    { ZeroOrderExecReportBroadcast }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp2 }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.crossMatchInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fixOrigClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyEndClientIdentification = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp) }

(***************************************************************************)
(* Notif Header Comp: 8 bytes                                              *)
(***************************************************************************)

NotifHeaderComp3 ==
    [ sendingTime : Sample(8) ]

EncodeNotifHeaderComp3(message) ==
    message.sendingTime

DecodeNotifHeaderComp3(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroNotifHeaderComp3 ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Notif Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotifHeaderComp3 ==
    { ZeroNotifHeaderComp3 }
        \cup { [ZeroNotifHeaderComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Partition Grp Comp: 8 bytes                                             *)
(***************************************************************************)

PartitionGrpComp ==
    [ partitionId : Sample(2),
      pad6        : Sample(6) ]

EncodePartitionGrpComp(message) ==
    message.partitionId
        \o message.pad6

DecodePartitionGrpComp(bytes) ==
    LET partitionId == ReadBytes(bytes, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partitionId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ partitionId |-> partitionId.value,
         pad6        |-> pad6.value ], pad6.rest)

ZeroPartitionGrpComp ==
    [ partitionId |-> [i \in 1 .. 2 |-> 0],
      pad6        |-> [i \in 1 .. 6 |-> 0] ]

(* Partition Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedPartitionGrpComp ==
    { ZeroPartitionGrpComp }
        \cup { [ZeroPartitionGrpComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroPartitionGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Partition Grp Comp, written one after another *)
RECURSIVE EncodePartitionGrpCompList(_)
EncodePartitionGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartitionGrpComp(Head(messages)) \o EncodePartitionGrpCompList(Tail(messages))

(* As many Partition Grp Comp as the field that counts them says *)
RECURSIVE ReadPartitionGrpCompList(_, _)
ReadPartitionGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartitionGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartitionGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Partition Grp Comp of each kind, for the lists that carry them *)
OnePartitionGrpComp == { ZeroPartitionGrpComp }

(***************************************************************************)
(* Partition List Notification                                             *)
(***************************************************************************)

PartitionListNotification ==
    [ pad2             : Sample(2),
      notifHeaderComp  : NotifHeaderComp3,
      pad7             : Sample(7),
      partitionGrpComp : SampleLists(OnePartitionGrpComp) ]

EncodePartitionListNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp3(message.notifHeaderComp)
        \o EncodeUIntBE(Len(message.partitionGrpComp), 1)
        \o message.pad7
        \o EncodePartitionGrpCompList(message.partitionGrpComp)

DecodePartitionListNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp3(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET noPartitions == ReadUIntBE(notifHeaderComp.rest, 1) IN IF ~noPartitions.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noPartitions.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET partitionGrpComp == ReadPartitionGrpCompList(pad7.rest, noPartitions.value) IN IF ~partitionGrpComp.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         pad7             |-> pad7.value,
         partitionGrpComp |-> partitionGrpComp.value ], partitionGrpComp.rest)

ZeroPartitionListNotification ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp3,
      pad7             |-> [i \in 1 .. 7 |-> 0],
      partitionGrpComp |-> << >> ]

(* Partition List Notification at zero, then each field in turn at the values it is checked at *)
CheckedPartitionListNotification ==
    { ZeroPartitionListNotification }
        \cup { [ZeroPartitionListNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPartitionListNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp3 }
        \cup { [ZeroPartitionListNotification EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroPartitionListNotification EXCEPT !.partitionGrpComp = one] : one \in SampleLists(OnePartitionGrpComp) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp3 ==
    [ requestTime  : Sample(8),
      sendingTime  : Sample(8),
      msgSeqNum    : Sample(4),
      lastFragment : Sample(1),
      pad3         : Sample(3) ]

EncodeResponseHeaderComp3(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeResponseHeaderComp3(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime  |-> requestTime.value,
         sendingTime  |-> sendingTime.value,
         msgSeqNum    |-> msgSeqNum.value,
         lastFragment |-> lastFragment.value,
         pad3         |-> pad3.value ], pad3.rest)

ZeroResponseHeaderComp3 ==
    [ requestTime  |-> [i \in 1 .. 8 |-> 0],
      sendingTime  |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum    |-> [i \in 1 .. 4 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      pad3         |-> [i \in 1 .. 3 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp3 ==
    { ZeroResponseHeaderComp3 }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Reject                                                                  *)
(***************************************************************************)

Reject ==
    [ pad2                : Sample(2),
      responseHeaderComp  : ResponseHeaderComp3,
      sessionRejectReason : Sample(4),
      sessionStatus       : Sample(1),
      varText             : SampleBytes,
      alignmentPadding    : SampleBytes ]

EncodeReject(message) ==
    message.pad2
        \o EncodeResponseHeaderComp3(message.responseHeaderComp)
        \o message.sessionRejectReason
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.sessionStatus
        \o message.varText
        \o message.alignmentPadding

DecodeReject(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp3(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(responseHeaderComp.rest, 4) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(sessionRejectReason.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET sessionStatus == ReadBytes(varTextLen.rest, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET varText == ReadBytes(sessionStatus.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2                |-> pad2.value,
         responseHeaderComp  |-> responseHeaderComp.value,
         sessionRejectReason |-> sessionRejectReason.value,
         sessionStatus       |-> sessionStatus.value,
         varText             |-> varText.value,
         alignmentPadding    |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroReject ==
    [ pad2                |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp  |-> ZeroResponseHeaderComp3,
      sessionRejectReason |-> [i \in 1 .. 4 |-> 0],
      sessionStatus       |-> [i \in 1 .. 1 |-> 0],
      varText             |-> << >>,
      alignmentPadding    |-> << >> ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroReject EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp3 }
        \cup { [ZeroReject EXCEPT !.sessionRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroReject EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroReject EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Notif Header Comp: 8 bytes                                              *)
(***************************************************************************)

NotifHeaderComp4 ==
    [ sendingTime : Sample(8) ]

EncodeNotifHeaderComp4(message) ==
    message.sendingTime

DecodeNotifHeaderComp4(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroNotifHeaderComp4 ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Notif Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotifHeaderComp4 ==
    { ZeroNotifHeaderComp4 }
        \cup { [ZeroNotifHeaderComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Sessions Grp Comp: 48 bytes                                             *)
(***************************************************************************)

SessionsGrpComp ==
    [ partyIdSessionId           : Sample(4),
      partyIdExecutingUnit       : Sample(4),
      partyIdSponsoredAccessUnit : Sample(4),
      sessionMode                : Sample(1),
      partyExecutingFirm         : Sample(5),
      partySponsoredAccessUnit   : Sample(30) ]

EncodeSessionsGrpComp(message) ==
    message.partyIdSessionId
        \o message.partyIdExecutingUnit
        \o message.partyIdSponsoredAccessUnit
        \o message.sessionMode
        \o message.partyExecutingFirm
        \o message.partySponsoredAccessUnit

DecodeSessionsGrpComp(bytes) ==
    LET partyIdSessionId == ReadBytes(bytes, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSponsoredAccessUnit == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSponsoredAccessUnit.ok THEN Fail ELSE
    LET sessionMode == ReadBytes(partyIdSponsoredAccessUnit.rest, 1) IN IF ~sessionMode.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(sessionMode.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partySponsoredAccessUnit == ReadBytes(partyExecutingFirm.rest, 30) IN IF ~partySponsoredAccessUnit.ok THEN Fail ELSE
    Ok([ partyIdSessionId           |-> partyIdSessionId.value,
         partyIdExecutingUnit       |-> partyIdExecutingUnit.value,
         partyIdSponsoredAccessUnit |-> partyIdSponsoredAccessUnit.value,
         sessionMode                |-> sessionMode.value,
         partyExecutingFirm         |-> partyExecutingFirm.value,
         partySponsoredAccessUnit   |-> partySponsoredAccessUnit.value ], partySponsoredAccessUnit.rest)

ZeroSessionsGrpComp ==
    [ partyIdSessionId           |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit       |-> [i \in 1 .. 4 |-> 0],
      partyIdSponsoredAccessUnit |-> [i \in 1 .. 4 |-> 0],
      sessionMode                |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm         |-> [i \in 1 .. 5 |-> 0],
      partySponsoredAccessUnit   |-> [i \in 1 .. 30 |-> 0] ]

(* Sessions Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSessionsGrpComp ==
    { ZeroSessionsGrpComp }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partyIdSponsoredAccessUnit = one] : one \in Sample(4) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.sessionMode = one] : one \in Sample(1) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partySponsoredAccessUnit = one] : one \in Sample(30) }

(* A run of Sessions Grp Comp, written one after another *)
RECURSIVE EncodeSessionsGrpCompList(_)
EncodeSessionsGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSessionsGrpComp(Head(messages)) \o EncodeSessionsGrpCompList(Tail(messages))

(* As many Sessions Grp Comp as the field that counts them says *)
RECURSIVE ReadSessionsGrpCompList(_, _)
ReadSessionsGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSessionsGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSessionsGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sessions Grp Comp of each kind, for the lists that carry them *)
OneSessionsGrpComp == { ZeroSessionsGrpComp }

(***************************************************************************)
(* Session List Notification                                               *)
(***************************************************************************)

SessionListNotification ==
    [ pad2            : Sample(2),
      notifHeaderComp : NotifHeaderComp4,
      pad6            : Sample(6),
      sessionsGrpComp : SampleLists(OneSessionsGrpComp) ]

EncodeSessionListNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp4(message.notifHeaderComp)
        \o EncodeUIntLE(Len(message.sessionsGrpComp), 2)
        \o message.pad6
        \o EncodeSessionsGrpCompList(message.sessionsGrpComp)

DecodeSessionListNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp4(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET noSessions == ReadUIntLE(notifHeaderComp.rest, 2) IN IF ~noSessions.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noSessions.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET sessionsGrpComp == ReadSessionsGrpCompList(pad6.rest, noSessions.value) IN IF ~sessionsGrpComp.ok THEN Fail ELSE
    Ok([ pad2            |-> pad2.value,
         notifHeaderComp |-> notifHeaderComp.value,
         pad6            |-> pad6.value,
         sessionsGrpComp |-> sessionsGrpComp.value ], sessionsGrpComp.rest)

ZeroSessionListNotification ==
    [ pad2            |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp |-> ZeroNotifHeaderComp4,
      pad6            |-> [i \in 1 .. 6 |-> 0],
      sessionsGrpComp |-> << >> ]

(* Session List Notification at zero, then each field in turn at the values it is checked at *)
CheckedSessionListNotification ==
    { ZeroSessionListNotification }
        \cup { [ZeroSessionListNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSessionListNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp4 }
        \cup { [ZeroSessionListNotification EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroSessionListNotification EXCEPT !.sessionsGrpComp = one] : one \in SampleLists(OneSessionsGrpComp) }

(***************************************************************************)
(* Rbc Header Comp: 16 bytes                                               *)
(***************************************************************************)

RbcHeaderComp3 ==
    [ sendingTime          : Sample(8),
      partyIdExecutingUnit : Sample(4),
      partitionId          : Sample(2),
      applId               : Sample(1),
      lastFragment         : Sample(1) ]

EncodeRbcHeaderComp3(message) ==
    message.sendingTime
        \o message.partyIdExecutingUnit
        \o message.partitionId
        \o message.applId
        \o message.lastFragment

DecodeRbcHeaderComp3(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(sendingTime.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partitionId == ReadBytes(partyIdExecutingUnit.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ sendingTime          |-> sendingTime.value,
         partyIdExecutingUnit |-> partyIdExecutingUnit.value,
         partitionId          |-> partitionId.value,
         applId               |-> applId.value,
         lastFragment         |-> lastFragment.value ], lastFragment.rest)

ZeroRbcHeaderComp3 ==
    [ sendingTime          |-> [i \in 1 .. 8 |-> 0],
      partyIdExecutingUnit |-> [i \in 1 .. 4 |-> 0],
      partitionId          |-> [i \in 1 .. 2 |-> 0],
      applId               |-> [i \in 1 .. 1 |-> 0],
      lastFragment         |-> [i \in 1 .. 1 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp3 ==
    { ZeroRbcHeaderComp3 }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Session Status Broadcast: 34 bytes                                      *)
(***************************************************************************)

SessionStatusBroadcast ==
    [ pad2            : Sample(2),
      rbcHeaderComp   : RbcHeaderComp3,
      tradeDate       : Sample(4),
      marketSegmentId : Sample(4),
      tradSesEvent    : Sample(1),
      pad7            : Sample(7) ]

EncodeSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp3(message.rbcHeaderComp)
        \o message.tradeDate
        \o message.marketSegmentId
        \o message.tradSesEvent
        \o message.pad7

DecodeSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp3(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(rbcHeaderComp.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tradeDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad7 == ReadBytes(tradSesEvent.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2            |-> pad2.value,
         rbcHeaderComp   |-> rbcHeaderComp.value,
         tradeDate       |-> tradeDate.value,
         marketSegmentId |-> marketSegmentId.value,
         tradSesEvent    |-> tradSesEvent.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroSessionStatusBroadcast ==
    [ pad2            |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp   |-> ZeroRbcHeaderComp3,
      tradeDate       |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedSessionStatusBroadcast ==
    { ZeroSessionStatusBroadcast }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp3 }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

DeleteOrderBroadcastCode == 10902  \* 0x2a96
ForcedLogoutNotificationCode == 10012  \* 0x271c
HeartbeatNotificationCode == 10023  \* 0x2727
LogonResponseCode == 10001  \* 0x2711
LogoutResponseCode == 10003  \* 0x2713
OrderExecReportBroadcastCode == 10901  \* 0x2a95
PartitionListNotificationCode == 10037  \* 0x2735
RejectCode == 10010  \* 0x271a
SessionListNotificationCode == 10036  \* 0x2734
SessionStatusBroadcastCode == 10903  \* 0x2a97

ServerPayload ==
    [ tag : {DeleteOrderBroadcastCode}, body : DeleteOrderBroadcast ]
        \cup [ tag : {ForcedLogoutNotificationCode}, body : ForcedLogoutNotification ]
        \cup [ tag : {HeartbeatNotificationCode}, body : HeartbeatNotification ]
        \cup [ tag : {LogonResponseCode}, body : LogonResponse ]
        \cup [ tag : {LogoutResponseCode}, body : LogoutResponse ]
        \cup [ tag : {OrderExecReportBroadcastCode}, body : OrderExecReportBroadcast ]
        \cup [ tag : {PartitionListNotificationCode}, body : PartitionListNotification ]
        \cup [ tag : {RejectCode}, body : Reject ]
        \cup [ tag : {SessionListNotificationCode}, body : SessionListNotification ]
        \cup [ tag : {SessionStatusBroadcastCode}, body : SessionStatusBroadcast ]

EncodeServerPayload(message) ==
    CASE message.tag = DeleteOrderBroadcastCode -> EncodeDeleteOrderBroadcast(message.body)
      [] message.tag = ForcedLogoutNotificationCode -> EncodeForcedLogoutNotification(message.body)
      [] message.tag = HeartbeatNotificationCode -> EncodeHeartbeatNotification(message.body)
      [] message.tag = LogonResponseCode -> EncodeLogonResponse(message.body)
      [] message.tag = LogoutResponseCode -> EncodeLogoutResponse(message.body)
      [] message.tag = OrderExecReportBroadcastCode -> EncodeOrderExecReportBroadcast(message.body)
      [] message.tag = PartitionListNotificationCode -> EncodePartitionListNotification(message.body)
      [] message.tag = RejectCode -> EncodeReject(message.body)
      [] message.tag = SessionListNotificationCode -> EncodeSessionListNotification(message.body)
      [] message.tag = SessionStatusBroadcastCode -> EncodeSessionStatusBroadcast(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DeleteOrderBroadcastCode -> DecodeDeleteOrderBroadcast(bytes)
              [] tag = ForcedLogoutNotificationCode -> DecodeForcedLogoutNotification(bytes)
              [] tag = HeartbeatNotificationCode -> DecodeHeartbeatNotification(bytes)
              [] tag = LogonResponseCode -> DecodeLogonResponse(bytes)
              [] tag = LogoutResponseCode -> DecodeLogoutResponse(bytes)
              [] tag = OrderExecReportBroadcastCode -> DecodeOrderExecReportBroadcast(bytes)
              [] tag = PartitionListNotificationCode -> DecodePartitionListNotification(bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] tag = SessionListNotificationCode -> DecodeSessionListNotification(bytes)
              [] tag = SessionStatusBroadcastCode -> DecodeSessionStatusBroadcast(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DeleteOrderBroadcastCode, body |-> ZeroDeleteOrderBroadcast]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DeleteOrderBroadcastCode, body |-> one] : one \in CheckedDeleteOrderBroadcast }
        \cup { [tag |-> ForcedLogoutNotificationCode, body |-> one] : one \in CheckedForcedLogoutNotification }
        \cup { [tag |-> HeartbeatNotificationCode, body |-> one] : one \in CheckedHeartbeatNotification }
        \cup { [tag |-> LogonResponseCode, body |-> one] : one \in CheckedLogonResponse }
        \cup { [tag |-> LogoutResponseCode, body |-> one] : one \in CheckedLogoutResponse }
        \cup { [tag |-> OrderExecReportBroadcastCode, body |-> one] : one \in CheckedOrderExecReportBroadcast }
        \cup { [tag |-> PartitionListNotificationCode, body |-> one] : one \in CheckedPartitionListNotification }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }
        \cup { [tag |-> SessionListNotificationCode, body |-> one] : one \in CheckedSessionListNotification }
        \cup { [tag |-> SessionStatusBroadcastCode, body |-> one] : one \in CheckedSessionStatusBroadcast }

(***************************************************************************)
(* Server Message, framed by Body Len                                      *)
(***************************************************************************)

ServerMessage ==
    [ serverPayload : ServerPayload ]

EncodeServerMessageBody(message) ==
    EncodeUIntLE(message.serverPayload.tag, 2)
        \o EncodeServerPayload(message.serverPayload)

(* Body Len counts the bytes it frames, so it is written from them *)
EncodeServerMessage(message) ==
    LET body == EncodeServerMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 4, 4) \o body

DecodeServerMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(templateId.value, templateId.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 4) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeServerMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerMessage ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Message at zero, then each field in turn at the values it is checked at *)
CheckedServerMessage ==
    { ZeroServerMessage }
        \cup { [ZeroServerMessage EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Message, written one after another *)
RECURSIVE EncodeServerMessageList(_)
EncodeServerMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerMessage(Head(messages)) \o EncodeServerMessageList(Tail(messages))

(* As many Server Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerMessageAll(_)
ReadServerMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Message of each kind, for the lists that carry them *)
OneServerMessage ==
    { [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderBroadcastCode, body |-> ZeroDeleteOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ForcedLogoutNotificationCode, body |-> ZeroForcedLogoutNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> HeartbeatNotificationCode, body |-> ZeroHeartbeatNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogonResponseCode, body |-> ZeroLogonResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogoutResponseCode, body |-> ZeroLogoutResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecReportBroadcastCode, body |-> ZeroOrderExecReportBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> PartitionListNotificationCode, body |-> ZeroPartitionListNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RejectCode, body |-> ZeroReject]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SessionListNotificationCode, body |-> ZeroSessionListNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SessionStatusBroadcastCode, body |-> ZeroSessionStatusBroadcast]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverMessage : SampleLists(OneServerMessage) ]

EncodeServerPacket(message) ==
    EncodeServerMessageList(message.serverMessage)

DecodeServerPacket(bytes) ==
    LET serverMessage == ReadServerMessageAll(bytes) IN IF ~serverMessage.ok THEN Fail ELSE
    Ok([ serverMessage |-> serverMessage.value ], serverMessage.rest)

ZeroServerPacket ==
    [ serverMessage |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverMessage = one] : one \in SampleLists(OneServerMessage) }

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

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp ==
    \A message \in CheckedRbcHeaderComp :
        LET read == DecodeRbcHeaderComp(EncodeRbcHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Affected Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripAffectedOrdGrpComp ==
    \A message \in CheckedAffectedOrdGrpComp :
        LET read == DecodeAffectedOrdGrpComp(EncodeAffectedOrdGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderBroadcast ==
    \A message \in CheckedDeleteOrderBroadcast :
        LET read == DecodeDeleteOrderBroadcast(EncodeDeleteOrderBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp ==
    \A message \in CheckedNotifHeaderComp :
        LET read == DecodeNotifHeaderComp(EncodeNotifHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Forced Logout Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripForcedLogoutNotification ==
    \A message \in CheckedForcedLogoutNotification :
        LET read == DecodeForcedLogoutNotification(EncodeForcedLogoutNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp2 ==
    \A message \in CheckedNotifHeaderComp2 :
        LET read == DecodeNotifHeaderComp2(EncodeNotifHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatNotification ==
    \A message \in CheckedHeartbeatNotification :
        LET read == DecodeHeartbeatNotification(EncodeHeartbeatNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp ==
    \A message \in CheckedResponseHeaderComp :
        LET read == DecodeResponseHeaderComp(EncodeResponseHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponse ==
    \A message \in CheckedLogonResponse :
        LET read == DecodeLogonResponse(EncodeLogonResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp2 ==
    \A message \in CheckedResponseHeaderComp2 :
        LET read == DecodeResponseHeaderComp2(EncodeResponseHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutResponse ==
    \A message \in CheckedLogoutResponse :
        LET read == DecodeLogoutResponse(EncodeLogoutResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp2 ==
    \A message \in CheckedRbcHeaderComp2 :
        LET read == DecodeRbcHeaderComp2(EncodeRbcHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGrpComp ==
    \A message \in CheckedFillsGrpComp :
        LET read == DecodeFillsGrpComp(EncodeFillsGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Exec Report Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecReportBroadcast ==
    \A message \in CheckedOrderExecReportBroadcast :
        LET read == DecodeOrderExecReportBroadcast(EncodeOrderExecReportBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp3 ==
    \A message \in CheckedNotifHeaderComp3 :
        LET read == DecodeNotifHeaderComp3(EncodeNotifHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partition Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripPartitionGrpComp ==
    \A message \in CheckedPartitionGrpComp :
        LET read == DecodePartitionGrpComp(EncodePartitionGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Partition List Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripPartitionListNotification ==
    \A message \in CheckedPartitionListNotification :
        LET read == DecodePartitionListNotification(EncodePartitionListNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp3 ==
    \A message \in CheckedResponseHeaderComp3 :
        LET read == DecodeResponseHeaderComp3(EncodeResponseHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripReject ==
    \A message \in CheckedReject :
        LET read == DecodeReject(EncodeReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp4 ==
    \A message \in CheckedNotifHeaderComp4 :
        LET read == DecodeNotifHeaderComp4(EncodeNotifHeaderComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sessions Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionsGrpComp ==
    \A message \in CheckedSessionsGrpComp :
        LET read == DecodeSessionsGrpComp(EncodeSessionsGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session List Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionListNotification ==
    \A message \in CheckedSessionListNotification :
        LET read == DecodeSessionListNotification(EncodeSessionListNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp3 ==
    \A message \in CheckedRbcHeaderComp3 :
        LET read == DecodeRbcHeaderComp3(EncodeRbcHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Status Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionStatusBroadcast ==
    \A message \in CheckedSessionStatusBroadcast :
        LET read == DecodeSessionStatusBroadcast(EncodeSessionStatusBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Message decodes back to what was encoded, and leaves nothing over *)
RoundTripServerMessage ==
    \A message \in CheckedServerMessage :
        LET read == DecodeServerMessage(EncodeServerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Server Payload is selected by the Template Id it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Body Len is written from the bytes it frames *)
FramesServerMessage ==
    \A message \in CheckedServerMessage :
        LET bytes == EncodeServerMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
