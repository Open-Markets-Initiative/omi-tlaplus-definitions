-------------------- MODULE BseIndia_Eti_v1_6_14_Server --------------------
(***************************************************************************)
(* BSE Limited Enhanced Trading Interface v1.6.14                          *)
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
(* Note: Alignment Padding pads to a 8 byte boundary: it is read as the    *)
(* bytes left to the end of the frame, and the frame's length is trusted   *)
(* to keep that boundary.                                                  *)
(*                                                                         *)
(* Note: Broadcast Error Notification fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Debt Inquiry Response fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete All Order Broadcast fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete All Order Nr Response fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete All Order Quote Event Broadcast fills what is left of the  *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Delete All Order Response fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete All Quote Broadcast fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete All Quote Response fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete Order Broadcast fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Order Nr Response fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Order Response fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Forced Logout Notification fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Gateway Response fills what is left of the frame Body Len states, *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Gw Order Acknowledgement fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Heartbeat Notification fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Inquire Session List Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Logon Response fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logout Response fills what is left of the frame Body Len states,  *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Mass Quote Response fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Modify Order Nr Response fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Modify Order Response fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Multi Leg Exec Report Broadcast fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Multi Leg Exec Response fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Multi Leg Order Reject fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Nr Response fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Response fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: News Broadcast fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Order Exec Notification fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Order Exec Report Broadcast fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Order Exec Response fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Quote Exec Report Broadcast fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Quote Execution Report fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Reject fills what is left of the frame Body Len states, which is  *)
(* what it is read from.                                                   *)
(*                                                                         *)
(* Note: Retransmit Me Message Response fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Retransmit Response fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Risk Collateral Alert Admin Broadcast fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Risk Collateral Alert Broadcast fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Risk Notification Broadcast fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Service Availability Broadcast fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Session Password Change Response fills what is left of the frame  *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Session Registration Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Subscribe Response fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tm Trading Session Status Broadcast fills what is left of the     *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Throttle Update Notification fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Trade Broadcast fills what is left of the frame Body Len states,  *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Trade Enhancement Broadcast fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Trading Session Status Broadcast fills what is left of the frame  *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Unsubscribe Response fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Login Response fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Logout Response fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Password Change Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
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
(* Broadcast Error Notification                                            *)
(***************************************************************************)

BroadcastErrorNotification ==
    [ filler4          : Sample(2),
      notifHeaderComp  : NotifHeaderComp,
      applIdStatus     : Sample(4),
      refApplSubId     : Sample(4),
      refApplId        : Sample(1),
      sessionStatus    : Sample(1),
      pad4             : Sample(4),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeBroadcastErrorNotification(message) ==
    message.filler4
        \o EncodeNotifHeaderComp(message.notifHeaderComp)
        \o message.applIdStatus
        \o message.refApplSubId
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.refApplId
        \o message.sessionStatus
        \o message.pad4
        \o message.varText
        \o message.alignmentPadding

DecodeBroadcastErrorNotification(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp(filler4.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET applIdStatus == ReadBytes(notifHeaderComp.rest, 4) IN IF ~applIdStatus.ok THEN Fail ELSE
    LET refApplSubId == ReadBytes(applIdStatus.rest, 4) IN IF ~refApplSubId.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(refApplSubId.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET refApplId == ReadBytes(varTextLen.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET sessionStatus == ReadBytes(refApplId.rest, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET pad4 == ReadBytes(sessionStatus.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET varText == ReadBytes(pad4.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4          |-> filler4.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         applIdStatus     |-> applIdStatus.value,
         refApplSubId     |-> refApplSubId.value,
         refApplId        |-> refApplId.value,
         sessionStatus    |-> sessionStatus.value,
         pad4             |-> pad4.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroBroadcastErrorNotification ==
    [ filler4          |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp,
      applIdStatus     |-> [i \in 1 .. 4 |-> 0],
      refApplSubId     |-> [i \in 1 .. 4 |-> 0],
      refApplId        |-> [i \in 1 .. 1 |-> 0],
      sessionStatus    |-> [i \in 1 .. 1 |-> 0],
      pad4             |-> [i \in 1 .. 4 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Broadcast Error Notification at zero, then each field in turn at the values it is checked at *)
CheckedBroadcastErrorNotification ==
    { ZeroBroadcastErrorNotification }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.applIdStatus = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp ==
    { ZeroNrResponseHeaderMeComp }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Debt Inquiry Response: 114 bytes                                        *)
(***************************************************************************)

DebtInquiryResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp,
      underlyingPx           : Sample(8),
      yield                  : Sample(8),
      accruedInterestAmt     : Sample(8),
      grossTradeAmt          : Sample(8),
      underlyingDirtyPrice   : Sample(8),
      securityId             : Sample(8),
      orderQty               : Sample(4),
      settlType              : Sample(4) ]

EncodeDebtInquiryResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp(message.nrResponseHeaderMeComp)
        \o message.underlyingPx
        \o message.yield
        \o message.accruedInterestAmt
        \o message.grossTradeAmt
        \o message.underlyingDirtyPrice
        \o message.securityId
        \o message.orderQty
        \o message.settlType

DecodeDebtInquiryResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET yield == ReadBytes(underlyingPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET accruedInterestAmt == ReadBytes(yield.rest, 8) IN IF ~accruedInterestAmt.ok THEN Fail ELSE
    LET grossTradeAmt == ReadBytes(accruedInterestAmt.rest, 8) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(grossTradeAmt.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET securityId == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET settlType == ReadBytes(orderQty.rest, 4) IN IF ~settlType.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         underlyingPx           |-> underlyingPx.value,
         yield                  |-> yield.value,
         accruedInterestAmt     |-> accruedInterestAmt.value,
         grossTradeAmt          |-> grossTradeAmt.value,
         underlyingDirtyPrice   |-> underlyingDirtyPrice.value,
         securityId             |-> securityId.value,
         orderQty               |-> orderQty.value,
         settlType              |-> settlType.value ], settlType.rest)

ZeroDebtInquiryResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp,
      underlyingPx           |-> [i \in 1 .. 8 |-> 0],
      yield                  |-> [i \in 1 .. 8 |-> 0],
      accruedInterestAmt     |-> [i \in 1 .. 8 |-> 0],
      grossTradeAmt          |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice   |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      settlType              |-> [i \in 1 .. 4 |-> 0] ]

(* Debt Inquiry Response at zero, then each field in turn at the values it is checked at *)
CheckedDebtInquiryResponse ==
    { ZeroDebtInquiryResponse }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroDebtInquiryResponse EXCEPT !.settlType = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp ==
    { ZeroRbcHeaderMeComp }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Not Affected Orders Grp Comp: 16 bytes                                  *)
(***************************************************************************)

NotAffectedOrdersGrpComp ==
    [ notAffectedOrderId : Sample(8),
      notAffOrigClOrdId  : Sample(8) ]

EncodeNotAffectedOrdersGrpComp(message) ==
    message.notAffectedOrderId
        \o message.notAffOrigClOrdId

DecodeNotAffectedOrdersGrpComp(bytes) ==
    LET notAffectedOrderId == ReadBytes(bytes, 8) IN IF ~notAffectedOrderId.ok THEN Fail ELSE
    LET notAffOrigClOrdId == ReadBytes(notAffectedOrderId.rest, 8) IN IF ~notAffOrigClOrdId.ok THEN Fail ELSE
    Ok([ notAffectedOrderId |-> notAffectedOrderId.value,
         notAffOrigClOrdId  |-> notAffOrigClOrdId.value ], notAffOrigClOrdId.rest)

ZeroNotAffectedOrdersGrpComp ==
    [ notAffectedOrderId |-> [i \in 1 .. 8 |-> 0],
      notAffOrigClOrdId  |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Orders Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedOrdersGrpComp ==
    { ZeroNotAffectedOrdersGrpComp }
        \cup { [ZeroNotAffectedOrdersGrpComp EXCEPT !.notAffectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNotAffectedOrdersGrpComp EXCEPT !.notAffOrigClOrdId = one] : one \in Sample(8) }

(* A run of Not Affected Orders Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedOrdersGrpCompList(_)
EncodeNotAffectedOrdersGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedOrdersGrpComp(Head(messages)) \o EncodeNotAffectedOrdersGrpCompList(Tail(messages))

(* As many Not Affected Orders Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedOrdersGrpCompList(_, _)
ReadNotAffectedOrdersGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedOrdersGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedOrdersGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Orders Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedOrdersGrpComp == { ZeroNotAffectedOrdersGrpComp }

(***************************************************************************)
(* Delete All Order Broadcast                                              *)
(***************************************************************************)

DeleteAllOrderBroadcast ==
    [ filler4                      : Sample(2),
      rbcHeaderMeComp              : RbcHeaderMeComp,
      massActionReportId           : Sample(8),
      securityId                   : Sample(8),
      marketSegmentId              : Sample(4),
      targetPartyIdSessionId       : Sample(4),
      targetPartyIdExecutingTrader : Sample(4),
      partyIdEnteringTrader        : Sample(4),
      algoId                       : Sample(16),
      filler1                      : Sample(8),
      filler2                      : Sample(4),
      filler3                      : Sample(4),
      partyIdEnteringFirm          : Sample(1),
      massActionReason             : Sample(1),
      execInst                     : Sample(1),
      pad3                         : Sample(3),
      notAffectedOrdersGrpComp     : SampleLists(OneNotAffectedOrdersGrpComp) ]

EncodeDeleteAllOrderBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o message.algoId
        \o message.filler1
        \o message.filler2
        \o message.filler3
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o message.partyIdEnteringFirm
        \o message.massActionReason
        \o message.execInst
        \o message.pad3
        \o EncodeNotAffectedOrdersGrpCompList(message.notAffectedOrdersGrpComp)

DecodeDeleteAllOrderBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(targetPartyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET algoId == ReadBytes(partyIdEnteringTrader.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET filler1 == ReadBytes(algoId.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler3 == ReadBytes(filler2.rest, 4) IN IF ~filler3.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(filler3.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(noNotAffectedOrders.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET execInst == ReadBytes(massActionReason.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET pad3 == ReadBytes(execInst.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpCompList(pad3.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    Ok([ filler4                      |-> filler4.value,
         rbcHeaderMeComp              |-> rbcHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         securityId                   |-> securityId.value,
         marketSegmentId              |-> marketSegmentId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         partyIdEnteringTrader        |-> partyIdEnteringTrader.value,
         algoId                       |-> algoId.value,
         filler1                      |-> filler1.value,
         filler2                      |-> filler2.value,
         filler3                      |-> filler3.value,
         partyIdEnteringFirm          |-> partyIdEnteringFirm.value,
         massActionReason             |-> massActionReason.value,
         execInst                     |-> execInst.value,
         pad3                         |-> pad3.value,
         notAffectedOrdersGrpComp     |-> notAffectedOrdersGrpComp.value ], notAffectedOrdersGrpComp.rest)

ZeroDeleteAllOrderBroadcast ==
    [ filler4                      |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader        |-> [i \in 1 .. 4 |-> 0],
      algoId                       |-> [i \in 1 .. 16 |-> 0],
      filler1                      |-> [i \in 1 .. 8 |-> 0],
      filler2                      |-> [i \in 1 .. 4 |-> 0],
      filler3                      |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringFirm          |-> [i \in 1 .. 1 |-> 0],
      massActionReason             |-> [i \in 1 .. 1 |-> 0],
      execInst                     |-> [i \in 1 .. 1 |-> 0],
      pad3                         |-> [i \in 1 .. 3 |-> 0],
      notAffectedOrdersGrpComp     |-> << >> ]

(* Delete All Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderBroadcast ==
    { ZeroDeleteAllOrderBroadcast }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.filler3 = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp2 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp2(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp2(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp2 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp2 ==
    { ZeroNrResponseHeaderMeComp2 }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Delete All Order Nr Response: 66 bytes                                  *)
(***************************************************************************)

DeleteAllOrderNrResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp2,
      massActionReportId     : Sample(8) ]

EncodeDeleteAllOrderNrResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp2(message.nrResponseHeaderMeComp)
        \o message.massActionReportId

DecodeDeleteAllOrderNrResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp2(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         massActionReportId     |-> massActionReportId.value ], massActionReportId.rest)

ZeroDeleteAllOrderNrResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp2,
      massActionReportId     |-> [i \in 1 .. 8 |-> 0] ]

(* Delete All Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderNrResponse ==
    { ZeroDeleteAllOrderNrResponse }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp2 }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp2 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp2(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp2(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp2 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp2 ==
    { ZeroRbcHeaderMeComp2 }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Delete All Order Quote Event Broadcast: 74 bytes                        *)
(***************************************************************************)

DeleteAllOrderQuoteEventBroadcast ==
    [ filler4            : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp2,
      massActionReportId : Sample(8),
      securityId         : Sample(8),
      marketSegmentId    : Sample(4),
      massActionReason   : Sample(1),
      execInst           : Sample(1),
      pad2               : Sample(2) ]

EncodeDeleteAllOrderQuoteEventBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp2(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.marketSegmentId
        \o message.massActionReason
        \o message.execInst
        \o message.pad2

DecodeDeleteAllOrderQuoteEventBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp2(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(marketSegmentId.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET execInst == ReadBytes(massActionReason.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET pad2 == ReadBytes(execInst.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         massActionReportId |-> massActionReportId.value,
         securityId         |-> securityId.value,
         marketSegmentId    |-> marketSegmentId.value,
         massActionReason   |-> massActionReason.value,
         execInst           |-> execInst.value,
         pad2               |-> pad2.value ], pad2.rest)

ZeroDeleteAllOrderQuoteEventBroadcast ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp2,
      massActionReportId |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      massActionReason   |-> [i \in 1 .. 1 |-> 0],
      execInst           |-> [i \in 1 .. 1 |-> 0],
      pad2               |-> [i \in 1 .. 2 |-> 0] ]

(* Delete All Order Quote Event Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderQuoteEventBroadcast ==
    { ZeroDeleteAllOrderQuoteEventBroadcast }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp2 }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp ==
    { ZeroResponseHeaderMeComp }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Affected Orders Grp Comp: 16 bytes                                  *)
(***************************************************************************)

NotAffectedOrdersGrpComp2 ==
    [ notAffectedOrderId : Sample(8),
      notAffOrigClOrdId  : Sample(8) ]

EncodeNotAffectedOrdersGrpComp2(message) ==
    message.notAffectedOrderId
        \o message.notAffOrigClOrdId

DecodeNotAffectedOrdersGrpComp2(bytes) ==
    LET notAffectedOrderId == ReadBytes(bytes, 8) IN IF ~notAffectedOrderId.ok THEN Fail ELSE
    LET notAffOrigClOrdId == ReadBytes(notAffectedOrderId.rest, 8) IN IF ~notAffOrigClOrdId.ok THEN Fail ELSE
    Ok([ notAffectedOrderId |-> notAffectedOrderId.value,
         notAffOrigClOrdId  |-> notAffOrigClOrdId.value ], notAffOrigClOrdId.rest)

ZeroNotAffectedOrdersGrpComp2 ==
    [ notAffectedOrderId |-> [i \in 1 .. 8 |-> 0],
      notAffOrigClOrdId  |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Orders Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedOrdersGrpComp2 ==
    { ZeroNotAffectedOrdersGrpComp2 }
        \cup { [ZeroNotAffectedOrdersGrpComp2 EXCEPT !.notAffectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNotAffectedOrdersGrpComp2 EXCEPT !.notAffOrigClOrdId = one] : one \in Sample(8) }

(* A run of Not Affected Orders Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedOrdersGrpComp2List(_)
EncodeNotAffectedOrdersGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedOrdersGrpComp2(Head(messages)) \o EncodeNotAffectedOrdersGrpComp2List(Tail(messages))

(* As many Not Affected Orders Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedOrdersGrpComp2List(_, _)
ReadNotAffectedOrdersGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedOrdersGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedOrdersGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Orders Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedOrdersGrpComp2 == { ZeroNotAffectedOrdersGrpComp2 }

(***************************************************************************)
(* Delete All Order Response                                               *)
(***************************************************************************)

DeleteAllOrderResponse ==
    [ filler4                  : Sample(2),
      responseHeaderMeComp     : ResponseHeaderMeComp,
      massActionReportId       : Sample(8),
      pad6                     : Sample(6),
      notAffectedOrdersGrpComp : SampleLists(OneNotAffectedOrdersGrpComp2) ]

EncodeDeleteAllOrderResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp(message.responseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o message.pad6
        \o EncodeNotAffectedOrdersGrpComp2List(message.notAffectedOrdersGrpComp)

DecodeDeleteAllOrderResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noNotAffectedOrders.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpComp2List(pad6.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    Ok([ filler4                  |-> filler4.value,
         responseHeaderMeComp     |-> responseHeaderMeComp.value,
         massActionReportId       |-> massActionReportId.value,
         pad6                     |-> pad6.value,
         notAffectedOrdersGrpComp |-> notAffectedOrdersGrpComp.value ], notAffectedOrdersGrpComp.rest)

ZeroDeleteAllOrderResponse ==
    [ filler4                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp     |-> ZeroResponseHeaderMeComp,
      massActionReportId       |-> [i \in 1 .. 8 |-> 0],
      pad6                     |-> [i \in 1 .. 6 |-> 0],
      notAffectedOrdersGrpComp |-> << >> ]

(* Delete All Order Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderResponse ==
    { ZeroDeleteAllOrderResponse }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp2) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp3 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp3(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp3(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp3 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp3 ==
    { ZeroRbcHeaderMeComp3 }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Not Affected Securities Grp Comp: 8 bytes                               *)
(***************************************************************************)

NotAffectedSecuritiesGrpComp ==
    [ notAffectedSecurityId : Sample(8) ]

EncodeNotAffectedSecuritiesGrpComp(message) ==
    message.notAffectedSecurityId

DecodeNotAffectedSecuritiesGrpComp(bytes) ==
    LET notAffectedSecurityId == ReadBytes(bytes, 8) IN IF ~notAffectedSecurityId.ok THEN Fail ELSE
    Ok([ notAffectedSecurityId |-> notAffectedSecurityId.value ], notAffectedSecurityId.rest)

ZeroNotAffectedSecuritiesGrpComp ==
    [ notAffectedSecurityId |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Securities Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedSecuritiesGrpComp ==
    { ZeroNotAffectedSecuritiesGrpComp }
        \cup { [ZeroNotAffectedSecuritiesGrpComp EXCEPT !.notAffectedSecurityId = one] : one \in Sample(8) }

(* A run of Not Affected Securities Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedSecuritiesGrpCompList(_)
EncodeNotAffectedSecuritiesGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedSecuritiesGrpComp(Head(messages)) \o EncodeNotAffectedSecuritiesGrpCompList(Tail(messages))

(* As many Not Affected Securities Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedSecuritiesGrpCompList(_, _)
ReadNotAffectedSecuritiesGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedSecuritiesGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedSecuritiesGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Securities Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedSecuritiesGrpComp == { ZeroNotAffectedSecuritiesGrpComp }

(***************************************************************************)
(* Delete All Quote Broadcast                                              *)
(***************************************************************************)

DeleteAllQuoteBroadcast ==
    [ filler4                      : Sample(2),
      rbcHeaderMeComp              : RbcHeaderMeComp3,
      massActionReportId           : Sample(8),
      securityId                   : Sample(8),
      marketSegmentId              : Sample(4),
      targetPartyIdSessionId       : Sample(4),
      partyIdEnteringTrader        : Sample(4),
      targetPartyIdExecutingTrader : Sample(4),
      algoId                       : Sample(16),
      filler1                      : Sample(8),
      filler2                      : Sample(4),
      filler3                      : Sample(4),
      massActionReason             : Sample(1),
      partyIdEnteringFirm          : Sample(1),
      targetPartyIdDeskId          : Sample(3),
      pad1                         : Sample(1),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp) ]

EncodeDeleteAllQuoteBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp3(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.partyIdEnteringTrader
        \o message.targetPartyIdExecutingTrader
        \o message.algoId
        \o message.filler1
        \o message.filler2
        \o message.filler3
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.massActionReason
        \o message.partyIdEnteringFirm
        \o message.targetPartyIdDeskId
        \o message.pad1
        \o EncodeNotAffectedSecuritiesGrpCompList(message.notAffectedSecuritiesGrpComp)

DecodeDeleteAllQuoteBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp3(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(partyIdEnteringTrader.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET algoId == ReadBytes(targetPartyIdExecutingTrader.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET filler1 == ReadBytes(algoId.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler3 == ReadBytes(filler2.rest, 4) IN IF ~filler3.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(filler3.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(noNotAffectedSecurities.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(massActionReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET targetPartyIdDeskId == ReadBytes(partyIdEnteringFirm.rest, 3) IN IF ~targetPartyIdDeskId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(targetPartyIdDeskId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpCompList(pad1.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ filler4                      |-> filler4.value,
         rbcHeaderMeComp              |-> rbcHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         securityId                   |-> securityId.value,
         marketSegmentId              |-> marketSegmentId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         partyIdEnteringTrader        |-> partyIdEnteringTrader.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         algoId                       |-> algoId.value,
         filler1                      |-> filler1.value,
         filler2                      |-> filler2.value,
         filler3                      |-> filler3.value,
         massActionReason             |-> massActionReason.value,
         partyIdEnteringFirm          |-> partyIdEnteringFirm.value,
         targetPartyIdDeskId          |-> targetPartyIdDeskId.value,
         pad1                         |-> pad1.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroDeleteAllQuoteBroadcast ==
    [ filler4                      |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp3,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      algoId                       |-> [i \in 1 .. 16 |-> 0],
      filler1                      |-> [i \in 1 .. 8 |-> 0],
      filler2                      |-> [i \in 1 .. 4 |-> 0],
      filler3                      |-> [i \in 1 .. 4 |-> 0],
      massActionReason             |-> [i \in 1 .. 1 |-> 0],
      partyIdEnteringFirm          |-> [i \in 1 .. 1 |-> 0],
      targetPartyIdDeskId          |-> [i \in 1 .. 3 |-> 0],
      pad1                         |-> [i \in 1 .. 1 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Delete All Quote Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteBroadcast ==
    { ZeroDeleteAllQuoteBroadcast }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp3 }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.filler3 = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdDeskId = one] : one \in Sample(3) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp3 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp3(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp3(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp3 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp3 ==
    { ZeroNrResponseHeaderMeComp3 }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Not Affected Securities Grp Comp: 8 bytes                               *)
(***************************************************************************)

NotAffectedSecuritiesGrpComp2 ==
    [ notAffectedSecurityId : Sample(8) ]

EncodeNotAffectedSecuritiesGrpComp2(message) ==
    message.notAffectedSecurityId

DecodeNotAffectedSecuritiesGrpComp2(bytes) ==
    LET notAffectedSecurityId == ReadBytes(bytes, 8) IN IF ~notAffectedSecurityId.ok THEN Fail ELSE
    Ok([ notAffectedSecurityId |-> notAffectedSecurityId.value ], notAffectedSecurityId.rest)

ZeroNotAffectedSecuritiesGrpComp2 ==
    [ notAffectedSecurityId |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Securities Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedSecuritiesGrpComp2 ==
    { ZeroNotAffectedSecuritiesGrpComp2 }
        \cup { [ZeroNotAffectedSecuritiesGrpComp2 EXCEPT !.notAffectedSecurityId = one] : one \in Sample(8) }

(* A run of Not Affected Securities Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedSecuritiesGrpComp2List(_)
EncodeNotAffectedSecuritiesGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedSecuritiesGrpComp2(Head(messages)) \o EncodeNotAffectedSecuritiesGrpComp2List(Tail(messages))

(* As many Not Affected Securities Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedSecuritiesGrpComp2List(_, _)
ReadNotAffectedSecuritiesGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedSecuritiesGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedSecuritiesGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Securities Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedSecuritiesGrpComp2 == { ZeroNotAffectedSecuritiesGrpComp2 }

(***************************************************************************)
(* Delete All Quote Response                                               *)
(***************************************************************************)

DeleteAllQuoteResponse ==
    [ filler4                      : Sample(2),
      nrResponseHeaderMeComp       : NrResponseHeaderMeComp3,
      massActionReportId           : Sample(8),
      pad6                         : Sample(6),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp2) ]

EncodeDeleteAllQuoteResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp3(message.nrResponseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.pad6
        \o EncodeNotAffectedSecuritiesGrpComp2List(message.notAffectedSecuritiesGrpComp)

DecodeDeleteAllQuoteResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp3(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noNotAffectedSecurities.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpComp2List(pad6.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ filler4                      |-> filler4.value,
         nrResponseHeaderMeComp       |-> nrResponseHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         pad6                         |-> pad6.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroDeleteAllQuoteResponse ==
    [ filler4                      |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp       |-> ZeroNrResponseHeaderMeComp3,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      pad6                         |-> [i \in 1 .. 6 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Delete All Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteResponse ==
    { ZeroDeleteAllQuoteResponse }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp3 }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp2) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp4 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp4(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp4(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp4 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp4 ==
    { ZeroRbcHeaderMeComp4 }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Delete Order Broadcast: 122 bytes                                       *)
(***************************************************************************)

DeleteOrderBroadcast ==
    [ filler4               : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp4,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      messageTag            : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      marketSegmentId       : Sample(4),
      partyIdEnteringTrader : Sample(4),
      execRestatementReason : Sample(2),
      partyIdEnteringFirm   : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      productComplex        : Sample(1),
      side                  : Sample(1),
      pad5                  : Sample(5) ]

EncodeDeleteOrderBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp4(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.messageTag
        \o message.cumQty
        \o message.cxlQty
        \o message.marketSegmentId
        \o message.partyIdEnteringTrader
        \o message.execRestatementReason
        \o message.partyIdEnteringFirm
        \o message.ordStatus
        \o message.execType
        \o message.productComplex
        \o message.side
        \o message.pad5

DecodeDeleteOrderBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp4(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(execId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET cumQty == ReadBytes(messageTag.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(cxlQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdEnteringTrader.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad5 == ReadBytes(side.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         messageTag            |-> messageTag.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         marketSegmentId       |-> marketSegmentId.value,
         partyIdEnteringTrader |-> partyIdEnteringTrader.value,
         execRestatementReason |-> execRestatementReason.value,
         partyIdEnteringFirm   |-> partyIdEnteringFirm.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         productComplex        |-> productComplex.value,
         side                  |-> side.value,
         pad5                  |-> pad5.value ], pad5.rest)

ZeroDeleteOrderBroadcast ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp4,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      messageTag            |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      partyIdEnteringFirm   |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      pad5                  |-> [i \in 1 .. 5 |-> 0] ]

(* Delete Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderBroadcast ==
    { ZeroDeleteOrderBroadcast }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp4 }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp4 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp4(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp4(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp4 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp4 ==
    { ZeroNrResponseHeaderMeComp4 }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Delete Order Nr Response: 114 bytes                                     *)
(***************************************************************************)

DeleteOrderNrResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp4,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2),
      productComplex         : Sample(1),
      pad3                   : Sample(3) ]

EncodeDeleteOrderNrResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp4(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.cumQty
        \o message.cxlQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.pad3

DecodeDeleteOrderNrResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp4(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(execId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(cxlQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad3 == ReadBytes(productComplex.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value,
         productComplex         |-> productComplex.value,
         pad3                   |-> pad3.value ], pad3.rest)

ZeroDeleteOrderNrResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp4,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

(* Delete Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderNrResponse ==
    { ZeroDeleteOrderNrResponse }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp4 }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp2 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp2(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp2(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp2 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp2 ==
    { ZeroResponseHeaderMeComp2 }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Response: 130 bytes                                        *)
(***************************************************************************)

DeleteOrderResponse ==
    [ filler4               : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp2,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2),
      productComplex        : Sample(1),
      pad3                  : Sample(3) ]

EncodeDeleteOrderResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp2(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.cumQty
        \o message.cxlQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.pad3

DecodeDeleteOrderResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp2(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(execId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(cxlQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad3 == ReadBytes(productComplex.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value,
         productComplex        |-> productComplex.value,
         pad3                  |-> pad3.value ], pad3.rest)

ZeroDeleteOrderResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp2,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0] ]

(* Delete Order Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderResponse ==
    { ZeroDeleteOrderResponse }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp2 }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Forced Logout Notification                                              *)
(***************************************************************************)

ForcedLogoutNotification ==
    [ filler4          : Sample(2),
      notifHeaderComp  : NotifHeaderComp2,
      pad6             : Sample(6),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeForcedLogoutNotification(message) ==
    message.filler4
        \o EncodeNotifHeaderComp2(message.notifHeaderComp)
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.pad6
        \o message.varText
        \o message.alignmentPadding

DecodeForcedLogoutNotification(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp2(filler4.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(notifHeaderComp.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET pad6 == ReadBytes(varTextLen.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET varText == ReadBytes(pad6.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4          |-> filler4.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         pad6             |-> pad6.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroForcedLogoutNotification ==
    [ filler4          |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp2,
      pad6             |-> [i \in 1 .. 6 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Forced Logout Notification at zero, then each field in turn at the values it is checked at *)
CheckedForcedLogoutNotification ==
    { ZeroForcedLogoutNotification }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp2 }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp ==
    { ZeroResponseHeaderComp }
        \cup { [ZeroResponseHeaderComp EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Gateway Response: 98 bytes                                              *)
(***************************************************************************)

GatewayResponse ==
    [ filler4               : Sample(2),
      responseHeaderComp    : ResponseHeaderComp,
      gatewayId             : Sample(4),
      gatewaySubId          : Sample(4),
      secondaryGatewayId    : Sample(4),
      secondaryGatewaySubId : Sample(4),
      sessionMode           : Sample(1),
      tradSesMode           : Sample(1),
      securityKey           : Sample(32),
      initializationVector  : Sample(16),
      pad6                  : Sample(6) ]

EncodeGatewayResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp(message.responseHeaderComp)
        \o message.gatewayId
        \o message.gatewaySubId
        \o message.secondaryGatewayId
        \o message.secondaryGatewaySubId
        \o message.sessionMode
        \o message.tradSesMode
        \o message.securityKey
        \o message.initializationVector
        \o message.pad6

DecodeGatewayResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET gatewayId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~gatewayId.ok THEN Fail ELSE
    LET gatewaySubId == ReadBytes(gatewayId.rest, 4) IN IF ~gatewaySubId.ok THEN Fail ELSE
    LET secondaryGatewayId == ReadBytes(gatewaySubId.rest, 4) IN IF ~secondaryGatewayId.ok THEN Fail ELSE
    LET secondaryGatewaySubId == ReadBytes(secondaryGatewayId.rest, 4) IN IF ~secondaryGatewaySubId.ok THEN Fail ELSE
    LET sessionMode == ReadBytes(secondaryGatewaySubId.rest, 1) IN IF ~sessionMode.ok THEN Fail ELSE
    LET tradSesMode == ReadBytes(sessionMode.rest, 1) IN IF ~tradSesMode.ok THEN Fail ELSE
    LET securityKey == ReadBytes(tradSesMode.rest, 32) IN IF ~securityKey.ok THEN Fail ELSE
    LET initializationVector == ReadBytes(securityKey.rest, 16) IN IF ~initializationVector.ok THEN Fail ELSE
    LET pad6 == ReadBytes(initializationVector.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderComp    |-> responseHeaderComp.value,
         gatewayId             |-> gatewayId.value,
         gatewaySubId          |-> gatewaySubId.value,
         secondaryGatewayId    |-> secondaryGatewayId.value,
         secondaryGatewaySubId |-> secondaryGatewaySubId.value,
         sessionMode           |-> sessionMode.value,
         tradSesMode           |-> tradSesMode.value,
         securityKey           |-> securityKey.value,
         initializationVector  |-> initializationVector.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroGatewayResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp    |-> ZeroResponseHeaderComp,
      gatewayId             |-> [i \in 1 .. 4 |-> 0],
      gatewaySubId          |-> [i \in 1 .. 4 |-> 0],
      secondaryGatewayId    |-> [i \in 1 .. 4 |-> 0],
      secondaryGatewaySubId |-> [i \in 1 .. 4 |-> 0],
      sessionMode           |-> [i \in 1 .. 1 |-> 0],
      tradSesMode           |-> [i \in 1 .. 1 |-> 0],
      securityKey           |-> [i \in 1 .. 32 |-> 0],
      initializationVector  |-> [i \in 1 .. 16 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Gateway Response at zero, then each field in turn at the values it is checked at *)
CheckedGatewayResponse ==
    { ZeroGatewayResponse }
        \cup { [ZeroGatewayResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroGatewayResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp }
        \cup { [ZeroGatewayResponse EXCEPT !.gatewayId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.gatewaySubId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.secondaryGatewayId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.secondaryGatewaySubId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.sessionMode = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.tradSesMode = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.securityKey = one] : one \in Sample(32) }
        \cup { [ZeroGatewayResponse EXCEPT !.initializationVector = one] : one \in Sample(16) }
        \cup { [ZeroGatewayResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp2 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp2(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp2(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp2 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp2 ==
    { ZeroResponseHeaderComp2 }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Gw Order Acknowledgement: 50 bytes                                      *)
(***************************************************************************)

GwOrderAcknowledgement ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp2,
      primaryOrderId     : Sample(8),
      clOrdId            : Sample(8),
      messageTag         : Sample(4),
      pad4               : Sample(4) ]

EncodeGwOrderAcknowledgement(message) ==
    message.filler4
        \o EncodeResponseHeaderComp2(message.responseHeaderComp)
        \o message.primaryOrderId
        \o message.clOrdId
        \o message.messageTag
        \o message.pad4

DecodeGwOrderAcknowledgement(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp2(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET primaryOrderId == ReadBytes(responseHeaderComp.rest, 8) IN IF ~primaryOrderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(primaryOrderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(clOrdId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET pad4 == ReadBytes(messageTag.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value,
         primaryOrderId     |-> primaryOrderId.value,
         clOrdId            |-> clOrdId.value,
         messageTag         |-> messageTag.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroGwOrderAcknowledgement ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp2,
      primaryOrderId     |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 8 |-> 0],
      messageTag         |-> [i \in 1 .. 4 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Gw Order Acknowledgement at zero, then each field in turn at the values it is checked at *)
CheckedGwOrderAcknowledgement ==
    { ZeroGwOrderAcknowledgement }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp2 }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.primaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroGwOrderAcknowledgement EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Heartbeat Notification: 10 bytes                                        *)
(***************************************************************************)

HeartbeatNotification ==
    [ filler4         : Sample(2),
      notifHeaderComp : NotifHeaderComp3 ]

EncodeHeartbeatNotification(message) ==
    message.filler4
        \o EncodeNotifHeaderComp3(message.notifHeaderComp)

DecodeHeartbeatNotification(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp3(filler4.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    Ok([ filler4         |-> filler4.value,
         notifHeaderComp |-> notifHeaderComp.value ], notifHeaderComp.rest)

ZeroHeartbeatNotification ==
    [ filler4         |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp |-> ZeroNotifHeaderComp3 ]

(* Heartbeat Notification at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatNotification ==
    { ZeroHeartbeatNotification }
        \cup { [ZeroHeartbeatNotification EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroHeartbeatNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp3 }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp3 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp3(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp3(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp3 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp3 ==
    { ZeroResponseHeaderComp3 }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp3 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Sessions Grp Comp: 8 bytes                                              *)
(***************************************************************************)

SessionsGrpComp ==
    [ partyIdSessionId : Sample(4),
      sessionMode      : Sample(1),
      sessionSubMode   : Sample(1),
      pad2             : Sample(2) ]

EncodeSessionsGrpComp(message) ==
    message.partyIdSessionId
        \o message.sessionMode
        \o message.sessionSubMode
        \o message.pad2

DecodeSessionsGrpComp(bytes) ==
    LET partyIdSessionId == ReadBytes(bytes, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET sessionMode == ReadBytes(partyIdSessionId.rest, 1) IN IF ~sessionMode.ok THEN Fail ELSE
    LET sessionSubMode == ReadBytes(sessionMode.rest, 1) IN IF ~sessionSubMode.ok THEN Fail ELSE
    LET pad2 == ReadBytes(sessionSubMode.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ partyIdSessionId |-> partyIdSessionId.value,
         sessionMode      |-> sessionMode.value,
         sessionSubMode   |-> sessionSubMode.value,
         pad2             |-> pad2.value ], pad2.rest)

ZeroSessionsGrpComp ==
    [ partyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      sessionMode      |-> [i \in 1 .. 1 |-> 0],
      sessionSubMode   |-> [i \in 1 .. 1 |-> 0],
      pad2             |-> [i \in 1 .. 2 |-> 0] ]

(* Sessions Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSessionsGrpComp ==
    { ZeroSessionsGrpComp }
        \cup { [ZeroSessionsGrpComp EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.sessionMode = one] : one \in Sample(1) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.sessionSubMode = one] : one \in Sample(1) }
        \cup { [ZeroSessionsGrpComp EXCEPT !.pad2 = one] : one \in Sample(2) }

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
(* Inquire Session List Response                                           *)
(***************************************************************************)

InquireSessionListResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp3,
      pad6               : Sample(6),
      sessionsGrpComp    : SampleLists(OneSessionsGrpComp) ]

EncodeInquireSessionListResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp3(message.responseHeaderComp)
        \o EncodeUIntLE(Len(message.sessionsGrpComp), 2)
        \o message.pad6
        \o EncodeSessionsGrpCompList(message.sessionsGrpComp)

DecodeInquireSessionListResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp3(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET noSessions == ReadUIntLE(responseHeaderComp.rest, 2) IN IF ~noSessions.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noSessions.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET sessionsGrpComp == ReadSessionsGrpCompList(pad6.rest, noSessions.value) IN IF ~sessionsGrpComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value,
         pad6               |-> pad6.value,
         sessionsGrpComp    |-> sessionsGrpComp.value ], sessionsGrpComp.rest)

ZeroInquireSessionListResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp3,
      pad6               |-> [i \in 1 .. 6 |-> 0],
      sessionsGrpComp    |-> << >> ]

(* Inquire Session List Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListResponse ==
    { ZeroInquireSessionListResponse }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp3 }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.sessionsGrpComp = one] : one \in SampleLists(OneSessionsGrpComp) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp4 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp4(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp4(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp4 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp4 ==
    { ZeroResponseHeaderComp4 }
        \cup { [ZeroResponseHeaderComp4 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp4 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Response: 98 bytes                                                *)
(***************************************************************************)

LogonResponse ==
    [ filler4                 : Sample(2),
      responseHeaderComp      : ResponseHeaderComp4,
      throttleTimeInterval    : Sample(8),
      lastLoginTime           : Sample(8),
      lastLoginIp             : Sample(4),
      throttleNoMsgs          : Sample(4),
      throttleDisconnectLimit : Sample(4),
      heartBtInt              : Sample(4),
      sessionInstanceId       : Sample(4),
      tradSesMode             : Sample(1),
      noOfPartition           : Sample(1),
      daysLeftForPasswdExpiry : Sample(1),
      graceLoginsLeft         : Sample(1),
      defaultCstmApplVerId    : Sample(30),
      pad2                    : Sample(2) ]

EncodeLogonResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp4(message.responseHeaderComp)
        \o message.throttleTimeInterval
        \o message.lastLoginTime
        \o message.lastLoginIp
        \o message.throttleNoMsgs
        \o message.throttleDisconnectLimit
        \o message.heartBtInt
        \o message.sessionInstanceId
        \o message.tradSesMode
        \o message.noOfPartition
        \o message.daysLeftForPasswdExpiry
        \o message.graceLoginsLeft
        \o message.defaultCstmApplVerId
        \o message.pad2

DecodeLogonResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp4(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET throttleTimeInterval == ReadBytes(responseHeaderComp.rest, 8) IN IF ~throttleTimeInterval.ok THEN Fail ELSE
    LET lastLoginTime == ReadBytes(throttleTimeInterval.rest, 8) IN IF ~lastLoginTime.ok THEN Fail ELSE
    LET lastLoginIp == ReadBytes(lastLoginTime.rest, 4) IN IF ~lastLoginIp.ok THEN Fail ELSE
    LET throttleNoMsgs == ReadBytes(lastLoginIp.rest, 4) IN IF ~throttleNoMsgs.ok THEN Fail ELSE
    LET throttleDisconnectLimit == ReadBytes(throttleNoMsgs.rest, 4) IN IF ~throttleDisconnectLimit.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(throttleDisconnectLimit.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET sessionInstanceId == ReadBytes(heartBtInt.rest, 4) IN IF ~sessionInstanceId.ok THEN Fail ELSE
    LET tradSesMode == ReadBytes(sessionInstanceId.rest, 1) IN IF ~tradSesMode.ok THEN Fail ELSE
    LET noOfPartition == ReadBytes(tradSesMode.rest, 1) IN IF ~noOfPartition.ok THEN Fail ELSE
    LET daysLeftForPasswdExpiry == ReadBytes(noOfPartition.rest, 1) IN IF ~daysLeftForPasswdExpiry.ok THEN Fail ELSE
    LET graceLoginsLeft == ReadBytes(daysLeftForPasswdExpiry.rest, 1) IN IF ~graceLoginsLeft.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(graceLoginsLeft.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(defaultCstmApplVerId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         responseHeaderComp      |-> responseHeaderComp.value,
         throttleTimeInterval    |-> throttleTimeInterval.value,
         lastLoginTime           |-> lastLoginTime.value,
         lastLoginIp             |-> lastLoginIp.value,
         throttleNoMsgs          |-> throttleNoMsgs.value,
         throttleDisconnectLimit |-> throttleDisconnectLimit.value,
         heartBtInt              |-> heartBtInt.value,
         sessionInstanceId       |-> sessionInstanceId.value,
         tradSesMode             |-> tradSesMode.value,
         noOfPartition           |-> noOfPartition.value,
         daysLeftForPasswdExpiry |-> daysLeftForPasswdExpiry.value,
         graceLoginsLeft         |-> graceLoginsLeft.value,
         defaultCstmApplVerId    |-> defaultCstmApplVerId.value,
         pad2                    |-> pad2.value ], pad2.rest)

ZeroLogonResponse ==
    [ filler4                 |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp      |-> ZeroResponseHeaderComp4,
      throttleTimeInterval    |-> [i \in 1 .. 8 |-> 0],
      lastLoginTime           |-> [i \in 1 .. 8 |-> 0],
      lastLoginIp             |-> [i \in 1 .. 4 |-> 0],
      throttleNoMsgs          |-> [i \in 1 .. 4 |-> 0],
      throttleDisconnectLimit |-> [i \in 1 .. 4 |-> 0],
      heartBtInt              |-> [i \in 1 .. 4 |-> 0],
      sessionInstanceId       |-> [i \in 1 .. 4 |-> 0],
      tradSesMode             |-> [i \in 1 .. 1 |-> 0],
      noOfPartition           |-> [i \in 1 .. 1 |-> 0],
      daysLeftForPasswdExpiry |-> [i \in 1 .. 1 |-> 0],
      graceLoginsLeft         |-> [i \in 1 .. 1 |-> 0],
      defaultCstmApplVerId    |-> [i \in 1 .. 30 |-> 0],
      pad2                    |-> [i \in 1 .. 2 |-> 0] ]

(* Logon Response at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponse ==
    { ZeroLogonResponse }
        \cup { [ZeroLogonResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroLogonResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp4 }
        \cup { [ZeroLogonResponse EXCEPT !.throttleTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponse EXCEPT !.lastLoginTime = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponse EXCEPT !.lastLoginIp = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.throttleNoMsgs = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.throttleDisconnectLimit = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.sessionInstanceId = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.tradSesMode = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponse EXCEPT !.noOfPartition = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponse EXCEPT !.daysLeftForPasswdExpiry = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponse EXCEPT !.graceLoginsLeft = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponse EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonResponse EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp5 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp5(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp5(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp5 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp5 ==
    { ZeroResponseHeaderComp5 }
        \cup { [ZeroResponseHeaderComp5 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp5 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Response: 26 bytes                                               *)
(***************************************************************************)

LogoutResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp5 ]

EncodeLogoutResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp5(message.responseHeaderComp)

DecodeLogoutResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp5(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroLogoutResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp5 ]

(* Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponse ==
    { ZeroLogoutResponse }
        \cup { [ZeroLogoutResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp5 }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp5 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp5(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp5(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp5 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp5 ==
    { ZeroNrResponseHeaderMeComp5 }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Quote Entry Ack Grp Comp: 24 bytes                                      *)
(***************************************************************************)

QuoteEntryAckGrpComp ==
    [ securityId             : Sample(8),
      bidCxlSize             : Sample(4),
      offerCxlSize           : Sample(4),
      quoteEntryRejectReason : Sample(4),
      quoteEntryStatus       : Sample(1),
      pad3                   : Sample(3) ]

EncodeQuoteEntryAckGrpComp(message) ==
    message.securityId
        \o message.bidCxlSize
        \o message.offerCxlSize
        \o message.quoteEntryRejectReason
        \o message.quoteEntryStatus
        \o message.pad3

DecodeQuoteEntryAckGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidCxlSize == ReadBytes(securityId.rest, 4) IN IF ~bidCxlSize.ok THEN Fail ELSE
    LET offerCxlSize == ReadBytes(bidCxlSize.rest, 4) IN IF ~offerCxlSize.ok THEN Fail ELSE
    LET quoteEntryRejectReason == ReadBytes(offerCxlSize.rest, 4) IN IF ~quoteEntryRejectReason.ok THEN Fail ELSE
    LET quoteEntryStatus == ReadBytes(quoteEntryRejectReason.rest, 1) IN IF ~quoteEntryStatus.ok THEN Fail ELSE
    LET pad3 == ReadBytes(quoteEntryStatus.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         bidCxlSize             |-> bidCxlSize.value,
         offerCxlSize           |-> offerCxlSize.value,
         quoteEntryRejectReason |-> quoteEntryRejectReason.value,
         quoteEntryStatus       |-> quoteEntryStatus.value,
         pad3                   |-> pad3.value ], pad3.rest)

ZeroQuoteEntryAckGrpComp ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      bidCxlSize             |-> [i \in 1 .. 4 |-> 0],
      offerCxlSize           |-> [i \in 1 .. 4 |-> 0],
      quoteEntryRejectReason |-> [i \in 1 .. 4 |-> 0],
      quoteEntryStatus       |-> [i \in 1 .. 1 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Entry Ack Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryAckGrpComp ==
    { ZeroQuoteEntryAckGrpComp }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.bidCxlSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.offerCxlSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.quoteEntryRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.quoteEntryStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Quote Entry Ack Grp Comp, written one after another *)
RECURSIVE EncodeQuoteEntryAckGrpCompList(_)
EncodeQuoteEntryAckGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEntryAckGrpComp(Head(messages)) \o EncodeQuoteEntryAckGrpCompList(Tail(messages))

(* As many Quote Entry Ack Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteEntryAckGrpCompList(_, _)
ReadQuoteEntryAckGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEntryAckGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEntryAckGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Entry Ack Grp Comp of each kind, for the lists that carry them *)
OneQuoteEntryAckGrpComp == { ZeroQuoteEntryAckGrpComp }

(***************************************************************************)
(* Mass Quote Response                                                     *)
(***************************************************************************)

MassQuoteResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp5,
      quoteId                : Sample(8),
      quoteResponseId        : Sample(8),
      marketSegmentId        : Sample(4),
      pad3                   : Sample(3),
      quoteEntryAckGrpComp   : SampleLists(OneQuoteEntryAckGrpComp) ]

EncodeMassQuoteResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp5(message.nrResponseHeaderMeComp)
        \o message.quoteId
        \o message.quoteResponseId
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.quoteEntryAckGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEntryAckGrpCompList(message.quoteEntryAckGrpComp)

DecodeMassQuoteResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp5(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteResponseId == ReadBytes(quoteId.rest, 8) IN IF ~quoteResponseId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteResponseId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(marketSegmentId.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteEntries.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET quoteEntryAckGrpComp == ReadQuoteEntryAckGrpCompList(pad3.rest, noQuoteEntries.value) IN IF ~quoteEntryAckGrpComp.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         quoteId                |-> quoteId.value,
         quoteResponseId        |-> quoteResponseId.value,
         marketSegmentId        |-> marketSegmentId.value,
         pad3                   |-> pad3.value,
         quoteEntryAckGrpComp   |-> quoteEntryAckGrpComp.value ], quoteEntryAckGrpComp.rest)

ZeroMassQuoteResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp5,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      quoteResponseId        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      quoteEntryAckGrpComp   |-> << >> ]

(* Mass Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponse ==
    { ZeroMassQuoteResponse }
        \cup { [ZeroMassQuoteResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp5 }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteResponseId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteEntryAckGrpComp = one] : one \in SampleLists(OneQuoteEntryAckGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp6 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp6(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp6(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp6 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp6 ==
    { ZeroNrResponseHeaderMeComp6 }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Modify Order Nr Response: 162 bytes                                     *)
(***************************************************************************)

ModifyOrderNrResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp6,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      priceMkToLimitPx       : Sample(8),
      yield                  : Sample(8),
      underlyingDirtyPrice   : Sample(8),
      activityTime           : Sample(8),
      filler1                : Sample(8),
      filler2                : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      filler4v2              : Sample(2),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2),
      productComplex         : Sample(1),
      rolloverFlag           : Sample(1) ]

EncodeModifyOrderNrResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp6(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.priceMkToLimitPx
        \o message.yield
        \o message.underlyingDirtyPrice
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.filler4v2
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.rolloverFlag

DecodeModifyOrderNrResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp6(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET priceMkToLimitPx == ReadBytes(execId.rest, 8) IN IF ~priceMkToLimitPx.ok THEN Fail ELSE
    LET yield == ReadBytes(priceMkToLimitPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(yield.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET activityTime == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(filler2.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(cxlQty.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(filler4v2.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(productComplex.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         priceMkToLimitPx       |-> priceMkToLimitPx.value,
         yield                  |-> yield.value,
         underlyingDirtyPrice   |-> underlyingDirtyPrice.value,
         activityTime           |-> activityTime.value,
         filler1                |-> filler1.value,
         filler2                |-> filler2.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         filler4v2              |-> filler4v2.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value,
         productComplex         |-> productComplex.value,
         rolloverFlag           |-> rolloverFlag.value ], rolloverFlag.rest)

ZeroModifyOrderNrResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp6,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      priceMkToLimitPx       |-> [i \in 1 .. 8 |-> 0],
      yield                  |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice   |-> [i \in 1 .. 8 |-> 0],
      activityTime           |-> [i \in 1 .. 8 |-> 0],
      filler1                |-> [i \in 1 .. 8 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      filler4v2              |-> [i \in 1 .. 2 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag           |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderNrResponse ==
    { ZeroModifyOrderNrResponse }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp6 }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.priceMkToLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.rolloverFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp3 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp3(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp3(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp3 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp3 ==
    { ZeroResponseHeaderMeComp3 }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Response: 186 bytes                                        *)
(***************************************************************************)

ModifyOrderResponse ==
    [ filler4               : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp3,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      priceMkToLimitPx      : Sample(8),
      yield                 : Sample(8),
      underlyingDirtyPrice  : Sample(8),
      trdRegTsTimePriority  : Sample(8),
      activityTime          : Sample(8),
      filler1               : Sample(8),
      filler2               : Sample(4),
      leavesQty             : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      filler4v2             : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2),
      productComplex        : Sample(1),
      rolloverFlag          : Sample(1) ]

EncodeModifyOrderResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp3(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.priceMkToLimitPx
        \o message.yield
        \o message.underlyingDirtyPrice
        \o message.trdRegTsTimePriority
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.filler4v2
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.rolloverFlag

DecodeModifyOrderResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp3(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET priceMkToLimitPx == ReadBytes(execId.rest, 8) IN IF ~priceMkToLimitPx.ok THEN Fail ELSE
    LET yield == ReadBytes(priceMkToLimitPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(yield.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET activityTime == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(filler2.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(cxlQty.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(filler4v2.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(productComplex.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         priceMkToLimitPx      |-> priceMkToLimitPx.value,
         yield                 |-> yield.value,
         underlyingDirtyPrice  |-> underlyingDirtyPrice.value,
         trdRegTsTimePriority  |-> trdRegTsTimePriority.value,
         activityTime          |-> activityTime.value,
         filler1               |-> filler1.value,
         filler2               |-> filler2.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         filler4v2             |-> filler4v2.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value,
         productComplex        |-> productComplex.value,
         rolloverFlag          |-> rolloverFlag.value ], rolloverFlag.rest)

ZeroModifyOrderResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp3,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      priceMkToLimitPx      |-> [i \in 1 .. 8 |-> 0],
      yield                 |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority  |-> [i \in 1 .. 8 |-> 0],
      activityTime          |-> [i \in 1 .. 8 |-> 0],
      filler1               |-> [i \in 1 .. 8 |-> 0],
      filler2               |-> [i \in 1 .. 4 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      filler4v2             |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag          |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse ==
    { ZeroModifyOrderResponse }
        \cup { [ZeroModifyOrderResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp3 }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.priceMkToLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.rolloverFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp5 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp5(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp5(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp5 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp5 ==
    { ZeroRbcHeaderMeComp5 }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Multi Leg Grp Comp: 56 bytes                                            *)
(***************************************************************************)

MultiLegGrpComp ==
    [ securityId            : Sample(8),
      orderId               : Sample(8),
      price                 : Sample(8),
      maxPricePercentage    : Sample(8),
      messageTag            : Sample(4),
      orderQty              : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      execRestatementReason : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      side                  : Sample(1),
      ordType               : Sample(1),
      pad2                  : Sample(2) ]

EncodeMultiLegGrpComp(message) ==
    message.securityId
        \o message.orderId
        \o message.price
        \o message.maxPricePercentage
        \o message.messageTag
        \o message.orderQty
        \o message.cumQty
        \o message.cxlQty
        \o message.execRestatementReason
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.ordType
        \o message.pad2

DecodeMultiLegGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(price.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET messageTag == ReadBytes(maxPricePercentage.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET orderQty == ReadBytes(messageTag.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(cxlQty.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRestatementReason.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad2 == ReadBytes(ordType.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         orderId               |-> orderId.value,
         price                 |-> price.value,
         maxPricePercentage    |-> maxPricePercentage.value,
         messageTag            |-> messageTag.value,
         orderQty              |-> orderQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         execRestatementReason |-> execRestatementReason.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         side                  |-> side.value,
         ordType               |-> ordType.value,
         pad2                  |-> pad2.value ], pad2.rest)

ZeroMultiLegGrpComp ==
    [ securityId            |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage    |-> [i \in 1 .. 8 |-> 0],
      messageTag            |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      pad2                  |-> [i \in 1 .. 2 |-> 0] ]

(* Multi Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegGrpComp ==
    { ZeroMultiLegGrpComp }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegGrpComp EXCEPT !.pad2 = one] : one \in Sample(2) }

(* A run of Multi Leg Grp Comp, written one after another *)
RECURSIVE EncodeMultiLegGrpCompList(_)
EncodeMultiLegGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultiLegGrpComp(Head(messages)) \o EncodeMultiLegGrpCompList(Tail(messages))

(* As many Multi Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadMultiLegGrpCompList(_, _)
ReadMultiLegGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultiLegGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultiLegGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multi Leg Grp Comp of each kind, for the lists that carry them *)
OneMultiLegGrpComp == { ZeroMultiLegGrpComp }

(***************************************************************************)
(* Multi Leg Fill Grp Comp: 32 bytes                                       *)
(***************************************************************************)

MultiLegFillGrpComp ==
    [ fillPx      : Sample(8),
      securityId  : Sample(8),
      fillQty     : Sample(4),
      fillMatchId : Sample(4),
      fillExecId  : Sample(4),
      pad4        : Sample(4) ]

EncodeMultiLegFillGrpComp(message) ==
    message.fillPx
        \o message.securityId
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.pad4

DecodeMultiLegFillGrpComp(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET securityId == ReadBytes(fillPx.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET fillQty == ReadBytes(securityId.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(fillExecId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ fillPx      |-> fillPx.value,
         securityId  |-> securityId.value,
         fillQty     |-> fillQty.value,
         fillMatchId |-> fillMatchId.value,
         fillExecId  |-> fillExecId.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroMultiLegFillGrpComp ==
    [ fillPx      |-> [i \in 1 .. 8 |-> 0],
      securityId  |-> [i \in 1 .. 8 |-> 0],
      fillQty     |-> [i \in 1 .. 4 |-> 0],
      fillMatchId |-> [i \in 1 .. 4 |-> 0],
      fillExecId  |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Multi Leg Fill Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegFillGrpComp ==
    { ZeroMultiLegFillGrpComp }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Multi Leg Fill Grp Comp, written one after another *)
RECURSIVE EncodeMultiLegFillGrpCompList(_)
EncodeMultiLegFillGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultiLegFillGrpComp(Head(messages)) \o EncodeMultiLegFillGrpCompList(Tail(messages))

(* As many Multi Leg Fill Grp Comp as the field that counts them says *)
RECURSIVE ReadMultiLegFillGrpCompList(_, _)
ReadMultiLegFillGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultiLegFillGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultiLegFillGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multi Leg Fill Grp Comp of each kind, for the lists that carry them *)
OneMultiLegFillGrpComp == { ZeroMultiLegFillGrpComp }

(***************************************************************************)
(* Instrmnt Leg Exec Grp Comp: 32 bytes                                    *)
(***************************************************************************)

InstrmntLegExecGrpComp ==
    [ legSecurityId : Sample(8),
      legLastPx     : Sample(8),
      legLastQty    : Sample(4),
      legExecId     : Sample(4),
      legSide       : Sample(1),
      noFillsIndex  : Sample(1),
      pad6          : Sample(6) ]

EncodeInstrmntLegExecGrpComp(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noFillsIndex
        \o message.pad6

DecodeInstrmntLegExecGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noFillsIndex == ReadBytes(legSide.rest, 1) IN IF ~noFillsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFillsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legLastPx     |-> legLastPx.value,
         legLastQty    |-> legLastQty.value,
         legExecId     |-> legExecId.value,
         legSide       |-> legSide.value,
         noFillsIndex  |-> noFillsIndex.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroInstrmntLegExecGrpComp ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legExecId     |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      noFillsIndex  |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmnt Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmntLegExecGrpComp ==
    { ZeroInstrmntLegExecGrpComp }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.noFillsIndex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmnt Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeInstrmntLegExecGrpCompList(_)
EncodeInstrmntLegExecGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmntLegExecGrpComp(Head(messages)) \o EncodeInstrmntLegExecGrpCompList(Tail(messages))

(* As many Instrmnt Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmntLegExecGrpCompList(_, _)
ReadInstrmntLegExecGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmntLegExecGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmntLegExecGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmnt Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneInstrmntLegExecGrpComp == { ZeroInstrmntLegExecGrpComp }

(***************************************************************************)
(* Multi Leg Exec Report Broadcast                                         *)
(***************************************************************************)

MultiLegExecReportBroadcast ==
    [ filler4                : Sample(2),
      rbcHeaderMeComp        : RbcHeaderMeComp5,
      senderLocationId       : Sample(8),
      clOrdId                : Sample(8),
      execId                 : Sample(8),
      accountType            : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      pad3                   : Sample(3),
      multiLegGrpComp        : SampleLists(OneMultiLegGrpComp),
      multiLegFillGrpComp    : SampleLists(OneMultiLegFillGrpComp),
      instrmntLegExecGrpComp : SampleLists(OneInstrmntLegExecGrpComp) ]

EncodeMultiLegExecReportBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp5(message.rbcHeaderMeComp)
        \o message.senderLocationId
        \o message.clOrdId
        \o message.execId
        \o EncodeUIntLE(Len(message.instrmntLegExecGrpComp), 2)
        \o message.accountType
        \o EncodeUIntBE(Len(message.multiLegGrpComp), 1)
        \o EncodeUIntBE(Len(message.multiLegFillGrpComp), 1)
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad3
        \o EncodeMultiLegGrpCompList(message.multiLegGrpComp)
        \o EncodeMultiLegFillGrpCompList(message.multiLegFillGrpComp)
        \o EncodeInstrmntLegExecGrpCompList(message.instrmntLegExecGrpComp)

DecodeMultiLegExecReportBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp5(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(execId.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET accountType == ReadBytes(noLegExecs.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET noOfMultiLeg == ReadUIntBE(accountType.rest, 1) IN IF ~noOfMultiLeg.ok THEN Fail ELSE
    LET noOfMultiLegExecs == ReadUIntBE(noOfMultiLeg.rest, 1) IN IF ~noOfMultiLegExecs.ok THEN Fail ELSE
    LET algoId == ReadBytes(noOfMultiLegExecs.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad3 == ReadBytes(cpCode.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET multiLegGrpComp == ReadMultiLegGrpCompList(pad3.rest, noOfMultiLeg.value) IN IF ~multiLegGrpComp.ok THEN Fail ELSE
    LET multiLegFillGrpComp == ReadMultiLegFillGrpCompList(multiLegGrpComp.rest, noOfMultiLegExecs.value) IN IF ~multiLegFillGrpComp.ok THEN Fail ELSE
    LET instrmntLegExecGrpComp == ReadInstrmntLegExecGrpCompList(multiLegFillGrpComp.rest, noLegExecs.value) IN IF ~instrmntLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         rbcHeaderMeComp        |-> rbcHeaderMeComp.value,
         senderLocationId       |-> senderLocationId.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         accountType            |-> accountType.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         pad3                   |-> pad3.value,
         multiLegGrpComp        |-> multiLegGrpComp.value,
         multiLegFillGrpComp    |-> multiLegFillGrpComp.value,
         instrmntLegExecGrpComp |-> instrmntLegExecGrpComp.value ], instrmntLegExecGrpComp.rest)

ZeroMultiLegExecReportBroadcast ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp        |-> ZeroRbcHeaderMeComp5,
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      multiLegGrpComp        |-> << >>,
      multiLegFillGrpComp    |-> << >>,
      instrmntLegExecGrpComp |-> << >> ]

(* Multi Leg Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegExecReportBroadcast ==
    { ZeroMultiLegExecReportBroadcast }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp5 }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.multiLegGrpComp = one] : one \in SampleLists(OneMultiLegGrpComp) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.multiLegFillGrpComp = one] : one \in SampleLists(OneMultiLegFillGrpComp) }
        \cup { [ZeroMultiLegExecReportBroadcast EXCEPT !.instrmntLegExecGrpComp = one] : one \in SampleLists(OneInstrmntLegExecGrpComp) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp4 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp4(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp4(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp4 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp4 ==
    { ZeroResponseHeaderMeComp4 }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Multi Leg Exec Grp Comp: 32 bytes                                       *)
(***************************************************************************)

MultiLegExecGrpComp ==
    [ orderId               : Sample(8),
      securityId            : Sample(8),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      execRestatementReason : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      pad4                  : Sample(4) ]

EncodeMultiLegExecGrpComp(message) ==
    message.orderId
        \o message.securityId
        \o message.cumQty
        \o message.cxlQty
        \o message.execRestatementReason
        \o message.ordStatus
        \o message.execType
        \o message.pad4

DecodeMultiLegExecGrpComp(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(securityId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(cxlQty.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRestatementReason.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET pad4 == ReadBytes(execType.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ orderId               |-> orderId.value,
         securityId            |-> securityId.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         execRestatementReason |-> execRestatementReason.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         pad4                  |-> pad4.value ], pad4.rest)

ZeroMultiLegExecGrpComp ==
    [ orderId               |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0] ]

(* Multi Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegExecGrpComp ==
    { ZeroMultiLegExecGrpComp }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegExecGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Multi Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeMultiLegExecGrpCompList(_)
EncodeMultiLegExecGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultiLegExecGrpComp(Head(messages)) \o EncodeMultiLegExecGrpCompList(Tail(messages))

(* As many Multi Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadMultiLegExecGrpCompList(_, _)
ReadMultiLegExecGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultiLegExecGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultiLegExecGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multi Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneMultiLegExecGrpComp == { ZeroMultiLegExecGrpComp }

(***************************************************************************)
(* Multi Leg Fill Grp Comp: 32 bytes                                       *)
(***************************************************************************)

MultiLegFillGrpComp2 ==
    [ fillPx      : Sample(8),
      securityId  : Sample(8),
      fillQty     : Sample(4),
      fillMatchId : Sample(4),
      fillExecId  : Sample(4),
      pad4        : Sample(4) ]

EncodeMultiLegFillGrpComp2(message) ==
    message.fillPx
        \o message.securityId
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.pad4

DecodeMultiLegFillGrpComp2(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET securityId == ReadBytes(fillPx.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET fillQty == ReadBytes(securityId.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(fillExecId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ fillPx      |-> fillPx.value,
         securityId  |-> securityId.value,
         fillQty     |-> fillQty.value,
         fillMatchId |-> fillMatchId.value,
         fillExecId  |-> fillExecId.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroMultiLegFillGrpComp2 ==
    [ fillPx      |-> [i \in 1 .. 8 |-> 0],
      securityId  |-> [i \in 1 .. 8 |-> 0],
      fillQty     |-> [i \in 1 .. 4 |-> 0],
      fillMatchId |-> [i \in 1 .. 4 |-> 0],
      fillExecId  |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Multi Leg Fill Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegFillGrpComp2 ==
    { ZeroMultiLegFillGrpComp2 }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegFillGrpComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Multi Leg Fill Grp Comp, written one after another *)
RECURSIVE EncodeMultiLegFillGrpComp2List(_)
EncodeMultiLegFillGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultiLegFillGrpComp2(Head(messages)) \o EncodeMultiLegFillGrpComp2List(Tail(messages))

(* As many Multi Leg Fill Grp Comp as the field that counts them says *)
RECURSIVE ReadMultiLegFillGrpComp2List(_, _)
ReadMultiLegFillGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultiLegFillGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultiLegFillGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multi Leg Fill Grp Comp of each kind, for the lists that carry them *)
OneMultiLegFillGrpComp2 == { ZeroMultiLegFillGrpComp2 }

(***************************************************************************)
(* Instrmnt Leg Exec Grp Comp: 32 bytes                                    *)
(***************************************************************************)

InstrmntLegExecGrpComp2 ==
    [ legSecurityId : Sample(8),
      legLastPx     : Sample(8),
      legLastQty    : Sample(4),
      legExecId     : Sample(4),
      legSide       : Sample(1),
      noFillsIndex  : Sample(1),
      pad6          : Sample(6) ]

EncodeInstrmntLegExecGrpComp2(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noFillsIndex
        \o message.pad6

DecodeInstrmntLegExecGrpComp2(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noFillsIndex == ReadBytes(legSide.rest, 1) IN IF ~noFillsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFillsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legLastPx     |-> legLastPx.value,
         legLastQty    |-> legLastQty.value,
         legExecId     |-> legExecId.value,
         legSide       |-> legSide.value,
         noFillsIndex  |-> noFillsIndex.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroInstrmntLegExecGrpComp2 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legExecId     |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      noFillsIndex  |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmnt Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmntLegExecGrpComp2 ==
    { ZeroInstrmntLegExecGrpComp2 }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.noFillsIndex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp2 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmnt Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeInstrmntLegExecGrpComp2List(_)
EncodeInstrmntLegExecGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmntLegExecGrpComp2(Head(messages)) \o EncodeInstrmntLegExecGrpComp2List(Tail(messages))

(* As many Instrmnt Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmntLegExecGrpComp2List(_, _)
ReadInstrmntLegExecGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmntLegExecGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmntLegExecGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmnt Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneInstrmntLegExecGrpComp2 == { ZeroInstrmntLegExecGrpComp2 }

(***************************************************************************)
(* Multi Leg Exec Response                                                 *)
(***************************************************************************)

MultiLegExecResponse ==
    [ filler4                : Sample(2),
      responseHeaderMeComp   : ResponseHeaderMeComp4,
      clOrdId                : Sample(8),
      execId                 : Sample(8),
      algoId                 : Sample(16),
      pad4                   : Sample(4),
      multiLegExecGrpComp    : SampleLists(OneMultiLegExecGrpComp),
      multiLegFillGrpComp    : SampleLists(OneMultiLegFillGrpComp2),
      instrmntLegExecGrpComp : SampleLists(OneInstrmntLegExecGrpComp2) ]

EncodeMultiLegExecResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp4(message.responseHeaderMeComp)
        \o message.clOrdId
        \o message.execId
        \o EncodeUIntLE(Len(message.instrmntLegExecGrpComp), 2)
        \o EncodeUIntBE(Len(message.multiLegExecGrpComp), 1)
        \o EncodeUIntBE(Len(message.multiLegFillGrpComp), 1)
        \o message.algoId
        \o message.pad4
        \o EncodeMultiLegExecGrpCompList(message.multiLegExecGrpComp)
        \o EncodeMultiLegFillGrpComp2List(message.multiLegFillGrpComp)
        \o EncodeInstrmntLegExecGrpComp2List(message.instrmntLegExecGrpComp)

DecodeMultiLegExecResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp4(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET execId == ReadBytes(clOrdId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(execId.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET noOfMultiLeg == ReadUIntBE(noLegExecs.rest, 1) IN IF ~noOfMultiLeg.ok THEN Fail ELSE
    LET noOfMultiLegExecs == ReadUIntBE(noOfMultiLeg.rest, 1) IN IF ~noOfMultiLegExecs.ok THEN Fail ELSE
    LET algoId == ReadBytes(noOfMultiLegExecs.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(algoId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET multiLegExecGrpComp == ReadMultiLegExecGrpCompList(pad4.rest, noOfMultiLeg.value) IN IF ~multiLegExecGrpComp.ok THEN Fail ELSE
    LET multiLegFillGrpComp == ReadMultiLegFillGrpComp2List(multiLegExecGrpComp.rest, noOfMultiLegExecs.value) IN IF ~multiLegFillGrpComp.ok THEN Fail ELSE
    LET instrmntLegExecGrpComp == ReadInstrmntLegExecGrpComp2List(multiLegFillGrpComp.rest, noLegExecs.value) IN IF ~instrmntLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         responseHeaderMeComp   |-> responseHeaderMeComp.value,
         clOrdId                |-> clOrdId.value,
         execId                 |-> execId.value,
         algoId                 |-> algoId.value,
         pad4                   |-> pad4.value,
         multiLegExecGrpComp    |-> multiLegExecGrpComp.value,
         multiLegFillGrpComp    |-> multiLegFillGrpComp.value,
         instrmntLegExecGrpComp |-> instrmntLegExecGrpComp.value ], instrmntLegExecGrpComp.rest)

ZeroMultiLegExecResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp   |-> ZeroResponseHeaderMeComp4,
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0],
      multiLegExecGrpComp    |-> << >>,
      multiLegFillGrpComp    |-> << >>,
      instrmntLegExecGrpComp |-> << >> ]

(* Multi Leg Exec Response at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegExecResponse ==
    { ZeroMultiLegExecResponse }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp4 }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.multiLegExecGrpComp = one] : one \in SampleLists(OneMultiLegExecGrpComp) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.multiLegFillGrpComp = one] : one \in SampleLists(OneMultiLegFillGrpComp2) }
        \cup { [ZeroMultiLegExecResponse EXCEPT !.instrmntLegExecGrpComp = one] : one \in SampleLists(OneInstrmntLegExecGrpComp2) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp7 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp7(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp7(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp7 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp7 ==
    { ZeroNrResponseHeaderMeComp7 }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Multi Leg Order Reject                                                  *)
(***************************************************************************)

MultiLegOrderReject ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp7,
      securityId             : Sample(8),
      sessionRejectReason    : Sample(4),
      pad2                   : Sample(2),
      varText                : SampleBytes,
      alignmentPadding       : SampleBytes ]

EncodeMultiLegOrderReject(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp7(message.nrResponseHeaderMeComp)
        \o message.securityId
        \o message.sessionRejectReason
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.pad2
        \o message.varText
        \o message.alignmentPadding

DecodeMultiLegOrderReject(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp7(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(securityId.rest, 4) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(sessionRejectReason.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET pad2 == ReadBytes(varTextLen.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET varText == ReadBytes(pad2.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         securityId             |-> securityId.value,
         sessionRejectReason    |-> sessionRejectReason.value,
         pad2                   |-> pad2.value,
         varText                |-> varText.value,
         alignmentPadding       |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroMultiLegOrderReject ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp7,
      securityId             |-> [i \in 1 .. 8 |-> 0],
      sessionRejectReason    |-> [i \in 1 .. 4 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      varText                |-> << >>,
      alignmentPadding       |-> << >> ]

(* Multi Leg Order Reject at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegOrderReject ==
    { ZeroMultiLegOrderReject }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp7 }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.sessionRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroMultiLegOrderReject EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp8 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp8(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp8(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp8 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp8 ==
    { ZeroNrResponseHeaderMeComp8 }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* New Order Nr Response: 146 bytes                                        *)
(***************************************************************************)

NewOrderNrResponse ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp8,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      securityId             : Sample(8),
      priceMkToLimitPx       : Sample(8),
      yield                  : Sample(8),
      underlyingDirtyPrice   : Sample(8),
      execId                 : Sample(8),
      activityTime           : Sample(8),
      filler1                : Sample(8),
      filler2                : Sample(4),
      filler4v2              : Sample(2),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2),
      productComplex         : Sample(1),
      rolloverFlag           : Sample(1),
      pad4                   : Sample(4) ]

EncodeNewOrderNrResponse(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp8(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.securityId
        \o message.priceMkToLimitPx
        \o message.yield
        \o message.underlyingDirtyPrice
        \o message.execId
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.filler4v2
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.rolloverFlag
        \o message.pad4

DecodeNewOrderNrResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp8(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET priceMkToLimitPx == ReadBytes(securityId.rest, 8) IN IF ~priceMkToLimitPx.ok THEN Fail ELSE
    LET yield == ReadBytes(priceMkToLimitPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(yield.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET execId == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(execId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(filler2.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(filler4v2.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(productComplex.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET pad4 == ReadBytes(rolloverFlag.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         securityId             |-> securityId.value,
         priceMkToLimitPx       |-> priceMkToLimitPx.value,
         yield                  |-> yield.value,
         underlyingDirtyPrice   |-> underlyingDirtyPrice.value,
         execId                 |-> execId.value,
         activityTime           |-> activityTime.value,
         filler1                |-> filler1.value,
         filler2                |-> filler2.value,
         filler4v2              |-> filler4v2.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value,
         productComplex         |-> productComplex.value,
         rolloverFlag           |-> rolloverFlag.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroNewOrderNrResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp8,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      priceMkToLimitPx       |-> [i \in 1 .. 8 |-> 0],
      yield                  |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice   |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      activityTime           |-> [i \in 1 .. 8 |-> 0],
      filler1                |-> [i \in 1 .. 8 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      filler4v2              |-> [i \in 1 .. 2 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag           |-> [i \in 1 .. 1 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderNrResponse ==
    { ZeroNewOrderNrResponse }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp8 }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.priceMkToLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp5 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp5(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp5(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp5 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp5 ==
    { ZeroResponseHeaderMeComp5 }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Response: 178 bytes                                           *)
(***************************************************************************)

NewOrderResponse ==
    [ filler4               : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp5,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      securityId            : Sample(8),
      priceMkToLimitPx      : Sample(8),
      yield                 : Sample(8),
      underlyingDirtyPrice  : Sample(8),
      execId                : Sample(8),
      trdRegTsEntryTime     : Sample(8),
      trdRegTsTimePriority  : Sample(8),
      activityTime          : Sample(8),
      filler1               : Sample(8),
      filler2               : Sample(4),
      filler4v2             : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2),
      productComplex        : Sample(1),
      rolloverFlag          : Sample(1),
      pad4                  : Sample(4) ]

EncodeNewOrderResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp5(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.securityId
        \o message.priceMkToLimitPx
        \o message.yield
        \o message.underlyingDirtyPrice
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.filler4v2
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.productComplex
        \o message.rolloverFlag
        \o message.pad4

DecodeNewOrderResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp5(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET priceMkToLimitPx == ReadBytes(securityId.rest, 8) IN IF ~priceMkToLimitPx.ok THEN Fail ELSE
    LET yield == ReadBytes(priceMkToLimitPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(yield.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET execId == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET activityTime == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(filler2.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(filler4v2.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(productComplex.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET pad4 == ReadBytes(rolloverFlag.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         securityId            |-> securityId.value,
         priceMkToLimitPx      |-> priceMkToLimitPx.value,
         yield                 |-> yield.value,
         underlyingDirtyPrice  |-> underlyingDirtyPrice.value,
         execId                |-> execId.value,
         trdRegTsEntryTime     |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority  |-> trdRegTsTimePriority.value,
         activityTime          |-> activityTime.value,
         filler1               |-> filler1.value,
         filler2               |-> filler2.value,
         filler4v2             |-> filler4v2.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value,
         productComplex        |-> productComplex.value,
         rolloverFlag          |-> rolloverFlag.value,
         pad4                  |-> pad4.value ], pad4.rest)

ZeroNewOrderResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp5,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      priceMkToLimitPx      |-> [i \in 1 .. 8 |-> 0],
      yield                 |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice  |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority  |-> [i \in 1 .. 8 |-> 0],
      activityTime          |-> [i \in 1 .. 8 |-> 0],
      filler1               |-> [i \in 1 .. 8 |-> 0],
      filler2               |-> [i \in 1 .. 4 |-> 0],
      filler4v2             |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      productComplex        |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag          |-> [i \in 1 .. 1 |-> 0],
      pad4                  |-> [i \in 1 .. 4 |-> 0] ]

(* New Order Response at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponse ==
    { ZeroNewOrderResponse }
        \cup { [ZeroNewOrderResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp5 }
        \cup { [ZeroNewOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.priceMkToLimitPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponse EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp ==
    { ZeroRbcHeaderComp }
        \cup { [ZeroRbcHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* News Broadcast                                                          *)
(***************************************************************************)

NewsBroadcast ==
    [ filler4          : Sample(2),
      rbcHeaderComp    : RbcHeaderComp,
      origTime         : Sample(8),
      headline         : Sample(256),
      pad6             : Sample(6),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeNewsBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp(message.rbcHeaderComp)
        \o message.origTime
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.headline
        \o message.pad6
        \o message.varText
        \o message.alignmentPadding

DecodeNewsBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET origTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(origTime.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET headline == ReadBytes(varTextLen.rest, 256) IN IF ~headline.ok THEN Fail ELSE
    LET pad6 == ReadBytes(headline.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET varText == ReadBytes(pad6.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4          |-> filler4.value,
         rbcHeaderComp    |-> rbcHeaderComp.value,
         origTime         |-> origTime.value,
         headline         |-> headline.value,
         pad6             |-> pad6.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroNewsBroadcast ==
    [ filler4          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp    |-> ZeroRbcHeaderComp,
      origTime         |-> [i \in 1 .. 8 |-> 0],
      headline         |-> [i \in 1 .. 256 |-> 0],
      pad6             |-> [i \in 1 .. 6 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* News Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedNewsBroadcast ==
    { ZeroNewsBroadcast }
        \cup { [ZeroNewsBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewsBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp }
        \cup { [ZeroNewsBroadcast EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroNewsBroadcast EXCEPT !.headline = one] : one \in Sample(256) }
        \cup { [ZeroNewsBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroNewsBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroNewsBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp6 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp6(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp6(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp6 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp6 ==
    { ZeroRbcHeaderMeComp6 }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Fills Grp Comp: 40 bytes                                                *)
(***************************************************************************)

FillsGrpComp ==
    [ fillPx           : Sample(8),
      fillYield        : Sample(8),
      fillDirtyPx      : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp(message) ==
    message.fillPx
        \o message.fillYield
        \o message.fillDirtyPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillYield == ReadBytes(fillPx.rest, 8) IN IF ~fillYield.ok THEN Fail ELSE
    LET fillDirtyPx == ReadBytes(fillYield.rest, 8) IN IF ~fillDirtyPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillDirtyPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillYield        |-> fillYield.value,
         fillDirtyPx      |-> fillDirtyPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillYield        |-> [i \in 1 .. 8 |-> 0],
      fillDirtyPx      |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp ==
    { ZeroFillsGrpComp }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillYield = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillDirtyPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Instrmnt Leg Exec Grp Comp: 32 bytes                                    *)
(***************************************************************************)

InstrmntLegExecGrpComp3 ==
    [ legSecurityId : Sample(8),
      legLastPx     : Sample(8),
      legLastQty    : Sample(4),
      legExecId     : Sample(4),
      legSide       : Sample(1),
      noFillsIndex  : Sample(1),
      pad6          : Sample(6) ]

EncodeInstrmntLegExecGrpComp3(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noFillsIndex
        \o message.pad6

DecodeInstrmntLegExecGrpComp3(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noFillsIndex == ReadBytes(legSide.rest, 1) IN IF ~noFillsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFillsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legLastPx     |-> legLastPx.value,
         legLastQty    |-> legLastQty.value,
         legExecId     |-> legExecId.value,
         legSide       |-> legSide.value,
         noFillsIndex  |-> noFillsIndex.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroInstrmntLegExecGrpComp3 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legExecId     |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      noFillsIndex  |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmnt Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmntLegExecGrpComp3 ==
    { ZeroInstrmntLegExecGrpComp3 }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.noFillsIndex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp3 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmnt Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeInstrmntLegExecGrpComp3List(_)
EncodeInstrmntLegExecGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmntLegExecGrpComp3(Head(messages)) \o EncodeInstrmntLegExecGrpComp3List(Tail(messages))

(* As many Instrmnt Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmntLegExecGrpComp3List(_, _)
ReadInstrmntLegExecGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmntLegExecGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmntLegExecGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmnt Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneInstrmntLegExecGrpComp3 == { ZeroInstrmntLegExecGrpComp3 }

(***************************************************************************)
(* Order Exec Notification                                                 *)
(***************************************************************************)

OrderExecNotification ==
    [ filler4                : Sample(2),
      rbcHeaderMeComp        : RbcHeaderMeComp6,
      orderId                : Sample(8),
      senderLocationId       : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      activityTime           : Sample(8),
      filler1                : Sample(8),
      filler2                : Sample(4),
      messageTag             : Sample(4),
      marketSegmentId        : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      filler4v2              : Sample(2),
      execRestatementReason  : Sample(2),
      accountType            : Sample(1),
      productComplex         : Sample(1),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      triggered              : Sample(1),
      side                   : Sample(1),
      rolloverFlag           : Sample(1),
      account                : Sample(2),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      freeText3              : Sample(12),
      pad4                   : Sample(4),
      fillsGrpComp           : SampleLists(OneFillsGrpComp),
      instrmntLegExecGrpComp : SampleLists(OneInstrmntLegExecGrpComp3) ]

EncodeOrderExecNotification(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp6(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.senderLocationId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.messageTag
        \o message.marketSegmentId
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o EncodeUIntLE(Len(message.instrmntLegExecGrpComp), 2)
        \o message.filler4v2
        \o message.execRestatementReason
        \o message.accountType
        \o message.productComplex
        \o message.ordStatus
        \o message.execType
        \o message.triggered
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.side
        \o message.rolloverFlag
        \o message.account
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o message.pad4
        \o EncodeFillsGrpCompList(message.fillsGrpComp)
        \o EncodeInstrmntLegExecGrpComp3List(message.instrmntLegExecGrpComp)

DecodeOrderExecNotification(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp6(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(orderId.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(execId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler2.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(messageTag.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(cxlQty.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(noLegExecs.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(filler4v2.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET accountType == ReadBytes(execRestatementReason.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(accountType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(productComplex.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET triggered == ReadBytes(execType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(triggered.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET side == ReadBytes(noFills.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(side.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET account == ReadBytes(rolloverFlag.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET algoId == ReadBytes(account.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET pad4 == ReadBytes(freeText3.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpCompList(pad4.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    LET instrmntLegExecGrpComp == ReadInstrmntLegExecGrpComp3List(fillsGrpComp.rest, noLegExecs.value) IN IF ~instrmntLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         rbcHeaderMeComp        |-> rbcHeaderMeComp.value,
         orderId                |-> orderId.value,
         senderLocationId       |-> senderLocationId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         activityTime           |-> activityTime.value,
         filler1                |-> filler1.value,
         filler2                |-> filler2.value,
         messageTag             |-> messageTag.value,
         marketSegmentId        |-> marketSegmentId.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         filler4v2              |-> filler4v2.value,
         execRestatementReason  |-> execRestatementReason.value,
         accountType            |-> accountType.value,
         productComplex         |-> productComplex.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         triggered              |-> triggered.value,
         side                   |-> side.value,
         rolloverFlag           |-> rolloverFlag.value,
         account                |-> account.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         freeText3              |-> freeText3.value,
         pad4                   |-> pad4.value,
         fillsGrpComp           |-> fillsGrpComp.value,
         instrmntLegExecGrpComp |-> instrmntLegExecGrpComp.value ], instrmntLegExecGrpComp.rest)

ZeroOrderExecNotification ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp        |-> ZeroRbcHeaderMeComp6,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      activityTime           |-> [i \in 1 .. 8 |-> 0],
      filler1                |-> [i \in 1 .. 8 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      messageTag             |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      filler4v2              |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag           |-> [i \in 1 .. 1 |-> 0],
      account                |-> [i \in 1 .. 2 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      freeText3              |-> [i \in 1 .. 12 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0],
      fillsGrpComp           |-> << >>,
      instrmntLegExecGrpComp |-> << >> ]

(* Order Exec Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecNotification ==
    { ZeroOrderExecNotification }
        \cup { [ZeroOrderExecNotification EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp6 }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecNotification EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecNotification EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecNotification EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp) }
        \cup { [ZeroOrderExecNotification EXCEPT !.instrmntLegExecGrpComp = one] : one \in SampleLists(OneInstrmntLegExecGrpComp3) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp7 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp7(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp7(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp7 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp7 ==
    { ZeroRbcHeaderMeComp7 }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Leg Ord Grp Comp: 8 bytes                                               *)
(***************************************************************************)

LegOrdGrpComp ==
    [ legAccount        : Sample(2),
      legPositionEffect : Sample(1),
      pad5              : Sample(5) ]

EncodeLegOrdGrpComp(message) ==
    message.legAccount
        \o message.legPositionEffect
        \o message.pad5

DecodeLegOrdGrpComp(bytes) ==
    LET legAccount == ReadBytes(bytes, 2) IN IF ~legAccount.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legAccount.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    LET pad5 == ReadBytes(legPositionEffect.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ legAccount        |-> legAccount.value,
         legPositionEffect |-> legPositionEffect.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroLegOrdGrpComp ==
    [ legAccount        |-> [i \in 1 .. 2 |-> 0],
      legPositionEffect |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Leg Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedLegOrdGrpComp ==
    { ZeroLegOrdGrpComp }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.legAccount = one] : one \in Sample(2) }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.legPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroLegOrdGrpComp EXCEPT !.pad5 = one] : one \in Sample(5) }

(* A run of Leg Ord Grp Comp, written one after another *)
RECURSIVE EncodeLegOrdGrpCompList(_)
EncodeLegOrdGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegOrdGrpComp(Head(messages)) \o EncodeLegOrdGrpCompList(Tail(messages))

(* As many Leg Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadLegOrdGrpCompList(_, _)
ReadLegOrdGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegOrdGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegOrdGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Ord Grp Comp of each kind, for the lists that carry them *)
OneLegOrdGrpComp == { ZeroLegOrdGrpComp }

(***************************************************************************)
(* Fills Grp Comp: 40 bytes                                                *)
(***************************************************************************)

FillsGrpComp2 ==
    [ fillPx           : Sample(8),
      fillYield        : Sample(8),
      fillDirtyPx      : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp2(message) ==
    message.fillPx
        \o message.fillYield
        \o message.fillDirtyPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp2(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillYield == ReadBytes(fillPx.rest, 8) IN IF ~fillYield.ok THEN Fail ELSE
    LET fillDirtyPx == ReadBytes(fillYield.rest, 8) IN IF ~fillDirtyPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillDirtyPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillYield        |-> fillYield.value,
         fillDirtyPx      |-> fillDirtyPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp2 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillYield        |-> [i \in 1 .. 8 |-> 0],
      fillDirtyPx      |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp2 ==
    { ZeroFillsGrpComp2 }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillYield = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillDirtyPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Fills Grp Comp, written one after another *)
RECURSIVE EncodeFillsGrpComp2List(_)
EncodeFillsGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGrpComp2(Head(messages)) \o EncodeFillsGrpComp2List(Tail(messages))

(* As many Fills Grp Comp as the field that counts them says *)
RECURSIVE ReadFillsGrpComp2List(_, _)
ReadFillsGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Grp Comp of each kind, for the lists that carry them *)
OneFillsGrpComp2 == { ZeroFillsGrpComp2 }

(***************************************************************************)
(* Instrmnt Leg Exec Grp Comp: 32 bytes                                    *)
(***************************************************************************)

InstrmntLegExecGrpComp4 ==
    [ legSecurityId : Sample(8),
      legLastPx     : Sample(8),
      legLastQty    : Sample(4),
      legExecId     : Sample(4),
      legSide       : Sample(1),
      noFillsIndex  : Sample(1),
      pad6          : Sample(6) ]

EncodeInstrmntLegExecGrpComp4(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noFillsIndex
        \o message.pad6

DecodeInstrmntLegExecGrpComp4(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noFillsIndex == ReadBytes(legSide.rest, 1) IN IF ~noFillsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFillsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legLastPx     |-> legLastPx.value,
         legLastQty    |-> legLastQty.value,
         legExecId     |-> legExecId.value,
         legSide       |-> legSide.value,
         noFillsIndex  |-> noFillsIndex.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroInstrmntLegExecGrpComp4 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legExecId     |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      noFillsIndex  |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmnt Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmntLegExecGrpComp4 ==
    { ZeroInstrmntLegExecGrpComp4 }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.noFillsIndex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp4 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmnt Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeInstrmntLegExecGrpComp4List(_)
EncodeInstrmntLegExecGrpComp4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmntLegExecGrpComp4(Head(messages)) \o EncodeInstrmntLegExecGrpComp4List(Tail(messages))

(* As many Instrmnt Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmntLegExecGrpComp4List(_, _)
ReadInstrmntLegExecGrpComp4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmntLegExecGrpComp4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmntLegExecGrpComp4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmnt Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneInstrmntLegExecGrpComp4 == { ZeroInstrmntLegExecGrpComp4 }

(***************************************************************************)
(* Order Exec Report Broadcast                                             *)
(***************************************************************************)

OrderExecReportBroadcast ==
    [ filler4                     : Sample(2),
      rbcHeaderMeComp             : RbcHeaderMeComp7,
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8),
      securityId                  : Sample(8),
      maxPricePercentage          : Sample(8),
      senderLocationId            : Sample(8),
      execId                      : Sample(8),
      trdRegTsEntryTime           : Sample(8),
      trdRegTsTimePriority        : Sample(8),
      price                       : Sample(8),
      stopPx                      : Sample(8),
      underlyingDirtyPrice        : Sample(8),
      yield                       : Sample(8),
      activityTime                : Sample(8),
      filler1                     : Sample(8),
      filler2                     : Sample(4),
      marketSegmentId             : Sample(4),
      messageTag                  : Sample(4),
      leavesQty                   : Sample(4),
      maxShow                     : Sample(4),
      cumQty                      : Sample(4),
      cxlQty                      : Sample(4),
      orderQty                    : Sample(4),
      expireDate                  : Sample(4),
      partyIdExecutingUnit        : Sample(4),
      partyIdSessionId            : Sample(4),
      partyIdExecutingTrader      : Sample(4),
      partyIdEnteringTrader       : Sample(4),
      filler4v2                   : Sample(2),
      execRestatementReason       : Sample(2),
      accountType                 : Sample(1),
      partyIdEnteringFirm         : Sample(1),
      productComplex              : Sample(1),
      ordStatus                   : Sample(1),
      execType                    : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      tradingCapacity             : Sample(1),
      timeInForce                 : Sample(1),
      execInst                    : Sample(1),
      tradingSessionSubId         : Sample(1),
      applSeqIndicator            : Sample(1),
      stpcFlag                    : Sample(1),
      rolloverFlag                : Sample(1),
      account                     : Sample(2),
      positionEffect              : Sample(1),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      regulatoryText              : Sample(20),
      algoId                      : Sample(16),
      clientCode                  : Sample(12),
      cpCode                      : Sample(12),
      freeText3                   : Sample(12),
      triggered                   : Sample(1),
      pad2                        : Sample(2),
      legOrdGrpComp               : SampleLists(OneLegOrdGrpComp),
      fillsGrpComp                : SampleLists(OneFillsGrpComp2),
      instrmntLegExecGrpComp      : SampleLists(OneInstrmntLegExecGrpComp4) ]

EncodeOrderExecReportBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp7(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.maxPricePercentage
        \o message.senderLocationId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.price
        \o message.stopPx
        \o message.underlyingDirtyPrice
        \o message.yield
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.marketSegmentId
        \o message.messageTag
        \o message.leavesQty
        \o message.maxShow
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.expireDate
        \o message.partyIdExecutingUnit
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o message.filler4v2
        \o EncodeUIntLE(Len(message.instrmntLegExecGrpComp), 2)
        \o message.execRestatementReason
        \o message.accountType
        \o message.partyIdEnteringFirm
        \o message.productComplex
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.ordType
        \o message.tradingCapacity
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.applSeqIndicator
        \o message.stpcFlag
        \o message.rolloverFlag
        \o message.account
        \o message.positionEffect
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.regulatoryText
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.triggered
        \o message.pad2
        \o EncodeLegOrdGrpCompList(message.legOrdGrpComp)
        \o EncodeFillsGrpComp2List(message.fillsGrpComp)
        \o EncodeInstrmntLegExecGrpComp4List(message.instrmntLegExecGrpComp)

DecodeOrderExecReportBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp7(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(securityId.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(maxPricePercentage.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET execId == ReadBytes(senderLocationId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET price == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(stopPx.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET yield == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET activityTime == ReadBytes(yield.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(filler2.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(marketSegmentId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(messageTag.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(leavesQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET cumQty == ReadBytes(maxShow.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(expireDate.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(partyIdEnteringTrader.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(filler4v2.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(noLegExecs.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET accountType == ReadBytes(execRestatementReason.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(accountType.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET productComplex == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(productComplex.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(ordType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(tradingCapacity.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(applSeqIndicator.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(stpcFlag.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET account == ReadBytes(rolloverFlag.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(account.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(positionEffect.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET regulatoryText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~regulatoryText.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryText.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(freeText3.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(noFills.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET triggered == ReadBytes(noLegs.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET pad2 == ReadBytes(triggered.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpCompList(pad2.rest, noLegs.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp2List(legOrdGrpComp.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    LET instrmntLegExecGrpComp == ReadInstrmntLegExecGrpComp4List(fillsGrpComp.rest, noLegExecs.value) IN IF ~instrmntLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4                     |-> filler4.value,
         rbcHeaderMeComp             |-> rbcHeaderMeComp.value,
         orderId                     |-> orderId.value,
         clOrdId                     |-> clOrdId.value,
         origClOrdId                 |-> origClOrdId.value,
         securityId                  |-> securityId.value,
         maxPricePercentage          |-> maxPricePercentage.value,
         senderLocationId            |-> senderLocationId.value,
         execId                      |-> execId.value,
         trdRegTsEntryTime           |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority        |-> trdRegTsTimePriority.value,
         price                       |-> price.value,
         stopPx                      |-> stopPx.value,
         underlyingDirtyPrice        |-> underlyingDirtyPrice.value,
         yield                       |-> yield.value,
         activityTime                |-> activityTime.value,
         filler1                     |-> filler1.value,
         filler2                     |-> filler2.value,
         marketSegmentId             |-> marketSegmentId.value,
         messageTag                  |-> messageTag.value,
         leavesQty                   |-> leavesQty.value,
         maxShow                     |-> maxShow.value,
         cumQty                      |-> cumQty.value,
         cxlQty                      |-> cxlQty.value,
         orderQty                    |-> orderQty.value,
         expireDate                  |-> expireDate.value,
         partyIdExecutingUnit        |-> partyIdExecutingUnit.value,
         partyIdSessionId            |-> partyIdSessionId.value,
         partyIdExecutingTrader      |-> partyIdExecutingTrader.value,
         partyIdEnteringTrader       |-> partyIdEnteringTrader.value,
         filler4v2                   |-> filler4v2.value,
         execRestatementReason       |-> execRestatementReason.value,
         accountType                 |-> accountType.value,
         partyIdEnteringFirm         |-> partyIdEnteringFirm.value,
         productComplex              |-> productComplex.value,
         ordStatus                   |-> ordStatus.value,
         execType                    |-> execType.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         tradingCapacity             |-> tradingCapacity.value,
         timeInForce                 |-> timeInForce.value,
         execInst                    |-> execInst.value,
         tradingSessionSubId         |-> tradingSessionSubId.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         stpcFlag                    |-> stpcFlag.value,
         rolloverFlag                |-> rolloverFlag.value,
         account                     |-> account.value,
         positionEffect              |-> positionEffect.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         regulatoryText              |-> regulatoryText.value,
         algoId                      |-> algoId.value,
         clientCode                  |-> clientCode.value,
         cpCode                      |-> cpCode.value,
         freeText3                   |-> freeText3.value,
         triggered                   |-> triggered.value,
         pad2                        |-> pad2.value,
         legOrdGrpComp               |-> legOrdGrpComp.value,
         fillsGrpComp                |-> fillsGrpComp.value,
         instrmntLegExecGrpComp      |-> instrmntLegExecGrpComp.value ], instrmntLegExecGrpComp.rest)

ZeroOrderExecReportBroadcast ==
    [ filler4                     |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp             |-> ZeroRbcHeaderMeComp7,
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage          |-> [i \in 1 .. 8 |-> 0],
      senderLocationId            |-> [i \in 1 .. 8 |-> 0],
      execId                      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime           |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority        |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      stopPx                      |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice        |-> [i \in 1 .. 8 |-> 0],
      yield                       |-> [i \in 1 .. 8 |-> 0],
      activityTime                |-> [i \in 1 .. 8 |-> 0],
      filler1                     |-> [i \in 1 .. 8 |-> 0],
      filler2                     |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      messageTag                  |-> [i \in 1 .. 4 |-> 0],
      leavesQty                   |-> [i \in 1 .. 4 |-> 0],
      maxShow                     |-> [i \in 1 .. 4 |-> 0],
      cumQty                      |-> [i \in 1 .. 4 |-> 0],
      cxlQty                      |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit        |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId            |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader      |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader       |-> [i \in 1 .. 4 |-> 0],
      filler4v2                   |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason       |-> [i \in 1 .. 2 |-> 0],
      accountType                 |-> [i \in 1 .. 1 |-> 0],
      partyIdEnteringFirm         |-> [i \in 1 .. 1 |-> 0],
      productComplex              |-> [i \in 1 .. 1 |-> 0],
      ordStatus                   |-> [i \in 1 .. 1 |-> 0],
      execType                    |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId         |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      stpcFlag                    |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      regulatoryText              |-> [i \in 1 .. 20 |-> 0],
      algoId                      |-> [i \in 1 .. 16 |-> 0],
      clientCode                  |-> [i \in 1 .. 12 |-> 0],
      cpCode                      |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      triggered                   |-> [i \in 1 .. 1 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      legOrdGrpComp               |-> << >>,
      fillsGrpComp                |-> << >>,
      instrmntLegExecGrpComp      |-> << >> ]

(* Order Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecReportBroadcast ==
    { ZeroOrderExecReportBroadcast }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp7 }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.regulatoryText = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.instrmntLegExecGrpComp = one] : one \in SampleLists(OneInstrmntLegExecGrpComp4) }

(***************************************************************************)
(* Response Header Me Comp: 72 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp6 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      partitionId     : Sample(2),
      applId          : Sample(1),
      applMsgId       : Sample(16),
      lastFragment    : Sample(1) ]

EncodeResponseHeaderMeComp6(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.partitionId
        \o message.applId
        \o message.applMsgId
        \o message.lastFragment

DecodeResponseHeaderMeComp6(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         partitionId     |-> partitionId.value,
         applId          |-> applId.value,
         applMsgId       |-> applMsgId.value,
         lastFragment    |-> lastFragment.value ], lastFragment.rest)

ZeroResponseHeaderMeComp6 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0] ]

(* Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderMeComp6 ==
    { ZeroResponseHeaderMeComp6 }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroResponseHeaderMeComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }

(***************************************************************************)
(* Fills Grp Comp: 40 bytes                                                *)
(***************************************************************************)

FillsGrpComp3 ==
    [ fillPx           : Sample(8),
      fillYield        : Sample(8),
      fillDirtyPx      : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp3(message) ==
    message.fillPx
        \o message.fillYield
        \o message.fillDirtyPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp3(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillYield == ReadBytes(fillPx.rest, 8) IN IF ~fillYield.ok THEN Fail ELSE
    LET fillDirtyPx == ReadBytes(fillYield.rest, 8) IN IF ~fillDirtyPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillDirtyPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillYield        |-> fillYield.value,
         fillDirtyPx      |-> fillDirtyPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp3 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillYield        |-> [i \in 1 .. 8 |-> 0],
      fillDirtyPx      |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp3 ==
    { ZeroFillsGrpComp3 }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillYield = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillDirtyPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Fills Grp Comp, written one after another *)
RECURSIVE EncodeFillsGrpComp3List(_)
EncodeFillsGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGrpComp3(Head(messages)) \o EncodeFillsGrpComp3List(Tail(messages))

(* As many Fills Grp Comp as the field that counts them says *)
RECURSIVE ReadFillsGrpComp3List(_, _)
ReadFillsGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Grp Comp of each kind, for the lists that carry them *)
OneFillsGrpComp3 == { ZeroFillsGrpComp3 }

(***************************************************************************)
(* Instrmnt Leg Exec Grp Comp: 32 bytes                                    *)
(***************************************************************************)

InstrmntLegExecGrpComp5 ==
    [ legSecurityId : Sample(8),
      legLastPx     : Sample(8),
      legLastQty    : Sample(4),
      legExecId     : Sample(4),
      legSide       : Sample(1),
      noFillsIndex  : Sample(1),
      pad6          : Sample(6) ]

EncodeInstrmntLegExecGrpComp5(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noFillsIndex
        \o message.pad6

DecodeInstrmntLegExecGrpComp5(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noFillsIndex == ReadBytes(legSide.rest, 1) IN IF ~noFillsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFillsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId |-> legSecurityId.value,
         legLastPx     |-> legLastPx.value,
         legLastQty    |-> legLastQty.value,
         legExecId     |-> legExecId.value,
         legSide       |-> legSide.value,
         noFillsIndex  |-> noFillsIndex.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroInstrmntLegExecGrpComp5 ==
    [ legSecurityId |-> [i \in 1 .. 8 |-> 0],
      legLastPx     |-> [i \in 1 .. 8 |-> 0],
      legLastQty    |-> [i \in 1 .. 4 |-> 0],
      legExecId     |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0],
      noFillsIndex  |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmnt Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmntLegExecGrpComp5 ==
    { ZeroInstrmntLegExecGrpComp5 }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.noFillsIndex = one] : one \in Sample(1) }
        \cup { [ZeroInstrmntLegExecGrpComp5 EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmnt Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeInstrmntLegExecGrpComp5List(_)
EncodeInstrmntLegExecGrpComp5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmntLegExecGrpComp5(Head(messages)) \o EncodeInstrmntLegExecGrpComp5List(Tail(messages))

(* As many Instrmnt Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmntLegExecGrpComp5List(_, _)
ReadInstrmntLegExecGrpComp5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmntLegExecGrpComp5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmntLegExecGrpComp5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmnt Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneInstrmntLegExecGrpComp5 == { ZeroInstrmntLegExecGrpComp5 }

(***************************************************************************)
(* Order Exec Response                                                     *)
(***************************************************************************)

OrderExecResponse ==
    [ filler4                : Sample(2),
      responseHeaderMeComp   : ResponseHeaderMeComp6,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      trdRegTsEntryTime      : Sample(8),
      trdRegTsTimePriority   : Sample(8),
      activityTime           : Sample(8),
      price                  : Sample(8),
      filler2                : Sample(4),
      marketSegmentId        : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      filler4v2              : Sample(2),
      execRestatementReason  : Sample(2),
      productComplex         : Sample(1),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      triggered              : Sample(1),
      rolloverFlag           : Sample(1),
      algoId                 : Sample(16),
      fillsGrpComp           : SampleLists(OneFillsGrpComp3),
      instrmntLegExecGrpComp : SampleLists(OneInstrmntLegExecGrpComp5) ]

EncodeOrderExecResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderMeComp6(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.activityTime
        \o message.price
        \o message.filler2
        \o message.marketSegmentId
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.filler4v2
        \o EncodeUIntLE(Len(message.instrmntLegExecGrpComp), 2)
        \o message.execRestatementReason
        \o message.productComplex
        \o message.ordStatus
        \o message.execType
        \o message.triggered
        \o message.rolloverFlag
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.algoId
        \o EncodeFillsGrpComp3List(message.fillsGrpComp)
        \o EncodeInstrmntLegExecGrpComp5List(message.instrmntLegExecGrpComp)

DecodeOrderExecResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp6(filler4.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET activityTime == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET price == ReadBytes(activityTime.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET filler2 == ReadBytes(price.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(filler2.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(cxlQty.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(filler4v2.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(noLegExecs.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET productComplex == ReadBytes(execRestatementReason.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(productComplex.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET triggered == ReadBytes(execType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(triggered.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(rolloverFlag.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET algoId == ReadBytes(noFills.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp3List(algoId.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    LET instrmntLegExecGrpComp == ReadInstrmntLegExecGrpComp5List(fillsGrpComp.rest, noLegExecs.value) IN IF ~instrmntLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         responseHeaderMeComp   |-> responseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         trdRegTsEntryTime      |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority   |-> trdRegTsTimePriority.value,
         activityTime           |-> activityTime.value,
         price                  |-> price.value,
         filler2                |-> filler2.value,
         marketSegmentId        |-> marketSegmentId.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         filler4v2              |-> filler4v2.value,
         execRestatementReason  |-> execRestatementReason.value,
         productComplex         |-> productComplex.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         triggered              |-> triggered.value,
         rolloverFlag           |-> rolloverFlag.value,
         algoId                 |-> algoId.value,
         fillsGrpComp           |-> fillsGrpComp.value,
         instrmntLegExecGrpComp |-> instrmntLegExecGrpComp.value ], instrmntLegExecGrpComp.rest)

ZeroOrderExecResponse ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp   |-> ZeroResponseHeaderMeComp6,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority   |-> [i \in 1 .. 8 |-> 0],
      activityTime           |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      filler4v2              |-> [i \in 1 .. 2 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag           |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      fillsGrpComp           |-> << >>,
      instrmntLegExecGrpComp |-> << >> ]

(* Order Exec Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecResponse ==
    { ZeroOrderExecResponse }
        \cup { [ZeroOrderExecResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp6 }
        \cup { [ZeroOrderExecResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecResponse EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp3) }
        \cup { [ZeroOrderExecResponse EXCEPT !.instrmntLegExecGrpComp = one] : one \in SampleLists(OneInstrmntLegExecGrpComp5) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp8 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp8(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp8(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp8 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp8 ==
    { ZeroRbcHeaderMeComp8 }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Quote Event Grp Comp: 104 bytes                                         *)
(***************************************************************************)

QuoteEventGrpComp ==
    [ orderId                : Sample(8),
      senderLocationId       : Sample(8),
      securityId             : Sample(8),
      quoteEventPx           : Sample(8),
      quoteMsgId             : Sample(8),
      quoteEventMatchId      : Sample(4),
      messageTag             : Sample(4),
      quoteEventExecId       : Sample(4),
      quoteEventQty          : Sample(4),
      quoteEventType         : Sample(1),
      quoteEventSide         : Sample(1),
      quoteEventLiquidityInd : Sample(1),
      quoteEventReason       : Sample(1),
      accountType            : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      pad3                   : Sample(3) ]

EncodeQuoteEventGrpComp(message) ==
    message.orderId
        \o message.senderLocationId
        \o message.securityId
        \o message.quoteEventPx
        \o message.quoteMsgId
        \o message.quoteEventMatchId
        \o message.messageTag
        \o message.quoteEventExecId
        \o message.quoteEventQty
        \o message.quoteEventType
        \o message.quoteEventSide
        \o message.quoteEventLiquidityInd
        \o message.quoteEventReason
        \o message.accountType
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad3

DecodeQuoteEventGrpComp(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(orderId.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET securityId == ReadBytes(senderLocationId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEventPx == ReadBytes(securityId.rest, 8) IN IF ~quoteEventPx.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(quoteEventPx.rest, 8) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(quoteMsgId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(messageTag.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventExecId.rest, 4) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(quoteEventQty.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET quoteEventLiquidityInd == ReadBytes(quoteEventSide.rest, 1) IN IF ~quoteEventLiquidityInd.ok THEN Fail ELSE
    LET quoteEventReason == ReadBytes(quoteEventLiquidityInd.rest, 1) IN IF ~quoteEventReason.ok THEN Fail ELSE
    LET accountType == ReadBytes(quoteEventReason.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET algoId == ReadBytes(accountType.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad3 == ReadBytes(cpCode.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ orderId                |-> orderId.value,
         senderLocationId       |-> senderLocationId.value,
         securityId             |-> securityId.value,
         quoteEventPx           |-> quoteEventPx.value,
         quoteMsgId             |-> quoteMsgId.value,
         quoteEventMatchId      |-> quoteEventMatchId.value,
         messageTag             |-> messageTag.value,
         quoteEventExecId       |-> quoteEventExecId.value,
         quoteEventQty          |-> quoteEventQty.value,
         quoteEventType         |-> quoteEventType.value,
         quoteEventSide         |-> quoteEventSide.value,
         quoteEventLiquidityInd |-> quoteEventLiquidityInd.value,
         quoteEventReason       |-> quoteEventReason.value,
         accountType            |-> accountType.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         pad3                   |-> pad3.value ], pad3.rest)

ZeroQuoteEventGrpComp ==
    [ orderId                |-> [i \in 1 .. 8 |-> 0],
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventPx           |-> [i \in 1 .. 8 |-> 0],
      quoteMsgId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventMatchId      |-> [i \in 1 .. 4 |-> 0],
      messageTag             |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId       |-> [i \in 1 .. 4 |-> 0],
      quoteEventQty          |-> [i \in 1 .. 4 |-> 0],
      quoteEventType         |-> [i \in 1 .. 1 |-> 0],
      quoteEventSide         |-> [i \in 1 .. 1 |-> 0],
      quoteEventLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      quoteEventReason       |-> [i \in 1 .. 1 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEventGrpComp ==
    { ZeroQuoteEventGrpComp }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Quote Event Grp Comp, written one after another *)
RECURSIVE EncodeQuoteEventGrpCompList(_)
EncodeQuoteEventGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEventGrpComp(Head(messages)) \o EncodeQuoteEventGrpCompList(Tail(messages))

(* As many Quote Event Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteEventGrpCompList(_, _)
ReadQuoteEventGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEventGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEventGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Event Grp Comp of each kind, for the lists that carry them *)
OneQuoteEventGrpComp == { ZeroQuoteEventGrpComp }

(***************************************************************************)
(* Quote Exec Report Broadcast                                             *)
(***************************************************************************)

QuoteExecReportBroadcast ==
    [ filler4           : Sample(2),
      rbcHeaderMeComp   : RbcHeaderMeComp8,
      execId            : Sample(8),
      stpcFlag          : Sample(1),
      pad6              : Sample(6),
      quoteEventGrpComp : SampleLists(OneQuoteEventGrpComp) ]

EncodeQuoteExecReportBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp8(message.rbcHeaderMeComp)
        \o message.execId
        \o EncodeUIntBE(Len(message.quoteEventGrpComp), 1)
        \o message.stpcFlag
        \o message.pad6
        \o EncodeQuoteEventGrpCompList(message.quoteEventGrpComp)

DecodeQuoteExecReportBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp8(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET noQuoteEvents == ReadUIntBE(execId.rest, 1) IN IF ~noQuoteEvents.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(noQuoteEvents.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET pad6 == ReadBytes(stpcFlag.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET quoteEventGrpComp == ReadQuoteEventGrpCompList(pad6.rest, noQuoteEvents.value) IN IF ~quoteEventGrpComp.ok THEN Fail ELSE
    Ok([ filler4           |-> filler4.value,
         rbcHeaderMeComp   |-> rbcHeaderMeComp.value,
         execId            |-> execId.value,
         stpcFlag          |-> stpcFlag.value,
         pad6              |-> pad6.value,
         quoteEventGrpComp |-> quoteEventGrpComp.value ], quoteEventGrpComp.rest)

ZeroQuoteExecReportBroadcast ==
    [ filler4           |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp   |-> ZeroRbcHeaderMeComp8,
      execId            |-> [i \in 1 .. 8 |-> 0],
      stpcFlag          |-> [i \in 1 .. 1 |-> 0],
      pad6              |-> [i \in 1 .. 6 |-> 0],
      quoteEventGrpComp |-> << >> ]

(* Quote Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecReportBroadcast ==
    { ZeroQuoteExecReportBroadcast }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp8 }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroQuoteExecReportBroadcast EXCEPT !.quoteEventGrpComp = one] : one \in SampleLists(OneQuoteEventGrpComp) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp9 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp9(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp9(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp9 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp9 ==
    { ZeroRbcHeaderMeComp9 }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Quote Event Grp Comp: 104 bytes                                         *)
(***************************************************************************)

QuoteEventGrpComp2 ==
    [ orderId                : Sample(8),
      senderLocationId       : Sample(8),
      securityId             : Sample(8),
      quoteEventPx           : Sample(8),
      quoteMsgId             : Sample(8),
      quoteEventMatchId      : Sample(4),
      messageTag             : Sample(4),
      quoteEventExecId       : Sample(4),
      quoteEventQty          : Sample(4),
      quoteEventType         : Sample(1),
      quoteEventSide         : Sample(1),
      quoteEventLiquidityInd : Sample(1),
      quoteEventReason       : Sample(1),
      accountType            : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      pad3                   : Sample(3) ]

EncodeQuoteEventGrpComp2(message) ==
    message.orderId
        \o message.senderLocationId
        \o message.securityId
        \o message.quoteEventPx
        \o message.quoteMsgId
        \o message.quoteEventMatchId
        \o message.messageTag
        \o message.quoteEventExecId
        \o message.quoteEventQty
        \o message.quoteEventType
        \o message.quoteEventSide
        \o message.quoteEventLiquidityInd
        \o message.quoteEventReason
        \o message.accountType
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad3

DecodeQuoteEventGrpComp2(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(orderId.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET securityId == ReadBytes(senderLocationId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEventPx == ReadBytes(securityId.rest, 8) IN IF ~quoteEventPx.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(quoteEventPx.rest, 8) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(quoteMsgId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(messageTag.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventExecId.rest, 4) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(quoteEventQty.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET quoteEventLiquidityInd == ReadBytes(quoteEventSide.rest, 1) IN IF ~quoteEventLiquidityInd.ok THEN Fail ELSE
    LET quoteEventReason == ReadBytes(quoteEventLiquidityInd.rest, 1) IN IF ~quoteEventReason.ok THEN Fail ELSE
    LET accountType == ReadBytes(quoteEventReason.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET algoId == ReadBytes(accountType.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad3 == ReadBytes(cpCode.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ orderId                |-> orderId.value,
         senderLocationId       |-> senderLocationId.value,
         securityId             |-> securityId.value,
         quoteEventPx           |-> quoteEventPx.value,
         quoteMsgId             |-> quoteMsgId.value,
         quoteEventMatchId      |-> quoteEventMatchId.value,
         messageTag             |-> messageTag.value,
         quoteEventExecId       |-> quoteEventExecId.value,
         quoteEventQty          |-> quoteEventQty.value,
         quoteEventType         |-> quoteEventType.value,
         quoteEventSide         |-> quoteEventSide.value,
         quoteEventLiquidityInd |-> quoteEventLiquidityInd.value,
         quoteEventReason       |-> quoteEventReason.value,
         accountType            |-> accountType.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         pad3                   |-> pad3.value ], pad3.rest)

ZeroQuoteEventGrpComp2 ==
    [ orderId                |-> [i \in 1 .. 8 |-> 0],
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventPx           |-> [i \in 1 .. 8 |-> 0],
      quoteMsgId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventMatchId      |-> [i \in 1 .. 4 |-> 0],
      messageTag             |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId       |-> [i \in 1 .. 4 |-> 0],
      quoteEventQty          |-> [i \in 1 .. 4 |-> 0],
      quoteEventType         |-> [i \in 1 .. 1 |-> 0],
      quoteEventSide         |-> [i \in 1 .. 1 |-> 0],
      quoteEventLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      quoteEventReason       |-> [i \in 1 .. 1 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

(* Quote Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEventGrpComp2 ==
    { ZeroQuoteEventGrpComp2 }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.quoteEventReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroQuoteEventGrpComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Quote Event Grp Comp, written one after another *)
RECURSIVE EncodeQuoteEventGrpComp2List(_)
EncodeQuoteEventGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEventGrpComp2(Head(messages)) \o EncodeQuoteEventGrpComp2List(Tail(messages))

(* As many Quote Event Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteEventGrpComp2List(_, _)
ReadQuoteEventGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEventGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEventGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Event Grp Comp of each kind, for the lists that carry them *)
OneQuoteEventGrpComp2 == { ZeroQuoteEventGrpComp2 }

(***************************************************************************)
(* Quote Leg Exec Grp Comp: 32 bytes                                       *)
(***************************************************************************)

QuoteLegExecGrpComp ==
    [ legSecurityId      : Sample(8),
      legLastPx          : Sample(8),
      legLastQty         : Sample(4),
      legExecId          : Sample(4),
      legSide            : Sample(1),
      noQuoteEventsIndex : Sample(1),
      pad6               : Sample(6) ]

EncodeQuoteLegExecGrpComp(message) ==
    message.legSecurityId
        \o message.legLastPx
        \o message.legLastQty
        \o message.legExecId
        \o message.legSide
        \o message.noQuoteEventsIndex
        \o message.pad6

DecodeQuoteLegExecGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legLastPx == ReadBytes(legSecurityId.rest, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 4) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legExecId == ReadBytes(legLastQty.rest, 4) IN IF ~legExecId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legExecId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET noQuoteEventsIndex == ReadBytes(legSide.rest, 1) IN IF ~noQuoteEventsIndex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noQuoteEventsIndex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId      |-> legSecurityId.value,
         legLastPx          |-> legLastPx.value,
         legLastQty         |-> legLastQty.value,
         legExecId          |-> legExecId.value,
         legSide            |-> legSide.value,
         noQuoteEventsIndex |-> noQuoteEventsIndex.value,
         pad6               |-> pad6.value ], pad6.rest)

ZeroQuoteLegExecGrpComp ==
    [ legSecurityId      |-> [i \in 1 .. 8 |-> 0],
      legLastPx          |-> [i \in 1 .. 8 |-> 0],
      legLastQty         |-> [i \in 1 .. 4 |-> 0],
      legExecId          |-> [i \in 1 .. 4 |-> 0],
      legSide            |-> [i \in 1 .. 1 |-> 0],
      noQuoteEventsIndex |-> [i \in 1 .. 1 |-> 0],
      pad6               |-> [i \in 1 .. 6 |-> 0] ]

(* Quote Leg Exec Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteLegExecGrpComp ==
    { ZeroQuoteLegExecGrpComp }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.legLastQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.legExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.noQuoteEventsIndex = one] : one \in Sample(1) }
        \cup { [ZeroQuoteLegExecGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Quote Leg Exec Grp Comp, written one after another *)
RECURSIVE EncodeQuoteLegExecGrpCompList(_)
EncodeQuoteLegExecGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteLegExecGrpComp(Head(messages)) \o EncodeQuoteLegExecGrpCompList(Tail(messages))

(* As many Quote Leg Exec Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteLegExecGrpCompList(_, _)
ReadQuoteLegExecGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteLegExecGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteLegExecGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Leg Exec Grp Comp of each kind, for the lists that carry them *)
OneQuoteLegExecGrpComp == { ZeroQuoteLegExecGrpComp }

(***************************************************************************)
(* Quote Execution Report                                                  *)
(***************************************************************************)

QuoteExecutionReport ==
    [ filler4             : Sample(2),
      rbcHeaderMeComp     : RbcHeaderMeComp9,
      execId              : Sample(8),
      marketSegmentId     : Sample(4),
      stpcFlag            : Sample(1),
      quoteEventGrpComp   : SampleLists(OneQuoteEventGrpComp2),
      quoteLegExecGrpComp : SampleLists(OneQuoteLegExecGrpComp) ]

EncodeQuoteExecutionReport(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp9(message.rbcHeaderMeComp)
        \o message.execId
        \o message.marketSegmentId
        \o EncodeUIntLE(Len(message.quoteLegExecGrpComp), 2)
        \o EncodeUIntBE(Len(message.quoteEventGrpComp), 1)
        \o message.stpcFlag
        \o EncodeQuoteEventGrpComp2List(message.quoteEventGrpComp)
        \o EncodeQuoteLegExecGrpCompList(message.quoteLegExecGrpComp)

DecodeQuoteExecutionReport(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp9(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(execId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noLegExecs == ReadUIntLE(marketSegmentId.rest, 2) IN IF ~noLegExecs.ok THEN Fail ELSE
    LET noQuoteEvents == ReadUIntBE(noLegExecs.rest, 1) IN IF ~noQuoteEvents.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(noQuoteEvents.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET quoteEventGrpComp == ReadQuoteEventGrpComp2List(stpcFlag.rest, noQuoteEvents.value) IN IF ~quoteEventGrpComp.ok THEN Fail ELSE
    LET quoteLegExecGrpComp == ReadQuoteLegExecGrpCompList(quoteEventGrpComp.rest, noLegExecs.value) IN IF ~quoteLegExecGrpComp.ok THEN Fail ELSE
    Ok([ filler4             |-> filler4.value,
         rbcHeaderMeComp     |-> rbcHeaderMeComp.value,
         execId              |-> execId.value,
         marketSegmentId     |-> marketSegmentId.value,
         stpcFlag            |-> stpcFlag.value,
         quoteEventGrpComp   |-> quoteEventGrpComp.value,
         quoteLegExecGrpComp |-> quoteLegExecGrpComp.value ], quoteLegExecGrpComp.rest)

ZeroQuoteExecutionReport ==
    [ filler4             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp     |-> ZeroRbcHeaderMeComp9,
      execId              |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId     |-> [i \in 1 .. 4 |-> 0],
      stpcFlag            |-> [i \in 1 .. 1 |-> 0],
      quoteEventGrpComp   |-> << >>,
      quoteLegExecGrpComp |-> << >> ]

(* Quote Execution Report at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionReport ==
    { ZeroQuoteExecutionReport }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp9 }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.quoteEventGrpComp = one] : one \in SampleLists(OneQuoteEventGrpComp2) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.quoteLegExecGrpComp = one] : one \in SampleLists(OneQuoteLegExecGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp9 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp9(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp9(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET requestOut == ReadBytes(requestTime.rest, 8) IN IF ~requestOut.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestOut.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         requestOut      |-> requestOut.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp9 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      requestOut      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp9 ==
    { ZeroNrResponseHeaderMeComp9 }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Reject                                                                  *)
(***************************************************************************)

Reject ==
    [ filler4                : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp9,
      sessionRejectReason    : Sample(4),
      sessionStatus          : Sample(1),
      pad1                   : Sample(1),
      varText                : SampleBytes,
      alignmentPadding       : SampleBytes ]

EncodeReject(message) ==
    message.filler4
        \o EncodeNrResponseHeaderMeComp9(message.nrResponseHeaderMeComp)
        \o message.sessionRejectReason
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.sessionStatus
        \o message.pad1
        \o message.varText
        \o message.alignmentPadding

DecodeReject(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp9(filler4.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(nrResponseHeaderMeComp.rest, 4) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(sessionRejectReason.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET sessionStatus == ReadBytes(varTextLen.rest, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET pad1 == ReadBytes(sessionStatus.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET varText == ReadBytes(pad1.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4                |-> filler4.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         sessionRejectReason    |-> sessionRejectReason.value,
         sessionStatus          |-> sessionStatus.value,
         pad1                   |-> pad1.value,
         varText                |-> varText.value,
         alignmentPadding       |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroReject ==
    [ filler4                |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp9,
      sessionRejectReason    |-> [i \in 1 .. 4 |-> 0],
      sessionStatus          |-> [i \in 1 .. 1 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      varText                |-> << >>,
      alignmentPadding       |-> << >> ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroReject EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp9 }
        \cup { [ZeroReject EXCEPT !.sessionRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroReject EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroReject EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp6 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp6(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp6(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp6 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp6 ==
    { ZeroResponseHeaderComp6 }
        \cup { [ZeroResponseHeaderComp6 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp6 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Me Message Response: 66 bytes                                *)
(***************************************************************************)

RetransmitMeMessageResponse ==
    [ filler4               : Sample(2),
      responseHeaderComp    : ResponseHeaderComp6,
      applTotalMessageCount : Sample(2),
      applEndMsgId          : Sample(16),
      refApplLastMsgId      : Sample(16),
      pad6                  : Sample(6) ]

EncodeRetransmitMeMessageResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp6(message.responseHeaderComp)
        \o message.applTotalMessageCount
        \o message.applEndMsgId
        \o message.refApplLastMsgId
        \o message.pad6

DecodeRetransmitMeMessageResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp6(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applTotalMessageCount == ReadBytes(responseHeaderComp.rest, 2) IN IF ~applTotalMessageCount.ok THEN Fail ELSE
    LET applEndMsgId == ReadBytes(applTotalMessageCount.rest, 16) IN IF ~applEndMsgId.ok THEN Fail ELSE
    LET refApplLastMsgId == ReadBytes(applEndMsgId.rest, 16) IN IF ~refApplLastMsgId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(refApplLastMsgId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderComp    |-> responseHeaderComp.value,
         applTotalMessageCount |-> applTotalMessageCount.value,
         applEndMsgId          |-> applEndMsgId.value,
         refApplLastMsgId      |-> refApplLastMsgId.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroRetransmitMeMessageResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp    |-> ZeroResponseHeaderComp6,
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      applEndMsgId          |-> [i \in 1 .. 16 |-> 0],
      refApplLastMsgId      |-> [i \in 1 .. 16 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Me Message Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitMeMessageResponse ==
    { ZeroRetransmitMeMessageResponse }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp6 }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.applTotalMessageCount = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.refApplLastMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp7 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp7(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp7(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp7 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp7 ==
    { ZeroResponseHeaderComp7 }
        \cup { [ZeroResponseHeaderComp7 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp7 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Response: 50 bytes                                           *)
(***************************************************************************)

RetransmitResponse ==
    [ filler4               : Sample(2),
      responseHeaderComp    : ResponseHeaderComp7,
      applEndSeqNum         : Sample(8),
      refApplLastSeqNum     : Sample(8),
      applTotalMessageCount : Sample(2),
      pad6                  : Sample(6) ]

EncodeRetransmitResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp7(message.responseHeaderComp)
        \o message.applEndSeqNum
        \o message.refApplLastSeqNum
        \o message.applTotalMessageCount
        \o message.pad6

DecodeRetransmitResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp7(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(responseHeaderComp.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET refApplLastSeqNum == ReadBytes(applEndSeqNum.rest, 8) IN IF ~refApplLastSeqNum.ok THEN Fail ELSE
    LET applTotalMessageCount == ReadBytes(refApplLastSeqNum.rest, 2) IN IF ~applTotalMessageCount.ok THEN Fail ELSE
    LET pad6 == ReadBytes(applTotalMessageCount.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ filler4               |-> filler4.value,
         responseHeaderComp    |-> responseHeaderComp.value,
         applEndSeqNum         |-> applEndSeqNum.value,
         refApplLastSeqNum     |-> refApplLastSeqNum.value,
         applTotalMessageCount |-> applTotalMessageCount.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroRetransmitResponse ==
    [ filler4               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp    |-> ZeroResponseHeaderComp7,
      applEndSeqNum         |-> [i \in 1 .. 8 |-> 0],
      refApplLastSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitResponse ==
    { ZeroRetransmitResponse }
        \cup { [ZeroRetransmitResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp7 }
        \cup { [ZeroRetransmitResponse EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitResponse EXCEPT !.refApplLastSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitResponse EXCEPT !.applTotalMessageCount = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp2 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp2(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp2(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp2 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp2 ==
    { ZeroRbcHeaderComp2 }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Risk Collateral Alert Admin Broadcast                                   *)
(***************************************************************************)

RiskCollateralAlertAdminBroadcast ==
    [ filler4                  : Sample(2),
      rbcHeaderComp            : RbcHeaderComp2,
      totalCollateral          : Sample(8),
      utilizedCollateral       : Sample(8),
      unutilizedCollateral     : Sample(8),
      origTime                 : Sample(8),
      percentageUtilized       : Sample(4),
      marketSegmentId          : Sample(4),
      marketId                 : Sample(2),
      rrmState                 : Sample(1),
      memberType               : Sample(1),
      incrementDecrementStatus : Sample(1),
      segmentIndicator         : Sample(1),
      duration                 : Sample(1),
      clientCode               : Sample(12),
      businessUnitSymbol       : Sample(8),
      pad3                     : Sample(3),
      varText                  : SampleBytes,
      alignmentPadding         : SampleBytes ]

EncodeRiskCollateralAlertAdminBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp2(message.rbcHeaderComp)
        \o message.totalCollateral
        \o message.utilizedCollateral
        \o message.unutilizedCollateral
        \o message.origTime
        \o message.percentageUtilized
        \o message.marketSegmentId
        \o message.marketId
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.rrmState
        \o message.memberType
        \o message.incrementDecrementStatus
        \o message.segmentIndicator
        \o message.duration
        \o message.clientCode
        \o message.businessUnitSymbol
        \o message.pad3
        \o message.varText
        \o message.alignmentPadding

DecodeRiskCollateralAlertAdminBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp2(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET totalCollateral == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~totalCollateral.ok THEN Fail ELSE
    LET utilizedCollateral == ReadBytes(totalCollateral.rest, 8) IN IF ~utilizedCollateral.ok THEN Fail ELSE
    LET unutilizedCollateral == ReadBytes(utilizedCollateral.rest, 8) IN IF ~unutilizedCollateral.ok THEN Fail ELSE
    LET origTime == ReadBytes(unutilizedCollateral.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET percentageUtilized == ReadBytes(origTime.rest, 4) IN IF ~percentageUtilized.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(percentageUtilized.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET marketId == ReadBytes(marketSegmentId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(marketId.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET rrmState == ReadBytes(varTextLen.rest, 1) IN IF ~rrmState.ok THEN Fail ELSE
    LET memberType == ReadBytes(rrmState.rest, 1) IN IF ~memberType.ok THEN Fail ELSE
    LET incrementDecrementStatus == ReadBytes(memberType.rest, 1) IN IF ~incrementDecrementStatus.ok THEN Fail ELSE
    LET segmentIndicator == ReadBytes(incrementDecrementStatus.rest, 1) IN IF ~segmentIndicator.ok THEN Fail ELSE
    LET duration == ReadBytes(segmentIndicator.rest, 1) IN IF ~duration.ok THEN Fail ELSE
    LET clientCode == ReadBytes(duration.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET businessUnitSymbol == ReadBytes(clientCode.rest, 8) IN IF ~businessUnitSymbol.ok THEN Fail ELSE
    LET pad3 == ReadBytes(businessUnitSymbol.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET varText == ReadBytes(pad3.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4                  |-> filler4.value,
         rbcHeaderComp            |-> rbcHeaderComp.value,
         totalCollateral          |-> totalCollateral.value,
         utilizedCollateral       |-> utilizedCollateral.value,
         unutilizedCollateral     |-> unutilizedCollateral.value,
         origTime                 |-> origTime.value,
         percentageUtilized       |-> percentageUtilized.value,
         marketSegmentId          |-> marketSegmentId.value,
         marketId                 |-> marketId.value,
         rrmState                 |-> rrmState.value,
         memberType               |-> memberType.value,
         incrementDecrementStatus |-> incrementDecrementStatus.value,
         segmentIndicator         |-> segmentIndicator.value,
         duration                 |-> duration.value,
         clientCode               |-> clientCode.value,
         businessUnitSymbol       |-> businessUnitSymbol.value,
         pad3                     |-> pad3.value,
         varText                  |-> varText.value,
         alignmentPadding         |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroRiskCollateralAlertAdminBroadcast ==
    [ filler4                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp            |-> ZeroRbcHeaderComp2,
      totalCollateral          |-> [i \in 1 .. 8 |-> 0],
      utilizedCollateral       |-> [i \in 1 .. 8 |-> 0],
      unutilizedCollateral     |-> [i \in 1 .. 8 |-> 0],
      origTime                 |-> [i \in 1 .. 8 |-> 0],
      percentageUtilized       |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      marketId                 |-> [i \in 1 .. 2 |-> 0],
      rrmState                 |-> [i \in 1 .. 1 |-> 0],
      memberType               |-> [i \in 1 .. 1 |-> 0],
      incrementDecrementStatus |-> [i \in 1 .. 1 |-> 0],
      segmentIndicator         |-> [i \in 1 .. 1 |-> 0],
      duration                 |-> [i \in 1 .. 1 |-> 0],
      clientCode               |-> [i \in 1 .. 12 |-> 0],
      businessUnitSymbol       |-> [i \in 1 .. 8 |-> 0],
      pad3                     |-> [i \in 1 .. 3 |-> 0],
      varText                  |-> << >>,
      alignmentPadding         |-> << >> ]

(* Risk Collateral Alert Admin Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRiskCollateralAlertAdminBroadcast ==
    { ZeroRiskCollateralAlertAdminBroadcast }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp2 }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.totalCollateral = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.utilizedCollateral = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.unutilizedCollateral = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.percentageUtilized = one] : one \in Sample(4) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.rrmState = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.memberType = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.incrementDecrementStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.segmentIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.duration = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.businessUnitSymbol = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroRiskCollateralAlertAdminBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp3 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp3(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp3(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp3 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp3 ==
    { ZeroRbcHeaderComp3 }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp3 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Risk Collateral Alert Broadcast                                         *)
(***************************************************************************)

RiskCollateralAlertBroadcast ==
    [ filler4                  : Sample(2),
      rbcHeaderComp            : RbcHeaderComp3,
      origTime                 : Sample(8),
      percentageUtilized       : Sample(4),
      marketSegmentId          : Sample(4),
      marketId                 : Sample(2),
      rrmState                 : Sample(1),
      memberType               : Sample(1),
      incrementDecrementStatus : Sample(1),
      segmentIndicator         : Sample(1),
      duration                 : Sample(1),
      clientCode               : Sample(12),
      businessUnitSymbol       : Sample(8),
      pad3                     : Sample(3),
      varText                  : SampleBytes,
      alignmentPadding         : SampleBytes ]

EncodeRiskCollateralAlertBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp3(message.rbcHeaderComp)
        \o message.origTime
        \o message.percentageUtilized
        \o message.marketSegmentId
        \o message.marketId
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.rrmState
        \o message.memberType
        \o message.incrementDecrementStatus
        \o message.segmentIndicator
        \o message.duration
        \o message.clientCode
        \o message.businessUnitSymbol
        \o message.pad3
        \o message.varText
        \o message.alignmentPadding

DecodeRiskCollateralAlertBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp3(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET origTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET percentageUtilized == ReadBytes(origTime.rest, 4) IN IF ~percentageUtilized.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(percentageUtilized.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET marketId == ReadBytes(marketSegmentId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(marketId.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET rrmState == ReadBytes(varTextLen.rest, 1) IN IF ~rrmState.ok THEN Fail ELSE
    LET memberType == ReadBytes(rrmState.rest, 1) IN IF ~memberType.ok THEN Fail ELSE
    LET incrementDecrementStatus == ReadBytes(memberType.rest, 1) IN IF ~incrementDecrementStatus.ok THEN Fail ELSE
    LET segmentIndicator == ReadBytes(incrementDecrementStatus.rest, 1) IN IF ~segmentIndicator.ok THEN Fail ELSE
    LET duration == ReadBytes(segmentIndicator.rest, 1) IN IF ~duration.ok THEN Fail ELSE
    LET clientCode == ReadBytes(duration.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET businessUnitSymbol == ReadBytes(clientCode.rest, 8) IN IF ~businessUnitSymbol.ok THEN Fail ELSE
    LET pad3 == ReadBytes(businessUnitSymbol.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET varText == ReadBytes(pad3.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4                  |-> filler4.value,
         rbcHeaderComp            |-> rbcHeaderComp.value,
         origTime                 |-> origTime.value,
         percentageUtilized       |-> percentageUtilized.value,
         marketSegmentId          |-> marketSegmentId.value,
         marketId                 |-> marketId.value,
         rrmState                 |-> rrmState.value,
         memberType               |-> memberType.value,
         incrementDecrementStatus |-> incrementDecrementStatus.value,
         segmentIndicator         |-> segmentIndicator.value,
         duration                 |-> duration.value,
         clientCode               |-> clientCode.value,
         businessUnitSymbol       |-> businessUnitSymbol.value,
         pad3                     |-> pad3.value,
         varText                  |-> varText.value,
         alignmentPadding         |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroRiskCollateralAlertBroadcast ==
    [ filler4                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp            |-> ZeroRbcHeaderComp3,
      origTime                 |-> [i \in 1 .. 8 |-> 0],
      percentageUtilized       |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      marketId                 |-> [i \in 1 .. 2 |-> 0],
      rrmState                 |-> [i \in 1 .. 1 |-> 0],
      memberType               |-> [i \in 1 .. 1 |-> 0],
      incrementDecrementStatus |-> [i \in 1 .. 1 |-> 0],
      segmentIndicator         |-> [i \in 1 .. 1 |-> 0],
      duration                 |-> [i \in 1 .. 1 |-> 0],
      clientCode               |-> [i \in 1 .. 12 |-> 0],
      businessUnitSymbol       |-> [i \in 1 .. 8 |-> 0],
      pad3                     |-> [i \in 1 .. 3 |-> 0],
      varText                  |-> << >>,
      alignmentPadding         |-> << >> ]

(* Risk Collateral Alert Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRiskCollateralAlertBroadcast ==
    { ZeroRiskCollateralAlertBroadcast }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp3 }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.percentageUtilized = one] : one \in Sample(4) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.rrmState = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.memberType = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.incrementDecrementStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.segmentIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.duration = one] : one \in Sample(1) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.businessUnitSymbol = one] : one \in Sample(8) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroRiskCollateralAlertBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp4 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp4(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp4(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp4 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp4 ==
    { ZeroRbcHeaderComp4 }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp4 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Risk Notification Broadcast: 106 bytes                                  *)
(***************************************************************************)

RiskNotificationBroadcast ==
    [ filler4                          : Sample(2),
      rbcHeaderComp                    : RbcHeaderComp4,
      transactTime                     : Sample(8),
      tradeDate                        : Sample(4),
      partyDetailIdExecutingUnit       : Sample(4),
      requestingPartyIdExecutingSystem : Sample(4),
      marketSegmentId                  : Sample(4),
      marketId                         : Sample(2),
      riskModeStatus                   : Sample(1),
      segmentIndicator                 : Sample(1),
      listUpdateAction                 : Sample(1),
      riskLimitAction                  : Sample(1),
      scopeIdentifier                  : Sample(1),
      clientCode                       : Sample(12),
      requestingPartyEnteringFirm      : Sample(9),
      requestingPartyClearingFirm      : Sample(9),
      businessUnitSymbol               : Sample(8),
      pad3                             : Sample(3) ]

EncodeRiskNotificationBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp4(message.rbcHeaderComp)
        \o message.transactTime
        \o message.tradeDate
        \o message.partyDetailIdExecutingUnit
        \o message.requestingPartyIdExecutingSystem
        \o message.marketSegmentId
        \o message.marketId
        \o message.riskModeStatus
        \o message.segmentIndicator
        \o message.listUpdateAction
        \o message.riskLimitAction
        \o message.scopeIdentifier
        \o message.clientCode
        \o message.requestingPartyEnteringFirm
        \o message.requestingPartyClearingFirm
        \o message.businessUnitSymbol
        \o message.pad3

DecodeRiskNotificationBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp4(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(transactTime.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET partyDetailIdExecutingUnit == ReadBytes(tradeDate.rest, 4) IN IF ~partyDetailIdExecutingUnit.ok THEN Fail ELSE
    LET requestingPartyIdExecutingSystem == ReadBytes(partyDetailIdExecutingUnit.rest, 4) IN IF ~requestingPartyIdExecutingSystem.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestingPartyIdExecutingSystem.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET marketId == ReadBytes(marketSegmentId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET riskModeStatus == ReadBytes(marketId.rest, 1) IN IF ~riskModeStatus.ok THEN Fail ELSE
    LET segmentIndicator == ReadBytes(riskModeStatus.rest, 1) IN IF ~segmentIndicator.ok THEN Fail ELSE
    LET listUpdateAction == ReadBytes(segmentIndicator.rest, 1) IN IF ~listUpdateAction.ok THEN Fail ELSE
    LET riskLimitAction == ReadBytes(listUpdateAction.rest, 1) IN IF ~riskLimitAction.ok THEN Fail ELSE
    LET scopeIdentifier == ReadBytes(riskLimitAction.rest, 1) IN IF ~scopeIdentifier.ok THEN Fail ELSE
    LET clientCode == ReadBytes(scopeIdentifier.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET requestingPartyEnteringFirm == ReadBytes(clientCode.rest, 9) IN IF ~requestingPartyEnteringFirm.ok THEN Fail ELSE
    LET requestingPartyClearingFirm == ReadBytes(requestingPartyEnteringFirm.rest, 9) IN IF ~requestingPartyClearingFirm.ok THEN Fail ELSE
    LET businessUnitSymbol == ReadBytes(requestingPartyClearingFirm.rest, 8) IN IF ~businessUnitSymbol.ok THEN Fail ELSE
    LET pad3 == ReadBytes(businessUnitSymbol.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ filler4                          |-> filler4.value,
         rbcHeaderComp                    |-> rbcHeaderComp.value,
         transactTime                     |-> transactTime.value,
         tradeDate                        |-> tradeDate.value,
         partyDetailIdExecutingUnit       |-> partyDetailIdExecutingUnit.value,
         requestingPartyIdExecutingSystem |-> requestingPartyIdExecutingSystem.value,
         marketSegmentId                  |-> marketSegmentId.value,
         marketId                         |-> marketId.value,
         riskModeStatus                   |-> riskModeStatus.value,
         segmentIndicator                 |-> segmentIndicator.value,
         listUpdateAction                 |-> listUpdateAction.value,
         riskLimitAction                  |-> riskLimitAction.value,
         scopeIdentifier                  |-> scopeIdentifier.value,
         clientCode                       |-> clientCode.value,
         requestingPartyEnteringFirm      |-> requestingPartyEnteringFirm.value,
         requestingPartyClearingFirm      |-> requestingPartyClearingFirm.value,
         businessUnitSymbol               |-> businessUnitSymbol.value,
         pad3                             |-> pad3.value ], pad3.rest)

ZeroRiskNotificationBroadcast ==
    [ filler4                          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                    |-> ZeroRbcHeaderComp4,
      transactTime                     |-> [i \in 1 .. 8 |-> 0],
      tradeDate                        |-> [i \in 1 .. 4 |-> 0],
      partyDetailIdExecutingUnit       |-> [i \in 1 .. 4 |-> 0],
      requestingPartyIdExecutingSystem |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                  |-> [i \in 1 .. 4 |-> 0],
      marketId                         |-> [i \in 1 .. 2 |-> 0],
      riskModeStatus                   |-> [i \in 1 .. 1 |-> 0],
      segmentIndicator                 |-> [i \in 1 .. 1 |-> 0],
      listUpdateAction                 |-> [i \in 1 .. 1 |-> 0],
      riskLimitAction                  |-> [i \in 1 .. 1 |-> 0],
      scopeIdentifier                  |-> [i \in 1 .. 1 |-> 0],
      clientCode                       |-> [i \in 1 .. 12 |-> 0],
      requestingPartyEnteringFirm      |-> [i \in 1 .. 9 |-> 0],
      requestingPartyClearingFirm      |-> [i \in 1 .. 9 |-> 0],
      businessUnitSymbol               |-> [i \in 1 .. 8 |-> 0],
      pad3                             |-> [i \in 1 .. 3 |-> 0] ]

(* Risk Notification Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRiskNotificationBroadcast ==
    { ZeroRiskNotificationBroadcast }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp4 }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.partyDetailIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.requestingPartyIdExecutingSystem = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.riskModeStatus = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.segmentIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.listUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.riskLimitAction = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.scopeIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.requestingPartyEnteringFirm = one] : one \in Sample(9) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.requestingPartyClearingFirm = one] : one \in Sample(9) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.businessUnitSymbol = one] : one \in Sample(8) }
        \cup { [ZeroRiskNotificationBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Nrbc Header Comp: 16 bytes                                              *)
(***************************************************************************)

NrbcHeaderComp ==
    [ sendingTime  : Sample(8),
      applSubId    : Sample(4),
      applId       : Sample(1),
      lastFragment : Sample(1),
      pad2         : Sample(2) ]

EncodeNrbcHeaderComp(message) ==
    message.sendingTime
        \o message.applSubId
        \o message.applId
        \o message.lastFragment
        \o message.pad2

DecodeNrbcHeaderComp(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET applId == ReadBytes(applSubId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad2 == ReadBytes(lastFragment.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ sendingTime  |-> sendingTime.value,
         applSubId    |-> applSubId.value,
         applId       |-> applId.value,
         lastFragment |-> lastFragment.value,
         pad2         |-> pad2.value ], pad2.rest)

ZeroNrbcHeaderComp ==
    [ sendingTime  |-> [i \in 1 .. 8 |-> 0],
      applSubId    |-> [i \in 1 .. 4 |-> 0],
      applId       |-> [i \in 1 .. 1 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      pad2         |-> [i \in 1 .. 2 |-> 0] ]

(* Nrbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrbcHeaderComp ==
    { ZeroNrbcHeaderComp }
        \cup { [ZeroNrbcHeaderComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrbcHeaderComp EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroNrbcHeaderComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroNrbcHeaderComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrbcHeaderComp EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Service Availability Broadcast: 42 bytes                                *)
(***************************************************************************)

ServiceAvailabilityBroadcast ==
    [ filler4                 : Sample(2),
      nrbcHeaderComp          : NrbcHeaderComp,
      matchingEngineTradeDate : Sample(4),
      tradeManagerTradeDate   : Sample(4),
      applSeqTradeDate        : Sample(4),
      partitionId             : Sample(2),
      matchingEngineStatus    : Sample(1),
      tradeManagerStatus      : Sample(1),
      applSeqStatus           : Sample(1),
      pad7                    : Sample(7) ]

EncodeServiceAvailabilityBroadcast(message) ==
    message.filler4
        \o EncodeNrbcHeaderComp(message.nrbcHeaderComp)
        \o message.matchingEngineTradeDate
        \o message.tradeManagerTradeDate
        \o message.applSeqTradeDate
        \o message.partitionId
        \o message.matchingEngineStatus
        \o message.tradeManagerStatus
        \o message.applSeqStatus
        \o message.pad7

DecodeServiceAvailabilityBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET nrbcHeaderComp == DecodeNrbcHeaderComp(filler4.rest) IN IF ~nrbcHeaderComp.ok THEN Fail ELSE
    LET matchingEngineTradeDate == ReadBytes(nrbcHeaderComp.rest, 4) IN IF ~matchingEngineTradeDate.ok THEN Fail ELSE
    LET tradeManagerTradeDate == ReadBytes(matchingEngineTradeDate.rest, 4) IN IF ~tradeManagerTradeDate.ok THEN Fail ELSE
    LET applSeqTradeDate == ReadBytes(tradeManagerTradeDate.rest, 4) IN IF ~applSeqTradeDate.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSeqTradeDate.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET matchingEngineStatus == ReadBytes(partitionId.rest, 1) IN IF ~matchingEngineStatus.ok THEN Fail ELSE
    LET tradeManagerStatus == ReadBytes(matchingEngineStatus.rest, 1) IN IF ~tradeManagerStatus.ok THEN Fail ELSE
    LET applSeqStatus == ReadBytes(tradeManagerStatus.rest, 1) IN IF ~applSeqStatus.ok THEN Fail ELSE
    LET pad7 == ReadBytes(applSeqStatus.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         nrbcHeaderComp          |-> nrbcHeaderComp.value,
         matchingEngineTradeDate |-> matchingEngineTradeDate.value,
         tradeManagerTradeDate   |-> tradeManagerTradeDate.value,
         applSeqTradeDate        |-> applSeqTradeDate.value,
         partitionId             |-> partitionId.value,
         matchingEngineStatus    |-> matchingEngineStatus.value,
         tradeManagerStatus      |-> tradeManagerStatus.value,
         applSeqStatus           |-> applSeqStatus.value,
         pad7                    |-> pad7.value ], pad7.rest)

ZeroServiceAvailabilityBroadcast ==
    [ filler4                 |-> [i \in 1 .. 2 |-> 0],
      nrbcHeaderComp          |-> ZeroNrbcHeaderComp,
      matchingEngineTradeDate |-> [i \in 1 .. 4 |-> 0],
      tradeManagerTradeDate   |-> [i \in 1 .. 4 |-> 0],
      applSeqTradeDate        |-> [i \in 1 .. 4 |-> 0],
      partitionId             |-> [i \in 1 .. 2 |-> 0],
      matchingEngineStatus    |-> [i \in 1 .. 1 |-> 0],
      tradeManagerStatus      |-> [i \in 1 .. 1 |-> 0],
      applSeqStatus           |-> [i \in 1 .. 1 |-> 0],
      pad7                    |-> [i \in 1 .. 7 |-> 0] ]

(* Service Availability Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedServiceAvailabilityBroadcast ==
    { ZeroServiceAvailabilityBroadcast }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.nrbcHeaderComp = one] : one \in CheckedNrbcHeaderComp }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.matchingEngineTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.tradeManagerTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.applSeqTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.matchingEngineStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.tradeManagerStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.applSeqStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp8 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp8(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp8(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp8 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp8 ==
    { ZeroResponseHeaderComp8 }
        \cup { [ZeroResponseHeaderComp8 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp8 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Password Change Response: 26 bytes                              *)
(***************************************************************************)

SessionPasswordChangeResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp8 ]

EncodeSessionPasswordChangeResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp8(message.responseHeaderComp)

DecodeSessionPasswordChangeResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp8(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroSessionPasswordChangeResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp8 ]

(* Session Password Change Response at zero, then each field in turn at the values it is checked at *)
CheckedSessionPasswordChangeResponse ==
    { ZeroSessionPasswordChangeResponse }
        \cup { [ZeroSessionPasswordChangeResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroSessionPasswordChangeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp8 }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp9 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp9(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp9(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp9 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp9 ==
    { ZeroResponseHeaderComp9 }
        \cup { [ZeroResponseHeaderComp9 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp9 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Registration Response                                           *)
(***************************************************************************)

SessionRegistrationResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp9,
      status             : Sample(1),
      pad1               : Sample(1),
      pad4               : Sample(4),
      varText            : SampleBytes,
      alignmentPadding   : SampleBytes ]

EncodeSessionRegistrationResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp9(message.responseHeaderComp)
        \o message.status
        \o message.pad1
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.pad4
        \o message.varText
        \o message.alignmentPadding

DecodeSessionRegistrationResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp9(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET status == ReadBytes(responseHeaderComp.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET pad1 == ReadBytes(status.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(pad1.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET pad4 == ReadBytes(varTextLen.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET varText == ReadBytes(pad4.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value,
         status             |-> status.value,
         pad1               |-> pad1.value,
         pad4               |-> pad4.value,
         varText            |-> varText.value,
         alignmentPadding   |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroSessionRegistrationResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp9,
      status             |-> [i \in 1 .. 1 |-> 0],
      pad1               |-> [i \in 1 .. 1 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0],
      varText            |-> << >>,
      alignmentPadding   |-> << >> ]

(* Session Registration Response at zero, then each field in turn at the values it is checked at *)
CheckedSessionRegistrationResponse ==
    { ZeroSessionRegistrationResponse }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp9 }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroSessionRegistrationResponse EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp10 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp10(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp10(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp10 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp10 ==
    { ZeroResponseHeaderComp10 }
        \cup { [ZeroResponseHeaderComp10 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp10 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscribe Response: 34 bytes                                            *)
(***************************************************************************)

SubscribeResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp10,
      applSubId          : Sample(4),
      pad4               : Sample(4) ]

EncodeSubscribeResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp10(message.responseHeaderComp)
        \o message.applSubId
        \o message.pad4

DecodeSubscribeResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp10(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applSubId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(applSubId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value,
         applSubId          |-> applSubId.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroSubscribeResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp10,
      applSubId          |-> [i \in 1 .. 4 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Subscribe Response at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeResponse ==
    { ZeroSubscribeResponse }
        \cup { [ZeroSubscribeResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp10 }
        \cup { [ZeroSubscribeResponse EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroSubscribeResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp5 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp5(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp5(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp5 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp5 ==
    { ZeroRbcHeaderComp5 }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp5 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Tm Trading Session Status Broadcast: 42 bytes                           *)
(***************************************************************************)

TmTradingSessionStatusBroadcast ==
    [ filler4       : Sample(2),
      rbcHeaderComp : RbcHeaderComp5,
      tradSesEvent  : Sample(1),
      pad7          : Sample(7) ]

EncodeTmTradingSessionStatusBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp5(message.rbcHeaderComp)
        \o message.tradSesEvent
        \o message.pad7

DecodeTmTradingSessionStatusBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp5(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(rbcHeaderComp.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad7 == ReadBytes(tradSesEvent.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ filler4       |-> filler4.value,
         rbcHeaderComp |-> rbcHeaderComp.value,
         tradSesEvent  |-> tradSesEvent.value,
         pad7          |-> pad7.value ], pad7.rest)

ZeroTmTradingSessionStatusBroadcast ==
    [ filler4       |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp |-> ZeroRbcHeaderComp5,
      tradSesEvent  |-> [i \in 1 .. 1 |-> 0],
      pad7          |-> [i \in 1 .. 7 |-> 0] ]

(* Tm Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTmTradingSessionStatusBroadcast ==
    { ZeroTmTradingSessionStatusBroadcast }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp5 }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Throttle Update Notification: 26 bytes                                  *)
(***************************************************************************)

ThrottleUpdateNotification ==
    [ filler4                 : Sample(2),
      notifHeaderComp         : NotifHeaderComp4,
      throttleTimeInterval    : Sample(8),
      throttleNoMsgs          : Sample(4),
      throttleDisconnectLimit : Sample(4) ]

EncodeThrottleUpdateNotification(message) ==
    message.filler4
        \o EncodeNotifHeaderComp4(message.notifHeaderComp)
        \o message.throttleTimeInterval
        \o message.throttleNoMsgs
        \o message.throttleDisconnectLimit

DecodeThrottleUpdateNotification(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp4(filler4.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET throttleTimeInterval == ReadBytes(notifHeaderComp.rest, 8) IN IF ~throttleTimeInterval.ok THEN Fail ELSE
    LET throttleNoMsgs == ReadBytes(throttleTimeInterval.rest, 4) IN IF ~throttleNoMsgs.ok THEN Fail ELSE
    LET throttleDisconnectLimit == ReadBytes(throttleNoMsgs.rest, 4) IN IF ~throttleDisconnectLimit.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         notifHeaderComp         |-> notifHeaderComp.value,
         throttleTimeInterval    |-> throttleTimeInterval.value,
         throttleNoMsgs          |-> throttleNoMsgs.value,
         throttleDisconnectLimit |-> throttleDisconnectLimit.value ], throttleDisconnectLimit.rest)

ZeroThrottleUpdateNotification ==
    [ filler4                 |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp         |-> ZeroNotifHeaderComp4,
      throttleTimeInterval    |-> [i \in 1 .. 8 |-> 0],
      throttleNoMsgs          |-> [i \in 1 .. 4 |-> 0],
      throttleDisconnectLimit |-> [i \in 1 .. 4 |-> 0] ]

(* Throttle Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedThrottleUpdateNotification ==
    { ZeroThrottleUpdateNotification }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp4 }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleNoMsgs = one] : one \in Sample(4) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleDisconnectLimit = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp6 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp6(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp6(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp6 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp6 ==
    { ZeroRbcHeaderComp6 }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp6 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trade Broadcast: 346 bytes                                              *)
(***************************************************************************)

TradeBroadcast ==
    [ filler4                         : Sample(2),
      rbcHeaderComp                   : RbcHeaderComp6,
      securityId                      : Sample(8),
      relatedSecurityId               : Sample(8),
      price                           : Sample(8),
      lastPx                          : Sample(8),
      sideLastPx                      : Sample(8),
      clearingTradePrice              : Sample(8),
      yield                           : Sample(8),
      underlyingDirtyPrice            : Sample(8),
      transactTime                    : Sample(8),
      orderId                         : Sample(8),
      senderLocationId                : Sample(8),
      clOrdId                         : Sample(8),
      activityTime                    : Sample(8),
      filler1                         : Sample(8),
      filler2                         : Sample(4),
      messageTag                      : Sample(4),
      tradeId                         : Sample(4),
      origTradeId                     : Sample(4),
      rootPartyIdExecutingUnit        : Sample(4),
      rootPartyIdSessionId            : Sample(4),
      rootPartyIdExecutingTrader      : Sample(4),
      rootPartyIdClearingUnit         : Sample(4),
      cumQty                          : Sample(4),
      leavesQty                       : Sample(4),
      marketSegmentId                 : Sample(4),
      relatedSymbol                   : Sample(4),
      lastQty                         : Sample(4),
      sideLastQty                     : Sample(4),
      clearingTradeQty                : Sample(4),
      sideTradeId                     : Sample(4),
      matchDate                       : Sample(4),
      trdMatchId                      : Sample(4),
      strategyLinkId                  : Sample(4),
      totNumTradeReports              : Sample(4),
      filler4v2                       : Sample(2),
      multiLegReportingType           : Sample(1),
      tradeReportType                 : Sample(1),
      transferReason                  : Sample(1),
      rolloverFlag                    : Sample(1),
      rootPartyIdBeneficiary          : Sample(9),
      rootPartyIdTakeUpTradingFirm    : Sample(5),
      rootPartyIdOrderOriginationFirm : Sample(7),
      accountType                     : Sample(1),
      matchType                       : Sample(1),
      matchSubType                    : Sample(1),
      side                            : Sample(1),
      aggressorIndicator              : Sample(1),
      tradingCapacity                 : Sample(1),
      account                         : Sample(2),
      positionEffect                  : Sample(1),
      custOrderHandlingInst           : Sample(1),
      algoId                          : Sample(16),
      clientCode                      : Sample(12),
      cpCode                          : Sample(12),
      freeText3                       : Sample(12),
      orderCategory                   : Sample(1),
      ordType                         : Sample(1),
      relatedProductComplex           : Sample(1),
      orderSide                       : Sample(1),
      rootPartyClearingOrganization   : Sample(4),
      rootPartyExecutingFirm          : Sample(5),
      rootPartyExecutingTrader        : Sample(6),
      rootPartyClearingFirm           : Sample(5),
      pad7                            : Sample(7) ]

EncodeTradeBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp6(message.rbcHeaderComp)
        \o message.securityId
        \o message.relatedSecurityId
        \o message.price
        \o message.lastPx
        \o message.sideLastPx
        \o message.clearingTradePrice
        \o message.yield
        \o message.underlyingDirtyPrice
        \o message.transactTime
        \o message.orderId
        \o message.senderLocationId
        \o message.clOrdId
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.messageTag
        \o message.tradeId
        \o message.origTradeId
        \o message.rootPartyIdExecutingUnit
        \o message.rootPartyIdSessionId
        \o message.rootPartyIdExecutingTrader
        \o message.rootPartyIdClearingUnit
        \o message.cumQty
        \o message.leavesQty
        \o message.marketSegmentId
        \o message.relatedSymbol
        \o message.lastQty
        \o message.sideLastQty
        \o message.clearingTradeQty
        \o message.sideTradeId
        \o message.matchDate
        \o message.trdMatchId
        \o message.strategyLinkId
        \o message.totNumTradeReports
        \o message.filler4v2
        \o message.multiLegReportingType
        \o message.tradeReportType
        \o message.transferReason
        \o message.rolloverFlag
        \o message.rootPartyIdBeneficiary
        \o message.rootPartyIdTakeUpTradingFirm
        \o message.rootPartyIdOrderOriginationFirm
        \o message.accountType
        \o message.matchType
        \o message.matchSubType
        \o message.side
        \o message.aggressorIndicator
        \o message.tradingCapacity
        \o message.account
        \o message.positionEffect
        \o message.custOrderHandlingInst
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o message.orderCategory
        \o message.ordType
        \o message.relatedProductComplex
        \o message.orderSide
        \o message.rootPartyClearingOrganization
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.rootPartyClearingFirm
        \o message.pad7

DecodeTradeBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp6(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET relatedSecurityId == ReadBytes(securityId.rest, 8) IN IF ~relatedSecurityId.ok THEN Fail ELSE
    LET price == ReadBytes(relatedSecurityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lastPx == ReadBytes(price.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET sideLastPx == ReadBytes(lastPx.rest, 8) IN IF ~sideLastPx.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(sideLastPx.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET yield == ReadBytes(clearingTradePrice.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET underlyingDirtyPrice == ReadBytes(yield.rest, 8) IN IF ~underlyingDirtyPrice.ok THEN Fail ELSE
    LET transactTime == ReadBytes(underlyingDirtyPrice.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(orderId.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(clOrdId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler2.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET tradeId == ReadBytes(messageTag.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(tradeId.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET rootPartyIdExecutingUnit == ReadBytes(origTradeId.rest, 4) IN IF ~rootPartyIdExecutingUnit.ok THEN Fail ELSE
    LET rootPartyIdSessionId == ReadBytes(rootPartyIdExecutingUnit.rest, 4) IN IF ~rootPartyIdSessionId.ok THEN Fail ELSE
    LET rootPartyIdExecutingTrader == ReadBytes(rootPartyIdSessionId.rest, 4) IN IF ~rootPartyIdExecutingTrader.ok THEN Fail ELSE
    LET rootPartyIdClearingUnit == ReadBytes(rootPartyIdExecutingTrader.rest, 4) IN IF ~rootPartyIdClearingUnit.ok THEN Fail ELSE
    LET cumQty == ReadBytes(rootPartyIdClearingUnit.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(leavesQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET relatedSymbol == ReadBytes(marketSegmentId.rest, 4) IN IF ~relatedSymbol.ok THEN Fail ELSE
    LET lastQty == ReadBytes(relatedSymbol.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET sideLastQty == ReadBytes(lastQty.rest, 4) IN IF ~sideLastQty.ok THEN Fail ELSE
    LET clearingTradeQty == ReadBytes(sideLastQty.rest, 4) IN IF ~clearingTradeQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(clearingTradeQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET matchDate == ReadBytes(sideTradeId.rest, 4) IN IF ~matchDate.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(matchDate.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET strategyLinkId == ReadBytes(trdMatchId.rest, 4) IN IF ~strategyLinkId.ok THEN Fail ELSE
    LET totNumTradeReports == ReadBytes(strategyLinkId.rest, 4) IN IF ~totNumTradeReports.ok THEN Fail ELSE
    LET filler4v2 == ReadBytes(totNumTradeReports.rest, 2) IN IF ~filler4v2.ok THEN Fail ELSE
    LET multiLegReportingType == ReadBytes(filler4v2.rest, 1) IN IF ~multiLegReportingType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(multiLegReportingType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET transferReason == ReadBytes(tradeReportType.rest, 1) IN IF ~transferReason.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(transferReason.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET rootPartyIdBeneficiary == ReadBytes(rolloverFlag.rest, 9) IN IF ~rootPartyIdBeneficiary.ok THEN Fail ELSE
    LET rootPartyIdTakeUpTradingFirm == ReadBytes(rootPartyIdBeneficiary.rest, 5) IN IF ~rootPartyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET rootPartyIdOrderOriginationFirm == ReadBytes(rootPartyIdTakeUpTradingFirm.rest, 7) IN IF ~rootPartyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET accountType == ReadBytes(rootPartyIdOrderOriginationFirm.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET matchType == ReadBytes(accountType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET matchSubType == ReadBytes(matchType.rest, 1) IN IF ~matchSubType.ok THEN Fail ELSE
    LET side == ReadBytes(matchSubType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(side.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(aggressorIndicator.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(tradingCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(account.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(positionEffect.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET algoId == ReadBytes(custOrderHandlingInst.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(freeText3.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderCategory.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET relatedProductComplex == ReadBytes(ordType.rest, 1) IN IF ~relatedProductComplex.ok THEN Fail ELSE
    LET orderSide == ReadBytes(relatedProductComplex.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET rootPartyClearingOrganization == ReadBytes(orderSide.rest, 4) IN IF ~rootPartyClearingOrganization.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(rootPartyClearingOrganization.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET rootPartyClearingFirm == ReadBytes(rootPartyExecutingTrader.rest, 5) IN IF ~rootPartyClearingFirm.ok THEN Fail ELSE
    LET pad7 == ReadBytes(rootPartyClearingFirm.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ filler4                         |-> filler4.value,
         rbcHeaderComp                   |-> rbcHeaderComp.value,
         securityId                      |-> securityId.value,
         relatedSecurityId               |-> relatedSecurityId.value,
         price                           |-> price.value,
         lastPx                          |-> lastPx.value,
         sideLastPx                      |-> sideLastPx.value,
         clearingTradePrice              |-> clearingTradePrice.value,
         yield                           |-> yield.value,
         underlyingDirtyPrice            |-> underlyingDirtyPrice.value,
         transactTime                    |-> transactTime.value,
         orderId                         |-> orderId.value,
         senderLocationId                |-> senderLocationId.value,
         clOrdId                         |-> clOrdId.value,
         activityTime                    |-> activityTime.value,
         filler1                         |-> filler1.value,
         filler2                         |-> filler2.value,
         messageTag                      |-> messageTag.value,
         tradeId                         |-> tradeId.value,
         origTradeId                     |-> origTradeId.value,
         rootPartyIdExecutingUnit        |-> rootPartyIdExecutingUnit.value,
         rootPartyIdSessionId            |-> rootPartyIdSessionId.value,
         rootPartyIdExecutingTrader      |-> rootPartyIdExecutingTrader.value,
         rootPartyIdClearingUnit         |-> rootPartyIdClearingUnit.value,
         cumQty                          |-> cumQty.value,
         leavesQty                       |-> leavesQty.value,
         marketSegmentId                 |-> marketSegmentId.value,
         relatedSymbol                   |-> relatedSymbol.value,
         lastQty                         |-> lastQty.value,
         sideLastQty                     |-> sideLastQty.value,
         clearingTradeQty                |-> clearingTradeQty.value,
         sideTradeId                     |-> sideTradeId.value,
         matchDate                       |-> matchDate.value,
         trdMatchId                      |-> trdMatchId.value,
         strategyLinkId                  |-> strategyLinkId.value,
         totNumTradeReports              |-> totNumTradeReports.value,
         filler4v2                       |-> filler4v2.value,
         multiLegReportingType           |-> multiLegReportingType.value,
         tradeReportType                 |-> tradeReportType.value,
         transferReason                  |-> transferReason.value,
         rolloverFlag                    |-> rolloverFlag.value,
         rootPartyIdBeneficiary          |-> rootPartyIdBeneficiary.value,
         rootPartyIdTakeUpTradingFirm    |-> rootPartyIdTakeUpTradingFirm.value,
         rootPartyIdOrderOriginationFirm |-> rootPartyIdOrderOriginationFirm.value,
         accountType                     |-> accountType.value,
         matchType                       |-> matchType.value,
         matchSubType                    |-> matchSubType.value,
         side                            |-> side.value,
         aggressorIndicator              |-> aggressorIndicator.value,
         tradingCapacity                 |-> tradingCapacity.value,
         account                         |-> account.value,
         positionEffect                  |-> positionEffect.value,
         custOrderHandlingInst           |-> custOrderHandlingInst.value,
         algoId                          |-> algoId.value,
         clientCode                      |-> clientCode.value,
         cpCode                          |-> cpCode.value,
         freeText3                       |-> freeText3.value,
         orderCategory                   |-> orderCategory.value,
         ordType                         |-> ordType.value,
         relatedProductComplex           |-> relatedProductComplex.value,
         orderSide                       |-> orderSide.value,
         rootPartyClearingOrganization   |-> rootPartyClearingOrganization.value,
         rootPartyExecutingFirm          |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader        |-> rootPartyExecutingTrader.value,
         rootPartyClearingFirm           |-> rootPartyClearingFirm.value,
         pad7                            |-> pad7.value ], pad7.rest)

ZeroTradeBroadcast ==
    [ filler4                         |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                   |-> ZeroRbcHeaderComp6,
      securityId                      |-> [i \in 1 .. 8 |-> 0],
      relatedSecurityId               |-> [i \in 1 .. 8 |-> 0],
      price                           |-> [i \in 1 .. 8 |-> 0],
      lastPx                          |-> [i \in 1 .. 8 |-> 0],
      sideLastPx                      |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice              |-> [i \in 1 .. 8 |-> 0],
      yield                           |-> [i \in 1 .. 8 |-> 0],
      underlyingDirtyPrice            |-> [i \in 1 .. 8 |-> 0],
      transactTime                    |-> [i \in 1 .. 8 |-> 0],
      orderId                         |-> [i \in 1 .. 8 |-> 0],
      senderLocationId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                         |-> [i \in 1 .. 8 |-> 0],
      activityTime                    |-> [i \in 1 .. 8 |-> 0],
      filler1                         |-> [i \in 1 .. 8 |-> 0],
      filler2                         |-> [i \in 1 .. 4 |-> 0],
      messageTag                      |-> [i \in 1 .. 4 |-> 0],
      tradeId                         |-> [i \in 1 .. 4 |-> 0],
      origTradeId                     |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingUnit        |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSessionId            |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingTrader      |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdClearingUnit         |-> [i \in 1 .. 4 |-> 0],
      cumQty                          |-> [i \in 1 .. 4 |-> 0],
      leavesQty                       |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                 |-> [i \in 1 .. 4 |-> 0],
      relatedSymbol                   |-> [i \in 1 .. 4 |-> 0],
      lastQty                         |-> [i \in 1 .. 4 |-> 0],
      sideLastQty                     |-> [i \in 1 .. 4 |-> 0],
      clearingTradeQty                |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                     |-> [i \in 1 .. 4 |-> 0],
      matchDate                       |-> [i \in 1 .. 4 |-> 0],
      trdMatchId                      |-> [i \in 1 .. 4 |-> 0],
      strategyLinkId                  |-> [i \in 1 .. 4 |-> 0],
      totNumTradeReports              |-> [i \in 1 .. 4 |-> 0],
      filler4v2                       |-> [i \in 1 .. 2 |-> 0],
      multiLegReportingType           |-> [i \in 1 .. 1 |-> 0],
      tradeReportType                 |-> [i \in 1 .. 1 |-> 0],
      transferReason                  |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                    |-> [i \in 1 .. 1 |-> 0],
      rootPartyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      rootPartyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      rootPartyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      accountType                     |-> [i \in 1 .. 1 |-> 0],
      matchType                       |-> [i \in 1 .. 1 |-> 0],
      matchSubType                    |-> [i \in 1 .. 1 |-> 0],
      side                            |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator              |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                 |-> [i \in 1 .. 1 |-> 0],
      account                         |-> [i \in 1 .. 2 |-> 0],
      positionEffect                  |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst           |-> [i \in 1 .. 1 |-> 0],
      algoId                          |-> [i \in 1 .. 16 |-> 0],
      clientCode                      |-> [i \in 1 .. 12 |-> 0],
      cpCode                          |-> [i \in 1 .. 12 |-> 0],
      freeText3                       |-> [i \in 1 .. 12 |-> 0],
      orderCategory                   |-> [i \in 1 .. 1 |-> 0],
      ordType                         |-> [i \in 1 .. 1 |-> 0],
      relatedProductComplex           |-> [i \in 1 .. 1 |-> 0],
      orderSide                       |-> [i \in 1 .. 1 |-> 0],
      rootPartyClearingOrganization   |-> [i \in 1 .. 4 |-> 0],
      rootPartyExecutingFirm          |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader        |-> [i \in 1 .. 6 |-> 0],
      rootPartyClearingFirm           |-> [i \in 1 .. 5 |-> 0],
      pad7                            |-> [i \in 1 .. 7 |-> 0] ]

(* Trade Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradeBroadcast ==
    { ZeroTradeBroadcast }
        \cup { [ZeroTradeBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp6 }
        \cup { [ZeroTradeBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.relatedSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.underlyingDirtyPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdClearingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.relatedSymbol = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideLastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clearingTradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.strategyLinkId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.totNumTradeReports = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.filler4v2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.multiLegReportingType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transferReason = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroTradeBroadcast EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchSubType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroTradeBroadcast EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroTradeBroadcast EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.relatedProductComplex = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyClearingOrganization = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyClearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp7 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp7(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp7(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(sendingTime.rest, 8) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET applSubId == ReadBytes(applSeqNum.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(partitionId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET applId == ReadBytes(applResendFlag.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ sendingTime    |-> sendingTime.value,
         applSeqNum     |-> applSeqNum.value,
         applSubId      |-> applSubId.value,
         partitionId    |-> partitionId.value,
         applResendFlag |-> applResendFlag.value,
         applId         |-> applId.value,
         lastFragment   |-> lastFragment.value,
         pad7           |-> pad7.value ], pad7.rest)

ZeroRbcHeaderComp7 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp7 ==
    { ZeroRbcHeaderComp7 }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp7 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trade Enhancement Broadcast: 122 bytes                                  *)
(***************************************************************************)

TradeEnhancementBroadcast ==
    [ filler4              : Sample(2),
      rbcHeaderComp        : RbcHeaderComp7,
      securityId           : Sample(8),
      clearingTradePrice   : Sample(8),
      transactTime         : Sample(8),
      orderId              : Sample(8),
      tradeId              : Sample(4),
      rootPartyIdSessionId : Sample(4),
      sideTradeId          : Sample(4),
      marketSegmentId      : Sample(4),
      matchDate            : Sample(4),
      clearingTradeQty     : Sample(4),
      accountType          : Sample(1),
      side                 : Sample(1),
      autoAcceptIndicator  : Sample(1),
      cpCode               : Sample(12),
      clientCode           : Sample(12),
      pad5                 : Sample(5) ]

EncodeTradeEnhancementBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderComp7(message.rbcHeaderComp)
        \o message.securityId
        \o message.clearingTradePrice
        \o message.transactTime
        \o message.orderId
        \o message.tradeId
        \o message.rootPartyIdSessionId
        \o message.sideTradeId
        \o message.marketSegmentId
        \o message.matchDate
        \o message.clearingTradeQty
        \o message.accountType
        \o message.side
        \o message.autoAcceptIndicator
        \o message.cpCode
        \o message.clientCode
        \o message.pad5

DecodeTradeEnhancementBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp7(filler4.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET clearingTradePrice == ReadBytes(securityId.rest, 8) IN IF ~clearingTradePrice.ok THEN Fail ELSE
    LET transactTime == ReadBytes(clearingTradePrice.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET rootPartyIdSessionId == ReadBytes(tradeId.rest, 4) IN IF ~rootPartyIdSessionId.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(rootPartyIdSessionId.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(sideTradeId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchDate.ok THEN Fail ELSE
    LET clearingTradeQty == ReadBytes(matchDate.rest, 4) IN IF ~clearingTradeQty.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingTradeQty.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET side == ReadBytes(accountType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET autoAcceptIndicator == ReadBytes(side.rest, 1) IN IF ~autoAcceptIndicator.ok THEN Fail ELSE
    LET cpCode == ReadBytes(autoAcceptIndicator.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET clientCode == ReadBytes(cpCode.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET pad5 == ReadBytes(clientCode.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ filler4              |-> filler4.value,
         rbcHeaderComp        |-> rbcHeaderComp.value,
         securityId           |-> securityId.value,
         clearingTradePrice   |-> clearingTradePrice.value,
         transactTime         |-> transactTime.value,
         orderId              |-> orderId.value,
         tradeId              |-> tradeId.value,
         rootPartyIdSessionId |-> rootPartyIdSessionId.value,
         sideTradeId          |-> sideTradeId.value,
         marketSegmentId      |-> marketSegmentId.value,
         matchDate            |-> matchDate.value,
         clearingTradeQty     |-> clearingTradeQty.value,
         accountType          |-> accountType.value,
         side                 |-> side.value,
         autoAcceptIndicator  |-> autoAcceptIndicator.value,
         cpCode               |-> cpCode.value,
         clientCode           |-> clientCode.value,
         pad5                 |-> pad5.value ], pad5.rest)

ZeroTradeEnhancementBroadcast ==
    [ filler4              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp        |-> ZeroRbcHeaderComp7,
      securityId           |-> [i \in 1 .. 8 |-> 0],
      clearingTradePrice   |-> [i \in 1 .. 8 |-> 0],
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      tradeId              |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      sideTradeId          |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId      |-> [i \in 1 .. 4 |-> 0],
      matchDate            |-> [i \in 1 .. 4 |-> 0],
      clearingTradeQty     |-> [i \in 1 .. 4 |-> 0],
      accountType          |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      autoAcceptIndicator  |-> [i \in 1 .. 1 |-> 0],
      cpCode               |-> [i \in 1 .. 12 |-> 0],
      clientCode           |-> [i \in 1 .. 12 |-> 0],
      pad5                 |-> [i \in 1 .. 5 |-> 0] ]

(* Trade Enhancement Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradeEnhancementBroadcast ==
    { ZeroTradeEnhancementBroadcast }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp7 }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.clearingTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.rootPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.matchDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.clearingTradeQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.autoAcceptIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroTradeEnhancementBroadcast EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Rbc Header Me Comp: 48 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp10 ==
    [ trdRegTsTimeOut : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp10(message) ==
    message.trdRegTsTimeOut
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp10(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp10 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp10 ==
    { ZeroRbcHeaderMeComp10 }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trading Session Status Broadcast: 82 bytes                              *)
(***************************************************************************)

TradingSessionStatusBroadcast ==
    [ filler4          : Sample(2),
      rbcHeaderMeComp  : RbcHeaderMeComp10,
      marketSegmentId  : Sample(4),
      tradeDate        : Sample(4),
      tradSesEvent     : Sample(1),
      refApplLastMsgId : Sample(16),
      pad7             : Sample(7) ]

EncodeTradingSessionStatusBroadcast(message) ==
    message.filler4
        \o EncodeRbcHeaderMeComp10(message.rbcHeaderMeComp)
        \o message.marketSegmentId
        \o message.tradeDate
        \o message.tradSesEvent
        \o message.refApplLastMsgId
        \o message.pad7

DecodeTradingSessionStatusBroadcast(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp10(filler4.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(rbcHeaderMeComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(tradeDate.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET refApplLastMsgId == ReadBytes(tradSesEvent.rest, 16) IN IF ~refApplLastMsgId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(refApplLastMsgId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ filler4          |-> filler4.value,
         rbcHeaderMeComp  |-> rbcHeaderMeComp.value,
         marketSegmentId  |-> marketSegmentId.value,
         tradeDate        |-> tradeDate.value,
         tradSesEvent     |-> tradSesEvent.value,
         refApplLastMsgId |-> refApplLastMsgId.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroTradingSessionStatusBroadcast ==
    [ filler4          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp  |-> ZeroRbcHeaderMeComp10,
      marketSegmentId  |-> [i \in 1 .. 4 |-> 0],
      tradeDate        |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent     |-> [i \in 1 .. 1 |-> 0],
      refApplLastMsgId |-> [i \in 1 .. 16 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusBroadcast ==
    { ZeroTradingSessionStatusBroadcast }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp10 }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.refApplLastMsgId = one] : one \in Sample(16) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp11 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp11(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp11(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp11 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp11 ==
    { ZeroResponseHeaderComp11 }
        \cup { [ZeroResponseHeaderComp11 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp11 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Unsubscribe Response: 26 bytes                                          *)
(***************************************************************************)

UnsubscribeResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp11 ]

EncodeUnsubscribeResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp11(message.responseHeaderComp)

DecodeUnsubscribeResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp11(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUnsubscribeResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp11 ]

(* Unsubscribe Response at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeResponse ==
    { ZeroUnsubscribeResponse }
        \cup { [ZeroUnsubscribeResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp11 }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp12 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp12(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp12(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp12 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp12 ==
    { ZeroResponseHeaderComp12 }
        \cup { [ZeroResponseHeaderComp12 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp12 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp12 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp12 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* User Login Response: 42 bytes                                           *)
(***************************************************************************)

UserLoginResponse ==
    [ filler4                 : Sample(2),
      responseHeaderComp      : ResponseHeaderComp12,
      lastLoginTime           : Sample(8),
      daysLeftForPasswdExpiry : Sample(1),
      graceLoginsLeft         : Sample(1),
      pad6                    : Sample(6) ]

EncodeUserLoginResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp12(message.responseHeaderComp)
        \o message.lastLoginTime
        \o message.daysLeftForPasswdExpiry
        \o message.graceLoginsLeft
        \o message.pad6

DecodeUserLoginResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp12(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET lastLoginTime == ReadBytes(responseHeaderComp.rest, 8) IN IF ~lastLoginTime.ok THEN Fail ELSE
    LET daysLeftForPasswdExpiry == ReadBytes(lastLoginTime.rest, 1) IN IF ~daysLeftForPasswdExpiry.ok THEN Fail ELSE
    LET graceLoginsLeft == ReadBytes(daysLeftForPasswdExpiry.rest, 1) IN IF ~graceLoginsLeft.ok THEN Fail ELSE
    LET pad6 == ReadBytes(graceLoginsLeft.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ filler4                 |-> filler4.value,
         responseHeaderComp      |-> responseHeaderComp.value,
         lastLoginTime           |-> lastLoginTime.value,
         daysLeftForPasswdExpiry |-> daysLeftForPasswdExpiry.value,
         graceLoginsLeft         |-> graceLoginsLeft.value,
         pad6                    |-> pad6.value ], pad6.rest)

ZeroUserLoginResponse ==
    [ filler4                 |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp      |-> ZeroResponseHeaderComp12,
      lastLoginTime           |-> [i \in 1 .. 8 |-> 0],
      daysLeftForPasswdExpiry |-> [i \in 1 .. 1 |-> 0],
      graceLoginsLeft         |-> [i \in 1 .. 1 |-> 0],
      pad6                    |-> [i \in 1 .. 6 |-> 0] ]

(* User Login Response at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginResponse ==
    { ZeroUserLoginResponse }
        \cup { [ZeroUserLoginResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp12 }
        \cup { [ZeroUserLoginResponse EXCEPT !.lastLoginTime = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginResponse EXCEPT !.daysLeftForPasswdExpiry = one] : one \in Sample(1) }
        \cup { [ZeroUserLoginResponse EXCEPT !.graceLoginsLeft = one] : one \in Sample(1) }
        \cup { [ZeroUserLoginResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp13 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp13(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp13(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp13 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp13 ==
    { ZeroResponseHeaderComp13 }
        \cup { [ZeroResponseHeaderComp13 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp13 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp13 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp13 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* User Logout Response: 26 bytes                                          *)
(***************************************************************************)

UserLogoutResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp13 ]

EncodeUserLogoutResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp13(message.responseHeaderComp)

DecodeUserLogoutResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp13(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUserLogoutResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp13 ]

(* User Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutResponse ==
    { ZeroUserLogoutResponse }
        \cup { [ZeroUserLogoutResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp13 }

(***************************************************************************)
(* Response Header Comp: 24 bytes                                          *)
(***************************************************************************)

ResponseHeaderComp14 ==
    [ requestTime : Sample(8),
      sendingTime : Sample(8),
      msgSeqNum   : Sample(4),
      pad4        : Sample(4) ]

EncodeResponseHeaderComp14(message) ==
    message.requestTime
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.pad4

DecodeResponseHeaderComp14(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(requestTime.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET pad4 == ReadBytes(msgSeqNum.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ requestTime |-> requestTime.value,
         sendingTime |-> sendingTime.value,
         msgSeqNum   |-> msgSeqNum.value,
         pad4        |-> pad4.value ], pad4.rest)

ZeroResponseHeaderComp14 ==
    [ requestTime |-> [i \in 1 .. 8 |-> 0],
      sendingTime |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      pad4        |-> [i \in 1 .. 4 |-> 0] ]

(* Response Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedResponseHeaderComp14 ==
    { ZeroResponseHeaderComp14 }
        \cup { [ZeroResponseHeaderComp14 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp14 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroResponseHeaderComp14 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseHeaderComp14 EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* User Password Change Response: 26 bytes                                 *)
(***************************************************************************)

UserPasswordChangeResponse ==
    [ filler4            : Sample(2),
      responseHeaderComp : ResponseHeaderComp14 ]

EncodeUserPasswordChangeResponse(message) ==
    message.filler4
        \o EncodeResponseHeaderComp14(message.responseHeaderComp)

DecodeUserPasswordChangeResponse(bytes) ==
    LET filler4 == ReadBytes(bytes, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp14(filler4.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ filler4            |-> filler4.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUserPasswordChangeResponse ==
    [ filler4            |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp14 ]

(* User Password Change Response at zero, then each field in turn at the values it is checked at *)
CheckedUserPasswordChangeResponse ==
    { ZeroUserPasswordChangeResponse }
        \cup { [ZeroUserPasswordChangeResponse EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroUserPasswordChangeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp14 }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

BroadcastErrorNotificationCode == 10032  \* 0x2730
DebtInquiryResponseCode == 10391  \* 0x2897
DeleteAllOrderBroadcastCode == 10122  \* 0x278a
DeleteAllOrderNrResponseCode == 10124  \* 0x278c
DeleteAllOrderQuoteEventBroadcastCode == 10308  \* 0x2844
DeleteAllOrderResponseCode == 10121  \* 0x2789
DeleteAllQuoteBroadcastCode == 10410  \* 0x28aa
DeleteAllQuoteResponseCode == 10409  \* 0x28a9
DeleteOrderBroadcastCode == 10112  \* 0x2780
DeleteOrderNrResponseCode == 10111  \* 0x277f
DeleteOrderResponseCode == 10110  \* 0x277e
ForcedLogoutNotificationCode == 10012  \* 0x271c
GatewayResponseCode == 10022  \* 0x2726
GwOrderAcknowledgementCode == 10990  \* 0x2aee
HeartbeatNotificationCode == 10023  \* 0x2727
InquireSessionListResponseCode == 10036  \* 0x2734
LogonResponseCode == 10001  \* 0x2711
LogoutResponseCode == 10003  \* 0x2713
MassQuoteResponseCode == 10406  \* 0x28a6
ModifyOrderNrResponseCode == 10108  \* 0x277c
ModifyOrderResponseCode == 10107  \* 0x277b
MultiLegExecReportBroadcastCode == 10994  \* 0x2af2
MultiLegExecResponseCode == 10993  \* 0x2af1
MultiLegOrderRejectCode == 10992  \* 0x2af0
NewOrderNrResponseCode == 10102  \* 0x2776
NewOrderResponseCode == 10101  \* 0x2775
NewsBroadcastCode == 10031  \* 0x272f
OrderExecNotificationCode == 10104  \* 0x2778
OrderExecReportBroadcastCode == 10117  \* 0x2785
OrderExecResponseCode == 10103  \* 0x2777
QuoteExecReportBroadcastCode == 10412  \* 0x28ac
QuoteExecutionReportCode == 10407  \* 0x28a7
RejectCode == 10010  \* 0x271a
RetransmitMeMessageResponseCode == 10027  \* 0x272b
RetransmitResponseCode == 10009  \* 0x2719
RiskCollateralAlertAdminBroadcastCode == 10048  \* 0x2740
RiskCollateralAlertBroadcastCode == 10049  \* 0x2741
RiskNotificationBroadcastCode == 10033  \* 0x2731
ServiceAvailabilityBroadcastCode == 10030  \* 0x272e
SessionPasswordChangeResponseCode == 10995  \* 0x2af3
SessionRegistrationResponseCode == 10054  \* 0x2746
SubscribeResponseCode == 10005  \* 0x2715
TmTradingSessionStatusBroadcastCode == 10501  \* 0x2905
ThrottleUpdateNotificationCode == 10028  \* 0x272c
TradeBroadcastCode == 10500  \* 0x2904
TradeEnhancementBroadcastCode == 10989  \* 0x2aed
TradingSessionStatusBroadcastCode == 10307  \* 0x2843
UnsubscribeResponseCode == 10007  \* 0x2717
UserLoginResponseCode == 10019  \* 0x2723
UserLogoutResponseCode == 10024  \* 0x2728
UserPasswordChangeResponseCode == 10043  \* 0x273b

ServerPayload ==
    [ tag : {BroadcastErrorNotificationCode}, body : BroadcastErrorNotification ]
        \cup [ tag : {DebtInquiryResponseCode}, body : DebtInquiryResponse ]
        \cup [ tag : {DeleteAllOrderBroadcastCode}, body : DeleteAllOrderBroadcast ]
        \cup [ tag : {DeleteAllOrderNrResponseCode}, body : DeleteAllOrderNrResponse ]
        \cup [ tag : {DeleteAllOrderQuoteEventBroadcastCode}, body : DeleteAllOrderQuoteEventBroadcast ]
        \cup [ tag : {DeleteAllOrderResponseCode}, body : DeleteAllOrderResponse ]
        \cup [ tag : {DeleteAllQuoteBroadcastCode}, body : DeleteAllQuoteBroadcast ]
        \cup [ tag : {DeleteAllQuoteResponseCode}, body : DeleteAllQuoteResponse ]
        \cup [ tag : {DeleteOrderBroadcastCode}, body : DeleteOrderBroadcast ]
        \cup [ tag : {DeleteOrderNrResponseCode}, body : DeleteOrderNrResponse ]
        \cup [ tag : {DeleteOrderResponseCode}, body : DeleteOrderResponse ]
        \cup [ tag : {ForcedLogoutNotificationCode}, body : ForcedLogoutNotification ]
        \cup [ tag : {GatewayResponseCode}, body : GatewayResponse ]
        \cup [ tag : {GwOrderAcknowledgementCode}, body : GwOrderAcknowledgement ]
        \cup [ tag : {HeartbeatNotificationCode}, body : HeartbeatNotification ]
        \cup [ tag : {InquireSessionListResponseCode}, body : InquireSessionListResponse ]
        \cup [ tag : {LogonResponseCode}, body : LogonResponse ]
        \cup [ tag : {LogoutResponseCode}, body : LogoutResponse ]
        \cup [ tag : {MassQuoteResponseCode}, body : MassQuoteResponse ]
        \cup [ tag : {ModifyOrderNrResponseCode}, body : ModifyOrderNrResponse ]
        \cup [ tag : {ModifyOrderResponseCode}, body : ModifyOrderResponse ]
        \cup [ tag : {MultiLegExecReportBroadcastCode}, body : MultiLegExecReportBroadcast ]
        \cup [ tag : {MultiLegExecResponseCode}, body : MultiLegExecResponse ]
        \cup [ tag : {MultiLegOrderRejectCode}, body : MultiLegOrderReject ]
        \cup [ tag : {NewOrderNrResponseCode}, body : NewOrderNrResponse ]
        \cup [ tag : {NewOrderResponseCode}, body : NewOrderResponse ]
        \cup [ tag : {NewsBroadcastCode}, body : NewsBroadcast ]
        \cup [ tag : {OrderExecNotificationCode}, body : OrderExecNotification ]
        \cup [ tag : {OrderExecReportBroadcastCode}, body : OrderExecReportBroadcast ]
        \cup [ tag : {OrderExecResponseCode}, body : OrderExecResponse ]
        \cup [ tag : {QuoteExecReportBroadcastCode}, body : QuoteExecReportBroadcast ]
        \cup [ tag : {QuoteExecutionReportCode}, body : QuoteExecutionReport ]
        \cup [ tag : {RejectCode}, body : Reject ]
        \cup [ tag : {RetransmitMeMessageResponseCode}, body : RetransmitMeMessageResponse ]
        \cup [ tag : {RetransmitResponseCode}, body : RetransmitResponse ]
        \cup [ tag : {RiskCollateralAlertAdminBroadcastCode}, body : RiskCollateralAlertAdminBroadcast ]
        \cup [ tag : {RiskCollateralAlertBroadcastCode}, body : RiskCollateralAlertBroadcast ]
        \cup [ tag : {RiskNotificationBroadcastCode}, body : RiskNotificationBroadcast ]
        \cup [ tag : {ServiceAvailabilityBroadcastCode}, body : ServiceAvailabilityBroadcast ]
        \cup [ tag : {SessionPasswordChangeResponseCode}, body : SessionPasswordChangeResponse ]
        \cup [ tag : {SessionRegistrationResponseCode}, body : SessionRegistrationResponse ]
        \cup [ tag : {SubscribeResponseCode}, body : SubscribeResponse ]
        \cup [ tag : {TmTradingSessionStatusBroadcastCode}, body : TmTradingSessionStatusBroadcast ]
        \cup [ tag : {ThrottleUpdateNotificationCode}, body : ThrottleUpdateNotification ]
        \cup [ tag : {TradeBroadcastCode}, body : TradeBroadcast ]
        \cup [ tag : {TradeEnhancementBroadcastCode}, body : TradeEnhancementBroadcast ]
        \cup [ tag : {TradingSessionStatusBroadcastCode}, body : TradingSessionStatusBroadcast ]
        \cup [ tag : {UnsubscribeResponseCode}, body : UnsubscribeResponse ]
        \cup [ tag : {UserLoginResponseCode}, body : UserLoginResponse ]
        \cup [ tag : {UserLogoutResponseCode}, body : UserLogoutResponse ]
        \cup [ tag : {UserPasswordChangeResponseCode}, body : UserPasswordChangeResponse ]

EncodeServerPayload(message) ==
    CASE message.tag = BroadcastErrorNotificationCode -> EncodeBroadcastErrorNotification(message.body)
      [] message.tag = DebtInquiryResponseCode -> EncodeDebtInquiryResponse(message.body)
      [] message.tag = DeleteAllOrderBroadcastCode -> EncodeDeleteAllOrderBroadcast(message.body)
      [] message.tag = DeleteAllOrderNrResponseCode -> EncodeDeleteAllOrderNrResponse(message.body)
      [] message.tag = DeleteAllOrderQuoteEventBroadcastCode -> EncodeDeleteAllOrderQuoteEventBroadcast(message.body)
      [] message.tag = DeleteAllOrderResponseCode -> EncodeDeleteAllOrderResponse(message.body)
      [] message.tag = DeleteAllQuoteBroadcastCode -> EncodeDeleteAllQuoteBroadcast(message.body)
      [] message.tag = DeleteAllQuoteResponseCode -> EncodeDeleteAllQuoteResponse(message.body)
      [] message.tag = DeleteOrderBroadcastCode -> EncodeDeleteOrderBroadcast(message.body)
      [] message.tag = DeleteOrderNrResponseCode -> EncodeDeleteOrderNrResponse(message.body)
      [] message.tag = DeleteOrderResponseCode -> EncodeDeleteOrderResponse(message.body)
      [] message.tag = ForcedLogoutNotificationCode -> EncodeForcedLogoutNotification(message.body)
      [] message.tag = GatewayResponseCode -> EncodeGatewayResponse(message.body)
      [] message.tag = GwOrderAcknowledgementCode -> EncodeGwOrderAcknowledgement(message.body)
      [] message.tag = HeartbeatNotificationCode -> EncodeHeartbeatNotification(message.body)
      [] message.tag = InquireSessionListResponseCode -> EncodeInquireSessionListResponse(message.body)
      [] message.tag = LogonResponseCode -> EncodeLogonResponse(message.body)
      [] message.tag = LogoutResponseCode -> EncodeLogoutResponse(message.body)
      [] message.tag = MassQuoteResponseCode -> EncodeMassQuoteResponse(message.body)
      [] message.tag = ModifyOrderNrResponseCode -> EncodeModifyOrderNrResponse(message.body)
      [] message.tag = ModifyOrderResponseCode -> EncodeModifyOrderResponse(message.body)
      [] message.tag = MultiLegExecReportBroadcastCode -> EncodeMultiLegExecReportBroadcast(message.body)
      [] message.tag = MultiLegExecResponseCode -> EncodeMultiLegExecResponse(message.body)
      [] message.tag = MultiLegOrderRejectCode -> EncodeMultiLegOrderReject(message.body)
      [] message.tag = NewOrderNrResponseCode -> EncodeNewOrderNrResponse(message.body)
      [] message.tag = NewOrderResponseCode -> EncodeNewOrderResponse(message.body)
      [] message.tag = NewsBroadcastCode -> EncodeNewsBroadcast(message.body)
      [] message.tag = OrderExecNotificationCode -> EncodeOrderExecNotification(message.body)
      [] message.tag = OrderExecReportBroadcastCode -> EncodeOrderExecReportBroadcast(message.body)
      [] message.tag = OrderExecResponseCode -> EncodeOrderExecResponse(message.body)
      [] message.tag = QuoteExecReportBroadcastCode -> EncodeQuoteExecReportBroadcast(message.body)
      [] message.tag = QuoteExecutionReportCode -> EncodeQuoteExecutionReport(message.body)
      [] message.tag = RejectCode -> EncodeReject(message.body)
      [] message.tag = RetransmitMeMessageResponseCode -> EncodeRetransmitMeMessageResponse(message.body)
      [] message.tag = RetransmitResponseCode -> EncodeRetransmitResponse(message.body)
      [] message.tag = RiskCollateralAlertAdminBroadcastCode -> EncodeRiskCollateralAlertAdminBroadcast(message.body)
      [] message.tag = RiskCollateralAlertBroadcastCode -> EncodeRiskCollateralAlertBroadcast(message.body)
      [] message.tag = RiskNotificationBroadcastCode -> EncodeRiskNotificationBroadcast(message.body)
      [] message.tag = ServiceAvailabilityBroadcastCode -> EncodeServiceAvailabilityBroadcast(message.body)
      [] message.tag = SessionPasswordChangeResponseCode -> EncodeSessionPasswordChangeResponse(message.body)
      [] message.tag = SessionRegistrationResponseCode -> EncodeSessionRegistrationResponse(message.body)
      [] message.tag = SubscribeResponseCode -> EncodeSubscribeResponse(message.body)
      [] message.tag = TmTradingSessionStatusBroadcastCode -> EncodeTmTradingSessionStatusBroadcast(message.body)
      [] message.tag = ThrottleUpdateNotificationCode -> EncodeThrottleUpdateNotification(message.body)
      [] message.tag = TradeBroadcastCode -> EncodeTradeBroadcast(message.body)
      [] message.tag = TradeEnhancementBroadcastCode -> EncodeTradeEnhancementBroadcast(message.body)
      [] message.tag = TradingSessionStatusBroadcastCode -> EncodeTradingSessionStatusBroadcast(message.body)
      [] message.tag = UnsubscribeResponseCode -> EncodeUnsubscribeResponse(message.body)
      [] message.tag = UserLoginResponseCode -> EncodeUserLoginResponse(message.body)
      [] message.tag = UserLogoutResponseCode -> EncodeUserLogoutResponse(message.body)
      [] message.tag = UserPasswordChangeResponseCode -> EncodeUserPasswordChangeResponse(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = BroadcastErrorNotificationCode -> DecodeBroadcastErrorNotification(bytes)
              [] tag = DebtInquiryResponseCode -> DecodeDebtInquiryResponse(bytes)
              [] tag = DeleteAllOrderBroadcastCode -> DecodeDeleteAllOrderBroadcast(bytes)
              [] tag = DeleteAllOrderNrResponseCode -> DecodeDeleteAllOrderNrResponse(bytes)
              [] tag = DeleteAllOrderQuoteEventBroadcastCode -> DecodeDeleteAllOrderQuoteEventBroadcast(bytes)
              [] tag = DeleteAllOrderResponseCode -> DecodeDeleteAllOrderResponse(bytes)
              [] tag = DeleteAllQuoteBroadcastCode -> DecodeDeleteAllQuoteBroadcast(bytes)
              [] tag = DeleteAllQuoteResponseCode -> DecodeDeleteAllQuoteResponse(bytes)
              [] tag = DeleteOrderBroadcastCode -> DecodeDeleteOrderBroadcast(bytes)
              [] tag = DeleteOrderNrResponseCode -> DecodeDeleteOrderNrResponse(bytes)
              [] tag = DeleteOrderResponseCode -> DecodeDeleteOrderResponse(bytes)
              [] tag = ForcedLogoutNotificationCode -> DecodeForcedLogoutNotification(bytes)
              [] tag = GatewayResponseCode -> DecodeGatewayResponse(bytes)
              [] tag = GwOrderAcknowledgementCode -> DecodeGwOrderAcknowledgement(bytes)
              [] tag = HeartbeatNotificationCode -> DecodeHeartbeatNotification(bytes)
              [] tag = InquireSessionListResponseCode -> DecodeInquireSessionListResponse(bytes)
              [] tag = LogonResponseCode -> DecodeLogonResponse(bytes)
              [] tag = LogoutResponseCode -> DecodeLogoutResponse(bytes)
              [] tag = MassQuoteResponseCode -> DecodeMassQuoteResponse(bytes)
              [] tag = ModifyOrderNrResponseCode -> DecodeModifyOrderNrResponse(bytes)
              [] tag = ModifyOrderResponseCode -> DecodeModifyOrderResponse(bytes)
              [] tag = MultiLegExecReportBroadcastCode -> DecodeMultiLegExecReportBroadcast(bytes)
              [] tag = MultiLegExecResponseCode -> DecodeMultiLegExecResponse(bytes)
              [] tag = MultiLegOrderRejectCode -> DecodeMultiLegOrderReject(bytes)
              [] tag = NewOrderNrResponseCode -> DecodeNewOrderNrResponse(bytes)
              [] tag = NewOrderResponseCode -> DecodeNewOrderResponse(bytes)
              [] tag = NewsBroadcastCode -> DecodeNewsBroadcast(bytes)
              [] tag = OrderExecNotificationCode -> DecodeOrderExecNotification(bytes)
              [] tag = OrderExecReportBroadcastCode -> DecodeOrderExecReportBroadcast(bytes)
              [] tag = OrderExecResponseCode -> DecodeOrderExecResponse(bytes)
              [] tag = QuoteExecReportBroadcastCode -> DecodeQuoteExecReportBroadcast(bytes)
              [] tag = QuoteExecutionReportCode -> DecodeQuoteExecutionReport(bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] tag = RetransmitMeMessageResponseCode -> DecodeRetransmitMeMessageResponse(bytes)
              [] tag = RetransmitResponseCode -> DecodeRetransmitResponse(bytes)
              [] tag = RiskCollateralAlertAdminBroadcastCode -> DecodeRiskCollateralAlertAdminBroadcast(bytes)
              [] tag = RiskCollateralAlertBroadcastCode -> DecodeRiskCollateralAlertBroadcast(bytes)
              [] tag = RiskNotificationBroadcastCode -> DecodeRiskNotificationBroadcast(bytes)
              [] tag = ServiceAvailabilityBroadcastCode -> DecodeServiceAvailabilityBroadcast(bytes)
              [] tag = SessionPasswordChangeResponseCode -> DecodeSessionPasswordChangeResponse(bytes)
              [] tag = SessionRegistrationResponseCode -> DecodeSessionRegistrationResponse(bytes)
              [] tag = SubscribeResponseCode -> DecodeSubscribeResponse(bytes)
              [] tag = TmTradingSessionStatusBroadcastCode -> DecodeTmTradingSessionStatusBroadcast(bytes)
              [] tag = ThrottleUpdateNotificationCode -> DecodeThrottleUpdateNotification(bytes)
              [] tag = TradeBroadcastCode -> DecodeTradeBroadcast(bytes)
              [] tag = TradeEnhancementBroadcastCode -> DecodeTradeEnhancementBroadcast(bytes)
              [] tag = TradingSessionStatusBroadcastCode -> DecodeTradingSessionStatusBroadcast(bytes)
              [] tag = UnsubscribeResponseCode -> DecodeUnsubscribeResponse(bytes)
              [] tag = UserLoginResponseCode -> DecodeUserLoginResponse(bytes)
              [] tag = UserLogoutResponseCode -> DecodeUserLogoutResponse(bytes)
              [] tag = UserPasswordChangeResponseCode -> DecodeUserPasswordChangeResponse(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> BroadcastErrorNotificationCode, body |-> ZeroBroadcastErrorNotification]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> BroadcastErrorNotificationCode, body |-> one] : one \in CheckedBroadcastErrorNotification }
        \cup { [tag |-> DebtInquiryResponseCode, body |-> one] : one \in CheckedDebtInquiryResponse }
        \cup { [tag |-> DeleteAllOrderBroadcastCode, body |-> one] : one \in CheckedDeleteAllOrderBroadcast }
        \cup { [tag |-> DeleteAllOrderNrResponseCode, body |-> one] : one \in CheckedDeleteAllOrderNrResponse }
        \cup { [tag |-> DeleteAllOrderQuoteEventBroadcastCode, body |-> one] : one \in CheckedDeleteAllOrderQuoteEventBroadcast }
        \cup { [tag |-> DeleteAllOrderResponseCode, body |-> one] : one \in CheckedDeleteAllOrderResponse }
        \cup { [tag |-> DeleteAllQuoteBroadcastCode, body |-> one] : one \in CheckedDeleteAllQuoteBroadcast }
        \cup { [tag |-> DeleteAllQuoteResponseCode, body |-> one] : one \in CheckedDeleteAllQuoteResponse }
        \cup { [tag |-> DeleteOrderBroadcastCode, body |-> one] : one \in CheckedDeleteOrderBroadcast }
        \cup { [tag |-> DeleteOrderNrResponseCode, body |-> one] : one \in CheckedDeleteOrderNrResponse }
        \cup { [tag |-> DeleteOrderResponseCode, body |-> one] : one \in CheckedDeleteOrderResponse }
        \cup { [tag |-> ForcedLogoutNotificationCode, body |-> one] : one \in CheckedForcedLogoutNotification }
        \cup { [tag |-> GatewayResponseCode, body |-> one] : one \in CheckedGatewayResponse }
        \cup { [tag |-> GwOrderAcknowledgementCode, body |-> one] : one \in CheckedGwOrderAcknowledgement }
        \cup { [tag |-> HeartbeatNotificationCode, body |-> one] : one \in CheckedHeartbeatNotification }
        \cup { [tag |-> InquireSessionListResponseCode, body |-> one] : one \in CheckedInquireSessionListResponse }
        \cup { [tag |-> LogonResponseCode, body |-> one] : one \in CheckedLogonResponse }
        \cup { [tag |-> LogoutResponseCode, body |-> one] : one \in CheckedLogoutResponse }
        \cup { [tag |-> MassQuoteResponseCode, body |-> one] : one \in CheckedMassQuoteResponse }
        \cup { [tag |-> ModifyOrderNrResponseCode, body |-> one] : one \in CheckedModifyOrderNrResponse }
        \cup { [tag |-> ModifyOrderResponseCode, body |-> one] : one \in CheckedModifyOrderResponse }
        \cup { [tag |-> MultiLegExecReportBroadcastCode, body |-> one] : one \in CheckedMultiLegExecReportBroadcast }
        \cup { [tag |-> MultiLegExecResponseCode, body |-> one] : one \in CheckedMultiLegExecResponse }
        \cup { [tag |-> MultiLegOrderRejectCode, body |-> one] : one \in CheckedMultiLegOrderReject }
        \cup { [tag |-> NewOrderNrResponseCode, body |-> one] : one \in CheckedNewOrderNrResponse }
        \cup { [tag |-> NewOrderResponseCode, body |-> one] : one \in CheckedNewOrderResponse }
        \cup { [tag |-> NewsBroadcastCode, body |-> one] : one \in CheckedNewsBroadcast }
        \cup { [tag |-> OrderExecNotificationCode, body |-> one] : one \in CheckedOrderExecNotification }
        \cup { [tag |-> OrderExecReportBroadcastCode, body |-> one] : one \in CheckedOrderExecReportBroadcast }
        \cup { [tag |-> OrderExecResponseCode, body |-> one] : one \in CheckedOrderExecResponse }
        \cup { [tag |-> QuoteExecReportBroadcastCode, body |-> one] : one \in CheckedQuoteExecReportBroadcast }
        \cup { [tag |-> QuoteExecutionReportCode, body |-> one] : one \in CheckedQuoteExecutionReport }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }
        \cup { [tag |-> RetransmitMeMessageResponseCode, body |-> one] : one \in CheckedRetransmitMeMessageResponse }
        \cup { [tag |-> RetransmitResponseCode, body |-> one] : one \in CheckedRetransmitResponse }
        \cup { [tag |-> RiskCollateralAlertAdminBroadcastCode, body |-> one] : one \in CheckedRiskCollateralAlertAdminBroadcast }
        \cup { [tag |-> RiskCollateralAlertBroadcastCode, body |-> one] : one \in CheckedRiskCollateralAlertBroadcast }
        \cup { [tag |-> RiskNotificationBroadcastCode, body |-> one] : one \in CheckedRiskNotificationBroadcast }
        \cup { [tag |-> ServiceAvailabilityBroadcastCode, body |-> one] : one \in CheckedServiceAvailabilityBroadcast }
        \cup { [tag |-> SessionPasswordChangeResponseCode, body |-> one] : one \in CheckedSessionPasswordChangeResponse }
        \cup { [tag |-> SessionRegistrationResponseCode, body |-> one] : one \in CheckedSessionRegistrationResponse }
        \cup { [tag |-> SubscribeResponseCode, body |-> one] : one \in CheckedSubscribeResponse }
        \cup { [tag |-> TmTradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTmTradingSessionStatusBroadcast }
        \cup { [tag |-> ThrottleUpdateNotificationCode, body |-> one] : one \in CheckedThrottleUpdateNotification }
        \cup { [tag |-> TradeBroadcastCode, body |-> one] : one \in CheckedTradeBroadcast }
        \cup { [tag |-> TradeEnhancementBroadcastCode, body |-> one] : one \in CheckedTradeEnhancementBroadcast }
        \cup { [tag |-> TradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTradingSessionStatusBroadcast }
        \cup { [tag |-> UnsubscribeResponseCode, body |-> one] : one \in CheckedUnsubscribeResponse }
        \cup { [tag |-> UserLoginResponseCode, body |-> one] : one \in CheckedUserLoginResponse }
        \cup { [tag |-> UserLogoutResponseCode, body |-> one] : one \in CheckedUserLogoutResponse }
        \cup { [tag |-> UserPasswordChangeResponseCode, body |-> one] : one \in CheckedUserPasswordChangeResponse }

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
    { [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> BroadcastErrorNotificationCode, body |-> ZeroBroadcastErrorNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DebtInquiryResponseCode, body |-> ZeroDebtInquiryResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderBroadcastCode, body |-> ZeroDeleteAllOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderNrResponseCode, body |-> ZeroDeleteAllOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderQuoteEventBroadcastCode, body |-> ZeroDeleteAllOrderQuoteEventBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderResponseCode, body |-> ZeroDeleteAllOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllQuoteBroadcastCode, body |-> ZeroDeleteAllQuoteBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllQuoteResponseCode, body |-> ZeroDeleteAllQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderBroadcastCode, body |-> ZeroDeleteOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderNrResponseCode, body |-> ZeroDeleteOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderResponseCode, body |-> ZeroDeleteOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ForcedLogoutNotificationCode, body |-> ZeroForcedLogoutNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> GatewayResponseCode, body |-> ZeroGatewayResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> GwOrderAcknowledgementCode, body |-> ZeroGwOrderAcknowledgement]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> HeartbeatNotificationCode, body |-> ZeroHeartbeatNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireSessionListResponseCode, body |-> ZeroInquireSessionListResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogonResponseCode, body |-> ZeroLogonResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogoutResponseCode, body |-> ZeroLogoutResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> MassQuoteResponseCode, body |-> ZeroMassQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ModifyOrderNrResponseCode, body |-> ZeroModifyOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ModifyOrderResponseCode, body |-> ZeroModifyOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> MultiLegExecReportBroadcastCode, body |-> ZeroMultiLegExecReportBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> MultiLegExecResponseCode, body |-> ZeroMultiLegExecResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> MultiLegOrderRejectCode, body |-> ZeroMultiLegOrderReject]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderNrResponseCode, body |-> ZeroNewOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderResponseCode, body |-> ZeroNewOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewsBroadcastCode, body |-> ZeroNewsBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecNotificationCode, body |-> ZeroOrderExecNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecReportBroadcastCode, body |-> ZeroOrderExecReportBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecResponseCode, body |-> ZeroOrderExecResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> QuoteExecReportBroadcastCode, body |-> ZeroQuoteExecReportBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> QuoteExecutionReportCode, body |-> ZeroQuoteExecutionReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RejectCode, body |-> ZeroReject]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitMeMessageResponseCode, body |-> ZeroRetransmitMeMessageResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitResponseCode, body |-> ZeroRetransmitResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RiskCollateralAlertAdminBroadcastCode, body |-> ZeroRiskCollateralAlertAdminBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RiskCollateralAlertBroadcastCode, body |-> ZeroRiskCollateralAlertBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RiskNotificationBroadcastCode, body |-> ZeroRiskNotificationBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ServiceAvailabilityBroadcastCode, body |-> ZeroServiceAvailabilityBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SessionPasswordChangeResponseCode, body |-> ZeroSessionPasswordChangeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SessionRegistrationResponseCode, body |-> ZeroSessionRegistrationResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SubscribeResponseCode, body |-> ZeroSubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TmTradingSessionStatusBroadcastCode, body |-> ZeroTmTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ThrottleUpdateNotificationCode, body |-> ZeroThrottleUpdateNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradeBroadcastCode, body |-> ZeroTradeBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradeEnhancementBroadcastCode, body |-> ZeroTradeEnhancementBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradingSessionStatusBroadcastCode, body |-> ZeroTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UnsubscribeResponseCode, body |-> ZeroUnsubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLoginResponseCode, body |-> ZeroUserLoginResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLogoutResponseCode, body |-> ZeroUserLogoutResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserPasswordChangeResponseCode, body |-> ZeroUserPasswordChangeResponse]] }

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

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp ==
    \A message \in CheckedNotifHeaderComp :
        LET read == DecodeNotifHeaderComp(EncodeNotifHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broadcast Error Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripBroadcastErrorNotification ==
    \A message \in CheckedBroadcastErrorNotification :
        LET read == DecodeBroadcastErrorNotification(EncodeBroadcastErrorNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp ==
    \A message \in CheckedNrResponseHeaderMeComp :
        LET read == DecodeNrResponseHeaderMeComp(EncodeNrResponseHeaderMeComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Debt Inquiry Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDebtInquiryResponse ==
    \A message \in CheckedDebtInquiryResponse :
        LET read == DecodeDebtInquiryResponse(EncodeDebtInquiryResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp ==
    \A message \in CheckedRbcHeaderMeComp :
        LET read == DecodeRbcHeaderMeComp(EncodeRbcHeaderMeComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Orders Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedOrdersGrpComp ==
    \A message \in CheckedNotAffectedOrdersGrpComp :
        LET read == DecodeNotAffectedOrdersGrpComp(EncodeNotAffectedOrdersGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderBroadcast ==
    \A message \in CheckedDeleteAllOrderBroadcast :
        LET read == DecodeDeleteAllOrderBroadcast(EncodeDeleteAllOrderBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp2 ==
    \A message \in CheckedNrResponseHeaderMeComp2 :
        LET read == DecodeNrResponseHeaderMeComp2(EncodeNrResponseHeaderMeComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Nr Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderNrResponse ==
    \A message \in CheckedDeleteAllOrderNrResponse :
        LET read == DecodeDeleteAllOrderNrResponse(EncodeDeleteAllOrderNrResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp2 ==
    \A message \in CheckedRbcHeaderMeComp2 :
        LET read == DecodeRbcHeaderMeComp2(EncodeRbcHeaderMeComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Quote Event Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderQuoteEventBroadcast ==
    \A message \in CheckedDeleteAllOrderQuoteEventBroadcast :
        LET read == DecodeDeleteAllOrderQuoteEventBroadcast(EncodeDeleteAllOrderQuoteEventBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp ==
    \A message \in CheckedResponseHeaderMeComp :
        LET read == DecodeResponseHeaderMeComp(EncodeResponseHeaderMeComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Orders Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedOrdersGrpComp2 ==
    \A message \in CheckedNotAffectedOrdersGrpComp2 :
        LET read == DecodeNotAffectedOrdersGrpComp2(EncodeNotAffectedOrdersGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderResponse ==
    \A message \in CheckedDeleteAllOrderResponse :
        LET read == DecodeDeleteAllOrderResponse(EncodeDeleteAllOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp3 ==
    \A message \in CheckedRbcHeaderMeComp3 :
        LET read == DecodeRbcHeaderMeComp3(EncodeRbcHeaderMeComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Securities Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedSecuritiesGrpComp ==
    \A message \in CheckedNotAffectedSecuritiesGrpComp :
        LET read == DecodeNotAffectedSecuritiesGrpComp(EncodeNotAffectedSecuritiesGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Quote Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteBroadcast ==
    \A message \in CheckedDeleteAllQuoteBroadcast :
        LET read == DecodeDeleteAllQuoteBroadcast(EncodeDeleteAllQuoteBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp3 ==
    \A message \in CheckedNrResponseHeaderMeComp3 :
        LET read == DecodeNrResponseHeaderMeComp3(EncodeNrResponseHeaderMeComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Securities Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedSecuritiesGrpComp2 ==
    \A message \in CheckedNotAffectedSecuritiesGrpComp2 :
        LET read == DecodeNotAffectedSecuritiesGrpComp2(EncodeNotAffectedSecuritiesGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteResponse ==
    \A message \in CheckedDeleteAllQuoteResponse :
        LET read == DecodeDeleteAllQuoteResponse(EncodeDeleteAllQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp4 ==
    \A message \in CheckedRbcHeaderMeComp4 :
        LET read == DecodeRbcHeaderMeComp4(EncodeRbcHeaderMeComp4(message))
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

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp4 ==
    \A message \in CheckedNrResponseHeaderMeComp4 :
        LET read == DecodeNrResponseHeaderMeComp4(EncodeNrResponseHeaderMeComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Nr Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderNrResponse ==
    \A message \in CheckedDeleteOrderNrResponse :
        LET read == DecodeDeleteOrderNrResponse(EncodeDeleteOrderNrResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp2 ==
    \A message \in CheckedResponseHeaderMeComp2 :
        LET read == DecodeResponseHeaderMeComp2(EncodeResponseHeaderMeComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderResponse ==
    \A message \in CheckedDeleteOrderResponse :
        LET read == DecodeDeleteOrderResponse(EncodeDeleteOrderResponse(message))
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

(* Every Forced Logout Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripForcedLogoutNotification ==
    \A message \in CheckedForcedLogoutNotification :
        LET read == DecodeForcedLogoutNotification(EncodeForcedLogoutNotification(message))
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

(* Every Gateway Response decodes back to what was encoded, and leaves nothing over *)
RoundTripGatewayResponse ==
    \A message \in CheckedGatewayResponse :
        LET read == DecodeGatewayResponse(EncodeGatewayResponse(message))
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

(* Every Gw Order Acknowledgement decodes back to what was encoded, and leaves nothing over *)
RoundTripGwOrderAcknowledgement ==
    \A message \in CheckedGwOrderAcknowledgement :
        LET read == DecodeGwOrderAcknowledgement(EncodeGwOrderAcknowledgement(message))
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

(* Every Heartbeat Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatNotification ==
    \A message \in CheckedHeartbeatNotification :
        LET read == DecodeHeartbeatNotification(EncodeHeartbeatNotification(message))
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

(* Every Sessions Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionsGrpComp ==
    \A message \in CheckedSessionsGrpComp :
        LET read == DecodeSessionsGrpComp(EncodeSessionsGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Session List Response decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireSessionListResponse ==
    \A message \in CheckedInquireSessionListResponse :
        LET read == DecodeInquireSessionListResponse(EncodeInquireSessionListResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp4 ==
    \A message \in CheckedResponseHeaderComp4 :
        LET read == DecodeResponseHeaderComp4(EncodeResponseHeaderComp4(message))
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
RoundTripResponseHeaderComp5 ==
    \A message \in CheckedResponseHeaderComp5 :
        LET read == DecodeResponseHeaderComp5(EncodeResponseHeaderComp5(message))
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

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp5 ==
    \A message \in CheckedNrResponseHeaderMeComp5 :
        LET read == DecodeNrResponseHeaderMeComp5(EncodeNrResponseHeaderMeComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Entry Ack Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEntryAckGrpComp ==
    \A message \in CheckedQuoteEntryAckGrpComp :
        LET read == DecodeQuoteEntryAckGrpComp(EncodeQuoteEntryAckGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteResponse ==
    \A message \in CheckedMassQuoteResponse :
        LET read == DecodeMassQuoteResponse(EncodeMassQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp6 ==
    \A message \in CheckedNrResponseHeaderMeComp6 :
        LET read == DecodeNrResponseHeaderMeComp6(EncodeNrResponseHeaderMeComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Nr Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderNrResponse ==
    \A message \in CheckedModifyOrderNrResponse :
        LET read == DecodeModifyOrderNrResponse(EncodeModifyOrderNrResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp3 ==
    \A message \in CheckedResponseHeaderMeComp3 :
        LET read == DecodeResponseHeaderMeComp3(EncodeResponseHeaderMeComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderResponse ==
    \A message \in CheckedModifyOrderResponse :
        LET read == DecodeModifyOrderResponse(EncodeModifyOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp5 ==
    \A message \in CheckedRbcHeaderMeComp5 :
        LET read == DecodeRbcHeaderMeComp5(EncodeRbcHeaderMeComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegGrpComp ==
    \A message \in CheckedMultiLegGrpComp :
        LET read == DecodeMultiLegGrpComp(EncodeMultiLegGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Fill Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegFillGrpComp ==
    \A message \in CheckedMultiLegFillGrpComp :
        LET read == DecodeMultiLegFillGrpComp(EncodeMultiLegFillGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmnt Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmntLegExecGrpComp ==
    \A message \in CheckedInstrmntLegExecGrpComp :
        LET read == DecodeInstrmntLegExecGrpComp(EncodeInstrmntLegExecGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Exec Report Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegExecReportBroadcast ==
    \A message \in CheckedMultiLegExecReportBroadcast :
        LET read == DecodeMultiLegExecReportBroadcast(EncodeMultiLegExecReportBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp4 ==
    \A message \in CheckedResponseHeaderMeComp4 :
        LET read == DecodeResponseHeaderMeComp4(EncodeResponseHeaderMeComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegExecGrpComp ==
    \A message \in CheckedMultiLegExecGrpComp :
        LET read == DecodeMultiLegExecGrpComp(EncodeMultiLegExecGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Fill Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegFillGrpComp2 ==
    \A message \in CheckedMultiLegFillGrpComp2 :
        LET read == DecodeMultiLegFillGrpComp2(EncodeMultiLegFillGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmnt Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmntLegExecGrpComp2 ==
    \A message \in CheckedInstrmntLegExecGrpComp2 :
        LET read == DecodeInstrmntLegExecGrpComp2(EncodeInstrmntLegExecGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Exec Response decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegExecResponse ==
    \A message \in CheckedMultiLegExecResponse :
        LET read == DecodeMultiLegExecResponse(EncodeMultiLegExecResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp7 ==
    \A message \in CheckedNrResponseHeaderMeComp7 :
        LET read == DecodeNrResponseHeaderMeComp7(EncodeNrResponseHeaderMeComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Order Reject decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegOrderReject ==
    \A message \in CheckedMultiLegOrderReject :
        LET read == DecodeMultiLegOrderReject(EncodeMultiLegOrderReject(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp8 ==
    \A message \in CheckedNrResponseHeaderMeComp8 :
        LET read == DecodeNrResponseHeaderMeComp8(EncodeNrResponseHeaderMeComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Nr Response decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderNrResponse ==
    \A message \in CheckedNewOrderNrResponse :
        LET read == DecodeNewOrderNrResponse(EncodeNewOrderNrResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp5 ==
    \A message \in CheckedResponseHeaderMeComp5 :
        LET read == DecodeResponseHeaderMeComp5(EncodeResponseHeaderMeComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Response decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderResponse ==
    \A message \in CheckedNewOrderResponse :
        LET read == DecodeNewOrderResponse(EncodeNewOrderResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp ==
    \A message \in CheckedRbcHeaderComp :
        LET read == DecodeRbcHeaderComp(EncodeRbcHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsBroadcast ==
    \A message \in CheckedNewsBroadcast :
        LET read == DecodeNewsBroadcast(EncodeNewsBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp6 ==
    \A message \in CheckedRbcHeaderMeComp6 :
        LET read == DecodeRbcHeaderMeComp6(EncodeRbcHeaderMeComp6(message))
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

(* Every Instrmnt Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmntLegExecGrpComp3 ==
    \A message \in CheckedInstrmntLegExecGrpComp3 :
        LET read == DecodeInstrmntLegExecGrpComp3(EncodeInstrmntLegExecGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Exec Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecNotification ==
    \A message \in CheckedOrderExecNotification :
        LET read == DecodeOrderExecNotification(EncodeOrderExecNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp7 ==
    \A message \in CheckedRbcHeaderMeComp7 :
        LET read == DecodeRbcHeaderMeComp7(EncodeRbcHeaderMeComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOrdGrpComp ==
    \A message \in CheckedLegOrdGrpComp :
        LET read == DecodeLegOrdGrpComp(EncodeLegOrdGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGrpComp2 ==
    \A message \in CheckedFillsGrpComp2 :
        LET read == DecodeFillsGrpComp2(EncodeFillsGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmnt Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmntLegExecGrpComp4 ==
    \A message \in CheckedInstrmntLegExecGrpComp4 :
        LET read == DecodeInstrmntLegExecGrpComp4(EncodeInstrmntLegExecGrpComp4(message))
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

(* Every Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderMeComp6 ==
    \A message \in CheckedResponseHeaderMeComp6 :
        LET read == DecodeResponseHeaderMeComp6(EncodeResponseHeaderMeComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGrpComp3 ==
    \A message \in CheckedFillsGrpComp3 :
        LET read == DecodeFillsGrpComp3(EncodeFillsGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrmnt Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmntLegExecGrpComp5 ==
    \A message \in CheckedInstrmntLegExecGrpComp5 :
        LET read == DecodeInstrmntLegExecGrpComp5(EncodeInstrmntLegExecGrpComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Exec Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecResponse ==
    \A message \in CheckedOrderExecResponse :
        LET read == DecodeOrderExecResponse(EncodeOrderExecResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp8 ==
    \A message \in CheckedRbcHeaderMeComp8 :
        LET read == DecodeRbcHeaderMeComp8(EncodeRbcHeaderMeComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEventGrpComp ==
    \A message \in CheckedQuoteEventGrpComp :
        LET read == DecodeQuoteEventGrpComp(EncodeQuoteEventGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Exec Report Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecReportBroadcast ==
    \A message \in CheckedQuoteExecReportBroadcast :
        LET read == DecodeQuoteExecReportBroadcast(EncodeQuoteExecReportBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp9 ==
    \A message \in CheckedRbcHeaderMeComp9 :
        LET read == DecodeRbcHeaderMeComp9(EncodeRbcHeaderMeComp9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEventGrpComp2 ==
    \A message \in CheckedQuoteEventGrpComp2 :
        LET read == DecodeQuoteEventGrpComp2(EncodeQuoteEventGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Leg Exec Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteLegExecGrpComp ==
    \A message \in CheckedQuoteLegExecGrpComp :
        LET read == DecodeQuoteLegExecGrpComp(EncodeQuoteLegExecGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Execution Report decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecutionReport ==
    \A message \in CheckedQuoteExecutionReport :
        LET read == DecodeQuoteExecutionReport(EncodeQuoteExecutionReport(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp9 ==
    \A message \in CheckedNrResponseHeaderMeComp9 :
        LET read == DecodeNrResponseHeaderMeComp9(EncodeNrResponseHeaderMeComp9(message))
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

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp6 ==
    \A message \in CheckedResponseHeaderComp6 :
        LET read == DecodeResponseHeaderComp6(EncodeResponseHeaderComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Me Message Response decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitMeMessageResponse ==
    \A message \in CheckedRetransmitMeMessageResponse :
        LET read == DecodeRetransmitMeMessageResponse(EncodeRetransmitMeMessageResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp7 ==
    \A message \in CheckedResponseHeaderComp7 :
        LET read == DecodeResponseHeaderComp7(EncodeResponseHeaderComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Response decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitResponse ==
    \A message \in CheckedRetransmitResponse :
        LET read == DecodeRetransmitResponse(EncodeRetransmitResponse(message))
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

(* Every Risk Collateral Alert Admin Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskCollateralAlertAdminBroadcast ==
    \A message \in CheckedRiskCollateralAlertAdminBroadcast :
        LET read == DecodeRiskCollateralAlertAdminBroadcast(EncodeRiskCollateralAlertAdminBroadcast(message))
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

(* Every Risk Collateral Alert Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskCollateralAlertBroadcast ==
    \A message \in CheckedRiskCollateralAlertBroadcast :
        LET read == DecodeRiskCollateralAlertBroadcast(EncodeRiskCollateralAlertBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp4 ==
    \A message \in CheckedRbcHeaderComp4 :
        LET read == DecodeRbcHeaderComp4(EncodeRbcHeaderComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Risk Notification Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripRiskNotificationBroadcast ==
    \A message \in CheckedRiskNotificationBroadcast :
        LET read == DecodeRiskNotificationBroadcast(EncodeRiskNotificationBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nrbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrbcHeaderComp ==
    \A message \in CheckedNrbcHeaderComp :
        LET read == DecodeNrbcHeaderComp(EncodeNrbcHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Service Availability Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripServiceAvailabilityBroadcast ==
    \A message \in CheckedServiceAvailabilityBroadcast :
        LET read == DecodeServiceAvailabilityBroadcast(EncodeServiceAvailabilityBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp8 ==
    \A message \in CheckedResponseHeaderComp8 :
        LET read == DecodeResponseHeaderComp8(EncodeResponseHeaderComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Password Change Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionPasswordChangeResponse ==
    \A message \in CheckedSessionPasswordChangeResponse :
        LET read == DecodeSessionPasswordChangeResponse(EncodeSessionPasswordChangeResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp9 ==
    \A message \in CheckedResponseHeaderComp9 :
        LET read == DecodeResponseHeaderComp9(EncodeResponseHeaderComp9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Registration Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionRegistrationResponse ==
    \A message \in CheckedSessionRegistrationResponse :
        LET read == DecodeSessionRegistrationResponse(EncodeSessionRegistrationResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp10 ==
    \A message \in CheckedResponseHeaderComp10 :
        LET read == DecodeResponseHeaderComp10(EncodeResponseHeaderComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscribe Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscribeResponse ==
    \A message \in CheckedSubscribeResponse :
        LET read == DecodeSubscribeResponse(EncodeSubscribeResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp5 ==
    \A message \in CheckedRbcHeaderComp5 :
        LET read == DecodeRbcHeaderComp5(EncodeRbcHeaderComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tm Trading Session Status Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTmTradingSessionStatusBroadcast ==
    \A message \in CheckedTmTradingSessionStatusBroadcast :
        LET read == DecodeTmTradingSessionStatusBroadcast(EncodeTmTradingSessionStatusBroadcast(message))
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

(* Every Throttle Update Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripThrottleUpdateNotification ==
    \A message \in CheckedThrottleUpdateNotification :
        LET read == DecodeThrottleUpdateNotification(EncodeThrottleUpdateNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp6 ==
    \A message \in CheckedRbcHeaderComp6 :
        LET read == DecodeRbcHeaderComp6(EncodeRbcHeaderComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBroadcast ==
    \A message \in CheckedTradeBroadcast :
        LET read == DecodeTradeBroadcast(EncodeTradeBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp7 ==
    \A message \in CheckedRbcHeaderComp7 :
        LET read == DecodeRbcHeaderComp7(EncodeRbcHeaderComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Enhancement Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeEnhancementBroadcast ==
    \A message \in CheckedTradeEnhancementBroadcast :
        LET read == DecodeTradeEnhancementBroadcast(EncodeTradeEnhancementBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp10 ==
    \A message \in CheckedRbcHeaderMeComp10 :
        LET read == DecodeRbcHeaderMeComp10(EncodeRbcHeaderMeComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusBroadcast ==
    \A message \in CheckedTradingSessionStatusBroadcast :
        LET read == DecodeTradingSessionStatusBroadcast(EncodeTradingSessionStatusBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp11 ==
    \A message \in CheckedResponseHeaderComp11 :
        LET read == DecodeResponseHeaderComp11(EncodeResponseHeaderComp11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsubscribe Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeResponse ==
    \A message \in CheckedUnsubscribeResponse :
        LET read == DecodeUnsubscribeResponse(EncodeUnsubscribeResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp12 ==
    \A message \in CheckedResponseHeaderComp12 :
        LET read == DecodeResponseHeaderComp12(EncodeResponseHeaderComp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginResponse ==
    \A message \in CheckedUserLoginResponse :
        LET read == DecodeUserLoginResponse(EncodeUserLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp13 ==
    \A message \in CheckedResponseHeaderComp13 :
        LET read == DecodeResponseHeaderComp13(EncodeResponseHeaderComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Logout Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLogoutResponse ==
    \A message \in CheckedUserLogoutResponse :
        LET read == DecodeUserLogoutResponse(EncodeUserLogoutResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp14 ==
    \A message \in CheckedResponseHeaderComp14 :
        LET read == DecodeResponseHeaderComp14(EncodeResponseHeaderComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Password Change Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUserPasswordChangeResponse ==
    \A message \in CheckedUserPasswordChangeResponse :
        LET read == DecodeUserPasswordChangeResponse(EncodeUserPasswordChangeResponse(message))
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
